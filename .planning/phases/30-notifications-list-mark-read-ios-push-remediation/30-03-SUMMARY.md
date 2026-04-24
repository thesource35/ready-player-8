---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 03
subsystem: ui
tags: [typescript, nextjs, react, vitest, notifications, supabase, web]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: fetchNotifications server helper + /inbox Server Component + ?project_id= searchParam handling
  - phase: 30-notifications-list-mark-read-ios-push-remediation
    provides: 30-01 Server Actions (markReadAction, markAllReadAction) in web/src/app/inbox/actions.ts; 30-02 iOS picker UX contract (All Projects pinned + unread-desc-then-latest sort + accent chip badges)

provides:
  - fetchProjectMembershipsWithUnread() — server helper querying cs_project_members JOIN cs_projects + parallel per-project unread count (HEAD) + latest_created_at (D-07/D-08)
  - resolveStalePickerFilter() — D-11 pure function rejecting persisted ids not in current memberships
  - LAST_FILTER_STORAGE_KEY = "constructos.notifications.last_filter_project_id" — D-10 cross-platform parity contract
  - InboxProjectPicker.tsx — client component with "All Projects" pinned, D-09 sorted rows, unread chips, router.push navigation, localStorage persist, mount-time rehydrate + stale recovery
  - /inbox page.tsx filter-aware sub-count + empty-state copy (D-12) + picker mount in header flex row
  - vitest regression coverage: projectMemberships.test.ts (5 cases) + inboxFilterStorage.test.ts (1 case)

affects:
  - Phase 30-04 (filter-scoped mark-all on web) — picker is the canonical filter surface; 30-04 operates against the ?project_id= query param already honored by markAllReadAction
  - Phase 30-06 (inbox_filter_changed analytics) — InboxProjectPicker.onPick is the single write point where analytics can hook (D-17 parity with iOS setFilter callsite)
  - Phase 30-09 (acceptance evidence bundle) — grep evidence for LAST_FILTER_STORAGE_KEY cross-platform parity now available on web side

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server Component Promise.all for independent fetches (notifications + memberships) to eliminate waterfall"
    - "Client-component mount-time rehydrate + stale-recovery pattern: useEffect reads localStorage on first render, silently router.replace for recovery (no error toast) — mirrors iOS NotificationsStore.start(userId:) staleFilter flow from 30-02"
    - "Inline style={} + shared rowStyle(active: boolean) helper instead of Tailwind (matches Phase 27 /map page + /inbox existing visual language)"
    - "PostgREST embedded-resource type coercion: Supabase's cs_projects join returns { id, name }[] | { id, name } | null depending on relationship cardinality inference — MembershipRow type handles both shapes via Array.isArray guard"

key-files:
  created:
    - web/src/app/inbox/InboxProjectPicker.tsx
    - web/src/lib/notifications/projectMemberships.test.ts
    - web/src/lib/notifications/inboxFilterStorage.test.ts
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-03-SUMMARY.md
  modified:
    - web/src/lib/notifications.ts
    - web/src/app/inbox/page.tsx

key-decisions:
  - "localStorage (not cookie) for D-10 persistence — same-tab responsiveness wins; cookie would require a server-round-trip for filter changes and introduce revalidate churn. Chosen over cookie per plan's `<objective>` explicit guidance"
  - "Embedded-resource coercion via MembershipRow union type (array | object | null) rather than disabling tsc strict on the Supabase query — keeps the rest of the file under strict mode; Array.isArray guard is idiomatic"
  - "Promise.all in /inbox page.tsx for notifications + memberships — saves one round-trip on every render; memberships already RLS-gated so no extra auth cost"
  - "Picker mount position BEFORE the mark-all form (not after) — puts the filter control next to the title it modifies, leaves the destructive action rightmost; matches iOS toolbar order (picker leading, Mark All Read trailing)"
  - "Accepted the plan's single-line `export async function fetchProjectMembershipsWithUnread` (grep yields 1) over the plan-text's implied ≥ 2 — TypeScript's single-line combined export+def satisfies the `definition + export` intent without redundant re-export lines. Same pattern for resolveStalePickerFilter. Documented here as a benign deviation from the literal grep threshold; semantic coverage is identical"
  - "Left unrelated pre-existing working-tree edits (19-*/21-* plan files, supabase/.temp/cli-latest) untouched per CLAUDE.md file-scope discipline — Phase 30-03 commits are scoped to web/src/{app/inbox,lib/notifications*}"

