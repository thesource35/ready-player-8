// @vitest-environment jsdom
// Phase 27 Plan 04 Task 1: behavioral tests for branded /map page.
// Covers: analytics sectionViewed="map", 5 CSS vars, PortalHeader props, notFound on expired.

import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";

// ---------------------------------------------------------------------------
// Hoisted mock state
// ---------------------------------------------------------------------------
const {
  mockConfig,
  mockLink,
  mockProject,
  mockAnalyticsCount,
  mockRecordPortalView,
  mockGetBranding,
  mockNotFound,
  portalHeaderSpy,
  portalMapClientSpy,
} = vi.hoisted(() => ({
  mockConfig: { value: null as unknown },
  mockLink: { value: null as unknown },
  mockProject: { value: null as unknown },
  mockAnalyticsCount: { value: 0 },
  mockRecordPortalView: vi.fn().mockResolvedValue(true),
  mockGetBranding: vi.fn(),
  mockNotFound: vi.fn(() => {
    throw new Error("NEXT_NOT_FOUND");
  }),
  portalHeaderSpy: vi.fn(),
  portalMapClientSpy: vi.fn(),
}));

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
vi.mock("@supabase/supabase-js", () => {
  const makeBuilder = (table: string) => {
    const builder: Record<string, unknown> = {};
    builder.select = vi.fn((_cols: string, opts?: { count?: string; head?: boolean }) => {
      if (opts?.count === "exact" && opts?.head) {
        // rate-limit path -- return count directly awaitable
        return {
          eq: vi.fn().mockReturnThis(),
          gte: vi.fn().mockResolvedValue({ count: mockAnalyticsCount.value }),
        };
      }
      return builder;
    });
    builder.eq = vi.fn(() => builder);
    builder.maybeSingle = vi.fn(async () => {
      if (table === "cs_portal_config") {
        return { data: mockConfig.value, error: null };
      }
      if (table === "cs_report_shared_links") {
        return { data: mockLink.value, error: null };
      }
      if (table === "cs_projects") {
        return { data: mockProject.value, error: null };
      }
      return { data: null, error: null };
    });
    return builder;
  };
  return {
    createClient: vi.fn(() => ({
      from: vi.fn((table: string) => makeBuilder(table)),
    })),
  };
});

vi.mock("@/lib/supabase/env", () => ({
  getSupabaseUrl: () => "https://test.supabase.co",
  getSupabaseServerKey: () => "test-service-key",
}));

vi.mock("next/navigation", () => ({
  notFound: mockNotFound,
}));

vi.mock("next/headers", () => ({
  headers: async () => ({
    get: (name: string) => {
      if (name === "x-forwarded-for") return "1.2.3.4";
      if (name === "user-agent") return "test-agent/1.0";
      return null;
    },
  }),
}));

vi.mock("@/lib/portal/brandingQueries", () => ({
  getBrandingForPortal: mockGetBranding,
}));

vi.mock("@/lib/portal/analyticsQueries", () => ({
  recordPortalView: mockRecordPortalView,
}));

vi.mock("@/app/components/portal/PortalHeader", () => ({
  default: (props: unknown) => {
    portalHeaderSpy(props);
    return <header data-testid="portal-header-mock" />;
  },
}));

vi.mock("./PortalMapClient", () => ({
  default: (props: unknown) => {
    portalMapClientSpy(props);
    return <div data-testid="portal-map-client-mock" />;
  },
}));

// ---------------------------------------------------------------------------
// Import AFTER mocks
// ---------------------------------------------------------------------------
import PortalMapPage from "./page";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const BASE_THEME = {
  primary: "#FF00FF",
  secondary: "#AA00AA",
  background: "#FAFAFA",
  text: "#111111",
  cardBg: "#F5F7F8",
  fontFamily: "Inter" as const,
  borderRadius: 12,
  customCSS: null,
};

function setHappyPath(opts: { showMap?: boolean; expired?: boolean; revoked?: boolean } = {}) {
  mockConfig.value = {
    id: "cfg-1",
    link_id: "link-1",
    project_id: "proj-1",
    org_id: "org-1",
    sections_config: {
      map_overlays: {
        show_map: opts.showMap ?? true,
        satellite: true,
        traffic: false,
        equipment: false,
        photos: true,
      },
    },
  };
  mockLink.value = {
    id: "link-1",
    token: "token-abc",
    expires_at: opts.expired
      ? new Date(Date.now() - 86_400_000).toISOString()
      : new Date(Date.now() + 86_400_000).toISOString(),
    is_revoked: opts.revoked ?? false,
  };
  mockProject.value = { name: "Riverdale Tower" };
  mockAnalyticsCount.value = 0;
  mockGetBranding.mockResolvedValue({
    branding: {
      company_name: "Acme Construction",
      logo_light_path: "https://cdn.test/logo.png",
    },
    theme: { ...BASE_THEME },
  });
}

async function renderPage() {
  const element = await PortalMapPage({
    params: Promise.resolve({ slug: "acme", project: "riverdale" }),
  });
  return renderToStaticMarkup(element as React.ReactElement);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
describe("PortalMapPage (Phase 27 Plan 04)", () => {
  beforeEach(() => {
    mockRecordPortalView.mockClear();
    mockGetBranding.mockClear();
    mockNotFound.mockClear();
    portalHeaderSpy.mockClear();
    portalMapClientSpy.mockClear();
  });

  afterEach(() => {
    vi.clearAllTimers();
  });

  it("D-27: recordPortalView is called with sectionViewed='map' on success", async () => {
    setHappyPath();
    await renderPage();
    expect(mockRecordPortalView).toHaveBeenCalledTimes(1);
    const args = mockRecordPortalView.mock.calls[0][0] as { sectionViewed: string };
    expect(args.sectionViewed).toBe("map");
  });

  it("D-20: all 5 CSS custom properties appear in rendered HTML root", async () => {
    setHappyPath();
    const html = await renderPage();
    expect(html).toContain("--portal-primary");
    expect(html).toContain("--portal-bg");
    expect(html).toContain("--portal-card-bg");
    expect(html).toContain("--portal-font-family");
    expect(html).toContain("--portal-radius");
  });

  it("D-14, D-26: PortalHeader receives showMapLink=true and sectionAnchors=[]", async () => {
    setHappyPath();
    await renderPage();
    expect(portalHeaderSpy).toHaveBeenCalledTimes(1);
    const props = portalHeaderSpy.mock.calls[0][0] as {
      showMapLink: boolean;
      sectionAnchors: unknown[];
    };
    expect(props.showMapLink).toBe(true);
    expect(props.sectionAnchors).toEqual([]);
  });

  it("D-22: notFound() is invoked when expires_at is in the past", async () => {
    setHappyPath({ expired: true });
    await expect(renderPage()).rejects.toThrow("NEXT_NOT_FOUND");
    expect(mockNotFound).toHaveBeenCalled();
  });
});
