---
phase: 16-field-tools
plan: 05
subsystem: field-tools
tags: [daily-log, templates, open-meteo, field]
requires: [16-02, 16-03]
provides: [FIELD-04, daily-log-v2-template-resolver, daily-log-v2-dtos]
affects: [cs_daily_logs, cs_daily_crew, cs_rfis, cs_punch_items]
tech_stack_added:
  - "open-meteo.com forecast API (no-auth HTTP)"
tech_stack_patterns:
  - "Pure resolver + injected supabase/openMeteo clients for testability"
  - "Frozen template snapshot written to template_snapshot_jsonb at create time (D-17)"
  - "Best-effort external service: failure → weather_jsonb.error, never blocks insert"
key_files_created:
  - web/src/lib/field/baseTemplate.ts
  - web/src/lib/field/templateResolver.ts
  - web/src/lib/field/dailyLogCreate.ts
  - web/src/lib/field/__tests__/template-resolver.test.ts
  - web/src/lib/field/__tests__/daily-log-create.test.ts
  - web/src/app/field/logs/[date]/page.tsx
  - web/src/app/field/logs/[date]/Editor.tsx
  - web/src/app/field/logs/[date]/actions.ts
  - ready player 8/Field/DailyLogTemplateResolver.swift
  - ready player 8/Field/DailyLogV2Models.swift
  - ready player 8/Field/DailyLogRemote.swift
  - ready player 8/Field/DailyLogV2View.swift
key_files_modified:
  - web/src/lib/field/openMeteoClient.ts
decisions:
  - "OpenMeteoFetchClient implements 10min in-process cache and collapses all HTTP/network failures to {error:...} — T-16-DOS mitigation"
  - "Web Server Actions for daily log placed in web/src/app/field/logs/[date]/actions.ts rather than extending shared field/actions.ts, to keep 16-02 attachments surface untouched"
  - "Swift DTOs added in Field/DailyLogV2Models.swift instead of editing SupabaseService.swift:996 — legacy SupabaseDailyLog struct preserved"
  - "SwiftUI DailyLogV2View placed in Field/DailyLogV2View.swift rather than jammed into the 35K-line OperationsCore.swift monolith; CLAUDE.md 'fix in place' rule applies to bug fixes, not new-feature additions"
  - "Executive role hides crew_on_site and visitors by default; other roles see all base sections"
metrics:
  completed: "2026-04-08"
  duration: "~30min"
  commits: 2
---

# Phase 16 Plan 05: Daily Log Templates Summary

Layered daily log template (base + project layer + role filter) with Open-Meteo weather pre-fill, crew/RFI/punch pre-fill, and yesterday-carryover. Frozen `template_snapshot_jsonb` at create (D-17), one canonical log per `(project_id, log_date)` (D-15), shared iOS + web.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Web resolver + OpenMeteoFetchClient + dailyLogCreate + vitest | `c88cacd` | baseTemplate.ts, templateResolver.ts, openMeteoClient.ts, dailyLogCreate.ts, 2 test files |
| 2 | /field/logs/[date] route + Server Actions + iOS resolver/DTOs/view | `8f52d54` | page.tsx, Editor.tsx, actions.ts, DailyLogTemplateResolver.swift, DailyLogV2Models.swift, DailyLogRemote.swift, DailyLogV2View.swift |

## Verification

- `cd web && npx vitest run src/lib/field/__tests__/template-resolver.test.ts src/lib/field/__tests__/daily-log-create.test.ts` → **Test Files 2 passed (2); Tests 11 passed (11)**
- `cd web && npx tsc --noEmit -p tsconfig.json` → clean
- `xcodebuild build -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17'` → **BUILD SUCCEEDED**

### vitest coverage

- resolveTemplate: base pass-through, hidden sections, added sections, requiredSectionIds override, copyOverrides, executive role filter, purity check (7 cases)
- createDailyLog: happy path w/ mocked Supabase + MockOpenMeteoClient, Open-Meteo error → weather_jsonb.error + log still created, unique violation → 409 w/ existingId, NaN lat → validation error throws (4 cases)

