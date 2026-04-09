import { NextResponse } from "next/server";
import { fetchTable, getAuthenticatedClient } from "@/lib/supabase/fetch";
import { addDays } from "@/lib/calendar/dates";
import { deriveMilestones } from "@/lib/calendar/derive-milestones";

export const dynamic = "force-dynamic";

type Project = { id: string; name?: string; start_date?: string | null; end_date?: string | null };
type Contract = { id: string; project_id?: string | null; bid_due_date?: string | null };
type ScheduleEvent = {
  id: string;
  project_id?: string | null;
  event_type?: string | null;
  date?: string | null;
  title?: string | null;
};
type Task = { id: string; project_id: string; start_date: string; end_date: string };
type CrewAssignment = { id: string; project_id?: string | null; date?: string | null };
type Dep = { id: string; predecessor_task_id: string; successor_task_id: string };

function todayIso(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

export async function GET(req: Request) {
  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const today = todayIso();
  // Default window: today-30d .. today+180d (Pitfall #6).
  const from = searchParams.get("from") ?? addDays(today, -30);
  const to = searchParams.get("to") ?? addDays(today, 180);

  // All six sources fire in parallel — Pattern 2. RLS does the org filtering
  // automatically (Pitfall #4: all tables must share the same auth model).
  const [tasks, projects, contracts, events, crewAssignments, dependencies] = await Promise.all([
    fetchTable<Task>("cs_project_tasks", { order: { column: "start_date", ascending: true } }),
    fetchTable<Project>("cs_projects"),
    fetchTable<Contract>("cs_contracts"),
    fetchTable<ScheduleEvent>("cs_schedule_events", {
      eq: { column: "event_type", value: "inspection" },
    }),
    fetchTable<CrewAssignment>("cs_daily_crew"),
    fetchTable<Dep>("cs_task_dependencies"),
  ]);

  const milestones = deriveMilestones({ projects, contracts, events });

  return NextResponse.json({
    window: { from, to },
    projects,
    tasks,
    milestones,
    crewAssignments,
    events,
    dependencies,
  });
}
