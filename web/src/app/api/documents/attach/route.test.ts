import { describe, it, expect, vi, beforeEach } from "vitest";

let user: { id: string } | null = null;
let insertResp: { error: { message: string; code?: string } | null } = {
  error: null,
};

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    from: vi.fn(() => ({
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
