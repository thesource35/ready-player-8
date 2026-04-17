// Phase 22-09 — POST /api/portal/video/playback-token
// Portal-scoped Mux JWT minting for live camera playback.
// Unauthenticated — portal_token is the only credential.
// D-15: Distinct portal JWT path (not the logged-in /api/video/mux/playback-token).
// D-22: Drone source_type always returns 403.
// D-34(a): Portal live is head-only (player enforces targetLiveWindow=0; server mints standard JWT).
// D-37: Rate-limited to 30 req/min/IP.
// D-39: No ownership check — portal_token scoping replaces user auth.

import { NextResponse } from 'next/server'
import { createServiceRoleClient } from '@/lib/supabase/server'
import { signPlaybackJWT } from '@/lib/video/mux'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { MUX_PLAYBACK_JWT_TTL_SECONDS } from '@/lib/video/types'
import { emitVideoEvent } from '@/lib/video/analytics'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function POST(req: Request) {
  // D-37: Rate limit 30 req/min/IP
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'portal:playback-token')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many playback requests. Wait a minute and try again.', true),
      {
        status: 429,
        headers: { 'Retry-After': String(Math.max(1, Math.ceil((rl.resetAt - Date.now()) / 1000))) },
      },
    )
  }

  // Parse body
  const body = (await req.json().catch(() => null)) as { portal_token?: string; source_id?: string } | null
  const portal_token = body?.portal_token
  const source_id = body?.source_id
  if (!portal_token || typeof portal_token !== 'string' || !source_id || typeof source_id !== 'string') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'portal_token and source_id required.', false),
      { status: 400 },
    )
  }

  // Service-role client — portal access bypasses RLS; token is the credential.
  const supabase = createServiceRoleClient()

  // Step 1: Look up portal link by token
  // Phase 20 uses cs_report_shared_links (link_type='portal') joined with cs_portal_config.
  // We query the link first, then join show_cameras from the config.
  const { data: link, error: linkErr } = await supabase
    .from('cs_report_shared_links')
    .select('id, project_id, is_revoked, expires_at, cs_portal_config(show_cameras)')
    .eq('token', portal_token)
    .eq('link_type', 'portal')
    .maybeSingle()

  if (linkErr) {
    console.error('[portal/video/playback-token] link lookup error:', linkErr.message)
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

  // Extract show_cameras from joined cs_portal_config
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const portalConfig = link.cs_portal_config as any
  const showCameras = Array.isArray(portalConfig)
    ? portalConfig[0]?.show_cameras === true
    : portalConfig?.show_cameras === true

  if (!showCameras) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Camera access is not enabled for this portal.', false),
      { status: 403 },
    )
  }

  // Step 2: Look up the video source; cross-check project_id
  const { data: source, error: srcErr } = await supabase
    .from('cs_video_sources')
    .select('id, project_id, org_id, kind, mux_playback_id')
    .eq('id', source_id)
    .maybeSingle()

  if (srcErr) {
    console.error('[portal/video/playback-token] source lookup error:', srcErr.message)
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, 'Source lookup failed.', true),
      { status: 500 },
    )
  }

  // T-22-09-01: Cross-check project_id — don't leak existence on mismatch
  if (!source || source.project_id !== link.project_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Not found or no access.', false),
      { status: 403 },
    )
  }

  // T-22-09-02: D-22 — Drone source_type always blocked from portal
  if (source.kind === 'drone') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Drone footage is not available via portal.', false),
      { status: 403 },
    )
  }

  if (!source.mux_playback_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, 'Source has no playback ID configured.', false),
      { status: 403 },
    )
  }

  // Step 3: Mint Mux JWT (D-14, TTL=300s)
  let token: string
  try {
    token = signPlaybackJWT(source.mux_playback_id, MUX_PLAYBACK_JWT_TTL_SECONDS)
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[portal/video/playback-token] signPlaybackJWT failed:', msg)
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, `Couldn't mint playback token. ${msg}.`, true),
      { status: 500 },
    )
  }

  // D-40: portal_video_view analytics event
  // Use the open live asset id if available, else stable "live:{source_id}" placeholder
  const { data: liveAsset } = await supabase
    .from('cs_video_assets')
    .select('id')
    .eq('source_id', source_id)
    .eq('kind', 'live')
    .is('ended_at', null)
    .limit(1)
    .maybeSingle()
  emitVideoEvent({
    event: 'portal_video_view',
    asset_id: liveAsset?.id ?? `live:${source_id}`,
    portal_link_id: link.id,
    project_id: source.project_id,
    org_id: source.org_id,
  })

  // Portal analytics table insert (fire-and-forget)
  void (async () => {
    try {
      await supabase
        .from('cs_portal_analytics')
        .insert({
          portal_config_id: Array.isArray(portalConfig) ? portalConfig[0]?.id : portalConfig?.id,
          link_id: link.id,
          section_viewed: 'video_live',
          metadata: { source_id, kind: 'live' },
        })
    } catch (err) {
      console.error('[portal/video/playback-token] analytics insert failed:', err)
    }
  })()

  return NextResponse.json(
    {
      token,
      ttl: MUX_PLAYBACK_JWT_TTL_SECONDS,
      playback_id: source.mux_playback_id,
    },
    { status: 200 },
  )
}
