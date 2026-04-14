---
phase: 21-live-satellite-traffic-maps
plan: 03
subsystem: api, ui
tags: [mapbox, traffic, equipment-tracking, gps-photos, directions-api, nextjs, supabase]

# Dependency graph
requires:
  - phase: 21-live-satellite-traffic-maps
    provides: "TypeScript types, equipment API helpers, Supabase schema (plan 01)"
provides:
  - "4 API routes: equipment positions, check-in, GPS photos, map sites"
  - "Enhanced maps page with traffic overlay, equipment markers, photo markers"
  - "Overlay and camera persistence via localStorage"
  - "On-demand delivery route directions via Mapbox Directions API"
affects: [21-04, 21-05, 21-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "API routes use getAuthenticatedClient from @/lib/supabase/fetch with try/catch and [maps/endpoint] prefix logging"
    - "Map markers rebuilt via useCallback + useEffect on data change for clean lifecycle"
    - "style.load event handler re-adds all custom layers after Mapbox style switch"

key-files:
  created:
    - web/src/app/api/maps/equipment/route.ts
    - web/src/app/api/maps/check-in/route.ts
    - web/src/app/api/maps/photos/route.ts
    - web/src/app/api/maps/sites/route.ts
  modified:
    - web/src/app/maps/page.tsx

key-decisions:
  - "API routes follow reports/health pattern: getAuthenticatedClient, try/catch, NextResponse.json"
  - "Equipment check-in validates lat [-90,90], lng [-180,180], equipment_id non-empty, sets recorded_by server-side (T-21-06, T-21-10)"
  - "Routes data includes coordinates for Mapbox Directions API integration"
  - "Photo markers use purple (#8A8FCC) to visually distinguish from equipment and site markers"

patterns-established:
  - "Map marker rebuild pattern: useCallback for builder, useEffect for trigger, ref array for cleanup"
  - "Traffic layer add/remove as standalone functions reusable across style reload and toggle"

requirements-completed: [MAP-01, MAP-02, MAP-03, MAP-04]

# Metrics
duration: 10min
completed: 2026-04-14
---

# Phase 21 Plan 03: Web Map Enhancement Summary

**Traffic overlay, equipment markers with typed shapes, GPS photo markers, Supabase data loading with mock fallback, localStorage persistence, and Mapbox Directions API for delivery routes**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-14T02:11:10Z
- **Completed:** 2026-04-14T02:22:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created 4 API routes under /api/maps/ for equipment positions (GET with filters), check-in (POST with validation), GPS photos (GET), and map sites (GET)
- Enhanced maps page with 7 new overlay capabilities: TRAFFIC toggle with Mapbox Traffic v1 vector layer, PHOTOS toggle with GPS-tagged photo markers, equipment markers with typed shapes (circle for equipment, rounded-square for vehicles, diamond for materials) and status colors (green/gold/red)
- Implemented overlay and camera persistence via localStorage using MAP_STORAGE_KEYS
- Added style.load event handler to preserve all custom layers when toggling SATELLITE style
- Added refresh button with rotation animation for on-demand equipment position reload
- Built equipment cards section with type filter bar (All/Equipment/Vehicles/Materials) and empty state
- Integrated Mapbox Directions API for on-demand road-following delivery route computation with GeoJSON line rendering
- Traffic legend overlay shows color coding (green=flowing, yellow=slow, red=congested)
- Site cards dynamically switch to Supabase data when available, falling back to hardcoded mock data

## Task Commits

Each task was committed atomically:

1. **Task 1: Create web API routes for maps data** - `ad08964` (feat)
2. **Task 2: Enhance maps page with traffic, equipment, photos, routes** - `852e1f6` (feat)

## Files Created/Modified
- `web/src/app/api/maps/equipment/route.ts` - Equipment positions GET with project_id/type/status filters
- `web/src/app/api/maps/check-in/route.ts` - Equipment check-in POST with lat/lng/equipment_id validation
- `web/src/app/api/maps/photos/route.ts` - GPS photos GET with project_id filter
- `web/src/app/api/maps/sites/route.ts` - Map sites GET from cs_projects
- `web/src/app/maps/page.tsx` - Full map enhancement (traffic, equipment, photos, persistence, directions)

## Decisions Made
- API routes follow the existing reports/health pattern: getAuthenticatedClient for auth, try/catch with console.error logging, NextResponse.json responses
- Equipment check-in validates coordinates and sets recorded_by from authenticated user server-side (T-21-06, T-21-10)
- Routes hardcoded data extended with fromLng/fromLat/toLng/toLat for Directions API
- Photo markers use purple (#8A8FCC) to visually distinguish from equipment and site markers
- Map marker rebuild uses useCallback + useEffect pattern for clean React lifecycle

## Deviations from Plan

None - plan executed exactly as written.

## Threat Surface Scan

All threat model mitigations implemented:
- T-21-06: check-in validates lat [-90,90], lng [-180,180], equipment_id non-empty, isNaN checks
- T-21-07: All API routes require authenticated client
- T-21-08: All popup content passes through escapeHtml
- T-21-10: recorded_by set from user.id server-side, not from client body

## Issues Encountered
None.

## Known Stubs
None - all data paths are wired to API endpoints with mock fallback.

## Self-Check: PASSED
