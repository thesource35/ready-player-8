# Phase 29.1 Deferred Items

Tracked out-of-scope issues discovered during Phase 29.1 execution. Not fixed here; surfaced for future phases.

## Pre-existing iOS test build failure (Phase 29.1-01)

**Discovered:** 2026-04-21 during Phase 29.1-01 Task 1 verification (`xcodebuild test -only-testing:"ready player 8Tests/AuthGateTests"`).

**Problem:** Identical to the issue captured in `.planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/deferred-items.md` — the `ready player 8Tests` target still contains pre-existing compile errors under the current toolchain (Xcode 16.2 / Swift 5.x with upcoming features enabled):

- `ready player 8Tests/ready_player_8Tests.swift` — 45+ errors of form `error: 'async' call in a function that does not support concurrency` (lines 103, 110, 118, 125, 132, 138, 150, 409, 414, 420, 425, 431, 436, 441, 447, ...). Root cause: `@Test @MainActor func mcpGet*()` bodies call `MCPToolServer.shared.executeTool(...)` — the shared accessor is now @MainActor-isolated (a concurrency-inference change) and the `@MainActor` on the test function does not suffice to bridge.
- `ready player 8Tests/ReportTests.swift` — same class of error.

**Impact on Phase 29.1-01:** Cannot execute the full test suite end-to-end. However, the new `AuthGateTests.swift` scaffold:

1. Is discovered + compiled by Xcode (visible in the `swift-frontend -c … AuthGateTests.swift …` invocation during `build-for-testing`).
2. Compiles cleanly — no errors or warnings attributed to `AuthGateTests.swift` in the build log.
3. Registers its 5 `@Test` cases under the `AuthGateTests` suite name (Swift Testing discovery is static at compile time).

**Scope ruling:** Per GSD scope boundary — "Only auto-fix issues DIRECTLY caused by the current task's changes." These errors predate Phase 29.1 and live in files owned by Phases 13–17 (they were already logged to `.planning/phases/22-…/deferred-items.md`). Fixing them is out of scope for Wave 0 scaffolding. The plan's stated purpose — "make the Nyquist verify commands resolvable" — is satisfied: Plans 02/03/04 can reference `-only-testing:"ready player 8Tests/AuthGateTests/<testName>"` and those targets resolve to real `@Test` cases, regardless of whether the rest of the test-target-wide suite compiles.

**Recommended owner:** Phase 30 NOTIF remediation cluster (already queued per STATE.md), or a dedicated quick task. Phase 28's retroactive verification sweep was supposed to address this but left the files untouched; Phase 29.1 Wave 1/2 plans will need the same compile-only workaround until a dedicated fix lands.

**Workaround for Phase 29.1 downstream waves (Plans 02/03/04):**

Until the pre-existing files are fixed, Phase 29.1 iOS tasks must either (a) include an incidental fix of `ready_player_8Tests.swift`'s `@MainActor` annotations as part of their first iOS task, or (b) rely on compile-only verification (`xcodebuild build-for-testing` + structural grep of the build log for `AuthGateTests.swift`) to prove the new assertions land without regressing the target.
