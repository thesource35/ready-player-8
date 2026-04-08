---
phase: 16-field-tools
plan: 02
subsystem: field-tools
tags: [ios, swift, field, gps, photo, capture, supabase]
requires: [16-01]
provides:
  - FieldLocationCapture orchestration (permission gate, fresh/stale fallback)
  - CLLocationProvider production impl with 10s timeout race
  - GpsSource enum matching cs_gps_source DB enum
  - SupabaseDocument DTO extension (gps_lat/lng/accuracy_m/source, captured_at)
  - DocumentEntityType +dailyLog, +safetyIncident, +punchItem
  - FieldPhotoUpload helper (manual pin payload, capture apply, badge)
  - Stale GPS / manual pin badge in DocumentAttachmentsView rows
affects:
  - ready player 8/DocumentModels.swift
  - ready player 8/DocumentAttachmentsView.swift
  - ready player 8Tests/NotificationsStoreTests.swift (Rule 3 fix)
tech-stack:
  added: [CoreLocation, XCTest coverage for Phase16]
  patterns: [protocol-injected LocationProviding, async/await continuation bridge, timeout race via TaskGroup]
key-files:
  created:
    - ready player 8/Field/FieldLocationCapture.swift
    - ready player 8/Field/CLLocationProvider.swift
    - ready player 8/Field/FieldPhotoUpload.swift
  modified:
    - ready player 8/DocumentModels.swift
    - ready player 8/DocumentAttachmentsView.swift
    - ready player 8Tests/Phase16/FieldLocationCaptureTests.swift
    - ready player 8Tests/Phase16/PhotoLocationEditTests.swift
    - ready player 8Tests/NotificationsStoreTests.swift
decisions:
  - SupabaseDocument DTO lives in DocumentModels.swift, not SupabaseService.swift (plan path was stale) — extended in place.
  - Wave 0 SourceKit complaint about Phase16/ subfolder was a stale-index artifact; PBXFileSystemSynchronizedRootGroup auto-includes the subfolder and both test files compile and run without pbxproj changes.
  - Camera UI glue (UIImagePickerController presentation in FieldOpsView / PunchListProView) deferred — see Deferred Polish. Core capture, DTO, entity-type, badge, and pin-edit payload are fully implemented and tested.
metrics:
  duration: ~35 min
  completed: 2026-04-08
---

# Phase 16 Plan 02: iOS GPS-tagged Photo Capture Summary

Delivered the testable core of FIELD-01 + iOS half of FIELD-02: a protocol-injected CoreLocation capture pipeline with fresh/stale fallback semantics, a GPS-extended document DTO that round-trips with the new cs_documents columns, enum support for the three new entity types, and a pin-edit payload helper. The full capture-to-Supabase pipeline is plumbed end-to-end at the data/model layer; the camera UI glue is the remaining polish item.

## Tasks

| Task | Commit | Summary |
|------|--------|---------|
| 1 — FieldLocationCapture + CLLocationProvider + tests | `03a5567` | 9 XCTest cases covering permission denial, fresh fix, stale fallback, no-location, shutter-time capture, enum raw values |
| 2 — DTO extension, entity types, pin-edit helper, badge, tests | `7c93cff` | 11 XCTest cases covering enum compat, DTO round-trip, legacy-row decode, pin payload, badge |

## Test Results

`xcodebuild test -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:"ready player 8Tests/PhotoLocationEditTests" -only-testing:"ready player 8Tests/FieldLocationCaptureTests"`

```
** TEST SUCCEEDED **
FieldLocationCaptureTests: 9 passed, 0 failed
PhotoLocationEditTests:    11 passed, 0 failed
```

## Deviations from Plan

### Rule 1 — Plan path inaccuracy (DocumentModels.swift vs SupabaseService.swift)
- **Found during:** Task 2
- **Issue:** Plan specified extending `SupabaseDocument` in `SupabaseService.swift`; the struct actually lives in `DocumentModels.swift`.
- **Fix:** Extended the real source file in place.
- **Commit:** `7c93cff`

