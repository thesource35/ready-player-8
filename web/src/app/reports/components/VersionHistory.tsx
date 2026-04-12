"use client";

import { useState, useEffect, useCallback } from "react";

// D-99: Report version history with full diff
// D-117: Time period comparison using version snapshots
// D-34l: Download PDF for any historical version
// D-96: Data retention indicator

type ReportVersion = {
  id: string;
  user_id: string;
  project_id: string | null;
  report_type: "project" | "rollup";
  snapshot_data: Record<string, unknown>;
  pdf_storage_path: string | null;
  created_at: string;
};

type MetricDiff = {
  key: string;
  label: string;
  oldValue: number;
  newValue: number;
  change: number;
  changePercent: number;
};

type VersionHistoryProps = {
  projectId: string;
  reportType?: "project" | "rollup";
  retentionDays?: number;
};

/** D-96: Calculate days until retention expiry */
function daysUntilExpiry(createdAt: string, retentionDays: number): number {
  const created = new Date(createdAt);
  const expiry = new Date(created.getTime() + retentionDays * 86400000);
  const now = new Date();
  return Math.max(0, Math.ceil((expiry.getTime() - now.getTime()) / 86400000));
}

/** Extract numeric metrics from snapshot_data for diff comparison */
function extractMetrics(snapshot: Record<string, unknown>): Record<string, number> {
  const metrics: Record<string, number> = {};

  // Budget metrics
  const budget = snapshot.budget as Record<string, unknown> | undefined;
  if (budget) {
    if (typeof budget.contractValue === "number") metrics["budget.contractValue"] = budget.contractValue;
    if (typeof budget.totalBilled === "number") metrics["budget.totalBilled"] = budget.totalBilled;
    if (typeof budget.percentComplete === "number") metrics["budget.percentComplete"] = budget.percentComplete;
    if (typeof budget.changeOrderNet === "number") metrics["budget.changeOrderNet"] = budget.changeOrderNet;
    if (typeof budget.spent === "number") metrics["budget.spent"] = budget.spent;
    if (typeof budget.remaining === "number") metrics["budget.remaining"] = budget.remaining;
  }

  // Schedule metrics
  const schedule = snapshot.schedule as Record<string, unknown> | undefined;
  if (schedule) {
    if (typeof schedule.delayedCount === "number") metrics["schedule.delayedCount"] = schedule.delayedCount;
    if (typeof schedule.totalCount === "number") metrics["schedule.totalCount"] = schedule.totalCount;
  }

  // Safety metrics
  const safety = snapshot.safety as Record<string, unknown> | undefined;
  if (safety) {
    if (typeof safety.totalIncidents === "number") metrics["safety.totalIncidents"] = safety.totalIncidents;
    if (typeof safety.daysSinceLastIncident === "number") metrics["safety.daysSinceLastIncident"] = safety.daysSinceLastIncident;
  }

  // Issues metrics
  const issues = snapshot.issues as Record<string, unknown> | undefined;
  if (issues) {
    if (typeof issues.criticalOpen === "number") metrics["issues.criticalOpen"] = issues.criticalOpen;
    if (typeof issues.totalOpen === "number") metrics["issues.totalOpen"] = issues.totalOpen;
  }

  // Team metrics
  const team = snapshot.team as Record<string, unknown> | undefined;
  if (team) {
    if (typeof team.memberCount === "number") metrics["team.memberCount"] = team.memberCount;
  }

  // Health score
  const health = snapshot.health as Record<string, unknown> | undefined;
  if (health && typeof health.score === "number") {
    metrics["health.score"] = health.score;
  }

  return metrics;
}

/** Human-readable label for metric key */
function metricLabel(key: string): string {
  const labels: Record<string, string> = {
    "budget.contractValue": "Contract Value",
    "budget.totalBilled": "Total Billed",
    "budget.percentComplete": "% Complete",
    "budget.changeOrderNet": "Change Order Net",
    "budget.spent": "Spent",
    "budget.remaining": "Remaining",
    "schedule.delayedCount": "Delayed Tasks",
    "schedule.totalCount": "Total Tasks",
    "safety.totalIncidents": "Safety Incidents",
    "safety.daysSinceLastIncident": "Days Since Last Incident",
    "issues.criticalOpen": "Critical Open Issues",
    "issues.totalOpen": "Total Open Issues",
    "team.memberCount": "Team Members",
    "health.score": "Health Score",
  };
  return labels[key] || key;
}

