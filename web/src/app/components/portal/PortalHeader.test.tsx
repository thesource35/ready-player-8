// @vitest-environment jsdom
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, within, cleanup } from "@testing-library/react";

const mockPathname = vi.fn();
vi.mock("next/navigation", () => ({
  usePathname: () => mockPathname(),
}));

import PortalHeader from "./PortalHeader";

const baseProps = {
  companyName: "Acme",
  projectName: "Riverdale",
  sectionAnchors: [
    { id: "schedule", label: "Schedule" },
    { id: "documents", label: "Documents" },
  ],
  lastUpdated: "Apr 18, 2026",
};

afterEach(() => {
  cleanup();
  mockPathname.mockReset();
});

describe("PortalHeader Map/Overview anchors (Phase 27)", () => {
  it("D-01,D-03,D-23: renders Map anchor as last nav child when showMapLink=true on home", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale");
    render(<PortalHeader {...baseProps} showMapLink={true} />);
    const nav = screen.getByRole("navigation", { name: /portal section navigation/i });
    const links = within(nav).getAllByRole("link");
    expect(links[links.length - 1].textContent).toBe("Map");
  });

  it("D-04: Map anchor uses href='./map' (Next.js Link relative)", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale");
    render(<PortalHeader {...baseProps} showMapLink={true} />);
    const mapLink = screen.getByRole("link", { name: "Map" });
    expect(mapLink.getAttribute("href")).toMatch(/\.\/map$|\/portal\/acme\/riverdale\/map$/);
  });

  it("D-05,D-26: renders Overview anchor as first nav child when showMapLink=true on /map", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale/map");
    render(<PortalHeader {...baseProps} showMapLink={true} />);
    const nav = screen.getByRole("navigation", { name: /portal section navigation/i });
    const links = within(nav).getAllByRole("link");
    expect(links[0].textContent).toBe("Overview");
    expect(links[0].getAttribute("href")).toMatch(/\.\.$|\/portal\/acme\/riverdale$/);
  });

  it("D-08 gate: hides Map and Overview anchors when showMapLink=false on home", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale");
    render(<PortalHeader {...baseProps} showMapLink={false} />);
    expect(screen.queryByRole("link", { name: "Map" })).toBeNull();
    expect(screen.queryByRole("link", { name: "Overview" })).toBeNull();
  });

  it("D-08 gate: hides Map and Overview anchors when showMapLink=false on /map", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale/map");
    render(<PortalHeader {...baseProps} showMapLink={false} />);
    expect(screen.queryByRole("link", { name: "Map" })).toBeNull();
    expect(screen.queryByRole("link", { name: "Overview" })).toBeNull();
  });

  it("D-07: renders Map anchor when sections empty + showMapLink=true on home", () => {
    mockPathname.mockReturnValue("/portal/acme/riverdale");
    render(<PortalHeader {...baseProps} sectionAnchors={[]} showMapLink={true} />);
    const nav = screen.getByRole("navigation", { name: /portal section navigation/i });
    const links = within(nav).getAllByRole("link");
    expect(links).toHaveLength(1);
    expect(links[0].textContent).toBe("Map");
  });
});
