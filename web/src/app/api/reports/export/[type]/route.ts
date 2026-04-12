import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import {
  computeBudgetSection,
  computeScheduleSection,
  computeIssuesSection,
  computeTeamSection,
  computeSafetySection,
  computeHealthScore,
  clampBudgetPercent,
} from "@/lib/reports/aggregation";
import { generateSummaryCSV, generateDetailedCSV, generateQuickBooksCSV } from "@/lib/reports/csv-generator";
import { generateExcel } from "@/lib/reports/excel-generator";
import { generatePPTX } from "@/lib/reports/pptx-generator";
import type { ProjectReport } from "@/lib/reports/types";

// D-52: POST handler for report export
// D-114: JSON API export + QuickBooks-compatible CSV
// D-62b: Tighter rate limit on export (10 req/min)
// D-112: Audit logging
// D-56h: Webhook events placeholder for Zapier/Make integration

const VALID_TYPES = ["csv-summary", "csv-detailed", "csv-quickbooks", "excel", "json", "pptx"] as const;
type ExportType = (typeof VALID_TYPES)[number];

// ---------------------------------------------------------------------------
// D-62b: Custom rate limit for exports (tighter: 10 req/min)
// ---------------------------------------------------------------------------

const exportRateLimitStore = new Map<string, { count: number; resetAt: number }>();

function checkExportRateLimit(identifier: string): { allowed: boolean; remaining: number } {
  const now = Date.now();
  const windowMs = 60_000; // 1 minute
  const maxRequests = 10; // D-62b: 10 req/min for exports

  const entry = exportRateLimitStore.get(identifier);
  if (!entry || now > entry.resetAt) {
    exportRateLimitStore.set(identifier, { count: 1, resetAt: now + windowMs });
    // Prune stale entries
    if (exportRateLimitStore.size > 10_000) {
      for (const [key, val] of exportRateLimitStore) {
        if (now > val.resetAt) exportRateLimitStore.delete(key);
      }
    }
    return { allowed: true, remaining: maxRequests - 1 };
  }

  if (entry.count >= maxRequests) {
    return { allowed: false, remaining: 0 };
  }

  entry.count++;
  return { allowed: true, remaining: maxRequests - entry.count };
}

// ---------------------------------------------------------------------------
// Build a ProjectReport from Supabase data
// ---------------------------------------------------------------------------

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

async function buildProjectReport(
  supabase: SupabaseAny,
  projectId: string
): Promise<ProjectReport | null> {
  const { data: project, error: projectErr } = await supabase
    .from("cs_projects")
    .select("*")
    .eq("id", projectId)
    .single();

  if (projectErr || !project) return null;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const asArr = (d: unknown): any[] => (Array.isArray(d) ? d : []);

  const [contractsRes, tasksRes, rfisRes, cosRes, assignRes, activityRes, incidentsRes] =
    await Promise.all([
      supabase.from("cs_contracts").select("*").eq("project_id", projectId),
      supabase.from("cs_project_tasks").select("*").eq("project_id", projectId),
      supabase.from("cs_rfis").select("*").eq("project_id", projectId),
      supabase.from("cs_change_orders").select("*").eq("project_id", projectId),
      supabase.from("cs_team_assignments").select("*").eq("project_id", projectId),
      supabase.from("cs_activity_feed").select("*").eq("project_id", projectId).order("timestamp", { ascending: false }).limit(10),
      supabase.from("cs_safety_incidents").select("*").eq("project_id", projectId),
    ]);

  const budget = computeBudgetSection(
    { budget: (project as { budget?: string }).budget ?? "0" },
    asArr(contractsRes.data)
  );
  const schedule = computeScheduleSection(asArr(tasksRes.data));
  const issues = computeIssuesSection(asArr(rfisRes.data), asArr(cosRes.data));
  const team = computeTeamSection(asArr(assignRes.data), asArr(activityRes.data));
  const safety = computeSafetySection(asArr(incidentsRes.data));

  const budgetSpentPercent =
    budget.contractValue > 0 ? (budget.totalBilled / budget.contractValue) * 100 : 0;
  const delayedMilestonePercent =
    schedule.totalCount > 0 ? (schedule.delayedCount / schedule.totalCount) * 100 : 0;
  const health = computeHealthScore({
    budgetSpentPercent: clampBudgetPercent(budgetSpentPercent),
    delayedMilestonePercent,
    criticalOpenIssues: issues.criticalOpen,
  });

  const proj = project as { name?: string; client?: string };

  return {
    project_id: projectId,
    project_name: proj.name ?? "Unknown",
    client_name: proj.client ?? "",
    generated_at: new Date().toISOString(),
    health,
    budget,
    schedule,
    issues,
    team,
    safety,
    ai_insights: null,
    documents: { count: 0 },
    photos: { count: 0 },
    errors: [],
  };
}

