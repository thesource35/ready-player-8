// Phase 14 — dismiss soft-deletes safely in mock-mode
import { describe, it, expect, vi } from "vitest";

vi.mock("../supabase/server", () => ({
  createServerSupabase: vi.fn(async () => null),
}));

import { dismiss, markRead } from "../notifications";

describe("dismiss (mock-mode)", () => {
  it("returns true without throwing when Supabase is missing", async () => {
    await expect(dismiss("any-id")).resolves.toBe(true);
  });
});

describe("markRead (mock-mode)", () => {
  it("returns true without throwing when Supabase is missing", async () => {
    await expect(markRead("any-id")).resolves.toBe(true);
  });
});
