---
phase: 23-ios-nav-assignment-wiring
plan: 04
subsystem: ui
tags: [swiftui, react, dirty-tracking, error-handling, save-flow, accessibility]

requires:
  - phase: 23-01
    provides: DailyCrewView zero-arg init with AppStorage projectId, project picker

provides:
  - Dirty state tracking (isDirty) on iOS DailyCrewView and web DailyCrewSection
  - Unsaved-changes confirmation dialog on iOS project switch
  - Auto-save on date change when dirty (both platforms)
  - AppError-based error handling with retry alert on iOS
  - Error toast with retry button for 5xx on web
  - Save button spinner with double-tap prevention (both platforms)
  - Accessibility attributes (aria-busy, aria-label, aria-live) on web save button

affects: [phase-28-verification-sweep]

tech-stack:
  added: []
  patterns:
    - "isDirty computed from lastSaved snapshot vs current state"
    - "confirmationDialog for unsaved guard on navigation"
    - "AppError catch mapping with isRetryable alert"
    - "CSS @keyframes spinner for web save button"

key-files:
  created: []
  modified:
    - ready player 8/DailyCrewView.swift
    - web/src/app/projects/[id]/DailyCrewSection.tsx

key-decisions:
  - "Used inline .alert with Binding<Bool> instead of AlertState ObservableObject — simpler for single-view use case, avoids @StateObject overhead"
  - "Web uses window.confirm for date-change guard (matches plan D-05/D-06) rather than custom modal"

patterns-established:
  - "isDirty pattern: snapshot lastSaved state after load/save, compare via computed property"
  - "AppError catch mapping: catch typed AppError first, fallback maps generic Error to .network(underlying:)"

requirements-completed: [TEAM-05]

duration: 16min
completed: 2026-04-17
---

# Phase 23 Plan 04: Save-Flow Hardening Summary

**Dirty tracking, unsaved-changes guard, auto-save on date change, AppError retry alert, and save spinner on iOS DailyCrewView and web DailyCrewSection**

## What Was Built

### iOS DailyCrewView (D-05, D-06, D-16, D-17, D-18)

- **isDirty computed property**: Compares `selected` vs `lastSavedSelected` and `notes` vs `lastSavedNotes` to detect unsaved changes
- **Unsaved-changes guard (D-05)**: Project picker shows `.confirmationDialog` with Save & Switch / Discard / Cancel when dirty
- **Auto-save on date change (D-06)**: `.onChange(of: date)` calls `save()` before `loadCrew()` when dirty
- **AppError error handling (D-17)**: Save catch block maps errors to `AppError.network(underlying:)`, shows `.alert` with Retry button when `isRetryable`
- **Save spinner (D-18)**: `ProgressView` with `CircularProgressViewStyle` inside save button, button background dims to `Theme.muted` while saving

### Web DailyCrewSection (D-05, D-06, D-16, D-17, D-18)

- **isDirty tracking**: Compares `selected` Set and `notes` against `lastSaved` snapshot
- **Date-change guard (D-05/D-06)**: `window.confirm` dialog on date input change when dirty, saves if confirmed
- **Error with retry (D-17)**: Separate `error` state with `{ message, retryable }`, shows Retry button for HTTP 5xx
- **Save spinner (D-18)**: CSS `@keyframes spin` animation on inline span, `aria-busy` and `aria-label` for accessibility

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | iOS save-flow hardening | f243531 | ready player 8/DailyCrewView.swift |
| 2 | Web save-flow hardening | b9f8322 | web/src/app/projects/[id]/DailyCrewSection.tsx |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] AppError constructor mismatch**
- **Found during:** Task 1
- **Issue:** Plan used `AppError.network(error.localizedDescription)` but actual AppError.swift defines `.network(underlying: Error)` with an Error parameter, not String
- **Fix:** Used `AppError.network(underlying: error)` to match actual enum case signature
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** f243531

**2. [Rule 3 - Blocking] ErrorAlertModifier API mismatch**
- **Found during:** Task 1
- **Issue:** Plan referenced `.errorAlert(error: $appError)` but this modifier does not exist. The actual `ErrorAlertModifier` requires an `AlertState` ObservableObject
- **Fix:** Used inline `.alert` with `Binding<Bool>` computed from `appError != nil`, which is simpler and avoids needing a `@StateObject`
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** f243531

**3. [Rule 3 - Blocking] iOS Simulator destination name**
- **Found during:** Task 1 verification
- **Issue:** Plan used `iPhone 16` but available simulators are iPhone 17 Pro Max and iPhone Air (Xcode 16.2 / iOS 26.3.1)
- **Fix:** Used `iPhone 17 Pro Max` for xcodebuild destination
- **Commit:** n/a (verification only)

## Verification

- iOS: `xcodebuild build` exits with BUILD SUCCEEDED
- Web: `npx tsc --noEmit` exits 0 (clean)
- isDirty grep count: iOS 3, Web 2
- lastSaved grep count: iOS 4, Web 4
- AppError grep count: iOS 3
- ProgressView grep count: iOS 2
- retryable/Retry grep count: Web 5
- aria grep count: Web 3

## Self-Check: PASSED
