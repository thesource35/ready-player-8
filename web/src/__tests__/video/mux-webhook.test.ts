// Owner: 22-03-PLAN.md Wave 2 — Mux webhook receiver (VIDEO-01-E)
// Will test: Mux-Signature HMAC verify rejects wrong signature (401); duplicate event_id dedupes via
// cs_video_webhook_events; fixtures: fixtures/mock-mux-webhook-active|disconnected|idle|asset-ready.json.
import { describe, it, expect } from "vitest";

describe("Mux webhook receiver", () => {
  it.skip("TODO: implemented in Wave 2 plan 22-03-PLAN.md — HMAC verify + dedupe via cs_video_webhook_events", () => {
    expect(true).toBe(true);
  });
});
