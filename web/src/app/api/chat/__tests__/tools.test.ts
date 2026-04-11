import { describe, test, expect } from "vitest";
import { createConstructionTools } from "../tools";

/**
 * Mock Supabase client factory for testing AI tools.
 * Returns a minimal client that resolves with provided override data per table.
 */
function mockSupabase(overrides: Record<string, unknown[]> = {}) {
  return {
    from: (table: string) => ({
      select: () => ({
        limit: () => ({
          eq: () =>
            Promise.resolve({
              data: overrides[table] ?? [],
              error: null,
            }),
          then: (resolve: (v: { data: unknown[]; error: null }) => void) =>
            resolve({ data: overrides[table] ?? [], error: null }),
        }),
        eq: () => ({
          single: () =>
            Promise.resolve({
              data: (overrides[table] ?? [])[0] ?? null,
              error: (overrides[table] ?? [])[0] ? null : { message: "not found" },
            }),
        }),
        then: (resolve: (v: { data: unknown[]; error: null }) => void) =>
          resolve({ data: overrides[table] ?? [], error: null }),
      }),
    }),
  } as unknown as ReturnType<typeof import("@supabase/supabase-js").createClient>;
}

// ---------------------------------------------------------------------------
// AI-01: Data Query Tools (get_projects, get_contracts)
// ---------------------------------------------------------------------------
describe("AI-01: Data Query Tools", () => {
  test("get_projects returns project data from Supabase", async () => {
    const tools = createConstructionTools(
      mockSupabase({
        cs_projects: [
          {
            id: "p1",
            name: "Test Project",
            status: "Active",
            progress: 50,
            budget: 1000000,
            client: "ACME",
          },
        ],
      })
    );

    const result = await tools.get_projects.execute({});
    expect(result).toHaveProperty("projects");
    expect(Array.isArray(result.projects)).toBe(true);
    expect(result.projects).toHaveLength(1);
    expect(result.projects[0]).toMatchObject({
      id: "p1",
      name: "Test Project",
    });
  });

  test("get_contracts returns contract data from Supabase", async () => {
    const tools = createConstructionTools(
      mockSupabase({
        cs_contracts: [
          {
            id: "c1",
            title: "Bridge Contract",
            stage: "Proposal",
            budget: 500000,
          },
        ],
      })
    );

    const result = await tools.get_contracts.execute({});
    expect(result).toHaveProperty("contracts");
    expect(Array.isArray(result.contracts)).toBe(true);
    expect(result.contracts).toHaveLength(1);
  });

  test("get_projects returns error when not authenticated", async () => {
    const tools = createConstructionTools(null);

    const result = await tools.get_projects.execute({});
    expect(result).toHaveProperty("error");
    expect(result.error).toBe("Not authenticated");
  });
});

// ---------------------------------------------------------------------------
// AI-02: Document Generation Tool (generate_rfi)
// ---------------------------------------------------------------------------
describe("AI-02: Document Generation - generate_rfi", () => {
  test("generate_rfi returns structured RFI draft", async () => {
    const tools = createConstructionTools(mockSupabase());

    const result = await tools.generate_rfi.execute({
      subject: "Concrete spec",
      details: "Need clarification on mix design",
      priority: "HIGH",
    });

    expect(result).toMatchObject({
      type: "rfi_draft",
      status: "DRAFT",
      subject: "Concrete spec",
      details: "Need clarification on mix design",
      priority: "HIGH",
      _action: "review_before_saving",
    });
  });

  test("generate_rfi requires subject field", async () => {
    const tools = createConstructionTools(mockSupabase());

    const result = await tools.generate_rfi.execute({
      subject: "",
      details: "Some details",
      priority: "LOW",
    });

    expect(result).toHaveProperty("error");
  });
});

// ---------------------------------------------------------------------------
// AI-03: Change Order Draft Tool (draft_change_order)
// ---------------------------------------------------------------------------
describe("AI-03: Change Order Draft - draft_change_order", () => {
  test("draft_change_order returns structured CO draft", async () => {
    const tools = createConstructionTools(mockSupabase());

    const result = await tools.draft_change_order.execute({
      description: "Added fire stops",
      amount: 18500,
      requested_by: "Owner",
    });

    expect(result).toMatchObject({
      type: "change_order_draft",
      status: "DRAFT",
      description: "Added fire stops",
      amount: 18500,
      requested_by: "Owner",
      _action: "review_before_saving",
    });
  });

  test("draft_change_order requires description", async () => {
    const tools = createConstructionTools(mockSupabase());

    const result = await tools.draft_change_order.execute({
      description: "",
      amount: 0,
      requested_by: "",
    });

    expect(result).toHaveProperty("error");
  });
});

// ---------------------------------------------------------------------------
// AI-04: Bid Analysis Tool (analyze_bid)
// ---------------------------------------------------------------------------
describe("AI-04: Bid Analysis - analyze_bid", () => {
  test("analyze_bid fetches contract and market data", async () => {
    const tools = createConstructionTools(
      mockSupabase({
        cs_contracts: [
          {
            id: "c1",
            title: "Bridge Contract",
            stage: "Proposal",
            budget: 500000,
            scope: "Bridge rehabilitation",
          },
        ],
        cs_market_data: [
          { id: "m1", region: "Northeast", segment: "Infrastructure", trend: "Growing" },
          { id: "m2", region: "Northeast", segment: "Commercial", trend: "Stable" },
        ],
      })
    );

    const result = await tools.analyze_bid.execute({ contract_id: "c1" });
    expect(result).toHaveProperty("contract");
    expect(result.contract).toMatchObject({ id: "c1", title: "Bridge Contract" });
    expect(result).toHaveProperty("market_context");
    expect(Array.isArray(result.market_context)).toBe(true);
  });

  test("analyze_bid returns error for missing contract", async () => {
    const tools = createConstructionTools(mockSupabase());

    const result = await tools.analyze_bid.execute({ contract_id: "nonexistent" });
    expect(result).toHaveProperty("error");
    expect(result.error).toBe("Contract not found");
  });
});
