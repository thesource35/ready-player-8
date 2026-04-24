# Phase 30 Notifications Parity Spec

**Authoritative for D-13 / D-14 / D-15.**
**Consumers:** web + iOS notification surfaces.
**Status:** locked 2026-04-22.

This spec is the single source of truth for how the header bell badge, the `/inbox` page sub-count, and the `MARK ALL READ` action relate to the user's active project filter. Phase 14 D-12 shipped the filter-aware mark-all-read at the API level; the picker UIs landed in 30-02 (iOS) and 30-03 (web). This document freezes the resulting semantics so future refactors can't drift.

---

## §Canonical Unread-Count Query

```sql
-- canonical.sql
-- canonical unread count (cap "99+" at render time)
SELECT COUNT(*) FROM cs_notifications
WHERE user_id = :me
  AND read_at IS NULL
  AND dismissed_at IS NULL;
```

Both platforms MUST issue this query (or an HTTP `HEAD` + `Prefer: count=exact` equivalent) for the header bell badge. No `project_id` predicate. The same query with an added `AND project_id = :filter` serves the `/inbox` sub-count when a filter is active.

Reference implementations (byte-preserved as of 2026-04-22):

- **Web:** `web/src/lib/notifications.ts` `fetchUnreadCount(projectId?)` — PostgREST `HEAD` with `count=exact` prefer header + `.is('read_at', null).is('dismissed_at', null)`; bell consumer (`HeaderBell.tsx`) calls `/api/notifications?limit=1` with NO `project_id` query-string param.
- **iOS:** `ready player 8/SupabaseService.swift` `fetchUnreadCount(userId:projectId:)` — REST `HEAD` to `cs_notifications?select=id&user_id=eq.<uid>&read_at=is.null&dismissed_at=is.null`; bell consumer (`NotificationsStore.displayBadge`) passes `projectId: nil`.

---

## §Scope Contract Table

| Consumer | project_id predicate | Shown As |
| --- | --- | --- |
| Header bell (web `HeaderBell.tsx` + iOS `HeaderView` bell via `NotificationsStore.displayBadge`) | NEVER applied | "99+" cap, empty at 0 |
| Inbox page sub-count `"{N} unread of {M}"` | WHEN filter active | raw integer both sides |
| Inbox `MARK ALL READ` action | WHEN filter active | operates on same rowset |

Rationale: the bell is an "attention tax" across the whole app; scoping it to the current filter would hide unread items the user hasn't switched to yet. The sub-count, by contrast, describes the current view; scoping it to the filter matches what the user visually sees in the list below.

---

## §Display Cap Rules

- `unreadCount <= 0` → `""` (empty / hidden — do NOT render the badge node at all, not even "0")
- `1 <= unreadCount <= 99` → `String(unreadCount)` (e.g. `"1"`, `"42"`, `"99"`)
- `unreadCount >= 100` → `"99+"`
- Applied identically by `formatBadge` (web — `web/src/lib/notifications.ts` line 160) + `NotificationsStore.formatBadge` (iOS — `ready player 8/NotificationsStore.swift`).

The 99+ cap protects layout: a raw `"12345"` badge overflows the 16px circle and can push header controls out of alignment. Both platforms must cap at exactly 100 (i.e. `99` renders as `"99"`, `100` renders as `"99+"`).

---

## §Mark-All-Read Scope Contract

- **With active filter:** `UPDATE cs_notifications SET read_at = now() WHERE user_id = :me AND project_id = :filter AND read_at IS NULL AND dismissed_at IS NULL`
- **Without filter:** `UPDATE cs_notifications SET read_at = now() WHERE user_id = :me AND read_at IS NULL AND dismissed_at IS NULL`
- Bell badge re-fetches after mark-all (Realtime/polling tick, not push from action) — the canonical query §Canonical Unread-Count Query returns the post-update count naturally; no separate invalidation hook is needed.
- NEVER marks rows from a project the user is no longer a member of (RLS short-circuits at `cs_notifications.user_id = auth.uid()` + `cs_project_members`; defense-in-depth — no app-level re-check needed).
- iOS: the PATCH query string is built by the SINGLE source of truth `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` (internal static). XCTests call this same function via `@testable import ready_player_8`. No mirror lives in the test target — Phase 14 taught us that test-side mirrors drift.

---

## §Regression Coverage

- `web/src/lib/notifications/markAllReadFilterScoped.test.ts` — asserts `.eq('project_id', id)` is invoked when filter passed and absent when not; asserts update payload is `{ read_at }` only; asserts signed-out path returns 0 without touching `.update()`.
- `web/src/lib/notifications/bellBadge99Cap.test.ts` — 5 `formatBadge` cases covering 0 / negative / 99 / 100 / 501.
- `ready player 8Tests/NotificationsStoreTests.swift` — 5 D-15 `formatBadge` cap cases + 1 D-13 case calling the real `SupabaseService.buildMarkAllReadQueryString` via `@testable import`.
- `ready player 8Tests/InboxViewTests.swift` — inbox sub-count string-format parity per §Scope Contract Table.

Any future regression that removes the 99+ cap, drops the project_id predicate on filter-active mark-all, adds a project_id predicate to the bell badge fetch, or reintroduces an XCTest mirror of the query-string builder fails CI before reaching users.

---

## §Non-Goals

Not revisited here: `read_at` / `dismissed_at` write semantics (Phase 14 D-10 / D-11 canonical), Realtime channel name (Phase 14 D-08 + Plan 30-05 iOS port), APNs push gating (Phase 14 D-16).