patterns-established:
  - "Same-tab filter rehydrate pattern: client component reads localStorage in useEffect, router.replace for URL sync on mount, router.push for user-initiated changes — works for any future filter persistence in the app (/projects page, /contracts page, etc.)"
  - "Cross-platform storage-key parity lock via two-file test fingerprint: one file asserts the frozen string constant (inboxFilterStorage.test.ts on web, the hardcoded @AppStorage key on iOS NotificationsStoreTests.swift from Phase 30-02) — future key renames are caught on both platforms simultaneously"

requirements-completed: [NOTIF-01]

# Metrics
duration: 61min
completed: 2026-04-23
---

# Phase 30 Plan 03: Web Inbox Project-Filter Picker Summary

**Web `/inbox` now has a project-filter dropdown mirroring the iOS Phase 30-02 toolbar Menu — "All Projects" pinned first, memberships sorted unread-desc-then-latest with accent-capsule unread chips, per-device filter persistence via `localStorage`, silent stale-id recovery on mount, and filter-aware empty-state copy. This closes the cross-platform parity clause of NOTIF-01 flagged in 14-04-SUMMARY.md §KL #3 ("currently URL-only; no dropdown UI built").**

## Performance

- **Duration:** 61 min (plan started 2026-04-23T22:38:03Z, completed 2026-04-23T23:39:04Z)
- **Tasks:** 2/2 executed and committed atomically
- **Files created:** 4 (InboxProjectPicker.tsx, 2 vitests, 30-03-SUMMARY.md); modified: 2 (notifications.ts, page.tsx)
- **Test suite:** 6 new vitest cases + full notifications suite 29/29 GREEN
- **Commits:** `f64ef8e` (Task 1), `451ce1d` (Task 2)

## Accomplishments

- **Task 1 (commit `f64ef8e`)** landed the server-side picker data path: `fetchProjectMembershipsWithUnread()` queries `cs_project_members` JOIN `cs_projects` with parallel HEAD-count + max-created_at enrichment per membership (≤20 typical per T-30-03-05), `resolveStalePickerFilter()` pure function for D-11 stale-recovery, `LAST_FILTER_STORAGE_KEY` frozen-string constant for cross-platform parity. 2 mock rows mirror the iOS `MOCK_MEMBERSHIPS` from 30-02 (Civic Center Phase 2 + Oak St Retrofit).
- **Task 2 (commit `451ce1d`)** landed the UI: `InboxProjectPicker.tsx` (185 LOC) renders an accessible accent-colored dropdown trigger with listbox, "All Projects" pinned, D-09 sorted membership rows with unread chips, click-outside close, keyboard-friendly aria attributes. `page.tsx` mounts the picker in the header flex row (before the 30-01 mark-all form), parallel-fetches memberships alongside notifications, branches the sub-count copy on active filter, and re-writes the empty state to the D-12 filter-aware copy with a "Show all projects" reset link.
- **TDD discipline observed** on Task 1: tests written first (6 failing cases confirmed RED), impl added (6 GREEN), single-commit because tests cannot even import symbols that don't exist — same pattern as the existing `markAllRead.test.ts` / `dismiss.test.ts` in this directory.
- **30-01 Server Action ownership byte-preserved:** `markReadAction` and `markAllReadAction` imports intact, form shapes (`<form action={markReadAction}>`, `<form action={markAllReadAction}>`) untouched — grep returns 3 occurrences (was 2 pre-Task-2; +1 from the markAllReadAction import line preserved across the edit). Regression check satisfied.

## Task Commits

1. **Task 1: TDD RED→GREEN — server helper + storage key + 6 vitest cases** — `f64ef8e` (feat)
2. **Task 2: InboxProjectPicker client component + page.tsx integration** — `451ce1d` (feat)

## Files Created/Modified

### From commit `f64ef8e` (Task 1)

