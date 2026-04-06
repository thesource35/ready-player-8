---
phase: 09-web-performance-dynamic-content
plan: 02
subsystem: web-api-performance
tags: [pagination, export-cap, chat-prompt, lazy-loading, geolocation, image-config]
dependency_graph:
  requires: []
  provides: [fetchTablePaginated, export-413-cap, summary-chat-prompt, lazy-map-popups, image-remotePatterns]
  affects: [web/src/lib/supabase/fetch.ts, web/src/app/api/export/route.ts, web/src/app/api/chat/route.ts, web/src/app/maps/page.tsx, web/next.config.ts]
tech_stack:
  added: []
  patterns: [range-based-pagination, head-only-count-queries, lazy-dom-creation, geolocation-with-fallback]
key_files:
  created: []
  modified:
    - web/src/lib/supabase/fetch.ts
    - web/src/app/api/export/route.ts
    - web/src/app/api/chat/route.ts
    - web/src/app/maps/page.tsx
    - web/next.config.ts
decisions:
  - pageSize capped at 100 max to prevent abuse via T-09-05 mitigation
  - Export count check uses head-only queries to avoid fetching data twice
  - Chat summary uses counts only (not serialized data) per PERF-03
  - Map creates popups lazily on click rather than eagerly on load
  - Geolocation uses flyTo after map init rather than delaying map creation
metrics:
  duration: 5m
  completed: "2026-04-06T02:16:42Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 5
---

# Phase 9 Plan 2: Pagination, Export Cap, Chat Prompt, Lazy Maps, Image Config Summary

Paginated Supabase queries with range support, 413 export cap at 1000 rows, chat prompt reduced to summary counts, lazy map popups with geolocation center, and Next.js image remotePatterns for Supabase/Mapbox.

## What Was Done

### Task 1: Add paginated fetchTable and cap export API
- Added `fetchTablePaginated<T>` to `web/src/lib/supabase/fetch.ts` with range-based pagination (default 25, max 100 via MAX_PAGE_SIZE)
- Returns `{ data, hasMore, total }` for load-more UI patterns
- Export API now checks row counts per table using head-only queries before fetching
- Returns HTTP 413 if any table exceeds 1000 rows
- Replaced hardcoded `version: "2.0"` with `process.env.npm_package_version || "unknown"`
- Commit: `0191d1d`

### Task 2: Replace chat system prompt with summary counts
- Added `createServerSupabase` import to chat route
- Fetches project, contract, and punch item counts via head-only queries (count: "exact", head: true)
- Appends USER DATA SUMMARY section to system prompt with counts only
- Non-critical failure path: if Supabase is unavailable, prompt works without summary
- No serialized data sent in prompt (PERF-03)
- Commit: `86a08c8`

### Task 3: Lazy map popups, geolocation center, image remotePatterns
- Refactored popup creation from eager (on map load) to lazy (on marker click)
- Uses `getPopup()` check to avoid re-creating popup on subsequent clicks
- Added `navigator.geolocation.getCurrentPosition()` with 3-second timeout and Houston fallback
- Uses `flyTo` after map initialization rather than delaying map creation
- Added `images.remotePatterns` to next.config.ts for `**.supabase.co` and `api.mapbox.com`
- Commit: `5941304`

## Deviations from Plan

None -- plan executed exactly as written.

## Decisions Made

1. **MAX_PAGE_SIZE = 100**: Caps pageSize parameter to prevent clients from requesting unbounded pages (T-09-05 mitigation)
2. **flyTo instead of delayed init**: Map creates immediately with Houston default, then flies to user location if geolocation succeeds -- better UX than waiting for geolocation before showing any map

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 0191d1d | feat(09-02): add paginated fetchTable and cap export API at 1000 rows |
| 2 | 86a08c8 | feat(09-02): replace chat system prompt with summary counts |
| 3 | 5941304 | feat(09-02): lazy map popups, geolocation center, image remotePatterns |

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-09-05 | pageSize capped at MAX_PAGE_SIZE (100); RLS still applies |
| T-09-06 | 1000-row cap with 413 response prevents memory exhaustion |
| T-09-07 | Only counts sent in chat prompt, no PII or actual data |
| T-09-08 | Geolocation is browser opt-in; Houston fallback if declined |

## Self-Check: PASSED

All 5 modified files verified present. All 3 task commits verified in git log.
