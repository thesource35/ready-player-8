// Phase 14 — GET /api/notifications
// Returns the authenticated user's notification list with optional project filter.
// Also returns the unread count in the same payload to avoid a second round-trip.
// 999.5 follow-up: structured logging via [api:notifications] prefix.

import { NextResponse } from "next/server";
import { fetchNotifications, fetchUnreadCount } from "@/lib/notifications/server";

export async function GET(req: Request) {
  const t0 = Date.now();
  let projectId: string | null = null;
  try {
    const url = new URL(req.url);
    projectId = url.searchParams.get("project_id");
    const limitRaw = url.searchParams.get("limit");
    const limit = limitRaw ? Math.min(Math.max(1, parseInt(limitRaw, 10) || 50), 200) : 50;
    const includeDismissed = url.searchParams.get("include_dismissed") === "true";

    const [notifications, unread] = await Promise.all([
      fetchNotifications({ projectId, limit, includeDismissed }),
      fetchUnreadCount(projectId),
    ]);

    console.log(`[api:notifications] GET 200 projectId=${projectId ?? "all"} count=${notifications.length} unread=${unread} ${Date.now() - t0}ms`);
    return NextResponse.json({ notifications, unread });
  } catch (err) {
    console.error(`[api:notifications] GET 500 projectId=${projectId ?? "all"} ${Date.now() - t0}ms`, err);
    return NextResponse.json({ error: "internal" }, { status: 500 });
  }
}
