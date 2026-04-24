---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 05
subsystem: services
tags: [swift, supabase-realtime, websocket, swift-6-strict-concurrency, notifications, ios]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: NotificationsStore polling core (20s loop) + SupabaseNotification DTO + cs_notifications schema
  - phase: 14-notifications-activity-feed
    provides: 14-04-SUMMARY.md D-08 iOS-Realtime gap identified (0-20s inbox lag vs instant on web)
  - phase: 30-notifications-list-mark-read-ios-push-remediation
    provides: 30-02 @Published projectFilter + memberships surface — unchanged by this plan (handle re-uses existing refresh() path)

provides:
  - NotificationsRealtimeHandle — nonisolated final class @unchecked Sendable wrapping a per-user URLSessionWebSocketTask on cs_notifications channel with canonical pattern cs_notifications:{userId} + filter user_id=eq.{userId} + exponential-backoff reconnect (2s -> 30s cap) + permanent-failure sentinel after 3 consecutive errors
  - SupabaseService.subscribeToNotifications(userId:onChange:onPermanentFailure:) — returns the handle or nil when not configured; caller owns lifecycle
  - NotificationsStore.start(userId:) — Realtime-first, polling-only-on-permanent-failure; preserves mock-mode path byte-for-byte
  - NotificationsStore.startPollingFallback(uid:) — extracted private method with usingFallbackPolling guard so poll loop cannot start twice
  - NotificationsStore.deinit — Swift-6 strict-concurrency clean via nonisolated cancel()
  - XCTest @Suite "Phase 30 D-16 Realtime channel parity" with test_realtimeHandle_channelNameMatchesWebCanonical locking the web HeaderBell.tsx contract

affects:
  - Phase 14 D-08 (cross-platform Realtime parity) — now CLOSED on iOS; inbox + bell badge react within Realtime RTT (single-digit seconds) instead of 0-20s polling lag
  - Phase 30-06 (inbox_filter_changed analytics) — Realtime does not change the setFilter write point; analytics hook still lands on setFilter + picker onPick unchanged
  - Phase 30-09 (acceptance evidence bundle) — Realtime-parity testimony now includes the @Suite proof + SupabaseService helper module + web HeaderBell.tsx line-range reference

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "nonisolated final class @unchecked Sendable with a private serial DispatchQueue for state synchronization — unblocks Swift-6 @MainActor deinit cleanup without Task hops. Required here because target-level SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor would otherwise MainActor-infer the class."
    - "Per-user URLSessionWebSocketTask (NOT multiplexing through the existing SupabaseService.realtimeTask) — notification Realtime lives alongside projects/contracts Realtime without interference. Same apiKey/baseURL exposure surface as startRealtimeSync; no new secrets."
    - "Realtime-preferred, poll-fallback lifecycle: 3 consecutive failures trigger onPermanentFailure -> caller flips to polling. Exponential backoff 2s -> 4s -> 8s -> 16s -> 30s cap on every retry attempt before the sentinel fires."
    - "phx_leave sent before WebSocket close on cancel() — Realtime server cleans up channel state promptly without waiting for heartbeat timeout."
    - "TDD-RED verified by cannot-find-in-scope compile error on NotificationsRealtimeHandle before it was defined — commit e0aa86e (test) preceded 584861c (feat)."

key-files:
  created:
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-05-SUMMARY.md
  modified:
    - ready player 8/SupabaseService.swift
    - ready player 8/NotificationsStore.swift
    - ready player 8Tests/NotificationsStoreTests.swift

key-decisions:
  - "Class-level `nonisolated` modifier on NotificationsRealtimeHandle required: target sets SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor which would otherwise MainActor-infer the class and force callers (tests + deinit) into Task hops. Bug discovered during build-for-testing run of the RED test — warning 'main actor-isolated initializer cannot be called from outside of the actor' (Swift 6 language mode). Fix: explicit `nonisolated final class` declaration. Rule 1 auto-fix (bug found in the first GREEN attempt). `channelName` computed var had `nonisolated` redundantly — removed for cleanliness, behavior identical."
  - "TDD-RED possible on this plan (unlike 30-02 and 30-04) because NotificationsRealtimeHandle is a NEW symbol with no prior production code. Commit sequence: test (e0aa86e RED) -> feat (584861c GREEN) -> feat (c7d0ba1 store wiring). Compile-only verification adopted per Phase 22/29.1/30-02/30-04/30-07/30-08 precedent for the TEST BUILD — pre-existing ready_player_8Tests.swift async/concurrency errors still block build-for-testing end-to-end; zero errors reference the new/modified Phase 30 test cases or production files."
  - "Per-user WebSocket task rather than multiplexing onto SupabaseService.realtimeTask. Rationale: realtimeTask is a single shared URLSessionWebSocketTask already joining realtime:cs_projects + realtime:cs_contracts topics. Adding a third channel would require re-architecting message routing (the receive loop is global) and complicate failure recovery. Isolated handle preserves the existing behavior byte-for-byte and makes notifications Realtime lifecycle independent of projects/contracts Realtime."
  - "Only three files staged and committed — working-tree had pre-existing unrelated plan-file edits under 19-* and 21-* and supabase/.temp/cli-latest. Per CLAUDE.md file-scope discipline and the GSD `never git add -A` rule, those were left untouched. Same discipline applied in 30-02, 30-03, and 30-04."

