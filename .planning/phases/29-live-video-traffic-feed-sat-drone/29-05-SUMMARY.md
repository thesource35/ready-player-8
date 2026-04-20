---
phase: 29-live-video-traffic-feed-sat-drone
plan: 05
subsystem: ui
tags: [ios, swiftui, navtab, appstorage, livefeed, fleet-view, project-switcher, xctest]

# Dependency graph
requires:
  - phase: 29-01
    provides: cs_live_suggestions schema (D-17 columns consumed by LiveSuggestion Codable struct)
  - phase: 29-03
    provides: generate-live-suggestions Edge Function (Live Feed UI will invoke — wiring deferred to 29-06/29-07)
  - phase: 22
    provides: VideoSourceType.drone enum case + VideoClipPlayer + VideoUploadClient (consumed by downstream 29-06 scaffold sections)
  - phase: 21
    provides: MapsView overlay-toggle + traffic-tile pattern (consumed by future mini-map integration)
provides:
  - "NavTab.liveFeed case + navItems 4-tuple entry (intel group, between Maps and Ops)"
  - "activeTabContent switch case routing to LiveFeedView()"
  - "LiveFeedView.swift — top-level tab shell with Fleet/Per-Project toggle persisted to ConstructOS.LiveFeed.LastFleetSelection"
  - "ProjectSwitcherSheet.swift — LIVE-04 picker with case-insensitive prefix filter; selection persists to ConstructOS.LiveFeed.LastSelectedProjectId"
  - "LiveFeedPerProjectView.swift — 5-section layout scaffold (video / scrubber / suggestions / traffic / library+upload) with named placeholders for 29-06 + 29-07"
  - "LiveFeedFleetView.swift — 2-col (compact) / 3-col (regular size class) LazyVGrid"
  - "FleetProjectTile.swift — 16:9 poster + 120pt suggestion row with premiumGlow"
  - "LiveFeedModels.swift — LiveSuggestion struct + LiveSuggestionActionHint + LiveSuggestionSeverity (routine/opportunity/alert) + LiveFeedStorageKey constants under ConstructOS.LiveFeed.*"
  - "ProjectSummary struct — minimal view-layer {id, name, client} shape iterated by switcher + Fleet grid"
  - "SupabaseService.allowedTables augmented with cs_live_suggestions"
  - "Real XCTest assertions replacing Wave 0 XCTSkip stubs in NavTabLiveFeedTests + ProjectSwitcherTests"
