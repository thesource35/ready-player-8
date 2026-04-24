---
phase: 30-notifications-list-mark-read-ios-push-remediation
verified: 2026-04-24T00:05:00Z
status: gaps_found
score: 21/23 must-haves verified (2 UAT-gated: deferred)
gaps:
  - truth: "User receives push notifications on a real iPhone for bid_deadline, safety_alert, and assigned_task categories (NOTIF-05)"
    status: failed
    reason: "Plan 30-09 Tasks 2-4 explicitly deferred by operator (Option B). Apple Developer portal Push Notifications capability was NOT toggled during this phase; no real-device UAT performed; no 3 category screenshots captured; 30-UAT-LOG.md is a stub with every data cell still marked {NEEDS-FILL}; 30-09-SUMMARY.md does not exist. Code + CI regression floor are fully in place (28/28 Deno tests green, APNs entitlement + device-token registration shipped Phase 14-05) — remediation is purely human/operational."
    artifacts:
      - path: ".planning/phases/30-notifications-list-mark-read-ios-push-remediation/assets/"
        issue: "Directory does not exist; the 3 required UAT screenshots (30-uat-screenshot-bid-deadline.png, -safety-alert.png, -assigned-task.png) are absent"
      - path: ".planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-UAT-LOG.md"
        issue: "File exists but is an explicit stub — every data cell (UAT date, device, build commit, trigger/receive timestamps, latency, log observations, cleanup) is {NEEDS-FILL}; prose header states 'STATUS: STUB — awaiting real-device UAT'"
      - path: ".planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-09-SUMMARY.md"
        issue: "File does not exist; Plan 30-09 has no completion SUMMARY because Tasks 2-4 were skipped"
    missing:
      - "Apple Developer portal: toggle Push Notifications capability on App ID nailed-it-network.ready-player-8 (follow 30-DEPLOY-STEPS.md Steps 1-6)"
      - "Real-device fresh build on a paired iPhone with updated provisioning profile (30-DEPLOY-STEPS.md Steps 7-13)"
      - "3 UAT screenshots: one per category (bid_deadline / safety_alert / assigned_task) saved under .planning/phases/30-.../assets/30-uat-screenshot-{category}.png"
      - "Negative control observation: insert a row that produces category='generic' and confirm NO push arrives (validates D-16 gate end-to-end)"
      - "Fill every {NEEDS-FILL} in 30-UAT-LOG.md with real values (device, build commit, timestamps, log counts)"
      - "Author 30-09-SUMMARY.md closing out the plan + record REQUIREMENTS.md before/after flip for NOTIF-05"
  - truth: "REQUIREMENTS.md NOTIF-05 Traceability row reflects Phase 30 outcome"
    status: partial
    reason: "NOTIF-05 still shows Unsatisfied [ ] + Phase 30 remediation planned. Code evidence (Phase 14-02 fanout + Phase 14-05 iOS registration) and test evidence (Phase 30-08 Deno suite 28/0 green) are now in place, but the UAT evidence required to flip the row is missing per the gap above. Intentional — orchestrator should NOT flip NOTIF-05 until the 30-09 UAT lands."
    artifacts:
      - path: ".planning/REQUIREMENTS.md"
        issue: "Line 189 shows 'NOTIF-05 | Phase 30 (remediation planned); UAT deferred 2026-04-19 | Unsatisfied'. No update needed yet — accurate reflection of current state."
    missing:
      - "After 30-09 UAT completes, flip NOTIF-05 line 26 from '[ ]' to '[x]' AND Traceability line 189 status from 'Unsatisfied' to 'Satisfied' (orchestrator owns this)"

human_verification:
  - test: "Real-device APNs delivery UAT (Plan 30-09 Tasks 2-4)"
    expected: "Three push banners (one per NOTIF-05 category) delivered to a physical paired iPhone with aps-environment=development; screenshots captured; negative control (category='generic') produces NO push; no BadDeviceToken / Unregistered / 410 responses in notifications-fanout Edge Function logs for the UAT device"
    why_human: "Requires (a) human sign-in to https://developer.apple.com to toggle the Push Notifications capability on the App ID — Apple publishes no API for this, (b) a physical paired iPhone running iOS 18.2+ (Simulator cannot receive APNs sandbox pushes per D-18), (c) human visual confirmation + screenshot capture of the push banner, (d) human observation + log filtering in the Supabase Dashboard during a live UAT window. No automation exists for any of the four steps."
---

# Phase 30: Notifications List + Mark-Read + iOS Push Remediation — Verification Report

**Phase Goal:** User can view a notification list with unread count badge on web parity with iOS, mark notifications as read individually (per-row) or all at once on both platforms, and receive iOS push notifications for bid deadlines, safety alerts, and assigned tasks on a real device.

