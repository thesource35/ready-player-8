import { describe, it, expect } from "vitest";

// Test the rate limiter
import { checkRateLimit } from "@/lib/rate-limit";

describe("Rate Limiter", () => {
  it("allows requests under limit", () => {
    const ip = "test-" + Date.now();
    expect(checkRateLimit(ip, 5)).toBe(true);
    expect(checkRateLimit(ip, 5)).toBe(true);
    expect(checkRateLimit(ip, 5)).toBe(true);
  });

  it("blocks requests over limit", () => {
    const ip = "blocked-" + Date.now();
    for (let i = 0; i < 5; i++) checkRateLimit(ip, 5);
    expect(checkRateLimit(ip, 5)).toBe(false);
  });
});

// Test the SEO metadata
import { getPageMetadata, pageMetadata } from "@/lib/seo";

describe("SEO Metadata", () => {
  it("returns metadata for known pages", () => {
    const meta = getPageMetadata("projects");
    expect(meta.title).toContain("Projects");
    expect(meta.description).toBeTruthy();
  });

  it("returns fallback for unknown pages", () => {
    const meta = getPageMetadata("nonexistent-page-xyz");
    expect(meta.title).toContain("ConstructionOS");
  });

  it("has metadata for all major pages", () => {
    const requiredPages = [
      "projects", "contracts", "market", "maps", "feed", "jobs",
      "ops", "hub", "security", "pricing", "ai", "field",
      "finance", "compliance", "clients", "analytics", "schedule",
      "training", "scanner", "electrical", "tax", "punch",
      "roofing", "smart-build", "contractors", "tech", "wealth",
      "rentals", "empire", "settings", "tasks", "login",
    ];
    for (const page of requiredPages) {
      expect(pageMetadata[page]).toBeDefined();
      expect(pageMetadata[page].title).toBeTruthy();
    }
  });
});

// Test the nav structure
import { navGroups } from "@/lib/nav";

describe("Navigation", () => {
  it("has all nav groups", () => {
    expect(navGroups.length).toBeGreaterThanOrEqual(7);
  });

  it("all links have href and label", () => {
    for (const group of navGroups) {
      expect(group.label).toBeTruthy();
      for (const link of group.links) {
        expect(link.href).toMatch(/^\//);
        expect(link.label).toBeTruthy();
      }
    }
  });

  it("no duplicate hrefs", () => {
    const hrefs = navGroups.flatMap(g => g.links.map(l => l.href));
    const unique = new Set(hrefs);
    expect(unique.size).toBe(hrefs.length);
  });
});
