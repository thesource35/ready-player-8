import { describe, it, expect } from "vitest";

describe("/api/calendar/tasks", () => {
  it("GET returns tasks for project_id", () => {
    throw new Error("RED — not yet implemented: GET /api/calendar/tasks?project_id (Plan 17-02)");
  });

  it("POST validates start<=end", () => {
    throw new Error("RED — not yet implemented: POST /api/calendar/tasks start<=end validation (Plan 17-02)");
  });

  it("PATCH /[id] preserves duration on date move", () => {
    throw new Error("RED — not yet implemented: PATCH preserves duration_days on drag (Plan 17-02)");
  });

  it("PATCH rejects non-ISO date strings with 400", () => {
    throw new Error("RED — not yet implemented: PATCH rejects TZ-naive dates with 400 (Plan 17-02)");
  });
});