- **`web/src/lib/notifications.ts`** — +100 lines appended: `LAST_FILTER_STORAGE_KEY` const, `ProjectMembershipUnread` type, `MOCK_MEMBERSHIPS` static (2 rows), `fetchProjectMembershipsWithUnread()` async helper with mock-mode fallback + signed-out zero-return + PostgREST embedded-resource type coercion + per-row parallel enrichment, `resolveStalePickerFilter()` pure function. Zero changes to existing exports (`fetchNotifications`, `markRead`, `markAllRead`, `formatBadge`, `subscribeToOwnNotifications`, etc.).
- **`web/src/lib/notifications/projectMemberships.test.ts`** (NEW) — 5 vitest cases locking the mock-mode row shape (4 properties asserted) + `resolveStalePickerFilter` behavior across 4 inputs (ghost id, null, empty-string, member hit).
- **`web/src/lib/notifications/inboxFilterStorage.test.ts`** (NEW) — 1 vitest case locking `LAST_FILTER_STORAGE_KEY === "constructos.notifications.last_filter_project_id"` as the cross-platform parity contract.

### From commit `451ce1d` (Task 2)

- **`web/src/app/inbox/InboxProjectPicker.tsx`** (NEW, 185 LOC) — `"use client"` React component. Props: `{ memberships: ProjectMembershipUnread[]; currentProjectId: string | null }`. `useEffect` mount hook handles D-10 rehydrate (URL empty + valid localStorage → `router.replace`) + D-11 stale recovery (URL id not in memberships → wipe + `router.replace('/inbox')`; persisted id not in memberships → wipe, no redirect). `useEffect` click-outside close. `onPick` callback: persist to localStorage, close dropdown, `router.push`. Inline-style dropdown with `aria-haspopup="listbox"` + `aria-expanded` + `aria-label`; rows rendered as `<button>` inside `<li>` with `role="listbox"` on parent `<ul>`. Sort function `sortMemberships` = unread desc + `latest_created_at` desc tiebreak (matches iOS `InboxView.membershipSort`). `rowStyle(active)` factored helper for the two visual states.
- **`web/src/app/inbox/page.tsx`** — 3 import additions (`fetchProjectMembershipsWithUnread` + `InboxProjectPicker`), 1 `Promise.all` swap for the notifications + memberships fetch, 1 `currentProjectName` lookup, 2 new wrapper `<div>` layouts (header flex row now has inner flex container for picker + mark-all form grouped on the right), sub-count copy now templates `currentProjectName` when filter active, empty-state branch replaced with the D-12 two-case render. 30-01 Server Action forms + imports untouched.

## Decisions Made

| Decision | Rationale |
|---|---|
| `localStorage` (not cookie) for D-10 persistence | Same-tab responsiveness, no server round-trip, no revalidate churn. Plan `<objective>` explicitly guided this choice: "chosen over cookie for same-tab responsiveness + Next.js 16 compat". iOS parity uses `@AppStorage` (UserDefaults), so both platforms store client-side. |
| Embedded-resource type coercion via `MembershipRow` union | Supabase PostgREST infers `cs_projects` as either array (many-to-one) or object (one-to-one) depending on FK cardinality hints; keeping `strict: true` required an `Array.isArray` guard rather than a cast-to-any. Zero runtime cost; idiomatic. |
| `Promise.all` for notifications + memberships fetch | Both are independent RLS-gated reads; parallelizing saves one round-trip on every `/inbox` render. |
| Picker mount BEFORE the mark-all form in the header | Places the filter control next to the title it modifies; leaves the destructive Mark All Read rightmost. Matches iOS toolbar order (picker leading, action trailing). |
| Single-line `export async function` satisfies the plan's implied `≥ 2` grep threshold | Plan text wrote "≥ 2 (definition + export)" because it templated with separate `export` lines + `async function`; TypeScript's single-line combined form is equivalent. Documented as a benign deviation from the literal grep count. Semantic coverage identical: symbol is both defined AND exported. |
| Only scoped files staged + committed | Working tree had pre-existing unrelated edits under `19-*`, `21-*`, and `supabase/.temp/cli-latest`. Per CLAUDE.md file-scope discipline and the GSD workflow's "never `git add -A`" rule, those were left untouched. |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] PostgREST embedded-resource type mismatch**
- **Found during:** Task 1 TSC verification after the initial impl edit landed.
- **Issue:** The plan's template typed `cs_projects` as `{ id: string; name: string | null } | null` (one-to-one). Supabase's generated types infer it as `{ id; name }[]` (array) because the FK inference defaults to the many-to-one side when cardinality hints are absent. TSC blocked the build.
- **Fix:** Introduced a local `MembershipRow` union type covering array-OR-object-OR-null, with `Array.isArray(row.cs_projects) ? row.cs_projects[0] ?? null : row.cs_projects` coercion at runtime. The rest of the file stays strict.
- **Files modified:** `web/src/lib/notifications.ts` (helper internals only; public signature unchanged)
- **Commit:** `f64ef8e` (folded into the single Task 1 commit)