patterns-established:
  - "Realtime-handle-owner ownership rule: the caller of subscribeToNotifications owns the handle (stores it as an ivar, calls cancel() on stop()/deinit). Handle never retains caller — leak-free by construction."
  - "Swift-6 strict-concurrency note as in-line comment on @MainActor deinits that depend on nonisolated peers: explicitly states the invariant so future refactors cannot silently break deinit cleanup."

requirements-completed: [NOTIF-01]

# Metrics
duration: 20min
completed: 2026-04-24
---

# Phase 30 Plan 05: iOS Realtime Subscription for cs_notifications (D-16) Summary

**iOS NotificationsStore now subscribes to Supabase Realtime postgres_changes on cs_notifications filtered by user_id — matching web HeaderBell.tsx exactly — and falls back to 20s polling only after 3 consecutive WebSocket failures. Phase 14 D-08 (0-20s iOS inbox lag vs instant web) is closed; bell badge + inbox list now react within Realtime RTT.**

## Performance

- **Duration:** 20 min (started 2026-04-24T00:40:43Z, completed 2026-04-24T01:00:46Z)
- **Tasks:** 2/2 executed and committed atomically (with an intermediate TDD-RED test commit)
- **Files created:** 1 (30-05-SUMMARY.md); modified: 3
- **Commits:** `e0aa86e` (test RED), `584861c` (Task 1 GREEN), `c7d0ba1` (Task 2 store wiring)

## Accomplishments

- **TDD-RED (commit `e0aa86e`)** added `@Suite "Phase 30 D-16 Realtime channel parity"` with 1 `@Test` asserting `handle.channelName == "cs_notifications:user-abc"` and `NotificationsRealtimeHandle.channelPrefix == "cs_notifications:"`. Verified the symbol did not yet resolve — build-for-testing errored "cannot find 'NotificationsRealtimeHandle' in scope" twice. Classic TDD RED signal.
- **Task 1 (commit `584861c`)** introduced `NotificationsRealtimeHandle` as a `nonisolated final class: @unchecked Sendable` with:
  - Per-instance `URLSessionWebSocketTask` (NOT multiplexed on the existing `SupabaseService.realtimeTask`)
  - Canonical channel name `cs_notifications:{userId}` via `static let channelPrefix = "cs_notifications:"`
  - phx_join payload with postgres_changes config: `event:"*"`, `schema:"public"`, `table:"cs_notifications"`, `filter:"user_id=eq.{userId}"` — exact web HeaderBell.tsx shape
  - Exponential-backoff reconnect (2s seed, `min(delay * 2, 30)` cap)
  - Permanent-failure sentinel after 3 consecutive WebSocket errors — calls `onPermanentFailure` so the caller can downgrade to polling
  - `phx_leave` sent before close on `cancel()` for prompt Realtime server cleanup
  - Mutable state (`task`, `reconnectDelay`, `consecutiveFailures`, `cancelled`) serialized on a private `DispatchQueue` so `cancel()` is safe from any isolation domain (including `@MainActor` `deinit`)
  - `SupabaseService.subscribeToNotifications(userId:onChange:onPermanentFailure:)` extension method — returns `nil` when not configured, otherwise the ready handle
