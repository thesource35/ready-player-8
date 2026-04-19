// Phase 22 — POST /api/video/vod/upload-url
// Register a resumable upload: validate size/duration/container (D-31), lazy-create
// the per-project "Uploads" video source (D-24), insert cs_video_assets row with
// status='uploading', and return the Supabase tus endpoint + auth token for the client
// to stream chunks. The DB INSERT fires the pg_net trigger (22-01 Task 3) which POSTs
// to the ffmpeg worker; the worker then downloads the raw upload and produces HLS.

import { NextResponse } from 'next/server'
import { z } from 'zod'
import { createServerSupabase } from '@/lib/supabase/server'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import {
  MAX_UPLOAD_SIZE_BYTES,
  MAX_UPLOAD_DURATION_SECONDS,
  ALLOWED_UPLOAD_CONTAINERS,
} from '@/lib/video/types'
import { emitVideoEvent } from '@/lib/video/analytics'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

type UploadUrlBody = {
  project_id?: string
  org_id?: string
  name?: string
  file_size_bytes?: number
  duration_s?: number
  container?: string
  source_type?: string // Phase 29 LIVE-01 D-11 — 'upload' | 'drone' (enum-validated below)
}

export async function POST(req: Request) {
  const ip = (req.headers.get('x-forwarded-for')?.split(',')[0] ?? 'unknown').trim()
  const rl = await checkVideoRateLimit(ip, 'vod:upload-url')
  if (!rl.allowed) {
    return NextResponse.json(
      videoError(VideoErrorCode.RateLimited, 'Too many upload requests. Wait a minute and try again.', true),
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
    error: authErr,
  } = await supabase.auth.getUser()
  if (authErr || !user) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Authentication required.', false),
      { status: 401 },
    )
  }

  // Session token — required for the client to authenticate the tus upload.
  const {
    data: { session },
  } = await supabase.auth.getSession()
  if (!session?.access_token) {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'No active session.', false),
      { status: 401 },
    )
  }

  const body = (await req.json().catch(() => null)) as UploadUrlBody | null
  if (!body || typeof body !== 'object') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'Bad request.', false),
      { status: 400 },
    )
  }

  const { project_id, org_id, name, file_size_bytes, duration_s, container, source_type } = body

  // Phase 29 LIVE-01 / T-29-02-01: validate source_type enum (defaults to 'upload' for
  // Phase 22 backward compat). Only 'upload' and 'drone' are accepted from user-facing
  // routes; 'fixed_camera' is server-side only (live inputs).
  const SourceTypeSchema = z.enum(['upload', 'drone'])
  const sourceTypeParse = SourceTypeSchema.safeParse(source_type ?? 'upload')
  if (!sourceTypeParse.success) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.PermissionDenied,
        'Invalid source_type. Allowed: upload, drone.',
        false,
      ),
      { status: 400 },
    )
  }
  const sourceType: 'upload' | 'drone' = sourceTypeParse.data

  if (!project_id || !org_id || typeof project_id !== 'string' || typeof org_id !== 'string') {
    return NextResponse.json(
      videoError(VideoErrorCode.PermissionDenied, 'project_id and org_id required.', false),
      { status: 400 },
    )
  }

  // D-31: 2GB file-size cap (server-side defense; client pre-checks too).
  if (typeof file_size_bytes !== 'number' || file_size_bytes <= 0) {
    return NextResponse.json(
      videoError(VideoErrorCode.ClipTooLarge, 'file_size_bytes required.', false),
      { status: 400 },
    )
  }
  if (file_size_bytes > MAX_UPLOAD_SIZE_BYTES) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.ClipTooLarge,
        `File too large. Max ${MAX_UPLOAD_SIZE_BYTES / (1024 * 1024 * 1024)} GB.`,
        false,
      ),
      { status: 413 },
    )
  }

  // D-31: 60-min duration cap. Optional — some uploaders may not probe first;
  // the worker re-validates with ffprobe and rejects then.
  if (typeof duration_s === 'number' && duration_s > MAX_UPLOAD_DURATION_SECONDS) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.ClipTooLong,
        `Clip too long. Max ${MAX_UPLOAD_DURATION_SECONDS / 60} minutes.`,
        false,
      ),
      { status: 413 },
    )
  }

  // D-31: container allowlist (mp4, mov).
  if (
    !container ||
    typeof container !== 'string' ||
    !(ALLOWED_UPLOAD_CONTAINERS as readonly string[]).includes(container.toLowerCase())
  ) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.UnsupportedVideoFormat,
        `Unsupported container. Allowed: ${ALLOWED_UPLOAD_CONTAINERS.join(', ')}.`,
        false,
      ),
      { status: 400 },
    )
  }
  const containerLower = container.toLowerCase()

  // D-24: lazy-create a synthetic "Uploads" video source per project.
  // Every upload belongs to a source (so the UI can group clips); we create one on first upload.
  let uploadSource: { id: string } | null = null
  {
    const { data: existing, error: srcErr } = await supabase
      .from('cs_video_sources')
      .select('id')
      .eq('org_id', org_id)
      .eq('project_id', project_id)
      .eq('kind', 'upload')
      .limit(1)
      .maybeSingle()
    if (srcErr) {
      return NextResponse.json(
        videoError(VideoErrorCode.MuxIngestFailed, srcErr.message, true),
        { status: 500 },
      )
    }
    if (existing) {
      uploadSource = { id: existing.id }
    } else {
      // synthetic upload source (D-24) — created lazily, one per project.
      const { data: created, error: insSrcErr } = await supabase
        .from('cs_video_sources')
        .insert({
          org_id,
          project_id,
          kind: 'upload',
          name: 'Uploads',
          audio_enabled: true,
          status: 'idle',
          created_by: user.id,
        })
        .select('id')
        .single()
      if (insSrcErr || !created) {
        return NextResponse.json(
          videoError(
            VideoErrorCode.MuxIngestFailed,
            `Couldn't create upload source. ${insSrcErr?.message ?? 'database error'}.`,
            true,
          ),
          { status: 500 },
        )
      }
      uploadSource = { id: created.id }
    }
  }

  // Insert the cs_video_assets row. DB default gen_random_uuid() fills id; we then use it
  // to build the storage path `<org>/<project>/<asset>/raw.<container>` (22-01 path convention).
  // Worker picks up this row via the pg_net trigger and downloads from storage_path.
  const { data: asset, error: assetErr } = await supabase
    .from('cs_video_assets')
    .insert({
      source_id: uploadSource.id,
      org_id,
      project_id,
      source_type: sourceType, // Phase 29 LIVE-01 — was hardcoded 'upload', now validated enum
      kind: 'vod',
      status: 'uploading',
      name: name && typeof name === 'string' ? name.slice(0, 128) : null,
      portal_visible: false,
      started_at: new Date().toISOString(),
      created_by: user.id,
    })
    .select('id')
    .single()

  if (assetErr || !asset) {
    return NextResponse.json(
      videoError(
        VideoErrorCode.MuxIngestFailed,
        `Couldn't create video asset row. ${assetErr?.message ?? 'database error'}.`,
        true,
      ),
      { status: 500 },
    )
  }

  // Patch storage_path now that we have the asset id.
  const storagePath = `${org_id}/${project_id}/${asset.id}/raw.${containerLower}`
  const { error: patchErr } = await supabase
    .from('cs_video_assets')
    .update({ storage_path: storagePath })
    .eq('id', asset.id)
  if (patchErr) {
    console.error('[video] failed to patch storage_path after insert:', patchErr.message)
    // non-fatal — client can still upload; worker will pattern-match on trigger payload
  }

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
  if (!supabaseUrl) {
    return NextResponse.json(
      videoError(VideoErrorCode.MuxIngestFailed, 'Supabase URL not configured.', false),
      { status: 503 },
    )
  }

  // D-40 analytics: video_upload_started (T-29-02-03: include source_type for drone traceability)
  emitVideoEvent({
    event: 'video_upload_started',
    asset_id: asset.id,
    file_size_bytes: file_size_bytes,
    container: containerLower,
    client_duration_estimate: typeof duration_s === 'number' ? duration_s : undefined,
    project_id,
    org_id,
    user_id: user.id,
    source_type: sourceType,
  })

  // Client will POST chunks to this endpoint with Bearer {auth_token} and tus metadata
  // { bucketName: 'videos', objectName: storagePath, contentType: 'video/...' }.
  return NextResponse.json(
    {
      asset_id: asset.id,
      bucket_name: 'videos',
      object_name: storagePath,
      upload_url: `${supabaseUrl}/storage/v1/upload/resumable`,
      auth_token: session.access_token,
    },
    { status: 201 },
  )
}
