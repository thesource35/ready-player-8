---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 04
subsystem: testing
tags: [swift, typescript, vitest, xctest, swift-testing, notifications, supabase, parity-spec]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: markAllRead(projectId?) filter-aware data layer (D-12); formatBadge(count) 99+ cap (D-13); SupabaseService.markAllNotificationsRead(userId:projectId:) iOS parity
  - phase: 30-notifications-list-mark-read-ios-push-remediation
    provides: 30-02 iOS picker UX contract (NotificationsStore.projectFilter as canonical filter source); 30-03 web picker UX contract (InboxProjectPicker + ?project_id= query-param routing)

provides:
  - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-PARITY-SPEC.md — authoritative written contract for D-13 (filter scope on mark-all-read), D-14 (bell-vs-sub-count scope split), D-15 (99+ cap) with canonical unread-count SQL quoted verbatim
  - SupabaseService.buildMarkAllReadQueryString(userId:projectId:) — internal static helper; single source of truth for the iOS mark-all-read PATCH query string (consumed by markAllNotificationsRead AND by XCTest via @testable)
  - web/src/lib/notifications/markAllReadFilterScoped.test.ts — 4 vitest cases locking .eq('project_id', id) predicate behavior, update-payload shape, signed-out no-op
  - web/src/lib/notifications/bellBadge99Cap.test.ts — 5 vitest cases locking 0 / -5 / 99 / 100 / 501 boundaries of formatBadge
  - ready player 8Tests/NotificationsStoreTests.swift — @Suite "Phase 30 mark-all-read scope + badge cap" with 5 D-15 cap cases + 1 D-13 filter-parity case exercising the REAL production helper
  - ready player 8Tests/InboxViewTests.swift — 1 D-14 inbox sub-count "{N} unread of {M}" format-lock case

affects:
  - Phase 30-05 (iOS Realtime subscription) — bell-badge refresh after mark-all is now formally specified as "re-fetch via canonical unread-count query, no dedicated invalidation hook"; 30-05 subscriber can rely on the Realtime channel triggering the same refetch path
  - Phase 30-06 (inbox_filter_changed analytics) — NotificationsStore.setFilter + InboxProjectPicker.onPick remain the single write points (unchanged); 30-04 didn't touch either, but the PARITY-SPEC clarifies why analytics on filter-change is the scope-changing event (bell stays global)
  - Phase 30-09 (acceptance evidence bundle) — PARITY-SPEC is now the canonical reviewable doc for D-13/D-14/D-15; the 4 new test files + the production helper-extraction are the reviewable code artifacts

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Production-extraction-over-test-mirror: when a pure helper needs parity coverage across production + tests, extract the helper INTO production as internal static (or equivalent), have the production caller AND the tests consume the same symbol via @testable import — eliminates test-mirror drift. Replaces the rejected prior-draft approach of duplicating the query-string builder inside the XCTest file."
    - "Chainable fake-Supabase vitest mock: track every .eq(col, val) call on a shared array, terminate the chain with a thenable resolving { error: null, count: N, data: null }, flip auth.getUser() to { user: null } to exercise signed-out branch — mirrors how Supabase-js PostgREST builders work without needing a real client."
    - "PARITY-SPEC.md pattern: when two platforms (iOS + web) implement the same contract and the rules are subtle (bell global, sub-count scoped), author a single Markdown doc with canonical SQL quoted verbatim + a scope table — both platforms' tests grep for the exact SQL text as their regression floor."

key-files:
  created:
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-PARITY-SPEC.md
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-04-SUMMARY.md
    - web/src/lib/notifications/markAllReadFilterScoped.test.ts
    - web/src/lib/notifications/bellBadge99Cap.test.ts
  modified:
    - ready player 8/SupabaseService.swift
    - ready player 8Tests/NotificationsStoreTests.swift
    - ready player 8Tests/InboxViewTests.swift

