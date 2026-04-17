// Owner: 22-09-PLAN.md Wave 4 — Portal video auth guards (VIDEO-01-L)
// Tests: drone source_type -> 403; portal_visible=false -> 403; live source with show_cameras=false -> 403;
// revoked/expired portal -> 410; project_id mismatch -> 403; rate limiting -> 429.
import { describe, it, expect, vi, beforeEach } from "vitest";

// --- Mocks ---

const mockCheckVideoRateLimit = vi.fn()
const mockSignPlaybackJWT = vi.fn()
const mockSignHlsManifest = vi.fn()

vi.mock("@/lib/video/ratelimit", () => ({
  checkVideoRateLimit: (...args: unknown[]) => mockCheckVideoRateLimit(...args),
}))

vi.mock("@/lib/video/mux", () => ({
  signPlaybackJWT: (...args: unknown[]) => mockSignPlaybackJWT(...args),
}))

vi.mock("@/lib/video/hls-sign", () => ({
  signHlsManifest: (...args: unknown[]) => mockSignHlsManifest(...args),
}))

// Supabase mock with chainable .from().select().eq().maybeSingle()
let mockQueryResults: Record<string, Record<string, unknown> | null> = {}

function makeMockChain(table: string) {
  return {
    select: vi.fn().mockReturnThis(),
    eq: vi.fn().mockReturnThis(),
    is: vi.fn().mockReturnThis(),
    order: vi.fn().mockReturnThis(),
    limit: vi.fn().mockReturnThis(),
    not: vi.fn().mockReturnThis(),
    lt: vi.fn().mockReturnThis(),
    insert: vi.fn().mockReturnValue(Promise.resolve({ data: null, error: null })),
    maybeSingle: vi.fn().mockImplementation(() => {
      return Promise.resolve({ data: mockQueryResults[table] ?? null, error: null })
    }),
  }
}

const mockFromFn = vi.fn().mockImplementation((table: string) => makeMockChain(table))

vi.mock("@/lib/supabase/server", () => ({
  createServiceRoleClient: () => ({ from: mockFromFn }),
  createServerSupabase: vi.fn(),
}))

function makeRequest(method: string, url: string, body?: Record<string, unknown>) {
  return new Request(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      "x-forwarded-for": "1.2.3.4",
    },
    body: body ? JSON.stringify(body) : undefined,
  })
}