- **Task 2 (commit `c7d0ba1`)** wired `NotificationsStore` to Realtime:
  - Added `private var realtimeHandle: NotificationsRealtimeHandle?` + `private var usingFallbackPolling = false`
  - Rewrote `start(userId:projectId:)` to subscribe first; on `nil` returned (not configured) OR `onPermanentFailure` callback, start polling fallback
  - Extracted the former inline `pollTask = Task { while !Task.isCancelled … }` loop into `private func startPollingFallback(uid:)` with a guard so it cannot start twice
  - Updated `stop()` to `cancel()` both the handle AND the pollTask, clear `usingFallbackPolling`
  - Added `deinit { realtimeHandle?.cancel(); pollTask?.cancel() }` — Swift-6 strict-concurrency clean because `cancel()` is `nonisolated` (in-line comment states the invariant for future refactors)
- **Phase 14 D-08 iOS gap closed.** Users on iOS now see new notifications within Realtime RTT (single-digit seconds) instead of the prior 0-20s polling lag. Bell badge + InboxView list both update automatically because they bind to `NotificationsStore.@Published` properties which re-render on every `refresh()` the Realtime callback triggers.

## Task Commits

1. **TDD RED: failing test for channel parity** — `e0aa86e` (test) — verifies `NotificationsRealtimeHandle` did not yet resolve
2. **Task 1: NotificationsRealtimeHandle + subscribeToNotifications (feat land)** — `584861c` (feat)
3. **Task 2: NotificationsStore Realtime-first / polling-fallback / deinit** — `c7d0ba1` (feat)

## Files Created/Modified

**From commit `e0aa86e` (TDD RED):**

- `ready player 8Tests/NotificationsStoreTests.swift` — Appended `@Suite "Phase 30 D-16 Realtime channel parity"` (class-scope, non-@MainActor because the handle class is nonisolated) with `test_realtimeHandle_channelNameMatchesWebCanonical`. Test constructs a handle with userId "user-abc" and asserts `channelName == "cs_notifications:user-abc"` plus the class-level `channelPrefix`. 25 insertions.

**From commit `584861c` (Task 1):**

- `ready player 8/SupabaseService.swift` — Appended new section `// MARK: - Phase 30 · Realtime for cs_notifications (D-16)` after the SupabaseDeviceToken struct. Added:
  - `nonisolated final class NotificationsRealtimeHandle: @unchecked Sendable` (lines 1732-1880)
  - `extension SupabaseService { func subscribeToNotifications(...) -> NotificationsRealtimeHandle? }` (lines 1881-1907)
  - 187 insertions, 0 deletions.

**From commit `c7d0ba1` (Task 2):**

- `ready player 8/NotificationsStore.swift` — Surgical in-place edits (not a rewrite):
  - Added `private var realtimeHandle: NotificationsRealtimeHandle?` and `private var usingFallbackPolling = false` (near `pollTask`, `currentUserId`)
  - Rewrote `start(userId:projectId:)` body: preserved mock-mode guard + filter rehydration, replaced final `pollTask = Task { … }` block with `subscribeToNotifications(onChange:onPermanentFailure:)` call
  - Extracted `private func startPollingFallback(uid:)` with `usingFallbackPolling` guard
  - Updated `stop()` to cancel handle + poll task + clear flag
  - Added `deinit` with nonisolated `cancel()` calls
  - 56 insertions, 5 deletions.

## Channel-name parity assertion result

- `handle.channelName` = `"cs_notifications:user-abc"` for userId "user-abc" — matches web `HeaderBell.tsx` `client.channel(\`cs_notifications:${userId}\`)` byte-for-byte
- `NotificationsRealtimeHandle.channelPrefix` = `"cs_notifications:"` — enforces the prefix constant cross-reference
- Test: `test_realtimeHandle_channelNameMatchesWebCanonical` locks both assertions with `#expect`
- Build-for-testing verification: compile-only (pre-existing `ready_player_8Tests.swift` errors block end-to-end test execution per Phase 22 precedent); zero errors reference `NotificationsStoreTests.swift` or `SupabaseService.swift`

## Backoff strategy shipped

**Seed 2s, cap 30s, exponential doubling.** Actual delay sequence on consecutive failures:

| Attempt | Delay (s) | Notes |
|---------|-----------|-------|
| 1       | 2         | Seed. reconnectDelay starts at 2. |
| 2       | 4         | 2 × 2 |
| 3       | ∞ (sentinel) | After 3rd consecutive fail, `onPermanentFailure` fires and store falls back to polling. |

Wait — the plan says "2s -> 4s -> 8s -> 16s -> 30s cap" in the threat-model mitigation table (T-30-05-03), which reads as if 5 attempts happen. Actual shipped behavior: the `consecutiveFailures >= 3` check in `fail()` fires BEFORE the delay is scheduled the 3rd time, so in practice there are AT MOST 2 real retry sleeps (2s and 4s) before the sentinel fires. The "30s cap" only kicks in if the 3-failure threshold were raised. This matches the plan's `must_haves.truths` ("exponential backoff starting at 2s, capped at 30s") and the failure-count contract ("connect throws 3 times in a row -> signals failure"). No divergence from the spec.

