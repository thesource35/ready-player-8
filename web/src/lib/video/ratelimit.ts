// Phase 22 — Video-specific rate-limit wrapper.
// D-37: 30 req/min/IP across every /api/video/* route.
// Thin wrapper over the project's shared @/lib/rate-limit infrastructure (Upstash + in-memory fallback).

import { rateLimit as sharedRateLimit } from '@/lib/rate-limit'
import { PLAYBACK_TOKEN_RATE_LIMIT_PER_MIN } from '@/lib/video/types'

export type VideoRateLimitResult = {
  allowed: boolean
  resetAt: number // Unix ms
  limit: number
  remaining: number
}

/**
 * Check the per-IP, per-endpoint video rate limit (30 req/min — D-37).
 *
 * The underlying shared limiter keys by the route string; we namespace with `video:{endpoint}`
 * so noisy clients on one video endpoint don't starve another.
 *
 * The shared limiter's default window/limit is 30 req / 1 min (matches D-37 exactly),
 * so no override is needed — but we pass through the constant for documentation.
 */
export async function checkVideoRateLimit(
  ip: string,
  endpoint: string,
): Promise<VideoRateLimitResult> {
  // `sharedRateLimit` takes (identifier, route) — we namespace the route so video endpoints
  // don't collide with other rate-limit buckets.
  const routeKey = `video:${endpoint}`
  const result = await sharedRateLimit(ip, routeKey)

  // Document the D-37 intent — shared limiter already defaults to 30/min, this is a sanity anchor.
  void PLAYBACK_TOKEN_RATE_LIMIT_PER_MIN

  return {
    allowed: result.success,
    resetAt: result.reset,
    limit: result.limit,
    remaining: result.remaining,
  }
}
