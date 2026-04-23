---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 01
subsystem: ui
tags: [nextjs, react-19, server-actions, vitest, notifications, supabase]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: markRead / markAllRead server helpers, cs_notifications RLS, /inbox server-component layout
  - phase: 28-retroactive-verification-sweep
    provides: NOTIF-03 Unsatisfied verdict that scoped this fix

provides:
  - Server Action path for per-row READ on /inbox (D-01)
  - Server Action path for MARK ALL READ on /inbox (D-02)
  - vitest regression lock on both actions (D-04)
  - Byte-preserved REST PATCH/DELETE/POST surface for iOS + programmatic callers (D-03)

affects:
  - Phase 30-02 (iOS InboxView picker) — page header layout is Server-Action-form-shaped, ready for picker insertion
  - Phase 30 verification (30-09) — NOTIF-03 has code evidence to flip to Satisfied
  - Any future /inbox UI work — Server Action pattern established as the canonical mutation path

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "React 19 <form action={serverActionFn}> for server component mutation (D-01/D-02)"
    - "vi.hoisted() pattern for vitest mock references shared across vi.mock() factories"
    - "Separate actions.ts co-located with page.tsx (Claude's Discretion from CONTEXT)"

key-files:
  created:
    - web/src/app/inbox/actions.ts
    - web/src/lib/notifications/markReadAction.test.ts
    - web/src/lib/notifications/markAllReadAction.test.ts
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-01-VERIFICATION.md
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/deferred-items.md
  modified:
    - web/src/app/inbox/page.tsx

key-decisions:
  - "Server Actions live in a separate co-located actions.ts (not inline in page.tsx) — keeps the server-component JSX readable and makes the actions importable by tests via @/app/inbox/actions"
  - "revalidatePath('/inbox') always runs after the underlying mutation — even if markRead returns false — because the page re-render will correctly reflect whatever row-state is authoritative in DB"
  - "Empty/whitespace id is treated as a silent no-op rather than an error — matches the notifications.ts helper contract and avoids throwing from a form submission path"
  - "Empty-string project_id coerced to null so markAllRead applies unfiltered mark-all (matches D-12 filter-aware semantics)"

patterns-established:
  - "Server Action pattern: <form action={serverAction}><input type='hidden' name='...'/>...</form> — replaces the POST + ?_method override kludge across the /inbox surface"
  - "vi.hoisted() mock pattern for Server Action tests — makes vi.fn() references survive vi.mock() factory hoisting"
  - "REST route preservation pattern: D-03 lock preserves /api/* handlers byte-for-byte so non-browser callers (iOS, curl) keep their surface"

requirements-completed: [NOTIF-03]

# Metrics
duration: 18min
completed: 2026-04-23
---

# Phase 30 Plan 01: Server Action refactor for /inbox mark-read (NOTIF-03) Summary

**Per-row READ + MARK ALL READ on /inbox now run via React 19 Server Actions, killing the POST → `?_method=PATCH` kludge that silently 404'd; REST PATCH/DELETE handlers preserved byte-for-byte for iOS callers.**

## Performance

- **Duration:** 18 min
- **Started:** 2026-04-23T21:15:24Z
- **Completed:** 2026-04-23T21:33:29Z
- **Tasks:** 3/3
- **Files modified:** 1 (`page.tsx`); created: 5

## Accomplishments

- Closed NOTIF-03 on the web surface — the broken POST-to-PATCH button is replaced with a working `<form action={markReadAction}>` that mutates `cs_notifications.read_at` via the existing `markRead()` helper and triggers `revalidatePath('/inbox')`.
- Same Server Action pattern applied to MARK ALL READ, preserving Phase 14's D-12 filter-aware semantics (`project_id` hidden input flows through to `markAllRead(projectId)`).
- Added 8 vitest cases across two co-located test files that lock the regression surface so this can never silently break again — including the "missing id", "empty-string id", and "empty-string project_id" edge cases.
- Preserved the REST surface at `/api/notifications/[id]` (PATCH + DELETE) and `/api/notifications/mark-all-read` (POST) byte-for-byte, keeping D-03 intact for iOS + programmatic consumers.

