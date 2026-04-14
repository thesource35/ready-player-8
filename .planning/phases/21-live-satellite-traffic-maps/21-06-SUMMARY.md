---
phase: 21-live-satellite-traffic-maps
plan: 06
subsystem: portal-maps
tags: [portal, mapbox, map-overlays, nextjs, supabase, D-13]

# Dependency graph
requires:
  - phase: 20-client-portal-sharing
    provides: cs_portal_config table, sections_config JSONB, PortalCreateDialog, cs_report_shared_links token pattern
  - phase: 21-live-satellite-traffic-maps/21-03
    provides: mapbox-traffic-v1 pattern, equipment marker shapes, photo marker style (#8A8FCC)
provides:
  - PortalSectionsConfig extended with optional map_overlays field
  - DEFAULT_MAP_OVERLAYS constant for backward-compatible fallbacks
  - TEMPLATE_DEFAULTS seeded with per-template map overlay defaults
  - PortalCreateDialog MAP SETTINGS section with Show Map master toggle + 4 sub-toggles
  - /api/portal/map token-validated public endpoint returning overlay-filtered map data
  - /portal/[slug]/[project]/map public page rendering Mapbox with LOCKED overlays
  - PortalMapClient component (no toggle strip, no refresh, pure embed per D-13)
affects:
  - Future phases that expose project site data to portal viewers
  - Portal analytics (map view events can hook into existing portal audit log)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Public portal API uses token validation + service-role client + per-link rate limit (D-109)"
    - "Locked overlay rendering: config determined server-side, client cannot modify which layers show"
    - "Backward-compatible JSONB: DEFAULT_MAP_OVERLAYS applied when sections_config.map_overlays is absent"

key-files:
  created:
    - web/src/app/api/portal/map/route.ts
    - web/src/app/portal/[slug]/[project]/map/page.tsx
    - web/src/app/portal/[slug]/[project]/map/PortalMapClient.tsx
  modified:
    - web/src/lib/portal/types.ts
    - web/src/app/components/portal/PortalCreateDialog.tsx
    - web/src/app/api/portal/create/route.ts

key-decisions:
  - "Token-based API (not slug-based) for consistency with /api/portal/photos and /api/portal/[id]/* routes"
  - "Portal map page placed at /portal/[slug]/[project]/map to match existing portal URL structure (not /portal/[companySlug]/[slug]/map as plan suggested)"
  - "DEFAULT_MAP_OVERLAYS applied in THREE places (types.ts default, API route fallback, page fallback) for layered backward compatibility"
  - "PortalMapClient is client component ('use client'); server page fetches config and passes token so client component only needs a single /api/portal/map fetch"
  - "200ms delay on invalid token (T-21-17) matches /api/portal/photos pattern (D-122) for enumeration prevention"
  - "Equipment markers shape-coded (circle/rounded-square/diamond) per D-07, color-coded by status -- identical to main map"
  - "Photo markers purple (#8A8FCC) per 21-03 convention"
  - "Navigation control ADDED (pan/zoom interactive) but overlay toggle strip EXCLUDED -- locked per D-13"

patterns-established:
  - "Portal-scoped public API pattern: token -> cs_report_shared_links -> expiry/revoke check -> cs_portal_config -> service-role data fetch"
  - "Backward-compatible JSONB extension: new optional field + DEFAULT constant + coercion logic with fallbacks at read time"
  - "Client-component map embed: server component fetches config, passes token, client component fetches data + renders mapbox"

requirements-completed: [MAP-01, MAP-04]

# Metrics
duration: 22min
completed: 2026-04-14
---

# Phase 21 Plan 6: Portal Map Overlay Configuration Summary

**D-13 portal map overlay configuration with admin picker UI, token-validated public API, and locked-overlay Mapbox embed at /portal/[slug]/[project]/map.**

## Performance

- **Duration:** ~22 min
- **Started:** 2026-04-14T05:47:41Z (continuation from plan 21-05)
- **Completed:** 2026-04-14T06:07:46Z
- **Tasks:** 3
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments
- Extended PortalSectionsConfig with optional `map_overlays` field + DEFAULT_MAP_OVERLAYS constant + TEMPLATE_DEFAULTS seeding
- Added MAP SETTINGS section to PortalCreateDialog with Show Map master toggle and sub-toggles for satellite/traffic/equipment/photos
- Extended /api/portal/create to accept and merge map_overlays into sections_config
- Created /api/portal/map token-validated endpoint returning project-scoped map data filtered by overlay config
- Created public portal map page at /portal/[slug]/[project]/map with LOCKED overlays (no toggle strip per D-13)
- Created PortalMapClient renderer handling satellite/dark style, traffic layer, equipment/photo markers conditionally

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend portal types and queries with map_overlays** - `b62c7cb` (feat)
2. **Task 2: Add map overlay toggles to portal creation admin UI** - `4697f8e` (feat)
3. **Task 3: Create portal map API route and public portal map page** - `4391fba` (feat)

## Files Created/Modified

Created:
- `web/src/app/api/portal/map/route.ts` - Token-validated public map data API with per-link rate limiting
- `web/src/app/portal/[slug]/[project]/map/page.tsx` - Server component: fetches portal config, validates link, delegates to client
- `web/src/app/portal/[slug]/[project]/map/PortalMapClient.tsx` - Client Mapbox renderer with locked overlays

Modified:
- `web/src/lib/portal/types.ts` - Added map_overlays field, DEFAULT_MAP_OVERLAYS, TEMPLATE_DEFAULTS
- `web/src/app/components/portal/PortalCreateDialog.tsx` - Added MAP SETTINGS section and state
- `web/src/app/api/portal/create/route.ts` - Accepts and merges map_overlays into sectionsConfig

## Decisions Made

- **Token-based API instead of slug-based:** Consistent with existing portal API pattern (/api/portal/photos uses token). Slug lookup happens in the server page component, which then passes the validated token to the client for the data fetch.
- **Route path /portal/[slug]/[project]/map:** Matches existing portal route structure (slug = companySlug, project = portal slug). Plan mentioned [companySlug]/[slug]/map but existing routes use [slug]/[project] nomenclature. Used existing structure to avoid creating a parallel/conflicting portal route tree.
- **Backward compatibility via DEFAULT_MAP_OVERLAYS at three layers:** types.ts export, API route reader, page component reader — any portal created before Phase 21 automatically shows map with safe defaults.
- **Locked overlays enforced at API and UI:** API returns data only for enabled overlays; client renders markers only for enabled overlays; no toggle buttons in the UI. Client cannot show layers the admin disabled.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Route path aligned to existing portal URL structure**
- **Found during:** Task 3
- **Issue:** Plan specified `web/src/app/portal/[companySlug]/[slug]/map/page.tsx` but existing portal routes live under `web/src/app/portal/[slug]/[project]/` (slug = companySlug, project = portal slug). Creating the map page at the plan's path would have created a parallel route tree that couldn't share the existing portal lookup logic and would have failed Next.js duplicate-slug-detection on sibling dynamic segments.
- **Fix:** Created the page at `web/src/app/portal/[slug]/[project]/map/page.tsx` to match the existing structure. Functionally equivalent -- both params represent the same URL shape /portal/{companySlug}/{slug}/map.
- **Files modified:** web/src/app/portal/[slug]/[project]/map/page.tsx, web/src/app/portal/[slug]/[project]/map/PortalMapClient.tsx
- **Verification:** TypeScript compiles, route resolves correctly, matches existing portal routing convention
- **Committed in:** 4391fba

**2. [Rule 3 - Blocking] Token-based portal map API instead of slug-based**
- **Found during:** Task 3
- **Issue:** Plan described slug-based lookup for the API, but existing portal APIs (/api/portal/photos, /api/portal/[id]/*) all use token validation. Slug-based lookup exposes company_slug/slug URL components in every XHR and bypasses the revocation check on cs_report_shared_links.
- **Fix:** API accepts `?token=` query param, validates via cs_report_shared_links (checks is_revoked and expires_at), then loads config by link_id. Server page component performs the slug-based lookup once, passes the validated token to PortalMapClient.
- **Files modified:** web/src/app/api/portal/map/route.ts, web/src/app/portal/[slug]/[project]/map/page.tsx
- **Verification:** Matches /api/portal/photos validation sequence; per-link rate limit works; expired/revoked links return 410/403 correctly
- **Committed in:** 4391fba

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both deviations align implementation with established portal patterns. No scope creep, no functional divergence from D-13 spec.

## Issues Encountered

- **Pre-existing TypeScript errors in unrelated files** (BudgetSection/ChangeOrdersSection/DocumentsSection/PortalShell/AnnotationCanvas/reports test) -- out of scope for this plan; logged here for future cleanup. No errors in any file created or modified by this plan.

## User Setup Required

None — all changes are code-level. Portal creators will see the new MAP SETTINGS section the next time they open the Create Portal Link dialog.

## Next Phase Readiness

- Phase 21 plans 1-6 complete. All portal and map integration points shipped.
- `/portal/{company}/{project}/map` URL works for any portal link created via the dialog; backward-compatible with older portal links (uses DEFAULT_MAP_OVERLAYS).
- Ready for phase verification / end-to-end manual walkthrough.

---
*Phase: 21-live-satellite-traffic-maps*
*Completed: 2026-04-14*

## Self-Check: PASSED

All claimed files verified on disk:
- FOUND: web/src/app/api/portal/map/route.ts
- FOUND: web/src/app/portal/[slug]/[project]/map/page.tsx
- FOUND: web/src/app/portal/[slug]/[project]/map/PortalMapClient.tsx
- FOUND: web/src/lib/portal/types.ts
- FOUND: web/src/app/components/portal/PortalCreateDialog.tsx
- FOUND: .planning/phases/21-live-satellite-traffic-maps/21-06-SUMMARY.md

All claimed commits verified via `git log --all`:
- FOUND: b62c7cb (Task 1: extend portal types)
- FOUND: 4697f8e (Task 2: add map overlay toggles)
- FOUND: 4391fba (Task 3: portal map API + page)
