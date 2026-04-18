"use client";

import { useEffect, useState, useMemo } from "react";
import Link from "next/link";
import { HealthBadge } from "./components/HealthBadge";
import { StatCard } from "./components/StatCard";
import { SkeletonReport } from "./components/SkeletonReport";
import type { HealthScore } from "@/lib/reports/types";
import { HEALTH_THRESHOLDS } from "@/lib/reports/constants";
import { CertComplianceWidget } from "./components/CertComplianceWidget";

// ---------- Types ----------

type ProjectRow = {
  id: string;
  name: string;
  status: string;
  client: string;
  budget: string;
  health?: HealthScore;
};

// ---------- Demo Data (D-66c) ----------

const DEMO_PROJECTS: ProjectRow[] = [
  {
    id: "demo-1",
    name: "Riverside Lofts",
    status: "Active",
    client: "Metro Development Corp",
    budget: "$2,400,000",
    health: { score: 87, color: "green", label: "On Track" },
  },
  {
    id: "demo-2",
    name: "Harbor Crossing Bridge",
    status: "Active",
    client: "City of Portland",
    budget: "$8,750,000",
    health: { score: 64, color: "gold", label: "At Risk" },
  },
  {
    id: "demo-3",
    name: "Pine Ridge Phase 2",
    status: "Completed",
    client: "Evergreen Homes",
    budget: "$1,100,000",
    health: { score: 92, color: "green", label: "On Track" },
  },
  {
    id: "demo-4",
    name: "Downtown Medical Center",
    status: "Active",
    client: "HealthBridge Partners",
    budget: "$12,300,000",
    health: { score: 45, color: "red", label: "Critical" },
  },
];

// ---------- Helpers ----------

function parseBudget(budget: string): number {
  const cleaned = budget.replace(/[^0-9.]/g, "");
  return parseFloat(cleaned) || 0;
}

function computeSimpleHealth(status: string): HealthScore {
  if (status === "Completed") return { score: 100, color: "green", label: "On Track" };
  if (status === "Delayed") return { score: 45, color: "red", label: "Critical" };
  return { score: 75, color: "gold", label: "At Risk" };
}

const statusColor = (s: string) =>
  s === "Completed"
    ? "var(--green)"
    : s === "Active"
    ? "var(--cyan)"
    : s === "Delayed"
    ? "var(--red)"
    : "var(--muted)";

// ---------- Component ----------