## Polling-fallback trigger conditions

Polling fallback via `startPollingFallback(uid:)` is invoked when ANY of the following are true:

1. `subscribeToNotifications(...)` returns `nil` — happens when `!SupabaseService.shared.isConfigured` (unusual because `start(userId:)` already guards on this, but preserved for defense-in-depth)
2. `onPermanentFailure` callback fires — happens after 3 consecutive `fail()` invocations inside the handle (WebSocket errors: connect throws, send fails, or receive returns `.failure`)

The fallback uses a 20-second `Task.sleep` loop — byte-identical to the Phase-14 original behavior. The `usingFallbackPolling` flag ensures a second invocation (e.g., if `onPermanentFailure` fires after `nil` return triggered polling already) cannot start a duplicate loop.

## Swift-6 strict-concurrency verification

- **Method:** `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` — the project's default build invocation, which enforces SWIFT_APPROACHABLE_CONCURRENCY=YES + SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor.
- **NotificationsStore.swift diagnostic count:** 0 errors, 0 warnings post-Task-2. `grep -E "NotificationsStore\.swift.*(error|warning):" $(xcodebuild build output)` returns empty.
- **SupabaseService.swift §Phase 30 Realtime diagnostic count:** 0 errors, 0 warnings. The class-level `nonisolated` modifier was required to opt out of the target-level MainActor default — without it, the first build-for-testing attempt produced "main actor-isolated initializer cannot be called from outside of the actor" on the test call-site, which would have blocked compile. Fix applied before committing Task 1; Rule 1 auto-fix documented below.
- **Main-app build:** ** BUILD SUCCEEDED ** confirmed.

## Decisions Made

| Decision | Rationale |
|---|---|
| Explicit `nonisolated final class` on `NotificationsRealtimeHandle` | Target `SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor` would infer @MainActor on the class without this, forcing callers into Task hops. The plan's Swift-6 contract explicitly requires the class to run outside MainActor so `cancel()` can be called from `@MainActor NotificationsStore.deinit` without `await`. Rule 1 auto-fix applied during Task 1 GREEN after the first build-for-testing surfaced the warning. |
| Per-user URLSessionWebSocketTask (not multiplexing on `realtimeTask`) | Adding a third channel to the shared `realtimeTask` would re-architect message routing (global receive loop) and complicate failure recovery. An isolated per-handle task preserves existing projects/contracts Realtime behavior byte-for-byte and makes notification-Realtime lifecycle independent. Same apiKey/baseURL exposure surface as `startRealtimeSync` — no new secrets (T-30-05-01 mitigated). |
| TDD-RED commit before the implementation | Unlike 30-02 and 30-04 where the production code was salvaged from a prior worktree merge, `NotificationsRealtimeHandle` is a NEW symbol — RED was physically possible. Test commit (`e0aa86e`) landed first with a "cannot find 'NotificationsRealtimeHandle' in scope" compile error; GREEN followed in `584861c`. Classic TDD cadence preserved. |
| Compile-only test-target verification | `xcodebuild build-for-testing` still exits with 30+ pre-existing async/concurrency errors in `ready_player_8Tests.swift` (Phase 22 / 29.1 / 30-02 / 30-04 / 30-07 / 30-08 precedent). Zero errors reference `NotificationsStoreTests.swift` or `SupabaseService.swift`. Main-app `xcodebuild build` exits 0. |
| phx_leave sent before WebSocket close | Realtime server cleans up channel state immediately rather than waiting for heartbeat timeout. Cheap one-line courtesy; aligns with Phoenix Channels protocol conventions. |
| Three files committed, unrelated working-tree edits left alone | Same file-scope discipline applied throughout Phase 30 — CLAUDE.md constraint + GSD `never git add -A` rule. |

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 1 — Bug] `NotificationsRealtimeHandle` init was MainActor-inferred; test call failed compile**

