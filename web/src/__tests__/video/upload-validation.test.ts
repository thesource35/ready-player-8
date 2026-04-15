// Owner: 22-08-PLAN.md Wave 3 — Client-side upload validation (VIDEO-01-L)
// Will test: >2GB → AppError.clipTooLarge; >60min → AppError.clipTooLong; non-MP4/MOV →
// AppError.unsupportedVideoFormat (all checked before any network call).
import { describe, it, expect } from "vitest";

describe("Clip upload validation", () => {
  it.skip("TODO: implemented in Wave 3 plan 22-08-PLAN.md — size/duration/format guards pre-network", () => {
    expect(true).toBe(true);
  });
});
