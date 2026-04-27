// Phase 14 + Phase 30 — Server-only notifications helpers (RSC + API routes).
//
// This module uses createServerSupabase() which transitively imports
// next/headers, so it must NEVER be loaded into a Client Component bundle.
// The `import "server-only"` marker below makes Next.js throw a build-time
// error if any Client Component touches this file (directly or transitively).
//
// Client-side helpers (subscribeToOwnNotifications, formatBadge, MOCK_*,
// resolveStalePickerFilter, types) live in @/lib/notifications.
// Pure-data exports for Client Components live in @/lib/notifications/shared-client.
//
// 999.5 (k) cleanup of the surgical 50203a0 boundary fix — splits the file
// into proper client/server halves rather than relying on the single shared-
// client extraction.

import "server-only";

import { createServerSupabase } from "../supabase/server";
import type { Notification, ActivityEvent } from "../supabase/types";
import {
  MOCK_NOTIFICATIONS,
  MOCK_ACTIVITY,
  type NotificationListOptions,
} from "../notifications";
import type { ProjectMembershipUnread } from "./shared-client";

// ---------- Server-side helpers (RSC + API routes) ----------

const HOURS_AGO = (h: number) => new Date(Date.now() - h * 3600 * 1000).toISOString();

/** Returns notifications for the authenticated user. Empty if not signed in. */
export async function fetchNotifications(
  opts: NotificationListOptions = {}
): Promise<Notification[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return MOCK_NOTIFICATIONS;

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  let q = supabase
    .from("cs_notifications")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(opts.limit ?? 50);

  if (!opts.includeDismissed) q = q.is("dismissed_at", null);
  if (opts.projectId) q = q.eq("project_id", opts.projectId);

  const { data, error } = await q;
  if (error) {
    console.error("[notifications] fetch error:", error.message);
    return [];
  }
  return (data as Notification[]) ?? [];
}

/** Returns the current user's unread count, or 0. Cheap server-side count. */
export async function fetchUnreadCount(projectId?: string | null): Promise<number> {
  const supabase = await createServerSupabase();
  if (!supabase) {
    return MOCK_NOTIFICATIONS.filter((n) => !n.read_at && !n.dismissed_at).length;
  }

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return 0;

  let q = supabase
    .from("cs_notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .is("read_at", null)
    .is("dismissed_at", null);
  if (projectId) q = q.eq("project_id", projectId);

  const { count, error } = await q;
  if (error) {
    console.error("[notifications] unread count error:", error.message);
    return 0;
  }
  return count ?? 0;
}

/** Mark a single notification as read. Returns true on success. */
export async function markRead(id: string): Promise<boolean> {
  const supabase = await createServerSupabase();
  if (!supabase) return true; // mock mode succeeds silently

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return false;

  const { error } = await supabase
    .from("cs_notifications")
    .update({ read_at: new Date().toISOString() })
    .eq("id", id)
    .eq("user_id", user.id);
  if (error) {
    console.error("[notifications] markRead error:", error.message);
    return false;
  }
  return true;
}

/** Soft-delete a notification. Returns true on success. */
export async function dismiss(id: string): Promise<boolean> {
  const supabase = await createServerSupabase();
  if (!supabase) return true;

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return false;

  const { error } = await supabase
    .from("cs_notifications")
    .update({ dismissed_at: new Date().toISOString() })
    .eq("id", id)
    .eq("user_id", user.id);
  if (error) {
    console.error("[notifications] dismiss error:", error.message);
    return false;
  }
  return true;
}

/**
 * Mark all notifications read for the current user. If projectId is provided,
 * only that project's notifications are marked (D-12: respects current filter).
 * Returns the number of rows touched.
 */
export async function markAllRead(projectId?: string | null): Promise<number> {
  const supabase = await createServerSupabase();
  if (!supabase) return 0;

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return 0;

  let q = supabase
    .from("cs_notifications")
    .update({ read_at: new Date().toISOString() }, { count: "exact" })
    .eq("user_id", user.id)
    .is("read_at", null)
    .is("dismissed_at", null);
  if (projectId) q = q.eq("project_id", projectId);

  const { error, count } = await q;
  if (error) {
    console.error("[notifications] markAllRead error:", error.message);
    return 0;
  }
  return count ?? 0;
}

/** Activity timeline for a project. Returns mock data when Supabase is missing. */
export async function fetchProjectActivity(
  projectId: string,
  limit = 100
): Promise<ActivityEvent[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return MOCK_ACTIVITY;

  const { data, error } = await supabase
    .from("cs_activity_events")
    .select("*")
    .eq("project_id", projectId)
    .order("created_at", { ascending: false })
    .limit(limit);
  if (error) {
    console.error("[notifications] activity fetch error:", error.message);
    return [];
  }
  return (data as ActivityEvent[]) ?? [];
}

// Mock picker rows — parity with the iOS MOCK_MEMBERSHIPS from Phase 30-02 so
// the /inbox dropdown has something to render in mock mode (no Supabase env).
const MOCK_MEMBERSHIPS: ProjectMembershipUnread[] = [
  { project_id: "mock-project-1", project_name: "Civic Center Phase 2", unread_count: 2, latest_created_at: HOURS_AGO(2) },
  { project_id: "mock-project-2", project_name: "Oak St Retrofit", unread_count: 0, latest_created_at: HOURS_AGO(28) },
];

/**
 * Returns the signed-in user's project memberships with per-project unread counts.
 * D-07 source: cs_project_members JOIN cs_projects. Mock fallback when unconfigured.
 * Non-fatal on error — logs and returns [] so /inbox still renders.
 */
export async function fetchProjectMembershipsWithUnread(): Promise<ProjectMembershipUnread[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return MOCK_MEMBERSHIPS;

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data: members, error: memErr } = await supabase
    .from("cs_project_members")
    .select("project_id, cs_projects(id, name)")
    .eq("user_id", user.id);

  if (memErr) {
    console.error("[notifications] memberships error:", memErr.message);
    return [];
  }

  // Enrich each membership with unread count + latest created_at in parallel
  // (T-30-03-05 accepted: memberships ≤ 20 typical; no N+1 concern at this scale).
  // Supabase PostgREST inference types embedded resources as an array (or null) —
  // we grab index 0 since cs_projects.id is the one-to-one FK target.
  type MembershipRow = { project_id: string; cs_projects: { id: string; name: string | null }[] | { id: string; name: string | null } | null };
  const results = await Promise.all(
    ((members ?? []) as MembershipRow[]).map(async (row) => {
      const proj = Array.isArray(row.cs_projects) ? row.cs_projects[0] ?? null : row.cs_projects;
      const pid = proj?.id ?? row.project_id;
      const pname = proj?.name ?? pid;

      const [{ count: unreadCount }, { data: latestRows }] = await Promise.all([
        supabase
          .from("cs_notifications")
          .select("id", { count: "exact", head: true })
          .eq("user_id", user.id)
          .eq("project_id", pid)
          .is("read_at", null)
          .is("dismissed_at", null),
        supabase
          .from("cs_notifications")
          .select("created_at")
          .eq("user_id", user.id)
          .eq("project_id", pid)
          .order("created_at", { ascending: false })
          .limit(1),
      ]);

      return {
        project_id: pid,
        project_name: pname,
        unread_count: unreadCount ?? 0,
        latest_created_at: (latestRows?.[0] as { created_at?: string } | undefined)?.created_at ?? null,
      };
    })
  );
  return results;
}
