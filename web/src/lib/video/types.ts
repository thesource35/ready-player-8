// Phase 22 — Video model types, wire-compatible with Supabase row shape.
// Swift counterparts live in "ready player 8/Video/VideoModels.swift".
// Field names are snake_case (matching DB columns); consumers may remap if they prefer camelCase.

export type VideoKind = 'fixed_camera' | 'drone' | 'upload'

// VideoSourceType mirrors cs_video_assets.source_type — same 3 values as VideoKind
// because Phase 29 filters assets by source_type (D-08).
export type VideoSourceType = 'fixed_camera' | 'drone' | 'upload'

export type VideoAssetKind = 'live' | 'vod'

export type VideoSourceStatus = 'idle' | 'active' | 'offline' | 'archived'

export type VideoAssetStatus = 'uploading' | 'transcoding' | 'ready' | 'failed'

export type VideoDefaultQuality = 'auto' | 'ld' | 'sd' | 'hd'

export type VideoSource = {
  id: string
  org_id: string
  project_id: string
  kind: VideoKind
  name: string
  location_label: string | null
  mux_live_input_id: string | null
  mux_playback_id: string | null
  audio_enabled: boolean
  status: VideoSourceStatus
  last_active_at: string | null
  created_at: string
  created_by: string
}

export type VideoAsset = {
  id: string
  source_id: string
  org_id: string
  project_id: string
  source_type: VideoSourceType
  kind: VideoAssetKind
  storage_path: string | null
  mux_playback_id: string | null
  mux_asset_id: string | null
  status: VideoAssetStatus
  started_at: string
  ended_at: string | null
  duration_s: number | null
  retention_expires_at: string | null
  name: string | null
  portal_visible: boolean
  last_error: string | null
  created_at: string
  created_by: string
}

export type VideoWebhookEvent = {
  event_id: string
  event_type: string
  received_at: string
  processed_at: string | null
  payload_hash: string
  processing_error: string | null
}

// D-28 soft cap values
export const CAMERA_SOFT_CAP = 20
export const CAMERA_WARNING_THRESHOLD = 16 // 80% of cap

// D-31 upload constraints
export const MAX_UPLOAD_SIZE_BYTES = 2 * 1024 * 1024 * 1024 // 2 GB
export const MAX_UPLOAD_DURATION_SECONDS = 60 * 60 // 60 min
export const ALLOWED_UPLOAD_CONTAINERS = ['mp4', 'mov'] as const
export const ALLOWED_UPLOAD_MIME_TYPES = ['video/mp4', 'video/quicktime', 'video/x-m4v'] as const

// D-14 / D-37 TTLs and rate limits
export const MUX_PLAYBACK_JWT_TTL_SECONDS = 300 // 5 min
export const VOD_SIGNED_URL_TTL_SECONDS = 3600 // 1 hour
export const PLAYBACK_TOKEN_RATE_LIMIT_PER_MIN = 30
