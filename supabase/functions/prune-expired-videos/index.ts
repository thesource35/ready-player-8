// Phase 22: daily VOD (30d) + live (24h after ended_at) retention prune.
// Schedule: '0 3 * * *' (03:00 UTC) per RESEARCH.md Retention Strategy.
// Also deletes corresponding Mux archive assets for live kind (prevents bill accumulation).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.101.1'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SERVICE_ROLE = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const MUX_TOKEN_ID = Deno.env.get('MUX_TOKEN_ID')
const MUX_TOKEN_SECRET = Deno.env.get('MUX_TOKEN_SECRET')

async function deleteMuxAsset(assetId: string): Promise<boolean> {
  if (!MUX_TOKEN_ID || !MUX_TOKEN_SECRET) return false
  const auth = btoa(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`)
  const res = await fetch(`https://api.mux.com/video/v1/assets/${assetId}`, {
    method: 'DELETE',
    headers: { Authorization: `Basic ${auth}` },
  })
  if (res.status === 404) return true // already gone
  return res.ok
}

Deno.serve(async (req) => {
  // T-22-10-01: Only pg_cron with service-role auth may invoke this function
  if (req.headers.get('authorization') !== `Bearer ${SERVICE_ROLE}`) {
    return new Response('Unauthorized', { status: 401 })
  }
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE)

  const report = { vod_deleted: 0, live_deleted: 0, mux_deleted: 0, errors: [] as string[] }

  // D-09 VOD retention: rows where retention_expires_at has passed
  const { data: expiredVod, error: vodErr } = await supabase
    .from('cs_video_assets')
    .select('id, org_id, project_id, storage_path')
    .eq('kind', 'vod')
    .lt('retention_expires_at', new Date().toISOString())
  if (vodErr) report.errors.push(`vod_select: ${vodErr.message}`)

  // T-22-10-02: Each row in its own try/catch — partial failure degrades gracefully
  for (const row of expiredVod ?? []) {
    try {
      const hlsDir = `${row.org_id}/${row.project_id}/${row.id}`
      // list + remove all storage objects under this asset
      const { data: files } = await supabase.storage
        .from('videos')
        .list(hlsDir, { limit: 1000 })
      const allPaths = [
        ...(files ?? []).map((f: { name: string }) => `${hlsDir}/${f.name}`),
      ]
      // also include nested hls/ subdirectory
      const { data: hlsFiles } = await supabase.storage
        .from('videos')
        .list(`${hlsDir}/hls`, { limit: 1000 })
      for (const f of hlsFiles ?? []) allPaths.push(`${hlsDir}/hls/${f.name}`)
      if (allPaths.length > 0) {
        await supabase.storage.from('videos').remove(allPaths)
      }
      await supabase.from('cs_video_assets').delete().eq('id', row.id)
      report.vod_deleted++
    } catch (e) {
      report.errors.push(`vod_row_${row.id}: ${e instanceof Error ? e.message : e}`)
    }
  }

  // D-10 live retention: 24h after ended_at, delete row + Mux archive asset
  const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
  const { data: expiredLive, error: liveErr } = await supabase
    .from('cs_video_assets')
    .select('id, mux_asset_id')
    .eq('kind', 'live')
    .not('ended_at', 'is', null)
    .lt('ended_at', cutoff)
  if (liveErr) report.errors.push(`live_select: ${liveErr.message}`)

  for (const row of expiredLive ?? []) {
    try {
      if (row.mux_asset_id) {
        const ok = await deleteMuxAsset(row.mux_asset_id)
        if (ok) report.mux_deleted++
        else report.errors.push(`mux_delete_${row.mux_asset_id}`)
      }
      await supabase.from('cs_video_assets').delete().eq('id', row.id)
      report.live_deleted++
    } catch (e) {
      report.errors.push(`live_row_${row.id}: ${e instanceof Error ? e.message : e}`)
    }
  }

  // T-22-10-03: Log report (no credentials), captured by cron.job_run_details
  console.log('[retention]', JSON.stringify(report))
  return new Response(JSON.stringify(report), {
    headers: { 'content-type': 'application/json' },
  })
})
