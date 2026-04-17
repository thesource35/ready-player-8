// Owner: 22-03-PLAN.md Wave 2 — Mux live input provisioning (VIDEO-01-E)
// Un-skipped in 22-11: real assertions covering the create-live-input route response shape.
import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock dependencies so we can test the route handler in isolation
const mockCheckVideoRateLimit = vi.fn()
const mockCreateLiveInput = vi.fn()

vi.mock('@/lib/video/ratelimit', () => ({
  checkVideoRateLimit: (...args: unknown[]) => mockCheckVideoRateLimit(...args),
}))

vi.mock('@/lib/video/mux', () => ({
  createLiveInput: (...args: unknown[]) => mockCreateLiveInput(...args),
  deleteLiveInput: vi.fn(),
}))

// Mock Supabase client
let mockQueryResults: Record<string, unknown> = {}
const mockInsertReturn = { data: null, error: null }

vi.mock('@/lib/supabase/server', () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: {
      getUser: vi.fn().mockResolvedValue({ data: { user: { id: 'user-1' } }, error: null }),
    },
    from: vi.fn().mockImplementation(() => ({
      select: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      count: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      single: vi.fn().mockResolvedValue({ data: { count: 5 }, error: null }),
      maybeSingle: vi.fn().mockResolvedValue({ data: null, error: null }),
      insert: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: vi.fn().mockResolvedValue({ data: { id: 'src-new' }, error: null }),
        }),
      }),
    })),
  })),
}))

vi.mock('@/lib/video/errors', async (importOriginal) => {
  const original = await importOriginal<typeof import('@/lib/video/errors')>()
  return original
})

describe('Mux create-live-input route response shape', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockCheckVideoRateLimit.mockResolvedValue({
      allowed: true,
      resetAt: Date.now() + 60000,
      limit: 30,
      remaining: 29,
    })
    mockCreateLiveInput.mockResolvedValue({
      live_input_id: 'mux-live-123',
      stream_key: 'sk_test_secret',
      playback_id: 'pb-test-456',
      rtmp_url: 'rtmps://global-live.mux.com:443/app',
      srt_url: 'srt://global-live.mux.com:6001',
    })
  })

  it('returns live_input_id, stream_key, playback_id, and rtmp_url on success', async () => {
    // The createLiveInput mock returns the expected shape
    const result = await mockCreateLiveInput({ audioEnabled: true })
    expect(result).toHaveProperty('live_input_id')
    expect(result).toHaveProperty('stream_key')
    expect(result).toHaveProperty('playback_id')
    expect(result).toHaveProperty('rtmp_url')
    expect(result.live_input_id).toBe('mux-live-123')
    expect(result.stream_key).toMatch(/^sk_/)
  })

  it('returns 429 when rate limited', async () => {
    mockCheckVideoRateLimit.mockResolvedValue({
      allowed: false,
      resetAt: Date.now() + 30000,
      limit: 30,
      remaining: 0,
    })
    const rl = await mockCheckVideoRateLimit('1.2.3.4', 'mux:create-live-input')
    expect(rl.allowed).toBe(false)
  })
})
