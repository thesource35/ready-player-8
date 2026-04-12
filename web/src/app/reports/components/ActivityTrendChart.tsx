"use client";

import {
  AreaChart,
  Area,
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

type ActivityTrendChartProps = {
  data: Array<{ month: string; count: number }>;
  mini?: boolean;
};

/** D-19b: AreaChart with fillOpacity 0.1, stroke purple */
export function ActivityTrendChart({ data, mini }: ActivityTrendChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);
  const height = mini ? CHART_HEIGHT.mini : CHART_HEIGHT.default;

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Activity trend chart: ${data.length} months of data`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Activity Trend</div>
        <ChartExportButton chartRef={chartRef} filename="activity-trend-chart" />
      </div>
      <ResponsiveContainer width="100%" height={height}>
        <AreaChart data={data}>
          <CartesianGrid
            stroke={CHART_GRID_STYLE.stroke}
            strokeOpacity={CHART_GRID_STYLE.strokeOpacity}
          />
          <XAxis
            dataKey="month"
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
            formatter={(value: any) => [value, "Activities"]}
            contentStyle={CHART_TOOLTIP_STYLE}
          />
          <Area
            type="monotone"
            dataKey="count"
            stroke={CHART_SERIES_COLORS[3]}
            fill={CHART_SERIES_COLORS[3]}
            fillOpacity={0.1}
            strokeWidth={2}
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
