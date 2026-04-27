// 999.5 follow-up: server-only marker (uses createServerSupabase).
import "server-only";

// Phase 16 FIELD-04: orchestration for creating a daily log.
//
// Composition:
//   1. Load project (lat/lng) + project template layer
//   2. resolveTemplate(base, layer, role) → frozen snapshot (D-17)
//   3. Parallel pre-fill (RESEARCH no-waterfalls): weather, crew, RFI count,
//      punch count, yesterday carryover
//   4. Insert into cs_daily_logs with template_snapshot_jsonb, weather_jsonb,
//      content_jsonb pre-filled. UNIQUE(project_id, log_date) → 409.
//
// Open-Meteo failure does NOT block insert (T-16-DOS). NaN lat → throws via
// assertValidLatLng (T-16-WX).
//
// The supabase + openMeteo clients are injected for testability.

import { BASE_TEMPLATE_V1, type ProjectTemplateLayer } from "./baseTemplate";
import { resolveTemplate, type RoleKey } from "./templateResolver";
import {
  assertValidLatLng,
  type OpenMeteoClient,
  type WeatherSnapshot,
} from "./openMeteoClient";

export type DailyLogCreateInput = {
  projectId: string;
  logDate: string; // YYYY-MM-DD
  role: RoleKey;
  openMeteo: OpenMeteoClient;
  // Injected for tests; in production callers pass createServerSupabase().
  // Typed as `any` because we use a tiny subset of the supabase-js surface
  // and zod is not a project dep.
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any;
};

export type DailyLogCreateResult =
  | { ok: true; id: string; templateSnapshot: unknown; contentSnapshot: unknown; weather: WeatherSnapshot }
  | { ok: false; status: number; error: string; existingId?: string };

type ProjectRow = {
  id: string;
  latitude: number | null;
  longitude: number | null;
  template_layer?: ProjectTemplateLayer | null;
};

export async function createDailyLog(input: DailyLogCreateInput): Promise<DailyLogCreateResult> {
  const { projectId, logDate, role, openMeteo, supabase } = input;

  if (typeof projectId !== "string" || projectId.length === 0) {
    return { ok: false, status: 400, error: "projectId required" };
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(logDate)) {
    return { ok: false, status: 400, error: "logDate must be YYYY-MM-DD" };
  }

  // 1. Load project + template layer
  const { data: project, error: projectErr } = await supabase
    .from("cs_projects")
    .select("id, latitude, longitude, template_layer")
    .eq("id", projectId)
    .maybeSingle();

  if (projectErr) {
    return { ok: false, status: 500, error: `project load failed: ${projectErr.message}` };
  }
  if (!project) {
    return { ok: false, status: 404, error: "project not found" };
  }
  const proj = project as ProjectRow;

  // 2. Resolve template (frozen snapshot)
  const layer = (proj.template_layer ?? null) as ProjectTemplateLayer | null;
  const templateSnapshot = resolveTemplate(BASE_TEMPLATE_V1, layer, role);

  // Pre-validate lat/lng if present so NaN throws BEFORE the insert kicks
  // off (T-16-WX surfaces as a thrown Error to caller).
  const lat = proj.latitude;
  const lng = proj.longitude;
  if (lat != null && lng != null) {
    assertValidLatLng(lat, lng);
  }

  // 3. Parallel pre-fill — Promise.all so weather/crew/counts/carryover
  //    don't waterfall.
  const yesterday = previousDay(logDate);

  const weatherPromise: Promise<WeatherSnapshot> =
    lat != null && lng != null
      ? openMeteo
          .fetch(lat, lng, logDate)
          .catch((e: unknown) => ({
            error: `open-meteo unavailable (${e instanceof Error ? e.message : "unknown"})`,
          }))
      : Promise.resolve({ error: "open-meteo unavailable (no project coordinates)" } as WeatherSnapshot);

  const crewPromise = supabase
    .from("cs_daily_crew")
    .select("id, project_id, assignment_date")
    .eq("project_id", projectId)
    .eq("assignment_date", logDate);

  const rfiCountPromise = supabase
    .from("cs_rfis")
    .select("id", { count: "exact", head: true })
    .eq("project_id", projectId)
    .eq("status", "open");

  const punchCountPromise = supabase
    .from("cs_punch_items")
    .select("id", { count: "exact", head: true })
    .eq("project_id", projectId)
    .eq("status", "open");

  const yesterdayPromise = supabase
    .from("cs_daily_logs")
    .select("content_jsonb")
    .eq("project_id", projectId)
    .eq("log_date", yesterday)
    .maybeSingle();

  const [weather, crewRes, rfiRes, punchRes, yesterdayRes] = await Promise.all([
    weatherPromise,
    crewPromise,
    rfiCountPromise,
    punchCountPromise,
    yesterdayPromise,
  ]);

  const contentSnapshot = {
    weather,
    crew_on_site: (crewRes?.data as unknown[]) ?? [],
    open_rfis: rfiRes?.count ?? 0,
    open_punch_items: punchRes?.count ?? 0,
    yesterday_carryover: yesterdayRes?.data ?? null,
    work_performed: "",
    delays: "",
    visitors: "",
    safety_notes: "",
  };

  // 4. Insert
  const { data: inserted, error: insertErr } = await supabase
    .from("cs_daily_logs")
    .insert({
      project_id: projectId,
      log_date: logDate,
      template_snapshot_jsonb: templateSnapshot,
      content_jsonb: contentSnapshot,
      weather_jsonb: weather,
    })
    .select("id")
    .single();

  if (insertErr) {
    // Postgres unique_violation
    if (insertErr.code === "23505") {
      const { data: existing } = await supabase
        .from("cs_daily_logs")
        .select("id")
        .eq("project_id", projectId)
        .eq("log_date", logDate)
        .maybeSingle();
      return {
        ok: false,
        status: 409,
        error: "daily log already exists for this date",
        existingId: existing?.id,
      };
    }
    if (insertErr.code === "42501") {
      return { ok: false, status: 403, error: "permission denied" };
    }
    return { ok: false, status: 500, error: insertErr.message ?? "insert failed" };
  }

  return {
    ok: true,
    id: (inserted as { id: string }).id,
    templateSnapshot,
    contentSnapshot,
    weather,
  };
}

function previousDay(ymd: string): string {
  const [y, m, d] = ymd.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() - 1);
  return dt.toISOString().slice(0, 10);
}