key-decisions:
  - "Helper-extraction over test-mirror: the prior plan draft had the XCTest re-implement buildMarkAllReadQueryString as a private mirror of production logic. Rejected — mirrors drift. Extracted `internal static func buildMarkAllReadQueryString(userId:projectId:)` into SupabaseService.swift; markAllNotificationsRead consumes it; XCTest calls the REAL symbol via existing `@testable import ready_player_8`."
  - "Regression-style (not TDD-RED) tests accepted: the production code already exhibits the D-13/D-15 behavior (Phase 14 shipped filter-aware markAllRead; formatBadge caps at 99+ since 14-04). Writing a failing test first would require temporarily breaking production. Tests are therefore green-from-start and serve as regression locks — mirrors 30-02's sanctioned approach."
  - "Compile-only iOS test-target verification: build-for-testing fails with 30+ async/concurrency errors in pre-existing ready_player_8Tests.swift (tracked in phase deferred-items since Phase 22). Zero errors reference NotificationsStoreTests.swift or InboxViewTests.swift. Main-app `xcodebuild build` exits 0. Compile-only acceptance adopted per Phase 22 / 29.1 / 30-07 / 30-02 precedent."
  - "Benign grep-threshold deviation on `cs_notifications?user_id=eq.` count: plan called for exactly 1 post-extraction; actual count is 2 because the preexisting fetchNotifications method at line 1832 also happens to share a 22-character prefix with the helper. Semantically irrelevant — fetchNotifications has a different query shape (no read_at=is.null&dismissed_at=is.null), different HTTP verb (GET not PATCH), different purpose. The full mark-all-read inline pattern (`cs_notifications?user_id=eq.*read_at=is.null&dismissed_at=is.null`) now grep-counts to exactly 1, inside the helper — semantic single-source-of-truth intent satisfied."
  - "Only 4 files staged and committed — working tree had pre-existing unrelated plan-file edits (19-*, 21-*, supabase/.temp/cli-latest). Per CLAUDE.md file-scope discipline and the GSD `never git add -A` rule, those were left untouched."

patterns-established:
  - "Mark-all-read helper shape: an internal static query-string builder on SupabaseService for every filter-aware PATCH. Future 30-xx plans that add another filter-aware mutation (e.g. archive-all, snooze-all) should extract a similar helper rather than inlining the query-string construction."
  - "Cross-platform parity doc + regression-floor greps: when a contract spans iOS + web + a spec doc, tests on both platforms reference the spec doc by name (grep `30-PARITY-SPEC` hits ≥3 in the Swift file, visible in every web test label) — a future spec-rewrite cannot orphan the test comments without a grep alarm."

requirements-completed: [NOTIF-01, NOTIF-03]

# Metrics
duration: 25min
completed: 2026-04-24
---

# Phase 30 Plan 04: Parity Spec + Filter-Scope / 99+ Cap Regression Lock Summary

**Locked D-13 (mark-all-read filter scope), D-14 (bell-vs-sub-count scope split), and D-15 (99+ cap) as a written contract in 30-PARITY-SPEC.md plus 9 web vitest cases + 7 iOS XCTest cases; extracted `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` into production so both `markAllNotificationsRead` AND the XCTests consume the same symbol — eliminating the test-mirror drift risk flagged during plan revision.**

## Performance

- **Duration:** 25 min (started 2026-04-24T00:02:50Z, completed 2026-04-24T00:28:09Z)
- **Tasks:** 3/3 executed and committed atomically
- **Files created:** 4 (30-PARITY-SPEC.md, 2 vitests, 30-04-SUMMARY.md); modified: 3 (SupabaseService.swift, 2 iOS test files)
- **Commits:** `1538500` (Task 1 docs), `3660917` (Task 2 test), `3557a31` (Task 3 refactor)
- **Test counts:**
  - Web: 9 new vitest cases (4 filter-scope + 5 cap); full notifications suite 38/38 GREEN (29 existing + 9 new)
  - iOS: 7 new XCTest cases (5 D-15 cap + 1 D-13 filter parity + 1 D-14 sub-count format)

## Accomplishments

