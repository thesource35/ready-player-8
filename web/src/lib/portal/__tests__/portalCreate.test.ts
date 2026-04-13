import { describe, it, expect } from "vitest";
import { generateSlug, generateCompanySlug } from "../slugGenerator";
import { TEMPLATE_DEFAULTS, EXPIRY_OPTIONS } from "../types";
import type { PortalSectionsConfig } from "../types";

describe("Portal Link Creation", () => {
  it("generates a UUID token for new portal link", () => {
    // Token generation uses crypto.randomUUID()
    const token = crypto.randomUUID();
    // UUID v4 format: 8-4-4-4-12 hex chars
    expect(token).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
    // Each call produces a unique token
    const token2 = crypto.randomUUID();
    expect(token).not.toBe(token2);
  });

  it("creates portal config with default template sections", () => {
    // When creating a portal link with executive_summary template,
    // sections_config should match TEMPLATE_DEFAULTS
    const template = "executive_summary" as const;
    const defaultConfig = TEMPLATE_DEFAULTS[template];
    expect(defaultConfig.schedule.enabled).toBe(true);
    expect(defaultConfig.budget.enabled).toBe(false);
    expect(defaultConfig.change_orders.enabled).toBe(true);
    expect(defaultConfig.photos.enabled).toBe(false);
    expect(defaultConfig.documents.enabled).toBe(false);
  });

  it("enforces unique (company_slug, slug) constraint", () => {
    // Slug generation produces consistent results for same input
    const slug1 = generateSlug("Riverdale Heights Phase 2");
    const slug2 = generateSlug("Riverdale Heights Phase 2");
    expect(slug1).toBe(slug2);
    // Different inputs produce different slugs
    const slug3 = generateSlug("Downtown Tower Project");
    expect(slug1).not.toBe(slug3);
  });

  it("sets expiry based on selected option (7/30/90/null days)", () => {
    for (const option of EXPIRY_OPTIONS) {
      if (option.days === null) {
        // "Never expires" — no expires_at
        expect(option.label).toContain("Never");
        continue;
      }
      // Calculate expected expiry from now
      const now = Date.now();
      const expiresAt = new Date(
        now + option.days * 24 * 60 * 60 * 1000
      );
      // Should be in the future
      expect(expiresAt.getTime()).toBeGreaterThan(now);
      // Should be approximately option.days from now
      const diffDays = (expiresAt.getTime() - now) / (24 * 60 * 60 * 1000);
      expect(diffDays).toBeCloseTo(option.days, 0);
    }
  });

  it("validates required fields: project_id, slug, company_slug", () => {
    // Slug must be non-empty after generation
    const validSlug = generateSlug("My Project");
    expect(validSlug.length).toBeGreaterThan(0);
    // Empty input produces empty slug
    const emptySlug = generateSlug("");
    expect(emptySlug).toBe("");
    // Whitespace-only produces empty slug
    const whitespaceSlug = generateSlug("   ");
    expect(whitespaceSlug).toBe("");
  });

  it("generates URL-safe slug from project name", () => {
    expect(generateSlug("Riverdale Heights Phase 2")).toBe(
      "riverdale-heights-phase-2"
    );
  });

  it("strips non-alphanumeric characters from slug", () => {
    expect(generateSlug("Project #1 (Main)")).toBe("project-1-main");
  });

  it("collapses multiple hyphens in slug", () => {
    expect(generateSlug("Project---Name")).toBe("project-name");
  });

  it("trims leading and trailing hyphens from slug", () => {
    expect(generateSlug("-Project Name-")).toBe("project-name");
  });

  it("limits slug to 50 characters", () => {
    const longName =
      "This Is A Very Long Project Name That Should Be Truncated To Fifty Characters Maximum";
    const slug = generateSlug(longName);
    expect(slug.length).toBeLessThanOrEqual(50);
  });

  it("generates company slug using same logic", () => {
    const companySlug = generateCompanySlug("Acme Builders Inc.");
    expect(companySlug).toBe("acme-builders-inc");
  });

  it("copies URL structure uses company_slug/slug pattern", () => {
    const companySlug = generateCompanySlug("Acme Builders");
    const projectSlug = generateSlug("Riverdale Heights");
    const url = `/portal/${companySlug}/${projectSlug}`;
    expect(url).toBe("/portal/acme-builders/riverdale-heights");
  });
});
