// Owner: 29-09-PLAN.md Wave 4 — LIVE-12: scrubber query uses 24h window
import { describe, it, expect } from "vitest";
import { partitionByCutoff, type DroneAsset } from "../useDroneAssets";

function asset(iso: string): DroneAsset {
  return {
    id: iso,
    org_id: "o",
    project_id: "p",
    source_type: "drone",
    status: "ready",
    name: null,
    created_at: iso,
    duration_s: 60,
  };
}

describe("DroneScrubberTimeline 24h window", () => {
  const now = new Date("2026-04-20T12:00:00Z").getTime();

  it("keeps clips within 24h", () => {
    const recent = asset(new Date(now - 60 * 60 * 1000).toISOString()); // 1h ago
    const day = asset(new Date(now - 23 * 60 * 60 * 1000).toISOString()); // 23h ago
    const { within24h, olderThan24h } = partitionByCutoff([recent, day], now);
    expect(within24h).toHaveLength(2);
    expect(olderThan24h).toHaveLength(0);
  });

  it("moves clips > 24h to olderThan24h", () => {
    const old = asset(new Date(now - 25 * 60 * 60 * 1000).toISOString()); // 25h ago
    const rec = asset(new Date(now - 60 * 60 * 1000).toISOString()); // 1h ago
    const { within24h, olderThan24h } = partitionByCutoff([old, rec], now);
    expect(within24h.map((c) => c.id)).toEqual([rec.id]);
    expect(olderThan24h.map((c) => c.id)).toEqual([old.id]);
  });

  it("handles empty clip list", () => {
    const { within24h, olderThan24h } = partitionByCutoff([], now);
    expect(within24h).toHaveLength(0);
    expect(olderThan24h).toHaveLength(0);
  });

  it("treats cutoff as exactly now - 24h", () => {
    const justInside = asset(
      new Date(now - 24 * 60 * 60 * 1000 + 1).toISOString(),
    ); // 24h - 1ms
    const justOutside = asset(
      new Date(now - 24 * 60 * 60 * 1000 - 1).toISOString(),
    ); // 24h + 1ms
    const { within24h, olderThan24h } = partitionByCutoff(
      [justInside, justOutside],
      now,
    );
    expect(within24h.map((c) => c.id)).toEqual([justInside.id]);
    expect(olderThan24h.map((c) => c.id)).toEqual([justOutside.id]);
  });

  it("sorts within24h descending by created_at", () => {
    const a = asset(new Date(now - 3 * 60 * 60 * 1000).toISOString());
    const b = asset(new Date(now - 1 * 60 * 60 * 1000).toISOString());
    const { within24h } = partitionByCutoff([a, b], now);
    expect(within24h.map((c) => c.id)).toEqual([b.id, a.id]);
  });
});
