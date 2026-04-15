// Owner: 22-10-PLAN.md Wave 4 — Retention prune job (VIDEO-01-N)
// Will test: prune deletes cs_video_assets rows where retention_expires_at < now(), removes storage
// objects under hls/ and posters/, and calls mux.video.assets.delete for archived live assets.
import { describe, it, expect } from "vitest";

describe("Video retention prune job", () => {
  it.skip("TODO: implemented in Wave 4 plan 22-10-PLAN.md — DB rows + storage objects + Mux assets deleted on expiry", () => {
    expect(true).toBe(true);
  });
});