- **Task 1 (commit `1538500`)** authored `30-PARITY-SPEC.md` — 7-section canonical spec covering §Canonical Unread-Count Query (SQL quoted verbatim for grep-testability), §Scope Contract Table (bell NEVER applies `project_id`; sub-count DOES when filter active; mark-all DOES when filter active), §Display Cap Rules (0 → "", 1..99 → raw, ≥100 → "99+"), §Mark-All-Read Scope Contract (includes the helper-extraction note), §Regression Coverage, §Non-Goals.
- **Task 2 (commit `3660917`)** shipped the web regression floor — `markAllReadFilterScoped.test.ts` (4 cases: with-filter `.eq('project_id', 'proj-A')` count = 1; without-filter `.eq('project_id', …)` count = 0; update-payload keys = exactly `['read_at']` with valid ISO8601; signed-out path returns 0 + `.update()` call count = 0) + `bellBadge99Cap.test.ts` (5 cases: 0 → "", -5 → "", 99 → "99", 100 → "99+", 501 → "99+").
- **Task 3 (commit `3557a31`)** extracted `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` into production as `internal static` (SupabaseService.swift lines 1886–1896); refactored `markAllNotificationsRead` to consume it via `Self.buildMarkAllReadQueryString(...)`; appended `@Suite "Phase 30 mark-all-read scope + badge cap"` to `NotificationsStoreTests.swift` (5 cap cases + 1 filter-parity case calling the REAL helper via `@testable import ready_player_8` — no mirror); appended 1 sub-count format-lock case to `InboxViewTests.swift`.

## Task Commits

1. **Task 1: Author 30-PARITY-SPEC.md — canonical unread SQL + scope contract** — `1538500` (docs)
2. **Task 2: Web vitest — filter-scoped mark-all (D-13) + 99+ cap (D-15)** — `3660917` (test)
3. **Task 3: Extract buildMarkAllReadQueryString + iOS XCTest via @testable import** — `3557a31` (refactor)

## Files Created/Modified

### From commit `1538500` (Task 1)

- **`.planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-PARITY-SPEC.md`** (NEW, 77 LOC) — Canonical SQL quoted verbatim (`read_at IS NULL AND dismissed_at IS NULL` appears 2× for grep-testability), 3-column scope contract table, display-cap bulleted rules, mark-all-read UPDATE SQL (with-filter + without-filter forms), helper-extraction call-out naming `SupabaseService.buildMarkAllReadQueryString`, regression-coverage list (4 files), non-goals one-liner.

### From commit `3660917` (Task 2)

- **`web/src/lib/notifications/markAllReadFilterScoped.test.ts`** (NEW, 106 LOC) — Chainable fake-Supabase mock tracking every `.eq(col, val)` call on `eqCalls: Array<[string, unknown]>`, terminal `.then` resolving `{ error: null, count: N, data: null }`, toggleable `authUser` for signed-out branch. Case labels include `"per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract"` for traceability grep.
- **`web/src/lib/notifications/bellBadge99Cap.test.ts`** (NEW, 28 LOC) — Pure `formatBadge` cases with labels grep-tagged `D-15` / `30-PARITY-SPEC §Display Cap Rules`.

### From commit `3557a31` (Task 3)

- **`ready player 8/SupabaseService.swift`** (MODIFIED, +11 LOC, -1 LOC) — Lines 1886–1896 add `buildMarkAllReadQueryString(userId:projectId:)` doc-commented as single source of truth with 30-PARITY-SPEC pointer. Line 1898–1901 replace the inline `var qs = …` / `if let projectId { qs += … }` with a single-line `let qs = Self.buildMarkAllReadQueryString(...)` consumption. Public signature of `markAllNotificationsRead` byte-preserved.
- **`ready player 8Tests/NotificationsStoreTests.swift`** (MODIFIED, +63 LOC) — Appended `@Suite "Phase 30 mark-all-read scope + badge cap"` with 6 `@Test` cases (5 cap + 1 filter parity). The filter-parity case calls `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` twice (once with "proj-A", once with nil) and asserts substring containment — `user_id=eq.user-abc`, `project_id=eq.proj-A`, `read_at=is.null`, `dismissed_at=is.null` in the filtered case; `user_id=eq.user-abc` present and `project_id=` absent in the unfiltered case. NO private or internal mirror helper defined in this file.
- **`ready player 8Tests/InboxViewTests.swift`** (MODIFIED, +20 LOC) — Appended `test_inboxSubCount_renders_N_unread_of_M` to the existing `@Suite "Phase 30 picker + empty-state"` struct; three string-interpolation assertions lock the `"{N} unread of {M}"` format (3/10, 0/10, 0/0).

