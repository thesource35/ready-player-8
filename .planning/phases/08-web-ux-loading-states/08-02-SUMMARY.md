---
phase: 08-web-ux-loading-states
plan: 02
subsystem: web-ux
tags: [loading-states, empty-states, ux, web]
dependency_graph:
  requires: []
  provides: [loading-indicators, maps-fallback, jobs-empty-state]
  affects: [web/src/app/maps/page.tsx, web/src/app/jobs/page.tsx, web/src/app/ai/page.tsx, web/src/app/punch/page.tsx, web/src/app/ops/page.tsx, web/src/app/tasks/page.tsx]
tech_stack:
  added: []
  patterns: [useState-driven-loading, conditional-rendering-fallbacks]
key_files:
  modified:
    - web/src/app/maps/page.tsx
    - web/src/app/jobs/page.tsx
    - web/src/app/ai/page.tsx
    - web/src/app/punch/page.tsx
    - web/src/app/ops/page.tsx
    - web/src/app/tasks/page.tsx
decisions:
  - Used early return pattern for loading indicators on AI, punch, and tasks pages
  - Used inline ternary for ops page to keep loading inside PremiumFeatureGate
  - Used HTML entity for emoji rendering to avoid encoding issues
metrics:
  duration: 247s
  completed: 2026-04-06T00:30:33Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 6
---

# Phase 08 Plan 02: Loading Indicators and Empty States Summary

Inline useState-driven loading indicators and fallback UI for six data-fetching pages: maps unavailable card, jobs empty state, and LOADING... text indicators for AI, punch, ops, and tasks.

## Completed Tasks

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Add maps unavailable fallback and jobs empty state | 97b06c2 | web/src/app/maps/page.tsx, web/src/app/jobs/page.tsx |
| 2 | Add loading indicators to AI, punch, ops, and tasks pages | 3d8ee2e | web/src/app/ai/page.tsx, web/src/app/punch/page.tsx, web/src/app/ops/page.tsx, web/src/app/tasks/page.tsx |

## Changes Made

### Maps Page - Unavailable Fallback
- Added `token` const reading `NEXT_PUBLIC_MAPBOX_TOKEN` at component level
- Conditionally renders a styled "Maps Unavailable" card when token is falsy, replacing the map container
- Rest of page (sites list, satellites, routes, overlays) still renders normally

### Jobs Page - Empty State
- Added `jobs.length === 0` check between the loading state and filtered empty state
- Shows "No Jobs Found" card with clipboard emoji when total jobs array is empty after fetch
- Preserved existing "No jobs in this filter yet" for when jobs exist but filter yields no results

### AI, Punch, Ops, Tasks Pages - Loading Indicators
- AI page: Added `pageLoading` useState, set false on mount via useEffect, early return with LOADING... indicator
- Punch page: Added `loading` useState, set false via `.finally()` on fetch promise chain, early return
- Ops page: Added `loading` useState with `.finally()`, loading indicator rendered inside PremiumFeatureGate via ternary
- Tasks page: Added `loading` useState with `.finally()`, early return with LOADING... indicator
- All indicators use consistent styling: `var(--accent)` color, `0.2em` letter-spacing, `fontWeight: 900`, centered in `40vh` container

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None - all loading states are wired to real fetch completion signals.

## Verification

- Maps page contains "Maps Unavailable" and "Configure MAPBOX_TOKEN to enable interactive maps"
- Jobs page contains "No Jobs Found" and preserves "No jobs in this filter yet"
- All four pages (ai, punch, ops, tasks) contain "LOADING..." with correct styling
- TypeScript compilation passes with no errors in modified files
- Note: `npm run build` has a pre-existing middleware/proxy conflict error unrelated to these changes

## Self-Check: PASSED

All 6 modified files verified on disk. Both commit hashes (97b06c2, 3d8ee2e) confirmed in git log.
