// Phase 29 LIVE-06 — Scheduled Anthropic-vision suggestion generator.
// Invocation paths:
//   1. pg_cron '*/15 * * * *' (body: {})  → iterates ALL projects with drone assets ready in last 24h
//   2. pg_net per-upload trigger (29-04, ?project_id=X) → scopes to one project
//
// Budget cap (D-22): 96 cs_live_suggestions rows per project per UTC day. Pre-call count check;
// when at cap, insert a single 'budget_reached_marker' sentinel row so UI can surface state.
//
// JSON validation (LIVE-08, T-29-VISION-PAYLOAD): responses MUST pass Zod
// LiveSuggestionResponseSchema before INSERT. Parse failures incremented in report.malformed_skipped.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'
import {
  callAnthropicVision,
  DEFAULT_VISION_MODEL,
} from '../_shared/anthropic-vision.ts'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY')!

const DAILY_BUDGET_PER_PROJECT = 96 // D-22

Deno.serve(async (req) => {
  // T-29-03-01: service_role auth gate (mirrors prune-expired-videos line 25)
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  const url = new URL(req.url)
  const scopedProjectId = url.searchParams.get('project_id')

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE)
  const report = {
    generated: 0,
    budget_skipped: 0,
    budget_marker_inserted: 0,
    no_poster_skipped: 0,
    malformed_skipped: 0,
    errors: [] as string[],
  }

  // Find candidate projects with a drone asset 'ready' in the last 24h.
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
  let query = supabase
    .from('cs_video_assets')
    .select('project_id, org_id')
    .eq('source_type', 'drone')
    .eq('status', 'ready')
    .gte('created_at', since)
  if (scopedProjectId) query = query.eq('project_id', scopedProjectId)
  const { data: candidates, error: candErr } = await query
  if (candErr) {
    report.errors.push(`candidate_query: ${candErr.message}`)
    console.log('[live-suggestions]', JSON.stringify(report))
    return new Response(JSON.stringify(report), {
      status: 500,
      headers: { 'content-type': 'application/json' },
    })
  }

  // Dedupe by project_id
  const uniqueProjects = Array.from(
    new Map((candidates ?? []).map((r) => [r.project_id, r])).values(),
  )

  for (const p of uniqueProjects) {
    try {
      // D-22: budget pre-check
      const todayStart = new Date()
      todayStart.setUTCHours(0, 0, 0, 0)
      const { count, error: countErr } = await supabase
        .from('cs_live_suggestions')
        .select('id', { count: 'exact', head: true })
        .eq('project_id', p.project_id)
        .gte('generated_at', todayStart.toISOString())
      if (countErr) {
        report.errors.push(`budget_count_${p.project_id}: ${countErr.message}`)
        continue
      }
      if ((count ?? 0) >= DAILY_BUDGET_PER_PROJECT) {
        report.budget_skipped++
        // UI-SPEC LIVE-11 line 326: write single sentinel row if none yet today
        const { count: markerCount } = await supabase
          .from('cs_live_suggestions')
          .select('id', { count: 'exact', head: true })
          .eq('project_id', p.project_id)
          .eq('model', 'budget_reached_marker')
          .gte('generated_at', todayStart.toISOString())
        if ((markerCount ?? 0) === 0) {
          const latestAsset = await latestDroneAsset(supabase, p.project_id)
          if (latestAsset) {
            await supabase.from('cs_live_suggestions').insert({
              project_id: p.project_id,
              org_id: p.org_id,
              source_asset_id: latestAsset.id,
              model: 'budget_reached_marker',
              suggestion_text: '(budget reached)',
              action_hint: null,
            })
            report.budget_marker_inserted++
          }
        }
        continue
      }

      // Get latest ready drone asset
      const asset = await latestDroneAsset(supabase, p.project_id)
      if (!asset) continue

      // Sign poster URL (60s TTL — Anthropic fetches within seconds)
      const posterPath = `${asset.org_id}/${asset.project_id}/${asset.id}/poster.jpg`
      const { data: signed, error: signErr } = await supabase.storage
        .from('videos')
        .createSignedUrl(posterPath, 60)
      if (signErr || !signed?.signedUrl) {
        report.no_poster_skipped++
        // T-29-03-02: do NOT log the full signed URL; log path only
        console.log('[live-suggestions] no_poster', JSON.stringify({ project_id: p.project_id, path: posterPath }))
        continue
      }

      // Build project context
      const context = await buildProjectContext(supabase, p.project_id)

      // Call Anthropic + validate
      let parsed
      try {
        parsed = await callAnthropicVision({
          imageUrl: signed.signedUrl,
          promptInput: { imageUrl: signed.signedUrl, ...context },
          model: DEFAULT_VISION_MODEL,
          apiKey: ANTHROPIC_API_KEY,
        })
      } catch (e) {
        report.malformed_skipped++
        report.errors.push(`vision_${p.project_id}: ${e instanceof Error ? e.message : e}`)
        continue
      }

      // INSERT row
      const { error: insErr } = await supabase.from('cs_live_suggestions').insert({
        project_id: p.project_id,
        org_id: p.org_id,
        source_asset_id: asset.id,
        model: DEFAULT_VISION_MODEL,
        suggestion_text: parsed.suggestion_text,
        action_hint: parsed.action_hint,
      })
      if (insErr) {
        report.errors.push(`insert_${p.project_id}: ${insErr.message}`)
        continue
      }
      report.generated++
    } catch (e) {
      report.errors.push(
        `project_${p.project_id}: ${e instanceof Error ? e.message : e}`,
      )
    }
  }

  // T-29-03-03: structured audit trail (no secrets logged)
  console.log('[live-suggestions]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})

async function latestDroneAsset(
  supabase: ReturnType<typeof createClient>,
  projectId: string,
) {
  const { data } = await supabase
    .from('cs_video_assets')
    .select('id, org_id, project_id, created_at')
    .eq('project_id', projectId)
    .eq('source_type', 'drone')
    .eq('status', 'ready')
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  return data as { id: string; org_id: string; project_id: string; created_at: string } | null
}

async function buildProjectContext(
  supabase: ReturnType<typeof createClient>,
  projectId: string,
): Promise<{
  projectName?: string
  activeEquipment?: string[]
  recentDeliveries?: string[]
  weather?: string
  roadTraffic?: string
}> {
  const { data: project } = await supabase
    .from('cs_projects')
    .select('name')
    .eq('id', projectId)
    .maybeSingle()

  const { data: equipment } = await supabase
    .from('cs_equipment')
    .select('name')
    .eq('project_id', projectId)
    .eq('status', 'active')
    .limit(8)

  return {
    projectName: (project as { name?: string } | null)?.name ?? undefined,
    activeEquipment: (equipment ?? []).map((e: { name: string }) => e.name),
    // recentDeliveries + weather + roadTraffic left unset in v1 — UI-SPEC notes these are optional.
  }
}
