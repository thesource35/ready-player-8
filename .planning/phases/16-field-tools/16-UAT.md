---
status: complete
phase: 16-field-tools
source: [16-00-SUMMARY.md, 16-01-SUMMARY.md, 16-02-SUMMARY.md, 16-03-SUMMARY.md, 16-04-SUMMARY.md, 16-05-SUMMARY.md]
started: 2026-04-08T00:00:00Z
updated: 2026-04-08T18:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Fresh start of web dev server and iOS app — both boot without errors, home screen loads.
result: pass

### 2. iOS GPS Photo Capture
expected: Take a photo in the field tool. A fresh GPS fix (<60s old) attaches lat/lng/accuracy to the photo. If location is stale or denied, photo still saves with a visible "stale GPS" or "no GPS" indicator — never silently drops.
result: issue
reported: "no — camera UI glue was deferred in 16-02; retry pending after commit a4397f9 wired FieldPhotoCaptureView"
severity: major

### 3. Web Photo Browser (/field/photos)
expected: Navigate to /field/photos with a project selected. Grid of project photos loads with thumbnails, captured_at, stale-GPS badge. Empty state or error banner if no photos.
result: issue
reported: "no i dont see it — route works but cs_documents has no image rows because capture pipeline had no entry point; unblocked by a4397f9, retry pending"
severity: major

### 4. Attach / Detach Photo to Entity
expected: From the photo browser, attach a photo to a daily log / punch item / safety incident. Attachment persists; detach removes it. Duplicate attach shows a clear error (409), not a silent success.
result: pass

### 5. iOS Photo Annotation (PencilKit)
expected: Open a photo in the annotate view. Draw strokes, save. Reopen — strokes reappear. Original photo unchanged.
result: pass

### 6. Web Photo Annotation (/field/photos/[id]/annotate)
expected: Open annotator on web. Add stroke, arrow, rect, text; save. Reload — annotations render deterministically. Text escaped (no XSS).
result: pass

### 7. Daily Log Create with Weather Pre-fill (/field/logs/[date])
expected: Open /field/logs/2026-04-08 for a project. Weather pre-fills from Open-Meteo. Crew, RFIs, punch items pre-fill. Second save same day shows 409.
result: pass

### 8. iOS Daily Log V2 View
expected: Open iOS daily log for a project. Template resolves with role filter. Executive hides crew_on_site/visitors; superintendent sees all. Save round-trips.
result: issue
reported: "screen not showing up"
severity: major

## Summary

total: 8
passed: 5
issues: 3
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Photo capture → upload → /field/photos browser pipeline has a usable entry point in the iOS app"
  status: fixed_pending_retest
  reason: "Camera UI glue deferred in 16-02 (Deferred Polish). Browser shipped in 16-03 but cs_documents was empty. Root cause: missing UI glue between FieldLocationCapture and DocumentSyncManager.uploadDocument."
  severity: major
  test: 2, 3
  root_cause: "iOS lacked any UI that called uploadDocument, so no photos ever reached cs_documents; web browser therefore always showed empty state"
  artifacts:
    - path: "ready player 8/Field/FieldPhotoCaptureView.swift"
      issue: "new file — PhotosPicker sheet wired end-to-end"
    - path: "ready player 8/FieldOpsView.swift"
      issue: "CAPTURE button added to header, presents FieldPhotoCaptureView sheet"
  missing: []
  fix_commit: "a4397f9"
  retest: "Run Field → CAPTURE in simulator; upload photo; refresh /field/photos on web"

- truth: "iOS Daily Log V2 view is reachable from the app"
  status: failed
  reason: "User reported: screen not showing up"
  severity: major
  test: 8
  root_cause: "DailyLogV2View is defined in ready player 8/Field/DailyLogV2View.swift but has zero references elsewhere — no NavigationLink, sheet presentation, or tab entry. Same Deferred Polish pattern as tests 2/3: backend/model logic shipped in 16-05 without a UI entry point."
  artifacts:
    - path: "ready player 8/Field/DailyLogV2View.swift"
      issue: "orphaned — only self-reference; never presented"
  missing:
    - "Add entry point: either a CAPTURE-style button in FieldOpsView that presents DailyLogV2View(projectId:role:) as a sheet, or a NavigationLink from the project row, with role resolved from current OpsRolePreset"
  debug_session: ""
