---
phase: 20-client-portal-sharing
plan: 06
subsystem: web-portal-management
tags: [portal, management-ui, create-dialog, list-table, templates, section-editor, live-preview, analytics]

requires:
  - phase: 20-03
    provides: Portal API routes (create, config, revoke, preview, analytics)
  - phase: 20-04
    provides: Portal SSR page, PortalShell, section components
provides:
  - Portal management dashboard at /portals with sortable link table
  - Link creation dialog with template selection, expiry, custom slug, section visibility
  - PortalTemplates component with 3 preset cards showing enabled sections
  - SectionVisibilityEditor with per-section toggles, date ranges, pinned items, notes
  - LivePreviewPanel with iframe mode and inline mini-preview
  - PortalAnalyticsDashboard with summary cards, per-section table, recharts bar chart
  - Portal list API route at /api/portal/list
affects: [20-07, 20-08, 20-10]

tech-stack:
  added: []
  patterns: [portal-management-page, section-visibility-editor, live-preview-panel, analytics-dashboard]

key-files:
  created:
    - web/src/app/portals/page.tsx
    - web/src/app/components/portal/PortalCreateDialog.tsx
    - web/src/app/components/portal/PortalListTable.tsx
    - web/src/app/components/portal/PortalTemplates.tsx
    - web/src/app/components/portal/SectionVisibilityEditor.tsx
    - web/src/app/components/portal/LivePreviewPanel.tsx
    - web/src/app/components/portal/PortalAnalyticsDashboard.tsx
    - web/src/app/api/portal/list/route.ts
  modified: []

decisions:
  - "All 7 management components created as use client components with inline styles using design tokens"
  - "Recharts Tooltip formatter uses any type for Recharts 3.x compatibility (matching Phase 19 pattern)"
  - "Portal list API route added at /api/portal/list wrapping portalQueries.listPortalLinks()"
  - "SectionVisibilityEditor and LivePreviewPanel created in Task 1 alongside PortalCreateDialog due to import dependency"

metrics:
  duration: 27min
  completed: 2026-04-13
  tasks: 2
  files_created: 8

self-check: PASSED
---

# Phase 20 Plan 06: Portal Management UI Summary

**Portal management dashboard with link creation dialog, sortable table, section visibility editor, live preview panel, analytics dashboard, and 3 preset templates**

## Performance

- **Duration:** 27 min
- **Started:** 2026-04-13T13:06:26Z
- **Completed:** 2026-04-13T13:33:45Z
- **Tasks:** 2
- **Files created:** 8

## Accomplishments

- Portal management page at `/portals` with authenticated access, sortable link table, empty state, and toast notifications
- PortalCreateDialog modal with project selector, 3 template cards, expiry dropdown (7/30/90/never), custom slug input with validation, client email, section visibility editor, and live preview panel
- PortalListTable with sortable columns (project, slug, template, status, views, created), status dots (green=active, gray=expired, red=revoked), alternating row colors, and confirmation dialogs for revoke/delete
- PortalTemplates with 3 preset cards (Executive Summary, Full Progress, Photo Update) showing which sections are enabled via checkmarks
- SectionVisibilityEditor with toggle switches for 5 sections in SECTION_ORDER, select all/deselect all, per-section date range pickers, pinned items display, section notes with 200-char limit, budget warning, and show exact amounts toggle
- LivePreviewPanel with iframe mode for existing portals (fetches preview token) and inline mini-preview for creation showing enabled/disabled sections
- PortalAnalyticsDashboard with summary cards (Total Views, Unique Viewers, Avg Time Spent, Last Viewed), per-section analytics table, time period selector (7/30/90/all), and daily views bar chart via Recharts
- Portal list API route at `/api/portal/list` with authentication and rate limiting

## Task Commits

1. **Task 1: Portal management page, create dialog, list table, templates + supporting components** - `752eaac` (feat)
2. **Task 2: Refine analytics dashboard with proper recharts import** - `e8bdfad` (feat)

## Files Created

- `web/src/app/portals/page.tsx` - Portal management dashboard with link table, create CTA, empty state, analytics view
- `web/src/app/components/portal/PortalCreateDialog.tsx` - Link creation modal with template, expiry, slug, email, section visibility, preview
- `web/src/app/components/portal/PortalListTable.tsx` - Sortable table with status dots, actions, revoke/delete confirmation dialogs
- `web/src/app/components/portal/PortalTemplates.tsx` - 3 preset template cards with enabled section checkmarks
- `web/src/app/components/portal/SectionVisibilityEditor.tsx` - Toggle grid with date ranges, pinned items, notes, budget warning
- `web/src/app/components/portal/LivePreviewPanel.tsx` - Iframe preview for existing, inline mini-preview for creation
- `web/src/app/components/portal/PortalAnalyticsDashboard.tsx` - Summary cards, per-section table, Recharts bar chart
- `web/src/app/api/portal/list/route.ts` - Authenticated list endpoint wrapping portalQueries.listPortalLinks

## Decisions Made

- All management components use `"use client"` with inline styles referencing design tokens (consistent with existing portal components)
- Recharts 3.x Tooltip `labelFormatter` typed as `any` to match Phase 19 compatibility pattern
- SectionVisibilityEditor and LivePreviewPanel built in Task 1 since PortalCreateDialog imports them directly
- Portal list API route added as missing endpoint needed by the management page (deviation Rule 3 - blocking issue)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added /api/portal/list endpoint**
- **Found during:** Task 1
- **Issue:** The portals page needs to fetch the user's portal links, but no list API endpoint existed
- **Fix:** Created `/api/portal/list/route.ts` wrapping the existing `listPortalLinks()` from portalQueries
- **Files created:** `web/src/app/api/portal/list/route.ts`
- **Commit:** 752eaac

**2. [Rule 3 - Blocking] SectionVisibilityEditor, LivePreviewPanel, PortalAnalyticsDashboard created in Task 1**
- **Found during:** Task 1
- **Issue:** PortalCreateDialog imports SectionVisibilityEditor and LivePreviewPanel; portals/page.tsx imports PortalAnalyticsDashboard. All needed for Task 1 to compile.
- **Fix:** Fully implemented all 3 components in Task 1 instead of waiting for Task 2
- **Impact:** Task 2 became a refinement-only task (replacing dynamic require with static import)
- **Commit:** 752eaac

## Issues Encountered

None.

## User Setup Required

None -- no external service configuration required.

## Next Phase Readiness

- Portal management UI complete and ready for integration with branding editor (Plan 07)
- Section visibility editor ready for inline editing from list table
- Analytics dashboard ready for production use with real portal view data

---
*Phase: 20-client-portal-sharing*
*Completed: 2026-04-13*
