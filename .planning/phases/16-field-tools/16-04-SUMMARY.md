---
phase: 16-field-tools
plan: 04
subsystem: field-tools
tags: [annotations, pencilkit, svg, supabase]
requires: [16-01, 16-02, 16-03]
provides: [FIELD-03, photo-annotation-v1-schema]
affects: [cs_photo_annotations, cs_documents]
tech_added: []
patterns: [shared-json-schema, deterministic-svg-render, non-destructive-annotation]
key_files_created:
  - web/src/lib/field/annotations/schema.ts
  - web/src/lib/field/annotations/render.ts
  - web/src/app/field/photos/[id]/annotate/page.tsx
  - web/src/app/field/photos/[id]/annotate/Editor.tsx
  - web/src/app/field/photos/[id]/annotate/actions.ts
  - ready player 8/Field/AnnotationSchema.swift
  - ready player 8/Field/PencilKitJSONConverter.swift
  - ready player 8/Field/PhotoAnnotateView.swift
  - ready player 8/Field/AnnotationRemote.swift
key_files_modified:
  - ready player 8/SupabaseService.swift
  - ready player 8Tests/Phase16/PencilKitJSONConverterTests.swift
  - web/src/lib/field/__tests__/annotation-render.test.ts
  - tests/fixtures/annotations/v1-sample.json
decisions:
  - "Renamed Swift enum Shape → AnnotationShape to avoid SwiftUI.Shape protocol collision"
  - "Isolated annotation Server Actions into app/field/photos/[id]/annotate/actions.ts to avoid conflict with concurrent 16-05"
  - "Added SupabasePhotoAnnotation DTO and upsertPhotoAnnotation in new AnnotationRemote.swift (extension) rather than inline in SupabaseService.swift for same reason"
  - "Rewrote tests/fixtures/annotations/v1-sample.json to match plan <interfaces> schema (old file was stale Wave 0 placeholder with different shape names)"
  - "Hand-rolled schema validation in TS (zod is not a web dependency per ground-truth note)"
metrics:
  duration: "~25m"
  completed_date: "2026-04-08"
---

# Phase 16 Plan 04: Photo Annotation (FIELD-03) Summary

Shared v1 JSON schema + iOS PencilKit editor + web SVG editor + cs_photo_annotations CRUD on both platforms. Non-destructive: originals are never modified (D-09). Export-on-demand flattening deferred per D-12.

## What shipped

**Web**
- `schema.ts` — hand-rolled `LayerJsonV1` validator with forward-compat drop of unknown shape `type` entries
- `render.ts` — deterministic SVG renderer; escapes text (T-16-XSS mitigation)
- `annotate/page.tsx` (Server Component) + `Editor.tsx` (Client Component) — stroke/arrow/rect/ellipse/text tools with undo/save
- `annotate/actions.ts` — `saveAnnotation` Server Action upserting on `document_id` with RLS→403 mapping

**iOS**
- `AnnotationSchema.swift` — Codable mirror; `AnnotationShape` enum with associated values; decoder silently drops unknown discriminants
- `PencilKitJSONConverter.swift` — `pkDrawingToStrokes` / `strokesToPKDrawing` / `composeLayer`; coordinates normalized 0..1
- `PhotoAnnotateView.swift` — SwiftUI PKCanvasView wrapper + save flow
- `AnnotationRemote.swift` — `SupabasePhotoAnnotation` DTO and `upsertPhotoAnnotation` extension on SupabaseService; maps HTTP 401/403 → `AppError.permissionDenied`
- `SupabaseService.swift` — single-line addition of `cs_photo_annotations` to `allowedTables`

## Test results

| Suite | Pass | Fail |
|-------|------|------|
| `web/src/lib/field/__tests__/annotation-render.test.ts` (vitest) | 7 | 0 |
| `ready player 8Tests/Phase16/PencilKitJSONConverterTests` (xcodebuild, iPhone 17 sim) | 6 | 0 |