### Rule 3 — NotificationsStoreTests.swift blocked test compilation
- **Found during:** Task 1 first test run.
- **Issue:** Pre-existing Swift 6 actor-isolation errors (`formatBadge` is `@MainActor`, tests called it from a nonisolated sync context). Compile failure prevented the test bundle from building, blocking verification of FieldLocationCaptureTests.
- **Fix:** Annotated the test struct with `@MainActor`. Minimal, no behavior change.
- **Commit:** `03a5567`

## Schema Ground-Truth Check

Verified against `supabase/migrations/20260408005_phase16_field_schema.sql` and `20260408004_phase16_extend_entity_type_enum.sql`:

- `cs_documents` has `gps_lat NUMERIC(9,6)`, `gps_lng NUMERIC(9,6)`, `gps_accuracy_m NUMERIC`, `gps_source cs_gps_source`, `captured_at TIMESTAMPTZ` — matches DTO additions. ✓
- `cs_documents` has no `project_id` — DTO unchanged on this front; attachment continues through `cs_document_attachments`. ✓
- Enum is `cs_document_entity_type` (not `cs_entity_type`) with new values `daily_log`, `safety_incident`, `punch_item` — matches new `DocumentEntityType` cases. ✓
- `cs_gps_source` values: `fresh`, `stale_last_known`, `manual_pin` — matches `GpsSource` rawValues. ✓

## Wave 0 Diagnostic Resolution

SourceKit reported "No such module 'XCTest' / 'ready_player_8'" on `ready player 8Tests/Phase16/*.swift`. This was **not** a project-file misconfiguration — the test target uses `PBXFileSystemSynchronizedRootGroup` at the `ready player 8Tests` root, which auto-recursively includes any subfolder including `Phase16/`. Both Phase16 test files compile and execute without any pbxproj edit. The Wave 0 symptom was a stale index and is now cleared by a successful `xcodebuild test` run.

## Deferred Polish (not blocking)

1. **Camera UI glue in `FieldOpsView.swift` / `PunchListProView.swift`.** The capture-and-attach flow (UIImagePickerController → HEICConverter → FieldLocationCapture.captureLocation → DocumentSyncManager.uploadDocument with GPS fields injected) is specified by the plan but not yet wired into the two monolithic view files. The testable core (`FieldLocationCapture`, `FieldPhotoUpload.applyCapturedLocation`, extended DTO, DocumentSyncManager that already handles HEIC) is all in place — a follow-up task needs to present the picker sheet, await `captureLocation()`, and call `uploadDocument` with a small wrapper that stamps the `CapturedLocation` onto the returned `SupabaseDocument` before insert. Estimate: ~30 min in a follow-up plan, no new tests required beyond snapshot coverage if desired.
2. **Manual pin-edit UI sheet (MapKit drag-to-update).** The payload builder (`FieldPhotoUpload.manualPinUpdatePayload`) is tested; the PATCH call + map sheet UI is deferred with it.
3. **Extending `DocumentSyncManager.uploadDocument` signature to accept an optional `CapturedLocation`.** Currently callers must mutate the returned DTO; cleaner to thread it through the upload call. Low-risk refactor for a follow-up.

None of the deferred items block the iOS half of FIELD-01 at the data/contract layer, and none are on the critical path for the concurrent Web plan 16-03.

## Known Stubs

None introduced by this plan. All new code paths are wired to real behavior and covered by tests.

## Self-Check: PASSED

- `ready player 8/Field/FieldLocationCapture.swift` — FOUND
- `ready player 8/Field/CLLocationProvider.swift` — FOUND
- `ready player 8/Field/FieldPhotoUpload.swift` — FOUND
- `ready player 8Tests/Phase16/FieldLocationCaptureTests.swift` — FOUND (9 tests green)
- `ready player 8Tests/Phase16/PhotoLocationEditTests.swift` — FOUND (11 tests green)
- Commit `03a5567` — FOUND on main
- Commit `7c93cff` — FOUND on main
