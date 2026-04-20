// Phase 29 LIVE-13 — Daily 7-day retention prune for cs_live_suggestions.
// Schedule: '45 3 * * *' (03:45 UTC) — staggered off Phase 22 slots 03:00/03:05/03:30.
// Row-only deletion: suggestions have no storage artefacts (unlike Phase 22 video assets).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req) => {
  // T-29-04-03: service_role auth gate (mirrors prune-expired-videos line 25)
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE)
  const report = { deleted: 0, errors: [] as string[] }

  // D-21: 7-day retention. Idempotent — safe to re-run (deletes nothing if already pruned).
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
  const { data: deleted, error: delErr } = await supabase
    .from('cs_live_suggestions')
    .delete()
    .lt('generated_at', cutoff)
    .select('id')
  if (delErr) {
    report.errors.push(`delete: ${delErr.message}`)
  } else {
    report.deleted = (deleted ?? []).length
  }

  console.log('[prune-suggestions]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})
