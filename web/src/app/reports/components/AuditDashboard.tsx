"use client";

import { useEffect, useState, useMemo } from "react";
import { StatCard } from "./StatCard";

// ---------- Types ----------

type AuditAction = "viewed" | "exported" | "shared" | "scheduled" | "commented" | "annotated";

type AuditEntry = {
  id: string;
  user_id: string;
  user_email?: string;
  action: AuditAction;
  report_type: string | null;
  project_id: string | null;
  device_info: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
};

type DateRange = {
  start: string;
  end: string;
};

// ---------- Helpers ----------

const ACTION_COLORS: Record<AuditAction, string> = {
  viewed: "var(--cyan)",
  exported: "var(--accent)",
  shared: "var(--green)",
  scheduled: "var(--purple)",
  commented: "var(--gold)",
  annotated: "var(--muted)",
};

const ACTION_LABELS: Record<AuditAction, string> = {
  viewed: "Viewed",
  exported: "Exported",
  shared: "Shared",
  scheduled: "Scheduled",
  commented: "Commented",
  annotated: "Annotated",
};

function formatTimestamp(ts: string): string {
  try {
    const d = new Date(ts);
    return d.toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return ts;
  }
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().split("T")[0];
}

// ---------- Demo Data ----------

const DEMO_ENTRIES: AuditEntry[] = [
  {
    id: "demo-a1",
    user_id: "u1",
    user_email: "jmartinez@example.com",
    action: "viewed",
    report_type: "project",
    project_id: "p1",
    device_info: "Chrome 124 / macOS 15",
    metadata: null,
    created_at: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: "demo-a2",
    user_id: "u2",
    user_email: "schen@example.com",
    action: "exported",
    report_type: "project",
    project_id: "p1",
    device_info: "Safari 18 / iOS 18",
    metadata: { format: "pdf" },
    created_at: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: "demo-a3",
    user_id: "u1",
    user_email: "jmartinez@example.com",
    action: "shared",
    report_type: "rollup",
    project_id: null,
    device_info: "Chrome 124 / macOS 15",
    metadata: { recipients: 3 },
    created_at: new Date(Date.now() - 8 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: "demo-a4",
    user_id: "u3",
    user_email: "kpatel@example.com",
    action: "viewed",
    report_type: "project",
    project_id: "p2",
    device_info: "Edge 124 / Windows 11",
    metadata: null,
    created_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: "demo-a5",
    user_id: "u2",
    user_email: "schen@example.com",
    action: "commented",
    report_type: "project",
    project_id: "p1",
    device_info: "Safari 18 / iOS 18",
    metadata: null,
    created_at: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: "demo-a6",
    user_id: "u1",
    user_email: "jmartinez@example.com",
    action: "scheduled",
    report_type: "rollup",
    project_id: null,
    device_info: "Chrome 124 / macOS 15",
    metadata: { frequency: "weekly" },
    created_at: new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString(),
  },
];

// ---------- Simple Bar Chart ----------

function SimpleBarChart({
  data,
  maxHeight = 100,
}: {
  data: { label: string; value: number; color: string }[];
  maxHeight?: number;
}) {
  const maxVal = Math.max(...data.map((d) => d.value), 1);

  return (
    <div style={{ display: "flex", alignItems: "flex-end", gap: 6, height: maxHeight }}>
      {data.map((d) => (
        <div
          key={d.label}
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            flex: 1,
          }}
        >
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "var(--text)",
              marginBottom: 2,
            }}
          >
            {d.value}
          </div>
          <div
            style={{
              width: "100%",
              maxWidth: 40,
              height: Math.max(4, (d.value / maxVal) * (maxHeight - 20)),
              background: d.color,
              borderRadius: "4px 4px 0 0",
              transition: "height 0.3s",
            }}
          />
          <div
            style={{
              fontSize: 9,
              color: "var(--muted)",
              marginTop: 4,
              textAlign: "center",
              whiteSpace: "nowrap",
            }}
          >
            {d.label}
          </div>
        </div>
      ))}
    </div>
  );
}

// ---------- Component ----------

