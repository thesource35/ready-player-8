// Owner: 22-03-PLAN.md Wave 2 — Mux live input provisioning (VIDEO-01-E)
// Will test: POST /api/video/mux/create-live-input returns { live_input_id, stream_key, playback_id, rtmp_url }
// and persists stream_key in cs_video_sources (not exposed to client on list endpoints).
import { describe, it, expect } from "vitest";

describe("Mux create-live-input route", () => {
  it.skip("TODO: implemented in Wave 2 plan 22-03-PLAN.md — returns live_input_id/stream_key/playback_id/rtmp_url schema", () => {
    expect(true).toBe(true);
  });
});
