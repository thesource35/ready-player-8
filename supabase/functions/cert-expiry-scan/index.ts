// Phase 25 — cert-expiry-scan Edge Function (TEAM-04, NOTIF-04)
// Invoked daily by pg_cron at 13:15 UTC. Scans cs_certifications for certs
// across 4 escalating thresholds: 30-day, 7-day, day-of, weekly post-expiry.
// Inserts grouped cs_activity_events rows (category='assigned_task') which flow
// through the Database Webhook -> notifications-fanout -> APNs pipeline (Phase 14).
//
// Features: batch processing (100/page, 50s timeout), payload-marker dedupe,
// member grouping, dismiss-suppress via suppress_user_ids, first-deploy guard,
// rate cap (200 events/run), structured JSON logging.
//
// D-26: Timezone — uses UTC date comparison. The scan runs at 13:15 UTC (morning
// US time), so date-level expiry checks are accurate for US construction schedules.
// A timezone-aware approach would resolve from project location; deferred for simplicity.

import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2'

// ─── Types ───────────────────────────────────────────────────────────────────

type Cert = {
  id: string
  member_id: string
  name: string
  expires_at: string
  status: string
}

type Threshold = 0 | 7 | 30 | 'post-expiry'

type GroupedAlert = {
  memberId: string
  memberName: string
  threshold: Threshold
  certs: Cert[]
  projectIds: string[]
  recipientUserIds: string[]
  suppressUserIds: string[]
}

// ─── Constants ───────────────────────────────────────────────────────────────

const BATCH_SIZE = 100
const TIMEOUT_MS = 50000
const RATE_CAP = 200

// Priority order: most urgent first (D-04)
const THRESHOLD_PRIORITY: Threshold[] = [0, 7, 30, 'post-expiry']

// ─── Main Handler ────────────────────────────────────────────────────────────

