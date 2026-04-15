// Owner: 22-03-PLAN.md Wave 2 — Rate limits on video token/URL endpoints (VIDEO-01-E)
// Will test: 30 req/min/IP on /api/video/mux/playback-token, /api/video/vod/playback-url, and
// /api/portal/video/playback-token. 31st request returns 429 with Retry-After header.
import { describe, it, expect } from "vitest";

describe("Video endpoint rate limits", () => {
  it.skip("TODO: implemented in Wave 2 plan 22-03-PLAN.md — 30/min/IP, 31st = 429 + Retry-After", () => {
    expect(true).toBe(true);
  });
});
