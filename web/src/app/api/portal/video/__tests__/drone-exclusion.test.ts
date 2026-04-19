// Owner: 29-02-PLAN.md Wave 1 — LIVE-14 CRITICAL: portal routes 403 on drone (regression lock per D-26).
//
// This test locks the Phase 22 invariant that drone-typed cs_video_assets / cs_video_sources
// cannot leak through the portal. Any future change that weakens this exclusion MUST break this
// test. Two invariants are asserted (one per route):
//
//   playback-url/route.ts:107  -> if (asset.source_type === 'drone') return 403
//   playback-token/route.ts:125 -> if (source.kind === 'drone')       return 403
//
// We exercise the real route handlers (not re-implementations). We mock the service-role Supabase
// client and the shared rate-limit so the path under test is the drone-exclusion branch.

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// ---------------------------------------------------------------------------
// Rate-limit bypass — D-37 30 req/min/IP would otherwise short-circuit on repeated requests.
// ---------------------------------------------------------------------------
vi.mock('@/lib/video/ratelimit', () => ({
  checkVideoRateLimit: async () => ({ allowed: true, resetAt: Date.now() + 60_000, limit: 30, remaining: 29 }),
}))

// ---------------------------------------------------------------------------
// HLS manifest signing — not exercised in drone path, but imported by playback-url route.
// Return a benign signed manifest so non-drone baseline reaches the 200 branch cleanly.
// ---------------------------------------------------------------------------
vi.mock('@/lib/video/hls-sign', () => ({
  signHlsManifest: async () => ({ manifestText: '#EXTM3U\n#EXT-X-VERSION:3\n' }),
}))

// ---------------------------------------------------------------------------
// Mux JWT signing — not exercised in drone path, but imported by playback-token route.
// ---------------------------------------------------------------------------
vi.mock('@/lib/video/mux', () => ({
  signPlaybackJWT: () => 'mock.jwt.token',
}))

// ---------------------------------------------------------------------------
// Supabase service-role client mock. Build a query builder that resolves to the
// row passed via the per-test "rows" map.
// ---------------------------------------------------------------------------
type Rows = {
  portalLink?: unknown
  asset?: unknown
  source?: unknown
  liveAsset?: unknown
}

let currentRows: Rows = {}

function buildQueryBuilder(tableResolver: () => unknown) {
  // Each chain method returns `this`; maybeSingle()/single() resolve with { data, error: null }.
  const chain: Record<string, unknown> = {}
  const chainFn = () => chain
  chain.select = chainFn
  chain.eq = chainFn
  chain.is = chainFn
  chain.limit = chainFn
  chain.maybeSingle = async () => ({ data: tableResolver(), error: null })
  chain.single = async () => ({ data: tableResolver(), error: null })
  chain.insert = async () => ({ data: null, error: null })
  return chain
}

vi.mock('@/lib/supabase/server', () => ({
  createServiceRoleClient: () => ({
    from: (table: string) => {
      if (table === 'cs_report_shared_links') return buildQueryBuilder(() => currentRows.portalLink ?? null)
      if (table === 'cs_video_assets') {
        // playback-token route also queries cs_video_assets for the live asset id
        // near line 154 (source_id + kind='live' + ended_at null). Return liveAsset
        // specifically if requested, else the primary asset row.
        // Simple discriminator: both queries use maybeSingle(); the live-asset query
        // stacks more chain methods. We return currentRows.asset first, and after a
        // single maybeSingle() resolve we switch to liveAsset. To keep this robust,
        // make BOTH resolvers inspect a counter.
        let asset_call_count = 0
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                is: () => ({
                  limit: () => ({
                    maybeSingle: async () => ({ data: currentRows.liveAsset ?? null, error: null }),
                  }),
                }),
                maybeSingle: async () => ({ data: currentRows.asset ?? null, error: null }),
              }),
              maybeSingle: async () => {
                asset_call_count += 1
                return { data: currentRows.asset ?? null, error: null }
              },
            }),
          }),
          insert: async () => ({ data: null, error: null }),
        }
      }
      if (table === 'cs_video_sources') return buildQueryBuilder(() => currentRows.source ?? null)
      if (table === 'cs_portal_analytics') return { insert: async () => ({ data: null, error: null }) }
      return buildQueryBuilder(() => null)
    },
  }),
  // createServerSupabase is not used by portal routes, but imports may touch it.
  createServerSupabase: async () => null,
}))