export async function handle(req: Request, deps: { supabase: SupabaseClient }): Promise<Response> {
  const { supabase } = deps
  const startMs = Date.now()

  // Auth check (T-25-01)
  const auth = req.headers.get('authorization') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!serviceKey || !auth.includes(serviceKey)) {
    return new Response('unauthorized', { status: 401 })
  }

  const today = new Date()
  const todayStr = today.toISOString().slice(0, 10)
  const target30 = new Date(today)
  target30.setUTCDate(today.getUTCDate() + 30)
  const target30Str = target30.toISOString().slice(0, 10)

  // ── Step 1: Auto-flip expired active certs ──────────────────────────────
  await supabase
    .from('cs_certifications')
    .update({ status: 'expired' })
    .lt('expires_at', todayStr)
    .eq('status', 'active')

  // ── Step 2: First-deploy guard (D-27) ───────────────────────────────────
  const { count: anyExisting } = await supabase
    .from('cs_activity_events')
    .select('id', { count: 'exact', head: true })
    .eq('entity_type', 'certifications')
  const isFirstDeploy = (anyExisting ?? 0) === 0

  // ── Step 3: Batch-fetch certs ───────────────────────────────────────────
  const allActiveCerts: Cert[] = []
  const allExpiredCerts: Cert[] = []
  let batchCount = 0

  // 3a. Active certs expiring within 30 days (covers 30d/7d/day-of)
  let lastId = ''
  while (true) {
    if (Date.now() - startMs > TIMEOUT_MS) {
      console.log(JSON.stringify({ warning: 'timeout_active_certs', lastId, elapsed_ms: Date.now() - startMs }))
      break
    }
    let query = supabase
      .from('cs_certifications')
      .select('id, member_id, name, expires_at, status')
      .gte('expires_at', todayStr)
      .lte('expires_at', target30Str)
      .eq('status', 'active')
      .order('id', { ascending: true })
      .limit(BATCH_SIZE)
    if (lastId) {
      query = query.gt('id', lastId)
    }
    const { data } = await query
    const certs = (data ?? []) as Cert[]
    if (certs.length === 0) break
    allActiveCerts.push(...certs)
    lastId = certs[certs.length - 1].id
    batchCount++
  }

  // 3b. Expired certs for post-expiry weekly (D-01)
  lastId = ''
  while (true) {
    if (Date.now() - startMs > TIMEOUT_MS) {
      console.log(JSON.stringify({ warning: 'timeout_expired_certs', lastId, elapsed_ms: Date.now() - startMs }))
      break
    }
    let query = supabase
      .from('cs_certifications')
      .select('id, member_id, name, expires_at, status')
      .eq('status', 'expired')
      .lt('expires_at', todayStr)
      .order('id', { ascending: true })
      .limit(BATCH_SIZE)
    if (lastId) {
      query = query.gt('id', lastId)
    }
    const { data } = await query
    const certs = (data ?? []) as Cert[]
    if (certs.length === 0) break
    allExpiredCerts.push(...certs)
    lastId = certs[certs.length - 1].id
    batchCount++
  }

  const totalScanned = allActiveCerts.length + allExpiredCerts.length

  // ── Step 4: Calculate thresholds per cert ───────────────────────────────

  type CertWithThreshold = Cert & { threshold: Threshold }
  const certsWithThresholds: CertWithThreshold[] = []

  for (const cert of allActiveCerts) {
    const expiresDate = new Date(cert.expires_at + 'T00:00:00Z')
    const todayStart = new Date(todayStr + 'T00:00:00Z')
    const diffDays = Math.round((expiresDate.getTime() - todayStart.getTime()) / (1000 * 60 * 60 * 24))

    let threshold: Threshold
    if (diffDays === 0) {
      threshold = 0
    } else if (diffDays >= 1 && diffDays <= 7) {
      threshold = 7
    } else {
      threshold = 30
    }

    certsWithThresholds.push({ ...cert, threshold })
  }

  for (const cert of allExpiredCerts) {
    const expiresDate = new Date(cert.expires_at + 'T00:00:00Z')
    const todayStart = new Date(todayStr + 'T00:00:00Z')
    const daysSinceExpiry = Math.round((todayStart.getTime() - expiresDate.getTime()) / (1000 * 60 * 60 * 24))

    // Post-expiry: only fire on weekly boundary (D-01)
    if (daysSinceExpiry > 0 && daysSinceExpiry % 7 === 0) {
      certsWithThresholds.push({ ...cert, threshold: 'post-expiry' })
    }
  }

  // ── Step 5: First-deploy filter (D-27) ──────────────────────────────────
  // On first deploy, fire only the most urgent threshold per cert
  let filteredCerts = certsWithThresholds
  if (isFirstDeploy) {
    const mostUrgentPerCert = new Map<string, CertWithThreshold>()
    for (const ct of certsWithThresholds) {
      // Skip post-expiry entirely on first deploy
      if (ct.threshold === 'post-expiry') continue
      const existing = mostUrgentPerCert.get(ct.id)
      if (!existing || thresholdUrgency(ct.threshold) > thresholdUrgency(existing.threshold)) {
        mostUrgentPerCert.set(ct.id, ct)
      }
    }
    filteredCerts = Array.from(mostUrgentPerCert.values())
  }

  // ── Step 6: Batch recipient resolution ──────────────────────────────────
  const allMemberIds = [...new Set(filteredCerts.map(c => c.member_id))]

  // 6a. Resolve member names
  const memberNames = new Map<string, string>()
  if (allMemberIds.length > 0) {
    const { data: members } = await supabase
      .from('cs_team_members')
      .select('id, name, user_id, created_by')
      .in('id', allMemberIds)
    for (const m of (members ?? []) as any[]) {
      memberNames.set(m.id, m.name ?? 'Team Member')
    }
  }

  // 6b. Get all active project assignments for these members
  const memberAssignments = new Map<string, string[]>()
  if (allMemberIds.length > 0) {
    const { data: assignments } = await supabase
      .from('cs_project_assignments')
      .select('member_id, project_id')
      .in('member_id', allMemberIds)
      .eq('status', 'active')
    for (const a of (assignments ?? []) as any[]) {
      const list = memberAssignments.get(a.member_id) ?? []
      list.push(a.project_id)
      memberAssignments.set(a.member_id, list)
    }
  }

  // 6c. Get all PM assignments for those projects
  const allProjectIds = [...new Set(Array.from(memberAssignments.values()).flat())]
  const projectPmMemberIds = new Map<string, string[]>()
  if (allProjectIds.length > 0) {
    const { data: pmAssignments } = await supabase
      .from('cs_project_assignments')
      .select('project_id, member_id')
      .in('project_id', allProjectIds)
      .eq('status', 'active')
      .or('role_on_project.ilike.%project manager%,role_on_project.ilike.%PM%')
    for (const pm of (pmAssignments ?? []) as any[]) {
      const list = projectPmMemberIds.get(pm.project_id) ?? []
      list.push(pm.member_id)
      projectPmMemberIds.set(pm.project_id, list)
    }
  }

  // 6d. Resolve user_ids for PM members
  const allPmMemberIds = [...new Set(Array.from(projectPmMemberIds.values()).flat())]
  const memberUserIds = new Map<string, string | null>()
  if (allPmMemberIds.length > 0 || allMemberIds.length > 0) {
    const allRelevantMemberIds = [...new Set([...allMemberIds, ...allPmMemberIds])]
    const { data: teamMembers } = await supabase
      .from('cs_team_members')
      .select('id, user_id, created_by')
      .in('id', allRelevantMemberIds)
    for (const tm of (teamMembers ?? []) as any[]) {
      memberUserIds.set(tm.id, tm.user_id ?? null)
    }
  }

  // 6e. Get project created_by values
  const projectCreatedBy = new Map<string, string>()
  if (allProjectIds.length > 0) {
    const { data: projects } = await supabase
      .from('cs_projects')
      .select('id, created_by')
      .in('id', allProjectIds)
    for (const p of (projects ?? []) as any[]) {
      if (p.created_by) projectCreatedBy.set(p.id, p.created_by)
    }
  }

  // 6f. Get member created_by for unassigned members (D-15)
  const memberCreatedBy = new Map<string, string>()
  if (allMemberIds.length > 0) {
    const { data: members } = await supabase
      .from('cs_team_members')
      .select('id, created_by')
      .in('id', allMemberIds)
    for (const m of (members ?? []) as any[]) {
      if (m.created_by) memberCreatedBy.set(m.id, m.created_by)
    }
  }

  // ── Step 7: Group certs by member + threshold (D-06) ────────────────────
  const groupKey = (memberId: string, threshold: Threshold) => `${memberId}::${threshold}`
  const groups = new Map<string, CertWithThreshold[]>()
  for (const ct of filteredCerts) {
    const key = groupKey(ct.member_id, ct.threshold)
    const list = groups.get(key) ?? []
    list.push(ct)
    groups.set(key, list)
  }

  // Sort groups by threshold urgency for rate cap priority (D-04)
  const sortedGroupKeys = Array.from(groups.keys()).sort((a, b) => {
    const threshA = groups.get(a)![0].threshold
    const threshB = groups.get(b)![0].threshold
    return thresholdUrgency(threshB) - thresholdUrgency(threshA)
  })

  // ── Step 8: Dedupe, dismiss-suppress, and insert events ─────────────────
  let eventsInserted = 0
  let dedupeSkipCount = 0
  let dismissSkipCount = 0
  let errorCount = 0

  for (const key of sortedGroupKeys) {
    // Rate cap check (D-04)
    if (eventsInserted >= RATE_CAP) {
      console.log(JSON.stringify({ warning: 'rate_cap_reached', cap: RATE_CAP, remaining_groups: sortedGroupKeys.length - sortedGroupKeys.indexOf(key) }))
      break
    }

    const certs = groups.get(key)!
    const memberId = certs[0].member_id
    const threshold = certs[0].threshold

    try {
      // 8a. Payload dedupe check (D-02)
      let skipGroup = false
      for (const cert of certs) {
        const { count } = await supabase
          .from('cs_activity_events')
          .select('id', { count: 'exact', head: true })
          .eq('entity_type', 'certifications')
          .filter('payload->>cert_id', 'eq', cert.id)
          .filter('payload->>threshold', 'eq', String(threshold))
          .filter('payload->>expires_at', 'eq', cert.expires_at)
        if ((count ?? 0) > 0) {
          dedupeSkipCount++
          skipGroup = true
          break
        }
      }
      if (skipGroup) continue

      // 8b. Resolve recipients (D-13, D-14, D-15)
      const recipientUserIds = new Set<string>()

      // Member's own user_id
      const memberUserId = memberUserIds.get(memberId)
      if (memberUserId) recipientUserIds.add(memberUserId)

      // PMs and created_by for all assigned projects
      const projects = memberAssignments.get(memberId) ?? []
      for (const projectId of projects) {
        // PM user_ids
        const pmMembers = projectPmMemberIds.get(projectId) ?? []
        for (const pmMemberId of pmMembers) {
          const pmUserId = memberUserIds.get(pmMemberId)
          if (pmUserId) recipientUserIds.add(pmUserId)
        }
        // Project created_by
        const createdBy = projectCreatedBy.get(projectId)
        if (createdBy) recipientUserIds.add(createdBy)
      }

      // D-15: If no assignments, alert created_by of member record
      if (projects.length === 0) {
        const createdBy = memberCreatedBy.get(memberId)
        if (createdBy) recipientUserIds.add(createdBy)
      }

      const recipientIds = Array.from(recipientUserIds)
      if (recipientIds.length === 0) continue

      // 8c. Dismiss-suppress (D-11, D-12)
      const suppressUserIds: string[] = []
      if (recipientIds.length > 0) {
        const { data: dismissed } = await supabase
          .from('cs_notifications')
          .select('user_id')
          .eq('entity_type', 'certifications')
          .eq('entity_id', certs[0].id)
          .filter('payload->>threshold', 'eq', String(threshold))
          .not('dismissed_at', 'is', null)
        for (const d of (dismissed ?? []) as any[]) {
          if (d.user_id) suppressUserIds.push(d.user_id)
        }
      }

      // If ALL recipients are dismissed, skip entirely
      const activeRecipients = recipientIds.filter(id => !suppressUserIds.includes(id))
      if (activeRecipients.length === 0) {
        dismissSkipCount++
        continue
      }

      // 8d. Build grouped summary (D-06, D-07, D-08)
      const memberName = memberNames.get(memberId) ?? 'Team Member'
      const certNames = certs.map(c => c.name).join(' + ')
      let summary: string
      if (threshold === 0) {
        summary = `${memberName}: ${certNames} expires today`
      } else if (threshold === 'post-expiry') {
        summary = `${memberName}: ${certNames} has expired`
      } else {
        summary = `${memberName}: ${certNames} expires in ${threshold} days`
      }

      // 8e. Insert activity event (D-34)
      const firstProjectId = projects.length > 0 ? projects[0] : null
      const { error } = await supabase.from('cs_activity_events').insert({
        project_id: firstProjectId,
        entity_type: 'certifications',
        entity_id: certs[0].id,
        action: 'updated',
        category: 'assigned_task',
        summary,
        payload: {
          cert_id: certs[0].id,
          cert_ids: certs.map(c => c.id),
          member_id: memberId,
          member_name: memberName,
          expires_at: certs[0].expires_at,
          threshold,
          cert_names: certs.map(c => c.name),
          delivery_channels: ['push', 'inbox'],
          recipient_user_ids: activeRecipients,
          suppress_user_ids: suppressUserIds,
        },
      })

      if (error) {
        errorCount++
        // D-37: No PII — log cert_id only
        console.error(JSON.stringify({ error: error.message, cert_id: certs[0].id }))
      } else {
        eventsInserted++
      }
    } catch (err: unknown) {
      // D-39: Log and continue on partial failures
      errorCount++
      const message = err instanceof Error ? err.message : String(err)
      console.error(JSON.stringify({ error: message, cert_id: certs[0].id }))
    }
  }

  // ── Step 9: Structured logging (D-37) ───────────────────────────────────
  const summaryLog = {
    scanned: totalScanned,
    alerts_created: eventsInserted,
    skipped_dedupe: dedupeSkipCount,
    skipped_dismissed: dismissSkipCount,
    errors: errorCount,
    elapsed_ms: Date.now() - startMs,
    batches: batchCount,
  }
  console.log(JSON.stringify(summaryLog))

  return new Response(JSON.stringify(summaryLog), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  })
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function thresholdUrgency(t: Threshold): number {
  if (t === 0) return 4
  if (t === 7) return 3
  if (t === 30) return 2
  return 1 // post-expiry
}

// Deno runtime entry — skipped during unit tests which import `handle` directly.
if (import.meta.main) {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  Deno.serve((req) => handle(req, { supabase }))
}
