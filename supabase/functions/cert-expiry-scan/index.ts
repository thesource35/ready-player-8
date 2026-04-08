// Phase 15 — cert-expiry-scan Edge Function (TEAM-04)
// Invoked daily by pg_cron. Scans cs_certifications for certs expiring in 30
// days and inserts cs_activity_events rows (category='assigned_task'), which
// flow through the same Database Webhook → notifications-fanout → APNs pipeline
// established in Phase 14 (D-05, D-06).
//
// Also idempotently flips any already-expired active certs to status='expired'.
//
// Dedupe guard: skips insertion if an event with the same entity_id + category
// was already created in the last 20 hours.

import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2'

export async function handle(req: Request, deps: { supabase: SupabaseClient }) {
  const { supabase } = deps
  const auth = req.headers.get('authorization') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!serviceKey || !auth.includes(serviceKey)) {
    return new Response('unauthorized', { status: 401 })
  }

  const today = new Date()
  const todayStr = today.toISOString().slice(0, 10)
  const target = new Date(today)
  target.setUTCDate(today.getUTCDate() + 30)
  const targetDate = target.toISOString().slice(0, 10)

  // 1. Idempotent auto-flip of already-expired active certs
  await supabase
    .from('cs_certifications')
    .update({ status: 'expired' })
    .lt('expires_at', todayStr)
    .eq('status', 'active')

  // 2. Find certs expiring exactly 30 days from today
  const { data: certs } = await supabase
    .from('cs_certifications')
    .select('id, member_id, name, expires_at')
    .eq('expires_at', targetDate)
    .eq('status', 'active')

  let inserted = 0
  for (const cert of (certs ?? []) as any[]) {
    // 20-hour dedupe guard (T-15-07)
    const since = new Date(Date.now() - 20 * 3600 * 1000).toISOString()
    const { count } = await supabase
      .from('cs_activity_events')
      .select('id', { count: 'exact', head: true })
      .eq('entity_id', cert.id)
      .eq('category', 'assigned_task')
      .gte('created_at', since)
    if ((count ?? 0) > 0) continue

    // Resolve project_id via first active assignment (D-06 fallback chain)
    const { data: assignment } = await supabase
      .from('cs_project_assignments')
      .select('project_id')
      .eq('member_id', cert.member_id)
      .eq('status', 'active')
      .limit(1)
      .maybeSingle()

    const { error } = await supabase.from('cs_activity_events').insert({
      project_id: (assignment as any)?.project_id ?? null,
      entity_type: 'certifications',
      entity_id: cert.id,
      action: 'updated',
      category: 'assigned_task', // CRITICAL: must be in Phase 14 PUSH_CATEGORIES
      summary: `Certification expiring in 30 days: ${cert.name}`,
      payload: {
        cert_id: cert.id,
        member_id: cert.member_id,
        expires_at: cert.expires_at,
        threshold: 30,
      },
    })
    if (!error) inserted++
  }

  return new Response(JSON.stringify({ inserted }), {
    status: 200,
    headers: { 'content-type': 'application/json' },
  })
}

// Deno runtime entry — skipped during unit tests which import `handle` directly.
if (import.meta.main) {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  Deno.serve((req) => handle(req, { supabase }))
}
