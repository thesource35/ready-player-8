---
phase: 29-live-video-traffic-feed-sat-drone
plan: 00
subsystem: testing

tags: [vitest, xctest, supabase-rls, scaffolding, phase29, live-feed, drone, regression-lock]

# Dependency graph
requires:
  - phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
    provides: "VideoAsset model + cs_video_assets schema + portal drone exclusion (D-22) — Phase 29 Wave 0 drone-exclusion regression test locks that invariant before Phase 29 code lands"
provides:
  - "9 vitest stub files (one describe + one it.skip + expect(true).toBe(true) each) covering LIVE-01/03/04/05/08/09/11/12/14"
  - "4 XCTest stub files under ready player 8Tests/Phase29/ (each final class + single XCTSkip testTODO_skipped)"
  - "1 SQL smoke placeholder for LIVE-05 cs_live_suggestions RLS (Phase 26 \\echo pattern)"
  - "Resolvable paths for every Phase 29 Wave 1-4 task's <automated> verify command — no MISSING-file errors in downstream executions"
  - "LIVE-14 critical regression test file on main ahead of any Phase 29 implementation (research-mandated land-the-critical-test-early rule)"
affects:
  - 29-01 (Wave 1 schema + RLS)
  - 29-02 (Wave 1 upload-url + portal drone-exclusion regression)
  - 29-03 (Wave 2 generate-live-suggestions + Anthropic vision adapter)
  - 29-05 (Wave 3 iOS LiveFeedView + NavTab + ProjectSwitcher + models)
  - 29-07 (Wave 3 iOS LiveSuggestionCard)
  - 29-08 (Wave 4 web /live-feed page + ProjectSwitcher)
  - 29-09 (Wave 4 DroneScrubberTimeline)
  - 29-10 (Wave 4 web LiveSuggestionCard + BudgetBadge)

# Tech tracking
tech-stack:
  added: []  # scaffolding only — no runtime deps added
  patterns:
    - "Wave 0 stub precedent: one describe() + one it.skip() + expect(true).toBe(true) + top-of-file // Owner: 29-NN-PLAN.md ... comment"
    - "iOS Wave 0 stub precedent: final class <Name>Tests: XCTestCase with single func testTODO_skipped() throws { throw XCTSkip(\"TODO ...\") }"
    - "SQL smoke placeholder: \\echo 'TODO Wave N plan 29-NN: <assertion>' lines documenting each intended check (Phase 26 pattern)"
    - "Parallel-executor commit hygiene: --no-verify on all commits to avoid pre-commit hook contention across worktree agents"

key-files:
  created:
    - web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts
    - web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts
    - web/src/__tests__/db/live-suggestions-rls.test.ts
    - web/src/app/live-feed/__tests__/page.test.tsx
    - web/src/app/live-feed/__tests__/project-switcher.test.tsx
    - web/src/app/live-feed/__tests__/suggestion-card.test.tsx
    - web/src/app/live-feed/__tests__/budget-badge.test.tsx
    - web/src/app/live-feed/__tests__/scrubber-window.test.ts
    - web/src/lib/live-feed/__tests__/anthropic-vision.test.ts
    - "ready player 8Tests/Phase29/NavTabLiveFeedTests.swift"
    - "ready player 8Tests/Phase29/ProjectSwitcherTests.swift"
    - "ready player 8Tests/Phase29/LiveSuggestionCardTests.swift"
    - "ready player 8Tests/Phase29/LiveFeedModelsTests.swift"
    - supabase/migrations/__tests__/phase29_cs_live_suggestions_rls.sql
  modified: []

key-decisions:
  - "Matched Phase 22 Wave 0 stub shape verbatim (single it.skip / single XCTSkip, top-of-file owner comment, no @testing-library or mocks) so downstream owners can un-skip with minimal surface"
  - "Landed LIVE-14 drone-exclusion stub in Wave 0 (not deferred) per research rule — critical regression test file present on main before any Phase 29 code change"
  - "Kept portal/video production code untouched — LIVE-14 invariant requires that only __tests__/ files are added under web/src/app/api/portal/video/ in Wave 0"
  - "Used --no-verify on both task commits per parallel-executor protocol (avoids pre-commit hook contention)"

patterns-established:
  - "Wave 0 scaffolding is pure inert stubs — no assertions beyond expect(true).toBe(true), no mocks, no deps"
  - "Every describe/final-class label is phrased as the eventual feature under test so owner plans can convert skip→it with minimal renaming"
  - "SQL smoke placeholders use \\echo 'TODO ...' lines one per intended assertion — self-documenting test plan"

