// Owner: 22-03-PLAN.md Wave 2 — Mux signed-playback JWT minting (VIDEO-01-E)
// Un-skipped in 22-11: real assertions covering signPlaybackJWT.
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import crypto from 'node:crypto'
import jwt from 'jsonwebtoken'

// Generate a test RSA keypair for RS256
const { privateKey, publicKey } = crypto.generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
})

const TEST_KID = 'test-kid-22-11'

describe('signPlaybackJWT', () => {
  const origKid = process.env.MUX_SIGNING_KEY_ID
  const origKey = process.env.MUX_SIGNING_KEY_PRIVATE

  beforeAll(() => {
    process.env.MUX_SIGNING_KEY_ID = TEST_KID
    process.env.MUX_SIGNING_KEY_PRIVATE = privateKey
  })

  afterAll(() => {
    if (origKid !== undefined) process.env.MUX_SIGNING_KEY_ID = origKid
    else delete process.env.MUX_SIGNING_KEY_ID
    if (origKey !== undefined) process.env.MUX_SIGNING_KEY_PRIVATE = origKey
    else delete process.env.MUX_SIGNING_KEY_PRIVATE
  })

  it('produces RS256 JWT with sub=playback_id, aud=v, exp within TTL, kid set', async () => {
    const { signPlaybackJWT } = await import('@/lib/video/mux')
    const token = signPlaybackJWT('playback-abc', 300)
    const decoded = jwt.decode(token, { complete: true }) as {
      header: { alg: string; kid?: string }
      payload: { sub: string; aud: string; exp: number }
    }
    expect(decoded.header.alg).toBe('RS256')
    expect(decoded.header.kid).toBe(TEST_KID)
    expect(decoded.payload.sub).toBe('playback-abc')
    expect(decoded.payload.aud).toBe('v')
    const now = Math.floor(Date.now() / 1000)
    expect(decoded.payload.exp).toBeGreaterThan(now)
    expect(decoded.payload.exp).toBeLessThanOrEqual(now + 301)
  })

  it('signature is verifiable with the corresponding public key', async () => {
    const { signPlaybackJWT } = await import('@/lib/video/mux')
    const token = signPlaybackJWT('verify-test', 120)
    const verified = jwt.verify(token, publicKey, { algorithms: ['RS256'] }) as {
      sub: string
      aud: string
    }
    expect(verified.sub).toBe('verify-test')
    expect(verified.aud).toBe('v')
  })

  it('accepts base64-encoded PEM (LS0tLS1 prefix)', async () => {
    process.env.MUX_SIGNING_KEY_PRIVATE = Buffer.from(privateKey).toString('base64')
    // Re-import to pick up new env
    const mod = await import('@/lib/video/mux')
    const token = mod.signPlaybackJWT('b64-test', 60)
    const decoded = jwt.decode(token, { complete: true }) as {
      payload: { sub: string }
    }
    expect(decoded.payload.sub).toBe('b64-test')
    // Restore raw PEM for other tests
    process.env.MUX_SIGNING_KEY_PRIVATE = privateKey
  })
})
