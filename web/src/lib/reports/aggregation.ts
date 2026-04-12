// Pure aggregation functions for report data computation.
// No side effects, no Supabase calls — accepts raw data arrays as arguments.
// All budget fields from Supabase are TEXT type (e.g., "$450,000").

import type {
  HealthScore,
  HealthColor,
  HealthLabel,
  BudgetSection,
  ScheduleSection,
  ScheduleMilestone,
  IssuesSection,
  RfiItem,
  ChangeOrderItem,
  TeamSection,
  ActivityEntry,
  SafetySection,
  SafetyIncident,
  SafetyMonthlyData,
  PortfolioRollup,
  ProjectSummary,
} from "./types";
import { HEALTH_THRESHOLDS, FEATURE_TOTAL } from "./constants";

// ---------- Budget String Parser (T-19-01 mitigation) ----------

/**
 * Parse a Supabase TEXT budget column into a numeric value.
 * Strips $, commas, spaces. Returns 0 for N/A, TBD, ---, empty, null, or unparseable values.
 */
export function parseBudgetString(budget: string): number {
  if (budget == null || typeof budget !== "string") return 0;

  const trimmed = budget.trim();
  if (trimmed === "" || trimmed === "N/A" || trimmed === "TBD" || trimmed === "---") {
    return 0;
  }

  // Preserve leading negative sign, strip all non-numeric characters except decimal point
  const isNegative = trimmed.startsWith("-");
  const cleaned = trimmed.replace(/[^0-9.]/g, "");
  const parsed = parseFloat(cleaned);

  if (isNaN(parsed)) return 0;
  return isNegative ? -parsed : parsed;
}

// ---------- Clamping Helpers (D-56e) ----------

/** Clamp a percentage to [0, 100] */
export function clampBudgetPercent(pct: number): number {
  return Math.min(100, Math.max(0, pct));
}

/** Clamp a count to [0, Infinity] */
export function clampCount(n: number): number {
  return Math.max(0, n);
}

// ---------- Health Score ----------

type HealthInput = {
  budgetSpentPercent: number;
  delayedMilestonePercent: number;
  criticalOpenIssues: number;
};

/**
 * Compute composite health score. Weights: budget 40%, schedule 35%, issues 25%.
 * Null/undefined inputs are treated as perfect (100).
 */
export function computeHealthScore(input: HealthInput): HealthScore {
  const budgetPct = input.budgetSpentPercent ?? null;
  const delayPct = input.delayedMilestonePercent ?? null;
  const criticalIssues = input.criticalOpenIssues ?? null;

  // If all inputs are null, return perfect score
  if (budgetPct === null && delayPct === null && criticalIssues === null) {
    return { score: 100, color: "green", label: "On Track" };
  }

  // Budget score: 100 if <=70% spent, linearly decreasing to 0 at 120% spent
  const budgetScore = budgetPct !== null
    ? clampBudgetPercent(100 - Math.max(0, (budgetPct - 70) * (100 / 50)))
    : 100;

  // Schedule score: 100 if 0% delayed, linearly decreasing to 0 at 50% delayed
  const scheduleScore = delayPct !== null
    ? clampBudgetPercent(100 - (delayPct * 2))
    : 100;

  // Issues score: 100 if 0 critical, decreasing 15 points per critical issue, min 0
  const issuesScore = criticalIssues !== null
    ? clampBudgetPercent(100 - (criticalIssues * 15))
    : 100;

  // Weighted composite
  const rawScore = (budgetScore * 0.4) + (scheduleScore * 0.35) + (issuesScore * 0.25);
  const score = Math.round(clampBudgetPercent(rawScore));

  let color: HealthColor;
  let label: HealthLabel;

  if (score >= HEALTH_THRESHOLDS.green.min) {
    color = "green";
    label = "On Track";
  } else if (score >= HEALTH_THRESHOLDS.gold.min) {
    color = "gold";
    label = "At Risk";
  } else {
    color = "red";
    label = "Critical";
  }

  return { score, color, label };
}

// ---------- Budget Section ----------

type ProjectBudgetInput = {
  budget: string;
  [key: string]: unknown;
};

type ContractInput = {
  budget?: string;
  billed?: number;
  change_order_amount?: number;
  retainage?: number;
  [key: string]: unknown;
};

