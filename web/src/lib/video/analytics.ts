// Phase 22 D-40 — server-side video analytics emission helper.
// Payloads NEVER include: stream_key, signed URLs, email addresses.

type BasePayload = { project_id: string; org_id: string; user_id?: string; portal_link_id?: string }

export type VideoEventPayload =
  | ({ event: 'video_upload_started'; asset_id: string; file_size_bytes: number; container: string; client_duration_estimate?: number; source_type?: 'upload' | 'drone' | 'fixed_camera' } & BasePayload)
  | ({ event: 'video_upload_failed'; asset_id: string; error_code: string; bytes_sent: number } & BasePayload)
  | ({ event: 'video_transcode_succeeded'; asset_id: string; duration_s: number; transcode_elapsed_ms: number } & BasePayload)
  | ({ event: 'video_transcode_failed'; asset_id: string; attempt_number: number; error_category: string } & BasePayload)
  | ({ event: 'live_stream_started'; source_id: string; mux_live_input_id: string } & BasePayload)
  | ({ event: 'live_stream_disconnected'; source_id: string; session_elapsed_s: number; reason: string } & BasePayload)
  | ({ event: 'video_playback_started'; asset_id: string; kind: 'live' | 'vod'; quality_rendition?: string; is_cellular?: boolean } & BasePayload)
  | ({ event: 'portal_video_view'; asset_id: string; portal_link_id: string } & BasePayload)

export function emitVideoEvent(payload: VideoEventPayload): void {
  // Structured log — downstream analytics pipeline can ingest from Vercel logs.
  // Defense-in-depth: redact any accidentally-included sensitive fields
  const safe = { ...payload } as Record<string, unknown>
  delete safe.stream_key
  delete safe.signed_url
  console.log('[analytics]', JSON.stringify(safe))
}