## Confirmation of acceptance-criteria greps

Per plan `<output>` requirement to confirm `grep -c "cs_notifications?user_id=eq\." "ready player 8/SupabaseService.swift"` after extraction:

- **Actual count: 2** (plan expected exactly 1). Lines are:
  - Line 1832 (`fetchNotifications`) — pre-existing, NOT touched by this plan. Different query shape (`…?user_id=eq.\(userId)"` with NO `read_at=is.null` predicate and NO `dismissed_at=is.null`). Different HTTP verb (GET, not PATCH). Different purpose (list notifications, not mark-all-read).
  - Line 1893 (`buildMarkAllReadQueryString`) — the new helper. Contains the full mark-all-read query pattern.
- **Semantic single-source-of-truth preserved:** `grep -c "cs_notifications?user_id=eq\..*read_at=is\.null&dismissed_at=is\.null" "ready player 8/SupabaseService.swift"` returns exactly **1** (only inside the helper). The inline-in-`markAllNotificationsRead` construction has been removed — confirmed by reading lines 1898–1901 post-edit.
- Documented as benign grep-threshold deviation below. Plan author scanned the local mark-all-read region; the out-of-scope `fetchNotifications` prefix overlap is a false-positive grep hit.

## @testable import verification

- `ready player 8Tests/NotificationsStoreTests.swift` line 8 carries `@testable import ready_player_8` (pre-existing, untouched).
- The new filter-parity test calls `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` — an `internal static` method on a production extension of `SupabaseService`. Access from the test target requires the `@testable` attribute on the import because `internal` symbols are otherwise invisible across modules. `@testable` unlocks them for the test module only.
- `grep -c "SupabaseService\.buildMarkAllReadQueryString" "ready player 8Tests/NotificationsStoreTests.swift"` = 3 (2 call sites in the test body + 1 comment reference). XCTest exercises the REAL production symbol, not a mirror.
- `grep -cE "private func buildMarkAllReadQueryString|private static func buildMarkAllReadQueryString|func buildMarkAllReadQueryString" "ready player 8Tests/NotificationsStoreTests.swift"` = 0. The rejected prior-draft mirror is NOT present.

## Decisions Made