export function computeBudgetSection(
  project: ProjectBudgetInput,
  contracts: ContractInput[]
): BudgetSection {
  const contractValue = parseBudgetString(project.budget);

  let totalBilled = 0;
  let changeOrderNet = 0;
  let retainage = 0;

  for (const c of contracts) {
    totalBilled += c.billed ?? 0;
    changeOrderNet += c.change_order_amount ?? 0;
    retainage += c.retainage ?? 0;
  }

  const percentComplete = contractValue > 0
    ? Math.round((totalBilled / contractValue) * 100)
    : 0;

  return {
    contractValue,
    totalBilled,
    percentComplete: clampBudgetPercent(percentComplete),
    changeOrderNet,
    retainage,
    spent: totalBilled,
    remaining: contractValue - totalBilled,
  };
}

// ---------- Schedule Section ----------

type TaskInput = {
  id: string;
  name: string;
  percent_complete: number;
  is_critical?: boolean;
  start_date?: string;
  end_date?: string;
  [key: string]: unknown;
};

export function computeScheduleSection(tasks: TaskInput[]): ScheduleSection {
  const milestones: ScheduleMilestone[] = tasks.map((t) => {
    const isComplete = t.percent_complete >= 100;
    let status = "In Progress";
    if (isComplete) {
      status = "Complete";
    } else if (t.percent_complete === 0) {
      status = "Not Started";
    }
    return {
      name: t.name,
      percentComplete: t.percent_complete,
      status,
    };
  });

  // Delayed = not 100% complete AND is_critical
  const delayedCount = tasks.filter(
    (t) => t.percent_complete < 100 && t.is_critical
  ).length;

  return {
    milestones,
    delayedCount,
    totalCount: tasks.length,
  };
}

// ---------- Issues Section ----------

type RfiInput = {
  id: string;
  subject: string;
  status: string;
  created_at: string;
  [key: string]: unknown;
};

type ChangeOrderInput = {
  id: string;
  description: string;
  amount: number;
  status: string;
  [key: string]: unknown;
};

export function computeIssuesSection(
  rfis: RfiInput[],
  changeOrders: ChangeOrderInput[]
): IssuesSection {
  const mappedRfis: RfiItem[] = rfis.map((r) => ({
    id: r.id,
    subject: r.subject,
    status: r.status,
    created_at: r.created_at,
  }));

  const mappedCOs: ChangeOrderItem[] = changeOrders.map((co) => ({
    id: co.id,
    description: co.description,
    amount: co.amount,
    status: co.status,
  }));

  const openRfis = rfis.filter((r) => r.status === "Open").length;
  const pendingCOs = changeOrders.filter((co) => co.status === "Pending").length;
  const totalOpen = openRfis + pendingCOs;

  // Critical = open RFIs (they block work)
  const criticalOpen = openRfis;

  return {
    rfis: mappedRfis,
    changeOrders: mappedCOs,
    criticalOpen: clampCount(criticalOpen),
    totalOpen: clampCount(totalOpen),
  };
}

// ---------- Team Section ----------

type AssignmentInput = {
  id: string;
  member_id?: string;
  role_on_project?: string;
  status?: string;
  [key: string]: unknown;
};

type ActivityInput = {
  user: string;
  action: string;
  timestamp: string;
  [key: string]: unknown;
};

export function computeTeamSection(
  assignments: AssignmentInput[],
  activityFeed: ActivityInput[]
): TeamSection {
  // Count only active members
  const activeMembers = assignments.filter((a) => a.status === "active");
  const memberCount = activeMembers.length;

  // D-14: last 5 activity entries
  const recentActivity: ActivityEntry[] = activityFeed.slice(0, 5).map((a) => ({
    user: a.user,
    action: a.action,
    timestamp: a.timestamp,
  }));

  // Role breakdown from active members
  const roleBreakdown: Record<string, number> = {};
  for (const a of activeMembers) {
    const role = a.role_on_project || "Unassigned";
    roleBreakdown[role] = (roleBreakdown[role] || 0) + 1;
  }

  return { memberCount, recentActivity, roleBreakdown };
}

// ---------- Safety Section ----------

type SafetyInput = {
  id: string;
  description: string;
  severity: string;
  date: string;
  [key: string]: unknown;
};

