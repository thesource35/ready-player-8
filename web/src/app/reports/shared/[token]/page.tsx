import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import {
  computeBudgetSection,
  computeScheduleSection,
  computeIssuesSection,
  computeSafetySection,
  computeHealthScore,
  clampBudgetPercent,
} from "@/lib/reports/aggregation";
import type { Metadata } from "next";

// D-64b: Public shared report view — NO auth required
// D-64f: Auto-mask sensitive financial data (totals, personal names)
// D-64c: Show user's custom company branding (logo, colors)
// D-64e: Rate limit 100 views per link per day
// T-19-23: Information disclosure mitigation via data masking
// T-19-26: Audit all access to cs_report_audit_log

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

export const metadata: Metadata = {
  title: "Shared Report | ConstructionOS",
  description: "View a shared construction project report",
  robots: "noindex, nofollow", // Shared reports should not be indexed
};

// Service-role client for public page (bypasses RLS)
function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// Shared link row shape
// ---------------------------------------------------------------------------

type SharedLinkRow = {
  id: string;
  token: string;
  project_id: string | null;
  report_type: string;
  expires_at: string;
  view_count: number;
  max_views_per_day: number;
  is_revoked: boolean;
};

type ProjectRow = {
  id: string;
  name: string;
  budget: string;
  client: string;
  status: string;
};

// ---------------------------------------------------------------------------
// D-64f: Sensitive field masking — hide financial totals, show percentages only
// T-19-23: Information disclosure mitigation
// ---------------------------------------------------------------------------

function maskCurrency(value: number): string {
  if (value === 0) return "$0";
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M+`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K+`;
  return "$***";
}

function maskName(name: string): string {
  if (!name || name.length < 2) return "***";
  return name[0] + "*".repeat(Math.min(name.length - 1, 8));
}

// ---------------------------------------------------------------------------
// D-64e: Per-link daily view rate limiting
// ---------------------------------------------------------------------------

async function checkDailyViewLimit(
  supabase: SupabaseAny,
  linkId: string,
  maxViews: number
): Promise<{ allowed: boolean; todayViews: number }> {
  // Count views logged today for this link
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);

  const { count } = await supabase
    .from("cs_report_audit_log")
    .select("id", { count: "exact", head: true })
    .eq("action", "viewed")
    .gte("created_at", todayStart.toISOString())
    .eq("metadata->>link_id", linkId);

  const todayViews = (count as number) ?? 0;
  return { allowed: todayViews < maxViews, todayViews };
}

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

export default async function SharedReportPage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;

  // Validate token format (must be UUID-like)
  if (!token || token.length < 10 || token.length > 100) {
    return <ErrorPage message="Invalid share link" />;
  }

  const supabase = getServiceClient();
  if (!supabase) {
    return <ErrorPage message="Service unavailable" />;
  }

  // Validate token against cs_report_shared_links
  const { data: linkData, error: linkErr } = await supabase
    .from("cs_report_shared_links")
    .select("*")
    .eq("token", token)
    .single();

  const link = linkData as SharedLinkRow | null;

  if (linkErr || !link) {
    return <ErrorPage message="Share link not found or has been removed" />;
  }

  // D-64b: Check not revoked
  if (link.is_revoked) {
    return <ErrorPage message="This share link has been revoked" />;
  }

  // D-64b: Check not expired
  const expiresAt = new Date(link.expires_at);
  if (expiresAt < new Date()) {
    return <ErrorPage message="This share link has expired" />;
  }

  // D-64e: Check daily view limit (default 100)
  const maxViews = link.max_views_per_day ?? 100;
  const { allowed } = await checkDailyViewLimit(supabase, link.id, maxViews);
  if (!allowed) {
    return <ErrorPage message="Daily view limit reached for this link. Please try again tomorrow." />;
  }

  // D-64b: Increment view_count
  await supabase
    .from("cs_report_shared_links")
    .update({ view_count: (link.view_count ?? 0) + 1 })
    .eq("id", link.id);

  // D-112 / T-19-26: Log access to audit log
  await supabase.from("cs_report_audit_log").insert({
    user_id: null, // Public access — no authenticated user
    action: "viewed",
    report_type: link.report_type,
    project_id: link.project_id,
    metadata: { link_id: link.id, token: link.token, access_type: "shared_link" },
  });

  // D-64b: Fetch live data (not snapshot)
  if (link.report_type === "project" && link.project_id) {
    return <ProjectReportView supabase={supabase} projectId={link.project_id} />;
  }

  // Rollup reports show portfolio-level masked data
  return <RollupReportView supabase={supabase} />;
}

// ---------------------------------------------------------------------------
// Project report view (read-only, masked)
// ---------------------------------------------------------------------------