describe("Portal video auth", () => {
  beforeEach(() => {
    vi.resetModules()
    vi.clearAllMocks()
    mockQueryResults = {}
    mockCheckVideoRateLimit.mockResolvedValue({
      allowed: true,
      resetAt: Date.now() + 60000,
      limit: 30,
      remaining: 29,
    })
  })

  describe("POST /api/portal/video/playback-token", () => {
    it("returns 200 with signed JWT for valid live source with show_cameras=true", { timeout: 15000 }, async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: new Date(Date.now() + 86400000).toISOString(),
        cs_portal_config: { show_cameras: true },
      }
      mockQueryResults["cs_video_sources"] = {
        id: "src-1",
        project_id: "proj-1",
        kind: "fixed_camera",
        mux_playback_id: "mux-pb-1",
      }
      mockSignPlaybackJWT.mockReturnValue("jwt-token-123")

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "valid-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      const json = await res.json()

      expect(res.status).toBe(200)
      expect(json.token).toBe("jwt-token-123")
      expect(json.ttl).toBe(300)
      expect(json.playback_id).toBe("mux-pb-1")
    })

    it("returns 403 when show_cameras=false", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: new Date(Date.now() + 86400000).toISOString(),
        cs_portal_config: { show_cameras: false },
      }

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "valid-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      expect(res.status).toBe(403)
    })

    it("returns 410 for revoked portal token", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: true,
        expires_at: null,
        cs_portal_config: { show_cameras: true },
      }

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "revoked-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      expect(res.status).toBe(410)
    })

    it("returns 403 when source belongs to different project", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
        cs_portal_config: { show_cameras: true },
      }
      mockQueryResults["cs_video_sources"] = {
        id: "src-1",
        project_id: "proj-2", // different project!
        kind: "fixed_camera",
        mux_playback_id: "mux-pb-1",
      }

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "valid-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      expect(res.status).toBe(403)
    })

    it("returns 403 for drone source_type (D-22)", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
        cs_portal_config: { show_cameras: true },
      }
      mockQueryResults["cs_video_sources"] = {
        id: "src-1",
        project_id: "proj-1",
        kind: "drone",
        mux_playback_id: "mux-pb-1",
      }

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "valid-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      expect(res.status).toBe(403)
      const json = await res.json()
      expect(json.code).toBe("video.permission_denied")
    })

    it("returns 429 when rate limited (D-37)", async () => {
      mockCheckVideoRateLimit.mockResolvedValue({
        allowed: false,
        resetAt: Date.now() + 30000,
        limit: 30,
        remaining: 0,
      })

      const { POST } = await import("@/app/api/portal/video/playback-token/route")
      const req = makeRequest("POST", "http://localhost/api/portal/video/playback-token", {
        portal_token: "valid-token",
        source_id: "src-1",
      })
      const res = await POST(req)
      expect(res.status).toBe(429)
      expect(res.headers.get("Retry-After")).toBeTruthy()
    })
  })

  describe("GET /api/portal/video/playback-url", () => {
    it("returns signed manifest for portal_visible VOD asset", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
      }
      mockQueryResults["cs_video_assets"] = {
        id: "asset-1",
        project_id: "proj-1",
        org_id: "org-1",
        source_id: "src-1",
        source_type: "fixed_camera",
        kind: "vod",
        status: "ready",
        portal_visible: true,
      }
      mockSignHlsManifest.mockResolvedValue({ manifestText: "#EXTM3U\n#EXT-X-VERSION:3\n" })

      const { GET } = await import("@/app/api/portal/video/playback-url/route")
      const req = makeRequest("GET", "http://localhost/api/portal/video/playback-url?portal_token=valid-token&asset_id=asset-1")
      const res = await GET(req)

      expect(res.status).toBe(200)
      expect(res.headers.get("Content-Type")).toBe("application/vnd.apple.mpegurl")
      expect(res.headers.get("Cache-Control")).toBe("private, max-age=0, no-store")
    })

    it("returns 403 for VOD asset with portal_visible=false", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
      }
      mockQueryResults["cs_video_assets"] = {
        id: "asset-1",
        project_id: "proj-1",
        org_id: "org-1",
        source_id: "src-1",
        source_type: "fixed_camera",
        kind: "vod",
        status: "ready",
        portal_visible: false,
      }

      const { GET } = await import("@/app/api/portal/video/playback-url/route")
      const req = makeRequest("GET", "http://localhost/api/portal/video/playback-url?portal_token=valid-token&asset_id=asset-1")
      const res = await GET(req)
      expect(res.status).toBe(403)
    })

    it("includes Cache-Control: no-store per D-34(b)", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
      }
      mockQueryResults["cs_video_assets"] = {
        id: "asset-1",
        project_id: "proj-1",
        org_id: "org-1",
        source_id: "src-1",
        source_type: "upload",
        kind: "vod",
        status: "ready",
        portal_visible: true,
      }
      mockSignHlsManifest.mockResolvedValue({ manifestText: "#EXTM3U\n" })

      const { GET } = await import("@/app/api/portal/video/playback-url/route")
      const req = makeRequest("GET", "http://localhost/api/portal/video/playback-url?portal_token=valid-token&asset_id=asset-1")
      const res = await GET(req)
      expect(res.headers.get("Cache-Control")).toContain("no-store")
    })

    it("returns 403 for drone source_type (D-22)", async () => {
      mockQueryResults["cs_report_shared_links"] = {
        id: "link-1",
        project_id: "proj-1",
        is_revoked: false,
        expires_at: null,
      }
      mockQueryResults["cs_video_assets"] = {
        id: "asset-1",
        project_id: "proj-1",
        org_id: "org-1",
        source_id: "src-1",
        source_type: "drone",
        kind: "vod",
        status: "ready",
        portal_visible: true,
      }

      const { GET } = await import("@/app/api/portal/video/playback-url/route")
      const req = makeRequest("GET", "http://localhost/api/portal/video/playback-url?portal_token=valid-token&asset_id=asset-1")
      const res = await GET(req)
      expect(res.status).toBe(403)
      const json = await res.json()
      expect(json.code).toBe("video.permission_denied")
    })
  })
})
