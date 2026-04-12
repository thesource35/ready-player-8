"use client";

import { useRef } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import {
  CHART_TOOLTIP_STYLE,
  CHART_AXIS_STYLE,
  CHART_ANIMATION,
  CHART_HEIGHT,
  CHART_WRAPPER_STYLE,
  CHART_TITLE_STYLE,
} from "@/lib/reports/chart-config";
import { ChartExportButton } from "./ChartExportButton";
import type { ProjectSummary } from "@/lib/reports/types";

// ---------- Types ----------

type PortfolioTimelineProps = {
  projects: ProjectSummary[];
};

// ---------- Helpers ----------

const healthBarColor = (score: number): string => {
  if (score >= 80) return "var(--green)";
  if (score >= 60) return "var(--gold)";
  return "var(--red)";
};

// ---------- Component ----------

/**
 * D-38: Horizontal timeline bars showing all projects' start/end dates (Gantt-style).
 * Uses Recharts BarChart with vertical layout.
 * Color-coded by health score (green/gold/red).
 * D-20: hover tooltip with project name, health, completion.
 */
export function PortfolioTimeline({ projects }: PortfolioTimelineProps) {
  const chartRef = useRef<HTMLDivElement>(null);

  if (projects.length === 0) {
    return (
      <div style={CHART_WRAPPER_STYLE}>
        <div style={CHART_TITLE_STYLE}>Portfolio Timeline</div>
        <div style={{ fontSize: 12, color: "var(--muted)", textAlign: "center", padding: 24 }}>
          No projects to display.
        </div>
      </div>
    );
  }

  // Build timeline data: each project as a horizontal bar representing % complete
  // Since we may not have actual dates from the rollup API, use percentComplete as bar width
  const timelineData = projects.map((p) => ({
    name: p.name.length > 18 ? p.name.slice(0, 18) + "..." : p.name,
    fullName: p.name,
    percentComplete: p.percentComplete,
    healthScore: p.health.score,
    healthLabel: p.health.label,
    status: p.status,
  }));

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Portfolio timeline showing ${projects.length} projects`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Portfolio Timeline</div>
        <ChartExportButton chartRef={chartRef} filename="portfolio-timeline" />
      </div>
      <ResponsiveContainer width="100%" height={Math.max(CHART_HEIGHT.default, projects.length * 36 + 40)}>
        <BarChart
          data={timelineData}
          layout="vertical"
          margin={{ top: 8, right: 24, bottom: 8, left: 8 }}
        >
          <XAxis
            type="number"
            domain={[0, 100]}
            tick={CHART_AXIS_STYLE}
            tickLine={false}
            axisLine={false}
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            tickFormatter={(v: any) => `${v}%`}
          />
          <YAxis
            type="category"
            dataKey="name"
            width={140}
            tick={{ ...CHART_AXIS_STYLE, fontSize: 10 }}
            tickLine={false}
            axisLine={false}
          />
          <Tooltip
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            content={({ active, payload }: any) => {
              if (!active || !payload?.[0]) return null;
              const d = payload[0].payload;
              return (
                <div style={{
                  ...CHART_TOOLTIP_STYLE,
                  background: "var(--surface)",
                  border: "1px solid var(--border)",
                }}>
                  <div style={{ fontSize: 12, fontWeight: 800, marginBottom: 4 }}>{d.fullName}</div>
                  <div style={{ fontSize: 10, color: "var(--muted)" }}>
                    Completion: {d.percentComplete}%
                  </div>
                  <div style={{ fontSize: 10, color: "var(--muted)" }}>
                    Health: {d.healthScore}% ({d.healthLabel})
                  </div>
                  <div style={{ fontSize: 10, color: "var(--muted)" }}>
                    Status: {d.status}
                  </div>
                </div>
              );
            }}
          />
          <Bar
            dataKey="percentComplete"
            name="Completion"
            barSize={20}
            radius={[0, 4, 4, 0]}
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
          >
            {timelineData.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={healthBarColor(entry.healthScore)} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
      {/* D-23: inline legend */}
      <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 8 }}>
        {[
          { label: "On Track (80+)", color: "var(--green)" },
          { label: "At Risk (60-79)", color: "var(--gold)" },
          { label: "Critical (<60)", color: "var(--red)" },
        ].map((item) => (
          <div key={item.label} style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 8, height: 8, borderRadius: 2, background: item.color }} />
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>
              {item.label}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
