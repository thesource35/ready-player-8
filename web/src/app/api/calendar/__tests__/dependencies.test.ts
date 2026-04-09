import { describe, it, expect } from "vitest";

describe("/api/calendar/dependencies", () => {
  it("POST rejects A→B when B→A already exists (409 cycle)", () => {
    throw new Error("RED — not yet implemented: cycle detection A↔B (Plan 17-02)");
  });

  it("POST 409 on self-loop A→A", () => {
    throw new Error("RED — not yet implemented: self-loop rejection (Plan 17-02)");
  });
});
