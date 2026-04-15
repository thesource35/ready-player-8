// Phase 22 — POST /api/video/mux/create-live-input
// Camera-wizard step 1→2: mint Mux live input, insert cs_video_sources row atomically.
// D-28 soft cap (20/org), D-29 rollback-on-DB-fail, D-37 rate limit, D-39 auth required.

import { NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'
import { createLiveInput, deleteLiveInput } from '@/lib/video/mux'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { CAMERA_SOFT_CAP } from '@/lib/video/types'

export const runtime = 'nodejs' // Mux SDK requires Node runtime
export const dynamic = 'force-dynamic'

export async function POST(req: Request) {
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'mux:create-live-input')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many requests. Wait a minute and try again.', true),
      {
        status: 429,
        headers: { 'Retry-After': String(Math.max(1, Math.ceil((rl.resetAt - Date.now()) / 1000))) },
      },
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

  const body = (await req.json().catch(() => null)) as
    | { name?: string; location_label?: string; audio_enabled?: boolean; project_id?: string; org_id?: string }
    | null
  if (!body || typeof body !== 'object') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Bad request.', false),
      { status: 400 },
    )
  }

  const { name, location_label, audio_enabled, project_id, org_id } = body
  if (!name || typeof name !== 'string' || name.length < 1 || name.length > 128) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Name must be 1-128 chars.', false),
      { status: 400 },
    )
  }
  if (!project_id || !org_id) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'project_id and org_id required.', false),
      { status: 400 },
    )
  }

  // Soft cap check (D-28) — count existing non-archived fixed_camera sources in this org.
  // RLS ensures the user can only count cameras in orgs they belong to.
  const { count: cap_count, error: cap_err } = await supabase
    .from('cs_video_sources')
    .select('*', { count: 'exact', head: true })
    .eq('org_id', org_id)
    .eq('kind', 'fixed_camera')
    .neq('status', 'archived')
  if (cap_err) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxIngestFailed, cap_err.message, true),
      { status: 500 },
    )
  }
  if ((cap_count ?? 0) >= CAMERA_SOFT_CAP) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.CameraLimitReached,
        `Camera limit reached (${CAMERA_SOFT_CAP}). Archive an unused camera or contact support to raise the cap.`,
        false,
      ),
      { status: 403 },
    )
  }

  // Create the Mux live input.
  let mux_result
  try {
    mux_result = await createLiveInput({ audioEnabled: Boolean(audio_enabled) })
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[video] Mux createLiveInput failed:', msg)
    return NextResponse.json(
      videoError(VideoErrorCode.MuxIngestFailed, `Couldn't reach Mux to create the camera. ${msg}.`, true),
      { status: 502 },
    )
  }

  // Insert cs_video_sources row. On failure, compensating-delete the Mux resource (D-29).
  const { data: row, error: ins_err } = await supabase
    .from('cs_video_sources')
    .insert({
      org_id,
      project_id,
      kind: 'fixed_camera',
      name,
      location_label: location_label ?? null,
      mux_live_input_id: mux_result.live_input_id,
      mux_playback_id: mux_result.playback_id,
      audio_enabled: Boolean(audio_enabled),
      status: 'idle',
      created_by: user.id,
    })
    .select('id')
    .single()

  if (ins_err || !row) {
    // D-29 compensating delete — try to roll back the Mux live input.
    console.error('[video] DB insert failed; rolling back Mux live_input:', ins_err?.message)
    try {
      await deleteLiveInput(mux_result.live_input_id)
    } catch (rbErr) {
      // Orphaned Mux resource — log loudly; retention cron cannot delete this because
      // no DB row exists. Ops should manually prune via Mux dashboard + search by created_at.
      console.error('[video] Mux rollback ALSO FAILED — orphaned live_input', mux_result.live_input_id, rbErr)
    }
    return NextResponse.json(
      videoError(
        VideoErrorCode.MuxIngestFailed,
        `Couldn't save camera. ${ins_err?.message ?? 'database error'}.`,
        true,
      ),
      { status: 500 },
    )
  }

  // Stream key returned ONCE. Never stored in DB (D-02), never echoed by any GET route.
  return NextResponse.json(
    {
      source_id: row.id,
      live_input_id: mux_result.live_input_id,
      stream_key: mux_result.stream_key,
      playback_id: mux_result.playback_id,
      rtmp_url: mux_result.rtmp_url,
      srt_url: mux_result.srt_url,
    },
    { status: 201 },
  )
}