requirements-completed:
  - LIVE-01
  - LIVE-03
  - LIVE-04
  - LIVE-05
  - LIVE-08
  - LIVE-09
  - LIVE-11
  - LIVE-12
  - LIVE-14

# Metrics
duration: ~6 min
completed: 2026-04-19
---

# Phase 29 Plan 00: Wave 0 Test Scaffolding Summary

**14 inert test stub files (9 vitest + 4 XCTest + 1 SQL) establishing Phase 29's verification contract and locking the LIVE-14 portal drone-exclusion regression test on main before any implementation code ships.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-19T19:30:20Z (approximate; agent spawn)
- **Completed:** 2026-04-19T19:36:00Z (approximate; post-task-2 verification)
- **Tasks:** 2 of 2 completed
- **Files created:** 14 (9 TS/TSX + 4 Swift + 1 SQL)
- **Files modified:** 0

## Accomplishments

- Every Phase 29 Wave 1-4 task's `<automated>` verify command now resolves to a file that exists on main — executors in downstream waves will not hit `MISSING` errors.
- LIVE-14 drone-exclusion regression test file lives at `web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts` with an `it.skip` placeholder and owner pointer to 29-02-PLAN.md — satisfies the research-mandated "land critical regression test early" rule.
- 4 XCTest stubs dropped into the Xcode PBXFileSystemSynchronizedRootGroup-managed `ready player 8Tests/Phase29/` directory; Xcode will auto-include on next project open (no pbxproj edit required).
- 1 SQL smoke placeholder at `supabase/migrations/__tests__/phase29_cs_live_suggestions_rls.sql` documents the 3 RLS assertions Wave 1 plan 29-01 will flesh out (table + RLS + 2 policies / cross-org SELECT deny / UPDATE guard).

## Task Commits

1. **Task 1: Create 9 vitest stub files covering LIVE-01/03/04/05/08/09/11/12/14** — `4226bbd` (test)
2. **Task 2: Create 4 XCTest stub files + 1 SQL smoke file covering LIVE-03/04/09 iOS + LIVE-05 DB + LiveFeed Codable** — `d625752` (test)

_Plan metadata commit will follow this SUMMARY write in the orchestrator sweep (per orchestrator-owns-STATE-and-ROADMAP rule for parallel executors)._

## Files Created

### Vitest stubs (Task 1 — `4226bbd`)

- `web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts` — LIVE-01 upload-url drone source_type (owner: 29-02 Wave 1)
- `web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts` — **LIVE-14 CRITICAL regression lock** — portal routes 403 on drone (owner: 29-02 Wave 1, per D-26)
- `web/src/__tests__/db/live-suggestions-rls.test.ts` — LIVE-05 cross-org RLS deny (owner: 29-01 Wave 1)
- `web/src/app/live-feed/__tests__/page.test.tsx` — LIVE-03 web /live-feed renders (owner: 29-08 Wave 4)
- `web/src/app/live-feed/__tests__/project-switcher.test.tsx` — LIVE-04 web project persistence (owner: 29-08 Wave 4)
- `web/src/app/live-feed/__tests__/suggestion-card.test.tsx` — LIVE-09 web dismiss flow (owner: 29-10 Wave 4)
- `web/src/app/live-feed/__tests__/budget-badge.test.tsx` — LIVE-11 healthy/warning/reached (owner: 29-10 Wave 4)
- `web/src/app/live-feed/__tests__/scrubber-window.test.ts` — LIVE-12 24h window query (owner: 29-09 Wave 4)
- `web/src/lib/live-feed/__tests__/anthropic-vision.test.ts` — LIVE-08 JSON validation (owner: 29-03 Wave 2)

### XCTest + SQL stubs (Task 2 — `d625752`)

- `ready player 8Tests/Phase29/NavTabLiveFeedTests.swift` — LIVE-03 iOS NavTab.liveFeed → LiveFeedView (owner: 29-05 Wave 3)
- `ready player 8Tests/Phase29/ProjectSwitcherTests.swift` — LIVE-04 iOS LastSelectedProjectId AppStorage (owner: 29-05 Wave 3)
- `ready player 8Tests/Phase29/LiveSuggestionCardTests.swift` — LIVE-09 iOS severity colors + dismiss (owner: 29-07 Wave 3)
- `ready player 8Tests/Phase29/LiveFeedModelsTests.swift` — LiveSuggestion / LiveSuggestionActionHint Codable (owner: 29-05 Wave 3)
- `supabase/migrations/__tests__/phase29_cs_live_suggestions_rls.sql` — 3 `\echo 'TODO'` lines placeholder (owner: 29-01 Wave 1)

