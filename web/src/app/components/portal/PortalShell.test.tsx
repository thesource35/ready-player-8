// @vitest-environment jsdom
import { describe, it, expect, vi } from "vitest";
import { render } from "@testing-library/react";

// Capture MobilePortalNav props for assertions (Phase 27 Plan 06 wiring test)
const mobilePortalNavSpy = vi.fn();
vi.mock("./MobilePortalNav", () => ({
  default: (props: unknown) => {
    mobilePortalNavSpy(props);
    return <nav aria-label="Portal section navigation" data-testid="mobile-nav-mock" />;
  },
}));

// Stub the heavy section components -- not under test here
vi.mock("./PortalHeader", () => ({ default: () => <header data-testid="header-mock" /> }));
vi.mock("./PortalFooter", () => ({ default: () => <footer data-testid="footer-mock" /> }));
vi.mock("./HealthBadge", () => ({ default: () => <div data-testid="health-mock" /> }));
vi.mock("./BudgetSection", () => ({ default: () => <div data-testid="budget-mock" /> }));
vi.mock("./ScheduleSection", () => ({ default: () => <div data-testid="schedule-mock" /> }));
vi.mock("./ChangeOrdersSection", () => ({ default: () => <div data-testid="co-mock" /> }));
vi.mock("./DocumentsSection", () => ({ default: () => <div data-testid="docs-mock" /> }));
vi.mock("./CookieConsent", () => ({ default: () => <div data-testid="cookie-mock" /> }));

import PortalShell from "./PortalShell";
import type { PortalConfig, PortalThemeConfig } from "@/lib/portal/types";

const baseTheme: PortalThemeConfig = {
  primary: "#2563EB",
  secondary: "#1E3A5F",
  background: "#FFFFFF",
  text: "#1F2937",
  cardBg: "#F5F7F8",
  fontFamily: "Inter",
  borderRadius: 8,
  customCSS: null,
};

function makeProps(
  overrides: Partial<{
    showMapLink: boolean;
    sectionsConfig: PortalConfig["sections_config"];
  }> = {},
) {
  const sectionsConfig = overrides.sectionsConfig ?? ({
    schedule: { enabled: true },
    budget: { enabled: true },
    photos: { enabled: true },
    change_orders: { enabled: true },
    documents: { enabled: true },
  } as PortalConfig["sections_config"]);

  const portalConfig = {
    id: "c1",
    link_id: "l1",
    project_id: "p1",
    org_id: "o1",
    slug: "s",
    company_slug: "cs",
    template: "full_progress",
    sections_config: sectionsConfig,
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
  } as unknown as PortalConfig;

  return {
    branding: null,
    theme: baseTheme,
    portalConfig,
    sections: { schedule: { milestones: [] }, budget: { contractValue: 0 } },
    healthScore: { score: 80, breakdown: {} } as never,
    projectName: "Riverdale",
    sectionOrder: [
      "schedule",
      "budget",
      "photos",
      "change_orders",
      "documents",
    ] as never,
    showAmounts: false,
    showMapLink: overrides.showMapLink ?? true,
  };
}

describe("PortalShell wires MobilePortalNav (Phase 27 Plan 06)", () => {
  it("renders MobilePortalNav inside the shell", () => {
    mobilePortalNavSpy.mockClear();
    const { getByTestId } = render(<PortalShell {...makeProps()} />);
    expect(getByTestId("mobile-nav-mock")).toBeTruthy();
    expect(mobilePortalNavSpy).toHaveBeenCalled();
  });

  it("D-19: forwards showMapLink=true to MobilePortalNav", () => {
    mobilePortalNavSpy.mockClear();
    render(<PortalShell {...makeProps({ showMapLink: true })} />);
    const propsArg = mobilePortalNavSpy.mock.calls[0][0] as { showMapLink: boolean };
    expect(propsArg.showMapLink).toBe(true);
  });

  it("D-19: forwards showMapLink=false to MobilePortalNav", () => {
    mobilePortalNavSpy.mockClear();
    render(<PortalShell {...makeProps({ showMapLink: false })} />);
    const propsArg = mobilePortalNavSpy.mock.calls[0][0] as { showMapLink: boolean };
    expect(propsArg.showMapLink).toBe(false);
  });

  it("forwards sections array with enabled flags from sections_config", () => {
    mobilePortalNavSpy.mockClear();
    render(
      <PortalShell
        {...makeProps({
          sectionsConfig: {
            schedule: { enabled: true },
            budget: { enabled: false },
            photos: { enabled: true },
            change_orders: { enabled: false },
            documents: { enabled: true },
          } as PortalConfig["sections_config"],
        })}
      />,
    );
    const propsArg = mobilePortalNavSpy.mock.calls[0][0] as {
      sections: { key: string; label: string; enabled: boolean }[];
    };
    expect(propsArg.sections).toHaveLength(5);
    const byKey = Object.fromEntries(
      propsArg.sections.map((s) => [s.key, s.enabled]),
    );
    expect(byKey.schedule).toBe(true);
    expect(byKey.budget).toBe(false);
    expect(byKey.photos).toBe(true);
    expect(byKey.change_orders).toBe(false);
    expect(byKey.documents).toBe(true);
  });
});
