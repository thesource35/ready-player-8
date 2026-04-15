// Phase 22 — Wire-portable error codes. iOS maps these back to AppError cases via the
// { error, code } JSON body returned by every /api/video/* route.

export const VideoErrorCode = {
  UnsupportedVideoFormat: 'video.unsupported_format',
  ClipTooLong: 'video.clip_too_long',
  ClipTooLarge: 'video.clip_too_large',
  AudioConsentRequired: 'video.audio_consent_required',
  TranscodeTimeout: 'video.transcode_timeout',
  MuxIngestFailed: 'video.mux_ingest_failed',
  MuxDeleteFailed: 'video.mux_delete_failed',
  CameraLimitReached: 'video.camera_limit_reached',
  WebhookSignatureInvalid: 'video.webhook_signature_invalid',
  PermissionDenied: 'video.permission_denied',
  RateLimited: 'video.rate_limited',
  PlaybackTokenMintFailed: 'video.playback_token_mint_failed',
} as const

export type VideoErrorCodeValue = typeof VideoErrorCode[keyof typeof VideoErrorCode]

export type VideoErrorBody = {
  error: string // human-facing copy
  code: VideoErrorCodeValue
  retryable: boolean
}

export function videoError(
  code: VideoErrorCodeValue,
  message: string,
  retryable = false,
): VideoErrorBody {
  return { error: message, code, retryable }
}
