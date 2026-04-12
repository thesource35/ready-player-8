"use client";

import { useRouter } from "next/navigation";
import { useRef, useCallback } from "react";
import { List } from "react-window";
import { HealthBadge } from "./HealthBadge";
import type { ProjectSummary } from "@/lib/reports/types";

// ---------- Types ----------

type SortDir = "asc" | "desc";

type PortfolioTableProps = {
  projects: ProjectSummary[];
  onSort: (key: string) => void;
  sortKey: string;
  sortDir: SortDir;
};

// ---------- Constants ----------

/** D-46: activate virtual scrolling at 25+ projects */
const VIRTUAL_THRESHOLD = 25;
const ROW_HEIGHT = 52;
const VIRTUAL_MAX_HEIGHT = 520; // ~10 visible rows

const COLUMNS: { key: string; label: string; width: string; align?: "right" }[] = [
  { key: "name", label: "Project Name", width: "20%" },
  { key: "health", label: "Health", width: "10%" },
  { key: "contractValue", label: "Contract Value", width: "14%", align: "right" },
  { key: "billed", label: "Billed", width: "12%", align: "right" },
  { key: "percentComplete", label: "% Complete", width: "10%", align: "right" },
  { key: "openIssues", label: "Open Issues", width: "10%", align: "right" },
  { key: "safetyIncidents", label: "Safety", width: "10%", align: "right" },
  { key: "status", label: "Status", width: "14%" },
];

// ---------- Helpers ----------

const formatDollar = (value: number): string => {
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
  return `$${value.toLocaleString()}`;
};

const statusColor = (s: string): string =>
  s === "Completed"
    ? "var(--green)"
    : s === "Active"
    ? "var(--cyan)"
    : s === "Delayed"
    ? "var(--red)"
    : "var(--muted)";

// ---------- Row Component ----------

function TableRow({
  project,
  onClick,
}: {
  project: ProjectSummary;
  onClick: () => void;
}) {
  const rowStyle: React.CSSProperties = {
    display: "flex",
    alignItems: "center",
    padding: "0 16px",
    height: ROW_HEIGHT,
    borderBottom: "1px solid rgba(51,84,94,0.3)",
    cursor: "pointer",
    fontSize: 12,
    fontWeight: 400,
    color: "var(--text)",
  };

  return (
    <div
      role="row"
      style={rowStyle}
      onClick={onClick}
      onMouseEnter={(e) => {
        (e.currentTarget as HTMLDivElement).style.background = "rgba(242,158,61,0.04)";
      }}
      onMouseLeave={(e) => {
        (e.currentTarget as HTMLDivElement).style.background = "transparent";
      }}
    >
      {/* Project Name */}
      <div style={{ width: "20%", fontWeight: 800, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
        {project.name}
      </div>
      {/* Health */}
      <div style={{ width: "10%" }}>
        <HealthBadge score={project.health.score} color={project.health.color} label={project.health.label} />
      </div>
      {/* Contract Value */}
      <div style={{ width: "14%", textAlign: "right" }}>{formatDollar(project.contractValue)}</div>
      {/* Billed */}
      <div style={{ width: "12%", textAlign: "right" }}>{formatDollar(project.billed)}</div>
      {/* % Complete */}
      <div style={{ width: "10%", textAlign: "right" }}>{project.percentComplete}%</div>
      {/* Open Issues */}
      <div style={{ width: "10%", textAlign: "right" }}>{project.openIssues}</div>
      {/* Safety */}
      <div style={{ width: "10%", textAlign: "right" }}>{project.safetyIncidents}</div>
      {/* Status + Feature Coverage D-16c */}
      <div style={{ width: "14%", display: "flex", gap: 6, alignItems: "center" }}>
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
        {/* D-16c: feature coverage badge */}
        <span
          style={{
            fontSize: 7,
            fontWeight: 800,
            color: "var(--muted)",
            background: "rgba(51,84,94,0.2)",
            padding: "2px 5px",
            borderRadius: 3,
          }}
          title="Feature coverage"
        >
          {project.featureCoverage.active}/{project.featureCoverage.total}
        </span>
      </div>
    </div>
  );
}

// ---------- Main Component ----------

/** D-39: sortable portfolio table, D-40: row click navigates, D-46: virtual scrolling at 25+ */
export function PortfolioTable({ projects, onSort, sortKey, sortDir }: PortfolioTableProps) {
  const router = useRouter();
  const useVirtual = projects.length >= VIRTUAL_THRESHOLD;

  const handleRowClick = useCallback(
    (id: string) => {
      router.push(`/reports/project/${id}`);
    },
    [router]
  );

  // D-39: sort indicator arrow
  const sortIndicator = (key: string) => {
    if (sortKey !== key) return null;
    return (
      <span style={{ fontSize: 8, color: "var(--accent)", marginLeft: 4 }}>
        {sortDir === "asc" ? "\u25B2" : "\u25BC"}
      </span>
    );
  };

  // react-window v2 rowComponent for virtual scrolling
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const VirtualRowComponent = useCallback((props: any) => {
    const { rowIndex, style } = props;
    const project = projects[rowIndex];
    if (!project) return null;
    return (
      <div style={style}>
        <TableRow project={project} onClick={() => handleRowClick(project.id)} />
      </div>
    );
  }, [projects, handleRowClick]);

  return (
    <div
      role="table"
      aria-label="Portfolio project table"
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        overflow: "hidden",
      }}
    >
      {/* Header */}
      <div
        role="row"
        style={{
          display: "flex",
          alignItems: "center",
          padding: "8px 16px",
          background: "var(--panel)",
        }}
      >
        {COLUMNS.map((col) => (
          <div
            key={col.key}
            role="columnheader"
            onClick={() => onSort(col.key)}
            style={{
              width: col.width,
              fontSize: 8,
              fontWeight: 800,
              color: "var(--muted)",
              letterSpacing: 1,
              textTransform: "uppercase",
              cursor: "pointer",
              textAlign: col.align || "left",
              userSelect: "none",
            }}
          >
            {col.label}
            {sortIndicator(col.key)}
          </div>
        ))}
      </div>

      {/* Body */}
      {projects.length === 0 ? (
        <div style={{ padding: 24, textAlign: "center", fontSize: 12, color: "var(--muted)" }}>
          No projects match your filters.
        </div>
      ) : useVirtual ? (
        <div style={{ height: Math.min(VIRTUAL_MAX_HEIGHT, projects.length * ROW_HEIGHT) }}>
          <List
            rowCount={projects.length}
            rowHeight={ROW_HEIGHT}
            rowComponent={VirtualRowComponent}
            rowProps={{}}
            style={{ height: "100%", width: "100%" }}
          />
        </div>
      ) : (
        projects.map((project) => (
          <TableRow
            key={project.id}
            project={project}
            onClick={() => handleRowClick(project.id)}
          />
        ))
      )}
    </div>
  );
}
