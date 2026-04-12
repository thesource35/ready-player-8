import { describe, it, expect } from "vitest";
import { computePortfolioRollup } from "../aggregation";

// Load fixture
import samplePortfolio from "./fixtures/sample-portfolio.json";

describe("computePortfolioRollup", () => {
  it("computes totals correctly across all projects", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    // Project 1: contracts billed = 85000 + 140000 = 225000
    // Project 2: contracts billed = 400000 + 250000 = 650000
    // Project 3: contracts billed = 1100000
    expect(result.totals.totalBilled).toBe(225000 + 650000 + 1100000);

    // Contract values from parseBudgetString:
    // Project 1: $450,000 -> 450000
    // Project 2: $800,000 -> 800000
    // Project 3: $1,200,000 -> 1200000
    expect(result.totals.contractValue).toBe(450000 + 800000 + 1200000);

    // Change order net:
    // Project 1: 5000 + (-3000) = 2000
    // Project 2: 50000 + 10000 = 60000
    // Project 3: 200000
    expect(result.totals.changeOrderNet).toBe(2000 + 60000 + 200000);
  });

  it("computes per-project health scores independently", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    expect(result.projects).toHaveLength(3);

    // Each project should have its own health score
    for (const p of result.projects) {
      expect(p.health).toHaveProperty("score");
      expect(p.health).toHaveProperty("color");
      expect(p.health).toHaveProperty("label");
      expect(typeof p.health.score).toBe("number");
      expect(p.health.score).toBeGreaterThanOrEqual(0);
      expect(p.health.score).toBeLessThanOrEqual(100);
    }

    // Project 1 (Downtown Office Tower) should be healthiest (50% spent, 1 delayed of 2 critical)
    // Project 3 (Highway Bridge) should be worst (91.7% spent, 2 delayed of 3 critical, 4 open RFIs)
    expect(result.projects[0].health.score).toBeGreaterThan(
      result.projects[2].health.score
    );
  });

  it("computes portfolio-level aggregate health score (D-41)", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    expect(result.health).toBeDefined();
    expect(result.health).toHaveProperty("score");
    expect(result.health).toHaveProperty("color");
    expect(result.health).toHaveProperty("label");
    expect(["green", "gold", "red"]).toContain(result.health.color);
  });

  it("computes feature coverage counts correctly (D-16c)", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    // Project 1 has 6/6 tables with data (all active)
    const proj1 = result.projects[0];
    expect(proj1.featureCoverage.total).toBe(6);
    expect(proj1.featureCoverage.active).toBe(6);

    // Project 2 has 3/6 (cs_projects, cs_contracts, cs_project_tasks have data; rest 0)
    const proj2 = result.projects[1];
    expect(proj2.featureCoverage.total).toBe(6);
    expect(proj2.featureCoverage.active).toBe(3);

    // Project 3 has 6/6 (all tables have data: cs_projects=1, cs_contracts=1, cs_project_tasks=3, cs_team_assignments=4, cs_field_reports=8, cs_documents=20)
    const proj3 = result.projects[2];
    expect(proj3.featureCoverage.total).toBe(6);
    expect(proj3.featureCoverage.active).toBe(6);
  });

  it("returns zero totals for empty projects array", () => {
    const result = computePortfolioRollup([]);

    expect(result.projects).toHaveLength(0);
    expect(result.totals.contractValue).toBe(0);
    expect(result.totals.totalBilled).toBe(0);
    expect(result.totals.changeOrderNet).toBe(0);
    expect(result.health.score).toBe(100);
    expect(result.health.color).toBe("green");
    expect(result.monthlySpend).toHaveLength(0);
  });

  it("includes generated_at timestamp", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);
    expect(result.generated_at).toBeTruthy();
    // Should be a valid ISO string
    expect(new Date(result.generated_at).toISOString()).toBe(
      result.generated_at
    );
  });

  it("computes schedule health per project", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    // Project 1: 1 critical task incomplete (Framing at 80%) -> "Delayed"
    expect(result.projects[0].scheduleHealth).toBe("Delayed");

    // Project 2: 2 critical tasks incomplete (Foundation 50%, Framing 10%) -> "Delayed"
    expect(result.projects[1].scheduleHealth).toBe("Delayed");

    // Project 3: 2 critical tasks incomplete (Structural 20%, Resurfacing 0%) -> "Delayed"
    expect(result.projects[2].scheduleHealth).toBe("Delayed");
  });

  it("counts safety incidents per project", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    expect(result.projects[0].safetyIncidents).toBe(1);
    expect(result.projects[1].safetyIncidents).toBe(3);
    expect(result.projects[2].safetyIncidents).toBe(4);
  });

  it("counts open issues per project", () => {
    const result = computePortfolioRollup(samplePortfolio.projects);

    // Project 1: 0 open RFIs (1 closed) + 0 pending COs (1 approved) = 0
    expect(result.projects[0].openIssues).toBe(0);

    // Project 2: 2 open RFIs + 1 pending CO = 3
    expect(result.projects[1].openIssues).toBe(3);

    // Project 3: 4 open RFIs + 0 pending COs = 4
    expect(result.projects[2].openIssues).toBe(4);
  });
});
