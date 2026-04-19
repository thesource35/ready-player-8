// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, within, cleanup } from "@testing-library/react";

const mockPathname = vi.fn();
vi.mock("next/navigation", () => ({
  usePathname: () => mockPathname(),
}));

import MobilePortalNav from "./MobilePortalNav";

const allFiveSections = [
  { key: "schedule" as const, label: "Schedule", enabled: true },
  { key: "budget" as const, label: "Budget", enabled: true },
  { key: "photos" as const, label: "Photos", enabled: true },
  { key: "change_orders" as const, label: "Change Orders", enabled: true },
  { key: "documents" as const, label: "Documents", enabled: true },
];

afterEach(() => {
  cleanup();
  mockPathname.mockReset();
});

describe("MobilePortalNav Map icon (Phase 27)", () => {
  it("D-08 gate: renders exactly 5 nav items when showMapLink=false", () => {
    mockPathname.mockReturnValue("/portal/acme/r");
    render(<MobilePortalNav sections={allFiveSections} showMapLink={false} />);
    const nav = screen.getByRole("navigation", { name: /portal section navigation/i });
    // 5 section buttons; no Map link
    const buttons = within(nav).getAllByRole("button");
    const links = within(nav).queryAllByRole("link");
    expect(buttons.length + links.length).toBe(5);
    expect(within(nav).queryByLabelText(/navigate to map/i)).toBeNull();
  });

  it("D-16,D-19,D-25: renders 6th MapPin entry when showMapLink=true", () => {
    mockPathname.mockReturnValue("/portal/acme/r");
    render(<MobilePortalNav sections={allFiveSections} showMapLink={true} />);
    const nav = screen.getByRole("navigation", { name: /portal section navigation/i });
    const mapLink = within(nav).getByLabelText(/navigate to map/i);
    expect(mapLink).toBeTruthy();
    // SVG exists inside the Map link
    expect(mapLink.querySelector("svg")).not.toBeNull();
  });

  it("D-16: Map entry is a Next.js Link (anchor), NOT a scroll button", () => {
    mockPathname.mockReturnValue("/portal/acme/r");
    render(<MobilePortalNav sections={allFiveSections} showMapLink={true} />);
    const mapLink = screen.getByLabelText(/navigate to map/i);
    expect(mapLink.tagName).toBe("A");
    expect(mapLink.getAttribute("href")).toMatch(/\.\/map$|\/portal\/acme\/r\/map$/);
  });

  it("D-17: Map entry shows active state when usePathname ends with /map", () => {
    mockPathname.mockReturnValue("/portal/acme/r/map");
    render(<MobilePortalNav sections={allFiveSections} showMapLink={true} />);
    const mapLink = screen.getByLabelText(/navigate to map/i);
    expect(mapLink.getAttribute("aria-current")).toBe("page");
    // Active color uses var(--portal-primary, #2563EB)
    const style = mapLink.getAttribute("style") ?? "";
    expect(style).toMatch(/var\(--portal-primary/);
  });

  it("D-17: Map entry shows inactive state on portal home", () => {
    mockPathname.mockReturnValue("/portal/acme/r");
    render(<MobilePortalNav sections={allFiveSections} showMapLink={true} />);
    const mapLink = screen.getByLabelText(/navigate to map/i);
    expect(mapLink.getAttribute("aria-current")).toBeNull();
    const style = mapLink.getAttribute("style") ?? "";
    expect(style).toMatch(/#9CA3AF/);
  });

  it("renders Map alone when sections all disabled + showMapLink=true", () => {
    mockPathname.mockReturnValue("/portal/acme/r");
    const noSections = allFiveSections.map((s) => ({ ...s, enabled: false }));
    render(<MobilePortalNav sections={noSections} showMapLink={true} />);
    // Component should render (not return null) and contain only the Map link
    expect(screen.getByLabelText(/navigate to map/i)).toBeTruthy();
  });
});