export default function ReportsPage() {
  const [projects, setProjects] = useState<ProjectRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [isDemo, setIsDemo] = useState(false);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [sortBy, setSortBy] = useState<"name" | "budget" | "health">("name");
  const [showCompleted, setShowCompleted] = useState(false);

  useEffect(() => {
    let cancelled = false;

    async function loadProjects() {
      try {
        const res = await fetch("/api/reports/rollup");
        if (!res.ok) throw new Error("Failed to load");
        const data = await res.json();
        if (!cancelled && data.projects && data.projects.length > 0) {
          const mapped: ProjectRow[] = data.projects.map(
            (p: { id: string; name: string; status: string; contractValue: number; health: HealthScore }) => ({
              id: p.id,
              name: p.name,
              status: p.status,
              client: "",
              budget: `$${p.contractValue.toLocaleString()}`,
              health: p.health,
            })
          );
          setProjects(mapped);
          setIsDemo(false);
        } else {
          throw new Error("No projects");
        }
      } catch {
        // D-66c: fall back to demo data
        if (!cancelled) {
          setProjects(DEMO_PROJECTS);
          setIsDemo(true);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadProjects();
    return () => {
      cancelled = true;
    };
  }, []);

  // D-106: filter + sort
  const filtered = useMemo(() => {
    let list = projects;

    // Status filter
    if (statusFilter !== "all") {
      list = list.filter((p) => p.status.toLowerCase() === statusFilter.toLowerCase());
    } else if (!showCompleted) {
      // D-42: active by default, toggle for completed
      list = list.filter((p) => p.status !== "Completed");
    }

    // Search
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.client.toLowerCase().includes(q)
      );
    }

    // Sort
    list = [...list].sort((a, b) => {
      if (sortBy === "name") return a.name.localeCompare(b.name);
      if (sortBy === "budget") return parseBudget(b.budget) - parseBudget(a.budget);
      if (sortBy === "health") return (b.health?.score ?? 0) - (a.health?.score ?? 0);
      return 0;
    });

    return list;
  }, [projects, search, statusFilter, sortBy, showCompleted]);

  // Portfolio KPIs
  const totalProjects = projects.length;
  const avgHealth =
    totalProjects > 0
      ? Math.round(
          projects.reduce((sum, p) => sum + (p.health?.score ?? 0), 0) / totalProjects
        )
      : 0;
  const totalValue = projects.reduce((sum, p) => sum + parseBudget(p.budget), 0);
  const avgHealthColor =
    avgHealth >= HEALTH_THRESHOLDS.green.min
      ? "var(--green)"
      : avgHealth >= HEALTH_THRESHOLDS.gold.min
      ? "var(--gold)"
      : "var(--red)";

  if (loading) return <SkeletonReport />;

  return (
    <>
      {/* D-66c: demo banner */}
      {isDemo && (
        <div
          style={{
            background: "rgba(242,158,61,0.1)",
            border: "1px solid rgba(242,158,61,0.3)",
            borderRadius: 8,
            padding: "8px 16px",
            marginBottom: 16,
            fontSize: 12,
            color: "var(--accent)",
          }}
        >
          This is a demo report with sample data. Create a project to see your own data.
        </div>
      )}

      {/* D-05: portfolio KPI stat cards */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
          gap: 8,
          marginBottom: 16,
        }}
      >
        <StatCard value={String(totalProjects)} label="Total Projects" color="var(--accent)" />
        <StatCard value={`${avgHealth}%`} label="Avg Health" color={avgHealthColor} />
        <StatCard
          value={totalValue >= 1_000_000 ? `$${(totalValue / 1_000_000).toFixed(1)}M` : `$${Math.round(totalValue / 1000)}K`}
          label="Total Value"
          color="var(--cyan)"
        />
      </div>

      {/* D-36: cert compliance widget */}
      <CertComplianceWidget />

      {/* D-106: filter bar */}
      <div
        style={{
          display: "flex",
          gap: 8,
          marginBottom: 16,
          flexWrap: "wrap",
          alignItems: "center",
        }}
      >
        <input
          type="text"
          placeholder="Search projects..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
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
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
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
          <option value="active">Active</option>
          <option value="completed">Completed</option>
          <option value="delayed">Delayed</option>
        </select>
        <select
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value as "name" | "budget" | "health")}
          aria-label="Sort by"
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
          <option value="name">Sort: Name</option>
          <option value="budget">Sort: Budget</option>
          <option value="health">Sort: Health</option>
        </select>
        {statusFilter === "all" && (
          <label
            style={{
              display: "flex",
              alignItems: "center",
              gap: 4,
              fontSize: 12,
              color: "var(--muted)",
              cursor: "pointer",
            }}
          >
            <input
              type="checkbox"
              checked={showCompleted}
              onChange={(e) => setShowCompleted(e.target.checked)}
            />
            Show completed
          </label>
        )}
      </div>

      {/* Project list */}
      {filtered.length === 0 ? (
        <div
          style={{
            textAlign: "center",
            padding: 32,
            color: "var(--muted)",
            fontSize: 12,
          }}
        >
          No projects match your filters.
        </div>
      ) : (
        filtered.map((project) => {
          const health = project.health ?? computeSimpleHealth(project.status);
          return (
            <Link
              key={project.id}
              href={`/reports/project/${project.id}`}
              style={{ textDecoration: "none", color: "inherit" }}
            >
              <div
                style={{
                  background: "var(--surface)",
                  borderRadius: 10,
                  padding: 12,
                  marginBottom: 8,
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  cursor: "pointer",
                }}
              >
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  <HealthBadge
                    score={health.score}
                    color={health.color}
                    label={health.label}
                  />
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 800 }}>{project.name}</div>
                    {project.client && (
                      <div style={{ fontSize: 10, color: "var(--muted)" }}>
                        {project.client}
                      </div>
                    )}
                  </div>
                </div>
                <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontSize: 12, fontWeight: 800, color: "var(--accent)" }}>
                      {project.budget}
                    </div>
                  </div>
                  <span
                    style={{
                      fontSize: 8,
                      fontWeight: 800,
                      color: statusColor(project.status),
                      background: `${statusColor(project.status)}15`,
                      padding: "3px 8px",
                      borderRadius: 4,
                      textTransform: "uppercase",
                    }}
                  >
                    {project.status}
                  </span>
                </div>
              </div>
            </Link>
          );
        })
      )}
    </>
  );
}
