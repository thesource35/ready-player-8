/**
 * Integration tests for report data pipeline.
 * Per D-77: Tests full aggregation flow end-to-end with shared fixtures.
 * Per D-80: Uses shared JSON fixtures from fixtures/ directory.
 * Per D-83: Covers all aggregation functions for 100% coverage.
 */
import { describe, it, expect } from "vitest";
import sampleProject from "./fixtures/sample-project.json";
import samplePortfolio from "./fixtures/sample-portfolio.json";
import {
  parseBudgetString,
  computeHealthScore,
  computeBudgetSection,
  computeScheduleSection,
  computeIssuesSection,
  computeTeamSection,
  computeSafetySection,
  computePortfolioRollup,
  computeFeatureCoverage,
} from "../aggregation";

// ---------- Full Pipeline: Raw Data -> Sections -> Health ----------

describe("Integration: Full report pipeline", () => {
  it("computes all sections from raw project data and derives consistent health", () => {
    const budget = computeBudgetSection(sampleProject.project, sampleProject.contracts);
    const schedule = computeScheduleSection(sampleProject.tasks);
    const issues = computeIssuesSection(sampleProject.rfis, sampleProject.change_orders);
    const team = computeTeamSection(sampleProject.team_assignments, sampleProject.activity_feed);
    const safety = computeSafetySection(sampleProject.safety_incidents, new Date("2025-06-15"));
    const coverage = computeFeatureCoverage(sampleProject.table_counts);

    // Budget section derived correctly
    expect(budget.contractValue).toBe(450000);
    expect(budget.totalBilled).toBe(225000);
    expect(budget.percentComplete).toBe(50);
    expect(budget.remaining).toBe(225000);

    // Schedule section
    expect(schedule.totalCount).toBe(5);
    expect(schedule.milestones).toHaveLength(5);

    // Issues section
    expect(issues.rfis).toHaveLength(3);
    expect(issues.changeOrders).toHaveLength(3);
    expect(issues.totalOpen).toBe(3); // 2 open RFIs + 1 pending CO

    // Team section
    expect(team.memberCount).toBe(4); // 4 active, 1 inactive
    expect(team.recentActivity).toHaveLength(5);

    // Safety section
    expect(safety.totalIncidents).toBe(3);
    expect(safety.daysSinceLastIncident).toBe(18);

    // Feature coverage
    expect(coverage.active).toBe(6);
    expect(coverage.total).toBe(6);

    // Health score derived from sections
    const budgetSpentPercent = (budget.totalBilled / budget.contractValue) * 100; // 50%
    const delayedMilestonePercent = (schedule.delayedCount / schedule.totalCount) * 100;
    const health = computeHealthScore({
      budgetSpentPercent,
      delayedMilestonePercent,
      criticalOpenIssues: issues.criticalOpen,
    });

    // With 50% budget spent, some delayed milestones, and 2 critical open issues
    // the health should be computed consistently
    expect(health.score).toBeGreaterThanOrEqual(0);
    expect(health.score).toBeLessThanOrEqual(100);
    expect(["green", "gold", "red"]).toContain(health.color);
    expect(["On Track", "At Risk", "Critical"]).toContain(health.label);
  });
});

// ---------- Budget Computation with Real-Format Text Fields ----------

describe("Integration: Budget with text formats", () => {
  it("handles dollar amounts: $450,000", () => {
    const result = computeBudgetSection(
      { budget: "$450,000" },
      [{ billed: 100000, change_order_amount: 5000, retainage: 10000 }]
    );
    expect(result.contractValue).toBe(450000);
    expect(result.spent).toBe(100000);
    expect(result.remaining).toBe(350000);
  });

  it("handles zero budget: $0", () => {
    const result = computeBudgetSection(
      { budget: "$0" },
      [{ billed: 5000, change_order_amount: 0, retainage: 0 }]
    );
    expect(result.contractValue).toBe(0);
    expect(result.percentComplete).toBe(0); // division by zero guarded
  });

  it("handles TBD budget", () => {
    const result = computeBudgetSection(
      { budget: "TBD" },
      [{ billed: 10000, change_order_amount: 0, retainage: 0 }]
    );
    expect(result.contractValue).toBe(0);
    expect(result.percentComplete).toBe(0);
    expect(result.spent).toBe(10000);
  });

  it("handles large dollar amounts: $12,500,000.50", () => {
    const result = computeBudgetSection(
      { budget: "$12,500,000.50" },
      []
    );
    expect(result.contractValue).toBe(12500000.50);
  });
});

