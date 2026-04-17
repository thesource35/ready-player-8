// Phase 22-09 — GET /api/portal/video/playback-url?portal_token=X&asset_id=Y
// Portal-scoped signed HLS manifest for VOD clips.
// Unauthenticated — portal_token is the only credential.
// D-22: Drone source_type always returns 403.
// D-34(b): Streaming-only — Cache-Control: private, max-age=0, no-store; no download affordance.
// D-37: Rate-limited to 30 req/min/IP.

import { createServiceRoleClient } from '@/lib/supabase/server'
import { signHlsManifest } from '@/lib/video/hls-sign'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { VOD_SIGNED_URL_TTL_SECONDS } from '@/lib/video/types'
import { NextResponse } from 'next/server'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function GET(req: Request) {
  // D-37: Rate limit 30 req/min/IP
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'portal:playback-url')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many requests. Wait a minute and try again.', true),
      {
        status: 429,
        headers: { 'Retry-After': String(Math.max(1, Math.ceil((rl.resetAt - Date.now()) / 1000))) },
      },
    )
  }

  // Parse query params
  const url = new URL(req.url)
  const portal_token = url.searchParams.get('portal_token')
  const asset_id = url.searchParams.get('asset_id')
  if (!portal_token || !asset_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'portal_token and asset_id required.', false),
      { status: 400 },
    )
  }

  // Service-role client — portal access bypasses RLS; token is the credential.
  const supabase = createServiceRoleClient()

  // Step 1: Look up portal link by token
  const { data: link, error: linkErr } = await supabase
    .from('cs_report_shared_links')
    .select('id, project_id, is_revoked, expires_at')
    .eq('token', portal_token)
    .eq('link_type', 'portal')
    .maybeSingle()

  if (linkErr) {
    console.error('[portal/video/playback-url] link lookup error:', linkErr.message)
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, 'Portal lookup failed.', true),
      { status: 500 },
    )
  }

  // T-22-09-08: Check link exists, not revoked, not expired
  if (!link) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Portal link not found.', false),
      { status: 410 },
    )
  }
  if (link.is_revoked) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'This portal link has been revoked.', false),
      { status: 410 },
    )
  }
  if (link.expires_at && new Date(link.expires_at as string) < new Date()) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'This portal link has expired.', false),
      { status: 410 },
    )
  }

  // Step 2: Look up the video asset; cross-check project_id
  const { data: asset, error: assetErr } = await supabase
    .from('cs_video_assets')
    .select('id, org_id, project_id, source_id, source_type, kind, status, portal_visible')
    .eq('id', asset_id)
    .maybeSingle()

  if (assetErr) {
    console.error('[portal/video/playback-url] asset lookup error:', assetErr.message)
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, 'Asset lookup failed.', true),
      { status: 500 },
    )
  }

  // T-22-09-01: Cross-check project_id
  if (!asset || asset.project_id !== link.project_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Not found or no access.', false),
      { status: 403 },
    )
  }

  // T-22-09-02: D-22 — Drone source_type always blocked from portal
  if (asset.source_type === 'drone') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Drone footage is not available via portal.', false),
      { status: 403 },
    )
  }

  // Live assets should use the playback-token route, not this one
  if (asset.kind === 'live') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Live assets use the playback-token endpoint.', false),
      { status: 403 },
    )
  }

  // T-22-09-03: VOD must have portal_visible=true
  if (asset.kind === 'vod' && !asset.portal_visible) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'This clip is not shared via portal.', false),
      { status: 403 },
    )
  }

  // Must be ready (same as logged-in path)
  if (asset.status !== 'ready') {
    return NextResponse.json(
      {
        ...videoError(
          VideoErrorCode.TranscodeTimeout,
          `Clip not ready yet (status=${asset.status}). Try again shortly.`,
          true,
        ),
        status: asset.status,
      },
      { status: 409 },
    )
  }

  // Step 3: Sign the HLS manifest (1h TTL — D-14)
  const hlsDir = `${asset.org_id}/${asset.project_id}/${asset.id}/hls`
  const result = await signHlsManifest(supabase, hlsDir, VOD_SIGNED_URL_TTL_SECONDS)
  if ('error' in result) {
    console.error('[portal/video/playback-url] signHlsManifest failed for asset', asset.id, result.error)
    return NextResponse.json(
      videoError(
        VideoErrorCode.PlaybackTokenMintFailed,
        `Couldn't sign HLS manifest. ${result.error}.`,
        true,
      ),
      { status: 502 },
    )
  }

  // D-40: Analytics event (fire-and-forget)
  void (async () => {
    try {
      await supabase
        .from('cs_portal_analytics')
        .insert({
          link_id: link.id,
          section_viewed: 'video_vod',
          metadata: { asset_id, source_id: asset.source_id, kind: 'vod' },
        })
    } catch (err) {
      console.error('[portal/video/playback-url] analytics insert failed:', err)
    }
  })()

  // D-34(b): Streaming-only — no-store prevents any caching of signed URLs
  return new Response(result.manifestText, {
    status: 200,
    headers: {
      'Content-Type': 'application/vnd.apple.mpegurl',
      'Cache-Control': 'private, max-age=0, no-store',
    },
  })
}
