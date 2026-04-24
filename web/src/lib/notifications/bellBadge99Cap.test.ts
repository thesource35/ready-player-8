// Phase 30 D-15 — bell badge 99+ cap regression
// per D-15 + 30-PARITY-SPEC §Display Cap Rules
//
// Locks the `formatBadge` cap contract shared by HeaderBell.tsx (web) and
// NotificationsStore.formatBadge (iOS). The existing unread.test.ts covers
// some of these cases already; this file ADDS the gap cases flagged by D-15:
//   - exactly 99 (lower boundary of the cap, still raw)
//   - exactly 100 (first value that must render "99+")
//   - 501 (ceiling sanity — still "99+")
//   - 0 and -5 (hidden-badge invariant per §Display Cap Rules)

import { describe, it, expect } from "vitest";
import { formatBadge } from "@/lib/notifications";

describe("formatBadge — D-15 bell/inbox cap parity", () => {
  it("returns empty string at 0 (hidden badge per D-14/D-15)", () => {
    expect(formatBadge(0)).toBe("");
  });
  it("returns empty string for negative counts (defensive per 30-PARITY-SPEC §Display Cap Rules)", () => {
    expect(formatBadge(-5)).toBe("");
  });
  it("returns \"99\" at boundary (per 30-PARITY-SPEC §Display Cap Rules)", () => {
    expect(formatBadge(99)).toBe("99");
  });
  it("returns \"99+\" at exactly 100 (cap threshold per D-15)", () => {
    expect(formatBadge(100)).toBe("99+");
  });
  it("returns \"99+\" for large counts (cap ceiling per D-15)", () => {
    expect(formatBadge(501)).toBe("99+");
  });
});
