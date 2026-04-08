// Phase 14 — POST /api/notifications/mark-all-read
// Marks all unread notifications read for the current user.
// Optional ?project_id= filter respects D-12 (current view filter).

import { NextResponse } from "next/server";
import { markAllRead } from "@/lib/notifications";

export async function POST(req: Request) {
  const url = new URL(req.url);
  const projectId = url.searchParams.get("project_id");
  const updated = await markAllRead(projectId);
  return NextResponse.json({ ok: true, updated });
}
