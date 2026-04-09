// @vitest-environment node
// NOTE: Plan 17-03 will switch this file to `// @vitest-environment jsdom`
// and install jsdom. RED stubs below do not touch the DOM.
import { describe, it, expect, vi, beforeAll } from "vitest";

beforeAll(() => {
  vi.stubEnv("TZ", "America/Los_Angeles");
});

describe("Gantt", () => {
  it("renders one TaskBar per task in window", () => {
    throw new Error("RED — not yet implemented: Gantt render (Plan 17-03)");
  });

  it("pointer drag commits Math.round(deltaPx/dayWidth) day delta", () => {
    throw new Error("RED — not yet implemented: pointer drag day-snap (Plan 17-03)");
  });

  it("DST boundary drag in America/Los_Angeles preserves duration_days", () => {
    expect(process.env.TZ).toBe("America/Los_Angeles");
    throw new Error("RED — not yet implemented: DST-safe drag (Plan 17-03)");
  });
});
