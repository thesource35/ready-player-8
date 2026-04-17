// D-30: idle-source auto-archive. Any cs_video_sources (kind='fixed_camera') with no webhook
// activity in 30 days flips to status='archived' and the Mux live_input is disabled.
// Schedule: '5 3 * * *' (03:05 UTC, runs alongside retention prune).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const MUX_TOKEN_ID = Deno.env.get('MUX_TOKEN_ID')
const MUX_TOKEN_SECRET = Deno.env.get('MUX_TOKEN_SECRET')

async function disableMuxLiveInput(liveInputId: string): Promise<boolean> {
  if (!MUX_TOKEN_ID || !MUX_TOKEN_SECRET) return false
  const auth = btoa(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`)
  const res = await fetch(
    `https://api.mux.com/video/v1/live-streams/${liveInputId}/disable`,
    {
      method: 'PUT',
      headers: { Authorization: `Basic ${auth}` },
    }
  )
  return res.ok || res.status === 404
}

Deno.serve(async (req) => {
  // T-22-10-01: Only pg_cron with service-role auth may invoke this function
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE)
  const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

  const { data: idle, error: selectErr } = await supabase
    .from('cs_video_sources')
    .select('id, mux_live_input_id, last_active_at, created_at')
    .eq('kind', 'fixed_camera')
    .neq('status', 'archived')
    .or(
      `last_active_at.lt.${cutoff},and(last_active_at.is.null,created_at.lt.${cutoff})`
    )

  const report = { archived: 0, mux_disabled: 0, errors: [] as string[] }
  if (selectErr) report.errors.push(`select: ${selectErr.message}`)

  // T-22-10-02: Each row in its own try/catch — partial failure degrades gracefully
  for (const row of idle ?? []) {
    try {
      if (row.mux_live_input_id) {
        const ok = await disableMuxLiveInput(row.mux_live_input_id)
        if (ok) report.mux_disabled++
      }
      await supabase
        .from('cs_video_sources')
        .update({ status: 'archived' })
        .eq('id', row.id)
      report.archived++
    } catch (e) {
      report.errors.push(
        `source_${row.id}: ${e instanceof Error ? e.message : e}`
      )
    }
  }
  // T-22-10-03: Log report (no credentials)
  console.log('[archive-idle]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})