export function computeSafetySection(
  incidents: SafetyInput[],
  referenceDate: Date = new Date()
): SafetySection {
  if (incidents.length === 0) {
    return {
      totalIncidents: 0,
      severityBreakdown: { minor: 0, moderate: 0, serious: 0 },
      daysSinceLastIncident: -1,
      monthlyData: [],
      incidents: [],
    };
  }

  const severityBreakdown = { minor: 0, moderate: 0, serious: 0 };
  for (const inc of incidents) {
    const sev = inc.severity.toLowerCase();
    if (sev === "minor") severityBreakdown.minor++;
    else if (sev === "moderate") severityBreakdown.moderate++;
    else if (sev === "serious") severityBreakdown.serious++;
  }

  // Sort by date descending to find most recent
  const sorted = [...incidents].sort(
    (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
  );
  const lastDate = new Date(sorted[0].date);
  const daysSinceLastIncident = Math.floor(
    (referenceDate.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24)
  );

  // Group by month (YYYY-MM)
  const monthMap = new Map<string, number>();
  for (const inc of incidents) {
    const d = new Date(inc.date);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    monthMap.set(key, (monthMap.get(key) || 0) + 1);
  }
  const monthlyData: SafetyMonthlyData[] = Array.from(monthMap.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([month, count]) => ({ month, count }));

  const mappedIncidents: SafetyIncident[] = sorted.map((inc) => ({
    id: inc.id,
    description: inc.description,
    severity: inc.severity,
    date: inc.date,
  }));

  return {
    totalIncidents: incidents.length,
    severityBreakdown,
    daysSinceLastIncident,
    monthlyData,
    incidents: mappedIncidents,
  };
}

// ---------- Feature Coverage (D-16c) ----------

type TableCounts = Record<string, number>;

const FEATURE_TABLES = [
  "cs_projects",
  "cs_contracts",
  "cs_project_tasks",
  "cs_team_assignments",
  "cs_field_reports",
  "cs_documents",
];

export function computeFeatureCoverage(tableCounts: TableCounts): {
  active: number;
  total: number;
} {
  let active = 0;
  for (const table of FEATURE_TABLES) {
    if ((tableCounts[table] ?? 0) > 0) active++;
  }
  return { active, total: FEATURE_TOTAL };
}

// ---------- Portfolio Rollup ----------

type PortfolioProjectInput = {
  project: { id: string; name: string; status: string; budget: string; progress?: number; [key: string]: unknown };
  contracts: ContractInput[];
  tasks: TaskInput[];
  rfis: RfiInput[];
  change_orders: ChangeOrderInput[];
  safety_incidents: SafetyInput[];
  table_counts: TableCounts;
};

export function computePortfolioRollup(
  projectInputs: PortfolioProjectInput[]
): PortfolioRollup {
  if (projectInputs.length === 0) {
    return {
      generated_at: new Date().toISOString(),
      health: { score: 100, color: "green", label: "On Track" },
      projects: [],
      totals: { contractValue: 0, totalBilled: 0, changeOrderNet: 0 },
      monthlySpend: [],
    };
  }

  let totalContractValue = 0;
  let totalBilled = 0;
  let totalChangeOrderNet = 0;
  let totalBudgetSpentPct = 0;
  let totalDelayedPct = 0;
  let totalCriticalOpen = 0;

  const projectSummaries: ProjectSummary[] = [];

  for (const input of projectInputs) {
    const budget = computeBudgetSection(input.project, input.contracts);
    const schedule = computeScheduleSection(input.tasks);
    const issues = computeIssuesSection(input.rfis, input.change_orders);
    const coverage = computeFeatureCoverage(input.table_counts);

    const budgetSpentPercent = budget.contractValue > 0
      ? (budget.totalBilled / budget.contractValue) * 100
      : 0;
    const delayedMilestonePercent = schedule.totalCount > 0
      ? (schedule.delayedCount / schedule.totalCount) * 100
      : 0;

    const health = computeHealthScore({
      budgetSpentPercent,
      delayedMilestonePercent,
      criticalOpenIssues: issues.criticalOpen,
    });

    totalContractValue += budget.contractValue;
    totalBilled += budget.totalBilled;
    totalChangeOrderNet += budget.changeOrderNet;
    totalBudgetSpentPct += budgetSpentPercent;
    totalDelayedPct += delayedMilestonePercent;
    totalCriticalOpen += issues.criticalOpen;

    const scheduleHealth = schedule.delayedCount > 0 ? "Delayed" : "On Track";

    projectSummaries.push({
      id: input.project.id,
      name: input.project.name,
      status: input.project.status,
      health,
      contractValue: budget.contractValue,
      billed: budget.totalBilled,
      percentComplete: budget.percentComplete,
      scheduleHealth,
      openIssues: issues.totalOpen,
      safetyIncidents: input.safety_incidents.length,
      featureCoverage: coverage,
    });
  }

  const count = projectInputs.length;
  const portfolioHealth = computeHealthScore({
    budgetSpentPercent: totalBudgetSpentPct / count,
    delayedMilestonePercent: totalDelayedPct / count,
    criticalOpenIssues: totalCriticalOpen,
  });

  return {
    generated_at: new Date().toISOString(),
    health: portfolioHealth,
    projects: projectSummaries,
    totals: {
      contractValue: totalContractValue,
      totalBilled,
      changeOrderNet: totalChangeOrderNet,
    },
    monthlySpend: [],
  };
}
