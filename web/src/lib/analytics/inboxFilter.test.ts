import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock BEFORE importing the module under test so the factory hoist is consistent.
vi.mock("@vercel/analytics", () => ({ track: vi.fn() }));

import {
  INBOX_FILTER_CHANGED_EVENT,
  sanitizeInboxFilterPayload,
  emitInboxFilterChanged,
} from "./inboxFilter";
import { track } from "@vercel/analytics";

describe("inbox_filter_changed payload (D-17)", () => {
  beforeEach(() => {
    (track as unknown as ReturnType<typeof vi.fn>).mockClear();
  });

  it("event name matches the D-17 canonical string", () => {
    expect(INBOX_FILTER_CHANGED_EVENT).toBe("inbox_filter_changed");
  });

  it("null from/to serialize to the 'all' sentinel", () => {
    const p = sanitizeInboxFilterPayload(null, null, 5);
    expect(p.from_project_id).toBe("all");
    expect(p.to_project_id).toBe("all");
    expect(p.unread_count_at_change).toBe(5);
  });

  it("UUID from/to pass through unchanged", () => {
    const p = sanitizeInboxFilterPayload("uuid-A", "uuid-B", 12);
    expect(p.from_project_id).toBe("uuid-A");
    expect(p.to_project_id).toBe("uuid-B");
  });

  it("payload has exactly the three allowed keys — no PII leakage", () => {
    const p = sanitizeInboxFilterPayload("u1", "u2", 7);
    expect(Object.keys(p).sort()).toEqual([
      "from_project_id",
      "to_project_id",
      "unread_count_at_change",
    ]);
  });

  it("negative unread count clamps to 0", () => {
    const p = sanitizeInboxFilterPayload("u1", "u2", -5);
    expect(p.unread_count_at_change).toBe(0);
  });

  it("non-integer unread count floors to an integer", () => {
    const p = sanitizeInboxFilterPayload("u1", "u2", 3.9);
    expect(p.unread_count_at_change).toBe(3);
  });

  it("emitInboxFilterChanged calls track with event name + sanitized payload", () => {
    emitInboxFilterChanged(null, "uuid-X", 42);
    expect(track).toHaveBeenCalledTimes(1);
    expect(track).toHaveBeenCalledWith("inbox_filter_changed", {
      from_project_id: "all",
      to_project_id: "uuid-X",
      unread_count_at_change: 42,
    });
  });
});