### Plan-level deviations

**1. [Acceptance-criteria grep threshold] Single-line export accepted**
- Plan wrote `grep -c "fetchProjectMembershipsWithUnread" web/src/lib/notifications.ts` ≥ 2 and `grep -c "resolveStalePickerFilter"` ≥ 2, templating for two occurrences (e.g., `export function foo()` counted once; some plans split `function foo()` + `export { foo }` for two). My impl uses the single-line `export async function fetchProjectMembershipsWithUnread` and `export function resolveStalePickerFilter` — yielding grep count of 1 each in `notifications.ts`. Semantic intent (`definition + export`) fully satisfied on one line; no redundant re-export added. Documented here for traceability.

### Out-of-scope flagged

- `web/src/lib/live-feed/generate-suggestion.ts:154` continues to emit `TS2741: Property 'imageUrl' is missing in type 'ProjectContext'` during `tsc --noEmit`. Pre-existing, already logged in phase `deferred-items.md`, not introduced or touched by 30-03.

**Total deviations:** 1 Rule-1 auto-fix (embedded-resource type coercion); 1 plan-level (grep-threshold semantic equivalence accepted). No architectural changes; no new dependencies.

## Issues Encountered

- **TSC embedded-resource shape:** caught and fixed mid-Task-1 (Rule 1 auto-fix above). No propagation to downstream tasks.
- **Validator false positive on `params`:** the PostToolUse validator flagged `line 45: const projectId = params.project_id ?? null;` as needing `await params` — a stale pattern match; `params` is the already-awaited local from `const params = await searchParams;` one line above. No-op.

## Auth Gates

None encountered.

## User Setup Required

None — 30-03 is entirely code + tests. Manual UAT walk scheduled for 30-09 (phase acceptance bundle) will include `/inbox` dropdown interaction.

## Threat Flags

No new threat surface beyond the plan's `<threat_model>` table. All 5 disposed threats (T-30-03-01 through T-30-03-05) remain closed as planned:

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-30-03-01 (URL tampering `?project_id=`) | mitigate | Closed: `fetchNotifications` uses auth-bound Supabase client + `.eq("user_id", user.id)`; RLS final gate |
| T-30-03-02 (localStorage tampering) | mitigate | Closed: `resolveStalePickerFilter` + `useEffect` recovery branch wipes the key when persisted id is not in memberships |
| T-30-03-03 (memberships payload disclosure) | accept | Closed: payload only carries project_name for projects the user is already a member of |
| T-30-03-04 (CSRF via picker) | accept | Closed: navigation only; mutations (mark-read, mark-all) carry their own Server Action CSRF protection |
| T-30-03-05 (N+1 memberships) | mitigate | Closed: `Promise.all` fan-out over membership rows; typical ≤20 |

## Known Stubs

None. The picker renders real data paths end-to-end (mock-mode fallback for dev screenshots; RLS-gated live query for signed-in users).

## Next Phase Readiness

**Ready for Plan 30-04 (filter-scoped mark-all on web).** `InboxProjectPicker` is the canonical filter surface; the `?project_id=` query param already flows into `markAllReadAction`'s FormData via the hidden input. 30-04's scope (adding vitest evidence + iOS XCTest parity for the SQL `WHERE project_id = X` predicate on mark-all) has nothing to wire up here — the data path already exists.