export function AuditDashboard() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState<DateRange>({
    start: daysAgo(30),
    end: daysAgo(0),
  });
  const [actionFilter, setActionFilter] = useState<string>("all");
  const [userFilter, setUserFilter] = useState<string>("all");

  useEffect(() => {
    let cancelled = false;

    async function loadAuditLog() {
      try {
        const params = new URLSearchParams({
          start: dateRange.start,
          end: dateRange.end,
        });
        const res = await fetch(`/api/reports/audit?${params}`);
        if (!res.ok) throw new Error("Failed to load audit log");
        const data = await res.json();
        if (!cancelled && Array.isArray(data.entries) && data.entries.length > 0) {
          setEntries(data.entries);
        } else {
          throw new Error("No entries");
        }
      } catch {
        // Fall back to demo data
        if (!cancelled) {
          setEntries(DEMO_ENTRIES);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadAuditLog();
    return () => {
      cancelled = true;
    };
  }, [dateRange]);

  // Computed stats
  const filtered = useMemo(() => {
    let list = entries;
    if (actionFilter !== "all") {
      list = list.filter((e) => e.action === actionFilter);
    }
    if (userFilter !== "all") {
      list = list.filter((e) => e.user_email === userFilter);
    }
    return list;
  }, [entries, actionFilter, userFilter]);

  const uniqueUsers = useMemo(
    () => [...new Set(entries.map((e) => e.user_email).filter(Boolean))] as string[],
    [entries]
  );

  // Action breakdown for bar chart
  const actionCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const e of entries) {
      counts[e.action] = (counts[e.action] || 0) + 1;
    }
    return Object.entries(counts)
      .map(([action, value]) => ({
        label: ACTION_LABELS[action as AuditAction] ?? action,
        value,
        color: ACTION_COLORS[action as AuditAction] ?? "var(--muted)",
      }))
      .sort((a, b) => b.value - a.value);
  }, [entries]);

  // Report type breakdown for pie-like display
  const reportTypeCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const e of entries) {
      const rt = e.report_type ?? "unknown";
      counts[rt] = (counts[rt] || 0) + 1;
    }
    return counts;
  }, [entries]);

  const totalViews = entries.filter((e) => e.action === "viewed").length;
  const totalExports = entries.filter((e) => e.action === "exported").length;

  if (loading) {
    return (
      <div style={{ padding: 20, color: "var(--muted)", fontSize: 12 }}>
        Loading audit log...
      </div>
    );
  }

  return (
    <div>
      <div style={{ fontSize: 14, fontWeight: 800, color: "var(--text)", marginBottom: 12 }}>
        Audit Dashboard
      </div>
      <div style={{ fontSize: 11, color: "var(--muted)", marginBottom: 16 }}>
        Access patterns and report activity per D-112.
      </div>

      {/* KPI cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(120px, 1fr))",
          gap: 8,
          marginBottom: 16,
        }}
      >
        <StatCard value={String(entries.length)} label="Total Actions" color="var(--accent)" />
        <StatCard value={String(totalViews)} label="Views" color="var(--cyan)" />
        <StatCard value={String(totalExports)} label="Exports" color="var(--gold)" />
        <StatCard value={String(uniqueUsers.length)} label="Unique Users" color="var(--green)" />
      </div>

      {/* Charts */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gap: 12,
          marginBottom: 16,
        }}
      >
        {/* Action breakdown bar chart */}
        <div
          style={{
            background: "var(--panel)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            padding: 12,
          }}
        >
          <div
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: "var(--text)",
              marginBottom: 8,
            }}
          >
            Actions by Type
          </div>
          <SimpleBarChart data={actionCounts} />
        </div>

        {/* Report type breakdown */}
        <div
          style={{
            background: "var(--panel)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            padding: 12,
          }}
        >
          <div
            style={{
              fontSize: 11,
              fontWeight: 700,
              color: "var(--text)",
              marginBottom: 8,
            }}
          >
            By Report Type
          </div>
          {Object.entries(reportTypeCounts).map(([type, count]) => {
            const total = entries.length || 1;
            const pct = Math.round((count / total) * 100);
            return (
              <div key={type} style={{ marginBottom: 6 }}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    fontSize: 11,
                    color: "var(--text)",
                    marginBottom: 2,
                  }}
                >
                  <span style={{ textTransform: "capitalize" }}>{type}</span>
                  <span>
                    {count} ({pct}%)
                  </span>
                </div>
                <div
                  style={{
                    height: 6,
                    background: "var(--surface)",
                    borderRadius: 3,
                    overflow: "hidden",
                  }}
                >
                  <div
                    style={{
                      height: "100%",
                      width: `${pct}%`,
                      background: type === "project" ? "var(--cyan)" : "var(--accent)",
                      borderRadius: 3,
                      transition: "width 0.3s",
                    }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Filters */}
      <div
        style={{
          display: "flex",
          gap: 8,
          marginBottom: 12,
          flexWrap: "wrap",
          alignItems: "center",
        }}
      >
        <label style={{ fontSize: 11, color: "var(--muted)" }}>
          From:
          <input
            type="date"
            value={dateRange.start}
            onChange={(e) => setDateRange((r) => ({ ...r, start: e.target.value }))}
            style={{
              marginLeft: 4,
              padding: "4px 6px",
              fontSize: 11,
              background: "var(--panel)",
              color: "var(--text)",
              border: "1px solid var(--border)",
              borderRadius: 4,
            }}
          />
        </label>
        <label style={{ fontSize: 11, color: "var(--muted)" }}>
          To:
          <input
            type="date"
            value={dateRange.end}
            onChange={(e) => setDateRange((r) => ({ ...r, end: e.target.value }))}
            style={{
              marginLeft: 4,
              padding: "4px 6px",
              fontSize: 11,
              background: "var(--panel)",
              color: "var(--text)",
              border: "1px solid var(--border)",
              borderRadius: 4,
            }}
          />
        </label>
        <select
          value={actionFilter}
          onChange={(e) => setActionFilter(e.target.value)}
          aria-label="Filter by action"
          style={{
            padding: "4px 8px",
            fontSize: 11,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 4,
          }}
        >
          <option value="all">All Actions</option>
          {(["viewed", "exported", "shared", "scheduled", "commented", "annotated"] as AuditAction[]).map(
            (a) => (
              <option key={a} value={a}>
                {ACTION_LABELS[a]}
              </option>
            )
          )}
        </select>
        <select
          value={userFilter}
          onChange={(e) => setUserFilter(e.target.value)}
          aria-label="Filter by user"
          style={{
            padding: "4px 8px",
            fontSize: 11,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 4,
          }}
        >
          <option value="all">All Users</option>
          {uniqueUsers.map((u) => (
            <option key={u} value={u}>
              {u}
            </option>
          ))}
        </select>
      </div>

      {/* Access log table (D-112) */}
      <div
        style={{
          background: "var(--panel)",
          border: "1px solid var(--border)",
          borderRadius: 8,
          overflow: "hidden",
        }}
      >
        <table
          style={{
            width: "100%",
            borderCollapse: "collapse",
            fontSize: 11,
          }}
        >
          <thead>
            <tr
              style={{
                background: "var(--surface)",
                textAlign: "left",
              }}
            >
              <th style={{ padding: "8px 10px", fontWeight: 700, color: "var(--text)" }}>
                User
              </th>
              <th style={{ padding: "8px 10px", fontWeight: 700, color: "var(--text)" }}>
                Action
              </th>
              <th style={{ padding: "8px 10px", fontWeight: 700, color: "var(--text)" }}>
                Report Type
              </th>
              <th style={{ padding: "8px 10px", fontWeight: 700, color: "var(--text)" }}>
                Device / Browser
              </th>
              <th style={{ padding: "8px 10px", fontWeight: 700, color: "var(--text)" }}>
                Timestamp
              </th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td
                  colSpan={5}
                  style={{
                    padding: 16,
                    textAlign: "center",
                    color: "var(--muted)",
                  }}
                >
                  No audit entries match your filters.
                </td>
              </tr>
            ) : (
              filtered.map((entry) => (
                <tr
                  key={entry.id}
                  style={{ borderTop: "1px solid var(--border)" }}
                >
                  <td style={{ padding: "6px 10px", color: "var(--text)" }}>
                    {entry.user_email ?? entry.user_id.slice(0, 8)}
                  </td>
                  <td style={{ padding: "6px 10px" }}>
                    <span
                      style={{
                        fontSize: 9,
                        fontWeight: 700,
                        color: ACTION_COLORS[entry.action],
                        background: `${ACTION_COLORS[entry.action]}15`,
                        padding: "2px 6px",
                        borderRadius: 3,
                        textTransform: "uppercase",
                      }}
                    >
                      {entry.action}
                    </span>
                  </td>
                  <td
                    style={{
                      padding: "6px 10px",
                      color: "var(--muted)",
                      textTransform: "capitalize",
                    }}
                  >
                    {entry.report_type ?? "—"}
                  </td>
                  <td style={{ padding: "6px 10px", color: "var(--muted)" }}>
                    {entry.device_info ?? "—"}
                  </td>
                  <td style={{ padding: "6px 10px", color: "var(--muted)" }}>
                    {formatTimestamp(entry.created_at)}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