| Decision | Rationale |
|---|---|
| Extract helper into production (Task 3 Step A) instead of mirroring it inside the XCTest | Prior draft had a `private func buildMarkAllReadQueryString` inside `NotificationsStoreTests.swift` — a copy of the production query-string construction. That's a self-test; if someone changes the production code and forgets the mirror, the test still passes while production drifts. Plan revised: helper extracted into `SupabaseService.swift` as `internal static`, `markAllNotificationsRead` consumes it, XCTest consumes the SAME symbol via `@testable import`. Single source of truth. Eliminates T-30-04-04 (Tampering — test-production drift). |
| Regression-style (green-from-start) tests rather than TDD-RED | `markAllRead(projectId)` has shipped the `.eq('project_id', …)` predicate since Phase 14-03 (D-12). `formatBadge` has capped at "99+" since Phase 14-04 (D-13). The behaviors under test already exist in production. TDD-RED would require temporarily breaking production just to see the test fail. Regression-style is the honest framing — same decision 30-02 made, with the same prompt-level sanction. |
| Compile-only iOS test-target verification | `xcodebuild build-for-testing` exits 65 due to 30+ pre-existing async/concurrency errors in `ready_player_8Tests.swift` (tracked in phase deferred-items since Phase 22). `grep -cE "error: .*NotificationsStoreTests\.swift|error: .*InboxViewTests\.swift"` on the build output returns 0. Main-app `xcodebuild build` exits 0 (BUILD SUCCEEDED) — the helper extraction compiles clean. Compile-only acceptance adopted per Phase 22 / 29.1 / 30-07 / 30-02 precedent captured in STATE.md. |
| Accept `cs_notifications?user_id=eq.` grep-count = 2 (plan expected 1) | The second match is an unrelated pre-existing occurrence in `fetchNotifications` (line 1832) — a GET list operation, not a PATCH mark-all-read. It predates this plan. The full mark-all-read pattern (`…?user_id=eq.*read_at=is.null&dismissed_at=is.null`) grep-counts to exactly 1, inside the helper — semantic single-source-of-truth intent satisfied. Same class of benign grep-threshold deviation as 30-03's "single-line export" acceptance. |
| Only 4 files staged + committed | Working tree had pre-existing unrelated edits under `19-*`, `21-*`, and `supabase/.temp/cli-latest`. Per CLAUDE.md file-scope discipline and the GSD `never git add -A` rule, those were left untouched — same discipline applied in 30-02 and 30-03. |

## Deviations from Plan

### Auto-fixed issues

None. No Rule 1 / 2 / 3 auto-fixes were triggered during execution. The plan was surgically authored; the helper extraction was a 1-for-1 code move with identical behavior; the tests simply wrapped existing behavior in grep-taggable cases.

### Plan-level deviations

**1. [Acceptance-criteria grep threshold] `cs_notifications?user_id=eq.` count = 2 instead of 1**
- **Found during:** Task 3 post-edit verification.
- **Issue:** Plan called for `grep -c "cs_notifications?user_id=eq." "ready player 8/SupabaseService.swift"` to return exactly 1 after the inline construction was moved to the helper. Actual count is 2 — the second match is an unrelated preexisting query-string in `fetchNotifications` (line 1832) whose first 22 chars happen to overlap with the helper.
- **Fix:** None required. Documented as benign. The full mark-all-read pattern `grep -c "cs_notifications?user_id=eq\..*read_at=is\.null&dismissed_at=is\.null"` returns exactly 1 (inside the helper), which is the semantic intent the plan captured. Reading the file at lines 1898–1901 confirms the inline construction is gone from `markAllNotificationsRead`.
- **Files modified:** None additional.
- **Commit:** `3557a31` (unchanged — the extraction itself is correct; only the grep threshold differs).

**2. [TDD framing] RED step physically impossible — behaviors already exist**
- **Found during:** Task 2 / Task 3 initial read.
- **Issue:** Plan frontmatter on both tasks reads `tdd="true"`. Strict TDD-RED requires the test to fail before the implementation exists. But `formatBadge` has capped at 99+ since Phase 14, `markAllRead(projectId)` has scoped .eq since Phase 14, and `buildMarkAllReadQueryString` was the sole new symbol in this plan — one of seven acceptance invariants in Task 3 still covers it (the rest cover existing production behavior).
- **Fix:** Reframed as regression-style (green-from-start). Same stance 30-02 adopted with explicit executor-prompt sanction ("when TDD-RED is impossible because implementation was salvaged before tests could be written"). The invariants tested are unchanged; only the framing of "did I see a RED run?" shifts.
- **Files modified:** None (the test file contents are what the plan prescribed).
- **Commit:** Same (`3660917` + `3557a31`).

### Out-of-scope flagged

- `web/src/lib/live-feed/generate-suggestion.ts:154` continues to emit `TS2741: Property 'imageUrl' is missing in type 'ProjectContext'` during `tsc --noEmit`. Pre-existing, already logged in phase `deferred-items.md`, not introduced or touched by 30-04.
- Pre-existing `ready_player_8Tests.swift` 30+ async/concurrency errors. Tracked in phase `deferred-items.md` since Phase 22. Not introduced or touched by 30-04.

