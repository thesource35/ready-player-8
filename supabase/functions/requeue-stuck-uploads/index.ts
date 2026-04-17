// Phase 22 backstop: requeue VOD assets stuck in 'uploading' status for >5 minutes.
// Schedule: '*/5 * * * *' (every 5 minutes).
// Note: The SQL function requeue_stuck_uploads() in migration 006 can also be called
// directly via pg_cron without this edge function. This edge function is the HTTP
// alternative when the pg_cron -> SQL path is not preferred.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'

Deno.serve(async (req) => {
  const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  // T-22-10-01: Only pg_cron with service-role auth may invoke this function
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }

  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, SERVICE_ROLE)
  const cutoff = new Date(Date.now() - 5 * 60 * 1000).toISOString()

  const { data: stuck } = await supabase
    .from('cs_video_assets')
    .select('id, storage_path, org_id, project_id')
    .eq('kind', 'vod')
    .eq('status', 'uploading')
    .lt('created_at', cutoff)

  const WORKER_URL = Deno.env.get('FFMPEG_WORKER_URL')
  const WORKER_SECRET = Deno.env.get('WORKER_SHARED_SECRET')
  if (!WORKER_URL || !WORKER_SECRET) {
    return new Response(
      JSON.stringify({ skipped: 'worker not configured' }),
      { headers: { 'content-type': 'application/json' } }
    )
  }

  let requeued = 0
  const errors: string[] = []
  // T-22-10-02: Each row in its own try/catch — partial failure degrades gracefully
  for (const row of stuck ?? []) {
    try {
      const res = await fetch(WORKER_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Worker-Secret': WORKER_SECRET,
        },
        body: JSON.stringify({
          asset_id: row.id,
          storage_path: row.storage_path,
          org_id: row.org_id,
          project_id: row.project_id,
          requeue: true,
        }),
      })
      if (res.ok || res.status === 202) requeued++
    } catch (e) {
      errors.push(
        `asset_${row.id}: ${e instanceof Error ? e.message : e}`
      )
    }
  }

  const report = { requeued, errors }
  console.log('[requeue-stuck]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})
