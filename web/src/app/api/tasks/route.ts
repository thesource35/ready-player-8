import { NextResponse } from "next/server";
import { fetchTable, insertRow, updateOwnedRow, deleteOwnedRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import { checkRateLimit } from "@/lib/rate-limit";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

// Only these tables can be targeted via the tasks API
const TASKS_TABLES = ["cs_todos", "cs_schedule_events", "cs_reminders"] as const;

function isTasksTable(name: string): name is (typeof TASKS_TABLES)[number] {
  return (TASKS_TABLES as readonly string[]).includes(name);
}

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });

  const [todos, events, reminders] = await Promise.all([
    fetchTable("cs_todos", { order: { column: "created_at", ascending: false } }),
    fetchTable("cs_schedule_events", { order: { column: "date" } }),
    fetchTable("cs_reminders", { order: { column: "trigger_at" } }),
  ]);

  return NextResponse.json({ todos, events, reminders });
}

export async function POST(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const body = await req.json();
  const { table, ...data } = body;
  const targetTable = typeof table === "string" ? table : "cs_todos";

  if (!isTasksTable(targetTable)) {
    return NextResponse.json({ error: "Invalid table" }, { status: 400 });
  }

  const row = await insertRow(targetTable, { ...data, user_id: user.id });
  if (!row) {
    return NextResponse.json({ error: "Failed to create" }, { status: 500 });
  }
  return NextResponse.json(row);
}

export async function PATCH(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const body = await req.json();
  const { table, id, ...updates } = body;
  const targetTable = typeof table === "string" ? table : "cs_todos";

  if (!isTasksTable(targetTable)) {
    return NextResponse.json({ error: "Invalid table" }, { status: 400 });
  }
  if (typeof id !== "string" || !id) {
    return NextResponse.json({ error: "Valid id is required" }, { status: 400 });
  }

  const row = await updateOwnedRow(targetTable, id, user.id, updates);
  if (!row) {
    return NextResponse.json({ error: "Not found or not owned" }, { status: 404 });
  }
  return NextResponse.json(row);
}

export async function DELETE(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { table, id } = await req.json();
  const targetTable = typeof table === "string" ? table : "cs_todos";

  if (!isTasksTable(targetTable)) {
    return NextResponse.json({ error: "Invalid table" }, { status: 400 });
  }
  if (typeof id !== "string" || !id) {
    return NextResponse.json({ error: "Valid id is required" }, { status: 400 });
  }

  const success = await deleteOwnedRow(targetTable, id, user.id);
  if (!success) {
    return NextResponse.json({ error: "Not found or not owned" }, { status: 404 });
  }
  return NextResponse.json({ success: true });
}
