// Phase 22 — Mux SDK singleton + live-input CRUD + playback JWT signing helpers.
// All calls happen server-side only; Mux tokens are never shipped to the client.
// iOS mirrors these shapes via SupabaseService + AppError.muxIngestFailed / muxDeleteFailed.

import Mux from '@mux/mux-node'
import jwt from 'jsonwebtoken'
import { MUX_PLAYBACK_JWT_TTL_SECONDS } from '@/lib/video/types'

// Module-level singleton. We do NOT throw on missing env here — routes read process.env
// directly and fail with a muxIngestFailed response. This keeps `import` side-effect free
// so unit tests / typecheck don't need the secrets.
const tokenId = process.env.MUX_TOKEN_ID ?? ''
const tokenSecret = process.env.MUX_TOKEN_SECRET ?? ''

export const mux = new Mux({ tokenId, tokenSecret })

export type CreateLiveInputResult = {
  live_input_id: string
  stream_key: string
  playback_id: string
  rtmp_url: string
  srt_url: string
}

/**
 * Create a Mux live input with LL-HLS + signed DVR archive.
 * D-03 reconnect_window=60, D-04 latency_mode='low', D-14 signed playback.
 */
export async function createLiveInput(opts: { audioEnabled: boolean }): Promise<CreateLiveInputResult> {
  const liveStream = await mux.video.liveStreams.create({
    latency_mode: 'low',
    reconnect_window: 60,
    playback_policy: ['signed'],
    new_asset_settings: { playback_policies: ['signed'] },
    max_continuous_duration: 43200, // 12h max single session
    // D-35: when audioEnabled=false, callers should additionally ensure encoder drops audio.
    // The Mux SDK does not expose a "reject audio" flag on live_inputs — this is enforced
    // client-side in the encoder and server-side at the worker level for VOD.
    audio_only: false,
  })

  const playbackId = liveStream.playback_ids?.[0]?.id
  if (!liveStream.id || !liveStream.stream_key || !playbackId) {
    throw new Error('Mux live input response missing id/stream_key/playback_id')
  }

  // Silence lint warning on unused opts when Mux SDK doesn't accept an audio flag directly.
  void opts

  return {
    live_input_id: liveStream.id,
    stream_key: liveStream.stream_key,
    playback_id: playbackId,
    rtmp_url: 'rtmps://global-live.mux.com:443/app',
    srt_url: 'srt://global-live.mux.com:6001',
  }
}

/**
 * Delete a Mux live input. Treats Mux 404 as already-deleted (idempotent).
 * Re-throws other errors for caller to map to AppError.muxDeleteFailed.
 */
export async function deleteLiveInput(liveInputId: string): Promise<void> {
  try {
    await mux.video.liveStreams.delete(liveInputId)
  } catch (err) {
    // @mux/mux-node errors expose a `status` field on the thrown error object
    const status = (err as { status?: number })?.status
    if (status === 404) return // already deleted — idempotent
    throw err
  }
}

/**
 * Delete an archived Mux asset. Used by the retention cron (plan 22-10) after
 * cs_video_assets rows past retention_expires_at are pruned.
 */
export async function deleteMuxAsset(assetId: string): Promise<void> {
  try {
    await mux.video.assets.delete(assetId)
  } catch (err) {
    const status = (err as { status?: number })?.status
    if (status === 404) return
    throw err
  }
}

/**
 * Sign a short-lived Mux playback JWT (RS256) bound to a single playback_id.
 * D-14: TTL defaults to 300s (5 minutes).
 *
 * Claims shape per https://docs.mux.com/guides/secure-video-playback:
 *   { sub: <playback_id>, aud: 'v', exp: <unix_sec>, kid: <signing_key_id> }
 *
 * Private key env var may be raw PEM or base64-encoded PEM. Auto-detect by the
 * leading 'LS0tLS1' base64 marker for '-----' (PEM header).
 */
export function signPlaybackJWT(playbackId: string, ttlSeconds = MUX_PLAYBACK_JWT_TTL_SECONDS): string {
  const kid = process.env.MUX_SIGNING_KEY_ID
  const keyRaw = process.env.MUX_SIGNING_KEY_PRIVATE
  if (!kid || !keyRaw) {
    throw new Error('MUX_SIGNING_KEY_ID / MUX_SIGNING_KEY_PRIVATE not configured')
  }

  // Detect base64-encoded PEM ("LS0tLS1" decodes to "-----" — the PEM header marker).
  const key = keyRaw.startsWith('LS0tLS1')
    ? Buffer.from(keyRaw, 'base64').toString('utf-8')
    : keyRaw

  const exp = Math.floor(Date.now() / 1000) + ttlSeconds

  return jwt.sign(
    { sub: playbackId, aud: 'v', exp },
    key,
    { algorithm: 'RS256', keyid: kid },
  )
}
