"use client";

import {
  LineChart,
  Line,
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

type SafetyLineChartProps = {
  monthlyData: Array<{ month: string; count: number }>;
  mini?: boolean;
};

export function SafetyLineChart({ monthlyData, mini }: SafetyLineChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);
  const height = mini ? CHART_HEIGHT.mini : CHART_HEIGHT.default;

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Safety incidents chart: ${monthlyData.length} months of data`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Safety Incidents</div>
        <ChartExportButton chartRef={chartRef} filename="safety-chart" />
      </div>
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={monthlyData}>
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
            formatter={(value: any) => [value, "Incidents"]}
            contentStyle={CHART_TOOLTIP_STYLE}
          />
          <Line
            type="monotone"
            dataKey="count"
            stroke={CHART_SERIES_COLORS[5]}
            strokeWidth={2}
            dot={{ r: 4, fill: CHART_SERIES_COLORS[5] }}
            activeDot={{ r: 6 }}
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
          />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
