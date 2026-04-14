---
phase: 21-live-satellite-traffic-maps
plan: 02
subsystem: database
tags: [swift, codable, supabase, equipment-tracking, mapkit, ios]

requires:
  - phase: 21-live-satellite-traffic-maps
    provides: "cs_equipment, cs_equipment_locations tables and cs_equipment_latest_positions view (plan 01)"
provides:
  - "iOS Codable DTOs for equipment tracking (SupabaseEquipment, SupabaseEquipmentLocation, SupabaseEquipmentLatestPosition)"
  - "EquipmentCheckInRequest Encodable struct for location submissions"
  - "SupabaseService equipment fetch/check-in methods"
  - "Mock data arrays for offline fallback"
affects: [21-04-ios-maps-view, 21-05-ios-checkin-flow]

tech-stack:
  added: []
  patterns: ["camelCase DTOs with convertFromSnakeCase decoder for Supabase view columns"]

key-files:
  created:
    - "ready player 8/EquipmentModels.swift"
  modified:
    - "ready player 8/SupabaseService.swift"

key-decisions:
  - "camelCase Swift properties with SupabaseService convertFromSnakeCase decoder (matches existing DTO pattern)"
  - "SupabaseEquipmentLatestPosition matches view columns (latest_lat, latest_lng, latest_recorded_at, latest_accuracy_m) not raw location table columns"
  - "checkInEquipmentLocation returns Void since insert() method does not return response data"

patterns-established:
  - "Equipment DTOs follow same camelCase pattern as Portal DTOs (Phase 20)"
  - "View-backed DTOs use view alias names (latest_ prefix) not raw table column names"

requirements-completed: [MAP-03]

duration: 7min
completed: 2026-04-14
---

# Phase 21 Plan 02: iOS Equipment Data Layer Summary

**Codable DTOs for equipment/vehicle/material tracking with SupabaseService fetch and check-in methods matching cs_equipment_latest_positions view**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-14T00:14:28Z
- **Completed:** 2026-04-14T01:57:39Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created EquipmentModels.swift with 6 types (3 enums, 3 structs), 1 request struct, and 2 mock data arrays
- Extended SupabaseService with 3 equipment methods (fetchEquipment, fetchEquipmentPositions, checkInEquipmentLocation)
- Xcode build succeeds with all new types and methods

## Task Commits

Each task was committed atomically:

1. **Task 1: Create EquipmentModels.swift with all Codable DTOs and mock data** - `c7f8981` (feat)
2. **Task 2: Extend SupabaseService with equipment fetch and check-in methods** - `c837152` (feat)

## Files Created/Modified
- `ready player 8/EquipmentModels.swift` - Equipment enums (EquipmentAssetType, EquipmentStatus, LocationSource), DTOs (SupabaseEquipment, SupabaseEquipmentLocation, SupabaseEquipmentLatestPosition), EquipmentCheckInRequest, Hashable extension, mock data
- `ready player 8/SupabaseService.swift` - Added fetchEquipment(), fetchEquipmentPositions(), checkInEquipmentLocation() in new "Equipment Methods (Phase 21)" MARK section

## Decisions Made
- Used camelCase Swift properties (e.g., `orgId`, `assignedProject`, `latestLat`) to match SupabaseService's `.convertFromSnakeCase` decoder strategy, deviating from the plan which showed snake_case field names
- SupabaseEquipmentLatestPosition maps to the actual view columns (`id`, `latest_lat`, `latest_lng`, etc.) rather than the plan's proposed `location_id`/`equipment_id` split which didn't match the real view schema
- checkInEquipmentLocation returns Void (matching existing `insert()` signature) rather than returning a decoded SupabaseEquipmentLocation as the plan proposed
- EquipmentCheckInRequest uses an explicit init with `source` defaulting to "manual" instead of a property default, for cleaner call-site ergonomics

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed DTO property naming to match decoder strategy**
- **Found during:** Task 1 (EquipmentModels.swift creation)
- **Issue:** Plan specified snake_case property names (e.g., `org_id`, `equipment_id`) but SupabaseService decoder uses `.convertFromSnakeCase` which expects camelCase properties
- **Fix:** Used camelCase properties throughout (orgId, equipmentId, latestLat, etc.)
- **Files modified:** ready player 8/EquipmentModels.swift
- **Verification:** Xcode build succeeded
- **Committed in:** c7f8981

**2. [Rule 1 - Bug] Fixed SupabaseEquipmentLatestPosition to match actual view schema**
- **Found during:** Task 1 (EquipmentModels.swift creation)
- **Issue:** Plan's DTO had `location_id` + `equipment_id` + separate location fields, but the actual cs_equipment_latest_positions view uses equipment `id` as primary key with `latest_` prefixed location columns
- **Fix:** Matched the actual view output: `id` (equipment id), `latestLat`, `latestLng`, `latestRecordedAt`, `latestAccuracyM`
- **Files modified:** ready player 8/EquipmentModels.swift
- **Verification:** Field names align with view SQL in migration file
- **Committed in:** c7f8981

**3. [Rule 1 - Bug] Adapted checkInEquipmentLocation to existing insert() signature**
- **Found during:** Task 2 (SupabaseService extension)
- **Issue:** Plan assumed insertRow returns Data for decoding; actual insert() returns Void
- **Fix:** checkInEquipmentLocation returns Void, matching existing insert pattern
- **Files modified:** ready player 8/SupabaseService.swift
- **Verification:** Xcode build succeeded
- **Committed in:** c837152

**4. [Rule 1 - Bug] Adapted fetch methods to use existing fetch() signature**
- **Found during:** Task 2 (SupabaseService extension)
- **Issue:** Plan assumed fetchTable(table:query:) with string query param; actual is fetch(_:query:[String:String]:)
- **Fix:** Used fetch() with dictionary query parameters matching actual method signature
- **Files modified:** ready player 8/SupabaseService.swift
- **Verification:** Xcode build succeeded
- **Committed in:** c837152

---

**Total deviations:** 4 auto-fixed (4 bug fixes)
**Impact on plan:** All fixes necessary for correctness -- code would not compile without them. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Equipment DTOs and service methods ready for Plans 04 (iOS MapsView) and 05 (iOS check-in flow)
- Mock data available for offline development and testing
- All types conform to Codable for automatic Supabase JSON serialization

---
*Phase: 21-live-satellite-traffic-maps*
*Completed: 2026-04-14*

## Self-Check: PASSED
