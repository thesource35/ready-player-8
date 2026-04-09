import { NextResponse } from "next/server";
import { fetchTable, insertRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import { verifyCsrfOrigin } from "@/lib/csrf";
import { isIsoDate } from "@/lib/calendar/dates";

export const dynamic = "force-dynamic";

type ProjectTask = {
  id: string;
  project_id: string;
  name: string;
  trade?: string | null;
  start_date: string;
  end_date: string;
  percent_complete?: number;
  is_critical?: boolean;
  created_by?: string;
  updated_by?: string;
};

export async function GET(req: Request) {
  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const projectId = searchParams.get("project_id");
  if (!projectId) {
    return NextResponse.json({ error: "project_id is required" }, { status: 400 });
  }

  const rows = await fetchTable<ProjectTask>("cs_project_tasks", {
    eq: { column: "project_id", value: projectId },
    order: { column: "start_date", ascending: true },
  });

  return NextResponse.json(rows);
}

export async function POST(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { project_id, name, start_date, end_date, trade, percent_complete, is_critical } = body as {
    project_id?: unknown;
    name?: unknown;
    start_date?: unknown;
    end_date?: unknown;
    trade?: unknown;
    percent_complete?: unknown;
    is_critical?: unknown;
  };

  if (typeof project_id !== "string" || !project_id) {
    return NextResponse.json({ error: "project_id is required" }, { status: 400 });
  }
  if (typeof name !== "string" || !name.trim()) {
    return NextResponse.json({ error: "name is required" }, { status: 400 });
  }
  if (!isIsoDate(start_date) || !isIsoDate(end_date)) {
    return NextResponse.json({ error: "start_date and end_date must be YYYY-MM-DD" }, { status: 400 });
  }
  // Lexical compare is safe for YYYY-MM-DD.
  if (start_date > end_date) {
    return NextResponse.json({ error: "start_date must be <= end_date" }, { status: 400 });
  }

  const row = await insertRow<ProjectTask>("cs_project_tasks", {
    project_id,
    name: name.trim(),
    trade: typeof trade === "string" ? trade : null,
    start_date,
    end_date,
    percent_complete: typeof percent_complete === "number" ? percent_complete : 0,
    is_critical: typeof is_critical === "boolean" ? is_critical : false,
    created_by: user.id,
    updated_by: user.id,
  });

  if (!row) {
    return NextResponse.json({ error: "Failed to create task" }, { status: 500 });
  }
  return NextResponse.json(row, { status: 201 });
}
