// Phase 30 — Project-filter picker server helper + stale-recovery contract (D-07/D-08/D-11)
// Mock-mode contract locked here; live-Supabase path is exercised by the E2E UAT walk.

import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("../supabase/server", () => ({
  createServerSupabase: vi.fn(async () => null), // mock mode
}));

import { fetchProjectMembershipsWithUnread } from "../notifications/server";
import { resolveStalePickerFilter } from "../notifications";

beforeEach(() => {
  vi.clearAllMocks();
});

describe("fetchProjectMembershipsWithUnread (mock-mode)", () => {
  it("returns MOCK_MEMBERSHIPS when Supabase is not configured", async () => {
    const out = await fetchProjectMembershipsWithUnread();
    expect(out.length).toBeGreaterThanOrEqual(1);
    expect(out[0]).toHaveProperty("project_id");
    expect(out[0]).toHaveProperty("project_name");
    expect(out[0]).toHaveProperty("unread_count");
    expect(out[0]).toHaveProperty("latest_created_at");
  });
});

describe("resolveStalePickerFilter (D-11)", () => {
  const memberships = [
    { project_id: "p-1", project_name: "One", unread_count: 0, latest_created_at: null },
    { project_id: "p-2", project_name: "Two", unread_count: 0, latest_created_at: null },
  ];
  it("returns null for a non-member project id", () => {
    expect(resolveStalePickerFilter("p-ghost", memberships)).toBe(null);
  });
  it("returns null for null input", () => {
    expect(resolveStalePickerFilter(null, memberships)).toBe(null);
  });
  it("returns null for empty-string input", () => {
    expect(resolveStalePickerFilter("", memberships)).toBe(null);
  });
  it("returns the id unchanged for a current member", () => {
    expect(resolveStalePickerFilter("p-2", memberships)).toBe("p-2");
  });
});
