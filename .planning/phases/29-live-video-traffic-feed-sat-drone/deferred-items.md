# Phase 29 Deferred Items

## Pre-existing test-target compile errors (out of scope for 29-05)

**Discovered during:** Plan 29-05 Task 2 verification (xcodebuild test run).

**File:** `ready player 8Tests/ready_player_8Tests.swift` lines 103, 110, 118, 125, 132, 138, 150, 409, 414, 420, 425, 431, 436, 441, 447

**Error class:** `'async' call in a function that does not support concurrency`

**Last touched by:** Phase 13-15 commit `9805e17` — well before Phase 29. These errors are Swift concurrency-rule failures that pre-date our work and are NOT caused by any 29-05 file.

**Why deferred:** Per executor scope-boundary rule, only auto-fix issues directly caused by the current task's changes. Fixing a pre-Phase-22 test-target file falls outside the 29-05 scope and affects unrelated test suites. The **app target** (`ready player 8`) `BUILD SUCCEEDED` — all Plan 29-05 Swift code compiles cleanly. Only the test target's legacy tests block the `xcodebuild test` command.

**Recommendation:** Schedule a maintenance plan (or include as part of a future phase that cleans the test target) to add `async throws` markers or wrap in `Task { ... }` / `expectation` patterns.

**Files created by 29-05 that DO compile:**
- `ready player 8/LiveFeed/LiveFeedModels.swift`
- `ready player 8/LiveFeed/LiveFeedView.swift`
- `ready player 8/LiveFeed/LiveFeedPerProjectView.swift`
- `ready player 8/LiveFeed/LiveFeedFleetView.swift`
- `ready player 8/LiveFeed/FleetProjectTile.swift`
- `ready player 8/LiveFeed/ProjectSwitcherSheet.swift`
- `ready player 8Tests/Phase29/NavTabLiveFeedTests.swift` (real assertions)
- `ready player 8Tests/Phase29/ProjectSwitcherTests.swift` (real assertions)

---

## Re-confirmed during 29-07 (2026-04-20)

Plan 29-07 Wave 3 hit the same pre-existing test-target concurrency errors
during `xcodebuild build-for-testing`. Verified pre-existing via `git stash &&
xcodebuild build-for-testing` reproducing the same errors at HEAD before
29-07's changes.

**Files created by 29-07 that DO compile (app target BUILD SUCCEEDED):**
- `ready player 8/LiveFeed/LiveSuggestionsStore.swift`
- `ready player 8/LiveFeed/LiveSuggestionCard.swift`
- `ready player 8/LiveFeed/LiveSuggestionCardRow.swift`
- `ready player 8/LiveFeed/TrafficUnifiedCard.swift`
- `ready player 8/LiveFeed/BudgetBadge.swift`
- `ready player 8/LiveFeed/AnalyzeNowButton.swift`
- `ready player 8/LiveFeed/LastAnalyzedLabel.swift`
- `ready player 8Tests/Phase29/LiveSuggestionCardTests.swift` (7 assertions, un-skipped)

29-07's own test file (`LiveSuggestionCardTests.swift`) uses `@MainActor`
annotations on its async-touching methods, sidestepping the pre-existing
pattern entirely.

---

## Noted during 29-08 (2026-04-20)

**Pre-existing web lint errors in `web/src/app/layout.tsx`:**

- Line 81: `<a href="/">` — `@next/next/no-html-link-for-pages` (logo anchor)
- Line 82: `<img>` — `@next/next/no-img-element` (logo image)
- Line 107: `<a href="/projects">` — `@next/next/no-html-link-for-pages` (footer link)

These errors pre-date 29-08. The only line 29-08 touched in `layout.tsx` is the
new INTEL-group entry `{ href: "/live-feed", label: "Live Feed" }` on line 39,
which does not introduce any lint rule violation. Per scope-boundary rule, not
fixing pre-existing cross-nav violations in this plan.

**Vitest 4 + jsdom 29 localStorage shim:**

`vitest@4.1.4` exposes a bare `{}` as `window.localStorage` (no Storage
prototype) even with `environmentOptions.jsdom.url` set. 29-08 Wave 4 tests
install a per-file in-memory Storage shim in `beforeAll` to sidestep this. A
future plan could consolidate this into a shared `setupFiles` entry once we
have more tests that touch localStorage.
