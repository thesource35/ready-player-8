// Phase 14 — apns.ts unit tests (Deno test runner)
// Run: deno test --allow-env supabase/functions/notifications-fanout/apns.test.ts
//
// P-256 test key generated fresh for tests only — not a real APNs key.

import { assertEquals, assertRejects, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { apnsProviderToken, sendApns, _resetJwtCache, type ApnsConfig } from './apns.ts'

// Ephemeral P-256 key exported as PKCS8 PEM — generated at test-time so we
// never commit or need a real .p8 key.
async function makeTestConfig(): Promise<ApnsConfig> {
  const { privateKey } = await crypto.subtle.generateKey(
    { name: 'ECDSA', namedCurve: 'P-256' },
    true,
    ['sign', 'verify'],
  )
  const pkcs8 = await crypto.subtle.exportKey('pkcs8', privateKey)
  const b64 = btoa(String.fromCharCode(...new Uint8Array(pkcs8)))
  const wrapped = b64.match(/.{1,64}/g)!.join('\n')
  const pem = `-----BEGIN PRIVATE KEY-----\n${wrapped}\n-----END PRIVATE KEY-----\n`
  return {
    teamId: 'TEAM12345X',
    keyId: 'KEYABCDEFG',
    p8Pem: pem,
    topic: 'nailed-it-network.ready-player-8',
    host: 'https://api.sandbox.push.apple.com',
  }
}

function decodeJwtHeader(jwt: string): Record<string, unknown> {
  const [h] = jwt.split('.')
  const json = atob(h.replace(/-/g, '+').replace(/_/g, '/'))
  return JSON.parse(json)
}

function decodeJwtPayload(jwt: string): Record<string, unknown> {
  const [, p] = jwt.split('.')
  const json = atob(p.replace(/-/g, '+').replace(/_/g, '/'))
  return JSON.parse(json)
}

Deno.test('apnsProviderToken signs ES256 JWT with correct header and claims', async () => {
  _resetJwtCache()
  const cfg = await makeTestConfig()
  const jwt = await apnsProviderToken(cfg)

  const header = decodeJwtHeader(jwt)
  assertEquals(header.alg, 'ES256')
  assertEquals(header.kid, cfg.keyId)
  assertEquals(header.typ, 'JWT')

  const payload = decodeJwtPayload(jwt)
  assertEquals(payload.iss, cfg.teamId)
  assert(typeof payload.iat === 'number')
})

Deno.test('apnsProviderToken caches JWT across calls', async () => {
  _resetJwtCache()
  const cfg = await makeTestConfig()
  const a = await apnsProviderToken(cfg)
  const b = await apnsProviderToken(cfg)
  assertEquals(a, b)
})

Deno.test('sendApns throws ApnsError with status 410 on Unregistered', async () => {
  _resetJwtCache()
  const cfg = await makeTestConfig()
  const fakeFetch: typeof fetch = () =>
    Promise.resolve(
      new Response(JSON.stringify({ reason: 'Unregistered' }), { status: 410 }),
    )

  await assertRejects(
    async () => {
      await sendApns('deadbeef', { aps: {} }, { config: cfg, fetchImpl: fakeFetch })
    },
    Error,
    'APNs 410',
  )
})

Deno.test('sendApns includes required APNs headers', async () => {
  _resetJwtCache()
  const cfg = await makeTestConfig()
  let captured: Request | null = null
  const fakeFetch: typeof fetch = (input, init) => {
    captured = new Request(input as string, init)
    return Promise.resolve(new Response('', { status: 200 }))
  }

  await sendApns('abc123', { aps: { alert: { title: 't', body: 'b' } } }, {
    config: cfg,
    fetchImpl: fakeFetch,
  })

  assert(captured)
  const req = captured as unknown as Request
  assert(req.headers.get('authorization')?.startsWith('bearer '))
  assertEquals(req.headers.get('apns-topic'), cfg.topic)
  assertEquals(req.headers.get('apns-push-type'), 'alert')
  assertEquals(req.headers.get('apns-priority'), '10')
})
