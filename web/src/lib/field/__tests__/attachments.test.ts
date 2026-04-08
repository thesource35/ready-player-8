import { describe, it, expect, vi, beforeEach } from "vitest";

// Phase 16 FIELD-02: attachments lib unit tests.
// Mocks @/lib/supabase/server so RLS, FK, and success paths are exercised
// without a live Supabase instance.

type PgError = { message: string; code?: string } | null;

let user: { id: string } | null = null;
let insertResp: { error: PgError } = { error: null };
let deleteResp: { error: PgError } = { error: null };
let selectResp: { data: unknown; error: PgError } = { data: [], error: null };

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    from: vi.fn(() => ({
      insert: vi.fn(async () => insertResp),
      delete: () => ({
        eq: () => ({
          eq: () => ({
            eq: async () => deleteResp,
          }),
        }),
      }),
      select: () => ({
        eq: () => ({
          eq: async () => selectResp,
        }),
      }),
    })),
  })),
}));

import {
  attachPhoto,
  detachPhoto,
  listAttachmentsForEntity,
  isFieldEntityType,
  isUuid,
} from "../attachments";

const DOC = "11111111-1111-4111-8111-111111111111";
const ENT = "22222222-2222-4222-8222-222222222222";

beforeEach(() => {
  user = { id: "u1" };
  insertResp = { error: null };
  deleteResp = { error: null };
  selectResp = { data: [], error: null };
});

describe("isFieldEntityType", () => {
  it("accepts new Phase 16 entity types", () => {
    expect(isFieldEntityType("daily_log")).toBe(true);
    expect(isFieldEntityType("safety_incident")).toBe(true);
    expect(isFieldEntityType("punch_item")).toBe(true);
  });
  it("accepts legacy Phase 13 entity types", () => {
    expect(isFieldEntityType("project")).toBe(true);
    expect(isFieldEntityType("rfi")).toBe(true);
  });
  it("rejects unknown values", () => {
    expect(isFieldEntityType("bogus")).toBe(false);
    expect(isFieldEntityType(42)).toBe(false);
    expect(isFieldEntityType(undefined)).toBe(false);
  });
});

describe("isUuid", () => {
  it("accepts v4 uuid", () => {
    expect(isUuid(DOC)).toBe(true);
  });
  it("rejects empty / NaN / malformed", () => {
    expect(isUuid("")).toBe(false);
    expect(isUuid("not-a-uuid")).toBe(false);
    expect(isUuid(NaN)).toBe(false);
  });
});

describe("attachPhoto", () => {
  it("returns 400 for invalid document_id", async () => {
    const res = await attachPhoto("nope", "punch_item", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(400);
  });

  it("returns 400 for invalid entity_type", async () => {
    const res = await attachPhoto(DOC, "bogus", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(400);
  });

  it("returns 400 for empty entity_id", async () => {
    const res = await attachPhoto(DOC, "daily_log", "");
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(400);
  });

  it("returns 401 when no user", async () => {
    user = null;
    const res = await attachPhoto(DOC, "punch_item", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(401);
  });

  it("returns 403 on RLS denial (42501)", async () => {
    insertResp = { error: { message: "rls", code: "42501" } };
    const res = await attachPhoto(DOC, "safety_incident", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(403);
  });

  it("returns 409 on duplicate (23505)", async () => {
    insertResp = { error: { message: "dup", code: "23505" } };
    const res = await attachPhoto(DOC, "punch_item", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(409);
  });

  it("returns 500 on other db error", async () => {
    insertResp = { error: { message: "boom", code: "XX000" } };
    const res = await attachPhoto(DOC, "punch_item", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(500);
  });

  it("returns ok on success", async () => {
    const res = await attachPhoto(DOC, "punch_item", ENT);
    expect(res.ok).toBe(true);
  });
});

describe("detachPhoto", () => {
  it("returns 400 for bad ids", async () => {
    const res = await detachPhoto("x", "punch_item", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(400);
  });

  it("returns ok on successful delete", async () => {
    const res = await detachPhoto(DOC, "daily_log", ENT);
    expect(res.ok).toBe(true);
  });

  it("returns 403 on RLS denial", async () => {
    deleteResp = { error: { message: "rls", code: "42501" } };
    const res = await detachPhoto(DOC, "daily_log", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(403);
  });
});

describe("listAttachmentsForEntity", () => {
  it("returns 400 for bad entity_type", async () => {
    const res = await listAttachmentsForEntity("bogus", ENT);
    expect(res.ok).toBe(false);
    if (!res.ok) expect(res.status).toBe(400);
  });

  it("returns data array on success", async () => {
    selectResp = {
      data: [{ document_id: DOC, entity_type: "punch_item", entity_id: ENT }],
      error: null,
    };
    const res = await listAttachmentsForEntity("punch_item", ENT);
    expect(res.ok).toBe(true);
    if (res.ok) expect(Array.isArray(res.data)).toBe(true);
  });
});