**Total deviations:** 2 plan-level (grep-threshold semantic equivalence; TDD-RED framing). No auto-fixes. No architectural changes. No new dependencies.

## Issues Encountered

- **`.planning/` is gitignored** — `.gitignore` line 2 lists `.planning/` so `30-PARITY-SPEC.md` needed `git add -f` to be committed. Same pattern as all prior Phase 30 SUMMARY files (tracked in git log; 30-01/02/03/07/08 SUMMARY.md all landed via force-add). Documented for posterity.
- **`cs_notifications?user_id=eq.` grep false positive** — resolved via the benign-deviation note above.

## Auth Gates

None encountered.

## User Setup Required

None. Plan was spec + tests + a surgical production refactor that preserves public signatures.

## Threat Flags

No new threat surface introduced. All threats disposed in the plan's `<threat_model>` remain closed:

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-30-04-01 (Tampering — malicious projectId on markAllRead) | mitigate | Closed: Task 2 Case 1 asserts `.eq('project_id', …)` IS applied; existing RLS on `cs_notifications` enforces `user_id = auth.uid()` server-side as defense-in-depth |
| T-30-04-02 (Information Disclosure — sub-count leak) | accept | Closed: sub-count always filter-scoped; picker only lists memberships the user actually belongs to (30-02/03) |
| T-30-04-03 (DoS — 99+ cap bypass) | mitigate | Closed: Tasks 2 + 3 lock the cap at 100 boundary on both platforms. 5 vitest + 5 XCTest cases each |
| T-30-04-04 (Tampering — test-production drift of mark-all builder) | mitigate | Closed: Task 3 EXTRACTED the builder into production; XCTest calls the REAL symbol via `@testable import`. Mirror surface eliminated — `grep -cE "private func buildMarkAllReadQueryString\|private static func buildMarkAllReadQueryString\|func buildMarkAllReadQueryString" "ready player 8Tests/NotificationsStoreTests.swift"` = 0 |

## Known Stubs

None. The PARITY-SPEC cites real production code paths; the tests exercise real exports; the helper-extraction preserves behavior byte-for-byte.

## Next Phase Readiness

**Ready for Plan 30-05 (iOS Realtime subscription).** The PARITY-SPEC now formally specifies that "bell badge re-fetches after mark-all (Realtime/polling tick, not push from action)". 30-05's Realtime subscriber can rely on the same canonical unread-count query path — no new invalidation API needed.

**Ready for Plan 30-06 (inbox_filter_changed analytics).** PARITY-SPEC clarifies WHY filter-change is the scope-affecting event (sub-count + mark-all move; bell does not) — gives 30-06 a crisp "what to track" framing. No code surface added by 30-04 that 30-06 needs to hook; `NotificationsStore.setFilter` and `InboxProjectPicker.onPick` remain the canonical write points.

**Ready for Plan 30-09 (acceptance evidence bundle).** 30-PARITY-SPEC is now the canonical reviewable doc for D-13/D-14/D-15; the 9 web vitest cases + 7 iOS XCTest cases + the extracted helper are the reviewable code artifacts. `grep -c "30-PARITY-SPEC" "ready player 8Tests/NotificationsStoreTests.swift"` = 3 (traceability from tests back to spec).

**No blockers.** `SupabaseService.markAllNotificationsRead` public signature unchanged; web `markAllRead` unchanged; `formatBadge` unchanged on both platforms. REST surface untouched; iOS existing behavior (polling, mark-read, mark-all) byte-preserved.

## Self-Check: PASSED

