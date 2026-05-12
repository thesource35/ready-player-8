---
phase: 260511-thn
plan: 01
subsystem: ios-ci
tags:
  - ios
  - swift6
  - charts
  - ci-honesty
  - quick-task
  - 999.10-followup
requires:
  - 260511-7vh (b293291) -- the un-silenced CI that surfaced these errors
provides:
  - Green xcodebuild build against iPhone 17 sim (local default)
  - Green xcodebuild build against iPhone 16e sim (local CI-parity substitute)
  - Expected GREEN next CI push on macos-15 + Xcode 16.4 + iPhone 16 Pro/iOS 18.5
affects:
  - All 74 CrashReporter.shared.reportError(...) call sites (now callable from any context)
  - AppStorageJSON.swift:17,30,41 (loadJSON/saveJSON nonisolated callers unblocked)
  - LeverageSystemView leverage history chart rendering
tech-stack:
  added: []
  patterns:
    - "nonisolated func + Task { @MainActor in ... } body wrap pattern for fire-and-forget MainActor mutators"
    - "@ChartContentBuilder explicit annotation to disambiguate Chart{} result-builder when MapKit is transitively imported"
key-files:
  created: []
  modified:
    - "ready player 8/AppInfrastructure.swift (line 86 + body lines 87-100 -> 95-104)"
    - "ready player 8/LeverageSystemView.swift (added @ChartContentBuilder var lines 124-133, collapsed Chart{} lines 137-146 -> 147)"
    - "/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md (line 6 iOS 26.2+ -> iOS 18.2+)"
decisions:
  - "T-thn-01 fallback ladder step 1 triggered: bare `nonisolated` rejected by compiler (default-isolation=MainActor + @Published crashLogs + saveJSON all require MainActor); body wrapped in `Task { @MainActor in ... }` per plan-prescribed first fallback. Step 2 (`nonisolated(unsafe)`) NOT needed."
  - "Chart pattern (a) chosen (private @ChartContentBuilder var) over inline `Chart { @ChartContentBuilder in ... }` for clearer separation and easier future test surface."
  - "iPhone 16 Pro / iOS 18.5 destination unavailable locally (only iOS 26.3 runtime installed); iPhone 16e on iOS 26.3 used as local CI-parity substitute. Real CI verification deferred to next push per Phase 22/29.1/30 compile-only precedent (mirrors 260511-7vh pattern)."
  - "NetworkClient.swift:143 Sendable warning left untouched -- not a hard build-blocker (warns but compiles). Bundling deferred to Swift 6 audit phase per CONTEXT 'Claude's Discretion' guidance."
metrics:
  duration_minutes: 5
  files_modified: 3
  lines_changed_repo: "+32 / -24"
  lines_changed_outside_repo: "+1 / -1 (MEMORY.md)"
  commits: 1
  completed_date: "2026-05-12"
---

# Quick Task 260511-thn: Fix iOS Compile Errors Surfaced by 999.10 CI Summary

**One-liner:** Two surgical iOS edits (`nonisolated` + `@ChartContentBuilder`) plus one user-memory line correction (iOS 18.2+) close the build errors that 999.10's CI honesty fix exposed; next CI push expected to land green on macos-15 + Xcode 16.4 + iPhone 16 Pro/iOS 18.5.

## Verification Table (4 named expected outcomes, mirrors 260511-7vh pattern)

| # | Scenario | Local Result | CI Expectation |
|---|----------|-------------|----------------|
| 1 | iPhone 17 sim local build | **PASSED** -- `** BUILD SUCCEEDED **` (commit e5d6f74 verified 2026-05-12) | N/A (local-only convention per Phase 22/29.1/30.x) |
| 2 | iPhone 16 Pro / iOS 18.5 sim local build (exact CI parity) | **NOT RUN LOCALLY** -- only iOS 26.3 runtime installed on this Mac; iOS 18.5 SDK + iPhone 16 Pro device profile not present | Will be verified on next CI push (canonical iOS 18.5 venue) |
| 3 | iPhone 16e on iOS 26.3 local build (CI-parity substitute) | **PASSED** -- `** BUILD SUCCEEDED **` (closest local proxy for iPhone 16 Pro family available with installed runtime) | Confirms cross-device build cleanliness within available local sims |
| 4 | NetworkClient.swift:143 Sendable warning | **DEFERRED** -- not a hard build-blocker (warns but compiles); per CONTEXT discretion left for Swift 6 audit phase | Will continue to warn on CI; not gating |

