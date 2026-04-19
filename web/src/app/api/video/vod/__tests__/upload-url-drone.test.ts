// Owner: 29-02-PLAN.md Wave 1 — LIVE-01: upload-url accepts source_type='drone'
// Asserts:
//  1. body.source_type='drone'        -> 201, cs_video_assets.source_type='drone'
//  2. body.source_type='upload'       -> 201, cs_video_assets.source_type='upload' (explicit)
//  3. body has no source_type         -> 201, cs_video_assets.source_type='upload' (Phase 22 back-compat)
//  4. body.source_type='fixed_camera' -> 400 (user route only accepts upload|drone); insert NOT called
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// ---------------------------------------------------------------------------
// Shared mock state
// ---------------------------------------------------------------------------
const insertMock = vi.fn()
// Per-call insert behavior: returns { data: { id }, error: null }
const selectSingleMock = vi.fn().mockResolvedValue({ data: { id: 'asset-uuid-1' }, error: null })
const sourceMaybeSingleMock = vi.fn().mockResolvedValue({ data: { id: 'src-uuid-1' }, error: null })

vi.mock('@/lib/supabase/server', () => ({
  createServerSupabase: async () => ({
    auth: {
      getUser: async () => ({ data: { user: { id: 'user-1' } }, error: null }),
      getSession: async () => ({ data: { session: { access_token: 'tok' } } }),
    },
    from: (table: string) => {
      if (table === 'cs_video_sources') {
        return {
          select: () => ({
            eq: () => ({
              eq: () => ({
                eq: () => ({
                  limit: () => ({ maybeSingle: sourceMaybeSingleMock }),
                }),
              }),
            }),
          }),
          insert: () => ({
            select: () => ({
              single: async () => ({ data: { id: 'src-uuid-1' }, error: null }),
            }),
          }),
        }
      }
      if (table === 'cs_video_assets') {
        return {
          insert: (payload: unknown) => {
            insertMock(payload)
            return {
              select: () => ({ single: selectSingleMock }),
            }
          },
          update: () => ({ eq: async () => ({ error: null }) }),
        }
      }
      return {}
    },
  }),
}))

vi.mock('@/lib/video/ratelimit', () => ({
  checkVideoRateLimit: async () => ({ allowed: true, resetAt: Date.now() + 60000, limit: 30, remaining: 29 }),
}))

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function postBody(body: unknown) {
  const { POST } = await import('../upload-url/route')
  const req = new Request('http://localhost/api/video/vod/upload-url', {
    method: 'POST',
    headers: { 'content-type': 'application/json', 'x-forwarded-for': '127.0.0.1' },
    body: JSON.stringify(body),
  })
  return POST(req)
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
describe('upload-url drone source_type (LIVE-01)', () => {
  beforeEach(() => {
    // Route requires NEXT_PUBLIC_SUPABASE_URL to be set at the end of the happy path.
    process.env.NEXT_PUBLIC_SUPABASE_URL = 'https://test.supabase.co'
    insertMock.mockClear()
    selectSingleMock.mockClear()
    sourceMaybeSingleMock.mockClear()
  })
  afterEach(() => {
    vi.resetModules()
  })

  it('accepts source_type=drone and inserts cs_video_assets with source_type=drone', async () => {
    const res = await postBody({
      project_id: 'p-1',
      org_id: 'o-1',
      file_size_bytes: 1000,
      container: 'mp4',
      source_type: 'drone',
    })
    expect(res.status).toBe(201)
    expect(insertMock).toHaveBeenCalled()
    const payload = insertMock.mock.calls[0][0] as Record<string, unknown>
    expect(payload.source_type).toBe('drone')
  })

  it('defaults to source_type=upload when absent (Phase 22 backward compat)', async () => {
    const res = await postBody({
      project_id: 'p-1',
      org_id: 'o-1',
      file_size_bytes: 1000,
      container: 'mp4',
    })
    expect(res.status).toBe(201)
    const payload = insertMock.mock.calls[0][0] as Record<string, unknown>
    expect(payload.source_type).toBe('upload')
  })

  it('accepts explicit source_type=upload', async () => {
    const res = await postBody({
      project_id: 'p-1',
      org_id: 'o-1',
      file_size_bytes: 1000,
      container: 'mp4',
      source_type: 'upload',
    })
    expect(res.status).toBe(201)
    const payload = insertMock.mock.calls[0][0] as Record<string, unknown>
    expect(payload.source_type).toBe('upload')
  })

  it('rejects unknown source_type=fixed_camera with 400 and never calls insert', async () => {
    const res = await postBody({
      project_id: 'p-1',
      org_id: 'o-1',
      file_size_bytes: 1000,
      container: 'mp4',
      source_type: 'fixed_camera', // not accepted from user-facing route
    })
    expect(res.status).toBe(400)
    expect(insertMock).not.toHaveBeenCalled()
    const bodyText = await res.text()
    expect(bodyText.toLowerCase()).toMatch(/source_type|invalid/i)
  })
})
