// Phase 22 — DELETE /api/video/mux/delete-live-input
// D-39: owner/admin role-gated. D-29: Mux delete FIRST; on 5xx keep DB row (502); on 404 proceed.

import { NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'
import { deleteLiveInput } from '@/lib/video/mux'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function DELETE(req: Request) {
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'mux:delete-live-input')
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
      videoError(VideoErrorCode.MuxDeleteFailed, 'Database not configured.', false),
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

  // Load the source row (RLS-scoped to user's orgs). Missing row → 403 (don't leak existence).
  const { data: src, error: src_err } = await supabase
    .from('cs_video_sources')
    .select('id, org_id, mux_live_input_id')
    .eq('id', source_id)
    .maybeSingle()
  if (src_err) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxDeleteFailed, src_err.message, true),
      { status: 500 },
    )
  }
  if (!src) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Not found or no access.', false),
      { status: 403 },
    )
  }

  // D-39: require owner or admin role in the source's org.
  const { data: role_row, error: role_err } = await supabase
    .from('user_orgs')
    .select('role')
    .eq('user_id', user.id)
    .eq('org_id', src.org_id)
    .maybeSingle()
  if (role_err) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxDeleteFailed, role_err.message, true),
      { status: 500 },
    )
  }
  const role = role_row?.role as string | undefined
  if (role !== 'owner' && role !== 'admin') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Only owner or admin can delete a camera.', false),
      { status: 403 },
    )
  }

  // D-29: delete the Mux live input FIRST. If Mux succeeds (or 404), proceed to DB delete.
  // If Mux returns 5xx, keep the DB row and 502 so the operator can retry.
  if (src.mux_live_input_id) {
    try {
      await deleteLiveInput(src.mux_live_input_id)
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'unknown'
      const status = (err as { status?: number })?.status
      console.error('[video] Mux deleteLiveInput failed:', status, msg)
      // deleteLiveInput already swallows 404 — reaching here means 5xx/4xx other than 404.
      return NextResponse.json(
        videoError(VideoErrorCode.MuxDeleteFailed, `Couldn't delete Mux live input. ${msg}.`, true),
        { status: 502 },
      )
    }
  }

  // Now delete the DB row. ON DELETE CASCADE drops any cs_video_assets children.
  const { error: del_err } = await supabase
    .from('cs_video_sources')
    .delete()
    .eq('id', source_id)
  if (del_err) {
    // Mux already deleted but DB delete failed — orphaned DB row with no Mux resource.
    // Retention cron can clean this up (row points to a nonexistent Mux id; next mux call will 404).
    console.error('[video] DB delete failed after Mux delete succeeded:', del_err.message)
    return NextResponse.json(
      videoError(VideoErrorCode.MuxDeleteFailed, `Couldn't remove camera row. ${del_err.message}.`, true),
      { status: 500 },
    )
  }

  return NextResponse.json({ ok: true }, { status: 200 })
}
