---
phase: 21-live-satellite-traffic-maps
plan: 09
subsystem: ios
tags: [ios, swiftui, supabase-allowlist, mock-relocate, error-surfacing, empty-state, app-error]

# Dependency graph
requires:
  - phase: 21-live-satellite-traffic-maps
    provides: Plan 21-07 clean iOS rebuild foundation + Plan 21-08 web equipment seed so iOS UAT has a cross-platform observable control
  - phase: 21-live-satellite-traffic-maps
    provides: shipped SupabaseEquipmentLatestPosition DTO, EquipmentCheckInView, MapsView skeleton
provides:
  - SupabaseService.allowedTables extended with cs_equipment, cs_equipment_locations, cs_equipment_latest_positions (iOS check-in pipeline unblocked)
  - mockEquipmentPositions relocated from Atlanta (33.749, -84.388) to NYC-Midtown cluster within ±0.005 deg of MapSite.mapCenter (40.7580, -73.9855)
  - MapsView.loadMapData() equipment branch — empty-successful response triggers mock fallback when Supabase is unconfigured; configured-empty stays empty (no UI lies)
  - mockPhotoAnnotations file-scope constant (3 entries near NYC-Midtown) — symmetric with mockEquipmentPositions
  - MapsView.loadMapData() photo branch — mirrors equipment branching (empty-success+unconfigured -> mocks, throw -> mocks + loadError)
  - "0 PHOTOS WITH GPS" empty-state chip when photosOverlay on AND photoAnnotations empty AND not loading
  - @State loadError: AppError? on MapsView + .alert modifier with Dismiss/Retry — "Map data load failed" surfacing
  - EquipmentCheckInView.submitCheckIn() catches AppError specifically + wraps raw errors into AppError.unknown for user-facing submitError section copy
