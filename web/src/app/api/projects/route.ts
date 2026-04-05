import { NextResponse } from "next/server";
import { fetchTable, insertRow, deleteOwnedRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { Project } from "@/lib/supabase/types";
import { MOCK_PROJECTS } from "@/lib/mock-data";
import { checkRateLimit } from "@/lib/rate-limit";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });
  const projects = await fetchTable<Project>("cs_projects", {
    order: { column: "created_at", ascending: false },
  });

  if (projects.length === 0) {
    return NextResponse.json(MOCK_PROJECTS);
  }

  return NextResponse.json(projects);
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
  const name = typeof body.name === "string" ? body.name.trim() : "";
  if (!name) {
    return NextResponse.json({ error: "Project name is required" }, { status: 400 });
  }

  const project = await insertRow<Project>("cs_projects", {
    user_id: user.id,
    name,
    client: typeof body.client === "string" ? body.client.trim() : "",
    type: typeof body.type === "string" ? body.type.trim() : "General",
    status: typeof body.status === "string" ? body.status.trim() : "On Track",
    progress: typeof body.progress === "number" ? body.progress : 0,
    budget: typeof body.budget === "string" ? body.budget.trim() : "$0",
    score: typeof body.score === "number" ? body.score : 0,
    team: typeof body.team === "string" ? body.team.trim() : "",
  });

  if (!project) {
    return NextResponse.json({ error: "Failed to create project" }, { status: 500 });
  }

  return NextResponse.json(project);
}

export async function DELETE(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  const { id } = await req.json();
  if (typeof id !== "string" || !id) {
    return NextResponse.json({ error: "Valid id is required" }, { status: 400 });
  }

  const success = await deleteOwnedRow("cs_projects", id, user.id);
  if (!success) {
    return NextResponse.json({ error: "Not found or not owned" }, { status: 404 });
  }
  return NextResponse.json({ success: true });
}