**Verified:** 2026-04-24T00:05:00Z
**Status:** gaps_found (NOTIF-05 real-device UAT explicitly deferred by operator per Option B)
**Re-verification:** No — initial verification (plan-level 30-01-VERIFICATION.md exists but no phase-level predecessor)
**Requirements in scope:** NOTIF-01, NOTIF-03, NOTIF-05 + internal decisions D-01..D-24

## Phase Scope Context

The phase ROADMAP entry advertised 9 plans. 8 were executed autonomously (30-01 through 30-08). Plan 30-09 is `autonomous: false` by design — it contains two `checkpoint:human-action` gates (Apple Developer portal toggle + 3-screenshot UAT). Per operator instruction (Option B), Task 1 of 30-09 (the 30-DEPLOY-STEPS.md runbook + 30-UAT-LOG.md stub) was committed in `e5b64ce`; Tasks 2-4 (portal toggle + real device build + screenshots + UAT log finalization + 30-09-SUMMARY.md) were deferred because the Apple Dev account + iPhone combination was not available during the phase window.

As a result, Plans 30-01..30-08 fully deliver the NOTIF-01 + NOTIF-03 parts of the phase goal (web mark-read, cross-platform project-filter picker, filter-scoped mark-all + 99+ cap parity, iOS Realtime, analytics, entity passthrough regression, push Edge Function Deno coverage). NOTIF-05 push delivery has code + test evidence but has NOT been proven end-to-end on a real device.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Web /inbox per-row READ button mutates read_at via a React 19 Server Action (no POST→PATCH 404) | VERIFIED | `web/src/app/inbox/actions.ts` exports `markReadAction` with `"use server"` directive + `revalidatePath("/inbox")`; `web/src/app/inbox/page.tsx` grep returns 0 for `_method`, 3 for `markReadAction`/`markAllReadAction`; 8 vitest cases in `markReadAction.test.ts` + `markAllReadAction.test.ts` green |
| 2 | Web /inbox MARK ALL READ respects the active ?project_id= filter via the same Server Action path | VERIFIED | `markAllReadAction` in `actions.ts` reads `project_id` from FormData (empty→null); `markAllRead(projectId)` applies `.eq('project_id', id)` when set; `web/src/lib/notifications/markAllReadFilterScoped.test.ts` asserts this via a chainable fake Supabase stub (4/4 green) |
| 3 | REST PATCH/DELETE/POST surface on /api/notifications/[id] and /api/notifications/mark-all-read is byte-preserved for iOS + programmatic callers (D-03) | VERIFIED | 30-01-VERIFICATION.md: PATCH=1, DELETE=1, POST=1 export counts unchanged |
| 4 | iOS InboxView toolbar renders a Menu picker with "All Projects" pinned + per-project unread chips + D-09 sort (unread-desc-then-latest) | VERIFIED | `ready player 8/InboxView.swift` grep: `Menu {`, `"All Projects"`, `Show all projects`, `membershipSort`, `store.setFilter`, `store.projectFilter` all present (17 total matches); `InboxViewTests.swift` has 5 Phase-30 cases covering sort order + empty-state branching |
| 5 | iOS filter selection persists to AppStorage key ConstructOS.Notifications.LastFilterProjectId with silent stale-id recovery on launch (D-10/D-11) | VERIFIED | `NotificationsStore.swift` grep: `ConstructOS.Notifications.LastFilterProjectId` literal + `setFilter` + `projectFilter` present; `NotificationsStoreTests.swift` ships `staleFilterRecovery`, `persistedFilterRehydrates`, `setFilterWritesUserDefaults` cases |
| 6 | Web /inbox has a project-filter dropdown mirroring iOS: "All Projects" pinned, sorted memberships with unread chips, URL ?project_id= routing, localStorage persistence under "constructos.notifications.last_filter_project_id" (D-06..D-12) | VERIFIED | `web/src/app/inbox/InboxProjectPicker.tsx` (185 LOC, `"use client"`) exists with router.push, router.replace, LAST_FILTER_STORAGE_KEY, All Projects label (17 grep matches); `page.tsx` mounts `<InboxProjectPicker>` and branches empty-state with "No notifications for" + "Show all projects"; `projectMemberships.test.ts` + `inboxFilterStorage.test.ts` cover the contract (6 cases) |
| 7 | Cross-platform storage key parity: iOS AppStorage key and web localStorage key both encode "last filter project id" under a semantically equivalent frozen string (D-10) | VERIFIED | iOS: `ConstructOS.Notifications.LastFilterProjectId` (PascalCase per iOS convention); Web: `constructos.notifications.last_filter_project_id` (lowercase.dot-delimited per web convention); `inboxFilterStorage.test.ts` locks the web form; iOS XCTest `persistedFilterRehydrates` locks the iOS form |
| 8 | Filter-scope parity (D-13): MARK ALL READ narrows to project_id = filter when active; bell badge always queries globally; sub-count templates the filtered project name | VERIFIED | `30-PARITY-SPEC.md` §Canonical Unread-Count Query + §Scope Contract Table + §Mark-All-Read Scope Contract authored 2026-04-22; `SupabaseService.buildMarkAllReadQueryString(userId:projectId:)` extracted as single source of truth; XCTest `test_markAllRead_withFilter_preservesProjectFilterInPATCHQuery` calls the real helper via `@testable import`; web `markAllReadFilterScoped.test.ts` asserts `.eq('project_id', ...)` behavior on both branches |
| 9 | Bell badge cap: 0→"", 1..99→raw, ≥100→"99+" (D-15) | VERIFIED | Web: `bellBadge99Cap.test.ts` 5/5 green (0, -5, 99, 100, 501); iOS: `NotificationsStoreTests.swift` 5 `test_formatBadge_*` cases covering the same boundaries |
| 10 | iOS NotificationsStore subscribes to Supabase Realtime postgres_changes on cs_notifications filtered by user_id, matching web HeaderBell channel name "cs_notifications:{userId}" exactly (D-16) | VERIFIED | `SupabaseService.swift` contains `class NotificationsRealtimeHandle` with `nonisolated func cancel` + `@unchecked Sendable` + `static let channelPrefix = "cs_notifications:"`; `subscribeToNotifications(userId:onChange:onPermanentFailure:)` extension method exists; `NotificationsStore.swift` wires `realtimeHandle` + `startPollingFallback` (polling only as fallback); `test_realtimeHandle_channelNameMatchesWebCanonical` XCTest locks the contract |
| 11 | Realtime polling fallback activates only after 3 consecutive WebSocket failures; exponential backoff 2s→30s cap; no leaked WebSocket across stop()/deinit | VERIFIED | `NotificationsStore.swift` `startPollingFallback(uid:)` extracted with `usingFallbackPolling` guard; `deinit` calls nonisolated `realtimeHandle?.cancel()` (Swift-6 strict-concurrency clean per 30-05-SUMMARY.md); backoff sequence verified in 30-05-SUMMARY.md §Backoff strategy shipped |
| 12 | inbox_filter_changed analytics event fires on diff-changed picker selection only (not hydration); payload EXACTLY {from_project_id, to_project_id, unread_count_at_change}; no PII keys (D-17) | VERIFIED | Web: `web/src/lib/analytics/inboxFilter.ts` exports `emitInboxFilterChanged` + `sanitizeInboxFilterPayload` + `INBOX_FILTER_CHANGED_EVENT`; `inboxFilter.test.ts` 7/7 green including PII-absence assertion `Object.keys(p).sort() === ['from_project_id','to_project_id','unread_count_at_change']`; iOS: `NotificationsStore.setFilter(_:)` body contains `if prev != projectId` diff-gate + `emitFilterChangedAnalytics` helper calling `AnalyticsEngine.shared.track("inbox_filter_changed", ...)`; grep for `setProjectFilter` = 0 (no parallel setter) |
| 13 | entity_id / entity_type columns pass through the web fetch and iOS DTO decode unchanged — deep-link deferred phase ships with zero wire-format work (D-24) | VERIFIED | Web: `entityPassthrough.test.ts` 4/4 green (fetchNotifications round-trip, null preservation, MOCK_NOTIFICATIONS fixture completeness, type-level assertion); iOS: `SupabaseNotificationDTOTests.swift` 3 cases (snake_case decode, null preservation, omitted-key tolerance) all compile clean |
| 14 | Push Edge Function (notifications-fanout) has first-class regression coverage for the 4 D-21 axes: category allowlist, device-token query shape, APNs payload shape, BadDeviceToken prune + redaction | VERIFIED | 4 new Deno test files exist (`push-categories.test.ts` 9 cases + `device-token-lookup.test.ts` 3 cases + `apns-payload-shape.test.ts` 3 cases + `bad-device-token.test.ts` 3 cases); full `deno test --allow-env --no-check supabase/functions/notifications-fanout/` re-run at verification time: **28 passed / 0 failed (419ms)** — exceeds ≥21 plan acceptance floor |
| 15 | APNs BadDeviceToken / Unregistered / 410 responses prune the stale token from cs_device_tokens; raw device_token string never appears in console.error logs (redaction invariant, T-30-08-01) | VERIFIED | `bad-device-token.test.ts` asserts prune on 400 BadDeviceToken + 410 Unregistered; asserts NO prune on 500; redaction invariant uses `logs.every(l => !l.includes(token))` substring-negative across all three failure modes. Re-run at verification time: passing. |
| 16 | APNsRegistrationTests.swift (Phase 14-05) is byte-identical since ship — D-22 audit recorded (shasum + last-commit timestamp + 0 uncommitted diff) | VERIFIED | 30-08-SUMMARY.md D-22 Audit Evidence: shasum `93581122217f703a4a8e05da33c9a5e4202edf4f`, last commit `9805e17` (pre-Phase-30), `git diff = 0 lines` |
| 17 | 30-PARITY-SPEC.md exists and documents the canonical unread-count SQL verbatim, scope contract table, display-cap rules, mark-all-read scope contract (with helper-extraction callout), regression coverage list, and non-goals (D-13/D-14/D-15) | VERIFIED | File read: 77 lines, all 7 sections present. `grep "read_at IS NULL AND dismissed_at IS NULL"` returns 2 hits; `grep "99+"` returns 5; `grep "buildMarkAllReadQueryString"` returns 2 |
| 18 | 30-DEPLOY-STEPS.md operator runbook exists (D-19) with exact click-path URLs, verification SQL, troubleshooting, and §Troubleshooting: Forcing a bid_deadline push during UAT (manual Edge Function invoke contract) | VERIFIED | File read: all sections present. Contains `developer.apple.com/account/resources/identifiers`, `nailed-it-network.ready-player-8`, `aps-environment=development`, `Authorization: Bearer`, `SUPABASE_SERVICE_ROLE_KEY`, `Content-Type: application/json`, `200` response, `inserted.*skipped` body shape, `13:00 UTC` / `pg_cron`, and `Production Cutover (DEFERRED per D-20)` |
| 19 | D-20 APNs production cutover is explicitly deferred and documented (not on v2.1 roadmap) | VERIFIED | 30-DEPLOY-STEPS.md §Production Cutover explicitly states "NOT on the current v2.1 roadmap per D-20. Do NOT flip aps-environment=production for this UAT." |
| 20 | D-23 notification-tap deep-link routing is explicitly deferred (D-24 future-prep makes it cheap to add) | VERIFIED | 30-07-SUMMARY.md audit result confirms production code untouched; entity_type/entity_id passthrough contracts locked with 4 vitest + 3 XCTest regressions; PARITY-SPEC §Non-Goals explicitly scopes out deep-link routing |
| 21 | Web vitest notifications + analytics suites fully green after all 8 plans land | VERIFIED | Re-run at verification time (`npx vitest run src/lib/notifications/ src/lib/analytics/inboxFilter.test.ts`): **11 test files, 45 tests, 45 passed, 0 failed** |
| 22 | Main iOS app compiles successfully with all Phase 30 iOS Swift additions | VERIFIED | Every Phase 30 iOS-touching SUMMARY (30-02, 30-04, 30-05, 30-06, 30-07) records `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` → BUILD SUCCEEDED. Known constraint: `xcodebuild build-for-testing` still blocks on pre-existing async errors in `ready_player_8Tests.swift` (Phase 22 / 29.1 precedent logged in deferred-items.md) — zero errors reference Phase-30-modified files. |
| 23 | User receives push notifications on a real iPhone for bid_deadline, safety_alert, and assigned_task categories (NOTIF-05 end-to-end) | FAILED (deferred) | Plan 30-09 Tasks 2-4 explicitly deferred by operator (Option B). No assets/ directory; 30-UAT-LOG.md is a stub ({NEEDS-FILL} on every cell); 30-09-SUMMARY.md does not exist. Code + CI regression floor in place (28/28 Deno tests + APNs entitlement + device-token registration + operator runbook all committed in `e5b64ce` + earlier commits), but end-to-end human UAT has not occurred. |