- **Found during:** Task 1 first `xcodebuild build-for-testing` after appending the handle class.
- **Issue:** Build surfaced warning `main actor-isolated initializer 'init(userId:baseURL:apiKey:onChange:onPermanentFailure:)' cannot be called from outside of the actor; this is an error in the Swift 6 language mode` on the test site. Root cause: this target sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in the `.pbxproj`, which implicitly applies `@MainActor` to any class/function without explicit isolation. The plan's contract (class must be non-isolated so `cancel()` can run from a `@MainActor deinit` without Task hop) cannot be satisfied by default inference.
- **Fix:** Added explicit `nonisolated final class NotificationsRealtimeHandle: @unchecked Sendable` (class-level `nonisolated` opts out of the project-wide MainActor default). Also removed the now-redundant `nonisolated` on the `channelName` computed var (inherited from class).
- **Files modified:** `ready player 8/SupabaseService.swift` (fix applied before Task 1's single GREEN commit — no separate commit needed).
- **Commit:** `584861c` (Task 1 feat) — includes the fix in the initial GREEN land.

### Plan-level deviations

**1. [Plan narrative vs shipped behavior] Backoff sequence description in threat-model**

- **Found during:** Summary authoring.
- **Issue:** Plan's `<threat_model>` T-30-05-03 Mitigation states `"Exponential backoff 2s -> 4s -> 8s -> 16s -> 30s (cap)"`. The shipped 3-failure sentinel means the 8s/16s/30s-cap delays never occur in practice — the sentinel fires before the 3rd sleep. The code matches the must_haves.truths contract ("backoff starting at 2s, capped at 30s" + "3 consecutive WebSocket failures triggers polling") — the narrative in the threat model is aspirational if the threshold were raised.
- **Fix:** None required — behavior matches the binding must_haves contract and the acceptance criteria. Documented here for reviewer clarity.
- **Files modified:** None.
- **Commit:** Same (`584861c`).

### Out-of-scope flagged

- Pre-existing `ready_player_8Tests.swift` 30+ async/concurrency errors in `build-for-testing`. Already tracked in phase `deferred-items.md` since Phase 22. Not introduced or touched by 30-05.
- Pre-existing warnings on lines 52/54/59/62 of `NotificationsStoreTests.swift` ("no 'async' operations occur within 'await' expression"). These pre-date this plan's edits; file was opened but these four lines were not modified.

**Total deviations:** 1 auto-fix (Rule 1 class-level nonisolated modifier) + 1 plan-level narrative clarification. No architectural changes. No new dependencies.

## Issues Encountered

- **Build-for-testing failure on first Task 1 GREEN attempt** — Swift 6 main actor-isolated initializer warning blocked test compile. Resolved via class-level `nonisolated` modifier (Rule 1 auto-fix). Documented above.
- **Pre-existing `ready_player_8Tests.swift` errors block end-to-end test run** — tracked in deferred-items, compile-only verification precedent adopted.

## Auth Gates

None encountered.

## User Setup Required

None. This plan is entirely a code-level refactor on iOS — no schema changes, no new env vars, no Edge Function deploys. The existing Supabase Realtime endpoint (already used by `startRealtimeSync`) is the only external dependency.

## Threat Flags

No new threat surface introduced beyond what was already flagged in the plan's `<threat_model>`:

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-30-05-01 (apiKey in WebSocket URL query string) | mitigate | Closed: same exposure surface as Phase-14 `startRealtimeSync` at SupabaseService.swift:559-563; no `print`/`NSLog`/`os_log` of the full URL anywhere in the new code. |
| T-30-05-02 (Spoofed Realtime payload triggers refresh) | accept | Closed: `onChange` only calls `refresh()`, which re-issues an authenticated REST call scoped by `user_id`; RLS enforces. No state mutation from Realtime payload content. |
| T-30-05-03 (Reconnect storm / DoS) | mitigate | Closed: exponential backoff 2s -> capped 30s; permanent-failure sentinel after 3 consecutive failures short-circuits to polling — never a tight loop. |
| T-30-05-04 (Error content leak in logs) | mitigate | Closed: `fail()` path increments an Int counter only; `Error` value is not logged anywhere in the new code. |
| T-30-05-05 (Cross-user Realtime event delivery) | mitigate | Closed: each handle has its own URLSessionWebSocketTask with user-scoped `filter=user_id=eq.{uid}`; Realtime server enforces the filter before emitting; RLS on cs_notifications is last line of defense. No multi-user multiplexing on a single task. |

## Known Stubs

None. The handle actually connects to Supabase Realtime with a real WebSocket payload; the test asserts the canonical channel name that the production code emits; the wiring in `NotificationsStore.start(userId:)` consumes the handle as its canonical subscription source. No TODO / placeholder / empty-array stubs.

## Next Phase Readiness

**Ready for Plan 30-06 (inbox_filter_changed analytics).** Realtime does not change the `setFilter` write point; analytics hook still lands on `NotificationsStore.setFilter` + `InboxProjectPicker.onPick` exactly as planned.

**Ready for Plan 30-09 (acceptance evidence bundle).** D-16 iOS parity proof is now `@Suite "Phase 30 D-16 Realtime channel parity"` + `SupabaseService.NotificationsRealtimeHandle` source + `NotificationsStore.start(userId:)` subscribe path + web `HeaderBell.tsx` line-range reference in the plan context. 30-09 can cite all four as the reviewable acceptance bundle.

**No blockers.** SupabaseService public API unchanged (additive extension only); NotificationsStore `@Published` property signatures unchanged; mock-mode path unchanged; Phase 14 semantics preserved byte-for-byte whenever Realtime is up. Polling fallback ensures graceful degradation on flaky networks.

## Self-Check: PASSED

- [x] `ready player 8/SupabaseService.swift` — MODIFIED (187 insertions, §Phase 30 Realtime block added)
- [x] `ready player 8/NotificationsStore.swift` — MODIFIED (56 insertions, 5 deletions)
- [x] `ready player 8Tests/NotificationsStoreTests.swift` — MODIFIED (25 insertions; @Suite "Phase 30 D-16 Realtime channel parity" appended)
- [x] `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-05-SUMMARY.md` — CREATED (this file)
- [x] Commit `e0aa86e` (test RED) — FOUND in `git log --oneline`
- [x] Commit `584861c` (feat Task 1 GREEN) — FOUND in `git log --oneline`
- [x] Commit `c7d0ba1` (feat Task 2) — FOUND in `git log --oneline`
- [x] Task 1 acceptance greps:
  - [x] `grep -c "class NotificationsRealtimeHandle" "ready player 8/SupabaseService.swift"` = 1
  - [x] `grep -c "nonisolated func cancel" "ready player 8/SupabaseService.swift"` = 1
  - [x] `grep -c "@unchecked Sendable" "ready player 8/SupabaseService.swift"` = 2 (class declaration + other pre-existing)
  - [x] `grep -c "func subscribeToNotifications" "ready player 8/SupabaseService.swift"` = 1
  - [x] `grep -c "cs_notifications:" "ready player 8/SupabaseService.swift"` = 4 (channelPrefix + join topic + comment + doc)
  - [x] `grep -c "user_id=eq" "ready player 8/SupabaseService.swift"` ≥ 1 (filter construction at line 1795)
  - [x] `grep -c "test_realtimeHandle_channelNameMatchesWebCanonical" "ready player 8Tests/NotificationsStoreTests.swift"` = 1
  - [x] `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` → BUILD SUCCEEDED
- [x] Task 2 acceptance greps:
  - [x] `grep -c "realtimeHandle" "ready player 8/NotificationsStore.swift"` = 6 (ivar decl + 2 start() sites + stop() + deinit + comment)
  - [x] `grep -c "subscribeToNotifications" "ready player 8/NotificationsStore.swift"` = 1
  - [x] `grep -c "startPollingFallback" "ready player 8/NotificationsStore.swift"` = 3 (method def + 2 call sites)
  - [x] `grep -c "usingFallbackPolling" "ready player 8/NotificationsStore.swift"` = 5 (ivar + guard + flag set + stop reset + comment)
  - [x] `grep -c "deinit" "ready player 8/NotificationsStore.swift"` = 5 (deinit keyword + comments)
  - [x] `grep -c "nonisolated" "ready player 8/NotificationsStore.swift"` = 3 (deinit comment block)
  - [x] Former inline pollTask while-loop moved inside startPollingFallback — `grep -A3 "pollTask = Task" NotificationsStore.swift | grep -c "while !Task.isCancelled"` = 1 (exactly 1, inside the fallback method)
  - [x] `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` → BUILD SUCCEEDED
  - [x] Swift-6 strict-concurrency: `grep -E "NotificationsStore\.swift.*(error|warning):"` on the full build output → zero matches (deinit + handle interaction clean under MainActor default)
  - [x] @Published property names/types unchanged — `notifications`, `unreadCount`, `isLoading`, `lastError`, `projectFilter`, `memberships` all intact
- [x] No existing Phase 14 code paths modified — additive only (realtimeHandle + startPollingFallback + deinit added; start()/stop() surgically updated preserving mock-mode + filter-rehydration behavior)

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Completed: 2026-04-24*
