"use client";

import { useState, useRef } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer,
  RadarChart,
  Radar,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  LineChart,
  Line,
  AreaChart,
  Area,
  Legend,
} from "recharts";
import {
  CHART_SERIES_COLORS,
  CHART_TOOLTIP_STYLE,
  CHART_AXIS_STYLE,
  CHART_GRID_STYLE,
  CHART_ANIMATION,
  CHART_HEIGHT,
  CHART_WRAPPER_STYLE,
  CHART_TITLE_STYLE,
} from "@/lib/reports/chart-config";
import { ChartExportButton } from "./ChartExportButton";
import type { ProjectSummary } from "@/lib/reports/types";

// ---------- Types ----------

type PortfolioChartsProps = {
  projects: ProjectSummary[];
  monthlySpend: Array<{ month: string; amount: number }>;
};

type SpendViewMode = "aggregate" | "per-project" | "stacked";

// ---------- Helpers ----------

const formatDollar = (value: number): string => {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toLocaleString()}`;
};

// ---------- Component ----------

/**
 * D-19c: Portfolio-level charts — grouped bar, radar, monthly spend trend.
 * D-43: Monthly spend trend with toggle between aggregate/per-project/stacked area.
 */
export function PortfolioCharts({ projects, monthlySpend }: PortfolioChartsProps) {
  const barChartRef = useRef<HTMLDivElement>(null);
  const radarChartRef = useRef<HTMLDivElement>(null);
  const spendChartRef = useRef<HTMLDivElement>(null);
  const [spendView, setSpendView] = useState<SpendViewMode>("aggregate");

  // D-19c: grouped bar data — contract value vs billed per project (top 8)
  const barData = projects.slice(0, 8).map((p) => ({
    name: p.name.length > 12 ? p.name.slice(0, 12) + "..." : p.name,
    contractValue: p.contractValue,
    billed: p.billed,
  }));

  // D-19c: radar chart data — multi-dimensional health per project (top 6)
  const radarData = projects.slice(0, 6).map((p) => ({
    project: p.name.length > 10 ? p.name.slice(0, 10) + "..." : p.name,
    health: p.health.score,
    completion: p.percentComplete,
    safety: Math.max(0, 100 - p.safetyIncidents * 10),
    issues: Math.max(0, 100 - p.openIssues * 10),
    coverage: (p.featureCoverage.active / p.featureCoverage.total) * 100,
  }));

  // D-43: per-project spend data for multi-line chart
  // Build from monthly data + distribute by project proportionally
  const perProjectSpend = monthlySpend.map((m) => {
    const row: Record<string, number | string> = { month: m.month };
    row.total = m.amount;
    for (const p of projects.slice(0, 5)) {
      const ratio = projects.reduce((s, pr) => s + pr.billed, 0);
      row[p.name] = ratio > 0 ? (p.billed / ratio) * m.amount : 0;
    }
    return row;
  });

  const projectNames = projects.slice(0, 5).map((p) => p.name);

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      {/* D-19c: Grouped Bar — Financial Comparison */}
      <div ref={barChartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label="Portfolio financial comparison chart">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={CHART_TITLE_STYLE}>Financial Comparison</div>
          <ChartExportButton chartRef={barChartRef} filename="portfolio-financial-comparison" />
        </div>
        <ResponsiveContainer width="100%" height={CHART_HEIGHT.default}>
          <BarChart data={barData}>
            <CartesianGrid stroke={CHART_GRID_STYLE.stroke} strokeOpacity={CHART_GRID_STYLE.strokeOpacity} />
            <XAxis dataKey="name" tick={CHART_AXIS_STYLE} tickLine={false} axisLine={false} />
            <YAxis
              tick={CHART_AXIS_STYLE}
              tickLine={false}
              axisLine={false}
              // eslint-disable-next-line @typescript-eslint/no-explicit-any
              tickFormatter={(v: any) => formatDollar(Number(v))}
            />
            <Tooltip
              // eslint-disable-next-line @typescript-eslint/no-explicit-any
              formatter={(value: any) => formatDollar(Number(value))}
              contentStyle={CHART_TOOLTIP_STYLE}
            />
            <Bar
              dataKey="contractValue"
              name="Contract Value"
              fill={CHART_SERIES_COLORS[0]}
              radius={[4, 4, 0, 0]}
              animationDuration={CHART_ANIMATION.duration}
              animationEasing={CHART_ANIMATION.easing}
            />
            <Bar
              dataKey="billed"
              name="Billed"
              fill={CHART_SERIES_COLORS[1]}
              radius={[4, 4, 0, 0]}
              animationDuration={CHART_ANIMATION.duration}
              animationEasing={CHART_ANIMATION.easing}
            />
          </BarChart>
        </ResponsiveContainer>
        {/* D-23: inline labels */}
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 8 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: CHART_SERIES_COLORS[0] }} />
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>Contract Value</span>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: CHART_SERIES_COLORS[1] }} />
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>Billed</span>
          </div>
        </div>
      </div>

      {/* D-19c: Radar — Multi-dimensional Health */}
      <div ref={radarChartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label="Portfolio multi-dimensional health radar chart">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={CHART_TITLE_STYLE}>Multi-Dimensional Health</div>
          <ChartExportButton chartRef={radarChartRef} filename="portfolio-health-radar" />
        </div>
        <ResponsiveContainer width="100%" height={CHART_HEIGHT.default}>
          <RadarChart data={radarData}>
            <PolarGrid stroke="var(--border)" strokeOpacity={0.3} />
            <PolarAngleAxis
              dataKey="project"
              tick={{ fontSize: 8, fontWeight: 800, fill: "var(--muted)" }}
            />
            <PolarRadiusAxis
              angle={30}
              domain={[0, 100]}
              tick={{ fontSize: 8, fill: "var(--muted)" }}
            />
            <Tooltip contentStyle={CHART_TOOLTIP_STYLE} />
            <Radar
              name="Health"
              dataKey="health"
              stroke={CHART_SERIES_COLORS[2]}
              fill={CHART_SERIES_COLORS[2]}
              fillOpacity={0.2}
              animationDuration={CHART_ANIMATION.duration}
              animationEasing={CHART_ANIMATION.easing}
            />
            <Radar
              name="Completion"
              dataKey="completion"
              stroke={CHART_SERIES_COLORS[0]}
              fill={CHART_SERIES_COLORS[0]}
              fillOpacity={0.1}
              animationDuration={CHART_ANIMATION.duration}
              animationEasing={CHART_ANIMATION.easing}
            />
            <Radar
              name="Safety"
              dataKey="safety"
              stroke={CHART_SERIES_COLORS[1]}
              fill={CHART_SERIES_COLORS[1]}
              fillOpacity={0.1}
              animationDuration={CHART_ANIMATION.duration}
              animationEasing={CHART_ANIMATION.easing}
            />
          </RadarChart>
        </ResponsiveContainer>
        {/* D-23: inline labels */}
        <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 8 }}>
          {[
            { label: "Health", color: CHART_SERIES_COLORS[2] },
            { label: "Completion", color: CHART_SERIES_COLORS[0] },
            { label: "Safety", color: CHART_SERIES_COLORS[1] },
          ].map((item) => (
            <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 4 }}>
              <div style={{ width: 8, height: 8, borderRadius: "50%", background: item.color }} />
              <span style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>{item.label}</span>
            </div>
          ))}
        </div>
      </div>

      {/* D-43: Monthly Spend Trend */}
      <div ref={spendChartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label="Monthly spend trend chart">
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={CHART_TITLE_STYLE}>Monthly Spend Trend</div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {/* D-43: toggle between aggregate/per-project/stacked area */}
            {(["aggregate", "per-project", "stacked"] as SpendViewMode[]).map((mode) => (
              <button
                key={mode}
                onClick={() => setSpendView(mode)}
                style={{
                  fontSize: 8,
                  fontWeight: 800,
                  padding: "4px 8px",
                  borderRadius: 4,
                  border: "none",
                  cursor: "pointer",
                  textTransform: "uppercase",
                  letterSpacing: 0.5,
                  background: spendView === mode ? "var(--accent)" : "var(--surface)",
                  color: spendView === mode ? "var(--bg)" : "var(--muted)",
                }}
              >
                {mode === "per-project" ? "Per Project" : mode === "stacked" ? "Stacked" : "Aggregate"}
              </button>
            ))}
            <ChartExportButton chartRef={spendChartRef} filename="portfolio-spend-trend" />
          </div>
        </div>
        <ResponsiveContainer width="100%" height={CHART_HEIGHT.default}>
          {spendView === "stacked" ? (
            <AreaChart data={perProjectSpend}>
              <CartesianGrid stroke={CHART_GRID_STYLE.stroke} strokeOpacity={CHART_GRID_STYLE.strokeOpacity} />
              <XAxis dataKey="month" tick={CHART_AXIS_STYLE} tickLine={false} axisLine={false} />
              <YAxis
                tick={CHART_AXIS_STYLE}
                tickLine={false}
                axisLine={false}
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                tickFormatter={(v: any) => formatDollar(Number(v))}
              />
              <Tooltip
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                formatter={(value: any) => formatDollar(Number(value))}
                contentStyle={CHART_TOOLTIP_STYLE}
              />
              {projectNames.map((name, i) => (
                <Area
                  key={name}
                  type="monotone"
                  dataKey={name}
                  stackId="1"
                  stroke={CHART_SERIES_COLORS[i % CHART_SERIES_COLORS.length]}
                  fill={CHART_SERIES_COLORS[i % CHART_SERIES_COLORS.length]}
                  fillOpacity={0.3}
                  animationDuration={CHART_ANIMATION.duration}
                  animationEasing={CHART_ANIMATION.easing}
                />
              ))}
            </AreaChart>
          ) : (
            <LineChart data={spendView === "aggregate" ? monthlySpend : perProjectSpend}>
              <CartesianGrid stroke={CHART_GRID_STYLE.stroke} strokeOpacity={CHART_GRID_STYLE.strokeOpacity} />
              <XAxis dataKey="month" tick={CHART_AXIS_STYLE} tickLine={false} axisLine={false} />
              <YAxis
                tick={CHART_AXIS_STYLE}
                tickLine={false}
                axisLine={false}
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                tickFormatter={(v: any) => formatDollar(Number(v))}
              />
              <Tooltip
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
                formatter={(value: any) => formatDollar(Number(value))}
                contentStyle={CHART_TOOLTIP_STYLE}
              />
              {spendView === "aggregate" ? (
                <Line
                  type="monotone"
                  dataKey="amount"
                  name="Total Spend"
                  stroke={CHART_SERIES_COLORS[0]}
                  strokeWidth={3}
                  dot={{ r: 4, fill: CHART_SERIES_COLORS[0] }}
                  activeDot={{ r: 6 }}
                  animationDuration={CHART_ANIMATION.duration}
                  animationEasing={CHART_ANIMATION.easing}
                />
              ) : (
                <>
                  {/* Bold aggregate line */}
                  <Line
                    type="monotone"
                    dataKey="total"
                    name="Total"
                    stroke={CHART_SERIES_COLORS[0]}
                    strokeWidth={3}
                    dot={{ r: 4, fill: CHART_SERIES_COLORS[0] }}
                    animationDuration={CHART_ANIMATION.duration}
                    animationEasing={CHART_ANIMATION.easing}
                  />
                  {/* Per-project lines */}
                  {projectNames.map((name, i) => (
                    <Line
                      key={name}
                      type="monotone"
                      dataKey={name}
                      name={name}
                      stroke={CHART_SERIES_COLORS[(i + 1) % CHART_SERIES_COLORS.length]}
                      strokeWidth={1.5}
                      strokeDasharray="4 2"
                      dot={false}
                      animationDuration={CHART_ANIMATION.duration}
                      animationEasing={CHART_ANIMATION.easing}
                    />
                  ))}
                </>
              )}
            </LineChart>
          )}
        </ResponsiveContainer>
      </div>
    </div>
  );
}
