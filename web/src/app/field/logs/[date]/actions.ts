"use server";

// Phase 16 FIELD-04: Server Actions for daily log create/save.
//
// Per Phase 16 convention (see web/src/app/field/actions.ts and lib/field/
// attachments.ts) Server Actions return plain serializable discriminated
// unions — never NextResponse.

import { createServerSupabase } from "@/lib/supabase/server";
import { createDailyLog, type DailyLogCreateResult } from "@/lib/field/dailyLogCreate";
import { OpenMeteoFetchClient } from "@/lib/field/openMeteoClient";
import type { RoleKey } from "@/lib/field/templateResolver";

const ROLES = new Set<RoleKey>(["superintendent", "projectManager", "executive"]);

export async function createDailyLogAction(
  projectId: unknown,
  logDate: unknown,
  role: unknown = "superintendent",
): Promise<DailyLogCreateResult> {
  if (typeof projectId !== "string" || projectId.length === 0) {
    return { ok: false, status: 400, error: "projectId required" };
  }
  if (typeof logDate !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(logDate)) {
    return { ok: false, status: 400, error: "logDate must be YYYY-MM-DD" };
  }
  const r: RoleKey = ROLES.has(role as RoleKey) ? (role as RoleKey) : "superintendent";

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, status: 503, error: "supabase not configured" };
  }

  return createDailyLog({
    projectId,
    logDate,
    role: r,
    openMeteo: new OpenMeteoFetchClient(),
    supabase,
  });
}

export type SaveDailyLogResult =
  | { ok: true }
  | { ok: false; status: number; error: string };

export async function saveDailyLog(
  logId: unknown,
  contentJson: unknown,
): Promise<SaveDailyLogResult> {
  if (typeof logId !== "string" || logId.length === 0) {
    return { ok: false, status: 400, error: "logId required" };
  }
  if (typeof contentJson !== "object" || contentJson === null) {
    return { ok: false, status: 400, error: "contentJson must be an object" };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, status: 503, error: "supabase not configured" };
  }

  const { error } = await supabase
    .from("cs_daily_logs")
    .update({ content_jsonb: contentJson })
    .eq("id", logId);

  if (error) {
    if (error.code === "42501") return { ok: false, status: 403, error: "permission denied" };
    return { ok: false, status: 500, error: error.message ?? "save failed" };
  }
  return { ok: true };
}
