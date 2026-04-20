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
