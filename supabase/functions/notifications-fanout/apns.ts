// Phase 14 — APNs HTTP/2 provider client
// Decisions: D-14 (direct APNs, no vendor), D-16 (push gating enforced in index.ts)
// Pattern: RESEARCH §Pattern 3 + Pitfall 1 (JWT cache 50 min)
//
// djwt pin: v3.0.2 (stable as of plan date 2026-04-07). If deploy fails with
// a redirect warning, re-check https://deno.land/x/djwt for the current tag.

import { create, getNumericDate } from 'https://deno.land/x/djwt@v3.0.2/mod.ts'

export interface ApnsConfig {
  teamId: string
  keyId: string
  p8Pem: string
  topic: string
  host: string
}

export interface ApnsError extends Error {
  status: number
  reason?: string
}

function envConfig(): ApnsConfig {
  const teamId = Deno.env.get('APNS_TEAM_ID')
  const keyId = Deno.env.get('APNS_KEY_ID')
  const p8Pem = Deno.env.get('APNS_AUTH_KEY_P8')
  const topic = Deno.env.get('APNS_BUNDLE_ID')
  const host = Deno.env.get('APNS_HOST') ?? 'https://api.push.apple.com'

  if (!teamId || !keyId || !p8Pem || !topic) {
    throw new Error(
      '[apns] missing env: APNS_TEAM_ID, APNS_KEY_ID, APNS_AUTH_KEY_P8, APNS_BUNDLE_ID required',
    )
  }
  return { teamId, keyId, p8Pem, topic, host }
}

// Module-level JWT cache. Edge Function instances are short-lived; within an
// instance we refresh at most once per ~50 minutes (Apple requires <60 min freshness).
let cachedJwt: { token: string; exp: number; kid: string } | null = null

async function importP8Key(p8Pem: string): Promise<CryptoKey> {
  const pem = p8Pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '')
  if (!pem) throw new Error('[apns] APNS_AUTH_KEY_P8 is empty after PEM strip')

  let der: Uint8Array
  try {
    der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  } catch (e) {
    throw new Error(`[apns] APNS_AUTH_KEY_P8 base64 decode failed: ${(e as Error).message}`)
  }

  return await crypto.subtle.importKey(
    'pkcs8',
    der,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign'],
  )
}

export async function apnsProviderToken(config?: ApnsConfig): Promise<string> {
  const cfg = config ?? envConfig()
  const now = Math.floor(Date.now() / 1000)
  if (cachedJwt && cachedJwt.kid === cfg.keyId && cachedJwt.exp > now + 60) {
    return cachedJwt.token
  }

  const key = await importP8Key(cfg.p8Pem)
  const jwt = await create(
    { alg: 'ES256', kid: cfg.keyId, typ: 'JWT' },
    { iss: cfg.teamId, iat: getNumericDate(0) },
    key,
  )
  cachedJwt = { token: jwt, exp: now + 50 * 60, kid: cfg.keyId }
  return jwt
}

// Exposed for tests
export function _resetJwtCache() {
  cachedJwt = null
}

export async function sendApns(
  deviceToken: string,
  payload: unknown,
  opts?: { config?: ApnsConfig; fetchImpl?: typeof fetch },
): Promise<void> {
  const cfg = opts?.config ?? envConfig()
  const f = opts?.fetchImpl ?? fetch
  const jwt = await apnsProviderToken(cfg)

  const res = await f(`${cfg.host}/3/device/${deviceToken}`, {
    method: 'POST',
    headers: {
      'authorization': `bearer ${jwt}`,
      'apns-topic': cfg.topic,
      'apns-push-type': 'alert',
      'apns-priority': '10',
      'apns-expiration': '0',
      'content-type': 'application/json',
    },
    body: JSON.stringify(payload),
  })

  if (!res.ok) {
    const body = (await res.json().catch(() => ({}))) as { reason?: string }
    const err = new Error(
      `APNs ${res.status}: ${body?.reason ?? 'unknown'}`,
    ) as ApnsError
    err.status = res.status
    err.reason = body?.reason
    // 403 means JWT is stale/wrong — bust the cache so next call re-signs
    if (res.status === 403) _resetJwtCache()
    throw err
  }
}
