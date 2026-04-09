import { NextResponse } from "next/server";
import { updateOwnedRow, deleteOwnedRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import { verifyCsrfOrigin } from "@/lib/csrf";
import { isIsoDate } from "@/lib/calendar/dates";

export const dynamic = "force-dynamic";

type ProjectTask = {
  id: string;
  project_id: string;
  name: string;
  start_date: string;
  end_date: string;
  updated_by?: string;
  updated_at?: string;
};

export async function PATCH(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: "id is required" }, { status: 400 });
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { start_date, end_date, name, percent_complete, is_critical, trade } = body as {
    start_date?: unknown;
    end_date?: unknown;
    name?: unknown;
    percent_complete?: unknown;
    is_critical?: unknown;
    trade?: unknown;
  };

  const updates: Partial<ProjectTask> & Record<string, unknown> = {
    updated_by: user.id,
    updated_at: new Date().toISOString(),
  };

  // If either date is present, both must be present + valid + start<=end.
  // This rejects TZ-naive timestamps via isIsoDate (Pitfall #1).
  if (start_date !== undefined || end_date !== undefined) {
    if (!isIsoDate(start_date) || !isIsoDate(end_date)) {
      return NextResponse.json(
        { error: "start_date and end_date must be YYYY-MM-DD" },
        { status: 400 }
      );
    }
    if (start_date > end_date) {
      return NextResponse.json(
        { error: "start_date must be <= end_date" },
        { status: 400 }
      );
    }
    updates.start_date = start_date;
    updates.end_date = end_date;
  }

  if (typeof name === "string") updates.name = name.trim();
  if (typeof percent_complete === "number") updates.percent_complete = percent_complete;
  if (typeof is_critical === "boolean") updates.is_critical = is_critical;
  if (typeof trade === "string") updates.trade = trade;

  const row = await updateOwnedRow<ProjectTask>("cs_project_tasks", id, user.id, updates);
  if (!row) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  return NextResponse.json(row);
}

export async function DELETE(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { id } = await params;
  if (!id) {
    return NextResponse.json({ error: "id is required" }, { status: 400 });
  }

  const ok = await deleteOwnedRow("cs_project_tasks", id, user.id);
  if (!ok) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
  return new NextResponse(null, { status: 204 });
}