**Ready for Plan 30-06 (inbox_filter_changed analytics).** `InboxProjectPicker.onPick` is the single write point for filter changes on web — analytics instrumentation is a one-line `track()` call at that callsite, matching iOS `NotificationsStore.setFilter` pattern from 30-02.

**Ready for Plan 30-09 (acceptance evidence bundle).** Grep evidence for `LAST_FILTER_STORAGE_KEY` cross-platform parity is now available: iOS `NotificationsStore.lastFilterKey` constant (from 30-02) + web `LAST_FILTER_STORAGE_KEY` (from 30-03) both freeze the same semantic value (`ConstructOS.Notifications.LastFilterProjectId` on iOS, `constructos.notifications.last_filter_project_id` on web — different casing per platform convention; equivalent intent).

**No blockers.** 30-01 Server Actions preserved (regression locked). REST surface unchanged. Existing /inbox behavior (mark-read, mark-all-read, category color system) byte-preserved outside the scoped header/empty-state edits.

## Self-Check: PASSED

- [x] `web/src/app/inbox/InboxProjectPicker.tsx` — FOUND (185 LOC, new)
- [x] `web/src/lib/notifications/projectMemberships.test.ts` — FOUND (5 cases)
- [x] `web/src/lib/notifications/inboxFilterStorage.test.ts` — FOUND (1 case)
- [x] `web/src/lib/notifications.ts` modifications — FOUND (+100 LOC appended, public signature unchanged)
- [x] `web/src/app/inbox/page.tsx` modifications — FOUND (imports + Promise.all + picker mount + D-12 empty state)
- [x] Task 1 commit `f64ef8e` — FOUND in `git log --oneline`
- [x] Task 2 commit `451ce1d` — FOUND in `git log --oneline`
- [x] Acceptance-criteria greps:
  - [x] `test -f web/src/app/inbox/InboxProjectPicker.tsx` → FILE_EXISTS
  - [x] `grep -c "\"use client\""` InboxProjectPicker.tsx = 1 (≥1 required)
  - [x] `grep -c "LAST_FILTER_STORAGE_KEY"` InboxProjectPicker.tsx = 6 (≥1 required)
  - [x] `grep -c "router\.push"` InboxProjectPicker.tsx = 1 (≥1 required)
  - [x] `grep -c "router\.replace"` InboxProjectPicker.tsx = 2 (≥1 required)
  - [x] `grep -c "All Projects"` InboxProjectPicker.tsx = 2 (≥1 required)
  - [x] `grep -c "<InboxProjectPicker"` page.tsx = 1 (≥1 required)
  - [x] `grep -c "Show all projects"` page.tsx = 1 (≥1 required)
  - [x] `grep -c "No notifications for "` page.tsx = 1 (≥1 required)
  - [x] `grep -c "fetchProjectMembershipsWithUnread"` page.tsx = 2 (≥1 required)
  - [x] `grep -c "markReadAction\|markAllReadAction"` page.tsx = 3 (≥2 regression required)
  - [x] `grep -c "fetchProjectMembershipsWithUnread"` notifications.ts = 1 (documented deviation: plan expected ≥2 with split export+def; single-line form satisfies the semantic intent)
  - [x] `grep -c "LAST_FILTER_STORAGE_KEY"` notifications.ts = 1 (≥1 required)
  - [x] `grep -c "\"constructos\.notifications\.last_filter_project_id\""` notifications.ts = 1 (≥1 required)
  - [x] `grep -c "resolveStalePickerFilter"` notifications.ts = 1 (documented deviation same as above)
- [x] `cd web && npx tsc --noEmit` — clean for inbox scope (only pre-existing unrelated live-feed error remains, documented in deferred-items.md)
- [x] `cd web && npx eslint src/app/inbox/page.tsx src/app/inbox/InboxProjectPicker.tsx` — exits 0
- [x] `cd web && npx vitest run src/lib/notifications/` — 29/29 GREEN (6 new cases + 23 existing; zero regressions)

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Completed: 2026-04-23*
