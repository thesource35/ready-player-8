// Owner: 22-03-PLAN.md Wave 2 — Mux webhook receiver (VIDEO-01-E)
// Un-skipped in 22-11: real assertions covering verifyMuxSignature.
import { describe, it, expect } from 'vitest'
import crypto from 'node:crypto'
import { verifyMuxSignature } from '@/lib/video/webhook-verify'

describe('verifyMuxSignature', () => {
  const secret = 'test-webhook-secret-22-11'
  const body = JSON.stringify({ type: 'video.live_stream.active', id: 'evt-1' })
  const ts = Math.floor(Date.now() / 1000)
  const sig = crypto.createHmac('sha256', secret).update(`${ts}.${body}`).digest('hex')
  const header = `t=${ts},v1=${sig}`

  it('accepts valid HMAC signature', () => {
    expect(verifyMuxSignature(body, header, secret)).toBe(true)
  })

  it('rejects forged signature', () => {
    const bad = `t=${ts},v1=${'0'.repeat(64)}`
    expect(verifyMuxSignature(body, bad, secret)).toBe(false)
  })

  it('rejects old timestamp (replay protection, >5min drift)', () => {
    const oldTs = ts - 600 // 10 minutes ago, beyond 5-min tolerance
    const oldSig = crypto.createHmac('sha256', secret).update(`${oldTs}.${body}`).digest('hex')
    expect(verifyMuxSignature(body, `t=${oldTs},v1=${oldSig}`, secret)).toBe(false)
  })

  it('rejects null header', () => {
    expect(verifyMuxSignature(body, null, secret)).toBe(false)
  })

  it('rejects empty secret', () => {
    expect(verifyMuxSignature(body, header, '')).toBe(false)
  })

  it('accepts any matching v1 during key rotation (multi-v1)', () => {
    const wrongSig = '0'.repeat(64)
    const rotationHeader = `t=${ts},v1=${wrongSig},v1=${sig}`
    expect(verifyMuxSignature(body, rotationHeader, secret)).toBe(true)
  })
})
