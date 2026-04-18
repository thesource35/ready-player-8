import { describe, it, expect, vi, beforeEach } from "vitest";

let user: { id: string } | null = null;
let insertResp: { error: { message: string; code?: string } | null } = {
  error: null,
};
// Phase 26 pre-flight mock state. `preflightExists` toggles whether the
// entity existence SELECT returns a row (true) or null (false). Tracks the
// tables queried so assertions can verify the correct table-name lookup.
let preflightExists = true;
let preflightError: { message: string } | null = null;
const preflightTablesQueried: string[] = [];

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    from: vi.fn((table: string) => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          maybeSingle: vi.fn(async () => {
            preflightTablesQueried.push(table);
            if (preflightError) return { data: null, error: preflightError };
            return {
              data: preflightExists ? { id: "exists" } : null,
              error: null,
            };
          }),
        })),
      })),
      insert: vi.fn(async () => insertResp),
    })),
  })),
}));

import { POST } from "./route";

function jsonReq(body: unknown): Request {
  return new Request("http://x/api/documents/attach", {
    method: "POST",
    body: JSON.stringify(body),
    headers: { "content-type": "application/json" },
  });
}

beforeEach(() => {
  user = { id: "u1" };
  insertResp = { error: null };
  preflightExists = true;
  preflightError = null;
  preflightTablesQueried.length = 0;
});

describe("POST /api/documents/attach", () => {
  it("returns 401 when no user", async () => {
    user = null;
    const res = await POST(jsonReq({}));
    expect(res.status).toBe(401);
  });

  it("returns 400 on invalid JSON body", async () => {
    const bad = new Request("http://x/api/documents/attach", {
      method: "POST",
      body: "not json",
      headers: { "content-type": "application/json" },
    });
    const res = await POST(bad);
    expect(res.status).toBe(400);
  });

  it("returns 400 when missing fields", async () => {
    const res = await POST(jsonReq({ document_id: "d1" }));
    expect(res.status).toBe(400);
  });

  it("returns 400 when entity_type invalid", async () => {
    const res = await POST(
      jsonReq({ document_id: "d1", entity_type: "bogus", entity_id: "e1" })
    );
    expect(res.status).toBe(400);
  });

  it("returns 409 on duplicate (23505)", async () => {
    insertResp = { error: { message: "dup", code: "23505" } };
    const res = await POST(
      jsonReq({ document_id: "d1", entity_type: "project", entity_id: "p1" })
    );
    expect(res.status).toBe(409);
  });

  it("returns 500 on other db error", async () => {
    insertResp = { error: { message: "boom", code: "XX000" } };
    const res = await POST(
      jsonReq({ document_id: "d1", entity_type: "project", entity_id: "p1" })
    );
    expect(res.status).toBe(500);
  });

  it("returns 200 ok on success", async () => {
    const res = await POST(
      jsonReq({ document_id: "d1", entity_type: "project", entity_id: "p1" })
    );
    expect(res.status).toBe(200);
    const json = (await res.json()) as { ok: boolean };
    expect(json.ok).toBe(true);
  });
});

describe("POST /api/documents/attach — Phase 26 pre-flight (D-06)", () => {
  it("returns 404 with '<entity_type> not found' when rfi entity missing", async () => {
    preflightExists = false;
    const res = await POST(
      jsonReq({ document_id: "d1", entity_type: "rfi", entity_id: "missing" })
    );
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("rfi not found");
    expect(preflightTablesQueried).toContain("cs_rfis");
  });

  it("returns 404 when daily_log entity missing", async () => {
    preflightExists = false;
    const res = await POST(
      jsonReq({
        document_id: "d1",
        entity_type: "daily_log",
        entity_id: "missing",
      })
    );
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("daily_log not found");
    expect(preflightTablesQueried).toContain("cs_daily_logs");
  });

  it("returns 404 when safety_incident entity missing", async () => {
    preflightExists = false;
    const res = await POST(
      jsonReq({
        document_id: "d1",
        entity_type: "safety_incident",
        entity_id: "missing",
      })
    );
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("safety_incident not found");
    expect(preflightTablesQueried).toContain("cs_safety_incidents");
  });

  it("returns 404 when punch_item entity missing", async () => {
    preflightExists = false;
    const res = await POST(
      jsonReq({
        document_id: "d1",
        entity_type: "punch_item",
        entity_id: "missing",
      })
    );
    expect(res.status).toBe(404);
    const json = (await res.json()) as { error: string };
    expect(json.error).toBe("punch_item not found");
    expect(preflightTablesQueried).toContain("cs_punch_items");
  });

  it("returns 500 when pre-flight lookup itself errors", async () => {
    preflightError = { message: "pg boom" };
    const res = await POST(
      jsonReq({
        document_id: "d1",
        entity_type: "rfi",
        entity_id: "whatever",
      })
    );
    expect(res.status).toBe(500);
  });

  it("proceeds to insert when entity exists (no regression)", async () => {
    preflightExists = true;
    const res = await POST(
      jsonReq({
        document_id: "d1",
        entity_type: "submittal",
        entity_id: "s1",
      })
    );
    expect(res.status).toBe(200);
    expect(preflightTablesQueried).toContain("cs_submittals");
  });
});
