"use client";

import { useState, useEffect, useCallback } from "react";
import { tokens } from "@/lib/design-tokens";
import { SECTION_ORDER } from "@/lib/portal/types";
import type { PortalSectionKey, PortalAnalyticsEvent } from "@/lib/portal/types";

// D-21, D-43: Portal analytics dashboard
// Total views, unique viewers, avg time, per-section metrics, bar chart

type AnalyticsData = {
  totalViews: number;
  perSectionViews: Record<string, number>;
  avgTimeSpentMs: number;
  avgScrollDepthPct: number;
  recentEvents: PortalAnalyticsEvent[];
};

type TimePeriod = 7 | 30 | 90 | 0; // 0 = all time

const SECTION_LABELS: Record<PortalSectionKey, string> = {
  schedule: "Schedule",
  budget: "Budget",
  photos: "Photos",
  change_orders: "Change Orders",
  documents: "Documents",
};

type PortalAnalyticsDashboardProps = {
  portalConfigId: string;
};

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  const seconds = Math.round(ms / 1000);
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainSec = seconds % 60;
  return `${minutes}m ${remainSec}s`;
}

function formatRelativeTime(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const hours = Math.floor(diff / (1000 * 60 * 60));
  if (hours < 1) return "Less than 1h ago";
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export function PortalAnalyticsDashboard({
  portalConfigId,
}: PortalAnalyticsDashboardProps) {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<TimePeriod>(30);

  const loadAnalytics = useCallback(async () => {
    setLoading(true);
    try {
      const days = period === 0 ? 365 : period;
      const res = await fetch(
        `/api/portal/analytics?portal_config_id=${portalConfigId}&days=${days}`
      );
      if (!res.ok) throw new Error("Failed to load analytics");
      const json = await res.json();
      setData(json.analytics ?? null);
    } catch {
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [portalConfigId, period]);

  useEffect(() => {
    loadAnalytics();
  }, [loadAnalytics]);

  // Compute unique viewers from recent events
  const uniqueViewers = data?.recentEvents
    ? new Set(
        data.recentEvents
          .filter((e) => e.ip_hash)
          .map((e) => e.ip_hash)
      ).size
    : 0;

  // Last viewed
  const lastViewed =
    data?.recentEvents && data.recentEvents.length > 0
      ? data.recentEvents[0].created_at
      : null;

  // Daily view counts for bar chart
  const dailyCounts: { date: string; count: number }[] = [];
  if (data?.recentEvents) {
    const countMap = new Map<string, number>();
    for (const ev of data.recentEvents) {
      const day = ev.created_at.slice(0, 10);
      countMap.set(day, (countMap.get(day) ?? 0) + 1);
    }
    const sorted = [...countMap.entries()].sort(
      (a, b) => a[0].localeCompare(b[0])
    );
    for (const [date, count] of sorted) {
      dailyCounts.push({ date, count });
    }
  }

  const maxCount = Math.max(1, ...dailyCounts.map((d) => d.count));

  if (loading) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: tokens.spacing.md,
          padding: tokens.spacing.md,
        }}
      >
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            style={{
              height: 60,
              background: tokens.colors.gray[100],
              borderRadius: tokens.radius.md,
              animation: `shimmer ${tokens.motion.shimmer} linear infinite`,
            }}
          />
        ))}
      </div>
    );
  }

  if (!data || data.totalViews === 0) {
    // Empty state
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          padding: `${tokens.spacing["3xl"]}px ${tokens.spacing.lg}px`,
          textAlign: "center",
        }}
      >
        <div
          style={{
            width: 56,
            height: 56,
            borderRadius: "50%",
            background: tokens.colors.primary[50],
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: 24,
            marginBottom: tokens.spacing.md,
          }}
        >
          {"\uD83D\uDC41"}
        </div>
        <h3
          style={{
            margin: 0,
            fontSize: tokens.typography.fontSize.lg,
            fontWeight: tokens.typography.fontWeight.semibold,
            color: tokens.colors.gray[900],
            marginBottom: tokens.spacing.xs,
          }}
        >
          No views yet
        </h3>
        <p
          style={{
            margin: 0,
            fontSize: tokens.typography.fontSize.sm,
            color: tokens.colors.gray[500],
            maxWidth: 320,
            lineHeight: tokens.typography.lineHeight.relaxed,
            marginBottom: tokens.spacing.md,
          }}
        >
          Share this portal link to start tracking engagement.
        </p>
        <button
          type="button"
          onClick={() => {
            // Copy link action — parent handles this
          }}
          style={{
            padding: "8px 20px",
            fontSize: tokens.typography.fontSize.sm,
            fontWeight: tokens.typography.fontWeight.medium,
            border: `1px solid ${tokens.colors.primary[600]}`,
            borderRadius: tokens.radius.md,
            background: tokens.card.bg,
            color: tokens.colors.primary[600],
            cursor: "pointer",
          }}
        >
          Copy Link
        </button>
      </div>
    );
  }

  const statCardStyle: React.CSSProperties = {
    padding: tokens.spacing.md,
    background: tokens.card.bg,
    border: `1px solid ${tokens.colors.gray[200]}`,
    borderRadius: tokens.radius.md,
    textAlign: "center",
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: tokens.spacing.md }}>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <h2
          style={{
            margin: 0,
            fontSize: tokens.typography.fontSize.xl,
            fontWeight: tokens.typography.fontWeight.semibold,
            color: tokens.colors.gray[900],
          }}
        >
          Portal Analytics
        </h2>

        {/* Time period selector */}
        <div style={{ display: "flex", gap: 4 }}>
          {([7, 30, 90, 0] as TimePeriod[]).map((p) => (
            <button
              key={p}
              type="button"
              onClick={() => setPeriod(p)}
              style={{
                padding: "4px 12px",
                fontSize: tokens.typography.fontSize.xs,
                fontWeight:
                  period === p
                    ? tokens.typography.fontWeight.semibold
                    : tokens.typography.fontWeight.normal,
                border: `1px solid ${period === p ? tokens.colors.primary[600] : tokens.colors.gray[200]}`,
                borderRadius: tokens.radius.sm,
                background:
                  period === p ? tokens.colors.primary[50] : tokens.card.bg,
                color:
                  period === p
                    ? tokens.colors.primary[600]
                    : tokens.colors.gray[600],
                cursor: "pointer",
              }}
            >
              {p === 0 ? "All time" : `${p} days`}
            </button>
          ))}
        </div>
      </div>

      {/* Summary cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: tokens.spacing.sm,
        }}
      >
        <div style={statCardStyle}>
          <div
            style={{
              fontSize: tokens.typography.fontSize["2xl"],
              fontWeight: tokens.typography.fontWeight.bold,
              color: tokens.colors.primary[600],
            }}
          >
            {data.totalViews}
          </div>
          <div
            style={{
              fontSize: tokens.typography.fontSize.xs,
              color: tokens.colors.gray[500],
              marginTop: 4,
            }}
          >
            Total Views
          </div>
        </div>
        <div style={statCardStyle}>
          <div
            style={{
              fontSize: tokens.typography.fontSize["2xl"],
              fontWeight: tokens.typography.fontWeight.bold,
              color: tokens.colors.primary[600],
            }}
          >
            {uniqueViewers}
          </div>
          <div
            style={{
              fontSize: tokens.typography.fontSize.xs,
              color: tokens.colors.gray[500],
              marginTop: 4,
            }}
          >
            Unique Viewers
          </div>
        </div>
        <div style={statCardStyle}>
          <div
            style={{
              fontSize: tokens.typography.fontSize["2xl"],
              fontWeight: tokens.typography.fontWeight.bold,
              color: tokens.colors.primary[600],
            }}
          >
            {formatDuration(data.avgTimeSpentMs)}
          </div>
          <div
            style={{
              fontSize: tokens.typography.fontSize.xs,
              color: tokens.colors.gray[500],
              marginTop: 4,
            }}
          >
            Avg Time Spent
          </div>
        </div>
        <div style={statCardStyle}>
          <div
            style={{
              fontSize: tokens.typography.fontSize["2xl"],
              fontWeight: tokens.typography.fontWeight.bold,
              color: tokens.colors.primary[600],
            }}
          >
            {lastViewed ? formatRelativeTime(lastViewed) : "Never"}
          </div>
          <div
            style={{
              fontSize: tokens.typography.fontSize.xs,
              color: tokens.colors.gray[500],
              marginTop: 4,
            }}
          >
            Last Viewed
          </div>
        </div>
      </div>

      {/* Per-section analytics table (D-43) */}
      <div
        style={{
          background: tokens.card.bg,
          border: `1px solid ${tokens.colors.gray[200]}`,
          borderRadius: tokens.radius.md,
          overflow: "hidden",
        }}
      >
        <div
          style={{
            padding: `${tokens.spacing.sm}px ${tokens.spacing.md}px`,
            background: tokens.colors.gray[50],
            borderBottom: `1px solid ${tokens.colors.gray[200]}`,
            fontSize: tokens.typography.fontSize.sm,
            fontWeight: tokens.typography.fontWeight.semibold,
            color: tokens.colors.gray[700],
          }}
        >
          Per-Section Analytics
        </div>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              <th
                style={{
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.xs,
                  fontWeight: tokens.typography.fontWeight.semibold,
                  color: tokens.colors.gray[500],
                  textAlign: "left",
                  borderBottom: `1px solid ${tokens.colors.gray[100]}`,
                }}
              >
                Section
              </th>
              <th
                style={{
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.xs,
                  fontWeight: tokens.typography.fontWeight.semibold,
                  color: tokens.colors.gray[500],
                  textAlign: "right",
                  borderBottom: `1px solid ${tokens.colors.gray[100]}`,
                }}
              >
                Views
              </th>
              <th
                style={{
                  padding: "8px 12px",
                  fontSize: tokens.typography.fontSize.xs,
                  fontWeight: tokens.typography.fontWeight.semibold,
                  color: tokens.colors.gray[500],
                  textAlign: "right",
                  borderBottom: `1px solid ${tokens.colors.gray[100]}`,
                }}
              >
                Avg Scroll Depth
              </th>
            </tr>
          </thead>
          <tbody>
            {SECTION_ORDER.map((key, idx) => {
              const views = data.perSectionViews[key] ?? 0;
              const rowBg =
                idx % 2 === 0 ? tokens.card.bg : tokens.colors.gray[50];
              return (
                <tr key={key} style={{ background: rowBg }}>
                  <td
                    style={{
                      padding: "8px 12px",
                      fontSize: tokens.typography.fontSize.sm,
                      color: tokens.colors.gray[700],
                    }}
                  >
                    {SECTION_LABELS[key]}
                  </td>
                  <td
                    style={{
                      padding: "8px 12px",
                      fontSize: tokens.typography.fontSize.sm,
                      color: tokens.colors.gray[700],
                      textAlign: "right",
                      fontWeight: tokens.typography.fontWeight.medium,
                    }}
                  >
                    {views}
                  </td>
                  <td
                    style={{
                      padding: "8px 12px",
                      fontSize: tokens.typography.fontSize.sm,
                      color: tokens.colors.gray[700],
                      textAlign: "right",
                    }}
                  >
                    {data.avgScrollDepthPct}%
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Simple bar chart for daily views (using recharts BarChart) */}
      {dailyCounts.length > 0 && (
        <div
          style={{
            background: tokens.card.bg,
            border: `1px solid ${tokens.colors.gray[200]}`,
            borderRadius: tokens.radius.md,
            padding: tokens.spacing.md,
          }}
        >
          <div
            style={{
              fontSize: tokens.typography.fontSize.sm,
              fontWeight: tokens.typography.fontWeight.semibold,
              color: tokens.colors.gray[700],
              marginBottom: tokens.spacing.sm,
            }}
          >
            Daily Views
          </div>
          <DailyViewsChart data={dailyCounts} maxCount={maxCount} />
        </div>
      )}
    </div>
  );
}

// Simple inline bar chart using recharts BarChart
function DailyViewsChart({
  data,
  maxCount,
}: {
  data: { date: string; count: number }[];
  maxCount: number;
}) {
  // Use recharts if available, otherwise fallback to CSS bars
  try {
    // Dynamic import check — if recharts is installed, use BarChart
    const RechartsBarChart = require("recharts").BarChart;
    const Bar = require("recharts").Bar;
    const XAxis = require("recharts").XAxis;
    const YAxis = require("recharts").YAxis;
    const Tooltip = require("recharts").Tooltip;
    const ResponsiveContainer = require("recharts").ResponsiveContainer;

    return (
      <ResponsiveContainer width="100%" height={200}>
        <RechartsBarChart data={data}>
          <XAxis
            dataKey="date"
            tick={{ fontSize: 10, fill: tokens.colors.gray[400] }}
            tickFormatter={(v: string) => v.slice(5)} // MM-DD
          />
          <YAxis
            tick={{ fontSize: 10, fill: tokens.colors.gray[400] }}
            allowDecimals={false}
          />
          <Tooltip
            formatter={(value: number) => [value, "Views"]}
            labelFormatter={(label: string) =>
              new Date(label).toLocaleDateString("en-US", {
                month: "short",
                day: "numeric",
              })
            }
          />
          <Bar
            dataKey="count"
            fill={tokens.colors.primary[500]}
            radius={[4, 4, 0, 0]}
          />
        </RechartsBarChart>
      </ResponsiveContainer>
    );
  } catch {
    // Fallback: CSS-based bars
    return (
      <div
        style={{
          display: "flex",
          alignItems: "flex-end",
          gap: 2,
          height: 120,
        }}
      >
        {data.map((d) => (
          <div
            key={d.date}
            style={{
              flex: 1,
              height: `${(d.count / maxCount) * 100}%`,
              minHeight: 4,
              background: tokens.colors.primary[500],
              borderRadius: "4px 4px 0 0",
            }}
            title={`${d.date}: ${d.count} views`}
          />
        ))}
      </div>
    );
  }
}
