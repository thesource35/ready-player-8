"use client";

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer,
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
import { useRef } from "react";

type TeamUtilizationChartProps = {
  roleBreakdown: Record<string, number>;
  workload?: Array<{ name: string; hours: number }>;
};

/** D-19b: stacked bar for role breakdown, horizontal bar for workload */
export function TeamUtilizationChart({ roleBreakdown, workload }: TeamUtilizationChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);

  // Transform role breakdown to chart data
  const roleData = Object.entries(roleBreakdown).map(([role, count]) => ({
    role,
    count,
  }));

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Team utilization: ${roleData.length} roles`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Team Utilization</div>
        <ChartExportButton chartRef={chartRef} filename="team-utilization-chart" />
      </div>

      {/* Role breakdown vertical bar */}
      <ResponsiveContainer width="100%" height={CHART_HEIGHT.default}>
        <BarChart data={roleData}>
          <CartesianGrid
            stroke={CHART_GRID_STYLE.stroke}
            strokeOpacity={CHART_GRID_STYLE.strokeOpacity}
            vertical={false}
          />
          <XAxis
            dataKey="role"
            tick={CHART_AXIS_STYLE}
            tickLine={false}
            axisLine={false}
          />
          <YAxis
            tick={CHART_AXIS_STYLE}
            tickLine={false}
            axisLine={false}
            allowDecimals={false}
          />
          <Tooltip
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            formatter={(value: any) => [value, "Members"]}
            contentStyle={CHART_TOOLTIP_STYLE}
          />
          <Bar
            dataKey="count"
            fill={CHART_SERIES_COLORS[3]}
            barSize={24}
            radius={[4, 4, 0, 0]}
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
          />
        </BarChart>
      </ResponsiveContainer>

      {/* Workload horizontal bar (if provided) */}
      {workload && workload.length > 0 && (
        <>
          <div style={{ ...CHART_TITLE_STYLE, marginTop: 16 }}>Workload by Member</div>
          <ResponsiveContainer width="100%" height={Math.max(CHART_HEIGHT.mini, workload.length * 40)}>
            <BarChart data={workload} layout="vertical">
              <CartesianGrid
                stroke={CHART_GRID_STYLE.stroke}
                strokeOpacity={CHART_GRID_STYLE.strokeOpacity}
                horizontal={false}
              />
              <XAxis
                type="number"
                tick={CHART_AXIS_STYLE}
                tickLine={false}
                axisLine={false}
                tickFormatter={(v: number) => `${v}h`}
              />
              <YAxis
                type="category"
                dataKey="name"
                tick={CHART_AXIS_STYLE}
                tickLine={false}
                axisLine={false}
                width={80}
              />
              <Tooltip
                // eslint-disable-next-line @typescript-eslint/no-explicit-any
            formatter={(value: any) => [`${value}h`, "Hours"]}
                contentStyle={CHART_TOOLTIP_STYLE}
              />
              <Bar
                dataKey="hours"
                fill={CHART_SERIES_COLORS[1]}
                barSize={20}
                radius={[0, 4, 4, 0]}
                animationDuration={CHART_ANIMATION.duration}
                animationEasing={CHART_ANIMATION.easing}
              />
            </BarChart>
          </ResponsiveContainer>
        </>
      )}
    </div>
  );
}
