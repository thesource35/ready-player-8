import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import {
  computeBudgetSection,
  computeScheduleSection,
  computeIssuesSection,
  computeHealthScore,
  computeFeatureCoverage,
  clampBudgetPercent,
} from "@/lib/reports/aggregation";
import type { PortfolioRollup, ProjectSummary } from "@/lib/reports/types";

// D-46: cap at 200 projects with notice if exceeded
const MAX_PROJECTS = 200;

// D-39: valid status filter values
const VALID_STATUSES = [
  "Active",
  "Delayed",
  "Completed",
  "On Hold",
  "Cancelled",
];

/** Sanitize a query parameter string (T-19-11) */
function sanitizeParam(val: string | null): string | null {
  if (!val) return null;
  // Strip any characters that are not alphanumeric, spaces, hyphens, underscores, or dots
  return val.replace(/[^a-zA-Z0-9 \-_.]/g, "").trim() || null;
}

export async function GET(req: Request) {
  // Rate limiting
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  // Auth check (T-19-08)
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  const startTime = Date.now();
  const url = new URL(req.url);

  // D-39: accept query params: status, date_range, project_type, client, budget_range
  const statusParam = sanitizeParam(url.searchParams.get("status"));
  const projectType = sanitizeParam(url.searchParams.get("project_type"));
  const client = sanitizeParam(url.searchParams.get("client"));
  // D-46b: accept optional compare_period param
  const comparePeriod = sanitizeParam(url.searchParams.get("compare_period"));

  // T-19-11: validate status param
  if (statusParam && !VALID_STATUSES.includes(statusParam)) {
    return NextResponse.json(
      { error: `Invalid status filter. Must be one of: ${VALID_STATUSES.join(", ")}` },
      { status: 400 }
    );
  }

  // Query all user's projects (RLS-filtered)
  let projectQuery = supabase.from("cs_projects").select("*");
  if (statusParam) {
    projectQuery = projectQuery.eq("status", statusParam);
  }
  if (projectType) {
    projectQuery = projectQuery.eq("type", projectType);
  }
  if (client) {
    projectQuery = projectQuery.eq("client", client);
  }
  // D-46: cap at MAX_PROJECTS + 1 to detect overflow
  projectQuery = projectQuery.limit(MAX_PROJECTS + 1);

  const { data: allProjects, error: projectsErr } = await projectQuery;

  if (projectsErr) {
    console.error("[rollup] Failed to fetch projects:", projectsErr.message);
    return NextResponse.json(
      { error: "Failed to load projects" },
      { status: 500 }
    );
  }

  const projects = allProjects ?? [];
  const capped = projects.length > MAX_PROJECTS;
  const projectSlice = capped ? projects.slice(0, MAX_PROJECTS) : projects;

  // Fetch per-project data in parallel
  const projectIds = projectSlice.map(
    (p: Record<string, unknown>) => p.id as string
  );

  // Batch fetch all related data
  const [contractsRes, tasksRes, rfisRes, cosRes, safetyRes] =
    await Promise.all([
      supabase
        .from("cs_contracts")
        .select("*")
        .in("project_id", projectIds.length > 0 ? projectIds : [""]),
      supabase
        .from("cs_project_tasks")
        .select("*")
        .in("project_id", projectIds.length > 0 ? projectIds : [""]),
      supabase
        .from("cs_rfis")
        .select("*")
        .in("project_id", projectIds.length > 0 ? projectIds : [""]),
      supabase
        .from("cs_change_orders")
        .select("*")
        .in("project_id", projectIds.length > 0 ? projectIds : [""]),
      supabase
        .from("cs_safety_incidents")
        .select("*")
        .in("project_id", projectIds.length > 0 ? projectIds : [""]),
    ]);

  const allContracts = contractsRes.data ?? [];
  const allTasks = tasksRes.data ?? [];
  const allRfis = rfisRes.data ?? [];
  const allCOs = cosRes.data ?? [];
  const allSafety = safetyRes.data ?? [];

  // Group data by project_id
  function groupBy<T extends Record<string, unknown>>(
    items: T[],
    key: string
  ): Record<string, T[]> {
    const map: Record<string, T[]> = {};
    for (const item of items) {
      const k = String(item[key] ?? "");
      if (!map[k]) map[k] = [];
      map[k].push(item);
    }
    return map;
  }

  const contractsByProject = groupBy(allContracts, "project_id");
  const tasksByProject = groupBy(allTasks, "project_id");
  const rfisByProject = groupBy(allRfis, "project_id");
  const cosByProject = groupBy(allCOs, "project_id");
  const safetyByProject = groupBy(allSafety, "project_id");

  // Compute per-project summaries
  let totalContractValue = 0;
  let totalBilled = 0;
  let totalChangeOrderNet = 0;
  let totalBudgetSpentPct = 0;
  let totalDelayedPct = 0;
  let totalCriticalOpen = 0;
  const monthlySpendMap = new Map<string, number>();

  const projectSummaries: ProjectSummary[] = [];

  for (const proj of projectSlice) {
    const pid = proj.id as string;
    const contracts = contractsByProject[pid] ?? [];
    const tasks = tasksByProject[pid] ?? [];
    const rfis = rfisByProject[pid] ?? [];
    const cos = cosByProject[pid] ?? [];
    const incidents = safetyByProject[pid] ?? [];

    const budget = computeBudgetSection(
      { budget: (proj.budget as string) ?? "0" },
      contracts
    );
    const schedule = computeScheduleSection(tasks);
    const issues = computeIssuesSection(rfis, cos);

    // D-16c: feature coverage (simplified — count non-zero tables per project)
    const tableCounts: Record<string, number> = {
      cs_projects: 1,
      cs_contracts: contracts.length,
      cs_project_tasks: tasks.length,
      cs_team_assignments: 0, // would need separate query; approximate
      cs_field_reports: 0,
      cs_documents: 0,
    };
    const coverage = computeFeatureCoverage(tableCounts);

    const budgetSpentPercent =
      budget.contractValue > 0
        ? (budget.totalBilled / budget.contractValue) * 100
        : 0;
    const delayedMilestonePercent =
      schedule.totalCount > 0
        ? (schedule.delayedCount / schedule.totalCount) * 100
        : 0;

    const health = computeHealthScore({
      budgetSpentPercent: clampBudgetPercent(budgetSpentPercent),
      delayedMilestonePercent,
      criticalOpenIssues: issues.criticalOpen,
    });

    totalContractValue += budget.contractValue;
    totalBilled += budget.totalBilled;
    totalChangeOrderNet += budget.changeOrderNet;
    totalBudgetSpentPct += budgetSpentPercent;
    totalDelayedPct += delayedMilestonePercent;
    totalCriticalOpen += issues.criticalOpen;

    // D-43: monthly spend trend data — aggregate billed amounts by month
    // Using contracts with billed > 0 as proxy for monthly spend
    if (budget.totalBilled > 0) {
      const now = new Date();
      const monthKey = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
      monthlySpendMap.set(
        monthKey,
        (monthlySpendMap.get(monthKey) ?? 0) + budget.totalBilled
      );
    }

    const scheduleHealth =
      schedule.delayedCount > 0 ? "Delayed" : "On Track";

    projectSummaries.push({
      id: pid,
      name: (proj.name as string) ?? "Unknown",
      status: (proj.status as string) ?? "Unknown",
      health,
      contractValue: budget.contractValue,
      billed: budget.totalBilled,
      percentComplete: budget.percentComplete,
      scheduleHealth,
      openIssues: issues.totalOpen,
      safetyIncidents: incidents.length,
      featureCoverage: coverage,
    });
  }

  // D-41: portfolio-level aggregate health score
  const count = projectSlice.length || 1;
  const portfolioHealth = computeHealthScore({
    budgetSpentPercent: totalBudgetSpentPct / count,
    delayedMilestonePercent: totalDelayedPct / count,
    criticalOpenIssues: totalCriticalOpen,
  });

  const monthlySpend = Array.from(monthlySpendMap.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([month, amount]) => ({ month, amount }));

  const now = new Date().toISOString();
  const totalMs = Date.now() - startTime;

  const rollup: PortfolioRollup = {
    generated_at: now,
    health: portfolioHealth,
    projects: projectSummaries,
    totals: {
      contractValue: totalContractValue,
      totalBilled,
      changeOrderNet: totalChangeOrderNet,
    },
    monthlySpend,
  };

  const responseBody = {
    ...rollup,
    _meta: {
      generated_at: now,
      total_ms: totalMs,
      project_count: projectSlice.length,
      capped,
      max_projects: MAX_PROJECTS,
      filters: {
        status: statusParam,
        project_type: projectType,
        client,
        compare_period: comparePeriod,
      },
    },
  };

  const debugHeader = JSON.stringify({
    total_ms: totalMs,
    project_count: projectSlice.length,
    capped,
  });

  return NextResponse.json(responseBody, {
    status: 200,
    headers: {
      "X-Report-Debug": debugHeader,
      ...getRateLimitHeaders(rl),
    },
  });
}
