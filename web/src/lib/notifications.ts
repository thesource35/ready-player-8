// Phase 14 — Notifications client + server helpers
// Server-side: uses createServerSupabase() (cookie-bound auth)
// Client-side: uses raw createClient() with anon key for Realtime + lightweight reads

import { createClient } from "@supabase/supabase-js";
import { createServerSupabase } from "./supabase/server";
import type { Notification, ActivityEvent } from "./supabase/types";

// ---------- Mock fallback ----------
// When Supabase is not configured (no URL / no key), every helper returns
// these demo rows so the UI renders something useful for screenshots and dev.

const NOW = () => new Date().toISOString();
const HOURS_AGO = (h: number) => new Date(Date.now() - h * 3600 * 1000).toISOString();

export const MOCK_NOTIFICATIONS: Notification[] = [
  {
    id: "mock-n-1",
    user_id: "mock-user",
    event_id: "mock-e-1",
    project_id: "mock-project-1",
    category: "bid_deadline",
    title: "Bid deadline approaching",
    body: "contracts: Civic Center Phase 2 — due in 1 day",
    entity_type: "cs_contracts",
    entity_id: "mock-contract-1",
    read_at: null,
    dismissed_at: null,
    created_at: HOURS_AGO(2),
  },
  {
    id: "mock-n-2",
    user_id: "mock-user",
    event_id: "mock-e-2",
    project_id: "mock-project-1",
    category: "safety_alert",
    title: "Safety alert",
    body: "safety_incidents: Near-miss reported on Level 4",
    entity_type: "cs_safety_incidents",
    entity_id: "mock-incident-1",
    read_at: null,
    dismissed_at: null,
    created_at: HOURS_AGO(5),
  },
  {
    id: "mock-n-3",
    user_id: "mock-user",
    event_id: "mock-e-3",
    project_id: "mock-project-2",
    category: "assigned_task",
    title: "New assignment",
    body: "rfis: RFI-042 assigned to you",
    entity_type: "cs_rfis",
    entity_id: "mock-rfi-42",
    read_at: HOURS_AGO(20),
    dismissed_at: null,
    created_at: HOURS_AGO(28),
  },
];

export const MOCK_ACTIVITY: ActivityEvent[] = [
  {
    id: "mock-e-1",
    project_id: "mock-project-1",
    entity_type: "cs_contracts",
    entity_id: "mock-contract-1",
    action: "update",
    category: "bid_deadline",
    actor_id: null,
    payload: { contract_name: "Civic Center Phase 2", days_out: 1 },
    created_at: HOURS_AGO(2),
  },
  {
    id: "mock-e-2",
    project_id: "mock-project-1",
    entity_type: "cs_safety_incidents",
    entity_id: "mock-incident-1",
    action: "insert",
    category: "safety_alert",
    actor_id: "mock-other-user",
    payload: { description: "Near-miss reported on Level 4" },
    created_at: HOURS_AGO(5),
  },
  {
    id: "mock-e-4",
    project_id: "mock-project-1",
    entity_type: "cs_daily_logs",
    entity_id: "mock-log-1",
    action: "insert",
    category: "generic",
    actor_id: "mock-other-user",
    payload: { date: NOW(), manpower: 12 },
    created_at: HOURS_AGO(8),
  },
];

// ---------- Server-side helpers (RSC + API routes) ----------

export type NotificationListOptions = {
  projectId?: string | null;
  limit?: number;
  includeDismissed?: boolean;
};

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

/** Display string for badges — caps at "99+" per D-13. */
export function formatBadge(count: number): string {
  if (count <= 0) return "";
  if (count > 99) return "99+";
  return String(count);
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

// ---------- Client-side: Realtime subscription for the header bell ----------
// Returns a cleanup function (unsubscribe), or null if Supabase not configured.

export function subscribeToOwnNotifications(
  userId: string,
  onChange: () => void
): (() => void) | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key =
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;

  const client = createClient(url, key);
  const channel = client
    .channel(`cs_notifications:${userId}`)
    .on(
      "postgres_changes",
      {
        event: "*",
        schema: "public",
        table: "cs_notifications",
        filter: `user_id=eq.${userId}`,
      },
      () => onChange()
    )
    .subscribe();

  return () => {
    channel.unsubscribe();
    client.removeChannel(channel);
  };
}

// ---------- Phase 30: project-filter picker helpers (D-06..D-11) ----------

/**
 * localStorage key for the /inbox project-filter picker (D-10). Mirrors the iOS
 * AppStorage key `ConstructOS.Notifications.LastFilterProjectId` by intent — both
 * platforms persist the last-selected project id per device.
 */
export const LAST_FILTER_STORAGE_KEY = "constructos.notifications.last_filter_project_id";

export type ProjectMembershipUnread = {
  project_id: string;
  project_name: string;
  unread_count: number;
  latest_created_at: string | null;
};

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

/**
 * D-11: if persistedId is not in the current memberships, return null (caller
 * should wipe localStorage). Otherwise return the id unchanged.
 */
export function resolveStalePickerFilter(
  persistedId: string | null,
  memberships: ProjectMembershipUnread[]
): string | null {
  if (!persistedId) return null;
  const ids = new Set(memberships.map((m) => m.project_id));
  return ids.has(persistedId) ? persistedId : null;
}
