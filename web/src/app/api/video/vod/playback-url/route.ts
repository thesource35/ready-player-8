// Phase 22 — GET /api/video/vod/playback-url?asset_id=...
// Serves a rewritten HLS manifest where every .ts/.m4s segment is a presigned Supabase URL
// with 1h TTL (D-14). Per 22-RESEARCH.md Pattern 3: Supabase cannot sign a "directory" and
// HLS manifests reference segments relatively, so we fetch the manifest, batch-sign siblings,
// and inline-rewrite every segment URI. Response Content-Type is application/vnd.apple.mpegurl.
//
// Cache-Control: private, max-age=60, no-store — signed URLs are per-user (D-14, D-34(b)).

import { createServerSupabase } from '@/lib/supabase/server'
import { signHlsManifest } from '@/lib/video/hls-sign'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { VOD_SIGNED_URL_TTL_SECONDS } from '@/lib/video/types'
import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function GET(req: Request) {
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'vod:playback-url')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many requests. Wait a minute and try again.', true),
      {
        status: 429,
        headers: { 'Retry-After': String(Math.max(1, Math.ceil((rl.resetAt - Date.now()) / 1000))) },
      },
    )
  }

  const url = new URL(req.url)
  const asset_id = url.searchParams.get('asset_id')
  if (!asset_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'asset_id required.', false),
      { status: 400 },
    )
  }

  const supabase = await createServerSupabase()
  if (!supabase) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxIngestFailed, 'Database not configured.', false),
      { status: 503 },
    )
  }

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Authentication required.', false),
      { status: 401 },
    )
  }

  // RLS enforces org scope. If user isn't in owning org, .maybeSingle() returns null -> 404.
  const { data: row, error: rowErr } = await supabase
    .from('cs_video_assets')
    .select('id, org_id, project_id, kind, status')
    .eq('id', asset_id)
    .maybeSingle()
  if (rowErr) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxIngestFailed, rowErr.message, true),
      { status: 500 },
    )
  }
  if (!row || row.kind !== 'vod') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Not found or no access.', false),
      { status: 404 },
    )
  }
  if (row.status !== 'ready') {
    // Client polls; re-hit after a few seconds.
    return NextResponse.json(
      {
        ...videoError(
          VideoErrorCode.TranscodeTimeout,
          `Clip not ready yet (status=${row.status}). Try again shortly.`,
          true,
        ),
        status: row.status,
      },
      { status: 409 },
    )
  }

  const hlsDir = `${row.org_id}/${row.project_id}/${row.id}/hls`
  const result = await signHlsManifest(supabase, hlsDir, VOD_SIGNED_URL_TTL_SECONDS)
  if ('error' in result) {
    console.error('[video] signHlsManifest failed for asset', row.id, result.error)
    return NextResponse.json(
      videoError(
        VideoErrorCode.MuxIngestFailed,
        `Couldn't sign HLS manifest. ${result.error}.`,
        true,
      ),
      { status: 502 },
    )
  }

  return new Response(result.manifestText, {
    status: 200,
    headers: {
      'Content-Type': 'application/vnd.apple.mpegurl',
      // Signed URLs are per-user and short-lived; never cache on shared CDN. no-store honors D-34(b).
      'Cache-Control': 'private, max-age=60, no-store',
    },
  })
}
