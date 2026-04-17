// D-32: 7-day retention on cs_video_webhook_events dedupe table.
// Schedule: '30 3 * * *' (03:30 UTC, after the main prune).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req) => {
  // T-22-10-01: Only pg_cron with service-role auth may invoke this function
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE)
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

  const { error, count } = await supabase
    .from('cs_video_webhook_events')
    .delete({ count: 'exact' })
    .lt('received_at', cutoff)

  const report = { deleted: count ?? 0, error: error?.message ?? null }
  // T-22-10-03: Log report (no credentials)
  console.log('[prune-webhook-events]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})