## Diff Stat

```
ready player 8/AppInfrastructure.swift  | 34 +++++++++++++++++++--------------
ready player 8/LeverageSystemView.swift | 22 +++++++++++----------
2 files changed, 32 insertions(+), 24 deletions(-)
```

Plus MEMORY.md (outside repo): 1 line changed.

## What Shipped

### Edit A: AppInfrastructure.swift — `nonisolated func reportError` + Task wrap

- Added `nonisolated` modifier to `func reportError(...)` at line 86 (D-01 decision).
- **T-thn-01 fallback ladder step 1 triggered**: bare `nonisolated` was rejected by the compiler with 5 errors (deviceModel() main-actor isolation; crashLogs @Published mutation; saveJSON main-actor isolation under project-level `default-isolation=MainActor`). Per plan, wrapped the body in `Task { @MainActor in ... }`. Acceptable fire-and-forget log-ordering shift.
- 3-line comment block added to mark the fallback for future Swift 6 audit reference.
- Pre-extracted `let fileName = URL(fileURLWithPath: file).lastPathComponent` outside the Task to avoid capturing `file` (already a String constant; clarity over necessity).
- Class-level `@MainActor` annotation untouched.
- `@Published var crashLogs` untouched.
- All 74 caller sites untouched (verified via grep -- API change is a strict superset).

### Edit B: LeverageSystemView.swift — `@ChartContentBuilder private var leverageChartContent`

- Added new private `@ChartContentBuilder` computed var immediately above `leverageHistoryPanel` (D-02 pattern (a)).
- Replaced the inline `Chart { ForEach { ... } }` (lines 137-146) with `Chart { leverageChartContent }` (line 147 in updated file).
- All `.chartYScale`, `.chartYAxis`, `.frame`, `.padding`, `.background`, `.cornerRadius`, `.premiumGlow` modifiers preserved byte-identical.
- T-thn-02 mitigated: pre-edit grep proved 0 hits for `leverageChartContent` (name was free).
- Imports unchanged (`import Charts` already present at top of file).

### Edit C: MEMORY.md — `iOS 26.2+` -> `iOS 18.2+`

- D-03 ("Trust pbxproj") executed: line 6 of user-memory MEMORY.md changed.
- pbxproj `IPHONEOS_DEPLOYMENT_TARGET = 18.2` confirmed unchanged (6 hits; truth source preserved).
- macOS target left at `15.6+` (per plan scope discipline -- CONTEXT decision section only locks the iOS fix).

## Threat Model Outcomes

| Threat | Disposition | Outcome |
|--------|-------------|---------|
| T-thn-01 (data race on crashLogs) | mitigate | **Fallback ladder step 1 triggered**: `Task { @MainActor in ... }` body wrap. Step 2 (`nonisolated(unsafe)`) NOT needed. Logging is fire-and-forget so log-ordering shift is acceptable per plan acceptance. |
| T-thn-02 (naming collision) | mitigate | Pre-edit grep confirmed `leverageChartContent` was free (0 hits). Post-edit: 2 hits (declaration + call site). |
| T-thn-03 (test target regression) | accept | Compile-only `xcodebuild build` used; build-for-testing NOT attempted (still blocked by pre-existing `ready_player_8Tests.swift` + `ReportTests.swift` async errors per Phase 22/29.1/30 deferred-items). |
| T-thn-04 (MEMORY.md doc edit info disclosure) | accept | MEMORY.md is local user memory (not in repo, not deployed). Edit reduces a misleading claim. |
| T-thn-05 (silent CI green) | mitigate | Verification compounded: `xcodebuild build` exit 0 AND grep proofs (nonisolated + @ChartContentBuilder + leverageChartContent x2) -- same compound-AND pattern that caught 999.10's silent no-op trap. |

## Deviations from Plan

**1. [Rule 1 - Bug] T-thn-01 fallback ladder step 1 triggered (anticipated by plan)**

- **Found during:** Task 1, first build attempt against iPhone 17 sim
- **Issue:** Bare `nonisolated func reportError` rejected with 5 errors: `deviceModel()` is MainActor-isolated; `crashLogs` is `@Published` (MainActor-mutable only); `saveJSON()` is MainActor-isolated under project-level `default-isolation=MainActor` (set in pbxproj as `-default-isolation=MainActor`).
- **Fix:** Per plan T-thn-01 fallback ladder step 1 -- wrapped function body in `Task { @MainActor in ... }`. Pre-extracted `let fileName = URL(fileURLWithPath: file).lastPathComponent` outside Task for readability (file is already a String constant; either captures cleanly).
- **Files modified:** `ready player 8/AppInfrastructure.swift` (additional 6 lines beyond the bare `nonisolated` change for the Task wrap + comment block)
- **Commit:** e5d6f74

