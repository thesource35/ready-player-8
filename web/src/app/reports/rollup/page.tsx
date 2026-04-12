"use client";

import { useEffect, useState, useMemo, useCallback, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { StatCard } from "../components/StatCard";
import { HealthBadge } from "../components/HealthBadge";
import { SkeletonReport } from "../components/SkeletonReport";
import { PortfolioTable } from "../components/PortfolioTable";
import type { PortfolioRollup, ProjectSummary } from "@/lib/reports/types";
import { HEALTH_THRESHOLDS } from "@/lib/reports/constants";

// ---------- Constants ----------

/** D-45: auto-refresh polling interval (ms) */
const REFRESH_INTERVAL_MS = 5 * 60 * 1000;

/** D-39: valid status filter values (T-19-14 mitigation) */
const VALID_STATUSES = ["Active", "Delayed", "Completed", "On Hold", "Cancelled"] as const;

// ---------- Helpers ----------

const formatDollar = (value: number): string => {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toLocaleString()}`;
};

/** T-19-14: Validate filter values against allowed enums before API call */
function sanitizeStatus(val: string | null): string | null {
  if (!val || val === "all") return null;
  const match = VALID_STATUSES.find((s) => s.toLowerCase() === val.toLowerCase());
  return match ?? null;
}

function sanitizeAlphanumeric(val: string | null): string | null {
  if (!val) return null;
  return val.replace(/[^a-zA-Z0-9 \-_.]/g, "").trim() || null;
}

// ---------- Sort Logic ----------

type SortKey = string;
type SortDir = "asc" | "desc";

function sortProjects(
  projects: ProjectSummary[],
  key: SortKey,
  dir: SortDir
): ProjectSummary[] {
  return [...projects].sort((a, b) => {
    let cmp = 0;
    switch (key) {
      case "name":
        cmp = a.name.localeCompare(b.name);
        break;
      case "health":
        cmp = a.health.score - b.health.score;
        break;
      case "contractValue":
        cmp = a.contractValue - b.contractValue;
        break;
      case "billed":
        cmp = a.billed - b.billed;
        break;
      case "percentComplete":
        cmp = a.percentComplete - b.percentComplete;
        break;
      case "openIssues":
        cmp = a.openIssues - b.openIssues;
        break;
      case "safetyIncidents":
        cmp = a.safetyIncidents - b.safetyIncidents;
        break;
      case "status":
        cmp = a.status.localeCompare(b.status);
        break;
      default:
        cmp = 0;
    }
    return dir === "asc" ? cmp : -cmp;
  });
}

// ---------- Component ----------

export default function PortfolioRollupPage() {
  const router = useRouter();
  const searchParams = useSearchParams();

  // D-39: filters from URL params
  const [statusFilter, setStatusFilter] = useState<string>(
    searchParams.get("status") ?? "all"
  );
  const [projectType, setProjectType] = useState<string>(
    searchParams.get("project_type") ?? ""
  );
  const [clientFilter, setClientFilter] = useState<string>(
    searchParams.get("client") ?? ""
  );
  const [search, setSearch] = useState<string>(
    searchParams.get("q") ?? ""
  );
  const [showCompleted, setShowCompleted] = useState(
    searchParams.get("show_completed") === "true"
  );
  // D-46b: period comparison toggle
  const [comparePeriod, setComparePeriod] = useState(
    searchParams.get("compare") === "true"
  );

  // Sort state
  const [sortKey, setSortKey] = useState<string>(
    searchParams.get("sort") ?? "name"
  );
  const [sortDir, setSortDir] = useState<SortDir>(
    (searchParams.get("dir") as SortDir) ?? "asc"
  );

  // Data state
  const [rollup, setRollup] = useState<PortfolioRollup | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const refreshTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // D-39: persist filters to URL searchParams
  const updateURL = useCallback(
    (overrides: Record<string, string>) => {
      const params = new URLSearchParams(searchParams.toString());
      for (const [k, v] of Object.entries(overrides)) {
        if (v && v !== "all" && v !== "" && v !== "false") {
          params.set(k, v);
        } else {
          params.delete(k);
        }
      }
      router.replace(`/reports/rollup?${params.toString()}`, { scroll: false });
    },
    [router, searchParams]
  );

  // Fetch rollup data
  const fetchRollup = useCallback(
    async (isRefresh = false) => {
      if (isRefresh) setRefreshing(true);
      else setLoading(true);
      setError(null);

      try {
        const params = new URLSearchParams();
        const status = sanitizeStatus(statusFilter);
        if (status) params.set("status", status);
        const pt = sanitizeAlphanumeric(projectType);
        if (pt) params.set("project_type", pt);
        const cl = sanitizeAlphanumeric(clientFilter);
        if (cl) params.set("client", cl);
        if (comparePeriod) params.set("compare_period", "month");

        const res = await fetch(`/api/reports/rollup?${params.toString()}`);
        if (!res.ok) {
          const body = await res.json().catch(() => ({ error: "Request failed" }));
          throw new Error(body.error ?? `HTTP ${res.status}`);
        }
        const data: PortfolioRollup = await res.json();
        setRollup(data);
      } catch (err) {
        const msg = err instanceof Error ? err.message : "Unknown error";
        console.error("[rollup] Fetch failed:", msg);
        setError("Report data could not be loaded. Check your connection and try again.");
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [statusFilter, projectType, clientFilter, comparePeriod]
  );

  // Initial fetch + auto-refresh (D-45)
  useEffect(() => {
    fetchRollup();

    // D-45: 5-minute auto-refresh polling
    refreshTimerRef.current = setInterval(() => {
      fetchRollup(true);
    }, REFRESH_INTERVAL_MS);

    return () => {
      if (refreshTimerRef.current) clearInterval(refreshTimerRef.current);
    };
  }, [fetchRollup]);

  // Handle sort toggle
  const handleSort = useCallback(
    (key: string) => {
      const newDir = sortKey === key && sortDir === "asc" ? "desc" : "asc";
      setSortKey(key);
      setSortDir(newDir);
      updateURL({ sort: key, dir: newDir });
    },
    [sortKey, sortDir, updateURL]
  );

  // Filter change handlers
  const handleStatusChange = useCallback(
    (val: string) => {
      setStatusFilter(val);
      updateURL({ status: val });
    },
    [updateURL]
  );

  const handleProjectTypeChange = useCallback(
    (val: string) => {
      setProjectType(val);
      updateURL({ project_type: val });
    },
    [updateURL]
  );

  const handleClientChange = useCallback(
    (val: string) => {
      setClientFilter(val);
      updateURL({ client: val });
    },
    [updateURL]
  );

  const handleSearchChange = useCallback(
    (val: string) => {
      setSearch(val);
      updateURL({ q: val });
    },
    [updateURL]
  );

  const handleShowCompletedChange = useCallback(
    (val: boolean) => {
      setShowCompleted(val);
      updateURL({ show_completed: String(val) });
    },
    [updateURL]
  );

  const handleComparePeriodChange = useCallback(
    (val: boolean) => {
      setComparePeriod(val);
      updateURL({ compare: String(val) });
    },
    [updateURL]
  );

  // D-106: client-side search filter + D-42: status filtering with completed toggle
  const filteredProjects = useMemo(() => {
    if (!rollup) return [];
    let list = rollup.projects;

    // D-42: hide completed unless toggled
    if (statusFilter === "all" && !showCompleted) {
      list = list.filter((p) => p.status !== "Completed");
    }

    // D-106: search by project name
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter((p) => p.name.toLowerCase().includes(q));
    }

    // Sort
    list = sortProjects(list, sortKey, sortDir);

    return list;
  }, [rollup, statusFilter, showCompleted, search, sortKey, sortDir]);

  // KPI calculations
  const totalContractValue = rollup?.totals.contractValue ?? 0;
  const totalBilled = rollup?.totals.totalBilled ?? 0;
  const totalRemaining = totalContractValue - totalBilled;
  const changeOrderImpact = rollup?.totals.changeOrderNet ?? 0;
  const projectCount = rollup?.projects.length ?? 0;
  const avgHealth =
    projectCount > 0
      ? Math.round(
          (rollup?.projects ?? []).reduce(
            (sum, p) => sum + p.health.score,
            0
          ) / projectCount
        )
      : 0;
  const avgHealthColor =
    avgHealth >= HEALTH_THRESHOLDS.green.min
      ? "var(--green)"
      : avgHealth >= HEALTH_THRESHOLDS.gold.min
      ? "var(--gold)"
      : "var(--red)";

  // ---------- Render ----------

  if (loading) {
    return (
      <div style={{ maxWidth: 1200, margin: "0 auto", padding: 20 }}>
        <SkeletonReport />
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ maxWidth: 1200, margin: "0 auto", padding: 20 }}>
        <div
          style={{
            background: "var(--surface)",
            borderRadius: 14,
            padding: 32,
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: 12, color: "var(--red)", marginBottom: 12 }}>
            {error}
          </div>
          <button
            onClick={() => fetchRollup()}
            style={{
              background: "var(--accent)",
              color: "var(--bg)",
              fontSize: 12,
              fontWeight: 800,
              padding: "8px 24px",
              borderRadius: 8,
              border: "none",
              cursor: "pointer",
            }}
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: 1200, margin: "0 auto", padding: 20 }}>
      {/* Page Header */}
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 14,
          padding: 20,
          border: "1px solid rgba(105,210,148,0.08)",
          marginBottom: 16,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div>
          <div
            style={{
              fontSize: 12,
              fontWeight: 800,
              letterSpacing: 3,
              color: "var(--green)",
              textTransform: "uppercase",
            }}
          >
            PORTFOLIO ROLLUP
          </div>
          <div style={{ fontSize: 24, fontWeight: 800, margin: "4px 0" }}>
            Cross-Project Overview
          </div>
          <div style={{ fontSize: 12, color: "var(--muted)" }}>
            Generated {rollup ? new Date(rollup.generated_at).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" }) : ""}
            {rollup?.health && (
              <span style={{ marginLeft: 8 }}>
                <HealthBadge
                  score={rollup.health.score}
                  color={rollup.health.color}
                  label={rollup.health.label}
                />
              </span>
            )}
          </div>
        </div>

        {/* D-45: refresh button with spin animation */}
        <button
          onClick={() => fetchRollup(true)}
          disabled={refreshing}
          aria-label="Refresh portfolio data"
          style={{
            background: "var(--surface)",
            color: "var(--text)",
            fontSize: 8,
            fontWeight: 800,
            padding: "8px 16px",
            borderRadius: 8,
            border: "1px solid var(--border)",
            cursor: refreshing ? "wait" : "pointer",
            display: "flex",
            alignItems: "center",
            gap: 4,
          }}
        >
          <svg
            width={14}
            height={14}
            viewBox="0 0 14 14"
            fill="none"
            stroke="currentColor"
            strokeWidth={1.5}
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{
              animation: refreshing ? "spin 1s linear infinite" : "none",
            }}
          >
            <path d="M1.5 7a5.5 5.5 0 019.39-3.89M12.5 7a5.5 5.5 0 01-9.39 3.89" />
            <path d="M10.89 1v2.11H13M3.11 11v-2.11H1" />
          </svg>
          {refreshing ? "REFRESHING" : "REFRESH"}
        </button>
      </div>

      {/* Spin keyframes */}
      <style>{`@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }`}</style>

      {/* D-35/D-36: KPI Stat Cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
          gap: 8,
          marginBottom: 16,
        }}
      >
        <StatCard
          value={formatDollar(totalContractValue)}
          label="Total Contract Value"
          color="var(--accent)"
        />
        <StatCard
          value={formatDollar(totalBilled)}
          label="Total Billed"
          color="var(--cyan)"
        />
        <StatCard
          value={formatDollar(totalRemaining)}
          label="Remaining"
          color="var(--green)"
        />
        <StatCard
          value={formatDollar(changeOrderImpact)}
          label="Change Order Impact"
          color={changeOrderImpact > 0 ? "var(--gold)" : "var(--green)"}
        />
        <StatCard
          value={String(projectCount)}
          label="Projects"
          color="var(--accent)"
        />
        <StatCard
          value={`${avgHealth}%`}
          label="Avg Health Score"
          color={avgHealthColor}
        />
      </div>

      {/* D-46b: Period comparison toggle */}
      {comparePeriod && rollup && (
        <div
          style={{
            background: "rgba(74,196,204,0.08)",
            border: "1px solid rgba(74,196,204,0.2)",
            borderRadius: 8,
            padding: "8px 16px",
            marginBottom: 16,
            fontSize: 12,
            color: "var(--cyan)",
          }}
        >
          Period comparison enabled -- delta % changes are shown alongside current values when available.
        </div>
      )}

      {/* D-39: Filter bar */}
      <div
        style={{
          display: "flex",
          gap: 8,
          marginBottom: 16,
          flexWrap: "wrap",
          alignItems: "center",
        }}
      >
        {/* D-106: search */}
        <input
          type="text"
          placeholder="Search projects..."
          value={search}
          onChange={(e) => handleSearchChange(e.target.value)}
          aria-label="Search projects"
          style={{
            flex: 1,
            minWidth: 160,
            padding: "8px 12px",
            fontSize: 12,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            outline: "none",
          }}
        />

        {/* Status filter */}
        <select
          value={statusFilter}
          onChange={(e) => handleStatusChange(e.target.value)}
          aria-label="Filter by status"
          style={{
            padding: "8px 12px",
            fontSize: 12,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            outline: "none",
          }}
        >
          <option value="all">All Status</option>
          {VALID_STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </select>

        {/* Project type filter */}
        <input
          type="text"
          placeholder="Project type..."
          value={projectType}
          onChange={(e) => handleProjectTypeChange(e.target.value)}
          aria-label="Filter by project type"
          style={{
            width: 120,
            padding: "8px 12px",
            fontSize: 12,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            outline: "none",
          }}
        />

        {/* Client filter */}
        <input
          type="text"
          placeholder="Client..."
          value={clientFilter}
          onChange={(e) => handleClientChange(e.target.value)}
          aria-label="Filter by client"
          style={{
            width: 120,
            padding: "8px 12px",
            fontSize: 12,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            outline: "none",
          }}
        />

        {/* D-42: show completed toggle */}
        {statusFilter === "all" && (
          <label
            style={{
              display: "flex",
              alignItems: "center",
              gap: 4,
              fontSize: 12,
              color: "var(--muted)",
              cursor: "pointer",
              whiteSpace: "nowrap",
            }}
          >
            <input
              type="checkbox"
              checked={showCompleted}
              onChange={(e) => handleShowCompletedChange(e.target.checked)}
            />
            Show completed
          </label>
        )}

        {/* D-46b: compare period toggle */}
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 4,
            fontSize: 12,
            color: "var(--muted)",
            cursor: "pointer",
            whiteSpace: "nowrap",
          }}
        >
          <input
            type="checkbox"
            checked={comparePeriod}
            onChange={(e) => handleComparePeriodChange(e.target.checked)}
          />
          Compare periods
        </label>
      </div>

      {/* D-39/D-40/D-46: Sortable project table */}
      <PortfolioTable
        projects={filteredProjects}
        onSort={handleSort}
        sortKey={sortKey}
        sortDir={sortDir}
      />
    </div>
  );
}