// ---------------------------------------------------------------------------
// Helpers to build request objects matching the real portal route shapes.
// ---------------------------------------------------------------------------
function validPortalLink(overrides: Partial<{ id: string; project_id: string; is_revoked: boolean; expires_at: string | null; cs_portal_config: unknown }> = {}) {
  return {
    id: 'link-1',
    project_id: 'p-1',
    is_revoked: false,
    expires_at: new Date(Date.now() + 3600_000).toISOString(),
    cs_portal_config: { show_cameras: true },
    ...overrides,
  }
}

function playbackUrlRequest(portal_token: string, asset_id: string): Request {
  const url = new URL('http://localhost/api/portal/video/playback-url')
  url.searchParams.set('portal_token', portal_token)
  url.searchParams.set('asset_id', asset_id)
  return new Request(url.toString(), {
    method: 'GET',
    headers: { 'x-forwarded-for': '127.0.0.1' },
  })
}

function playbackTokenRequest(portal_token: string, source_id: string): Request {
  return new Request('http://localhost/api/portal/video/playback-token', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-forwarded-for': '127.0.0.1' },
    body: JSON.stringify({ portal_token, source_id }),
  })
}

// ---------------------------------------------------------------------------
// Env — service-role client requires both URL and service-role key to be set.
// ---------------------------------------------------------------------------
beforeEach(() => {
  process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co'
  process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key'
  currentRows = {}
})

afterEach(() => {
  vi.resetModules()
})

// ---------------------------------------------------------------------------
// Tests — LIVE-14 CRITICAL
// ---------------------------------------------------------------------------
describe('LIVE-14 portal drone-exclusion regression (D-26)', () => {
  it('playback-url: drone source_type asset with portal_visible=true still returns 403 (line 107 invariant)', async () => {
    currentRows = {
      portalLink: validPortalLink(),
      asset: {
        id: 'a-1',
        org_id: 'o-1',
        project_id: 'p-1',
        source_id: 's-1',
        source_type: 'drone',
        kind: 'vod',
        status: 'ready',
        portal_visible: true,
      },
    }
    const { GET } = await import('../playback-url/route')
    const res = await GET(playbackUrlRequest('tok', 'a-1'))
    expect(res.status).toBe(403)
    const bodyText = await res.text()
    expect(bodyText.toLowerCase()).toMatch(/drone/)
  })

  it('playback-token: drone source.kind returns 403 (line 125 invariant)', async () => {
    currentRows = {
      portalLink: validPortalLink(),
      source: {
        id: 's-1',
        project_id: 'p-1',
        org_id: 'o-1',
        kind: 'drone',
        mux_playback_id: null,
      },
    }
    const { POST } = await import('../playback-token/route')
    const res = await POST(playbackTokenRequest('tok', 's-1'))
    expect(res.status).toBe(403)
    const bodyText = await res.text()
    expect(bodyText.toLowerCase()).toMatch(/drone/)
  })

  it('playback-url: non-drone (upload) asset does NOT hit the drone-specific 403 branch (baseline)', async () => {
    currentRows = {
      portalLink: validPortalLink(),
      asset: {
        id: 'a-2',
        org_id: 'o-1',
        project_id: 'p-1',
        source_id: 's-1',
        source_type: 'upload',
        kind: 'vod',
        status: 'ready',
        portal_visible: true,
      },
    }
    const { GET } = await import('../playback-url/route')
    const res = await GET(playbackUrlRequest('tok', 'a-2'))
    // Non-drone asset should pass the drone exclusion. Happy path returns 200 with the
    // signed HLS manifest; any downstream 403 MUST NOT reference drone.
    if (res.status === 403) {
      const bodyText = await res.text()
      expect(bodyText.toLowerCase()).not.toMatch(/drone/)
    } else {
      expect(res.status).not.toBe(403)
    }
  })

  it('playback-token: non-drone (fixed_camera) source does NOT hit the drone-specific 403 branch (baseline)', async () => {
    currentRows = {
      portalLink: validPortalLink(),
      source: {
        id: 's-2',
        project_id: 'p-1',
        org_id: 'o-1',
        kind: 'fixed_camera',
        mux_playback_id: 'pb-1',
      },
      // The route queries cs_video_assets near line 154 to resolve the live asset id for
      // analytics — return null so it falls back to the 'live:{source_id}' placeholder.
      liveAsset: null,
    }
    const { POST } = await import('../playback-token/route')
    const res = await POST(playbackTokenRequest('tok', 's-2'))
    // fixed_camera with a playback id should succeed (200 with token). Any 403 here MUST
    // NOT be due to the drone exclusion.
    if (res.status === 403) {
      const bodyText = await res.text()
      expect(bodyText.toLowerCase()).not.toMatch(/drone/)
    } else {
      expect(res.status).not.toBe(403)
    }
  })
})
