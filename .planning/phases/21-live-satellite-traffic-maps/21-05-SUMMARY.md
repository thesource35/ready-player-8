---
phase: 21-live-satellite-traffic-maps
plan: 05
subsystem: ios-maps
tags: [swift, swiftui, mapkit, corelocation, mkdirections, equipment-checkin, ios]

requires:
  - phase: 21-live-satellite-traffic-maps
    provides: "EquipmentModels + SupabaseService equipment methods (plan 02); enhanced MapsView with equipment annotations (plan 04)"
provides:
  - "EquipmentCheckInView sheet with GPS capture, equipment picker, and Supabase submission"
  - "CheckInLocationManager wrapping CLLocationManager with auth gating and error messaging"
  - "CHECK IN EQUIPMENT button, sheet presentation, and success toast on MapsView"
  - "MKDirections-backed delivery routes with Get Directions button per route, distance/ETA, and road-following polyline"
affects: [21-06-verification]

tech-stack:
  added: []
  patterns:
    - "CLLocationManager via ObservableObject + @Published with Combine import for SwiftUI bindings"
    - "MKDirections on-demand road route calculation with @State dictionary keyed by route UUID"
    - "Hide straight-line MapPolyline when a computed road route exists for the same route id"

key-files:
  created:
    - "ready player 8/EquipmentCheckInView.swift"
  modified:
    - "ready player 8/MapsView.swift"

key-decisions:
  - "computedRoutes keyed by MapRoute UUID (not label) since MapRoute.id is already unique"
  - "Straight-line MapPolyline hidden when a computed road route is present to avoid double rendering"
  - "Extracted loadMapData() as a named method so the check-in success callback can re-trigger data refresh"
  - "Delivery routes surfaced in a new sidebar section (DELIVERY ROUTES) so the Get Directions affordance is discoverable"

patterns-established:
  - "CheckInLocationManager pattern: NSObject+ObservableObject+CLLocationManagerDelegate with @Published location/accuracy/errorMessage triplet"
  - "Route calculation pattern: @State dictionary keyed by stable route id with separate computingRoute/routeError sentinel state"

requirements-completed: [MAP-03]

duration: 7min
completed: 2026-04-14
---

# Phase 21 Plan 05: iOS Equipment Check-In + Delivery Routes Summary

**EquipmentCheckInView sheet with GPS capture and CLLocationManager authorization handling; MapsView gains CHECK IN EQUIPMENT button, success toast, delivery routes sidebar, and MKDirections road-following polylines**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-14T05:33:51Z
- **Completed:** 2026-04-14T05:41:17Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- Created `EquipmentCheckInView` with Form-based UI: equipment picker (typed icons with status colors), live GPS coordinate/accuracy display with color-coded accuracy bands, notes field, submit error banner, and Cancel / Confirm Location toolbar
- Added `CheckInLocationManager` wrapping CLLocationManager with authorization gating (requests when-in-use on first entry, emits UI-SPEC error copy on denial)
- Wired submit flow to `SupabaseService.checkInEquipmentLocation(_:)` with onCheckInComplete callback returning equipment name to host view
- Added `CHECK IN EQUIPMENT` button to MapsView button bar (Theme.accent background per UI-SPEC) that presents EquipmentCheckInView as a sheet
- Implemented success toast overlay ("Location updated for {name}") that appears at top, animates in, and auto-dismisses after 3s
- Added `DELIVERY ROUTES` sidebar section with per-route cards showing route label, from→to, and Get Directions button
- Implemented MKDirections-backed `calculateRoute(for:)` that resolves MKPlacemark from site coordinates, calls `directions.calculate()`, and stores MKRoute in keyed dictionary
- Computed routes render as MapPolyline(route.polyline) in Theme.gold; straight-line connector is hidden when a computed route exists
- Route card displays distance (miles) and ETA (minutes) from MKRoute; shows "Computing route..." while in-flight and "Route unavailable. Showing straight-line connection." on error (UI-SPEC copy)
- Extracted existing `.task` closure into named `loadMapData()` so check-in success can re-trigger equipment/photo refresh

## Task Commits

Each task was committed atomically:

1. **Task 1: Create EquipmentCheckInView with GPS capture and equipment picker** — `5aea7e0` (feat)
2. **Task 2: Add Check In Equipment button, sheet, success toast, and MKDirections routes to MapsView** — `7e1400b` (feat)

## Files Created/Modified
- `ready player 8/EquipmentCheckInView.swift` (created) — EquipmentCheckInView struct (Form-based sheet), CheckInLocationManager class (CLLocationManagerDelegate with @Published properties), imports (Combine, CoreLocation, Foundation, MapKit, SwiftUI)
- `ready player 8/MapsView.swift` (modified) — Added showCheckInSheet / checkInSuccessMessage / computedRoutes / computingRoute / routeError state; CHECK IN EQUIPMENT button; .sheet and .overlay modifiers; DELIVERY ROUTES sidebar section; loadMapData() method; calculateRoute(for:) method; LiveMapView signature gained computedRoutes param; computed road route rendering with straight-line suppression

