import { describe, it, expect } from "vitest";
import sampleProject from "./fixtures/sample-project.json";
import samplePortfolio from "./fixtures/sample-portfolio.json";
import {
  parseBudgetString,
  clampBudgetPercent,
  clampCount,
  computeHealthScore,
  computeBudgetSection,
  computeScheduleSection,
  computeIssuesSection,
  computeTeamSection,
  computeSafetySection,
  computePortfolioRollup,
  computeFeatureCoverage,
} from "../aggregation";

// ---------- parseBudgetString ----------

describe("parseBudgetString", () => {
  it("parses dollar amount with commas", () => {
    expect(parseBudgetString("$450,000")).toBe(450000);
  });

  it("parses plain number string", () => {
    expect(parseBudgetString("1234.56")).toBe(1234.56);
  });

  it('returns 0 for "N/A"', () => {
    expect(parseBudgetString("N/A")).toBe(0);
  });

  it('returns 0 for "TBD"', () => {
    expect(parseBudgetString("TBD")).toBe(0);
  });

  it("returns 0 for empty string", () => {
    expect(parseBudgetString("")).toBe(0);
  });

  it('returns 0 for "---"', () => {
    expect(parseBudgetString("---")).toBe(0);
  });

  it("returns 0 for null/undefined cast to string", () => {
    // Defensive: Supabase could return null for a TEXT column
    expect(parseBudgetString(null as unknown as string)).toBe(0);
    expect(parseBudgetString(undefined as unknown as string)).toBe(0);
  });

  it("returns 0 for random text", () => {
    expect(parseBudgetString("pending approval")).toBe(0);
  });

  it("parses number with spaces", () => {
    expect(parseBudgetString("$ 1,000,000")).toBe(1000000);
  });

  it("parses negative amounts", () => {
    expect(parseBudgetString("-$5,000")).toBe(-5000);
  });
});

// ---------- clampBudgetPercent ----------

describe("clampBudgetPercent", () => {
  it("clamps values above 100 to 100", () => {
    expect(clampBudgetPercent(150)).toBe(100);
  });

  it("clamps negative values to 0", () => {
    expect(clampBudgetPercent(-10)).toBe(0);
  });

  it("passes through normal values", () => {
    expect(clampBudgetPercent(65)).toBe(65);
  });

  it("handles edge values 0 and 100", () => {
    expect(clampBudgetPercent(0)).toBe(0);
    expect(clampBudgetPercent(100)).toBe(100);
  });
});

// ---------- clampCount ----------

describe("clampCount", () => {
  it("clamps negative values to 0", () => {
    expect(clampCount(-5)).toBe(0);
  });

  it("passes through zero", () => {
    expect(clampCount(0)).toBe(0);
  });

  it("passes through positive values", () => {
    expect(clampCount(42)).toBe(42);
  });
});

// ---------- computeHealthScore ----------

describe("computeHealthScore", () => {
  it("returns green for healthy project", () => {
    const result = computeHealthScore({
      budgetSpentPercent: 50,
      delayedMilestonePercent: 0,
      criticalOpenIssues: 0,
    });
    expect(result.score).toBeGreaterThanOrEqual(80);
    expect(result.color).toBe("green");
    expect(result.label).toBe("On Track");
  });

  it("returns red for troubled project", () => {
    const result = computeHealthScore({
      budgetSpentPercent: 95,
      delayedMilestonePercent: 40,
      criticalOpenIssues: 5,
    });
    expect(result.score).toBeLessThan(60);
    expect(result.color).toBe("red");
    expect(result.label).toBe("Critical");
  });

  it("returns gold for at-risk project", () => {
    const result = computeHealthScore({
      budgetSpentPercent: 75,
      delayedMilestonePercent: 20,
      criticalOpenIssues: 2,
    });
    expect(result.score).toBeGreaterThanOrEqual(60);
    expect(result.score).toBeLessThan(80);
    expect(result.color).toBe("gold");
    expect(result.label).toBe("At Risk");
  });

  it("returns green with score 100 for null/undefined sections", () => {
    const result = computeHealthScore({
      budgetSpentPercent: null as unknown as number,
      delayedMilestonePercent: null as unknown as number,
      criticalOpenIssues: null as unknown as number,
    });
    expect(result.score).toBe(100);
    expect(result.color).toBe("green");
  });

  it("clamps score to 0-100 range", () => {
    const result = computeHealthScore({
      budgetSpentPercent: 200,
      delayedMilestonePercent: 100,
      criticalOpenIssues: 50,
    });
    expect(result.score).toBeGreaterThanOrEqual(0);
    expect(result.score).toBeLessThanOrEqual(100);
  });
});