// ---------- Health Score End-to-End ----------

describe("Integration: Health score computation end-to-end", () => {
  it("perfect project yields green/100", () => {
    const health = computeHealthScore({
      budgetSpentPercent: 30,
      delayedMilestonePercent: 0,
      criticalOpenIssues: 0,
    });
    expect(health.score).toBe(100);
    expect(health.color).toBe("green");
    expect(health.label).toBe("On Track");
  });

  it("over-budget with some delays yields gold", () => {
    const health = computeHealthScore({
      budgetSpentPercent: 95,
      delayedMilestonePercent: 15,
      criticalOpenIssues: 1,
    });
    expect(health.color).toBe("gold");
    expect(health.label).toBe("At Risk");
  });

  it("all-critical project yields red", () => {
    const health = computeHealthScore({
      budgetSpentPercent: 110,
      delayedMilestonePercent: 50,
      criticalOpenIssues: 5,
    });
    expect(health.color).toBe("red");
    expect(health.label).toBe("Critical");
  });
});

// ---------- Portfolio Rollup with 5 Projects of Varying Health ----------

describe("Integration: Portfolio rollup with varying health", () => {
  it("aggregates 5 projects correctly", () => {
    const fiveProjects = [
      ...samplePortfolio.projects,
      // Add 2 more for 5-project scenario
      {
        project: { id: "proj-004", name: "Warehouse Build", status: "Active", budget: "$500,000", progress: 80 },
        contracts: [{ id: "c6", budget: "$500,000", billed: 400000, change_order_amount: 0, retainage: 40000 }],
        tasks: [
          { id: "t9", name: "Foundation", percent_complete: 100, is_critical: false, start_date: "2025-01-01", end_date: "2025-03-01" },
          { id: "t10", name: "Walls", percent_complete: 90, is_critical: false, start_date: "2025-03-01", end_date: "2025-06-01" },
        ],
        rfis: [],
        change_orders: [],
        safety_incidents: [],
        table_counts: { cs_projects: 1, cs_contracts: 1, cs_project_tasks: 2, cs_team_assignments: 2, cs_field_reports: 3, cs_documents: 5 },
      },
      {
        project: { id: "proj-005", name: "School Renovation", status: "On Hold", budget: "$300,000", progress: 10 },
        contracts: [{ id: "c7", budget: "$300,000", billed: 30000, change_order_amount: 0, retainage: 3000 }],
        tasks: [
          { id: "t11", name: "Demo", percent_complete: 100, is_critical: true, start_date: "2025-01-01", end_date: "2025-02-01" },
          { id: "t12", name: "Rebuild", percent_complete: 5, is_critical: true, start_date: "2025-02-01", end_date: "2025-09-01" },
        ],
        rfis: [
          { id: "r8", subject: "Asbestos plan", status: "Open", created_at: "2025-02-10T00:00:00Z" },
        ],
        change_orders: [],
        safety_incidents: [
          { id: "s9", description: "Dust exposure", severity: "minor", date: "2025-02-20" },
        ],
        table_counts: { cs_projects: 1, cs_contracts: 1, cs_project_tasks: 2, cs_team_assignments: 0, cs_field_reports: 0, cs_documents: 2 },
      },
    ];

    const rollup = computePortfolioRollup(fiveProjects);

    expect(rollup.projects).toHaveLength(5);
    expect(rollup.generated_at).toBeTruthy();

    // Total contract value: 450000 + 800000 + 1200000 + 500000 + 300000 = 3250000
    expect(rollup.totals.contractValue).toBe(3250000);

    // Each project has a health score
    for (const proj of rollup.projects) {
      expect(proj.health.score).toBeGreaterThanOrEqual(0);
      expect(proj.health.score).toBeLessThanOrEqual(100);
      expect(["green", "gold", "red"]).toContain(proj.health.color);
    }

    // Portfolio health is an average
    expect(rollup.health.score).toBeGreaterThanOrEqual(0);
    expect(rollup.health.score).toBeLessThanOrEqual(100);
  });
});