## Task Commits

1. **Task 1: Write Server Action regression tests (RED)** — `9aabc1d` (test)
2. **Task 2: Create actions.ts + refactor inbox/page.tsx (GREEN)** — `80c7808` (feat)
3. **Task 3: Verify D-03 REST surface + full notifications suite** — `cbe2a14` (chore)

## Files Created/Modified

- `web/src/app/inbox/actions.ts` — Server Actions `markReadAction` + `markAllReadAction` with `revalidatePath('/inbox')`; top-level `"use server"` directive; imports `markRead`/`markAllRead` from `@/lib/notifications`
- `web/src/app/inbox/page.tsx` — Replaced both forms: MARK ALL READ now `<form action={markAllReadAction}>{projectId && <input name="project_id"/>}`; per-row READ now `<form action={markReadAction}><input name="id"/>`; zero remaining `_method` references (grep -c = 0); all inline styling preserved byte-identically; stays a Server Component (no `"use client"`)
- `web/src/lib/notifications/markReadAction.test.ts` — 4 vitest cases covering D-01 contract (call with id, revalidate, no-op on null id, no-op on empty-string id); uses `vi.hoisted()` for mock references
- `web/src/lib/notifications/markAllReadAction.test.ts` — 4 vitest cases covering D-02 contract (null default, project_id passthrough, revalidate, empty-string → null)
- `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-01-VERIFICATION.md` — Captures D-03 lock evidence, vitest 19/19 pass, ESLint clean
- `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/deferred-items.md` — Logs pre-existing Phase 29 tsc error on `live-feed/generate-suggestion.ts` (out of scope for 30-01)

## Decisions Made

| Decision | Rationale |
|---|---|
| Co-locate actions in `web/src/app/inbox/actions.ts` (vs inline in page.tsx) | CONTEXT §Claude's Discretion called this out; separate file keeps JSX readable and makes the action importable by tests via `@/app/inbox/actions` |
| Use `vi.hoisted()` for vitest mocks instead of top-level `const = vi.fn()` | `vi.mock` factories are hoisted to the top of the file; top-level `const` is not — references would be TDZ at hoist time. `vi.hoisted()` is Vitest's official pattern for this case (docs: https://vitest.dev/api/vi.html#vi-hoisted) |
| Always call `revalidatePath('/inbox')` after mutation, even if `markRead` returned false | The page will re-render with whatever is authoritative in the DB; no downside to revalidating, and keeps the Server Action side-effect predictable |
| Empty-string id is silent no-op (not throw) | Matches the existing helper contract and avoids throwing from a form submission path; tests lock both null and empty-string cases |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] vitest mock hoisting TDZ error**
- **Found during:** Task 2 (after first attempt at running tests against the new actions.ts)
- **Issue:** Plan-specified test template used `const markReadMock = vi.fn()` at module top-level and referenced it inside `vi.mock(..., () => ({...}))`. Because Vitest hoists `vi.mock` to the very top of the file (before any imports or declarations), the factory ran before `markReadMock` was initialized, producing `ReferenceError: Cannot access 'revalidatePathMock' before initialization`.
- **Fix:** Switched both test files to `vi.hoisted(() => ({ markReadMock: vi.fn(), ... }))` which is Vitest's official pattern for sharing references between the test body and hoisted mock factories. Tests went from "0 test" / "Failed Suites 2" to "8 passed".
- **Files modified:** `web/src/lib/notifications/markReadAction.test.ts`, `web/src/lib/notifications/markAllReadAction.test.ts`
- **Verification:** `npx vitest run src/lib/notifications/markReadAction.test.ts src/lib/notifications/markAllReadAction.test.ts` → 8/8 GREEN
- **Committed in:** `80c7808` (part of Task 2 commit)

