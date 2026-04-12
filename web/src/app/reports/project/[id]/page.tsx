"use client";

import { useEffect, useState, use } from "react";
import Link from "next/link";
import { SkeletonReport } from "../../components/SkeletonReport";
import { ReportHeader } from "../../components/ReportHeader";
import { BudgetSection } from "../../components/BudgetSection";
import { ScheduleSection } from "../../components/ScheduleSection";
import { SafetySection } from "../../components/SafetySection";
import { TeamSection } from "../../components/TeamSection";
import { AIInsightsSection } from "../../components/AIInsightsSection";
import type { ProjectReport } from "@/lib/reports/types";

// ---------- Types ----------

type ViewMode = "charts-data" | "charts-only";
type ActiveTab = "financial" | "schedule" | "safety" | "team" | "activity";

type ReportMeta = {
  generated_at: string;
  total_ms: number;
  section_timings: Record<string, number>;
  freshness: Record<string, string>;
  errors_count: number;
};

type ReportResponse = ProjectReport & { _meta: ReportMeta };

// ---------- Component ----------

export default function ProjectReportPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id: projectId } = use(params);

  const [report, setReport] = useState<ReportResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<ActiveTab>("financial");
  const [viewMode, setViewMode] = useState<ViewMode>("charts-data");

  useEffect(() => {
    let cancelled = false;

    async function loadReport() {
      setLoading(true);
      setError(null);
      try {
        const res = await fetch(`/api/reports/project/${projectId}`);
        if (!res.ok) {
          const body = await res.json().catch(() => ({ error: "Unknown error" }));
          throw new Error(body.error || `HTTP ${res.status}`);
        }
        const data: ReportResponse = await res.json();
        if (!cancelled) setReport(data);
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err.message : String(err));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    loadReport();
    return () => {
      cancelled = true;
    };
  }, [projectId]);

  // D-62: progressive loading -- show skeleton while loading
  if (loading) return <SkeletonReport />;

  // D-56: error card with retry
  if (error) {
    return (
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 14,
          padding: 32,
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: 12, color: "var(--red)", marginBottom: 12 }}>
          Report data could not be loaded. Check your connection and try again.
        </div>
        <div style={{ fontSize: 10, color: "var(--muted)", marginBottom: 16 }}>{error}</div>
        <button
          onClick={() => {
            setError(null);
            setLoading(true);
            fetch(`/api/reports/project/${projectId}`)
              .then((r) => r.json())
              .then((d) => setReport(d))
              .catch((e) => setError(e.message))
              .finally(() => setLoading(false));
          }}
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
    );
  }

  if (!report) return null;

  const meta = report._meta;
  const freshness = meta?.freshness ?? {};

  // D-26f: tab definitions
  const tabs: { key: ActiveTab; label: string }[] = [
    { key: "financial", label: "Financial" },
    { key: "schedule", label: "Schedule" },
    { key: "safety", label: "Safety" },
    { key: "team", label: "Team" },
    { key: "activity", label: "Activity" },
  ];

  // Render section errors inline
  const sectionErrors = report.errors ?? [];
  const hasSectionError = (section: string) =>
    sectionErrors.some((e) => e.section === section);

  const renderSectionError = (section: string) => {
    const err = sectionErrors.find((e) => e.section === section);
    if (!err) return null;
    return (
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 10,
          padding: 16,
          marginTop: 12,
          textAlign: "center",
        }}
      >
        <div style={{ fontSize: 12, color: "var(--red)", marginBottom: 8 }}>
          This section failed to load.
        </div>
        <button
          onClick={() => window.location.reload()}
          style={{
            background: "var(--surface)",
            color: "var(--text)",
            fontSize: 8,
            fontWeight: 800,
            padding: "6px 16px",
            borderRadius: 8,
            border: "1px solid var(--border)",
            cursor: "pointer",
          }}
        >
          Retry
        </button>
      </div>
    );
  };

  return (
    <>
      {/* Back navigation */}
      <Link
        href="/reports"
        style={{
          fontSize: 12,
          color: "var(--muted)",
          textDecoration: "none",
          display: "inline-block",
          marginBottom: 12,
        }}
      >
        &larr; Back to Reports
      </Link>

      {/* D-10: Report header */}
      <ReportHeader
        projectName={report.project_name}
        clientName={report.client_name}
        generatedAt={report.generated_at}
        health={report.health}
      />

      {/* Export button group + view mode toggle per UI-SPEC */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 16,
          flexWrap: "wrap",
          gap: 8,
        }}
      >
        {/* UI-SPEC Export Button Group */}
        <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
          <button
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
            Export PDF
          </button>
          <button
            style={{
              background: "var(--surface)",
              color: "var(--text)",
              fontSize: 8,
              fontWeight: 800,
              padding: "8px 16px",
              borderRadius: 8,
              border: "1px solid var(--border)",
              cursor: "pointer",
            }}
          >
            Export CSV
          </button>
          <button
            style={{
              background: "var(--surface)",
              color: "var(--text)",
              fontSize: 8,
              fontWeight: 800,
              padding: "8px 16px",
              borderRadius: 8,
              border: "1px solid var(--border)",
              cursor: "pointer",
            }}
          >
            Share Report
          </button>
        </div>

        {/* D-26g: view mode toggle */}
        <div style={{ display: "flex", gap: 0, borderRadius: 6, overflow: "hidden" }}>
          <button
            onClick={() => setViewMode("charts-data")}
            style={{
              padding: "6px 12px",
              fontSize: 8,
              fontWeight: 800,
              border: "none",
              cursor: "pointer",
              background: viewMode === "charts-data" ? "var(--accent)" : "var(--surface)",
              color: viewMode === "charts-data" ? "var(--bg)" : "var(--muted)",
            }}
          >
            Charts + Data
          </button>
          <button
            onClick={() => setViewMode("charts-only")}
            style={{
              padding: "6px 12px",
              fontSize: 8,
              fontWeight: 800,
              border: "none",
              cursor: "pointer",
              background: viewMode === "charts-only" ? "var(--accent)" : "var(--surface)",
              color: viewMode === "charts-only" ? "var(--bg)" : "var(--muted)",
            }}
          >
            Charts Only
          </button>
        </div>
      </div>

      {/* D-26f: tabbed sections */}
      <div
        style={{
          display: "flex",
          gap: 0,
          borderRadius: 8,
          overflow: "hidden",
          marginBottom: 16,
        }}
      >
        {tabs.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            style={{
              flex: 1,
              textAlign: "center",
              padding: "8px 0",
              fontSize: 8,
              fontWeight: 800,
              letterSpacing: 1,
              textTransform: "uppercase",
              border: "none",
              cursor: "pointer",
              background: activeTab === tab.key ? "var(--accent)" : "var(--surface)",
              color: activeTab === tab.key ? "var(--bg)" : "var(--muted)",
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* D-08: always show all sections, empty ones show "None recorded" */}
      {/* D-26h: independent loading per section with prioritized order */}

      {activeTab === "financial" && (
        hasSectionError("budget")
          ? renderSectionError("budget")
          : <BudgetSection
              data={report.budget}
              freshness={freshness.budget}
              mini={viewMode === "charts-only"}
            />
      )}

      {activeTab === "schedule" && (
        hasSectionError("schedule")
          ? renderSectionError("schedule")
          : <ScheduleSection data={report.schedule} freshness={freshness.schedule} />
      )}

      {activeTab === "safety" && (
        hasSectionError("safety")
          ? renderSectionError("safety")
          : <SafetySection data={report.safety} freshness={freshness.safety} />
      )}

      {activeTab === "team" && (
        hasSectionError("team")
          ? renderSectionError("team")
          : <TeamSection
              data={report.team}
              freshness={freshness.team}
              documentCount={report.documents?.count}
              photoCount={report.photos?.count}
            />
      )}

      {activeTab === "activity" && (
        <AIInsightsSection data={report.ai_insights} />
      )}

      {/* D-56c: debug info for developers */}
      {meta && (
        <div
          style={{
            marginTop: 32,
            padding: 12,
            background: "var(--panel)",
            borderRadius: 8,
            fontSize: 8,
            color: "var(--muted)",
          }}
        >
          Report generated in {meta.total_ms}ms
          {meta.errors_count > 0 && (
            <span style={{ color: "var(--gold)", marginLeft: 8 }}>
              ({meta.errors_count} section{meta.errors_count > 1 ? "s" : ""} failed)
            </span>
          )}
        </div>
      )}
    </>
  );
}
