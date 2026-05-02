// Phase 14 — markAllRead respects project filter (D-12)
// We can't easily mock @supabase/ssr cookies in vitest, so this test focuses
// on the contract: in mock-mode (no Supabase), the function should return 0
// without throwing, regardless of whether projectId is passed.

import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../supabase/server", () => ({
  createServerSupabase: vi.fn(async () => null),
}));

import { markAllRead } from "../notifications/server";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("markAllRead (mock-mode)", () => {
  it("returns 0 when Supabase is not configured", async () => {
    const n = await markAllRead();
    expect(n).toBe(0);
  });

  it("returns 0 when projectId filter passed in mock-mode", async () => {
    const n = await markAllRead("project-xyz");
    expect(n).toBe(0);
  });

  it("does not throw on null projectId", async () => {
    await expect(markAllRead(null)).resolves.toBe(0);
  });
});
