// Owner: 22-03-PLAN.md Wave 2 — Mux signed-playback JWT minting (VIDEO-01-E)
// Will test: signPlaybackJWT produces RS256 JWT with sub=playback_id, aud='v', exp<=now+300, kid set.
import { describe, it, expect } from "vitest";

describe("Mux playback JWT signer", () => {
  it.skip("TODO: implemented in Wave 2 plan 22-03-PLAN.md — claims sub/aud/exp/kid/alg RS256", () => {
    expect(true).toBe(true);
  });
});