**2. [Rule 2 - Critical requirement] Literal `_method` string remained in a comment**
- **Found during:** Task 2 (acceptance-criteria grep check)
- **Issue:** Plan acceptance criterion `grep -c "_method" web/src/app/inbox/page.tsx == 0` failed because my initial header comment said "the legacy POST -> ?_method=PATCH kludge is gone" — literally matching `_method`.
- **Fix:** Re-worded to "the legacy POST + HTTP-method-override kludge is gone" — preserves the explanatory intent without keeping the exact kludge string in the file. Acceptance criterion now passes.
- **Files modified:** `web/src/app/inbox/page.tsx`
- **Verification:** `grep -c "_method" web/src/app/inbox/page.tsx` → 0
- **Committed in:** `80c7808` (part of Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1× Rule 1 bug, 1× Rule 2 criterion satisfaction)
**Impact on plan:** Both auto-fixes were necessary for tests-pass / criteria-pass; neither expanded scope. Final shipped output is semantically identical to the plan intent.

## Issues Encountered

- **Pre-existing tsc error in `web/src/lib/live-feed/generate-suggestion.ts:154`** — `TS2741: Property 'imageUrl' is missing in type 'ProjectContext' but required in type 'VisionPromptInput'`. Confirmed on main via `git stash` → `npx tsc --noEmit` → `git stash pop` round-trip. Not introduced or touched by Phase 30-01; logged to `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/deferred-items.md` as a Phase 29 follow-up. Phase 30-01 itself adds zero new tsc errors.

## Auth Gates

None encountered.

## User Setup Required

None — this plan is entirely a code-level refactor. No environment variables, no external service configuration, no provisioning steps.

## Threat Flags

None — the mutation surface is the same cs_notifications table, the same `markRead`/`markAllRead` helpers, and the same RLS policies from Phase 03. Server Actions are module-scoped so Next.js 16's encrypted action IDs + same-site cookie enforcement provide CSRF protection by default (T-30-01-02 mitigation inherited from framework).

## Known Stubs

None.

## Next Phase Readiness

**Ready for Plan 30-02 (iOS Inbox project-filter picker) and beyond.** The web `/inbox/page.tsx` header is now a simple flex row with a `<form action={markAllReadAction}>` on the right — any future picker insertion (D-06 web parity in a later plan) has a clean layout to slot into.

**Ready for Plan 30-09 (phase verification).** NOTIF-03 now has code evidence (commit `80c7808` + SUMMARY line "MARK ALL READ on /inbox runs via Server Action") sufficient to flip the requirement from Unsatisfied to Satisfied in REQUIREMENTS.md.

**No blockers.** REST surface at `/api/notifications/[id]` and `/api/notifications/mark-all-read` is byte-preserved (D-03 verified in 30-01-VERIFICATION.md); iOS `NotificationsStore` continues to hit the same REST endpoints it always has.

## Self-Check: PASSED

- [x] `web/src/app/inbox/actions.ts` exists — FOUND
- [x] `web/src/app/inbox/page.tsx` modified — FOUND (zero `_method` refs, 1 import from `./actions`, 1 `action={markAllReadAction}`, 1 `action={markReadAction}`)
- [x] `web/src/lib/notifications/markReadAction.test.ts` exists — FOUND
- [x] `web/src/lib/notifications/markAllReadAction.test.ts` exists — FOUND
- [x] Task 1 commit `9aabc1d` exists in git log — FOUND
- [x] Task 2 commit `80c7808` exists in git log — FOUND
- [x] Task 3 commit `cbe2a14` exists in git log — FOUND
- [x] Full notifications vitest suite: 5 files, 19 tests, all GREEN
- [x] D-03 REST surface: PATCH=1, DELETE=1, POST=1 (byte-preserved)
- [x] ESLint on all 4 touched files: exit 0

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Completed: 2026-04-23*
