// Phase 14 — Unread badge formatting tests
import { describe, it, expect } from "vitest";
import { formatBadge, MOCK_NOTIFICATIONS } from "../notifications";

describe("formatBadge", () => {
  it("returns empty string for zero", () => {
    expect(formatBadge(0)).toBe("");
  });

  it("returns empty string for negative", () => {
    expect(formatBadge(-1)).toBe("");
  });

  it("returns the number for 1..99", () => {
    expect(formatBadge(1)).toBe("1");
    expect(formatBadge(42)).toBe("42");
    expect(formatBadge(99)).toBe("99");
  });

  it("caps at 99+ for 100 and above (D-13)", () => {
    expect(formatBadge(100)).toBe("99+");
    expect(formatBadge(500)).toBe("99+");
    expect(formatBadge(99999)).toBe("99+");
  });
});

describe("MOCK_NOTIFICATIONS", () => {
  it("includes at least one unread row so the badge is visible in dev", () => {
    const unread = MOCK_NOTIFICATIONS.filter((n) => !n.read_at && !n.dismissed_at);
    expect(unread.length).toBeGreaterThan(0);
  });

  it("only contains the D-16 push categories or generic", () => {
    const valid = new Set(["bid_deadline", "safety_alert", "assigned_task", "generic"]);
    for (const n of MOCK_NOTIFICATIONS) {
      expect(valid.has(n.category)).toBe(true);
    }
  });
});
