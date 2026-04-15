// Phase 22 — Mux webhook signature verifier + dedupe helper.
// D-32: HMAC-SHA256 over `{timestamp}.{rawBody}`; constant-time compare; replay window 5 min.
// Dedupe uses cs_video_webhook_events PK on event_id (service role only — RLS default-deny).

import crypto from 'crypto'
import type { SupabaseClient } from '@supabase/supabase-js'

/**
 * Parse the Mux-Signature header (format: `t={unix-ts},v1={hex-hmac}[,v1={hex-hmac}]*`)
 * and verify the HMAC-SHA256 of `{ts}.{rawBody}` against the shared secret.
 *
 * Returns false if header missing/malformed, ts drift exceeds tolerance, or HMAC mismatch.
 * Uses crypto.timingSafeEqual for constant-time comparison.
 */
export function verifyMuxSignature(
  rawBody: string,
  header: string | null,
  secret: string,
  toleranceSeconds = 300,
): boolean {
  if (!header || !secret) return false

  // Parse "t=...,v1=..." — Mux may emit multiple v1 entries during key rotation; accept any match.
  const parts = header.split(',').map((p) => p.trim())
  let ts: string | null = null
  const v1s: string[] = []
  for (const p of parts) {
    if (p.startsWith('t=')) ts = p.slice(2)
    else if (p.startsWith('v1=')) v1s.push(p.slice(3))
  }
  if (!ts || v1s.length === 0) return false

  const tsNum = Number(ts)
  if (!Number.isFinite(tsNum)) return false

  // Replay protection (D-32): reject if timestamp drift is more than tolerance.
  const now = Math.floor(Date.now() / 1000)
  if (Math.abs(now - tsNum) > toleranceSeconds) return false

  const expected = crypto
    .createHmac('sha256', secret)
    .update(`${ts}.${rawBody}`)
    .digest('hex')

  const expectedBuf = Buffer.from(expected, 'hex')

  for (const provided of v1s) {
    // Both buffers must be the same length for timingSafeEqual — mismatched length means fail fast.
    let providedBuf: Buffer
    try {
      providedBuf = Buffer.from(provided, 'hex')
    } catch {
      continue
    }
    if (providedBuf.length !== expectedBuf.length) continue
    if (crypto.timingSafeEqual(providedBuf, expectedBuf)) return true
  }
  return false
}

export type RecordWebhookResult = 'new' | 'duplicate'

/**
 * Insert a row into cs_video_webhook_events. Returns 'duplicate' on unique-violation
 * against event_id PK so callers can short-circuit (D-32 dedupe).
 *
 * Caller must use a service-role client because cs_video_webhook_events has RLS enabled
 * with no authenticated policies (service role bypasses RLS).
 */
export async function recordWebhookEvent(
  supabase: SupabaseClient,
  args: { eventId: string; eventType: string; payloadHash: string },
): Promise<RecordWebhookResult> {
  const { error } = await supabase
    .from('cs_video_webhook_events')
    .insert({
      event_id: args.eventId,
      event_type: args.eventType,
      payload_hash: args.payloadHash,
    })

  if (!error) return 'new'

  // Supabase surfaces Postgres unique violation as code '23505'.
  const code = (error as { code?: string }).code
  if (code === '23505') return 'duplicate'

  // Unknown error — rethrow so caller can log and still 200 to Mux
  // (webhook handlers MUST return 2xx fast; the caller's catch block handles logging).
  throw error
}