Covered behaviours:
- v1 fixture round-trip
- Forward-compat: unknown shape types silently dropped (both platforms)
- Malformed known shapes rejected (web)
- Normalized coordinates ∈ [0, 1] asserted
- PKDrawing round-trip within ε=0.01
- `composeLayer` merges strokes + overlay shapes
- SVG text content XSS escaping (T-16-XSS)
- Deterministic SVG output

## Commits

| SHA | Scope |
|-----|-------|
| `fc21813` | web annotation v1 schema, SVG renderer, and editor |
| `8c59f08` | iOS PencilKit ↔ LayerJSON converter, PhotoAnnotateView, upsert helper |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Fixture schema mismatch**
- **Found during:** Task 1, writing the renderer test.
- **Issue:** `tests/fixtures/annotations/v1-sample.json` was a stale Wave 0 placeholder using `variants.portrait.strokes` with type names `freehand`/`rectangle`, incompatible with the v1 schema defined in the plan's `<interfaces>` block (`shapes` array with `stroke`/`rect`/`ellipse`).
- **Fix:** Rewrote fixture to match the v1 schema exactly. All five shape types represented.
- **Files modified:** `tests/fixtures/annotations/v1-sample.json`
- **Commit:** `fc21813`

**2. [Rule 3 - Blocker] Swift `Shape` name collision**
- **Found during:** Task 2, first xcodebuild run.
- **Issue:** Top-level `enum Shape` collided with SwiftUI's `Shape` protocol (`Inheritance from non-protocol type 'Shape'`).
- **Fix:** Renamed enum to `AnnotationShape` across schema, converter, view, and tests.
- **Commit:** `8c59f08`

### Conflict-avoidance choices (concurrent 16-05 executor)

- **Web:** All new annotation Server Actions live in `web/src/app/field/photos/[id]/annotate/actions.ts` rather than shared `web/src/app/field/actions.ts`. Shared `actions.ts` was NOT touched. `git diff HEAD` on it before each commit was clean.
- **iOS:** `SupabasePhotoAnnotation` DTO and `upsertPhotoAnnotation` helper were placed in a new `ready player 8/Field/AnnotationRemote.swift` file (extension on `SupabaseService`) rather than inline in `SupabaseService.swift`. The only change to `SupabaseService.swift` is a two-line addition to the `allowedTables` set.
- **Result:** No conflicts encountered with 16-05 during execution.

## Deferred (out of scope per D-12)

- Export-on-demand flattening of annotations into a new JPEG/PNG variant of the photo. Plan notes this is deferred; the source photo remains untouched.

## Threat Model coverage

| Threat ID | Mitigation landed |
|-----------|-------------------|
| T-16-RLS | `saveAnnotation` maps Postgrest `42501` → 403; iOS `upsertPhotoAnnotation` maps HTTP 401/403 → `AppError.permissionDenied` |
| T-16-XSS | `render.ts` escapes text via XML-entity replacement; test asserts `<script>` is encoded |
| T-16-FWDCOMPAT | `parseLayerJson` (TS) and `LayerJSON.init(from:)` (Swift) both silently drop unknown shape types; explicit tests on both sides |

## Self-Check: PASSED

- `web/src/lib/field/annotations/schema.ts` — FOUND
- `web/src/lib/field/annotations/render.ts` — FOUND
- `web/src/app/field/photos/[id]/annotate/page.tsx` — FOUND
- `web/src/app/field/photos/[id]/annotate/Editor.tsx` — FOUND
- `web/src/app/field/photos/[id]/annotate/actions.ts` — FOUND
- `ready player 8/Field/AnnotationSchema.swift` — FOUND
- `ready player 8/Field/PencilKitJSONConverter.swift` — FOUND
- `ready player 8/Field/PhotoAnnotateView.swift` — FOUND
- `ready player 8/Field/AnnotationRemote.swift` — FOUND
- Commit `fc21813` — FOUND
- Commit `8c59f08` — FOUND
