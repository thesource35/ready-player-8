import { headers } from "next/headers";
import RollupTimeline from "./RollupTimeline";
import GanttChart from "./GanttChart";
import AgendaView from "./AgendaView";

export const dynamic = "force-dynamic";

type Project = { id: string; name: string; color?: string | null };
type Task = {
  id: string;
  project_id: string;
  name: string;
  start_date: string;
  end_date: string;
  trade?: string | null;
  percent_complete: number;
  is_critical: boolean;
};
type Milestone = {
  project_id: string;
  type: "start" | "end" | "bid_due" | "inspection";
  date: string;
  label: string;
  source_id: string;
};
type CrewAssignment = { id: string; project_id: string; date: string; crew_count?: number };
type ScheduleEvent = { id: string; project_id: string; date: string; title: string; event_type: string };
type Dependency = {
  id: string;
  predecessor_task_id: string;
  successor_task_id: string;
  dep_type: "FS" | "SS" | "FF" | "SF";
  lag_days: number;
};

export type TimelineResponse = {
  window: { from: string; to: string };
  projects: Project[];
  tasks: Task[];
  milestones: Milestone[];
  crewAssignments: CrewAssignment[];
  events: ScheduleEvent[];
  dependencies: Dependency[];
};

async function fetchTimeline(from?: string, to?: string): Promise<TimelineResponse | null> {
  const h = await headers();
  const cookie = h.get("cookie") ?? "";
  const host = h.get("host") ?? "localhost:3000";
  const proto = h.get("x-forwarded-proto") ?? "http";
  const base = process.env.NEXT_PUBLIC_BASE_URL ?? `${proto}://${host}`;
  const qs = new URLSearchParams();
  if (from) qs.set("from", from);
  if (to) qs.set("to", to);
  const url = `${base}/api/calendar/timeline${qs.toString() ? `?${qs.toString()}` : ""}`;
  try {
    const res = await fetch(url, { cache: "no-store", headers: { cookie } });
    if (!res.ok) {
      return null;
    }
    return (await res.json()) as TimelineResponse;
  } catch (err) {
    console.error("[schedule] fetch timeline failed:", err);
    return null;
  }
}

type SearchParams = { project?: string; view?: string; from?: string; to?: string };

export default async function SchedulePage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const sp = await searchParams;
  const view = sp.view ?? (sp.project ? "gantt" : "rollup");
  const data = await fetchTimeline(sp.from, sp.to);

  if (!data) {
    return (
      <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
        <div
          style={{
            background: "var(--surface)",
            borderRadius: 14,
            padding: 20,
            border: "1px solid rgba(242,158,61,0.08)",
          }}
        >
          <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>
            SCHEDULE
          </div>
          <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Timeline unavailable</h1>
          <p style={{ fontSize: 12, color: "var(--muted)" }}>
            Unable to load schedule data. Sign in and ensure Supabase is configured.
          </p>
        </div>
      </div>
    );
  }

  const header = (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        padding: 20,
        marginBottom: 16,
        border: "1px solid rgba(242,158,61,0.08)",
      }}
    >
      <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>
        SCHEDULE
      </div>
      <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Project Timeline &amp; Gantt</h1>
      <p style={{ fontSize: 12, color: "var(--muted)" }}>
        {view === "rollup" && "Cross-project rollup · click a swim lane to drill in"}
        {view === "gantt" && "Drag a task bar to reschedule · day-snap · persists to Supabase"}
        {view === "agenda" && "Day-by-day agenda across all projects"}
      </p>
      <div style={{ display: "flex", gap: 8, marginTop: 12, fontSize: 10, fontWeight: 800 }}>
        <a
          href="/schedule"
          style={{
            padding: "6px 10px",
            borderRadius: 6,
            background: view === "rollup" ? "var(--accent)" : "var(--panel)",
            color: view === "rollup" ? "#000" : "var(--text)",
            textDecoration: "none",
          }}
        >
          ROLLUP
        </a>
        <a
          href="/schedule?view=agenda"
          style={{
            padding: "6px 10px",
            borderRadius: 6,
            background: view === "agenda" ? "var(--accent)" : "var(--panel)",
            color: view === "agenda" ? "#000" : "var(--text)",
            textDecoration: "none",
          }}
        >
          AGENDA
        </a>
      </div>
    </div>
  );

  return (
    <div style={{ padding: 20, maxWidth: 1400, margin: "0 auto" }}>
      {header}
      {view === "agenda" && <AgendaView data={data} />}
      {view === "rollup" && <RollupTimeline data={data} />}
      {view === "gantt" && sp.project && (
        <GanttChart
          projectId={sp.project}
          projectName={data.projects.find((p) => p.id === sp.project)?.name ?? "Project"}
          tasks={data.tasks.filter((t) => t.project_id === sp.project)}
          dependencies={data.dependencies}
          milestones={data.milestones.filter((m) => m.project_id === sp.project)}
          rangeStart={data.window.from}
          rangeEnd={data.window.to}
        />
      )}
      {view === "gantt" && !sp.project && (
        <p style={{ color: "var(--muted)", fontSize: 12 }}>Select a project from the rollup view.</p>
      )}
    </div>
  );
}
