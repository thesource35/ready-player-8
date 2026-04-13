import { describe, it, expect } from "vitest";
import { TRAFFIC_COLORS } from "@/lib/maps/types";

describe("Traffic Overlay (MAP-02)", () => {
  it.todo("adds mapbox-traffic vector source when TRAFFIC enabled");
  it.todo("removes traffic source and layer when TRAFFIC disabled");
  it.todo("re-adds traffic layer after setStyle satellite toggle");

  it("maps congestion levels to theme colors", () => {
    expect(TRAFFIC_COLORS.low).toBe("#69D294");
    expect(TRAFFIC_COLORS.moderate).toBe("#FCC757");
    expect(TRAFFIC_COLORS.heavy).toBe("#FF8C42");
    expect(TRAFFIC_COLORS.severe).toBe("#D94D48");
  });
});
