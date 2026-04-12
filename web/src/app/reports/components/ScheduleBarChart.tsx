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

type Milestone = {
  name: string;
  percentComplete: number;
};

type ScheduleBarChartProps = {
  milestones: Milestone[];
  onMilestoneClick?: (milestone: Milestone) => void;
};

/** D-26: Show top 5-8 milestones. T-19-03: Cap at 8 to prevent DoS. */
const MAX_MILESTONES = 8;

export function ScheduleBarChart({ milestones, onMilestoneClick }: ScheduleBarChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);
  const displayData = milestones.slice(0, MAX_MILESTONES);

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Schedule chart: ${displayData.length} milestones`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Schedule Milestones</div>
        <ChartExportButton chartRef={chartRef} filename="schedule-chart" />
      </div>
      <ResponsiveContainer width="100%" height={CHART_HEIGHT.default}>
        <BarChart data={displayData}>
          <CartesianGrid
            stroke={CHART_GRID_STYLE.stroke}
            strokeOpacity={CHART_GRID_STYLE.strokeOpacity}
            vertical={false}
          />
          <XAxis
            dataKey="name"
            tick={CHART_AXIS_STYLE}
            tickLine={false}
            axisLine={false}
          />
          <YAxis
            domain={[0, 100]}
            tick={CHART_AXIS_STYLE}
            tickLine={false}
            axisLine={false}
            tickFormatter={(v: number) => `${v}%`}
          />
          <Tooltip
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            formatter={(value: any) => [`${value}%`, "Complete"]}
            contentStyle={CHART_TOOLTIP_STYLE}
          />
          <Bar
            dataKey="percentComplete"
            fill={CHART_SERIES_COLORS[1]}
            barSize={24}
            radius={[4, 4, 0, 0]}
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
            onClick={(_data: unknown, index: number) => {
              if (onMilestoneClick && displayData[index]) {
                onMilestoneClick(displayData[index]);
              }
            }}
            style={{ cursor: onMilestoneClick ? "pointer" : "default" }}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
