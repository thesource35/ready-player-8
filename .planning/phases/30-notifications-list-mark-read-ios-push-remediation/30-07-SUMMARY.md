---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 07
subsystem: ui
tags: [notifications, vitest, xctest, dto, regression, future-prep, d-24]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: cs_notifications entity_type/entity_id columns, Notification TS type, SupabaseNotification Swift DTO
  - phase: 28-retroactive-verification-sweep
    provides: NOTIF-01 Unsatisfied verdict that scoped this remediation into Phase 30

provides:
  - Vitest regression lock on entity_id/entity_type passthrough through fetchNotifications (D-24)
  - Vitest regression on MOCK_NOTIFICATIONS fixture completeness for deep-link dev
  - XCTest regression lock on SupabaseNotification JSON decode of entityType/entityId with convertFromSnakeCase (D-24)
  - Signed audit confirming fetchNotifications .select("*"), Notification type, and SupabaseNotification DTO already meet the D-24 contract

affects:
  - Deferred deep-link routing phase (D-23 / post-Phase-30) — can ship with zero schema migration or wire-format change; notification rows already carry the routing payload
  - Any future refactor of cs_notifications read paths — will fail vitest or xcodebuild if entity fields are silently dropped

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Defense-in-depth regression pattern: lock a passing contract with tests BEFORE a future refactor can silently break it"
    - "PostgREST fetch chain mocking in vitest via nested thenable factories (from -> select -> eq -> order -> limit -> is -> then)"
    - "Compile-only acceptance for iOS tests when ready_player_8Tests.swift pre-existing async errors block build-for-testing (Phase 22 / 29.1 precedent)"

key-files:
  created:
    - web/src/lib/notifications/entityPassthrough.test.ts
    - ready player 8Tests/SupabaseNotificationDTOTests.swift
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-07-SUMMARY.md
  modified: []

key-decisions:
  - "Audit found zero drift on either platform — MOCK_NOTIFICATIONS all carry entity_type+entity_id; Notification type has string | null on both; SupabaseNotification DTO has entityType/entityId as String?; no production repair required"
  - "Vitest mock uses nested thenable factories (not Supabase client mocking libs) to mirror the exact .select().eq().order().limit().is() chain fetchNotifications calls in the default no-project-filter path"
  - "iOS verification is compile-only per Phase 22 / 29.1 precedent: pre-existing async/concurrency errors in ready_player_8Tests.swift still block build-for-testing; new file compiles with zero errors/warnings and main app `xcodebuild build` SUCCEEDED"
  - "Type-level assertion shipped as a runtime test case (assignment literal) because tsc will fail the file if Notification drops either field"

patterns-established:
  - "Defense-in-depth regression suite pattern: audit first, lock second — production code untouched unless the audit finds drift"
  - "entity_type/entity_id as the locked deep-link payload contract for cs_notifications — future phases read these two columns, no new columns needed"

metrics:
  duration_minutes: 19
  completed_date: 2026-04-23
  commits:
    - "55b3822"
    - "56b8d4b"
---

# Phase 30 Plan 07: D-24 entity_id/entity_type passthrough regression lock Summary

One-liner: Audited and locked `entity_id`/`entity_type` passthrough on both platforms' cs_notifications read paths with 4 vitest + 3 XCTest regression cases so the deferred deep-link routing phase can ship with zero wire-format work.

## What shipped

### Audit result: production code untouched

All four production surfaces already meet the D-24 contract:

| Surface | Location | Finding |
|---------|----------|---------|
| Web fetch | `web/src/lib/notifications.ts:117` | `.select("*")` — all columns pass through unchanged |
| Web type | `web/src/lib/supabase/types.ts:233-234` | `entity_type: string \| null` + `entity_id: string \| null` — both present |
| Web mock fixture | `web/src/lib/notifications.ts:16-59` | All 3 MOCK_NOTIFICATIONS rows have non-null entity fields (mock-contract-1, mock-incident-1, mock-rfi-42) |
| iOS DTO | `ready player 8/SupabaseService.swift:1691-1692` | `entityType: String?` + `entityId: String?` — decoded via `.convertFromSnakeCase` |

No drift detected → no production repair needed. This plan is defense-in-depth regression coverage only.

### Tests added

**Web (`web/src/lib/notifications/entityPassthrough.test.ts`) — 4/4 vitest GREEN:**

