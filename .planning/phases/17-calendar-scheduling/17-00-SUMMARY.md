---
phase: 17
plan: 00
subsystem: calendar-scheduling
tags: [test-scaffolding, nyquist, wave-0, red-stubs]
requires: []
provides:
  - "Failing test stubs for Phase 17 critical paths"
  - "org_id scoping test (Threat T-17-01-pre)"
affects:
  - "web/src/lib/calendar/__tests__/"
  - "web/src/app/api/calendar/__tests__/"
  - "web/src/app/schedule/__tests__/"
  - "web/src/lib/supabase/__tests__/"
  - "ready player 8Tests/"
tech-stack:
  added: []
  patterns: ["vitest RED stubs", "XCTest RED stubs"]
key-files:
  created:
    - web/src/lib/calendar/__tests__/derive-milestones.test.ts
    - web/src/app/api/calendar/__tests__/tasks.test.ts
    - web/src/app/api/calendar/__tests__/dependencies.test.ts
    - web/src/app/schedule/__tests__/gantt.test.tsx
    - web/src/lib/supabase/__tests__/updateOwnedRow.test.ts
    - ready player 8Tests/CalendarAgendaTests.swift
    - ready player 8Tests/CalendarRescheduleTests.swift
  modified: []
decisions:
  - "Gantt stub uses `// @vitest-environment node` directive until Plan 17-03 installs jsdom"
  - "Confirmed open question: current `updateOwnedRow` scopes by `user_id`, NOT `org_id`. Plan 17-02 must fix this before layering PATCH on top."
metrics:
  duration: "~15 min"
  completed: 2026-04-09
---

# Phase 17 Plan 00: Wave 0 Test Scaffolding Summary

Seven RED test files landed so every downstream Phase 17 task has a real test file to point its `<automated>` verify at — Nyquist compliance unlocked.

## What Shipped

- **5 vitest RED stubs** (11 failing tests) covering:
  - `deriveMilestones` pure fn (CAL-02)
  - `/api/calendar/tasks` GET/POST/PATCH + TZ validation (CAL-01/02)
  - `/api/calendar/dependencies` cycle detection (CAL-03)
  - Gantt render + pointer drag + DST preservation (CAL-04)
  - `updateOwnedRow` org_id scoping (Threat T-17-01-pre)
- **2 XCTest RED stubs**:
  - `CalendarAgendaTests.test_agendaGroupsItemsByDay` (Plan 17-04)
  - `CalendarRescheduleTests.test_tapToRescheduleSendsPatch` (Plan 17-04)

Each failing test carries an explicit `RED — implement in Plan 17-XX` message and, where applicable, lists the exact symbols the downstream plan must create.

## Verification Evidence

```
$ cd web && npx vitest run src/lib/calendar src/app/api/calendar \
    src/app/schedule/__tests__ src/lib/supabase/__tests__/updateOwnedRow.test.ts
 Test Files  5 failed (5)
      Tests  11 failed (11)
```

All 11 tests fail with "RED — not yet implemented" messages (no vacuous passes).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Gantt test file environment override**
- **Found during:** Task 1 verification
- **Issue:** Vitest 3.x auto-selects jsdom environment for `.tsx` files; jsdom is not installed in `web/`.
- **Fix:** Added `// @vitest-environment node` directive to `gantt.test.tsx`. RED stubs don't touch the DOM, so node env is safe. Plan 17-03 will swap this to `jsdom` and install the dep.
- **Files modified:** `web/src/app/schedule/__tests__/gantt.test.tsx`
- **Commit:** 262e4f1

## Open Question Resolved

**Q:** Does `updateOwnedRow` scope by `org_id`?
**A:** **No.** Current implementation at `web/src/lib/supabase/fetch.ts:139` scopes by `.eq("id", id).eq("user_id", userId)`. There is no `org_id` filter. The RED test in `updateOwnedRow.test.ts` asserts that an `org_id` eq-filter is present in the query chain — this failing test is now the blocker that forces Plan 17-02 to thread `org_id` through the helper before shipping the new PATCH route on top of an unscoped surface. (Threat T-17-01-pre mitigated-by-failing-test.)

## Commits

- `262e4f1` test(17-00): add RED vitest stubs for calendar API, Gantt, and org_id scoping
- `37c2402` test(17-00): add RED XCTest stubs for iOS agenda + reschedule

## Self-Check: PASSED

- Files: all 7 present on disk (5 vitest + 2 XCTest)
- Commits: 262e4f1, 37c2402 present in `git log`
- Vitest run confirms 11 RED failures across 5 files
