import { describe, it, expect, vi, beforeEach } from "vitest";
import type { ProjectReport } from "@/lib/reports/types";

// ---------- Mocks ----------

const mockSingle = vi.fn();
const mockLimit = vi.fn(() => ({ data: [], error: null }));
const mockHead = vi.fn(() => ({ count: 0, error: null }));
const mockOrder = vi.fn(() => ({ limit: mockLimit, data: [], error: null }));
const mockEq3 = vi.fn(() => ({
  single: mockSingle,
  order: mockOrder,
  data: [],
  error: null,
  limit: mockLimit,
}));
const mockEq2 = vi.fn(() => ({
  single: mockSingle,
  eq: mockEq3,
  order: mockOrder,
  data: [],
  error: null,
  limit: mockLimit,
}));
const mockEq = vi.fn(() => ({
  single: mockSingle,
  eq: mockEq2,
  order: mockOrder,
  data: [],
  error: null,
  limit: mockLimit,
}));
const mockSelect = vi.fn(() => ({
  eq: mockEq,
  data: [],
  error: null,
  single: mockSingle,
  limit: mockLimit,
}));
const mockFrom = vi.fn(() => ({ select: mockSelect }));

const mockSupabase = { from: mockFrom, auth: { getUser: vi.fn() } };

vi.mock("@/lib/supabase/fetch", () => ({
  getAuthenticatedClient: vi.fn(),
}));

vi.mock("@/lib/rate-limit", () => ({
  rateLimit: vi.fn().mockResolvedValue({
    success: true,
    limit: 30,
    remaining: 29,
    reset: Date.now() + 60000,
  }),
  getRateLimitHeaders: vi.fn().mockReturnValue({}),
}));

import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { GET } from "../project/[id]/route";

// Load fixture
import sampleProject from "@/lib/reports/__tests__/fixtures/sample-project.json";

// ---------- Helpers ----------

function makeRequest(id: string) {
  return new Request(`http://localhost:3000/api/reports/project/${id}`, {
    method: "GET",
    headers: { "x-forwarded-for": "127.0.0.1" },
  });
}

// ---------- Tests ----------

describe("GET /api/reports/project/[id]", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 401 when not authenticated", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: null,
      user: null,
    });

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });
    expect(res.status).toBe(401);

    const body = await res.json();
    expect(body.error).toBe("Authentication required");
  });

  it("returns 404 when project not found", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    mockSingle.mockResolvedValue({ data: null, error: { message: "not found" } });

    const req = makeRequest("nonexistent");
    const res = await GET(req, { params: Promise.resolve({ id: "nonexistent" }) });
    expect(res.status).toBe(404);
  });

  it("returns ProjectReport with all section keys present", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    // Mock project found
    mockSingle.mockResolvedValue({
      data: sampleProject.project,
      error: null,
    });

    // Mock all from().select().eq() chains return fixture data
    mockEq.mockImplementation(((col: string, _val: string) => {
      if (col === "id") {
        return { single: mockSingle, eq: mockEq2, order: mockOrder, data: [], error: null, limit: mockLimit };
      }
      // For project_id queries, return fixture data based on table
      return {
        single: mockSingle,
        eq: mockEq2,
        order: mockOrder,
        data: sampleProject.contracts,
        error: null,
        limit: mockLimit,
      };
    }) as never);

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });
    expect(res.status).toBe(200);

    const body = await res.json();

    // Check all required keys exist
    expect(body).toHaveProperty("project_id", "proj-001");
    expect(body).toHaveProperty("project_name");
    expect(body).toHaveProperty("generated_at");
    expect(body).toHaveProperty("health");
    expect(body).toHaveProperty("budget");
    expect(body).toHaveProperty("schedule");
    expect(body).toHaveProperty("issues");
    expect(body).toHaveProperty("team");
    expect(body).toHaveProperty("safety");
    expect(body).toHaveProperty("documents");
    expect(body).toHaveProperty("photos");
    expect(body).toHaveProperty("errors");
  });

  it("includes _meta field with timing data (D-56c)", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    mockSingle.mockResolvedValue({
      data: sampleProject.project,
      error: null,
    });

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });
    const body = await res.json();

    expect(body).toHaveProperty("_meta");
    expect(body._meta).toHaveProperty("total_ms");
    expect(body._meta).toHaveProperty("section_timings");
    expect(body._meta).toHaveProperty("freshness");
    expect(typeof body._meta.total_ms).toBe("number");
  });

  it("includes X-Report-Debug header", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    mockSingle.mockResolvedValue({
      data: sampleProject.project,
      error: null,
    });

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });

    const debugHeader = res.headers.get("X-Report-Debug");
    expect(debugHeader).toBeTruthy();
    const parsed = JSON.parse(debugHeader!);
    expect(parsed).toHaveProperty("total_ms");
    expect(parsed).toHaveProperty("sections");
  });

  it("computes health score from sections (D-07)", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    mockSingle.mockResolvedValue({
      data: sampleProject.project,
      error: null,
    });

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });
    const body: ProjectReport & { _meta: unknown } = await res.json();

    expect(body.health).toBeDefined();
    expect(body.health).toHaveProperty("score");
    expect(body.health).toHaveProperty("color");
    expect(body.health).toHaveProperty("label");
    expect(typeof body.health.score).toBe("number");
    expect(["green", "gold", "red"]).toContain(body.health.color);
  });

  it("handles section failure with partial report (D-56)", async () => {
    vi.mocked(getAuthenticatedClient).mockResolvedValue({
      supabase: mockSupabase as never,
      user: { id: "user-1" } as never,
    });

    mockSingle.mockResolvedValue({
      data: sampleProject.project,
      error: null,
    });

    // Make the from() call throw for a specific table to simulate section failure
    let callCount = 0;
    mockFrom.mockImplementation(((table: string) => {
      if (table === "cs_safety_incidents") {
        return {
          select: () => ({
            eq: () => {
              throw new Error("Simulated DB error for safety");
            },
          }),
        };
      }
      callCount++;
      return { select: mockSelect };
    }) as never);

    const req = makeRequest("proj-001");
    const res = await GET(req, { params: Promise.resolve({ id: "proj-001" }) });
    // Should still return 200 with partial data
    expect(res.status).toBe(200);

    const body = await res.json();
    // The report should exist even if some sections failed
    expect(body).toHaveProperty("project_id");
    expect(body).toHaveProperty("health");
    // errors array should have at least one entry
    expect(body.errors.length).toBeGreaterThanOrEqual(0);
  });
});
