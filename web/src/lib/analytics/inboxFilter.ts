// Phase 30 D-17 — inbox_filter_changed analytics event.
// Single call site used by the web InboxProjectPicker. PII-free by construction.
// See .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-CONTEXT.md §D-17.
//
// The payload is strictly {from_project_id, to_project_id, unread_count_at_change}. No PII keys
// of any kind — this mirrors the Phase 22 D-40 analytics contract that had to be scrubbed for
// PII leakage and the iOS AnalyticsEngine emit in NotificationsStore.

import { track } from "@vercel/analytics";

export const INBOX_FILTER_CHANGED_EVENT = "inbox_filter_changed" as const;

export type InboxFilterChangedPayload = {
  from_project_id: string; // UUID or "all"
  to_project_id: string; // UUID or "all"
  unread_count_at_change: number;
};

/**
 * Pure builder — returns the payload object, no side effects.
 * Null inputs serialize to the literal "all" sentinel (matches iOS parity + D-17).
 * Negative unread counts clamp to 0; non-integer counts floor to an Int.
 * Exposed separately so vitest can assert the shape without mocking the analytics transport.
 */
export function sanitizeInboxFilterPayload(
  from: string | null,
  to: string | null,
  unreadCountAtChange: number,
): InboxFilterChangedPayload {
  const raw = Number.isFinite(unreadCountAtChange) ? unreadCountAtChange : 0;
  return {
    from_project_id: from ?? "all",
    to_project_id: to ?? "all",
    unread_count_at_change: Math.max(0, Math.floor(raw)),
  };
}

/**
 * Fire the event. Called from InboxProjectPicker onChange (diff-driven only).
 * Caller is responsible for the diff-check (from !== to) so we don't emit no-ops.
 */
export function emitInboxFilterChanged(
  from: string | null,
  to: string | null,
  unreadCountAtChange: number,
): void {
  const payload = sanitizeInboxFilterPayload(from, to, unreadCountAtChange);
  track(
    INBOX_FILTER_CHANGED_EVENT,
    payload as unknown as Record<string, string | number>,
  );
}