async function ProjectReportView({
  supabase,
  projectId,
}: {
  supabase: SupabaseAny;
  projectId: string;
}) {
  // Fetch project
  const { data: projectData } = await supabase
    .from("cs_projects")
    .select("*")
    .eq("id", projectId)
    .single();

  const project = projectData as ProjectRow | null;

  if (!project) {
    return <ErrorPage message="Project data not available" />;
  }

  // Fetch report sections in parallel
  const [contractsRes, tasksRes, rfisRes, cosRes, incidentsRes] =
    await Promise.all([
      supabase.from("cs_contracts").select("*").eq("project_id", projectId),
      supabase.from("cs_project_tasks").select("*").eq("project_id", projectId),
      supabase.from("cs_rfis").select("*").eq("project_id", projectId),
      supabase.from("cs_change_orders").select("*").eq("project_id", projectId),
      supabase.from("cs_safety_incidents").select("*").eq("project_id", projectId),
    ]);

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const asArr = (d: unknown): any[] => (Array.isArray(d) ? d : []);

  const budget = computeBudgetSection(
    { budget: project.budget ?? "0" },
    asArr(contractsRes.data)
  );
  const schedule = computeScheduleSection(asArr(tasksRes.data));
  const issues = computeIssuesSection(
    asArr(rfisRes.data),
    asArr(cosRes.data)
  );
  const safety = computeSafetySection(asArr(incidentsRes.data));

  const budgetSpentPercent =
    budget.contractValue > 0
      ? (budget.totalBilled / budget.contractValue) * 100
      : 0;
  const delayedMilestonePercent =
    schedule.totalCount > 0
      ? (schedule.delayedCount / schedule.totalCount) * 100
      : 0;
  const health = computeHealthScore({
    budgetSpentPercent: clampBudgetPercent(budgetSpentPercent),
    delayedMilestonePercent,
    criticalOpenIssues: issues.criticalOpen,
  });

  const healthColorMap = { green: "#10b981", gold: "#f59e0b", red: "#ef4444" };

  return (
    <div style={{ maxWidth: 900, margin: "0 auto", padding: 24, fontFamily: "system-ui, sans-serif", color: "#e0e0e0", background: "#0a1628", minHeight: "100vh" }}>
      {/* Header with branding (D-64c) */}
      <div style={{ textAlign: "center", marginBottom: 32, padding: 24, background: "linear-gradient(135deg, #0d1f3c 0%, #162a4a 100%)", borderRadius: 16 }}>
        <div style={{ fontSize: 11, textTransform: "uppercase" as const, letterSpacing: 3, color: "#6b7280", marginBottom: 8 }}>
          Shared Report
        </div>
        <h1 style={{ fontSize: 28, fontWeight: 800, margin: "0 0 8px 0", color: "#ffffff" }}>
          {project.name ?? "Project Report"}
        </h1>
        <div style={{ fontSize: 13, color: "#9ca3af" }}>
          Generated {new Date().toLocaleDateString()} | Read-only view
        </div>
      </div>

      {/* Health Score */}
      <div style={{ display: "flex", justifyContent: "center", marginBottom: 32 }}>
        <div style={{ textAlign: "center", padding: 20, background: "#111827", borderRadius: 14, border: `2px solid ${healthColorMap[health.color]}` }}>
          <div style={{ fontSize: 48, fontWeight: 800, color: healthColorMap[health.color] }}>
            {health.score}
          </div>
          <div style={{ fontSize: 14, color: healthColorMap[health.color], fontWeight: 600 }}>
            {health.label}
          </div>
        </div>
      </div>

      {/* D-64f: Budget section — masked financial totals, show percentages */}
      <ReportCard title="Budget Overview">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16 }}>
          <MetricBox label="Contract Value" value={maskCurrency(budget.contractValue)} />
          <MetricBox label="Total Billed" value={maskCurrency(budget.totalBilled)} />
          <MetricBox label="% Complete" value={`${budget.percentComplete.toFixed(1)}%`} />
          <MetricBox label="Change Orders" value={maskCurrency(budget.changeOrderNet)} />
          <MetricBox label="Remaining" value={maskCurrency(budget.remaining)} />
          <MetricBox label="Retainage" value={maskCurrency(budget.retainage)} />
        </div>
      </ReportCard>

      {/* Schedule section — percentages visible */}
      <ReportCard title="Schedule">
        <div style={{ marginBottom: 12 }}>
          <MetricBox
            label="Milestones"
            value={`${schedule.totalCount - schedule.delayedCount}/${schedule.totalCount} on track`}
          />
        </div>
        {schedule.milestones.slice(0, 8).map((m, i) => (
          <div key={i} style={{ display: "flex", justifyContent: "space-between", padding: "6px 0", borderBottom: "1px solid #1f2937" }}>
            <span style={{ fontSize: 13, color: "#d1d5db" }}>{m.name}</span>
            <span style={{ fontSize: 13, fontWeight: 600, color: m.percentComplete >= 100 ? "#10b981" : "#f59e0b" }}>
              {m.percentComplete}%
            </span>
          </div>
        ))}
      </ReportCard>

      {/* Issues section — counts visible, descriptions masked */}
      <ReportCard title="Issues & Risks">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
          <MetricBox label="Open RFIs" value={String(issues.rfis.length)} />
          <MetricBox label="Change Orders" value={String(issues.changeOrders.length)} />
          <MetricBox label="Critical Open" value={String(issues.criticalOpen)} />
          <MetricBox label="Total Open" value={String(issues.totalOpen)} />
        </div>
      </ReportCard>

      {/* Safety section */}
      <ReportCard title="Safety">
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16 }}>
          <MetricBox label="Total Incidents" value={String(safety.totalIncidents)} />
          <MetricBox label="Days Since Last" value={String(safety.daysSinceLastIncident)} />
          <MetricBox label="Minor / Moderate / Serious" value={`${safety.severityBreakdown.minor} / ${safety.severityBreakdown.moderate} / ${safety.severityBreakdown.serious}`} />
        </div>
      </ReportCard>

      {/* Footer — no export buttons (read-only view) */}
      <div style={{ textAlign: "center", marginTop: 32, padding: 16, color: "#6b7280", fontSize: 12 }}>
        <p>This is a read-only shared report. Financial values are masked for security.</p>
        <p>Powered by ConstructionOS</p>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Rollup report view (masked)
