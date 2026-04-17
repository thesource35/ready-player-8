// Owner: 22-03-PLAN.md Wave 2 — Rate limits on video token/URL endpoints (VIDEO-01-E)
// Un-skipped in 22-11: real assertions covering checkVideoRateLimit.
import { describe, it, expect } from 'vitest'
import { checkVideoRateLimit } from '@/lib/video/ratelimit'

describe('Video endpoint rate limits (D-37: 30 req/min/IP)', () => {
  // Use a unique IP per test run to avoid cross-test pollution from the in-memory store.
  const uniqueIp = `ratelimit-test-${Date.now()}`

  it('allows 30 calls within 60s window', async () => {
    for (let i = 0; i < 30; i++) {
      const result = await checkVideoRateLimit(uniqueIp, 'test:ratelimit')
      expect(result.allowed).toBe(true)
    }
  })

  it('rejects 31st call with allowed=false and resetAt in the future', async () => {
    // The 30 calls above already consumed the budget for uniqueIp
    const result = await checkVideoRateLimit(uniqueIp, 'test:ratelimit')
    expect(result.allowed).toBe(false)
    expect(result.resetAt).toBeGreaterThan(Date.now())
    expect(result.remaining).toBe(0)
  })

  it('different endpoints have independent buckets', async () => {
    const ip2 = `ratelimit-test-2-${Date.now()}`
    const r1 = await checkVideoRateLimit(ip2, 'test:endpoint-a')
    const r2 = await checkVideoRateLimit(ip2, 'test:endpoint-b')
    expect(r1.allowed).toBe(true)
    expect(r2.allowed).toBe(true)
  })
})
