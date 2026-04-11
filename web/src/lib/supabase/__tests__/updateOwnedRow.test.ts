import { describe, it, expect, vi, beforeEach } from "vitest";

// Threat T-17-01-pre: updateOwnedRow must scope by org_id (Information Disclosure).
// This test asserts the query chain includes .eq('org_id', <user_org_id>).
// It is expected to FAIL against the current implementation (which scopes by user_id),
// and this failure is the blocker forcing Plan 17-02 to fix org_id scoping before
// layering the new PATCH route on top of an unscoped helper.

const eqSpy = vi.fn();
const selectSpy = vi.fn();
const singleSpy = vi.fn();
const maybeSingleSpy = vi.fn();
const updateSpy = vi.fn();
const fromSpy = vi.fn();

type Chain = {
  update: typeof updateSpy;
  eq: typeof eqSpy;
  select: typeof selectSpy;
  single: typeof singleSpy;
  maybeSingle: typeof maybeSingleSpy;
};

const chain: Chain = {
  update: updateSpy,
  eq: eqSpy,
  select: selectSpy,
  single: singleSpy,
  maybeSingle: maybeSingleSpy,
};

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: async () => ({
    from: fromSpy,
  }),
}));

describe("updateOwnedRow org_id scoping", () => {
  beforeEach(() => {
    vi.resetModules();
    eqSpy.mockReturnValue(chain);
    updateSpy.mockReturnValue(chain);
    selectSpy.mockReturnValue(chain);
    singleSpy.mockResolvedValue({ data: { id: "row-1" }, error: null });
    // user_orgs lookup returns a valid org for this user
    maybeSingleSpy.mockResolvedValue({
      data: { org_id: "org-123" },
      error: null,
    });
    fromSpy.mockReturnValue(chain);
  });

  it("filters by org_id of authenticated user", async () => {
    const { updateOwnedRow } = await import("@/lib/supabase/fetch");
    await updateOwnedRow("cs_project_tasks", "row-1", "user-1", { name: "x" });

    const calledWithOrgId = eqSpy.mock.calls.some(
      ([column]) => column === "org_id"
    );
    expect(calledWithOrgId).toBe(true);
  });
});
