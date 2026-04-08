// Phase 16 FIELD-04: /field/logs/[date] route.
//
// Server Component. Loads existing log for (projectId, date) or returns the
// resolved template + prefilled content for the Editor to render.
//
// Next 15+ async params/searchParams pattern.

import { createServerSupabase } from "@/lib/supabase/server";
import { createDailyLogAction } from "./actions";
import Editor from "./Editor";

type PageProps = {
  params: Promise<{ date: string }>;
  searchParams: Promise<{ projectId?: string; role?: string }>;
};

export default async function DailyLogPage({ params, searchParams }: PageProps) {
  const { date } = await params;
  const { projectId, role } = await searchParams;

  if (!projectId) {
    return (
      <main style={{ padding: 24 }}>
        <h1>Daily Log {date}</h1>
        <p style={{ color: "var(--muted)" }}>Missing projectId query param.</p>
      </main>
    );
  }

  const supabase = await createServerSupabase();
  type ExistingLog = { id: string; content_jsonb: unknown; template_snapshot_jsonb: unknown };
  let existingLog: ExistingLog | null = null;
  if (supabase) {
    const { data } = await supabase
      .from("cs_daily_logs")
      .select("id, content_jsonb, template_snapshot_jsonb")
      .eq("project_id", projectId)
      .eq("log_date", date)
      .maybeSingle();
    existingLog = (data as ExistingLog | null) ?? null;
  }

  if (existingLog) {
    return (
      <Editor
        logId={existingLog.id}
        date={date}
        template={existingLog.template_snapshot_jsonb}
        content={existingLog.content_jsonb}
      />
    );
  }

  // No existing log — create one server-side via the action so the user lands
  // on a pre-filled editor.
  const created = await createDailyLogAction(projectId, date, role ?? "superintendent");
  if (!created.ok) {
    return (
      <main style={{ padding: 24 }}>
        <h1>Daily Log {date}</h1>
        <p style={{ color: "var(--red)" }}>
          Could not create log: {created.error} (status {created.status})
        </p>
      </main>
    );
  }

  return (
    <Editor
      logId={created.id}
      date={date}
      template={created.templateSnapshot}
      content={created.contentSnapshot}
    />
  );
}
