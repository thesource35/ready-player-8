---
phase: 21-live-satellite-traffic-maps
plan: 01
subsystem: database, api, testing
tags: [mapbox, supabase, equipment-tracking, gps, rls, typescript, vitest]

# Dependency graph
requires:
  - phase: 16-field-tools
    provides: GPS-tagged photos on maps
  - phase: 20-client-portal-sharing
    provides: Portal may embed maps
provides:
  - TypeScript types for equipment, map overlays, and portal map config
  - Supabase cs_equipment and cs_equipment_locations tables with RLS
  - cs_projects lat/lng columns for map site display
  - Equipment API helper functions (fetch, check-in, GPS photos, map sites)
  - Test stubs for MAP-01 through MAP-04 (23 tests, 8 implemented)
  - cs_equipment_latest_positions database view
affects: [21-02, 21-03, 21-04, 21-05, 21-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Equipment API uses createClient from @/lib/supabase/client with try/catch and [maps] prefix logging"
    - "Coordinate validation as standalone pure function (validateCoordinates) reusable across layers"
    - "Append-only location history (no UPDATE/DELETE RLS on cs_equipment_locations)"

key-files:
  created:
    - web/src/lib/maps/types.ts
    - web/src/lib/maps/equipment-api.ts
    - web/src/__tests__/maps/map-layers.test.ts
    - web/src/__tests__/maps/traffic-overlay.test.ts
    - web/src/__tests__/maps/equipment-tracking.test.ts
    - web/src/__tests__/maps/photo-overlay.test.ts
    - supabase/migrations/20260412001_phase21_equipment_tables.sql
    - supabase/migrations/20260412002_phase21_equipment_rls.sql
  modified: []

key-decisions:
  - "Append-only cs_equipment_locations with no UPDATE/DELETE RLS for tamper-proof location history (T-21-04)"
  - "Database CHECK constraints enforce lat [-90,90] and lng [-180,180] at schema level, duplicated in API validateCoordinates (T-21-02)"
  - "cs_equipment_latest_positions as database view using DISTINCT ON for efficient latest-position queries"

patterns-established:
  - "Equipment API pattern: createClient per call, try/catch with console.error('[maps]'), return empty array or null on error"
  - "Map overlay keys as union type with ALL_OVERLAY_KEYS constant array for iteration"

requirements-completed: [MAP-01, MAP-02, MAP-03, MAP-04]

# Metrics
duration: 15min
completed: 2026-04-14
---

# Phase 21 Plan 01: Foundation Summary

**TypeScript types, equipment API helpers, Supabase schema (cs_equipment + cs_equipment_locations with RLS), and 23 test stubs for MAP-01 through MAP-04**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-13T23:50:00Z
- **Completed:** 2026-04-14T00:02:12Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Created comprehensive TypeScript types module with Equipment, EquipmentLocation, MapSiteRow, GpsPhoto, PortalMapOverlays, and display constants (STATUS_COLORS, TRAFFIC_COLORS, EQUIPMENT_ICONS, MAP_STORAGE_KEYS)
- Built equipment API module with 6 exported functions: validateCoordinates, fetchEquipment, fetchEquipmentPositions, checkInEquipment, fetchGpsPhotos, fetchMapSites
- Created 2 Supabase migrations: equipment tables with constraints/indexes/view, and 5 org-scoped RLS policies
- Added 23 test entries across 4 test files (8 implemented with assertions, 15 todo stubs) covering all 4 MAP requirements
- Pushed migrations to Supabase successfully (cs_equipment, cs_equipment_locations, cs_equipment_latest_positions view, cs_projects lat/lng columns)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create map types module and equipment API helper** - `01e46f8` (feat)
2. **Task 2: Create test stubs and Supabase schema migrations** - `ecaf4fe` (feat)
3. **Task 3: Push database schema to Supabase** - User-executed (checkpoint:human-action, migrations pushed successfully)

## Files Created/Modified
- `web/src/lib/maps/types.ts` - Equipment, location, overlay types and display constants
- `web/src/lib/maps/equipment-api.ts` - Supabase fetch/insert functions for equipment data
- `web/src/__tests__/maps/map-layers.test.ts` - 5 test stubs for MAP-01 (layer toggle)
- `web/src/__tests__/maps/traffic-overlay.test.ts` - 4 tests for MAP-02 (1 implemented, 3 todo)
- `web/src/__tests__/maps/equipment-tracking.test.ts` - 9 tests for MAP-03 (4 implemented, 5 todo)
- `web/src/__tests__/maps/photo-overlay.test.ts` - 5 test stubs for MAP-04 (photo overlay)
- `supabase/migrations/20260412001_phase21_equipment_tables.sql` - cs_equipment + cs_equipment_locations tables, indexes, view, cs_projects lat/lng
- `supabase/migrations/20260412002_phase21_equipment_rls.sql` - RLS policies for equipment tables (5 policies)

## Decisions Made
- Append-only cs_equipment_locations with no UPDATE/DELETE RLS for tamper-proof location history (T-21-04)
- Database CHECK constraints enforce coordinate ranges at schema level, duplicated in API validateCoordinates for client-side validation (T-21-02)
- cs_equipment_latest_positions as database view using DISTINCT ON for efficient latest-position queries

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - database migrations were pushed during Task 3 checkpoint.

## Next Phase Readiness
- All types and API helpers ready for Plans 21-02 (iOS Swift models) and 21-03 (web map enhancement)
- Database schema deployed: cs_equipment, cs_equipment_locations, cs_equipment_latest_positions view, cs_projects lat/lng columns
- Test stubs in place for verification during implementation plans
- No blockers for subsequent plans

## Self-Check: PASSED

All 8 created files verified on disk. Both task commits (01e46f8, ecaf4fe) verified in git log.

---
*Phase: 21-live-satellite-traffic-maps*
*Completed: 2026-04-14*