This deviation was explicitly anticipated by the plan ("If Swift 6 strict mode rejects the nonisolated body because of `crashLogs` mutation: First fallback: Wrap the body in `Task { @MainActor in ... }`"). Step 2 (`nonisolated(unsafe)`) was NOT needed -- step 1 sufficed. Provides data point for future Swift 6 audit phase: this codebase enables `default-isolation=MainActor` upcoming feature, so any `nonisolated` member that touches stored properties on a MainActor class will need either Task hop or actor-safe storage.

**2. [Out-of-scope-discovery] CI-parity destination iPhone 16 Pro/iOS 18.5 not installable locally**

- **Found during:** Task 1, second build attempt
- **Issue:** Only iOS 26.3 runtime is installed on this Mac (`xcrun simctl list runtimes available` shows only `iOS 26.3 (26.3.1)`). iPhone 16 Pro is in Apple's device profile but requires iOS 18.5 SDK to instantiate -- not present. xcodebuild reports it under "Ineligible destinations".
- **Fix:** Per CONTEXT discretion ("If iPhone 17 sim isn't available locally, fall back per CONTEXT discretion") -- substituted iPhone 16e on iOS 26.3 (closest available local proxy for the iPhone 16 family). Build succeeded against both iPhone 17 and iPhone 16e. Real CI iOS 18.5 verification deferred to next push, mirroring 260511-7vh's deferred-CI-observation pattern.
- **Files modified:** None (environmental discovery only)
- **Commit:** N/A

This is a pure local-environment limitation, not a code issue. The CI runs on macos-15 with Xcode 16.4 (which ships iOS 18.5 SDK) and is the canonical iOS 18.5 venue per the 999.10 fix.

## Authentication Gates

None encountered.

## Cross-Reference

- **Backlog 999.10** (b293291): This commit (e5d6f74) is the FIRST push that exercises the un-silenced CI installed by 999.10. Outcomes feed back into 999.10's deferred CI verification (T-999.10-04 acceptance). If next CI push lands GREEN against iPhone 16 Pro/iOS 18.5, both 999.10 and 260511-thn close cleanly.
- **Phase 22 / 29.1 / 30 compile-only precedent**: This task uses `xcodebuild build` (NOT `build-for-testing`). Pre-existing `ready_player_8Tests.swift` + `ReportTests.swift` async errors continue to block test target -- tracked in deferred-items, not in scope here.
- **Quick task 260511-7vh** (b293291): Direct upstream -- fixed the silent no-op CI; this task fixes the errors that the un-silenced CI now surfaces.

## Next Steps

1. Push commit e5d6f74 to main; observe CI run (the actual iPhone 16 Pro/iOS 18.5 verification venue).
2. If CI lands GREEN: backlog 999.10 closes-CONFIRMED; this task closes COMPLETE.
3. If CI surfaces additional errors: scope a follow-up quick task (NetworkClient Sendable, ReportTests async cleanup, or whatever surfaces) -- T-thn-04 per CONTEXT canonical_refs is the established pattern for serial CI gap closure.

## Self-Check: PASSED

Verified files exist:
- FOUND: `ready player 8/AppInfrastructure.swift` (modified, contains `nonisolated func reportError` x1)
- FOUND: `ready player 8/LeverageSystemView.swift` (modified, contains `@ChartContentBuilder` x1, `leverageChartContent` x2)
- FOUND: `/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md` (modified, `iOS 26.2` x0, `iOS 18.2` x1)

Verified commits exist:
- FOUND: e5d6f74 -- `fix(260511-thn-01): close iOS Swift 6 + Charts inference compile errors surfaced by 999.10 CI`

Verified build outcomes:
- FOUND: `** BUILD SUCCEEDED **` against iPhone 17 sim
- FOUND: `** BUILD SUCCEEDED **` against iPhone 16e sim
- DEFERRED-TO-CI: iPhone 16 Pro/iOS 18.5 (runtime not installed locally; CI is canonical venue)

Verified pbxproj truth preserved:
- FOUND: `IPHONEOS_DEPLOYMENT_TARGET = 18.2` x6 in `ready player 8.xcodeproj/project.pbxproj` (unchanged)
