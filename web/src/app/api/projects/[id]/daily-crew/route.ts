import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { dailyCrewSchema } from "@/lib/team/schemas";

// GET /api/projects/[id]/daily-crew?date=YYYY-MM-DD → single row or null
// GET /api/projects/[id]/daily-crew?from=YYYY-MM-DD&to=YYYY-MM-DD → array
export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: project_id } = await params;
  const supabase = await createServerSupabase();
  if (!supabase)
    return NextResponse.json(
      { error: "Supabase not configured" },
      { status: 500 }
    );
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });

  const url = new URL(req.url);
  const date = url.searchParams.get("date");
  const from = url.searchParams.get("from");
  const to = url.searchParams.get("to");

  if (date) {
    const { data, error } = await supabase
      .from("cs_daily_crew")
      .select("*")
      .eq("project_id", project_id)
      .eq("assignment_date", date)
      .maybeSingle();
    if (error)
      return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
  }

  let q = supabase
    .from("cs_daily_crew")
    .select("*")
    .eq("project_id", project_id)
    .order("assignment_date", { ascending: false });
  if (from) q = q.gte("assignment_date", from);
  if (to) q = q.lte("assignment_date", to);
  const { data, error } = await q;
  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json(data ?? []);
}

// POST upserts by (project_id, assignment_date) — D-07 enforces one row per day.
export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id: project_id } = await params;
  const supabase = await createServerSupabase();
  if (!supabase)
    return NextResponse.json(
      { error: "Supabase not configured" },
      { status: 500 }
    );
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "invalid json" }, { status: 400 });
  }
  const parsed = dailyCrewSchema.safeParse(body);
  if (!parsed.success)
    return NextResponse.json(
      { error: parsed.error.issues[0].message },
      { status: 400 }
    );

  const row = { project_id, ...parsed.data, created_by: user.id };
  const { data, error } = await supabase
    .from("cs_daily_crew")
    .upsert(row, { onConflict: "project_id,assignment_date" })
    .select()
    .single();
  if (error) {
    console.error("[api/projects/daily-crew] upsert:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json(data, { status: 201 });
}