affects: [29-06, 29-07, 29-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "iOS AppStorage namespacing: `ConstructOS.LiveFeed.*` root + `LiveFeedStorageKey` enum of static constants + static formatter functions for per-project scoped keys (lastAnalyzedAt/lastScrubTimestamp). Matches CLAUDE.md `ConstructOS.{Feature}.{Property}` convention while keeping per-project keys consistent."
    - "View-layer placeholder pattern: LiveFeedPerProjectView ships 5 named placeholder sub-views (videoPlayerPlaceholder, scrubberPlaceholder, etc.) with '29-06' / '29-07' comment markers that the downstream plans replace. Lets Wave 3 be purely navigation + layout while reserving slot names for wave-scoped consumption."
    - "AppStorage binding lock-in via test: locks the key strings (lastSelectedProjectId / lastFleetSelection / suggestionModel) at the UserDefaults layer rather than asserting @AppStorage view state — makes the contract testable without instantiating SwiftUI views in XCTest."
    - "Stale-id guard: LiveFeedView.effectiveProjectId computed property checks the persisted LastSelectedProjectId against the current accessibleProjects list and falls back to the first project when the stored id has been removed from the user's org (T-29-RLS-CLIENT mitigation)."

key-files:
  created:
    - "ready player 8/LiveFeed/LiveFeedModels.swift"
    - "ready player 8/LiveFeed/LiveFeedView.swift"
    - "ready player 8/LiveFeed/LiveFeedPerProjectView.swift"
    - "ready player 8/LiveFeed/LiveFeedFleetView.swift"
    - "ready player 8/LiveFeed/FleetProjectTile.swift"
    - "ready player 8/LiveFeed/ProjectSwitcherSheet.swift"
  modified:
    - "ready player 8/ContentView.swift"
    - "ready player 8/SupabaseService.swift"
    - "ready player 8Tests/Phase29/NavTabLiveFeedTests.swift"
    - "ready player 8Tests/Phase29/ProjectSwitcherTests.swift"

key-decisions:
  - "Used movie-camera emoji (U+1F3A5) in navItems instead of SF Symbol 'video.badge.waveform' — navItems is an emoji-glyph 4-tuple by Phase 22 convention; keeping parity avoids a mixed-icon-type navItems array."
  - "Kept LiveFeedView.accessibleProjects empty in Wave 3 — real SupabaseService.shared.fetch('cs_projects') wiring deferred to the downstream plan that actually needs project data (29-07 budget badge / 29-06 upload). This plan ships the shell; consumption plans wire data."
  - "Placed the enum case `liveFeed` in the NavTab enum after `.maps` (logical ordering) while navItems places it AFTER `.network` — the navItems order drives visual rendering; the enum order is just source-code readability."
  - "Added ProjectSummary struct to LiveFeedView.swift rather than LiveFeedModels.swift — it's a view-layer shape, not a wire-format DTO. LiveFeedModels is reserved for cs_live_suggestions shape + AppStorage keys."

patterns-established:
  - "ConstructOS.LiveFeed.* AppStorage namespace + LiveFeedStorageKey enum with static constants + per-project key formatters"
  - "Wave-3 navigation scaffold pattern: ship tab enum entry + switch case + shell view with named placeholder sections for downstream consumption plans to fill, rather than bundling UI + data wiring in one plan"
  - "Structured-field action_hint nested Codable with snake_case CodingKeys at each level (LiveSuggestion → LiveSuggestionActionHint → StructuredFields)"

requirements-completed: [LIVE-03, LIVE-04]

# Metrics
duration: 20min
completed: 2026-04-19
---

# Phase 29 Plan 05: Wave 3 iOS UI — Live Feed Tab Shell + Project Switcher + Fleet Toggle Summary

**iOS `NavTab.liveFeed` wired into the intel group with a `LiveFeedView` shell that persists project selection + Fleet/Per-Project mode to `ConstructOS.LiveFeed.*` AppStorage, plus a `ProjectSwitcherSheet` with case-insensitive prefix filter and a `FleetProjectTile`-driven grid — ready for 29-06 (scrubber/upload) and 29-07 (suggestion cards/traffic/budget) to fill the named placeholder sections.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-04-19T22:29:25-04:00
- **Completed:** 2026-04-19T22:41:56-04:00
- **Tasks:** 2 (both autonomous, type=auto tdd=true)
- **Files created:** 6 (5 views + 1 models file under `ready player 8/LiveFeed/`)
- **Files modified:** 4 (ContentView.swift, SupabaseService.swift, 2 XCTest files)

## Accomplishments

- **LIVE-03 (iOS) closed.** `NavTab.liveFeed` case added to the `ContentView.NavTab` enum with rawValue `"live-feed"`; `navItems` 4-tuple has the entry in the `intel` group between `.network` (core) and `.ops` (intel); `activeTabContent` switch routes to `LiveFeedView()`.
- **LIVE-04 (iOS) closed.** `ProjectSwitcherSheet` persists selection via `@Binding` bound to `@AppStorage(LiveFeedStorageKey.lastSelectedProjectId)` in the parent `LiveFeedView`; Fleet toggle persists via `@AppStorage(LiveFeedStorageKey.lastFleetSelection)`.
- **`ConstructOS.LiveFeed.*` namespace locked.** `LiveFeedStorageKey` enum exposes 3 static constants (lastSelectedProjectId, lastFleetSelection, suggestionModel) + 2 per-project formatter functions (lastAnalyzedAt, lastScrubTimestamp). Stability pinned by XCTest.
- **LiveSuggestion Codable shape pinned.** `LiveSuggestion` + nested `LiveSuggestionActionHint.StructuredFields` decode cs_live_suggestions snake_case JSON from 29-01's schema; `isBudgetMarker` sentinel (model == 'budget_reached_marker' per UI-SPEC LIVE-11) surfaces the D-22 cost cap state without a separate counter table.
- **Downstream scaffold in place.** `LiveFeedPerProjectView` ships 5 named placeholder sections (`videoPlayerPlaceholder`, `scrubberPlaceholder`, `suggestionsPlaceholder`, `trafficPlaceholder`, library+upload buttons) with "29-06" / "29-07" markers so those plans can swap in real widgets without further `ContentView.swift` edits.
- **FleetProjectTile uses premiumGlow.** 16:9 poster surface + 120pt suggestion row per UI-SPEC Fleet lines 261-272; applies `.premiumGlow(cornerRadius: 14, color: Theme.accent)` matching the existing glow convention (ClientPortalView / GlobalContractorDirectoryView).
- **Wave 0 stubs un-skipped.** `NavTabLiveFeedTests.swift` now has 4 assertions (enum rawValue, severity 3-case lock, snake_case Codable decode, budget_reached_marker sentinel); `ProjectSwitcherTests.swift` now has 5 assertions (3 storage-key strings, per-project key interpolation, AppStorage Bool + String round-trip, ProjectSummary identity). **Zero** `XCTSkip` calls remain in either file.
- **App-target xcodebuild passes.** Built `ready player 8` scheme on iPhone 17 Simulator → `BUILD SUCCEEDED`. No errors from any new `LiveFeed/*.swift` file.

## Task Commits

Each task was committed atomically:

1. **Task 1: NavTab.liveFeed + LiveFeedModels + navItems + activeTabContent + SupabaseService allowlist + real NavTabLiveFeedTests** — `2334176` (feat)
2. **Task 2: LiveFeedView shell + LiveFeedPerProjectView + LiveFeedFleetView + FleetProjectTile + ProjectSwitcherSheet + real ProjectSwitcherTests** — `6bd0da6` (feat)

## Files Created/Modified

### Created (6)

- `ready player 8/LiveFeed/LiveFeedModels.swift` — `LiveSuggestion` Codable + nested `LiveSuggestionActionHint.StructuredFields` + `LiveSuggestionSeverity` (routine/opportunity/alert) + `LiveFeedStorageKey` enum with 3 static key constants + 2 per-project key formatter functions.
- `ready player 8/LiveFeed/LiveFeedView.swift` — Top-level `NavTab.liveFeed` shell with `@AppStorage` bindings for LastSelectedProjectId + LastFleetSelection; routes between per-project and Fleet views; sheet-presents `ProjectSwitcherSheet`; falls back to first accessible project when persisted id is stale. Also defines `ProjectSummary` struct.
- `ready player 8/LiveFeed/LiveFeedPerProjectView.swift` — 5-section layout scaffold (video / scrubber / suggestions / traffic / library+upload) with named placeholder sub-views and empty-state copy from UI-SPEC.
- `ready player 8/LiveFeed/LiveFeedFleetView.swift` — `LazyVGrid` with 2 cols (compact horizontalSizeClass) / 3 cols (regular); empty-state with "No Active Projects" copy per UI-SPEC.
- `ready player 8/LiveFeed/FleetProjectTile.swift` — 16:9 drone-poster placeholder + 120pt suggestion-snippet row with `.premiumGlow(cornerRadius: 14, color: Theme.accent)`.
- `ready player 8/LiveFeed/ProjectSwitcherSheet.swift` — `.searchable` list with case-insensitive prefix filter; tap-to-select writes to `@Binding var selectedProjectId`; Done button in toolbar.

### Modified (4)

- `ready player 8/ContentView.swift` — Added `case liveFeed = "live-feed"` to `NavTab` enum (line 555); added `("live-feed","LIVE FEED","\u{1F3A5}","intel")` entry to `navItems` (line 591); added `case .liveFeed: LiveFeedView()` to `activeTabContent` switch (line 750).
- `ready player 8/SupabaseService.swift` — Added `"cs_live_suggestions"` to `allowedTables` Set (Phase 29 row-only extension).
- `ready player 8Tests/Phase29/NavTabLiveFeedTests.swift` — Replaced XCTSkip stub with 4 real assertions.
- `ready player 8Tests/Phase29/ProjectSwitcherTests.swift` — Replaced XCTSkip stub with 5 real assertions.

## Decisions Made

- **Emoji glyph over SF Symbol in navItems.** UI-SPEC recommended `video.badge.waveform` SF Symbol, but `navItems` is an emoji-glyph 4-tuple (per Phase 22 convention — all 35 other entries are emoji Unicode escapes). Used `\u{1F3A5}` 🎥 (movie camera) to maintain visual + type-system parity across the nav rail. SF Symbols can still land in downstream plans that own specific views.
- **Wave-3 scaffold excludes real SupabaseService fetch.** `loadProjects()` intentionally leaves `accessibleProjects = []` in both configured and unconfigured branches. Rationale: a UI shell wired to data it doesn't actually render yet is a code smell; the downstream plans (29-06 upload picker, 29-07 budget badge) that actually need the project list own the fetch. This keeps plan 29-05 at the scope declared in its objective.
- **ProjectSummary lives in LiveFeedView.swift, not LiveFeedModels.swift.** `LiveFeedModels.swift` is reserved for wire-format DTOs (LiveSuggestion shape) + AppStorage key constants. `ProjectSummary` is a view-layer projection of `cs_projects` — it doesn't decode from the network directly, so belongs alongside the view that iterates it.
- **AppStorage contract locked at UserDefaults layer in tests.** The 5 `ProjectSwitcherTests` assertions write/read via `UserDefaults.standard` directly rather than constructing SwiftUI views. `@AppStorage` binds to UserDefaults under the hood, so asserting the key strings + round-trip types at that layer tests the observable contract without SwiftUI lifecycle complications in XCTest.

## Deviations from Plan

None - plan executed exactly as written.

Both Task 1 and Task 2 hit their acceptance criteria on the first build pass. The plan's Step A / Step B / Step C / Step D / Step E / Step F sequencing translated directly to edits + Write calls with no auto-fixes needed. The movie-camera emoji choice is explicitly allowed by the plan ("Icon rationale: ... Executor may substitute any emoji that reads as 'live video' if preferred").

## Issues Encountered

- **Pre-existing test-target compile errors in `ready_player_8Tests.swift` (unrelated file).** The monolithic legacy test file (last touched by Phase 13-15 commit `9805e17`) has 15 Swift-6-style concurrency errors (`'async' call in a function that does not support concurrency`) at lines 103/110/118/125/132/138/150/409/414/420/425/431/436/441/447. These prevent `xcodebuild test` from compiling the test target. Logged to `.planning/phases/29-live-video-traffic-feed-sat-drone/deferred-items.md` per the executor scope-boundary rule: only auto-fix issues directly caused by the current task's changes. **The app target (`ready player 8` scheme) builds cleanly** — verified via `xcodebuild -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" build` → `BUILD SUCCEEDED`.
- **No iPhone 16 simulator available.** Switched to iPhone 17 (same arm64 simulator class). Not a bug — just a local environment note.

## User Setup Required

None — no external service configuration required. Plan 29-05 is pure iOS UI + test infrastructure; no secrets, no deploys.

## Next Phase Readiness

- **29-06 (iOS: scrubber + upload + library):** `LiveFeedPerProjectView` has 5 named placeholder sections labelled with "29-06" / "29-07" in source comments. `LiveFeedStorageKey.lastScrubTimestamp(projectId:)` is already exposed for the D-20 30s scrub-touched guard.
- **29-07 (iOS: suggestion cards + traffic + budget + analyze now):** `LiveSuggestion` Codable shape + `LiveSuggestionActionHint.StructuredFields` are locked; `isBudgetMarker` sentinel is available for the budget-reached UI. `LiveFeedStorageKey.suggestionModel` + `lastAnalyzedAt(projectId:)` are ready for the "Last analyzed N min ago" label.
- **29-08 (web parity):** iOS contract (key strings, severity enum values, LiveSuggestion shape) is now stable; web can mirror via `web/src/lib/live-feed/types.ts` without drift.
- **Shell data wiring gap:** `LiveFeedView.loadProjects()` is a Wave 3 stub that always leaves `accessibleProjects = []`. The first downstream plan that needs the project list (29-06 or 29-07) must wire `SupabaseService.shared.fetch("cs_projects")` through the authenticated client — NEVER service-role — and the RLS policy scopes by org_id (T-29-RLS-CLIENT mitigation).

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Completed: 2026-04-19*

## Self-Check: PASSED

**Files created (verified):**
- FOUND: `ready player 8/LiveFeed/LiveFeedModels.swift`
- FOUND: `ready player 8/LiveFeed/LiveFeedView.swift`
- FOUND: `ready player 8/LiveFeed/LiveFeedPerProjectView.swift`
- FOUND: `ready player 8/LiveFeed/LiveFeedFleetView.swift`
- FOUND: `ready player 8/LiveFeed/FleetProjectTile.swift`
- FOUND: `ready player 8/LiveFeed/ProjectSwitcherSheet.swift`

**Commits recorded (verified):**
- FOUND: `2334176` — Task 1 (NavTab + LiveFeedModels)
- FOUND: `6bd0da6` — Task 2 (5 view files + ProjectSwitcherTests)

**Key contract checks:**
- FOUND: 1× `case liveFeed = "live-feed"` in ContentView.swift (line 555)
- FOUND: 1× `("live-feed","LIVE FEED",` navItems entry (line 591)
- FOUND: 1× `case .liveFeed: LiveFeedView()` activeTabContent switch (line 750)
- FOUND: 1× `cs_live_suggestions` in SupabaseService.allowedTables
- FOUND: 0× `XCTSkip` in NavTabLiveFeedTests.swift (down from 1)
- FOUND: 0× `XCTSkip` in ProjectSwitcherTests.swift (down from 1)
- FOUND: `BUILD SUCCEEDED` on iPhone 17 Simulator with `ready player 8` scheme