/** Compute diffs between two snapshots */
function computeDiffs(
  oldSnapshot: Record<string, unknown>,
  newSnapshot: Record<string, unknown>
): MetricDiff[] {
  const oldMetrics = extractMetrics(oldSnapshot);
  const newMetrics = extractMetrics(newSnapshot);
  const allKeys = new Set([...Object.keys(oldMetrics), ...Object.keys(newMetrics)]);
  const diffs: MetricDiff[] = [];

  for (const key of Array.from(allKeys)) {
    const oldVal = oldMetrics[key] ?? 0;
    const newVal = newMetrics[key] ?? 0;
    if (oldVal !== newVal) {
      diffs.push({
        key,
        label: metricLabel(key),
        oldValue: oldVal,
        newValue: newVal,
        change: newVal - oldVal,
        changePercent: oldVal !== 0 ? ((newVal - oldVal) / Math.abs(oldVal)) * 100 : 0,
      });
    }
  }

  return diffs;
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatNumber(n: number): string {
  if (Math.abs(n) >= 1000) {
    return n.toLocaleString(undefined, { maximumFractionDigits: 0 });
  }
  return n.toFixed(n % 1 === 0 ? 0 : 1);
}

export default function VersionHistory({
  projectId,
  reportType = "project",
  retentionDays = 365,
}: VersionHistoryProps) {
  const [versions, setVersions] = useState<ReportVersion[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [compareId, setCompareId] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const fetchVersions = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        project_id: projectId,
        report_type: reportType,
        limit: "50",
      });
      const res = await fetch(`/api/reports/history?${params}`);
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: "Failed to load" }));
        throw new Error(err.error || "Failed to load versions");
      }
      const data = await res.json();
      setVersions(data.versions ?? []);
      if (data.versions?.length > 0) {
        setSelectedId(data.versions[0].id);
        if (data.versions.length > 1) {
          setCompareId(data.versions[1].id);
        }
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load versions");
    } finally {
      setLoading(false);
    }
  }, [projectId, reportType]);

  useEffect(() => {
    if (projectId) {
      fetchVersions();
    }
  }, [projectId, fetchVersions]);

  const selectedVersion = versions.find((v) => v.id === selectedId);
  const compareVersion = versions.find((v) => v.id === compareId);
  const diffs =
    selectedVersion && compareVersion
      ? computeDiffs(compareVersion.snapshot_data, selectedVersion.snapshot_data)
      : [];

  return (
    <div
      style={{
        background: "var(--surface, #1a1a2e)",
        borderRadius: 14,
        padding: 16,
        border: "1px solid var(--border, #333)",
      }}
    >
      <h3
        style={{
          fontSize: 14,
          fontWeight: 800,
          color: "var(--text, #e5e5e5)",
          marginBottom: 12,
          letterSpacing: 1,
          textTransform: "uppercase",
        }}
      >
        Version History
      </h3>

      {error && (
        <div
          style={{
            padding: 8,
            marginBottom: 8,
            background: "rgba(239,68,68,0.1)",
            border: "1px solid var(--red, #ef4444)",
            borderRadius: 6,
            fontSize: 12,
            color: "var(--red, #ef4444)",
          }}
        >
          {error}
        </div>
      )}

      {loading && (
        <p style={{ fontSize: 12, color: "var(--muted, #888)", textAlign: "center", padding: 20 }}>
          Loading version history...
        </p>
      )}

      {!loading && versions.length === 0 && (
        <p style={{ fontSize: 12, color: "var(--muted, #888)", textAlign: "center", padding: 20 }}>
          No report versions yet. Generate a report to create the first version.
        </p>
      )}

      {!loading && versions.length > 0 && (
        <>
          {/* D-117: Version comparison dropdowns */}
          <div
            style={{
              display: "flex",
              gap: 12,
              marginBottom: 16,
              flexWrap: "wrap",
              alignItems: "center",
            }}
          >
            <label style={{ fontSize: 12, color: "var(--muted, #888)" }}>
              Current:
              <select
                value={selectedId ?? ""}
                onChange={(e) => setSelectedId(e.target.value)}
                style={{
                  marginLeft: 6,
                  padding: "4px 8px",
                  fontSize: 12,
                  background: "var(--bg, #0d1117)",
                  color: "var(--text, #e5e5e5)",
                  border: "1px solid var(--border, #333)",
                  borderRadius: 4,
                }}
              >
                {versions.map((v, i) => (
                  <option key={v.id} value={v.id}>
                    v{versions.length - i} - {formatDate(v.created_at)}
                  </option>
                ))}
              </select>
            </label>

            <label style={{ fontSize: 12, color: "var(--muted, #888)" }}>
              Compare with:
              <select
                value={compareId ?? ""}
                onChange={(e) => setCompareId(e.target.value)}
                style={{
                  marginLeft: 6,
                  padding: "4px 8px",
                  fontSize: 12,
                  background: "var(--bg, #0d1117)",
                  color: "var(--text, #e5e5e5)",
                  border: "1px solid var(--border, #333)",
                  borderRadius: 4,
                }}
              >
                <option value="">None</option>
                {versions
                  .filter((v) => v.id !== selectedId)
                  .map((v, i) => (
                    <option key={v.id} value={v.id}>
                      v{versions.length - versions.indexOf(v)} - {formatDate(v.created_at)}
                      {i === 0 ? " (previous)" : ""}
                    </option>
                  ))}
              </select>
            </label>
          </div>

          {/* D-99: Visual diff highlights */}
          {compareVersion && diffs.length > 0 && (
            <div style={{ marginBottom: 16 }}>
              <h4
                style={{
                  fontSize: 12,
                  fontWeight: 700,
                  color: "var(--accent, #f59e0b)",
                  marginBottom: 8,
                  textTransform: "uppercase",
                  letterSpacing: 0.5,
                }}
              >
                Changes
              </h4>
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))",
                  gap: 8,
                }}
              >
                {diffs.map((diff) => {
                  const isPositive = diff.change > 0;
                  // For some metrics, increase is bad (delayed count, incidents, critical issues)
                  const invertedMetrics = [
                    "schedule.delayedCount",
                    "safety.totalIncidents",
                    "issues.criticalOpen",
                    "issues.totalOpen",
                  ];
                  const isGood = invertedMetrics.includes(diff.key)
                    ? !isPositive
                    : isPositive;

                  return (
                    <div
                      key={diff.key}
                      style={{
                        padding: 10,
                        background: "var(--bg, #0d1117)",
                        borderRadius: 8,
                        border: `1px solid ${isGood ? "var(--green, #22c55e)" : "var(--red, #ef4444)"}`,
                      }}
                    >
                      <div
                        style={{
                          fontSize: 11,
                          color: "var(--muted, #888)",
                          marginBottom: 4,
                        }}
                      >
                        {diff.label}
                      </div>
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: 6,
                        }}
                      >
                        <span
                          style={{
                            fontSize: 13,
                            color: "var(--muted, #888)",
                            textDecoration: "line-through",
                          }}
                        >
                          {formatNumber(diff.oldValue)}
                        </span>
                        <span
                          style={{
                            fontSize: 14,
                            fontWeight: 700,
                            color: isGood
                              ? "var(--green, #22c55e)"
                              : "var(--red, #ef4444)",
                          }}
                        >
                          {isPositive ? "\u2191" : "\u2193"} {formatNumber(diff.newValue)}
                        </span>
                        {diff.changePercent !== 0 && (
                          <span
                            style={{
                              fontSize: 10,
                              color: isGood
                                ? "var(--green, #22c55e)"
                                : "var(--red, #ef4444)",
                            }}
                          >
                            ({isPositive ? "+" : ""}
                            {diff.changePercent.toFixed(1)}%)
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {compareVersion && diffs.length === 0 && (
            <p
              style={{
                fontSize: 12,
                color: "var(--muted, #888)",
                marginBottom: 12,
                fontStyle: "italic",
              }}
            >
              No metric changes between these versions.
            </p>
          )}

          {/* Version list */}
          <div style={{ maxHeight: 400, overflowY: "auto" }}>
            {versions.map((version, index) => {
              const versionNumber = versions.length - index;
              const remaining = daysUntilExpiry(version.created_at, retentionDays);
              const nearingExpiry = remaining <= 30;

              return (
                <div
                  key={version.id}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "space-between",
                    padding: "8px 12px",
                    marginBottom: 4,
                    background:
                      selectedId === version.id
                        ? "rgba(245, 158, 11, 0.1)"
                        : "transparent",
                    borderRadius: 6,
                    border: `1px solid ${
                      selectedId === version.id
                        ? "var(--accent, #f59e0b)"
                        : "var(--border, #333)"
                    }`,
                    cursor: "pointer",
                  }}
                  onClick={() => setSelectedId(version.id)}
                >
                  <div>
                    <div
                      style={{
                        fontSize: 13,
                        fontWeight: 600,
                        color: "var(--text, #e5e5e5)",
                      }}
                    >
                      Version {versionNumber}
                    </div>
                    <div
                      style={{
                        fontSize: 11,
                        color: "var(--muted, #888)",
                        marginTop: 2,
                      }}
                    >
                      {formatDate(version.created_at)}
                    </div>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    {/* D-96: Data retention indicator */}
                    <span
                      style={{
                        fontSize: 10,
                        padding: "2px 6px",
                        borderRadius: 4,
                        background: nearingExpiry
                          ? "rgba(239,68,68,0.15)"
                          : "rgba(34,197,94,0.1)",
                        color: nearingExpiry
                          ? "var(--red, #ef4444)"
                          : "var(--green, #22c55e)",
                        border: `1px solid ${
                          nearingExpiry
                            ? "var(--red, #ef4444)"
                            : "var(--green, #22c55e)"
                        }`,
                      }}
                    >
                      {remaining === 0
                        ? "Expiring"
                        : nearingExpiry
                          ? `${remaining}d left`
                          : `${remaining}d`}
                    </span>

                    {/* D-34l: Download PDF for historical version */}
                    {version.pdf_storage_path && (
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          // Open Supabase Storage URL for PDF download
                          window.open(version.pdf_storage_path!, "_blank");
                        }}
                        style={{
                          padding: "3px 8px",
                          fontSize: 10,
                          fontWeight: 600,
                          background: "var(--purple, #a855f7)",
                          color: "#fff",
                          border: "none",
                          borderRadius: 4,
                          cursor: "pointer",
                        }}
                      >
                        PDF
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
