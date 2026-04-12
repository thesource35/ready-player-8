/**
 * @vitest-environment jsdom
 */
import { describe, it, expect, vi, afterEach } from "vitest";
import { render, screen, cleanup } from "@testing-library/react";
import React from "react";

afterEach(() => {
  cleanup();
});

// Mock Recharts ResponsiveContainer — jsdom has no layout engine so width/height = 0
vi.mock("recharts", async () => {
  const actual = await vi.importActual<typeof import("recharts")>("recharts");
  return {
    ...actual,
    ResponsiveContainer: ({ children }: { children: React.ReactNode }) => (
      <div style={{ width: 400, height: 240 }}>{children}</div>
    ),
  };
});

// Mock html2canvas — not available in jsdom
vi.mock("html2canvas", () => ({
  default: vi.fn().mockResolvedValue({
    toDataURL: () => "data:image/png;base64,mock",
  }),
}));

import { BudgetPieChart } from "../components/BudgetPieChart";
import { ScheduleBarChart } from "../components/ScheduleBarChart";
import { SafetyLineChart } from "../components/SafetyLineChart";
import { StatCard } from "../components/StatCard";
import { HealthBadge } from "../components/HealthBadge";
import { SkeletonReport } from "../components/SkeletonReport";

// ---------- BudgetPieChart ----------

describe("BudgetPieChart", () => {
  it("renders with spent=300000 remaining=150000 and shows 67% Complete", () => {
    render(<BudgetPieChart spent={300000} remaining={150000} />);
    expect(screen.getByText("67%")).toBeDefined();
    expect(screen.getByText("Complete")).toBeDefined();
  });

  it("renders inline labels for Spent and Remaining", () => {
    render(<BudgetPieChart spent={300000} remaining={150000} />);
    expect(screen.getByText("Spent")).toBeDefined();
    expect(screen.getByText("Remaining")).toBeDefined();
  });

  it("has aria-label with budget info", () => {
    const { container } = render(<BudgetPieChart spent={300000} remaining={150000} />);
    const wrapper = container.querySelector('[role="img"]');
    expect(wrapper).toBeDefined();
    expect(wrapper?.getAttribute("aria-label")).toContain("67%");
  });
});

// ---------- ScheduleBarChart ----------

describe("ScheduleBarChart", () => {
  const milestones = [
    { name: "Foundation", percentComplete: 100 },
    { name: "Framing", percentComplete: 75 },
    { name: "Roofing", percentComplete: 30 },
  ];

  it("renders with 3 milestones", () => {
    const { container } = render(<ScheduleBarChart milestones={milestones} />);
    // Check the chart wrapper renders
    const wrapper = container.querySelector('[role="img"]');
    expect(wrapper).toBeDefined();
    expect(wrapper?.getAttribute("aria-label")).toContain("3 milestones");
  });

  it("renders chart title", () => {
    render(<ScheduleBarChart milestones={milestones} />);
    expect(screen.getByText("Schedule Milestones")).toBeDefined();
  });
});

// ---------- SafetyLineChart ----------

describe("SafetyLineChart", () => {
  const monthlyData = [
    { month: "Jan", count: 2 },
    { month: "Feb", count: 1 },
    { month: "Mar", count: 3 },
    { month: "Apr", count: 0 },
    { month: "May", count: 1 },
    { month: "Jun", count: 2 },
  ];

  it("renders with 6 months of data", () => {
    const { container } = render(<SafetyLineChart monthlyData={monthlyData} />);
    const wrapper = container.querySelector('[role="img"]');
    expect(wrapper).toBeDefined();
    expect(wrapper?.getAttribute("aria-label")).toContain("6 months");
  });

  it("renders chart title", () => {
    render(<SafetyLineChart monthlyData={monthlyData} />);
    expect(screen.getByText("Safety Incidents")).toBeDefined();
  });
});

// ---------- StatCard ----------

describe("StatCard", () => {
  it("renders value and label text", () => {
    render(<StatCard value="$952K" label="BILLED" />);
    expect(screen.getByText("$952K")).toBeDefined();
    expect(screen.getByText("BILLED")).toBeDefined();
  });

  it("applies custom color to value", () => {
    render(<StatCard value="87%" label="COMPLETE" color="var(--green)" />);
    const valueEl = screen.getByText("87%");
    expect(valueEl.getAttribute("style")).toContain("--green");
  });

  it("defaults value color to var(--text) when no color prop", () => {
    render(<StatCard value="4.2" label="SCORE" />);
    const valueEl = screen.getByText("4.2");
    expect(valueEl.getAttribute("style")).toContain("--text");
  });
});

// ---------- HealthBadge ----------

describe("HealthBadge", () => {
  it("renders correct label for green", () => {
    render(<HealthBadge score={85} color="green" label="On Track" />);
    expect(screen.getByText("On Track")).toBeDefined();
  });

  it("renders correct label for gold", () => {
    render(<HealthBadge score={70} color="gold" label="At Risk" />);
    expect(screen.getByText("At Risk")).toBeDefined();
  });

  it("renders correct label for red", () => {
    render(<HealthBadge score={40} color="red" label="Critical" />);
    expect(screen.getByText("Critical")).toBeDefined();
  });

  it("maps green to var(--green)", () => {
    const { container } = render(<HealthBadge score={85} color="green" label="On Track" />);
    // The dot element
    const dot = container.querySelector("span > span:first-child");
    expect((dot as HTMLElement).style.background).toBe("var(--green)");
  });

  it("maps gold to var(--gold)", () => {
    const { container } = render(<HealthBadge score={70} color="gold" label="At Risk" />);
    const dot = container.querySelector("span > span:first-child");
    expect((dot as HTMLElement).style.background).toBe("var(--gold)");
  });

  it("maps red to var(--red)", () => {
    const { container } = render(<HealthBadge score={40} color="red" label="Critical" />);
    const dot = container.querySelector("span > span:first-child");
    expect((dot as HTMLElement).style.background).toBe("var(--red)");
  });

  it("has aria-label with score and label", () => {
    render(<HealthBadge score={85} color="green" label="On Track" />);
    const badge = screen.getByLabelText("Health score: 85% - On Track");
    expect(badge).toBeDefined();
  });
});

// ---------- SkeletonReport ----------

describe("SkeletonReport", () => {
  it("renders KPI skeleton cards", () => {
    render(<SkeletonReport />);
    const kpiGrid = screen.getByTestId("skeleton-kpi");
    expect(kpiGrid).toBeDefined();
    // Should have 4 skeleton cards
    expect(kpiGrid.children.length).toBe(4);
  });

  it("renders chart skeleton block", () => {
    render(<SkeletonReport />);
    const chart = screen.getByTestId("skeleton-chart");
    expect(chart).toBeDefined();
  });

  it("renders list skeleton rows", () => {
    render(<SkeletonReport />);
    const list = screen.getByTestId("skeleton-list");
    expect(list).toBeDefined();
    expect(list.children.length).toBe(4);
  });
});