1. `fetchNotifications preserves entity_type + entity_id from the server row` — fakes a Supabase row with `cs_rfis` + `rfi-42`, asserts round-trip via the full PostgREST fetch chain
2. `null entity fields stay null — no coercion to empty string or 'unknown'` — guards against accidental `|| ""` or `?? "unknown"` shrink-wrap
3. `MOCK_NOTIFICATIONS fixture keeps entity_type + entity_id populated for deep-link future-prep` — iterates the fixture, asserts both fields truthy on every row
4. `Notification type exposes entity_type + entity_id as string | null` — compile-time type assertion via literal assignment; if tsc passes, both fields exist

**iOS (`ready player 8Tests/SupabaseNotificationDTOTests.swift`) — 3 @Test cases, compile-clean:**

1. `test_decode_preservesEntityIdAndEntityType` — server-shape JSON with snake_case keys decodes to `entityType == "cs_rfis"` + `entityId == "rfi-42"`
2. `test_decode_nullEntityFieldsRemainNil` — explicit JSON `null` decodes to Swift `nil` for both fields
3. `test_decode_omittedEntityFieldsToleratedAsNil` — narrow PostgREST projection omitting the keys decodes cleanly with Optional nil (no throw)

## How the tests were built

- Vitest chain mock: nested thenable factories mirror fetchNotifications' exact default call path (`from → select → eq → order → limit → is → then`). Terminal `then` resolves with `{ data: [row, nullRow], error: null }` so `await q` in the SUT reads both test rows in one call.
- XCTest decoder factory: `private func decoder() -> JSONDecoder { keyDecodingStrategy = .convertFromSnakeCase }` — matches SupabaseService.swift:1682 contract. All three tests share the factory; test names reference the JSON keys they toggle.
- Fixture precedent mirrored from `web/src/lib/notifications/unread.test.ts` (MOCK_NOTIFICATIONS iteration) and `ready player 8Tests/NotificationsStoreTests.swift` (Swift Testing `@Test` struct pattern).

## Verification evidence

- `cd web && npx vitest run src/lib/notifications/entityPassthrough.test.ts` → **4/4 GREEN** (217ms)
- `cd web && npx vitest run src/lib/notifications` → **23/23 GREEN across 6 files** (no regression in sibling tests)
- `xcodebuild -project "ready player 8.xcodeproj" -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" build` → **\*\* BUILD SUCCEEDED \*\***
- `xcodebuild … build-for-testing` → pre-existing async/concurrency errors in `ready_player_8Tests.swift` still block, but grep confirms ZERO errors or warnings reference `SupabaseNotificationDTOTests.swift` (compile-only acceptance per Phase 22 / 29.1 precedent documented in the plan and STATE decisions)
- Acceptance grep audits:
  - `grep -c "entity_type\|entity_id"` in `entityPassthrough.test.ts` → 20 (≥8 required)
  - `grep -c "D-24"` in `entityPassthrough.test.ts` → 2 (≥1 required)
  - `grep -c "entity_id\|entity_type"` in `web/src/lib/supabase/types.ts` → 3+3 (≥1 each — type unchanged)
  - `grep -c "null$"` for `entity_type:` lines in `notifications.ts` → 0 (no MOCK fixture drift)
  - `grep -c "test_decode_*"` in `SupabaseNotificationDTOTests.swift` → 3/3 expected test names
  - `grep -c "entity_type\|entity_id\|entityType\|entityId"` → 12 (≥8 required)
  - `grep -c "convertFromSnakeCase"` → 3 (≥1 required)
- `git diff --name-only HEAD~2 HEAD | grep -v "^ready player 8Tests/\|^web/src/lib/notifications/\|^\.planning/"` → empty (zero production code modifications)

## Deviations from Plan

None — plan executed exactly as written. The audit found zero drift; no production code was touched; both commits are test-only files at the paths specified in the plan's artifact list.

## Authentication gates

None.

## Deferred issues

None.

## Known Stubs

None — this plan adds no UI, no new data paths, no placeholders. The tests reference real production code surfaces (`fetchNotifications`, `MOCK_NOTIFICATIONS`, `SupabaseNotification`) that all carry real values.

## Commits

- `55b3822` — test(30-07): lock entity_id/entity_type passthrough in web notifications fetch (D-24)
- `56b8d4b` — test(30-07): lock entity_id/entity_type JSON decode in SupabaseNotification DTO (D-24)

## Self-Check: PASSED

- `test -f web/src/lib/notifications/entityPassthrough.test.ts` → FOUND
- `test -f "ready player 8Tests/SupabaseNotificationDTOTests.swift"` → FOUND
- `git log --oneline --all | grep -q 55b3822` → FOUND
- `git log --oneline --all | grep -q 56b8d4b` → FOUND
- 4 vitest cases execute and pass in CI
- 3 XCTest cases compile clean with zero warnings in the new file
