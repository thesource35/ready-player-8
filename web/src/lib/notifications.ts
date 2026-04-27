// Phase 14 + Phase 30 — Client-side + shared notifications helpers.
//
// 999.5 (k) cleanup: server-side functions (fetchNotifications, fetchUnreadCount,
// markRead, dismiss, markAllRead, fetchProjectActivity, fetchProjectMembershipsWithUnread)
// moved to @/lib/notifications/server. They use createServerSupabase() which
// transitively imports next/headers and must NOT be loaded by Client Components.
// Pure-data exports for Client Components (LAST_FILTER_STORAGE_KEY,
// ProjectMembershipUnread type) live in @/lib/notifications/shared-client.
//
// This file is safe to import from anywhere — Server Components, Client
// Components, API routes, tests. It does NOT import from supabase/server.

import { createClient } from "@supabase/supabase-js";
import type { Notification, ActivityEvent } from "./supabase/types";

// ---------- Mock fallback ----------
// When Supabase is not configured (no URL / no key), every server helper
// returns these demo rows so the UI renders something useful for screenshots
// and dev. The mock arrays themselves are safe for client + server.

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

// ---------- Shared types ----------

export type NotificationListOptions = {
  projectId?: string | null;
  limit?: number;
  includeDismissed?: boolean;
};

// ---------- Pure helpers (safe for client + server) ----------

/** Display string for badges — caps at "99+" per D-13. */
export function formatBadge(count: number): string {
  if (count <= 0) return "";
  if (count > 99) return "99+";
  return String(count);
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

// ---------- Phase 30: project-filter picker shared exports (D-06..D-11) ----------

// LAST_FILTER_STORAGE_KEY + ProjectMembershipUnread live in shared-client.ts.
// Re-exported here for convenience; safe for both client and server consumers
// because shared-client.ts has zero Supabase imports.
export {
  LAST_FILTER_STORAGE_KEY,
  type ProjectMembershipUnread,
} from "./notifications/shared-client";

import type { ProjectMembershipUnread } from "./notifications/shared-client";

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