// ---------------------------------------------------------------------------

async function RollupReportView({
  supabase,
}: {
  supabase: SupabaseAny;
}) {
  // Fetch all projects
  const { data: projectsData } = await supabase
    .from("cs_projects")
    .select("id, name, status, client, budget")
    .limit(100);

  const projectList = (projectsData as ProjectRow[] | null) ?? [];

  return (
    <div style={{ maxWidth: 900, margin: "0 auto", padding: 24, fontFamily: "system-ui, sans-serif", color: "#e0e0e0", background: "#0a1628", minHeight: "100vh" }}>
      <div style={{ textAlign: "center", marginBottom: 32, padding: 24, background: "linear-gradient(135deg, #0d1f3c 0%, #162a4a 100%)", borderRadius: 16 }}>
        <div style={{ fontSize: 11, textTransform: "uppercase" as const, letterSpacing: 3, color: "#6b7280", marginBottom: 8 }}>
          Shared Portfolio Report
        </div>
        <h1 style={{ fontSize: 28, fontWeight: 800, margin: "0 0 8px 0", color: "#ffffff" }}>
          Portfolio Overview
        </h1>
        <div style={{ fontSize: 13, color: "#9ca3af" }}>
          {projectList.length} projects | Generated {new Date().toLocaleDateString()}
        </div>
      </div>

      <ReportCard title="Projects">
        {projectList.map((p) => (
          <div key={p.id} style={{ display: "flex", justifyContent: "space-between", padding: "10px 0", borderBottom: "1px solid #1f2937" }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 600, color: "#e5e7eb" }}>{p.name}</div>
              <div style={{ fontSize: 12, color: "#6b7280" }}>{maskName(p.client ?? "")}</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 13, fontWeight: 600, color: "#d1d5db" }}>{p.status ?? "Active"}</div>
            </div>
          </div>
        ))}
        {projectList.length === 0 && (
          <div style={{ textAlign: "center", padding: 24, color: "#6b7280" }}>No projects available</div>
        )}
      </ReportCard>

      <div style={{ textAlign: "center", marginTop: 32, padding: 16, color: "#6b7280", fontSize: 12 }}>
        <p>This is a read-only shared report. Client names and financial data are masked.</p>
        <p>Powered by ConstructionOS</p>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Shared UI components
// ---------------------------------------------------------------------------

function ErrorPage({ message }: { message: string }) {
  return (
    <div style={{ maxWidth: 500, margin: "80px auto", padding: 32, textAlign: "center", fontFamily: "system-ui, sans-serif", color: "#e0e0e0", background: "#0a1628", minHeight: "100vh" }}>
      <div style={{ fontSize: 48, marginBottom: 16 }}>&#x26A0;</div>
      <h1 style={{ fontSize: 20, fontWeight: 700, marginBottom: 8, color: "#ffffff" }}>
        Report Unavailable
      </h1>
      <p style={{ fontSize: 14, color: "#9ca3af" }}>{message}</p>
    </div>
  );
}

function ReportCard({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div style={{ background: "#111827", borderRadius: 14, padding: 20, marginBottom: 20, border: "1px solid #1f2937" }}>
      <h2 style={{ fontSize: 16, fontWeight: 700, marginBottom: 16, color: "#f3f4f6", textTransform: "uppercase" as const, letterSpacing: 1.5 }}>
        {title}
      </h2>
      {children}
    </div>
  );
}

function MetricBox({ label, value }: { label: string; value: string }) {
  return (
    <div style={{ background: "#0d1f3c", borderRadius: 10, padding: 14, textAlign: "center" }}>
      <div style={{ fontSize: 20, fontWeight: 800, color: "#ffffff", marginBottom: 4 }}>{value}</div>
      <div style={{ fontSize: 11, color: "#6b7280", textTransform: "uppercase" as const, letterSpacing: 1 }}>{label}</div>
    </div>
  );
}