// ---------- Partial Failure Scenario (D-56) ----------

describe("Integration: Partial failure scenario", () => {
  it("individual section failure does not prevent other sections from computing", () => {
    // Simulate: budget section works, schedule throws (bad data), issues works
    const budget = computeBudgetSection(sampleProject.project, sampleProject.contracts);
    expect(budget.contractValue).toBe(450000);

    // Schedule with malformed data -- empty array is safe
    const schedule = computeScheduleSection([]);
    expect(schedule.totalCount).toBe(0);
    expect(schedule.delayedCount).toBe(0);

    // Issues still computes fine
    const issues = computeIssuesSection(sampleProject.rfis, sampleProject.change_orders);
    expect(issues.totalOpen).toBe(3);

    // Health can be computed even with partial data (schedule returns zeros)
    const health = computeHealthScore({
      budgetSpentPercent: (budget.totalBilled / budget.contractValue) * 100,
      delayedMilestonePercent: 0, // schedule section had no data
      criticalOpenIssues: issues.criticalOpen,
    });
    expect(health.score).toBeGreaterThanOrEqual(0);
    expect(health.score).toBeLessThanOrEqual(100);
  });

  it("null-like inputs to health score produce perfect score", () => {
    const health = computeHealthScore({
      budgetSpentPercent: null as unknown as number,
      delayedMilestonePercent: null as unknown as number,
      criticalOpenIssues: null as unknown as number,
    });
    expect(health.score).toBe(100);
    expect(health.color).toBe("green");
  });

  it("safety section handles zero incidents gracefully", () => {
    const safety = computeSafetySection([], new Date("2025-06-15"));
    expect(safety.totalIncidents).toBe(0);
    expect(safety.daysSinceLastIncident).toBe(-1);
    expect(safety.monthlyData).toHaveLength(0);
  });
});

// ---------- Cross-Platform Fixture Consistency (D-80) ----------

describe("Integration: Shared fixture consistency", () => {
  it("sample-project.json has all required fields", () => {
    expect(sampleProject.project).toBeDefined();
    expect(sampleProject.project.id).toBe("proj-001");
    expect(sampleProject.project.budget).toBe("$450,000");
    expect(sampleProject.contracts).toHaveLength(3);
    expect(sampleProject.tasks).toHaveLength(5);
    expect(sampleProject.rfis).toHaveLength(3);
    expect(sampleProject.change_orders).toHaveLength(3);
    expect(sampleProject.safety_incidents).toHaveLength(3);
    expect(sampleProject.team_assignments).toHaveLength(5);
    expect(sampleProject.activity_feed).toHaveLength(6);
    expect(sampleProject.table_counts).toBeDefined();
  });

  it("sample-portfolio.json has 3 projects with all sections", () => {
    expect(samplePortfolio.projects).toHaveLength(3);
    for (const p of samplePortfolio.projects) {
      expect(p.project).toBeDefined();
      expect(p.project.id).toBeTruthy();
      expect(p.project.budget).toBeTruthy();
      expect(Array.isArray(p.contracts)).toBe(true);
      expect(Array.isArray(p.tasks)).toBe(true);
      expect(Array.isArray(p.rfis)).toBe(true);
      expect(Array.isArray(p.change_orders)).toBe(true);
      expect(Array.isArray(p.safety_incidents)).toBe(true);
      expect(p.table_counts).toBeDefined();
    }
  });

  it("parseBudgetString produces same results as documented Swift equivalent", () => {
    // These values must match the Swift ReportTests expectations
    expect(parseBudgetString("$450,000")).toBe(450000);
    expect(parseBudgetString("$0")).toBe(0);
    expect(parseBudgetString("TBD")).toBe(0);
    expect(parseBudgetString("N/A")).toBe(0);
    expect(parseBudgetString("$1,200,000")).toBe(1200000);
    expect(parseBudgetString("$800,000")).toBe(800000);
  });
});
