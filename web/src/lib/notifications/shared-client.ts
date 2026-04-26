// Phase 14 — Notifications shared types + constants safe for Client Components.
//
// This file MUST NOT import from `../supabase/server` (which uses next/headers
// and is server-only). It exists so Client Components — notably
// `src/app/inbox/InboxProjectPicker.tsx` — can pull in `LAST_FILTER_STORAGE_KEY`
// and the `ProjectMembershipUnread` type without dragging the server-only
// notifications.ts module into the client bundle.
//
// Server-side consumers should keep importing from `@/lib/notifications`.

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