// ---------------------------------------------------------------------------
// POST: Export report in specified format
// ---------------------------------------------------------------------------

export async function POST(
  req: Request,
  { params }: { params: Promise<{ type: string }> }
) {
  const { type: exportType } = await params;

  // Validate export type
  if (!VALID_TYPES.includes(exportType as ExportType)) {
    return NextResponse.json(
      { error: `Invalid export type. Must be one of: ${VALID_TYPES.join(", ")}` },
      { status: 400 }
    );
  }

  // General rate limit
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  // D-62b: Tighter export-specific rate limit
  const exportRl = checkExportRateLimit(ip);
  if (!exportRl.allowed) {
    return NextResponse.json(
      { error: "Export rate limit exceeded. Maximum 10 exports per minute." },
      { status: 429, headers: { "X-Export-RateLimit-Remaining": "0" } }
    );
  }

  // Auth
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  // Parse body for project_id
  let body: { project_id?: string; chart_images?: Record<string, string> };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const projectId = body.project_id;
  if (!projectId) {
    return NextResponse.json({ error: "project_id is required" }, { status: 400 });
  }

  // Sanitize project_id (T-19-11: strip non-alphanumeric except hyphens for UUID)
  const sanitizedId = projectId.replace(/[^a-zA-Z0-9-]/g, "");
  if (sanitizedId !== projectId || sanitizedId.length < 10) {
    return NextResponse.json({ error: "Invalid project_id format" }, { status: 400 });
  }

  // Build report data
  const report = await buildProjectReport(supabase, sanitizedId);
  if (!report) {
    return NextResponse.json({ error: "Project not found" }, { status: 404 });
  }

  // D-112: Log export to audit log
  await supabase.from("cs_report_audit_log").insert({
    user_id: user.id,
    action: "exported",
    report_type: "project",
    project_id: sanitizedId,
    metadata: { export_type: exportType },
  });

  // D-56h: Webhook event placeholder — emit when export completes
  // Future: POST to configured webhook URL with { event: "report.exported", ... }

  // Generate and return appropriate format
  try {
    switch (exportType as ExportType) {
      case "csv-summary": {
        const csv = generateSummaryCSV(report);
        return new Response(csv, {
          status: 200,
          headers: {
            "Content-Type": "text/csv; charset=utf-8",
            "Content-Disposition": `attachment; filename="${report.project_name}-summary.csv"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      case "csv-detailed": {
        const csv = generateDetailedCSV(report);
        return new Response(csv, {
          status: 200,
          headers: {
            "Content-Type": "text/csv; charset=utf-8",
            "Content-Disposition": `attachment; filename="${report.project_name}-detailed.csv"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      case "csv-quickbooks": {
        const csv = generateQuickBooksCSV(report);
        return new Response(csv, {
          status: 200,
          headers: {
            "Content-Type": "text/csv; charset=utf-8",
            "Content-Disposition": `attachment; filename="${report.project_name}-quickbooks.csv"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      case "excel": {
        const buf = generateExcel(report);
        return new Response(new Uint8Array(buf), {
          status: 200,
          headers: {
            "Content-Type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "Content-Disposition": `attachment; filename="${report.project_name}.xlsx"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      case "json": {
        // D-114: JSON API export for external tools
        return NextResponse.json(report, {
          status: 200,
          headers: {
            "Content-Disposition": `attachment; filename="${report.project_name}.json"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      case "pptx": {
        const chartImages = body.chart_images;
        const pptxBuf = await generatePPTX(report, chartImages);
        return new Response(new Uint8Array(pptxBuf), {
          status: 200,
          headers: {
            "Content-Type": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
            "Content-Disposition": `attachment; filename="${report.project_name}.pptx"`,
            "X-Export-RateLimit-Remaining": String(exportRl.remaining),
          },
        });
      }

      default:
        return NextResponse.json({ error: "Unsupported export type" }, { status: 400 });
    }
  } catch (err) {
    console.error(`[export/${exportType}] Generation error:`, err);
    return NextResponse.json(
      { error: "Failed to generate export" },
      { status: 500 }
    );
  }
}