// ---------- computeBudgetSection ----------

describe("computeBudgetSection", () => {
  it("computes correct budget from sample project data", () => {
    const result = computeBudgetSection(
      sampleProject.project,
      sampleProject.contracts
    );
    // contractValue = parseBudgetString("$450,000") = 450000
    expect(result.contractValue).toBe(450000);
    // totalBilled = 85000 + 140000 + 0 = 225000
    expect(result.totalBilled).toBe(225000);
    // percentComplete = (225000 / 450000) * 100 = 50
    expect(result.percentComplete).toBe(50);
    // changeOrderNet = 5000 + (-3000) + 0 = 2000
    expect(result.changeOrderNet).toBe(2000);
    // retainage = 8500 + 14000 + 0 = 22500
    expect(result.retainage).toBe(22500);
    // spent = totalBilled = 225000
    expect(result.spent).toBe(225000);
    // remaining = 450000 - 225000 = 225000
    expect(result.remaining).toBe(225000);
  });

  it("handles project with no contracts", () => {
    const result = computeBudgetSection(sampleProject.project, []);
    expect(result.contractValue).toBe(450000);
    expect(result.totalBilled).toBe(0);
    expect(result.percentComplete).toBe(0);
    expect(result.changeOrderNet).toBe(0);
    expect(result.retainage).toBe(0);
  });

  it("handles project with N/A budget", () => {
    const result = computeBudgetSection(
      { ...sampleProject.project, budget: "N/A" },
      []
    );
    expect(result.contractValue).toBe(0);
    expect(result.percentComplete).toBe(0);
  });
});

// ---------- computeScheduleSection ----------

describe("computeScheduleSection", () => {
  it("computes milestones from sample tasks", () => {
    const result = computeScheduleSection(sampleProject.tasks);
    expect(result.milestones).toHaveLength(5);
    expect(result.totalCount).toBe(5);
    // Tasks with percent_complete < 100 and past end_date or is_critical
    // are considered; let implementation decide delayed logic
    expect(result.milestones[0].name).toBe("Excavation");
    expect(result.milestones[0].percentComplete).toBe(100);
  });

  it("handles empty tasks", () => {
    const result = computeScheduleSection([]);
    expect(result.milestones).toHaveLength(0);
    expect(result.delayedCount).toBe(0);
    expect(result.totalCount).toBe(0);
  });
});

// ---------- computeIssuesSection ----------

describe("computeIssuesSection", () => {
  it("computes issues from sample data", () => {
    const result = computeIssuesSection(
      sampleProject.rfis,
      sampleProject.change_orders
    );
    expect(result.rfis).toHaveLength(3);
    expect(result.changeOrders).toHaveLength(3);
    // Open RFIs: rfi-002, rfi-003 = 2
    expect(result.totalOpen).toBe(2);
    // criticalOpen = open RFIs (simplified — all open are treated as needing attention)
    expect(result.criticalOpen).toBeGreaterThanOrEqual(0);
  });

  it("handles empty arrays", () => {
    const result = computeIssuesSection([], []);
    expect(result.rfis).toHaveLength(0);
    expect(result.changeOrders).toHaveLength(0);
    expect(result.totalOpen).toBe(0);
    expect(result.criticalOpen).toBe(0);
  });
});

// ---------- computeTeamSection ----------

describe("computeTeamSection", () => {
  it("computes team from sample data", () => {
    const result = computeTeamSection(
      sampleProject.team_assignments,
      sampleProject.activity_feed
    );
    // 4 active members (ta-005 is inactive)
    expect(result.memberCount).toBe(4);
    // D-14: last 5 activity entries
    expect(result.recentActivity).toHaveLength(5);
    expect(result.recentActivity[0].user).toBe("Jane Smith");
    // Role breakdown
    expect(result.roleBreakdown["Foreman"]).toBe(2);
    expect(result.roleBreakdown["Project Manager"]).toBe(1);
  });

  it("handles empty team", () => {
    const result = computeTeamSection([], []);
    expect(result.memberCount).toBe(0);
    expect(result.recentActivity).toHaveLength(0);
    expect(Object.keys(result.roleBreakdown)).toHaveLength(0);
  });
});