affects: [21-10, 21-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "AppError wrap at catch boundary: `let wrapped = (error as? AppError) ?? AppError.unknown(error.localizedDescription)` — surfaces project-convention messages instead of raw SDK strings"
    - "Conditional error surfacing: `if SupabaseService.shared.isConfigured { loadError = wrapped }` — unconfigured demo paths stay silent (mock fallback is expected), configured paths always signal failure"
    - "Empty-success fallback gate: `if fetched.isEmpty && !SupabaseService.shared.isConfigured` — a configured-and-empty response is a legitimate empty state, not a reason to inject mocks"
    - "Data fallback symmetry: photos mirror equipment (file-scope mock array + empty-success fallback + empty-state chip) to prevent inconsistent UX across overlay types"

key-files:
  created: []
  modified:
    - "ready player 8/SupabaseService.swift"
    - "ready player 8/EquipmentCheckInView.swift"
    - "ready player 8/EquipmentModels.swift"
    - "ready player 8/MapsView.swift"

key-decisions:
  - "Wrap raw errors with AppError.unknown(error.localizedDescription) at the catch boundary instead of forcing every call site to emit AppError — preserves backward compatibility with callers that still throw generic Error types; the wrap happens once at the UI boundary"
  - "Surface errors to UI ONLY when Supabase is configured — the unconfigured demo path is the intended dev/showcase flow, and mocks are the expected result. Surfacing an 'error' there would train users to ignore the alert"
  - "Keep CrashReporter.reportError() calls alongside new UI surfacing — they feed analytics; only add, never remove"
  - "Empty-state chip gates on pre-filter `photoAnnotations` array (not a post-filter derived value) — the chip's point is 'Phase 16 has not captured any GPS photos yet', not 'current filter matches nothing'"
  - "Photos fall back to mockPhotoAnnotations on throw even when Supabase IS configured — matches existing equipment behavior at load time; loadError surfaces the fact that it's offline data via the alert"
  - "Empty-state chip positioned above the map (in the VStack with the metric cards), not inside the annotation layer — an in-map chip would fight with marker rendering"

patterns-established:
  - "Conditional error surfacing by isConfigured: configured paths alert; unconfigured paths fall back silently"
  - "Mock-array file-scope constants named `mock{Feature}` — consistent with mockEquipmentPositions, mockEquipment, mockProjects, mockContracts"
  - "AppError wrap at catch boundary pattern (error as? AppError) ?? AppError.unknown(error.localizedDescription) for any catch that needs to set a UI-visible error string"

requirements-completed: [MAP-03, MAP-04]

# Metrics
duration: ~20 min
completed: 2026-04-22
---

# Phase 21 Plan 09: iOS Gap Closure — Allowlist + Mock Relocation + Empty-Success Fallback + Photo Symmetry + Visible Errors Summary

**SupabaseService allowlist extended with 3 Phase-21 equipment tables, mock equipment relocated from Atlanta to NYC-Midtown, empty-successful fetches trigger mock fallback when Supabase is unconfigured, photo branch now mirrors equipment (mock fallback + empty-state chip + visible errors), and both MapsView load errors and EquipmentCheckInView submit errors now surface to the UI via AppError-shaped messages instead of silent CrashReporter swallow — closes UAT Tests 8, 9, 11 in three atomic commits.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-04-22T05:06:52Z
- **Completed:** 2026-04-22T05:27:00Z (approximate)
- **Tasks:** 3/3 (all auto)
- **Files modified:** 4 (SupabaseService.swift, EquipmentCheckInView.swift, EquipmentModels.swift, MapsView.swift)

## Accomplishments

- **UAT Test 11 root cause closed** — `SupabaseService.allowedTables` now permits `cs_equipment`, `cs_equipment_locations`, `cs_equipment_latest_positions`. Before this change `validateTable()` threw "Invalid table name" before any HTTP request was issued, breaking the entire iOS check-in flow even against a correctly configured Supabase. Three single-line additions next to existing Phase-21-adjacent groups.
- **UAT Test 8 defect 1 closed** — `mockEquipmentPositions` moved from Atlanta coords (33.749, -84.388) to NYC-Midtown cluster (40.7558 to 40.7598 lat, -73.9880 to -73.9835 lng). All four entries are now within ±0.005 deg of `MapSite.mapCenter = (40.7580, -73.9855)` so mock pins are visible in the default iOS viewport when Supabase is unconfigured.
- **UAT Test 8 defect 2 closed** — `MapsView.loadMapData()` equipment branch now checks `fetched.isEmpty && !SupabaseService.shared.isConfigured` before assigning `mockEquipmentPositions`. The `cs_equipment_latest_positions` view uses INNER JOIN on `cs_equipment_locations` and returns empty-success on fresh installs; the old code only fell back on `catch`, so empty-success silently rendered no pins.
- **UAT Test 9 data gap closed** — `mockPhotoAnnotations` added as a file-scope `let` in `MapsView.swift` (3 entries clustered near NYC-Midtown with realistic filenames). Photo fetch branch now mirrors equipment: empty-success + unconfigured → mocks; throw → mocks + loadError (if configured).
- **UAT Test 9 empty-state affordance closed** — "0 PHOTOS WITH GPS" chip renders when `photosOverlay && photoAnnotations.isEmpty && !isLoadingData`. Chip uses Theme.muted tone, 9pt black font with 1pt tracking (matches codebase sidebar header style), positioned above the map in the main VStack (not inside the annotation layer).
- **Project core-value regression closed (Test 11 silent swallow)** — `loadError: AppError?` state + `.alert("Map data load failed", ...)` modifier with Dismiss/Retry buttons on MapsView; `EquipmentCheckInView.submitCheckIn()` catches `AppError` specifically and wraps raw errors into `AppError.unknown` so the existing `submitError` section shows a project-convention message instead of raw SDK output. CrashReporter calls preserved for analytics.

## Task Commits

Each task was committed atomically on `main`:

1. **Task 1: Add cs_equipment* to allowedTables + surface check-in errors via AppError** — `63b261c` (fix)
2. **Task 2: Relocate mockEquipmentPositions to NYC-Midtown cluster** — `8aa93e7` (fix)
3. **Task 3 (and MapsView.swift slice of Task 1 + Task 2): mock-photo fallback + empty-state chip + visible load errors** — `64f8991` (fix)

**Plan metadata closeout:** (this commit — `docs(21-09): summary + state/roadmap update`)

## Files Created/Modified

### Modified
- `ready player 8/SupabaseService.swift` — 3 new entries in the `allowedTables` Set under a new `// Phase 21: Equipment tracking (tables + latest-position view)` comment, mirroring the existing `// Phase N:` group-comment convention. `validateTable()` function body unchanged — it simply now allows these three identifiers through.
- `ready player 8/EquipmentCheckInView.swift` — `submitCheckIn()` catch replaced with a `catch let appError as AppError` / `catch` pattern. AppError path uses `errorDescription`; generic path wraps into `AppError.unknown(error.localizedDescription)` and reads the same `errorDescription`. The existing `submitError` Section at lines 118-124 already renders this string — no additional UI wiring needed. CrashReporter calls preserved.
- `ready player 8/EquipmentModels.swift` — 4 entries of `mockEquipmentPositions` relocated; `latestLat`/`latestLng` pairs changed from Atlanta to NYC-Midtown cluster. IDs, names, types, subtypes, statuses, timestamps, accuracies preserved byte-identically. Added a comment explaining the relocation rationale.
- `ready player 8/MapsView.swift` — 5 surgical changes:
  1. File-scope `mockPhotoAnnotations: [MapPhotoAnnotation]` added below the `MapPhotoAnnotation` struct.
  2. `@State private var loadError: AppError?` added near the other state declarations.
  3. `loadMapData()` equipment branch rewritten: let-binding `fetched` + empty-success-unconfigured gate + AppError-wrap + `if isConfigured { loadError = wrapped }` in catch.
  4. `loadMapData()` photo branch rewritten: same pattern as equipment — empty-success-unconfigured fallback to `mockPhotoAnnotations`; catch block wraps to AppError + surfaces + falls back to mocks.
  5. `.alert("Map data load failed", ...)` modifier added below the existing `.sheet` modifier on the root `ScrollView`.
  6. "0 PHOTOS WITH GPS" chip JSX added in the main VStack just below the metric-cards row, gated on `photosOverlay && photoAnnotations.isEmpty && !isLoadingData`.

## Decisions Made

- **AppError wrap at catch boundary (not at every throw site).** The codebase uses `AppError` as a rich LocalizedError enum but many SupabaseService methods still throw `SupabaseError.httpError` / URLSession errors directly. Rather than changing every throw site, the fix wraps at the UI boundary where we need a user-facing string. One line: `let wrapped = (error as? AppError) ?? AppError.unknown(error.localizedDescription)`. Future work can migrate throws to AppError natively.
- **Error surface gate on isConfigured.** When Supabase is unconfigured, the mock fallback IS the expected UX — the demo/preview/dev flow. Surfacing an error alert there would train users to ignore the alert. So loadError is only set when Supabase IS configured AND the fetch threw or returned empty. Unconfigured empty-success silently falls back to mocks.
- **Photo mock fallback on throw is unconditional.** Equipment does this already (fallback to mocks in catch regardless of isConfigured); photos now match so the UX is symmetric. The loadError alert communicates the failure; the mock data keeps the map functional.
- **Empty-state chip goes above the map, not inside the annotation layer.** The plan suggested this explicitly — an in-map overlay would fight with MapKit's marker rendering. The chip sits in the main VStack with the metric cards, which is where status affordances already live.
- **Kept CrashReporter calls.** UI surfacing is additive, not a replacement. CrashReporter feeds analytics; losing that telemetry would make future regressions harder to diagnose.
- **Added a comment block on the relocated mockEquipmentPositions.** Future maintainers need to know these coords aren't Atlanta by accident — the comment cites the default viewport center so the rationale is load-bearing code, not tribal knowledge.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] AppError API mismatch with plan sample code**
- **Found during:** Task 1 (EquipmentCheckInView.swift edit)
- **Issue:** Plan showed `AppError.unknown(message: ...)` but the actual enum declares `case unknown(String)` — positional, not labeled. Same for `AppError.network(reason:)` (actual: `.network(underlying:)`) and `.supabaseHTTP(status:message:)` (actual: `.supabaseHTTP(statusCode:body:)`). Using the plan's labels would have produced a compile error.
- **Fix:** Used positional argument style — `AppError.unknown(error.localizedDescription)` — throughout EquipmentCheckInView.swift and MapsView.swift catch blocks. All references matched to the actual AppError.swift declarations (re-verified via file read at execute time).
- **Files modified:** `ready player 8/EquipmentCheckInView.swift` (line 181); `ready player 8/MapsView.swift` (2 catch blocks in loadMapData)
- **Verification:** `xcodebuild ... build` → BUILD SUCCEEDED.
- **Committed in:** `63b261c` (Task 1) + `64f8991` (Task 3, MapsView portion)

**2. [Rule 3 - Blocking] `latestLat: 40\.75[0-9]+` regex requires 4 matches; initial relocation produced 3**
- **Found during:** Task 2 verification
- **Issue:** Plan's `done` criteria include grep `latestLat: 40\.75[0-9]+ | wc -l | xargs test 4 -eq`. My initial relocation set eq-003 to `40.7600` — still within ±0.005 deg of mapCenter (0.002 deg above 40.758, well within spec), but `40.7600` does not match the regex because the literal "75" appears only in the 40.7585/40.7572/40.7558 rows, not 40.7600. Three matches instead of four.
- **Fix:** Rebound eq-003 from 40.7600 → 40.7598 (still above 40.758, within spec, now matches 40\.75[0-9]+). Zero behavioral change; cosmetic shift to satisfy plan verification as written.
- **Files modified:** `ready player 8/EquipmentModels.swift` (eq-003 latestLat only)
- **Verification:** `grep -cE "latestLat: 40\.75[0-9]+" ... → 4`
- **Committed in:** `8aa93e7` (Task 2) — the correction happened pre-commit, so no follow-up commit needed.

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Zero scope creep. Deviation 1 was a verbatim fidelity gap between the plan's illustrative code and the actual Swift source — expected; the plan's `<interfaces>` section was abbreviated. Deviation 2 was a regex/coord pairing nit that required a 0.0002-deg shift to satisfy the literal `done` criteria.

## Issues Encountered

- **Pre-existing modified files in working tree** — `.planning/PROJECT.md`, six prior PLAN.md files, and `supabase/.temp/cli-latest` were already modified on entry from earlier planning sessions. Per the plan's scope boundary rule (only touch files directly caused by this task), these were NOT staged or committed. The three task commits only touch the four Swift files in scope. The working tree still has the pre-existing modifications for the next plan/session to address.

## User Setup Required

None. Pure code changes on existing files. The Supabase allowlist extension is client-side only — it widens what the iOS client is willing to send, not what the remote accepts. Remote permission is separately governed by Phase 21 RLS (see Plan 21-08 note on `user_orgs` RLS path — that remains a Plan 21-11 UAT-walk concern and is out of scope for 21-09).

## Next Phase Readiness

- **Plan 21-10 (Wave 3 iOS: AUTO TRACK persistence + permission UX for Test 12)** is unblocked — this plan cleared the path on the same files (MapsView.swift + EquipmentCheckInView.swift) without stepping on Test 10 / Test 12 territory.
- **Plan 21-11 (re-walk)** gains:
  - iOS Test 11 should now flip to PASS with a configured Supabase (no "Invalid table name" error).
  - iOS Test 8 should now show 4 mock pins near NYC-Midtown when unconfigured, and fall back to mocks on empty-successful fetch.
  - iOS Test 9 should now show either real GPS photos (if any) OR the "0 PHOTOS WITH GPS" chip OR the 3 mock photo markers (if unconfigured) — no silent empty state.
  - iOS load errors + check-in submit errors now produce visible alerts, consistent with the project core value.

## Verification Evidence

- `grep -c "cs_equipment_latest_positions" "ready player 8/SupabaseService.swift"` → `2` (allowlist entry + existing verify-site reference)
- `grep -c "loadError" "ready player 8/MapsView.swift"` → `7` (state var + 2 catch-block assignments + 3 .alert references + 1 retry handler)
- `grep -cE "latestLat: 40\.75[0-9]+" "ready player 8/EquipmentModels.swift"` → `4`
- `grep -c "isEmpty && !SupabaseService.shared.isConfigured" "ready player 8/MapsView.swift"` → `2` (equipment + photo branches)
- `grep -c "mockPhotoAnnotations" "ready player 8/MapsView.swift"` → `3` (file-scope decl + 2 usages in fallback paths)
- `grep -c "0 PHOTOS WITH GPS" "ready player 8/MapsView.swift"` → `2` (comment + chip text)
- `xcodebuild -project "ready player 8.xcodeproj" -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17 Pro" -configuration Debug build 2>&1 | tail -5 | grep -c "BUILD SUCCEEDED"` → `1`
- `git log --oneline HEAD~3..HEAD` → `64f8991 fix(21-09): mock-photo fallback + empty-state chip + visible load errors` + `8aa93e7 fix(21-09): relocate mockEquipmentPositions to NYC-Midtown cluster` + `63b261c fix(21-09): allow cs_equipment* tables + surface check-in errors via AppError`

## Threat Flags

None new. Threat register entries from plan frontmatter honored:
- **T-21-25 (allowedTables tampering):** Additions are hard-coded Swift string literals in a `private static let` — no runtime mutation path. `grep "cs_equipment_latest_positions"` verified exactly the 3 intended entries landed (no typos, no extra additions).
- **T-21-26 (loadError alert message disclosure):** `AppError.errorDescription` is user-facing by construction. Raw errors wrapped via `AppError.unknown(error.localizedDescription)` may leak SDK detail, but the alert reaches only the authenticated user of this device — acceptable per threat register.
- **T-21-27 (silent throw-swallow repudiation):** Before this plan, CrashReporter absorbed errors with no user signal. After: both CrashReporter logs AND an on-screen alert appear when Supabase is configured. Audit trail is stronger at both ends.

## Self-Check: PASSED

- `ready player 8/SupabaseService.swift` Task 1 allowlist — `cs_equipment_latest_positions` → FOUND (2 occurrences incl. existing reference)
- `ready player 8/EquipmentCheckInView.swift` Task 1 AppError wrap — catch let appError pattern → FOUND
- `ready player 8/EquipmentModels.swift` Task 2 relocation — 4 latestLat entries in 40.75x range → FOUND
- `ready player 8/MapsView.swift` Task 1 + 3 loadError alert → FOUND (7 refs)
- `ready player 8/MapsView.swift` Task 2 empty-success gate → FOUND (2 refs: equipment + photo)
- `ready player 8/MapsView.swift` Task 3 mockPhotoAnnotations → FOUND (3 refs)
- `ready player 8/MapsView.swift` Task 3 chip text → FOUND (2 refs)
- Commit `63b261c` (Task 1) → `git log` shows HEAD~2
- Commit `8aa93e7` (Task 2) → `git log` shows HEAD~1
- Commit `64f8991` (Task 3) → `git log` shows HEAD
- `xcodebuild ... build` → BUILD SUCCEEDED

---
*Phase: 21-live-satellite-traffic-maps*
*Plan: 09*
*Completed: 2026-04-22*
