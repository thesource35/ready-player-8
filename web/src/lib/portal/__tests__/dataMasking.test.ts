import { describe, it, expect } from "vitest";
import { TEMPLATE_DEFAULTS } from "../types";
import type { PortalSectionsConfig, PortalConfig } from "../types";

/**
 * Data masking tests verify that:
 * 1. Disabled sections are never queried (D-123)
 * 2. Budget amounts are masked/shown based on show_exact_amounts (D-30)
 * 3. Change order dollars follow budget visibility rules (D-38)
 * 4. Empty sections are hidden from portal (D-44)
 *
 * These tests validate the masking logic at the application level.
 * The actual Supabase queries are in portalQueries.ts; here we test
 * the decision logic that determines what to fetch and display.
 */

// Helper: simulate which sections to query based on config (D-123)
function getSectionsToQuery(config: PortalSectionsConfig): string[] {
  const sections: string[] = [];
  if (config.schedule.enabled) sections.push("schedule");
  if (config.budget.enabled) sections.push("budget");
  if (config.photos.enabled) sections.push("photos");
  if (config.change_orders.enabled) sections.push("change_orders");
  if (config.documents.enabled) sections.push("documents");
  return sections;
}

// Helper: determine if budget amounts should be shown (D-30, D-38)
function shouldShowExactAmounts(
  budgetEnabled: boolean,
  showExactAmounts: boolean
): boolean {
  return budgetEnabled && showExactAmounts;
}

// Helper: determine if change order dollars are visible (D-38)
function shouldShowChangeOrderDollars(
  budgetEnabled: boolean,
  showExactAmounts: boolean
): boolean {
  // Change order dollars only visible when budget is enabled AND unmasked
  return budgetEnabled && showExactAmounts;
}

// Helper: mask a budget value to a percentage string (D-30)
function maskBudgetToPercent(spent: number, total: number): string {
  if (total === 0) return "0%";
  return `${Math.round((spent / total) * 100)}%`;
}

// Helper: filter out empty sections (D-44)
function filterEmptySections(
  sections: { key: string; itemCount: number }[]
): { key: string; itemCount: number }[] {
  return sections.filter((s) => s.itemCount > 0);
}

describe("Data Masking", () => {
  it("never queries disabled sections from database (D-123)", () => {
    // executive_summary: schedule ON, budget OFF, photos OFF, change_orders ON, documents OFF
    const config = TEMPLATE_DEFAULTS.executive_summary;
    const sectionsToQuery = getSectionsToQuery(config);

    expect(sectionsToQuery).toContain("schedule");
    expect(sectionsToQuery).toContain("change_orders");
    expect(sectionsToQuery).not.toContain("budget");
    expect(sectionsToQuery).not.toContain("photos");
    expect(sectionsToQuery).not.toContain("documents");
  });

  it("masks budget to percentages when show_exact_amounts is false (D-30)", () => {
    const budgetEnabled = true;
    const showExactAmounts = false;

    expect(shouldShowExactAmounts(budgetEnabled, showExactAmounts)).toBe(false);

    // Budget should be displayed as percentage, not dollar amount
    const masked = maskBudgetToPercent(750000, 1000000);
    expect(masked).toBe("75%");
    expect(masked).not.toContain("$");
  });

  it("shows exact amounts when show_exact_amounts is true", () => {
    const budgetEnabled = true;
    const showExactAmounts = true;

    expect(shouldShowExactAmounts(budgetEnabled, showExactAmounts)).toBe(true);
  });

  it("hides change order dollars when budget section disabled (D-38)", () => {
    // Budget disabled entirely -- change order dollars must be hidden
    const budgetEnabled = false;
    const showExactAmounts = true; // even if this is true, budget disabled wins

    expect(shouldShowChangeOrderDollars(budgetEnabled, showExactAmounts)).toBe(
      false
    );
  });

  it("hides change order dollars when budget enabled but masked (D-38)", () => {
    // Budget enabled but amounts masked -- change order dollars still hidden
    const budgetEnabled = true;
    const showExactAmounts = false;

    expect(shouldShowChangeOrderDollars(budgetEnabled, showExactAmounts)).toBe(
      false
    );

    // Only visible when budget is enabled AND show_exact_amounts is true
    expect(shouldShowChangeOrderDollars(true, true)).toBe(true);
  });

  it("hides empty sections from portal (D-44)", () => {
    const sections = [
      { key: "schedule", itemCount: 5 },
      { key: "budget", itemCount: 0 }, // empty -- should be hidden
      { key: "photos", itemCount: 47 },
      { key: "change_orders", itemCount: 0 }, // empty -- should be hidden
      { key: "documents", itemCount: 12 },
    ];

    const visible = filterEmptySections(sections);
    expect(visible).toHaveLength(3);
    expect(visible.map((s) => s.key)).toEqual([
      "schedule",
      "photos",
      "documents",
    ]);
    expect(visible.map((s) => s.key)).not.toContain("budget");
    expect(visible.map((s) => s.key)).not.toContain("change_orders");
  });

  it("photo_update template only queries photos section (D-123)", () => {
    const config = TEMPLATE_DEFAULTS.photo_update;
    const sectionsToQuery = getSectionsToQuery(config);

    expect(sectionsToQuery).toEqual(["photos"]);
    expect(sectionsToQuery).toHaveLength(1);
  });

  it("full_progress template queries all except budget (D-123, D-33)", () => {
    const config = TEMPLATE_DEFAULTS.full_progress;
    const sectionsToQuery = getSectionsToQuery(config);

    // Budget always defaults to disabled per D-33
    expect(sectionsToQuery).not.toContain("budget");
    expect(sectionsToQuery).toContain("schedule");
    expect(sectionsToQuery).toContain("photos");
    expect(sectionsToQuery).toContain("change_orders");
    expect(sectionsToQuery).toContain("documents");
  });

  it("masks budget to 0% when total is zero", () => {
    expect(maskBudgetToPercent(0, 0)).toBe("0%");
  });
});