**Score:** 21/23 verified (2 FAILED/PARTIAL: truth #23 is a deferred UAT gap; truth at `gaps[1]` is the REQUIREMENTS.md flip consequent on #23).

### Required Artifacts

#### Web (NOTIF-03 + NOTIF-01 + D-17 + D-24)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `web/src/app/inbox/actions.ts` | Server Actions markReadAction + markAllReadAction with `"use server"` + revalidatePath | VERIFIED | `"use server"` on line 1; 3 grep matches for action names; revalidatePath called twice |
| `web/src/app/inbox/page.tsx` | Mounts actions + InboxProjectPicker + filter-aware empty state; zero `_method` | VERIFIED | `markReadAction`/`markAllReadAction` + `InboxProjectPicker` + `Show all projects` + `No notifications for` + `fetchProjectMembershipsWithUnread` all present (10 matches); `_method` grep = 0 |
| `web/src/app/inbox/InboxProjectPicker.tsx` | Client component with All Projects pinned + router.push/replace + localStorage + emit hook | VERIFIED | 17 grep matches for `use client|InboxProjectPicker|router.push|router.replace|LAST_FILTER_STORAGE_KEY|emitInboxFilterChanged|unreadCountAtSelect` |
| `web/src/lib/notifications.ts` | Adds fetchProjectMembershipsWithUnread + LAST_FILTER_STORAGE_KEY + resolveStalePickerFilter | VERIFIED | 3 grep matches for the helper symbols; `"constructos.notifications.last_filter_project_id"` literal present on line 296 |
| `web/src/lib/notifications/markReadAction.test.ts` | 4 vitest cases | VERIFIED | Ships with vi.hoisted mocks + 4 cases green |
| `web/src/lib/notifications/markAllReadAction.test.ts` | 4 vitest cases | VERIFIED | 4 cases green |
| `web/src/lib/notifications/projectMemberships.test.ts` | 5 cases covering mock-mode shape + resolveStalePickerFilter | VERIFIED | 5 cases green |
| `web/src/lib/notifications/inboxFilterStorage.test.ts` | 1 case locking the localStorage key string | VERIFIED | 1 case green |
| `web/src/lib/notifications/markAllReadFilterScoped.test.ts` | 4 cases covering filter-on + filter-off + payload keys + signed-out | VERIFIED | 4 cases green |
| `web/src/lib/notifications/bellBadge99Cap.test.ts` | 5 cases at the 0 / -5 / 99 / 100 / 501 boundaries | VERIFIED | 5 cases green |
| `web/src/lib/notifications/entityPassthrough.test.ts` | 4 cases locking entity_id/entity_type passthrough | VERIFIED | 4 cases green |
| `web/src/lib/analytics/inboxFilter.ts` | emitInboxFilterChanged + sanitizer + const | VERIFIED | Ships 50 LOC with all three exports |
| `web/src/lib/analytics/inboxFilter.test.ts` | 7 cases locking payload shape + PII absence | VERIFIED | 7 cases green |

#### iOS (NOTIF-01 + D-13..D-17 + D-24)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ready player 8/InboxView.swift` | Toolbar Menu picker + filter-aware empty state + static helpers | VERIFIED | 17 grep matches for `Menu {`, `All Projects`, `Show all projects`, `emptyStateCopyForFilter`, `membershipSort`, `store.setFilter`, `store.projectFilter` |
| `ready player 8/NotificationsStore.swift` | @Published projectFilter + memberships + setFilter + loadMemberships + lastFilterKey + realtimeHandle + startPollingFallback + deinit + inbox_filter_changed emit | VERIFIED | 29 grep matches across the required symbols; `func setProjectFilter` grep = 0 (single-setter invariant held) |
| `ready player 8/SupabaseService.swift` | fetchProjectMembershipsWithUnread + ProjectMembershipUnread + NotificationsRealtimeHandle + subscribeToNotifications + buildMarkAllReadQueryString | VERIFIED | 21 grep matches across all six symbols |
| `ready player 8Tests/InboxViewTests.swift` | Phase 30 @Suite with emptyStateCopyForFilter + membershipSort + inboxSubCount cases | VERIFIED | 12 grep matches |
| `ready player 8Tests/NotificationsStoreTests.swift` | Phase 30 @Suites for filter persistence (30-02) + badge cap + D-13 filter parity (30-04) + Realtime channel parity (30-05) + D-17 payload contract (30-06) | VERIFIED | 15 grep matches across all target test names; includes `SupabaseService.buildMarkAllReadQueryString` real-helper call sites |
| `ready player 8Tests/SupabaseNotificationDTOTests.swift` | 3 XCTest cases for entity_id/entity_type decode (30-07) | VERIFIED | 3 cases compile clean |
| `ready player 8Tests/APNsRegistrationTests.swift` (D-22 audit) | Byte-identical since Phase 14-05 | VERIFIED | shasum + last-commit + git diff recorded in 30-08-SUMMARY.md |

#### Edge Function (NOTIF-05 / D-21 / D-22)

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/functions/notifications-fanout/push-categories.test.ts` | 9 Deno cases locking the allowlist | VERIFIED | Re-run green |
| `supabase/functions/notifications-fanout/device-token-lookup.test.ts` | 3 Deno cases locking query shape + error + zero-recipient short-circuit | VERIFIED | Re-run green |
| `supabase/functions/notifications-fanout/apns-payload-shape.test.ts` | 3 Deno cases locking aps.* + top-level invariants | VERIFIED | Re-run green |
| `supabase/functions/notifications-fanout/bad-device-token.test.ts` | 3 Deno cases locking stale prune + redaction | VERIFIED | Re-run green |

#### Phase Docs

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `30-PARITY-SPEC.md` | Canonical SQL + scope contract + cap rules + mark-all contract + regression coverage | VERIFIED | 77-line authoritative doc, all sections present |
| `30-DEPLOY-STEPS.md` | Operator runbook: portal click-path + verification SQL + troubleshooting + manual-invoke §Troubleshooting + D-20 deferral | VERIFIED | All acceptance-criteria greps pass |
| `30-UAT-LOG.md` | Structured log of 3 category deliveries + device + timestamps + log observations + closure | STUB | File exists but every data cell is {NEEDS-FILL}; marked "STATUS: STUB — awaiting real-device UAT" |
| `assets/30-uat-screenshot-bid-deadline.png` | Real-device push banner screenshot | MISSING | `assets/` directory does not exist |
| `assets/30-uat-screenshot-safety-alert.png` | Real-device push banner screenshot | MISSING | `assets/` directory does not exist |
| `assets/30-uat-screenshot-assigned-task.png` | Real-device push banner screenshot | MISSING | `assets/` directory does not exist |
| `30-09-SUMMARY.md` | Plan 30-09 closeout | MISSING | File does not exist (Plan 30-09 Tasks 2-4 deferred) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `web/src/app/inbox/page.tsx` | Server Actions | `import { markReadAction, markAllReadAction } from './actions'` | WIRED | Import + `<form action={markReadAction}>` + `<form action={markAllReadAction}>` (3 grep matches) |
| `web/src/app/inbox/actions.ts` | `@/lib/notifications` markRead/markAllRead | `import { markRead, markAllRead }` | WIRED | Both helpers imported + called; `revalidatePath("/inbox")` called twice |
| `web/src/app/inbox/page.tsx` | `<InboxProjectPicker />` | Client-component mount in header | WIRED | 1 mount site + memberships/currentProjectId/unreadCountAtSelect props forwarded |
| `InboxProjectPicker.tsx` | `next/navigation` useRouter | `router.push('/inbox?project_id=X')` + `router.replace('/inbox')` on stale/rehydrate | WIRED | Both router methods present |
| `InboxProjectPicker.tsx` | localStorage | `LAST_FILTER_STORAGE_KEY` + `window.localStorage.setItem/removeItem` | WIRED | Storage key constant imported + persistence on pick + rehydrate on mount |
| `InboxProjectPicker.tsx` | `@/lib/analytics/inboxFilter` | `import { emitInboxFilterChanged }` + diff-gated call in onPick | WIRED | Import + 1 diff-guarded call site (grep `from === to` within the emit context window) |
| `ready player 8/InboxView.swift` | `NotificationsStore.setFilter` / `.projectFilter` | Menu binding in toolbar | WIRED | Multiple grep hits on `store.setFilter` + `store.projectFilter` |
| `NotificationsStore.setFilter` | AppStorage `ConstructOS.Notifications.LastFilterProjectId` | UserDefaults.set/removeObject | WIRED | Literal key present + XCTest `setFilterWritesUserDefaults` asserts both directions |
| `NotificationsStore.setFilter` | `AnalyticsEngine.shared.track("inbox_filter_changed", ...)` | `if prev != projectId { emitFilterChangedAnalytics(...) }` at end of body | WIRED | diff-gate literal present; payload grep confirms PII absence |
| `NotificationsStore.start(userId:)` | `SupabaseService.subscribeToNotifications` | Handle stored; onPermanentFailure → startPollingFallback | WIRED | 1 call site; fallback path covered by `usingFallbackPolling` guard |
| `SupabaseService.subscribeToNotifications` | `URLSessionWebSocketTask` → wss Supabase realtime | Canonical channel `cs_notifications:{userId}` + filter `user_id=eq.{userId}` | WIRED | XCTest `test_realtimeHandle_channelNameMatchesWebCanonical` locks the name + prefix |
| `SupabaseService.markAllNotificationsRead` | `SupabaseService.buildMarkAllReadQueryString` | Production caller + XCTest via `@testable import` | WIRED | Helper consumed by production; XCTest calls the real symbol (grep = 3); no mirror (grep = 0) |
| `supabase/functions/notifications-fanout/index.ts` PUSH_CATEGORIES | `sendApns` | `PUSH_CATEGORIES.has(event.category)` gate | WIRED | 3 Deno tests enforce allowed/denied behavior; set size = 3 assertion |
| `notifications-fanout` ApnsError catch | `.delete().eq(user_id).eq(device_token)` on cs_device_tokens | 400/410 branches only | WIRED | 3 Deno tests enforce prune-on-400/410 + no-prune-on-500 + redaction invariant |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `/inbox/page.tsx` | `notifications`, `memberships` | `Promise.all([fetchNotifications(...), fetchProjectMembershipsWithUnread()])` against auth-bound Supabase client with `.select("*")` + RLS | Yes (RLS-gated live rows; mock fallback when unconfigured returns realistic 3-row / 2-membership fixtures) | FLOWING |
| `InboxProjectPicker.tsx` | `memberships`, `currentProjectId` | Server-Component props from page.tsx (not hardcoded; flows from RLS-gated fetch) | Yes | FLOWING |
| `InboxView.swift` picker Menu | `store.memberships` | `NotificationsStore.loadMemberships(userId:)` → `SupabaseService.fetchProjectMembershipsWithUnread(userId:)` with `withThrowingTaskGroup` fan-out | Yes (live query or mock fallback with 2 rows) | FLOWING |
| `NotificationsStore.notifications` | @Published array | `refresh()` → `SupabaseService.fetchNotifications` REST GET with user_id filter | Yes | FLOWING |
| Realtime `onChange` callback | (no state; triggers `refresh()`) | Fires on every cs_notifications INSERT/UPDATE/DELETE filtered by `user_id=eq.{uid}` | Yes (Phoenix postgres_changes payload) | FLOWING |

All artifacts that render dynamic data have traceable live data paths through RLS-gated queries. Mock mode is explicit fallback, not disconnected props.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Web notifications + analytics vitest suites pass | `cd web && npx vitest run src/lib/notifications/ src/lib/analytics/inboxFilter.test.ts` | 11 test files, 45/45 green (7.16s total) | PASS |
| Deno test suite for notifications-fanout passes | `deno test --allow-env --no-check supabase/functions/notifications-fanout/` | 28/28 green (419ms) | PASS |
| iOS main-app build compiles | `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` | BUILD SUCCEEDED per 30-02/04/05/06/07 SUMMARYs; orchestrator pre-run confirmed | PASS |
| Apple Developer portal Push Notifications capability toggled | (no automated check — requires human sign-in) | NOT PERFORMED (deferred) | SKIP (routed to human_verification) |
| Real-device push delivery for 3 NOTIF-05 categories | (no automated check — requires physical iPhone + UAT window) | NOT PERFORMED (deferred) | SKIP (routed to human_verification) |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|----------------|-------------|--------|----------|
| NOTIF-01 | 30-02, 30-03, 30-04, 30-05, 30-06, 30-07 | User can view in-app notification list with unread count badge | SATISFIED | Cross-platform picker + filter persistence + Realtime + analytics + entity passthrough all shipped with code + tests green. Web + iOS reach functional parity on list viewing and project filtering. Truths #4-14 verified. |
| NOTIF-03 | 30-01, 30-04 | User can mark notifications as read (individually or all) | SATISFIED | Web Server Action path shipped + 8 vitest cases green; REST surface preserved for iOS (D-03); filter-scoped mark-all asserted on both platforms (D-13). Truths #1-3, #8 verified. |
| NOTIF-05 | 30-08, 30-09 | User receives push notifications on iOS for bid deadlines, safety alerts, and assigned tasks | BLOCKED (UAT-gated) | Code evidence: Phase 14-02 fanout + Phase 14-05 iOS registration (out-of-scope but pre-existing). Test evidence: 30-08 Deno suite 28/0 green. Runbook evidence: 30-DEPLOY-STEPS.md committed. UAT evidence: MISSING — 30-09 Tasks 2-4 deferred. Truth #23 failed. Needs human verification. |

REQUIREMENTS.md orphan check: no additional requirement IDs mapped to Phase 30 beyond NOTIF-01/03/05; lines 185-189 of REQUIREMENTS.md accurately scope the three to Phase 30.

### Anti-Patterns Found

| File | Line(s) | Pattern | Severity | Impact |
|------|---------|---------|----------|--------|
| `.planning/phases/30-.../30-UAT-LOG.md` | Multiple | 22× `{NEEDS-FILL}` placeholder | INFO | Intentional stub per operator Option B deferral. Consumer of the log (future orchestrator flipping REQUIREMENTS.md NOTIF-05 row) must wait for UAT to fill cells. NOT a code-surface defect — file is prose documentation. |
| `ready player 8Tests/ready_player_8Tests.swift` | 30+ | Pre-existing Swift-6 async/concurrency errors blocking `xcodebuild build-for-testing` | WARNING | Inherited from Phase 22 / 29.1; not introduced by Phase 30. Every Phase-30 iOS SUMMARY documents compile-only verification per established precedent. Zero Phase 30 test files trigger errors. Logged in phase `deferred-items.md` and STATE.md. |
| `web/src/lib/live-feed/generate-suggestion.ts:154` | 154 | Pre-existing TS2741 (Phase 29 error) | INFO | Not introduced by Phase 30; logged in `deferred-items.md` during 30-01. |

No BLOCKER-class anti-patterns. Known stubs (SUMMARY self-reports "Known Stubs: None" on all 8 plans) were spot-checked — the mentioned code surfaces all bind to live data paths.

### Human Verification Required

#### 1. Real-device APNs delivery UAT (Plan 30-09 Tasks 2-4)

**Test:**
1. Follow `30-DEPLOY-STEPS.md` Steps 1-6 on https://developer.apple.com/account/resources/identifiers/list — toggle Push Notifications capability on App ID `nailed-it-network.ready-player-8`; Save; confirm provisioning-profile regeneration warning.
2. In Xcode, re-pull provisioning profile via Signing & Capabilities → Automatically manage signing off/on.
3. `Cmd+R` fresh build on a paired physical iPhone (iOS 18.2+); grant notification permission on first launch.
4. Run SQL Check 1 from the runbook — confirm a `cs_device_tokens` row exists for your user with `platform='ios'` + `last_seen_at` ≈ now.
5. For each NOTIF-05 category (bid_deadline, safety_alert, assigned_task), trigger a push per 30-09-PLAN.md Task 3; wait ≤30s; capture a screenshot of the push banner; save as `.planning/phases/30-.../assets/30-uat-screenshot-{category}.png`. For bid_deadline, use the `notifications-schedule` manual invoke documented in `30-DEPLOY-STEPS.md §Troubleshooting` if the pg_cron 13:00 UTC window hasn't fired.
6. Negative control: insert a row producing `category='generic'` (e.g. cs_daily_logs) and confirm NO push banner appears within 60s.
7. Fill `30-UAT-LOG.md` with real values for every `{NEEDS-FILL}` cell (UAT date, device, build commit, trigger/receive timestamps, latency, log observations, screenshot review, cleanup).
8. Create `30-09-SUMMARY.md` following the plan's `<output>` section (include before/after for the REQUIREMENTS.md NOTIF-05 flip).

**Expected:**
- 3 screenshots committed under `assets/` showing the push banners on the physical device (same device UI theme/status bar across all 3).
- Negative control confirmed: no push for `generic`.
- No `BadDeviceToken` / `Unregistered` / `410` / `500 InvalidProviderToken` responses in Supabase Edge Function logs during the UAT window (filter notifications-fanout Logs, last 1h).
- `cs_device_tokens` row for the UAT device still present post-UAT (no stale-token prune).
- `30-UAT-LOG.md` has zero `{NEEDS-FILL}` remaining.
- `30-09-SUMMARY.md` exists and cites the evidence chain.

**Why human:**
- Apple Developer portal publishes no API for App ID capability toggling (D-19) — literal human sign-in + click is the only path.
- APNs sandbox only delivers pushes to physical devices, not Simulator (D-18) — requires a real paired iPhone.
- Push banner capture is a visual/screenshot action; no headless automation can verify "a banner appeared on the lock screen".
- Supabase Edge Function log observation during a live UAT window (with correct time filtering) is an eyes-on-dashboard task.

### Gaps Summary

Phase 30 delivered 8 of 9 plans fully. Plans 30-01 through 30-08 shipped code + tests across 4 subsystems (web mark-read Server Actions, cross-platform project-filter picker, filter-scope / badge-cap parity lock, iOS Realtime, cross-platform analytics, DTO passthrough, push Edge Function regression). Every NOTIF-01 + NOTIF-03 observable truth is verified against the codebase (21/23 observable truths VERIFIED). Automated test floors are in place: 45/45 web vitest + 28/28 Deno tests passing at verification time; iOS main-app builds clean (compile-only test-target acceptance per long-standing Phase 22 precedent).

The one uncovered area is Plan 30-09's real-device UAT (NOTIF-05 truth #23). By operator directive (Option B):
- **Done:** The operator runbook `30-DEPLOY-STEPS.md` and the UAT-log stub `30-UAT-LOG.md` are committed (`e5b64ce`); 30-08's CI regression floor (28/28 Deno tests) ensures any future fanout regression fails CI before reaching this runbook.
- **Deferred:** Apple Developer portal capability toggle; fresh real-device build; 3 category push screenshots; UAT-log data finalization; 30-09-SUMMARY.md. These require an Apple Developer account + paired iPhone combo not available during the phase window.

This is a clean "code + test + runbook ready; awaiting human UAT" posture — not a design gap, build regression, or hidden stub. When the operator returns to close NOTIF-05, running `/gsd-plan-phase 30 --gaps` will re-plan the single remaining UAT task set from the structured `gaps:` frontmatter above.

Recommended next step for the orchestrator: surface `status: gaps_found` + the two structured gaps so the user is correctly routed to the closure workflow. Do NOT flip `REQUIREMENTS.md` NOTIF-05 Traceability row (line 189) from `Unsatisfied` until the UAT evidence lands.

---

*Verified: 2026-04-24T00:05:00Z*
*Verifier: Claude (gsd-verifier)*
