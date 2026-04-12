"use client";

import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from "recharts";
import {
  CHART_SERIES_COLORS,
  CHART_TOOLTIP_STYLE,
  CHART_ANIMATION,
  CHART_HEIGHT,
  CHART_WRAPPER_STYLE,
  CHART_TITLE_STYLE,
} from "@/lib/reports/chart-config";
import { ChartExportButton } from "./ChartExportButton";
import { useRef } from "react";

type BudgetPieChartProps = {
  spent: number;
  remaining: number;
  mini?: boolean;
};

const formatDollar = (value: number): string => {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toLocaleString()}`;
};

export function BudgetPieChart({ spent, remaining, mini }: BudgetPieChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);
  const total = spent + remaining;
  const percent = total > 0 ? Math.round((spent / total) * 100) : 0;
  const height = mini ? CHART_HEIGHT.mini : CHART_HEIGHT.default;
  const innerRadius = mini ? 30 : 60;
  const outerRadius = mini ? 50 : 90;

  const data = [
    { name: "Spent", value: spent },
    { name: "Remaining", value: remaining },
  ];

  const colors = [CHART_SERIES_COLORS[0], CHART_SERIES_COLORS[2]];

  return (
    <div ref={chartRef} style={CHART_WRAPPER_STYLE} role="img" aria-label={`Budget chart: ${percent}% complete, ${formatDollar(spent)} spent of ${formatDollar(total)}`}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div style={CHART_TITLE_STYLE}>Budget Overview</div>
        <ChartExportButton chartRef={chartRef} filename="budget-chart" />
      </div>
      <ResponsiveContainer width="100%" height={height}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={innerRadius}
            outerRadius={outerRadius}
            dataKey="value"
            animationDuration={CHART_ANIMATION.duration}
            animationEasing={CHART_ANIMATION.easing}
            stroke="none"
          >
            {data.map((_, index) => (
              <Cell key={`cell-${index}`} fill={colors[index]} />
            ))}
          </Pie>
          <Tooltip
            // eslint-disable-next-line @typescript-eslint/no-explicit-any
            formatter={(value: any) => formatDollar(Number(value))}
            contentStyle={CHART_TOOLTIP_STYLE}
          />
        </PieChart>
      </ResponsiveContainer>
      {/* Center text overlay */}
      <div
        style={{
          position: "absolute",
          top: "50%",
          left: "50%",
          transform: "translate(-50%, -50%)",
          textAlign: "center",
          pointerEvents: "none",
          marginTop: mini ? 10 : 14,
        }}
      >
        <div style={{ fontSize: mini ? 16 : 24, fontWeight: 800, color: "var(--text)" }}>
          {percent}%
        </div>
        <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>
          Complete
        </div>
      </div>
      {/* Inline labels per D-23 */}
      <div style={{ display: "flex", justifyContent: "center", gap: 16, marginTop: 8 }}>
        {data.map((entry, index) => (
          <div key={entry.name} style={{ display: "flex", alignItems: "center", gap: 4 }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: colors[index] }} />
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", textTransform: "uppercase" }}>
              {entry.name}
            </span>
            <span style={{ fontSize: 8, fontWeight: 400, color: "var(--text)" }}>
              {formatDollar(entry.value)}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
