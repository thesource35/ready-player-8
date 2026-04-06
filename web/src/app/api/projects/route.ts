import { NextResponse } from "next/server";
import { fetchTable, fetchTablePaginated, insertRow, deleteOwnedRow, getAuthenticatedClient } from "@/lib/supabase/fetch";
import type { Project } from "@/lib/supabase/types";
import { MOCK_PROJECTS } from "@/lib/mock-data";
import { checkRateLimit } from "@/lib/rate-limit";
import { verifyCsrfOrigin } from "@/lib/csrf";

export const dynamic = "force-dynamic";

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for") ?? "unknown";
  if (!checkRateLimit(ip)) return NextResponse.json({ error: "Too many requests" }, { status: 429 });

  const { searchParams } = new URL(req.url);
  const page = Math.max(0, parseInt(searchParams.get("page") || "0", 10) || 0);

  const result = await fetchTablePaginated<Project>("cs_projects", {
    order: { column: "created_at", ascending: false },
    page,
  });

  if (result.data.length === 0 && page === 0) {
    return NextResponse.json({ data: MOCK_PROJECTS, hasMore: false, total: MOCK_PROJECTS.length });
  }

  return NextResponse.json(result);
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
    score: typeof body.score === "string" ? body.score.trim() : typeof body.score === "number" ? String(body.score) : "0",
    team: typeof body.team === "string" ? body.team.trim() : "",
  });

  if (!project) {
    return NextResponse.json({ error: "Failed to create project" }, { status: 500 });
  }

  return NextResponse.json(project, { status: 201 });
}

export async function DELETE(req: Request) {
  if (!verifyCsrfOrigin(req)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { user } = await getAuthenticatedClient();
  if (!user) {
    return NextResponse.json({ error: "Sign in required" }, { status: 401 });
  }

  let deleteBody: Record<string, unknown>;
  try {
    deleteBody = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }
  const { id } = deleteBody as { id?: string };
  if (typeof id !== "string" || !id) {
    return NextResponse.json({ error: "Valid id is required" }, { status: 400 });
  }

  const success = await deleteOwnedRow("cs_projects", id, user.id);
  if (!success) {
    return NextResponse.json({ error: "Not found or not owned" }, { status: 404 });
  }
  return NextResponse.json({ success: true });
}
