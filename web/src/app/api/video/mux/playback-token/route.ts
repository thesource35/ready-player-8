// Phase 22 — POST /api/video/mux/playback-token
// Mint a short-lived (300s) Mux playback JWT bound to a source's mux_playback_id.
// D-14 TTL, D-37 rate limit, RLS enforces org scope (no explicit check needed).

import { NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'
import { signPlaybackJWT } from '@/lib/video/mux'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { MUX_PLAYBACK_JWT_TTL_SECONDS } from '@/lib/video/types'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function POST(req: Request) {
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'mux:playback-token')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many playback requests. Wait a minute and try again.', true),
      {
        status: 429,
        headers: { 'Retry-After': String(Math.max(1, Math.ceil((rl.resetAt - Date.now()) / 1000))) },
      },
    )
  }

  const supabase = await createServerSupabase()
  if (!supabase) {
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, 'Database not configured.', false),
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

  const body = (await req.json().catch(() => null)) as { source_id?: string } | null
  const source_id = body?.source_id
  if (!source_id || typeof source_id !== 'string') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'source_id required.', false),
      { status: 400 },
    )
  }

  // RLS transparently enforces org scope — if the user isn't in the owning org, no row returns.
  const { data: src, error: src_err } = await supabase
    .from('cs_video_sources')
    .select('id, mux_playback_id')
    .eq('id', source_id)
    .maybeSingle()
  if (src_err) {
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, src_err.message, true),
      { status: 500 },
    )
  }
  if (!src || !src.mux_playback_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Not found or no access.', false),
      { status: 403 },
    )
  }

  // Sign the JWT (D-14 TTL = 300s).
  let token: string
  try {
    token = signPlaybackJWT(src.mux_playback_id, MUX_PLAYBACK_JWT_TTL_SECONDS)
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[video] signPlaybackJWT failed:', msg)
    return NextResponse.json(
      videoError(VideoErrorCode.PlaybackTokenMintFailed, `Couldn't mint playback token. ${msg}.`, true),
      { status: 500 },
    )
  }

  return NextResponse.json(
    {
      token,
      ttl: MUX_PLAYBACK_JWT_TTL_SECONDS,
      playback_id: src.mux_playback_id,
    },
    { status: 200 },
  )
}