// ---------- computeSafetySection ----------

describe("computeSafetySection", () => {
  it("computes safety from sample incidents", () => {
    const result = computeSafetySection(
      sampleProject.safety_incidents,
      new Date("2025-06-15")
    );
    expect(result.totalIncidents).toBe(3);
    expect(result.severityBreakdown.minor).toBe(2);
    expect(result.severityBreakdown.moderate).toBe(1);
    expect(result.severityBreakdown.serious).toBe(0);
    // Days since last incident (2025-05-28 to 2025-06-15 = 18 days)
    expect(result.daysSinceLastIncident).toBe(18);
    expect(result.incidents).toHaveLength(3);
    // Monthly data should group by month
    expect(result.monthlyData.length).toBeGreaterThan(0);
  });

  it("handles no incidents", () => {
    const result = computeSafetySection([], new Date("2025-06-15"));
    expect(result.totalIncidents).toBe(0);
    expect(result.severityBreakdown).toEqual({ minor: 0, moderate: 0, serious: 0 });
    expect(result.daysSinceLastIncident).toBe(-1);
    expect(result.monthlyData).toHaveLength(0);
    expect(result.incidents).toHaveLength(0);
  });
});

// ---------- computeFeatureCoverage ----------

describe("computeFeatureCoverage", () => {
  it("counts active features from table counts", () => {
    const result = computeFeatureCoverage(sampleProject.table_counts);
    // All 6 tables have counts > 0
    expect(result.active).toBe(6);
    expect(result.total).toBe(6);
  });

  it("counts zero for empty table counts", () => {
    const result = computeFeatureCoverage({
      cs_projects: 0,
      cs_contracts: 0,
      cs_project_tasks: 0,
      cs_team_assignments: 0,
      cs_field_reports: 0,
      cs_documents: 0,
    });
    expect(result.active).toBe(0);
    expect(result.total).toBe(6);
  });

  it("handles partial feature usage", () => {
    const result = computeFeatureCoverage({
      cs_projects: 1,
      cs_contracts: 2,
      cs_project_tasks: 0,
      cs_team_assignments: 0,
      cs_field_reports: 0,
      cs_documents: 0,
    });
    expect(result.active).toBe(2);
    expect(result.total).toBe(6);
  });
});

// ---------- computePortfolioRollup ----------

describe("computePortfolioRollup", () => {
  it("aggregates totals across multiple projects", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);
    expect(result.projects).toHaveLength(3);

    // Total contract values: 450000 + 800000 + 1200000 = 2450000
    // Note: portfolio uses parseBudgetString on each project.budget
    expect(result.totals.contractValue).toBe(2450000);

    // Total billed: (85000+140000) + (400000+250000) + 1100000 = 1975000
    expect(result.totals.totalBilled).toBe(1975000);

    // Total change orders: (5000-3000) + (50000+10000) + 200000 = 262000
    expect(result.totals.changeOrderNet).toBe(262000);

    // Should have generated_at
    expect(result.generated_at).toBeTruthy();

    // Overall health should be computed
    expect(result.health.color).toBeDefined();
    expect(result.health.score).toBeGreaterThanOrEqual(0);
  });

  it("handles empty projects array", () => {
    const result = computePortfolioRollup([]);
    expect(result.projects).toHaveLength(0);
    expect(result.totals.contractValue).toBe(0);
    expect(result.totals.totalBilled).toBe(0);
    expect(result.totals.changeOrderNet).toBe(0);
    expect(result.health.score).toBe(100);
    expect(result.health.color).toBe("green");
  });

  it("includes per-project summaries with health scores", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);
    const proj1 = result.projects.find((p) => p.id === "proj-001");
    expect(proj1).toBeDefined();
    expect(proj1!.name).toBe("Downtown Office Tower");
    expect(proj1!.health.color).toBeDefined();
    expect(proj1!.contractValue).toBe(450000);
    expect(proj1!.featureCoverage.total).toBe(6);
  });

  it("includes per-project open issues and safety counts", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);
    const proj3 = result.projects.find((p) => p.id === "proj-003");
    expect(proj3).toBeDefined();
    // proj-003 has 4 open RFIs + 0 pending COs open = 4 open issues
    expect(proj3!.openIssues).toBeGreaterThan(0);
    expect(proj3!.safetyIncidents).toBe(4);
  });
});
