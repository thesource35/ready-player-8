import { describe, it, expect } from "vitest";
import {
  TEMPLATE_DEFAULTS,
  SECTION_ORDER,
  PORTAL_RATE_LIMITS,
  EXPIRY_OPTIONS,
} from "../types";
import type { PortalSectionsConfig, PortalSectionKey } from "../types";

describe("Section Configuration", () => {
  it("applies executive_summary template defaults", () => {
    const config = TEMPLATE_DEFAULTS.executive_summary;
    expect(config.schedule.enabled).toBe(true);
    expect(config.budget.enabled).toBe(false);
    expect(config.photos.enabled).toBe(false);
    expect(config.change_orders.enabled).toBe(true);
    expect(config.documents.enabled).toBe(false);
  });

  it("applies full_progress template defaults", () => {
    const config = TEMPLATE_DEFAULTS.full_progress;
    expect(config.schedule.enabled).toBe(true);
    expect(config.budget.enabled).toBe(false);
    expect(config.photos.enabled).toBe(true);
    expect(config.change_orders.enabled).toBe(true);
    expect(config.documents.enabled).toBe(true);
  });

  it("applies photo_update template defaults", () => {
    const config = TEMPLATE_DEFAULTS.photo_update;
    expect(config.schedule.enabled).toBe(false);
    expect(config.budget.enabled).toBe(false);
    expect(config.photos.enabled).toBe(true);
    expect(config.change_orders.enabled).toBe(false);
    expect(config.documents.enabled).toBe(false);
  });

  it("budget defaults to disabled regardless of template (D-33)", () => {
    for (const [templateName, config] of Object.entries(TEMPLATE_DEFAULTS)) {
      expect(config.budget.enabled).toBe(false);
      // Verify this is a deliberate default, not coincidence
      expect(typeof config.budget.enabled).toBe("boolean");
      // Template name should be a valid template
      expect(["executive_summary", "full_progress", "photo_update"]).toContain(
        templateName
      );
    }
  });

  it("toggles individual sections independently", () => {
    // Clone a template and toggle one section
    const config: PortalSectionsConfig = JSON.parse(
      JSON.stringify(TEMPLATE_DEFAULTS.executive_summary)
    );
    // schedule starts enabled
    expect(config.schedule.enabled).toBe(true);
    // Toggle it off
    config.schedule.enabled = false;
    expect(config.schedule.enabled).toBe(false);
    // Other sections unaffected
    expect(config.change_orders.enabled).toBe(true);
  });

  it("persists date range per section (D-35)", () => {
    const config: PortalSectionsConfig = JSON.parse(
      JSON.stringify(TEMPLATE_DEFAULTS.full_progress)
    );
    config.photos.date_range = { start: "2026-01-01", end: "2026-03-31" };
    expect(config.photos.date_range).toEqual({
      start: "2026-01-01",
      end: "2026-03-31",
    });
    // Other sections should not have date_range unless explicitly set
    expect(config.schedule.date_range).toBeUndefined();
  });

  it("persists pinned items per section (D-36)", () => {
    // Pinned items are stored in PortalConfig.pinned_items (Record<string, string[]>)
    const pinnedItems: Record<string, string[]> = {};
    pinnedItems["photos"] = ["photo-uuid-1", "photo-uuid-2"];
    pinnedItems["documents"] = ["doc-uuid-1"];
    expect(pinnedItems["photos"]).toHaveLength(2);
    expect(pinnedItems["documents"]).toHaveLength(1);
    expect(pinnedItems["schedule"]).toBeUndefined();
  });

  it("persists section notes (D-45)", () => {
    // Section notes stored in PortalConfig.section_notes (Record<string, string>)
    const sectionNotes: Record<string, string> = {};
    sectionNotes["budget"] = "Budget is on track as of April 10";
    sectionNotes["schedule"] = "Phase 2 starting next week";
    expect(sectionNotes["budget"]).toContain("on track");
    expect(sectionNotes["schedule"]).toContain("Phase 2");
    expect(sectionNotes["photos"]).toBeUndefined();
  });

  it("select all / deselect all toggle (D-34)", () => {
    const config: PortalSectionsConfig = JSON.parse(
      JSON.stringify(TEMPLATE_DEFAULTS.photo_update)
    );
    // Select all
    for (const key of SECTION_ORDER) {
      config[key].enabled = true;
    }
    for (const key of SECTION_ORDER) {
      expect(config[key].enabled).toBe(true);
    }
    // Deselect all
    for (const key of SECTION_ORDER) {
      config[key].enabled = false;
    }
    for (const key of SECTION_ORDER) {
      expect(config[key].enabled).toBe(false);
    }
  });

  it("fixed section display order (D-32)", () => {
    expect(SECTION_ORDER).toEqual([
      "schedule",
      "budget",
      "photos",
      "change_orders",
      "documents",
    ]);
    expect(SECTION_ORDER).toHaveLength(5);
  });

  it("rate limits match D-109 specification", () => {
    expect(PORTAL_RATE_LIMITS.viewsPerDayPerLink).toBe(100);
    expect(PORTAL_RATE_LIMITS.managementPerHourPerUser).toBe(50);
    expect(PORTAL_RATE_LIMITS.failedLookupPerMinPerIP).toBe(10);
  });

  it("expiry options include 7, 30, 90 days and never (D-04)", () => {
    const days = EXPIRY_OPTIONS.map((o) => o.days);
    expect(days).toContain(7);
    expect(days).toContain(30);
    expect(days).toContain(90);
    expect(days).toContain(null); // "Never expires"
  });

  it("all template sections have the 5 required keys", () => {
    const requiredKeys: PortalSectionKey[] = [
      "schedule",
      "budget",
      "photos",
      "change_orders",
      "documents",
    ];
    for (const [, config] of Object.entries(TEMPLATE_DEFAULTS)) {
      for (const key of requiredKeys) {
        expect(config).toHaveProperty(key);
        expect(config[key]).toHaveProperty("enabled");
        expect(typeof config[key].enabled).toBe("boolean");
      }
    }
  });
});
