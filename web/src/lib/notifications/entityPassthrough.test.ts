// Phase 30 D-24 — entity_id / entity_type passthrough regression.
// Locks the contract that cs_notifications read paths preserve these columns
// unchanged so the deferred deep-link phase can ship with zero wire-format work.
//
// Coverage:
//   1. fetchNotifications returns server entity_id/entity_type unchanged
//   2. null entity fields stay null (no coercion to "" or "unknown")
//   3. MOCK_NOTIFICATIONS fixture carries non-null entity fields on every row
//   4. Notification type accepts string | null for both fields (compile-time)

import { describe, it, expect, vi } from "vitest";
import type { Notification } from "@/lib/supabase/types";

// Build server-shape rows BEFORE importing the SUT so the mock factory closes over them.
const mockRow: Notification = {
  id: "n1",
  user_id: "u1",
  event_id: "e1",
  project_id: "p1",
  category: "assigned_task",
  title: "Test",
  body: "body",
  entity_type: "cs_rfis",
  entity_id: "rfi-42",
  read_at: null,
  dismissed_at: null,
  created_at: "2026-04-22T00:00:00Z",
};

const mockNullRow: Notification = {
  ...mockRow,
  id: "n2",
  entity_type: null,
  entity_id: null,
};

// Thenable that resolves with the fake PostgREST shape so `await q` in the SUT
// reads { data, error } directly from the final link in the chain.
// fetchNotifications chain (with default opts): from → select → eq → order → limit → is
vi.mock("../supabase/server", () => {
  const thenable = {
    then: (resolve: (v: unknown) => void) =>
      resolve({ data: [mockRow, mockNullRow], error: null }),
  };
  const is = () => thenable;
  const limit = () => ({ is });
  const order = () => ({ limit });
  const eq = () => ({ order });
  const select = () => ({ eq });
  const from = () => ({ select });
  return {
    createServerSupabase: async () => ({
      auth: { getUser: async () => ({ data: { user: { id: "u1" } } }) },
      from,
    }),
  };
});

import { fetchNotifications, MOCK_NOTIFICATIONS } from "@/lib/notifications";

describe("entity_id / entity_type passthrough (D-24)", () => {
  it("fetchNotifications preserves entity_type + entity_id from the server row", async () => {
    const rows = await fetchNotifications();
    const row = rows.find((r) => r.id === "n1");
    expect(row).toBeDefined();
    expect(row?.entity_type).toBe("cs_rfis");
    expect(row?.entity_id).toBe("rfi-42");
  });

  it("null entity fields stay null — no coercion to empty string or 'unknown'", async () => {
    const rows = await fetchNotifications();
    const row = rows.find((r) => r.id === "n2");
    expect(row).toBeDefined();
    expect(row?.entity_type).toBeNull();
    expect(row?.entity_id).toBeNull();
  });

  it("MOCK_NOTIFICATIONS fixture keeps entity_type + entity_id populated for deep-link future-prep", () => {
    expect(MOCK_NOTIFICATIONS.length).toBeGreaterThanOrEqual(3);
    for (const n of MOCK_NOTIFICATIONS) {
      expect(n.entity_type, `mock id=${n.id} missing entity_type`).toBeTruthy();
      expect(n.entity_id, `mock id=${n.id} missing entity_id`).toBeTruthy();
    }
  });

  it("Notification type exposes entity_type + entity_id as string | null", () => {
    // Compile-time assertion via assignment: if the type drops either field or
    // narrows it away from `string | null`, tsc fails this file.
    const t: Notification = {
      id: "x",
      user_id: "x",
      event_id: "x",
      project_id: null,
      category: "generic",
      title: "",
      body: null,
      entity_type: null,
      entity_id: null,
      read_at: null,
      dismissed_at: null,
      created_at: "",
    };
    expect(t.entity_type).toBeNull();
    expect(t.entity_id).toBeNull();
  });
});
