// Phase 30 — localStorage key contract lock for the /inbox project-filter picker (D-10)
// The client-side picker writes under this key; keeping it a frozen string is the
// cross-platform parity invariant with the iOS AppStorage key in Phase 30-02.

import { describe, it, expect } from "vitest";
import { LAST_FILTER_STORAGE_KEY } from "../notifications";

describe("LAST_FILTER_STORAGE_KEY contract (D-10)", () => {
  it("is the exact string the iOS side mirrors (web-side localStorage key)", () => {
    expect(LAST_FILTER_STORAGE_KEY).toBe("constructos.notifications.last_filter_project_id");
  });
});
