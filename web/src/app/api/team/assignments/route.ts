import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { assignmentSchema } from "@/lib/team/schemas";

export async function POST(req: Request) {
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
  const parsed = assignmentSchema.safeParse(body);
  if (!parsed.success)
    return NextResponse.json(
      { error: parsed.error.issues[0].message },
      { status: 400 }
    );

  const { data, error } = await supabase
    .from("cs_project_assignments")
    .insert(parsed.data)
    .select()
    .single();
  if (error) {
    // Postgres unique_violation — per D-04, only one active assignment per (project, member)
    if ((error as { code?: string }).code === "23505") {
      return NextResponse.json(
        { error: "member already actively assigned to project" },
        { status: 409 }
      );
    }
    console.error("[api/team/assignments] insert:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
  return NextResponse.json(data, { status: 201 });
}

export async function DELETE(req: Request) {
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
  const id = url.searchParams.get("id");
  if (!id)
    return NextResponse.json({ error: "id required" }, { status: 400 });
  const { error } = await supabase
    .from("cs_project_assignments")
    .delete()
    .eq("id", id);
  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ ok: true });
}