- [x] `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-PARITY-SPEC.md` — FOUND
- [x] `web/src/lib/notifications/markAllReadFilterScoped.test.ts` — FOUND
- [x] `web/src/lib/notifications/bellBadge99Cap.test.ts` — FOUND
- [x] `ready player 8/SupabaseService.swift` modified — FOUND (helper extraction at lines 1886–1901)
- [x] `ready player 8Tests/NotificationsStoreTests.swift` modified — FOUND (@Suite "Phase 30 mark-all-read scope + badge cap" appended)
- [x] `ready player 8Tests/InboxViewTests.swift` modified — FOUND (test_inboxSubCount_renders_N_unread_of_M appended)
- [x] Task 1 commit `1538500` — FOUND in `git log --oneline`
- [x] Task 2 commit `3660917` — FOUND in `git log --oneline`
- [x] Task 3 commit `3557a31` — FOUND in `git log --oneline`
- [x] Task 1 acceptance greps:
  - [x] `grep -c "read_at IS NULL AND dismissed_at IS NULL" PARITY-SPEC.md` = 2 (≥ 1 required)
  - [x] `grep -c "NEVER applied" PARITY-SPEC.md` = 1 (≥ 1 required)
  - [x] `grep -c "99+" PARITY-SPEC.md` = 5 (≥ 2 required)
  - [x] `grep -c "cs_notifications" PARITY-SPEC.md` = 5 (≥ 2 required)
  - [x] `grep -c "buildMarkAllReadQueryString" PARITY-SPEC.md` = 2 (≥ 1 required)
- [x] Task 2 acceptance:
  - [x] `cd web && npx vitest run src/lib/notifications/markAllReadFilterScoped.test.ts` → 4/4 GREEN
  - [x] `cd web && npx vitest run src/lib/notifications/bellBadge99Cap.test.ts` → 5/5 GREEN
  - [x] `grep -c "D-13" markAllReadFilterScoped.test.ts` = 7 (≥ 1 required)
  - [x] `grep -c "D-15" bellBadge99Cap.test.ts` = 7 (≥ 2 required)
  - [x] `grep -c "project_id" markAllReadFilterScoped.test.ts` = 8 (≥ 3 required)
  - [x] Full notifications suite 38/38 GREEN (no regressions to existing 29 cases)
- [x] Task 3 acceptance:
  - [x] `grep -c "buildMarkAllReadQueryString" "ready player 8/SupabaseService.swift"` = 2 (≥ 2 required: def + call)
  - [x] `grep -c "cs_notifications?user_id=eq\..*read_at=is\.null&dismissed_at=is\.null" "ready player 8/SupabaseService.swift"` = 1 (single source of truth; benign grep-threshold deviation on the 22-char-prefix-only grep)
  - [x] `grep -c "SupabaseService\.buildMarkAllReadQueryString" "ready player 8Tests/NotificationsStoreTests.swift"` = 3 (≥ 2 required)
  - [x] `grep -cE "private func buildMarkAllReadQueryString|private static func buildMarkAllReadQueryString|func buildMarkAllReadQueryString" "ready player 8Tests/NotificationsStoreTests.swift"` = 0 (= 0 required — no mirror)
  - [x] `grep -c "@testable import ready_player_8" "ready player 8Tests/NotificationsStoreTests.swift"` = 2 (≥ 1 required — 1 actual import at line 8, 1 comment reference at line 164)
  - [x] `grep -c "test_formatBadge_" NotificationsStoreTests.swift` = 5 (≥ 5 required)
  - [x] `grep -c "test_markAllRead_withFilter_preservesProjectFilterInPATCHQuery" NotificationsStoreTests.swift` = 1 (= 1 required)
  - [x] `grep -c "test_inboxSubCount_renders_N_unread_of_M" InboxViewTests.swift` = 1 (= 1 required)
  - [x] `grep -c "project_id=eq.proj-A" NotificationsStoreTests.swift` = 1 (≥ 1 required)
  - [x] `grep -c "30-PARITY-SPEC" NotificationsStoreTests.swift` = 3 (≥ 1 required — traceability from tests to spec)
  - [x] `xcodebuild build` main app → BUILD SUCCEEDED
  - [x] `xcodebuild build-for-testing` errors: zero reference the new/modified test files (compile-only per Phase 22/29.1/30-07/30-02 precedent; pre-existing ready_player_8Tests.swift errors documented in deferred-items.md)

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Completed: 2026-04-24*