## Decisions Made

None beyond the key-decisions listed in frontmatter — plan executed exactly as written.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. Two write operations triggered Vercel-plugin MCP skill injections (bootstrap/next-upgrade on `package.json` read; vercel-functions/next-cache-components/nextjs on `api/**/app/**` write; vercel-storage on `supabase/**` write) — all declined with reasoning: scaffolding files contain no Next.js / Vercel / storage surface, only inert `describe` + `it.skip` or `\echo` placeholder text.

## Authentication Gates

None — no external services touched during Wave 0 scaffolding.

## Verification Evidence

```
cd web && npx vitest run src/app/live-feed/__tests__ src/app/api/video/vod/__tests__ \
  src/app/api/portal/video/__tests__ src/__tests__/db src/lib/live-feed/__tests__
# Test Files  9 skipped (9)
#      Tests  9 skipped (9)
#   Duration  349ms
```

All 9 vitest stubs discovered, all marked `.skip`, zero failing, zero passing. Matches plan `<verification>` block exactly.

iOS verification deferred: `xcodebuild test -only-testing:"ready player 8Tests/Phase29"` was not run because the PBXFileSystemSynchronizedRootGroup picks up files lazily on next Xcode open. File presence verified via `test -f` + grep; XCTSkip + final class + Owner assertions pass (4 files each).

LIVE-14 invariant check:
```
git diff d1a4d9a..HEAD --name-only | grep -v '__tests__' | grep 'web/src/app/api/portal/video/'
# CLEAN: no non-test files under portal/video touched
```

## Threat Flags

None — Wave 0 creates inert test stubs only; no new auth paths, endpoints, or trust-boundary surface.

## Known Stubs

All 14 files are intentionally stubs. Each carries an owner comment identifying the Wave 1-4 plan that will un-skip it:

| File | Owner plan | Requirement |
|------|-----------|-------------|
| upload-url-drone.test.ts | 29-02 Wave 1 | LIVE-01 |
| drone-exclusion.test.ts | 29-02 Wave 1 | LIVE-14 **[CRITICAL]** |
| live-suggestions-rls.test.ts | 29-01 Wave 1 | LIVE-05 |
| page.test.tsx | 29-08 Wave 4 | LIVE-03 web |
| project-switcher.test.tsx | 29-08 Wave 4 | LIVE-04 web |
| suggestion-card.test.tsx | 29-10 Wave 4 | LIVE-09 web |
| budget-badge.test.tsx | 29-10 Wave 4 | LIVE-11 |
| scrubber-window.test.ts | 29-09 Wave 4 | LIVE-12 |
| anthropic-vision.test.ts | 29-03 Wave 2 | LIVE-08 |
| NavTabLiveFeedTests.swift | 29-05 Wave 3 | LIVE-03 iOS |
| ProjectSwitcherTests.swift | 29-05 Wave 3 | LIVE-04 iOS |
| LiveSuggestionCardTests.swift | 29-07 Wave 3 | LIVE-09 iOS |
| LiveFeedModelsTests.swift | 29-05 Wave 3 | LiveFeed Codable |
| phase29_cs_live_suggestions_rls.sql | 29-01 Wave 1 | LIVE-05 (smoke) |

## User Setup Required

None — no external service configuration required for Wave 0 scaffolding.

## Next Phase Readiness

- Wave 1 (plans 29-01, 29-02) can proceed immediately — their `<automated>` verify commands now resolve.
- LIVE-14 critical regression test is present and ready to be filled with real 403 assertions in 29-02.
- PBXFileSystemSynchronizedRootGroup will pick up the `Phase29/` XCTest folder on next Xcode open; no manual pbxproj edit required before Wave 3.
- Pre-existing async/concurrency build errors in `ready_player_8Tests.swift` + `ReportTests.swift` (logged to Phase 22 `deferred-items.md`) remain out of scope — Phase 29 iOS waves must either compile-only or bundle a fix when they need live XCTest runs.

## Self-Check

Per executor self-check protocol:

- ✅ 14 created files exist on disk (`test -f` pass for all)
- ✅ Task 1 commit `4226bbd` present in `git log --oneline -5`
- ✅ Task 2 commit `d625752` present in `git log --oneline -5`
- ✅ Vitest discovers all 9 stubs, reports 9 skipped / 0 failed / 0 passed
- ✅ LIVE-14 invariant: zero non-test file changes under `web/src/app/api/portal/video/`
- ✅ Plan frontmatter `requirements` (LIVE-01/03/04/05/08/09/11/12/14) copied verbatim into `requirements-completed`

## Self-Check: PASSED

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Completed: 2026-04-19*
