// Phase 14 — POST /api/notifications/mark-all-read
// Marks all unread notifications read for the current user.
// Optional ?project_id= filter respects D-12 (current view filter).
// 999.5 follow-up: structured logging via [api:notifications] prefix.

import { NextResponse } from "next/server";
import { markAllRead } from "@/lib/notifications/server";

export async function POST(req: Request) {
  const t0 = Date.now();
  const url = new URL(req.url);
  const projectId = url.searchParams.get("project_id");
  try {
    const updated = await markAllRead(projectId);
    console.log(`[api:notifications] POST mark-all-read 200 projectId=${projectId ?? "all"} updated=${updated} ${Date.now() - t0}ms`);
    return NextResponse.json({ ok: true, updated });
  } catch (e) {
    console.error(`[api:notifications] POST mark-all-read 500 projectId=${projectId ?? "all"} ${Date.now() - t0}ms`, e);
    return NextResponse.json({ error: "internal error" }, { status: 500 });
  }
}