## Decisions Made
- computedRoutes dictionary keyed by `MapRoute.id` (UUID) rather than label — ids are already unique and stable across the view lifecycle
- Added `routeError` as a separate @State UUID sentinel (rather than embedding error in computedRoutes dictionary) to keep success and failure states orthogonal
- Hide the straight-line connector for a route once a road route is computed, so the road polyline is visually primary without flickering or overlap
- Placed DELIVERY ROUTES as its own sidebar card after EQUIPMENT rather than as an overlay on the map, matching the existing SAT PASSES/EQUIPMENT sidebar pattern
- Kept ObservableObject class instead of the newer @Observable macro to stay consistent with the rest of the iOS codebase (uses @StateObject elsewhere)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added missing `import Combine`**
- **Found during:** Task 1 build
- **Issue:** Xcode build failed with `static subscript 'subscript(_enclosingInstance:wrapped:storage:)' is not available due to missing import of defining module 'Combine'` — @Published property wrapper requires Combine on iOS 26 SDK in a file that only imports SwiftUI
- **Fix:** Added `import Combine` to EquipmentCheckInView.swift
- **Files modified:** ready player 8/EquipmentCheckInView.swift
- **Verification:** Xcode BUILD SUCCEEDED
- **Committed in:** 5aea7e0

**2. [Deviation - Plan Adaptation] Reused existing Hashable extension in EquipmentModels.swift**
- **Found during:** Task 1 planning
- **Issue:** Plan showed adding `extension SupabaseEquipment: Hashable` but this conformance already exists in EquipmentModels.swift (lines 158-161, added in plan 21-02)
- **Fix:** Did not duplicate the extension — the existing conformance already satisfies the Picker usage requirement
- **Files modified:** None (no-op)
- **Verification:** Picker in EquipmentCheckInView compiles and type-checks
- **Committed in:** 5aea7e0

**3. [Deviation - Plan Adaptation] `computedRoutes` keyed by UUID, not String**
- **Found during:** Task 2 implementation
- **Issue:** Plan showed `[String: MKRoute]` keyed by "route label" but MapRoute.id is already a stable UUID and labels are not guaranteed unique
- **Fix:** Used `[UUID: MKRoute]` keyed by MapRoute.id
- **Files modified:** ready player 8/MapsView.swift
- **Verification:** Xcode BUILD SUCCEEDED; all route card lookups work correctly
- **Committed in:** 7e1400b

**4. [Rule 2 - Missing critical functionality] Added `routeError` state and error copy**
- **Found during:** Task 2 implementation
- **Issue:** Plan mentioned "Route unavailable. Showing straight-line connection." error copy in UI-SPEC but did not specify the state variable to drive it
- **Fix:** Added `@State private var routeError: UUID?` and surfaced the UI-SPEC error copy when MKDirections fails or returns no routes
- **Files modified:** ready player 8/MapsView.swift
- **Verification:** Xcode BUILD SUCCEEDED
- **Committed in:** 7e1400b

**5. [Deviation - Plan Adaptation] Extracted `loadMapData()` helper**
- **Found during:** Task 2 implementation
- **Issue:** Plan wanted the success callback to call `loadMapData()` but the existing file had the loading logic inlined in the `.task` closure
- **Fix:** Extracted the existing task body into a `private func loadMapData() async` method; `.task` now calls `await loadMapData()` and the check-in callback can reuse it
- **Files modified:** ready player 8/MapsView.swift
- **Verification:** Xcode BUILD SUCCEEDED; behavior preserved for initial load
- **Committed in:** 7e1400b

---

**Total deviations:** 5 (1 blocking build fix, 1 no-op reuse, 3 plan adaptations for correctness)
**Impact on plan:** All adaptations necessary for correct behavior and compilation. No scope creep; all changes scoped to the plan's two listed files.

## Issues Encountered
- Xcode simulator initially failed on "iPhone 16" destination (not installed) — retried with "iPhone 17" which is available; non-blocking.
- Transient Xcode build database lock ("database is locked Possibly there are two concurrent builds running") after a Cmd-build + CLI build overlap — resolved on retry.

## Known Stubs
None — EquipmentCheckInView is fully wired end-to-end (CLLocationManager → CheckInLocationManager → EquipmentCheckInRequest → SupabaseService.checkInEquipmentLocation → cs_equipment_locations). MKDirections is on-demand per UI button press.

## User Setup Required
None — the Info.plist for this project already supports location permissions via existing CarPlay/iOS entitlements. Users will be prompted for "When In Use" location permission on first check-in attempt; this is standard iOS behavior.

## Next Phase Readiness
- iOS check-in loop complete: UI → CLLocationManager → SupabaseService → cs_equipment_locations → cs_equipment_latest_positions view → map refresh
- MKDirections integration complete for delivery routes (D-16)
- Ready for Plan 06 (verification) — no blockers
- Plan 04 and Plan 05 together complete all iOS requirements for MAP-01/02/03/04

## Self-Check: PASSED

All created/modified files verified on disk. Both task commits (5aea7e0, 7e1400b) verified in git log. Xcode BUILD SUCCEEDED.

---
*Phase: 21-live-satellite-traffic-maps*
*Completed: 2026-04-14*
