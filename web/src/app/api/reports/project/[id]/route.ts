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
import type { ProjectReport, SectionError } from "@/lib/reports/types";

// D-51: GET handler returning full ProjectReport
// D-53: single API call returns full report (all sections)
// D-04: computed on-the-fly, no persistence

const SECTION_TIMEOUT_MS = 10_000;

/** Wrap a promise with a timeout. Rejects with REPORT_SECTION_TIMEOUT on expiry. */
function withTimeout<T>(promise: Promise<T>, section: string): Promise<T> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject({
        code: "REPORT_SECTION_TIMEOUT",
        message: `Section "${section}" timed out after ${SECTION_TIMEOUT_MS}ms`,
        section,
        retryable: true,
      } satisfies SectionError & { section: string });
    }, SECTION_TIMEOUT_MS);

    promise
      .then((val) => {
        clearTimeout(timer);
        resolve(val);
      })
      .catch((err) => {
        clearTimeout(timer);
        reject(err);
      });
  });
}

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: projectId } = await params;

  // Rate limiting
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  // Auth: getAuthenticatedClient(), return 401 if not authenticated (T-19-08)
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  const startTime = Date.now();
  const sectionTimings: Record<string, number> = {};
  const errors: Array<{ section: string; error: string }> = [];

  // Fetch project first (required for report)
  const { data: project, error: projectErr } = await supabase
    .from("cs_projects")
    .select("*")
    .eq("id", projectId)
    .single();

  if (projectErr || !project) {
    // T-19-09: no data leakage on 404
    return NextResponse.json(
      { error: "Project not found" },
      { status: 404 }
    );
  }

  // D-56: use Promise.allSettled to fetch all sections in parallel with 10s timeout each
  type SectionResult<T> = { data: T; timing: number };

  async function fetchSection<T>(
    name: string,
    fn: () => Promise<T>
  ): Promise<SectionResult<T>> {
    const t0 = Date.now();
    const data = await withTimeout(fn(), name);
    return { data, timing: Date.now() - t0 };
  }

  // Section fetchers
  const budgetFetcher = fetchSection("budget", async () => {
    const { data: contracts } = await supabase
      .from("cs_contracts")
      .select("*")
      .eq("project_id", projectId);
    return computeBudgetSection(
      { budget: project.budget ?? "0" },
      contracts ?? []
    );
  });

  const scheduleFetcher = fetchSection("schedule", async () => {
    const { data: tasks } = await supabase
      .from("cs_project_tasks")
      .select("*")
      .eq("project_id", projectId);
    return computeScheduleSection(tasks ?? []);
  });

  const issuesFetcher = fetchSection("issues", async () => {
    const [rfisRes, cosRes] = await Promise.all([
      supabase
        .from("cs_rfis")
        .select("*")
        .eq("project_id", projectId),
      supabase
        .from("cs_change_orders")
        .select("*")
        .eq("project_id", projectId),
    ]);
    return computeIssuesSection(rfisRes.data ?? [], cosRes.data ?? []);
  });

  const teamFetcher = fetchSection("team", async () => {
    const [assignRes, activityRes] = await Promise.all([
      supabase
        .from("cs_team_assignments")
        .select("*")
        .eq("project_id", projectId),
      supabase
        .from("cs_activity_feed")
        .select("*")
        .eq("project_id", projectId)
        .order("timestamp", { ascending: false })
        .limit(10),
    ]);
    return computeTeamSection(assignRes.data ?? [], activityRes.data ?? []);
  });

  const safetyFetcher = fetchSection("safety", async () => {
    const { data: incidents } = await supabase
      .from("cs_safety_incidents")
      .select("*")
      .eq("project_id", projectId);
    return computeSafetySection(incidents ?? []);
  });

  const docsFetcher = fetchSection("documents", async () => {
    // D-15: COUNT from cs_documents WHERE entity_type = 'project' AND entity_id = id
    const { count } = await supabase
      .from("cs_documents")
      .select("id", { count: "exact", head: true })
      .eq("entity_type", "project")
      .eq("entity_id", projectId);
    return { count: count ?? 0 };
  });

  const photosFetcher = fetchSection("photos", async () => {
    // D-15: COUNT from cs_field_photos WHERE project_id = id
    const { count } = await supabase
      .from("cs_field_photos")
      .select("id", { count: "exact", head: true })
      .eq("project_id", projectId);
    return { count: count ?? 0 };
  });

  // D-56: Promise.allSettled — section failures produce partial report
  const results = await Promise.allSettled([
    budgetFetcher,
    scheduleFetcher,
    issuesFetcher,
    teamFetcher,
    safetyFetcher,
    docsFetcher,
    photosFetcher,
  ]);

  const sectionNames = [
    "budget",
    "schedule",
    "issues",
    "team",
    "safety",
    "documents",
    "photos",
  ];

  type SectionValues = {
    budget: ReturnType<typeof computeBudgetSection> | null;
    schedule: ReturnType<typeof computeScheduleSection> | null;
    issues: ReturnType<typeof computeIssuesSection> | null;
    team: ReturnType<typeof computeTeamSection> | null;
    safety: ReturnType<typeof computeSafetySection> | null;
    documents: { count: number };
    photos: { count: number };
  };

  const sections: SectionValues = {
    budget: null,
    schedule: null,
    issues: null,
    team: null,
    safety: null,
    documents: { count: 0 },
    photos: { count: 0 },
  };

  for (let i = 0; i < results.length; i++) {
    const r = results[i];
    const name = sectionNames[i];
    if (r.status === "fulfilled") {
      sectionTimings[name] = r.value.timing;
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      (sections as Record<string, unknown>)[name] = r.value.data;
    } else {
      // D-56: on section failure, set section to null and add to errors array
      sectionTimings[name] = Date.now() - startTime;
      const reason = r.reason;
      const errMsg =
        typeof reason === "object" && reason?.message
          ? reason.message
          : String(reason);
      errors.push({ section: name, error: errMsg });
    }
  }

  // D-07: compute health score from sections
  const budgetSpentPercent =
    sections.budget && sections.budget.contractValue > 0
      ? (sections.budget.totalBilled / sections.budget.contractValue) * 100
      : 0;
  const delayedMilestonePercent =
    sections.schedule && sections.schedule.totalCount > 0
      ? (sections.schedule.delayedCount / sections.schedule.totalCount) * 100
      : 0;
  const criticalOpenIssues = sections.issues?.criticalOpen ?? 0;

  const health = computeHealthScore({
    budgetSpentPercent: clampBudgetPercent(budgetSpentPercent),
    delayedMilestonePercent,
    criticalOpenIssues,
  });

  const now = new Date().toISOString();

  const report: ProjectReport = {
    project_id: projectId,
    project_name: project.name ?? "Unknown",
    client_name: project.client ?? "",
    generated_at: now,
    health,
    budget: sections.budget,
    schedule: sections.schedule,
    issues: sections.issues,
    team: sections.team,
    safety: sections.safety,
    ai_insights: null, // AI insights computed separately
    documents: sections.documents,
    photos: sections.photos,
    errors,
  };

  const totalMs = Date.now() - startTime;

  // D-56c: _meta field in JSON
  const responseBody = {
    ...report,
    _meta: {
      generated_at: now,
      total_ms: totalMs,
      section_timings: sectionTimings,
      errors_count: errors.length,
      // D-16b: freshness timestamp per section
      freshness: Object.fromEntries(
        sectionNames.map((s) => [s, now])
      ),
    },
  };

  // D-56c: set X-Report-Debug response header with timing per section
  const debugHeader = JSON.stringify({
    total_ms: totalMs,
    sections: sectionTimings,
  });

  return NextResponse.json(responseBody, {
    status: 200,
    headers: {
      "X-Report-Debug": debugHeader,
      ...getRateLimitHeaders(rl),
    },
  });
}
