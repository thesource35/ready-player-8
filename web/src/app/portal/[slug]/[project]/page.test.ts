import { describe, it, expect } from "vitest";
import { computeShowMapLink } from "./page";
import type { PortalConfig } from "@/lib/portal/types";

function makeConfig(
  sectionsConfig: Partial<PortalConfig["sections_config"]>
): PortalConfig {
  return {
    id: "c1",
    link_id: "l1",
    project_id: "p1",
    user_id: "u1",
    org_id: "o1",
    slug: "s",
    company_slug: "cs",
    template: "full_progress",
    sections_config: sectionsConfig as PortalConfig["sections_config"],
    show_exact_amounts: false,
    show_cameras: false,
    welcome_message: null,
    section_notes: {},
    pinned_items: {},
    date_ranges: {},
    watermark_enabled: false,
    powered_by_enabled: false,
    client_email: null,
    created_at: "",
    updated_at: "",
  };
}

describe("computeShowMapLink (D-08, D-09, D-11)", () => {
  it("returns false when sections_config has no map_overlays field (D-09 pre-Phase-21)", () => {
    expect(
      computeShowMapLink(
        makeConfig({
          schedule: { enabled: true },
          budget: { enabled: false },
          photos: { enabled: false },
          change_orders: { enabled: false },
          documents: { enabled: false },
        })
      )
    ).toBe(false);
  });

  it("returns true when map_overlays.show_map === true (D-08)", () => {
    expect(
      computeShowMapLink(
        makeConfig({
          schedule: { enabled: true },
          budget: { enabled: false },
          photos: { enabled: false },
          change_orders: { enabled: false },
          documents: { enabled: false },
          map_overlays: {
            show_map: true,
            satellite: true,
            traffic: false,
            equipment: false,
            photos: true,
          },
        })
      )
    ).toBe(true);
  });

  it("returns false when map_overlays.show_map === false (D-08)", () => {
    expect(
      computeShowMapLink(
        makeConfig({
          schedule: { enabled: true },
          budget: { enabled: false },
          photos: { enabled: false },
          change_orders: { enabled: false },
          documents: { enabled: false },
          map_overlays: {
            show_map: false,
            satellite: true,
            traffic: false,
            equipment: false,
            photos: true,
          },
        })
      )
    ).toBe(false);
  });

  it("returns false when map_overlays exists but show_map is undefined", () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const cfg = makeConfig({
      schedule: { enabled: true },
      budget: { enabled: false },
      photos: { enabled: false },
      change_orders: { enabled: false },
      documents: { enabled: false },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      map_overlays: {} as any,
    });
    expect(computeShowMapLink(cfg)).toBe(false);
  });

  it("returns false when sections_config is null (defensive)", () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    expect(computeShowMapLink({ sections_config: null } as any)).toBe(false);
  });
});
