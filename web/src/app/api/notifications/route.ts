// Phase 14 — GET /api/notifications
// Returns the authenticated user's notification list with optional project filter.
// Also returns the unread count in the same payload to avoid a second round-trip.

import { NextResponse } from "next/server";
import { fetchNotifications, fetchUnreadCount } from "@/lib/notifications/server";

export async function GET(req: Request) {
  try {
    const url = new URL(req.url);
    const projectId = url.searchParams.get("project_id");
    const limitRaw = url.searchParams.get("limit");
    const limit = limitRaw ? Math.min(Math.max(1, parseInt(limitRaw, 10) || 50), 200) : 50;
    const includeDismissed = url.searchParams.get("include_dismissed") === "true";

    const [notifications, unread] = await Promise.all([
      fetchNotifications({ projectId, limit, includeDismissed }),
      fetchUnreadCount(projectId),
    ]);

    return NextResponse.json({ notifications, unread });
  } catch (err) {
    console.error("[api/notifications] GET error:", err);
    return NextResponse.json({ error: "internal" }, { status: 500 });
  }
}
