# Phase 22 Deferred Items

Tracked out-of-scope issues discovered during Phase 22 execution. Not fixed here; surfaced for future phases.

## Pre-existing iOS test build failure (Phase 22-00)

**Discovered:** 2026-04-15 during Phase 22-00 Task 2 verification (`xcodebuild test -only-testing:"ready player 8Tests/VideoTests"`).

**Problem:** Xcode builds the entire `ready player 8Tests` target before running `-only-testing` filter. Two pre-existing files fail to compile under the current toolchain:

- `ready player 8Tests/ready_player_8Tests.swift` — 45+ errors of form `error: 'async' call in a function that does not support concurrency` (lines 103, 110, 118, 125, 132, 138, 150, 409, 414, 420, 425, 431, 436, 441, 447, ...).
- `ready player 8Tests/ReportTests.swift` — same class of error.

**Impact on Phase 22-00:** Cannot execute XCTest VideoTests target end-to-end. However, all four new VideoTests/*.swift stub files compile cleanly and are correctly discovered by the build system (they appear in the swift-frontend compile command alongside the other tests). The skip logic in the stubs (`throw XCTSkip(...)`) is idiomatic; the files are structurally sound.

**Scope ruling:** Per GSD scope boundary — "Only auto-fix issues DIRECTLY caused by the current task's changes." These errors predate Phase 22 and live in files owned by Phases 13–17. Fixing them is out of scope for Wave 0 scaffolding.

**Recommended owner:** Either a dedicated quick task ("fix ready_player_8Tests.swift + ReportTests.swift async/concurrency annotations") or the Phase 28 retroactive verification sweep.

**Workaround for downstream waves:** Until the pre-existing files are fixed, Phase 22 iOS waves (22-02, 22-05, 22-06) must either (a) include an incidental fix as part of their first iOS task, or (b) tolerate that `xcodebuild test -only-testing:VideoTests` returns "build failed" and rely on compile-only verification (`xcodebuild build-for-testing`) plus structural checks for the VideoTests stubs.
