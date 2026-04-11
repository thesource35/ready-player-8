import { tool } from "ai";
import { z } from "zod";
import type { createServerSupabase } from "@/lib/supabase/server";

type SupabaseClient = Awaited<ReturnType<typeof createServerSupabase>>;

/* eslint-disable @typescript-eslint/no-explicit-any */

/**
 * Create construction-specific AI tools backed by a Supabase client.
 * If supabase is null (unauthenticated), data-fetching tools return an error.
 * Document generation tools (generate_rfi, draft_change_order) return DRAFT
 * objects only -- they never insert into the database (T-18-03).
 */
export function createConstructionTools(supabase: SupabaseClient) {
  // ---------- Helper: guard against null supabase ----------
  function requireAuth(): { error: string } | null {
    if (!supabase) return { error: "Not authenticated" };
    return null;
  }

  // ---------- AI-01: Data Query Tools ----------

  const get_projects = tool({
    description:
      "Get active construction projects with status, progress, budget, and team",
    inputSchema: z.object({
      status: z
        .string()
        .optional()
        .describe("Filter by status: Active, Delayed, Complete"),
    }),
    execute: async ({ status }: { status?: string }) => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        let query = supabase!.from("cs_projects").select("*").limit(20);
        if (status) query = query.eq("status", status);
        const { data, error } = await query;
        if (error) return { error: error.message };
        return { projects: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch projects" };
      }
    },
  });

  const get_contracts = tool({
    description:
      "Get contracts in bid pipeline with stage, budget, bid due dates",
    inputSchema: z.object({
      stage: z
        .string()
        .optional()
        .describe(
          "Filter by stage: Pursuit, Proposal, Negotiation, Won, Lost"
        ),
    }),
    execute: async ({ stage }: { stage?: string }) => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        let query = supabase!.from("cs_contracts").select("*").limit(20);
        if (stage) query = query.eq("stage", stage);
        const { data, error } = await query;
        if (error) return { error: error.message };
        return { contracts: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch contracts" };
      }
    },
  });

  const get_market_data = tool({
    description:
      "Get construction market data by city including vacancy rates, new business, and trends",
    inputSchema: z.object({}),
    execute: async () => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data, error } = await supabase!
          .from("cs_market_data")
          .select("*")
          .limit(20);
        if (error) return { error: error.message };
        return { market_data: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch market data" };
      }
    },
  });

  const get_rfis = tool({
    description: "Get open RFIs with priority, status, and assignment",
    inputSchema: z.object({}),
    execute: async () => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data, error } = await supabase!
          .from("cs_rfis")
          .select("*")
          .limit(20);
        if (error) return { error: error.message };
        return { rfis: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch RFIs" };
      }
    },
  });

  const get_change_orders = tool({
    description:
      "Get change orders with status, amounts, and approval state",
    inputSchema: z.object({}),
    execute: async () => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data, error } = await supabase!
          .from("cs_change_orders")
          .select("*")
          .limit(20);
        if (error) return { error: error.message };
        return { change_orders: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch change orders" };
      }
    },
  });

  const get_punch_list = tool({
    description: "Get open punch list items with priority and status",
    inputSchema: z.object({}),
    execute: async () => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data, error } = await supabase!
          .from("cs_punch_pro")
          .select("*")
          .limit(20);
        if (error) return { error: error.message };
        return { punch_items: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch punch list" };
      }
    },
  });

  const get_daily_logs = tool({
    description:
      "Get recent daily logs with weather, crew, and work summaries",
    inputSchema: z.object({}),
    execute: async () => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data, error } = await supabase!
          .from("cs_daily_logs")
          .select("*")
          .order("log_date", { ascending: false })
          .limit(10);
        if (error) return { error: error.message };
        return { daily_logs: data ?? [], count: data?.length ?? 0 };
      } catch (err: any) {
        return { error: err.message ?? "Failed to fetch daily logs" };
      }
    },
  });

  // ---------- AI-02: Document Generation ----------

  const generate_rfi = tool({
    description:
      "Generate a draft RFI document from conversation context. Returns a draft for user review -- does NOT save to database.",
    inputSchema: z.object({
      subject: z.string().describe("RFI subject line"),
      details: z
        .string()
        .describe("Detailed description of the information requested"),
      priority: z
        .enum(["HIGH", "MED", "LOW"])
        .describe("Priority level"),
      project_id: z
        .string()
        .optional()
        .describe("Associated project ID"),
    }),
    execute: async ({
      subject,
      details,
      priority,
      project_id,
    }: {
      subject: string;
      details: string;
      priority: "HIGH" | "MED" | "LOW";
      project_id?: string;
    }) => {
      if (!subject.trim()) {
        return { error: "Subject is required" };
      }
      return {
        type: "rfi_draft" as const,
        number: "RFI-DRAFT-" + Date.now(),
        subject,
        details,
        priority,
        project_id: project_id ?? null,
        status: "DRAFT" as const,
        created_at: new Date().toISOString(),
        _action: "review_before_saving" as const,
      };
    },
  });

  // ---------- AI-03: Change Order Draft ----------

  const draft_change_order = tool({
    description:
      "Draft a change order entry from natural language description. Returns a draft for user review -- does NOT save to database.",
    inputSchema: z.object({
      description: z.string().describe("Change order description"),
      amount: z.number().describe("Dollar amount of the change"),
      requested_by: z.string().describe("Who requested the change"),
      project_id: z
        .string()
        .optional()
        .describe("Associated project ID"),
    }),
    execute: async ({
      description,
      amount,
      requested_by,
      project_id,
    }: {
      description: string;
      amount: number;
      requested_by: string;
      project_id?: string;
    }) => {
      if (!description.trim()) {
        return { error: "Description is required" };
      }
      return {
        type: "change_order_draft" as const,
        number: "CO-DRAFT-" + Date.now(),
        description,
        amount,
        requested_by,
        project_id: project_id ?? null,
        status: "DRAFT" as const,
        created_at: new Date().toISOString(),
        _action: "review_before_saving" as const,
      };
    },
  });

  // ---------- AI-04: Bid Analysis ----------

  const analyze_bid = tool({
    description:
      "Analyze a bid's competitiveness using contract and market data",
    inputSchema: z.object({
      contract_id: z.string().describe("Contract ID to analyze"),
    }),
    execute: async ({ contract_id }: { contract_id: string }) => {
      const guard = requireAuth();
      if (guard) return guard;
      try {
        const { data: contract, error: contractErr } = await supabase!
          .from("cs_contracts")
          .select("*")
          .eq("id", contract_id)
          .single();
        if (contractErr || !contract) {
          return { error: "Contract not found" };
        }
        const { data: market_data } = await supabase!
          .from("cs_market_data")
          .select("*");
        return {
          contract,
          market_context: market_data ?? [],
          _analysis_type: "bid_competitiveness" as const,
        };
      } catch (err: any) {
        return { error: err.message ?? "Failed to analyze bid" };
      }
    },
  });

  return {
    get_projects,
    get_contracts,
    get_market_data,
    get_rfis,
    get_change_orders,
    get_punch_list,
    get_daily_logs,
    generate_rfi,
    draft_change_order,
    analyze_bid,
  };
}