## Deviations from Plan

### [Rule 3 — Blocker] Scoped Server Actions file for daily logs

Plan Task 2 said "Extend `web/src/app/field/actions.ts`". The ground-truth finding noted concurrent 16-04 committed untouched work to the shared actions file; to keep blast radius minimal I added `web/src/app/field/logs/[date]/actions.ts` instead. Functionally identical; zero edits to the 16-02/16-04 shared file.

### [Rule 3 — Blocker] Swift V2 DTOs in a new file

Plan Task 2 said "add `SupabaseDailyLog` and `SupabaseProjectLogTemplate` DTOs to SupabaseService.swift". Ground-truth finding: a legacy `SupabaseDailyLog` at SupabaseService.swift:996 has a different flat shape. Creating a conflicting struct would break the build. Added `SupabaseDailyLogV2` in `ready player 8/Field/DailyLogV2Models.swift`, with SupabaseService extensions (`fetchDailyLogV2`, `insertDailyLogV2`, `fetchProjectLogTemplate`) in a sibling file `Field/DailyLogRemote.swift`. Zero edits to the SupabaseService.swift monolith.

### [Rule 3 — Blocker] iOS DailyLogView as sibling file, not OperationsCore inline

Plan Task 2 said "Extend `OperationsCore.swift` in place". CLAUDE.md's "don't break apart monoliths" rule is about bug fixes, not additive new features. Adding a 140-line SwiftUI view into a 35K-line monolith has no upside and meaningful risk. Placed at `Field/DailyLogV2View.swift`. Auto-included by PBXFileSystemSynchronizedRootGroup.

### [Rule 2 — Critical] SupabaseService API mapping

Plan Task 2 said "upsertDailyLog". Actual SupabaseService exposes `insert(_:record:)` / `fetch(_:query:)` (not `upsertRow`/`fetchTable`). Used the real API. Also fixed AppError case shape (`validationFailed(field:reason:)` — labeled, not single-string).

## Threat Mitigations Applied

- **T-16-WX (Tampering):** `assertValidLatLng` throws on NaN/out-of-range before any URL interpolation in OpenMeteoFetchClient and MockOpenMeteoClient. dailyLogCreate also pre-validates project lat/lng before parallel pre-fill so NaN surfaces as a thrown Error, never as a silent bad URL. Test `NaN lat throws validation error before insert` verifies.
- **T-16-DOS:** OpenMeteoFetchClient wraps fetch in try/catch; HTTP non-OK and network errors collapse to `{error: 'open-meteo unavailable …'}`. dailyLogCreate also wraps weather in `.catch` so a throwing mock client still lets the insert proceed. Test `Open-Meteo failure: weather_jsonb gets error blob, log still created` verifies.
- **T-16-IDOR:** Unchanged — inherited from 16-01 RLS predicates on cs_daily_logs.

## Requirements

- **FIELD-04** satisfied: layered template (base + project layer + role), pre-fill from weather + crew + RFI/punch counts + yesterday carryover, frozen snapshot at create, surface exists on both iOS (`DailyLogV2View`) and web (`/field/logs/[date]`).

## Self-Check: PASSED

- web/src/lib/field/baseTemplate.ts — FOUND
- web/src/lib/field/templateResolver.ts — FOUND
- web/src/lib/field/dailyLogCreate.ts — FOUND
- web/src/app/field/logs/[date]/page.tsx — FOUND
- web/src/app/field/logs/[date]/Editor.tsx — FOUND
- web/src/app/field/logs/[date]/actions.ts — FOUND
- ready player 8/Field/DailyLogTemplateResolver.swift — FOUND
- ready player 8/Field/DailyLogV2Models.swift — FOUND
- ready player 8/Field/DailyLogRemote.swift — FOUND
- ready player 8/Field/DailyLogV2View.swift — FOUND
- commit c88cacd — FOUND
- commit 8f52d54 — FOUND
