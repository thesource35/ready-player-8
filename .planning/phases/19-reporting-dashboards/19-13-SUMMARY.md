---
phase: 19-reporting-dashboards
plan: 13
subsystem: ui
tags: [reports, i18n, next-intl, themes, keyboard-shortcuts, bookmarks, bulk-operations]

# Dependency graph
requires:
  - phase: 19-reporting-dashboards
    provides: Report constants with REPORT_THEMES, CHART_COLORS (plan 01)
  - phase: 19-reporting-dashboards
    provides: Report pages at /reports with project list and section components (plan 05)
  - phase: 19-reporting-dashboards
    provides: Export functionality and PDF generation (plan 07)
provides:
  - i18n foundation with next-intl and English message catalog for all report labels
  - 5 report themes (Professional, Construction, Corporate, Minimal, Executive) with CSS variable override system
  - Keyboard shortcuts (Cmd+P/E/S/R/?) with optional vim-mode navigation
  - Bookmark/favorites system with localStorage persistence and drag-and-drop dashboard
  - Bulk operations bar with delete/export/revoke/pause/resume and confirmation dialogs
affects: [19-14, 19-15, 19-16]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Report theme system: CSS custom properties applied to container via applyThemeToElement()"
    - "Keyboard shortcut pattern: useEffect + addEventListener with input field exclusion"
    - "Bookmark persistence: localStorage with JSON array and MAX_BOOKMARKS cap"
    - "Bulk operations: confirmation dialog for destructive actions, MAX_BULK_ITEMS=50 (T-19-34)"

key-files:
  created:
    - web/src/lib/reports/i18n-messages/en.json
    - web/src/i18n.ts
    - web/src/lib/reports/report-themes.ts
    - web/src/app/reports/components/ReportThemeSwitcher.tsx
    - web/src/app/reports/components/KeyboardShortcuts.tsx
    - web/src/app/reports/components/BookmarkButton.tsx
    - web/src/app/reports/components/BulkOperationsBar.tsx
  modified:
    - web/src/middleware.ts

key-decisions:
  - "i18n uses next-intl getRequestConfig with English-only to start, extensible to additional locales"
  - "Report themes use CSS custom properties applied to container element, not global styles"
  - "Custom CSS themes sanitized against script injection patterns (T-19-35)"
  - "Keyboard shortcuts exclude input/textarea/select to prevent conflicts"
  - "Bookmarks stored in localStorage with 50-item cap"
  - "Bulk operations limited to 50 items per request with confirmation for destructive actions (T-19-34)"

patterns-established:
  - "Theme switcher pattern: preview-on-hover with restore-on-leave before commit"
  - "Bulk operations pattern: fixed bottom bar, count display, action buttons with destructive/non-destructive styling"
  - "i18n message structure: nested by feature area (reports.tabs, reports.sections, reports.errors, etc.)"

requirements-completed: [REPORT-01]

# Metrics
duration: 7min
completed: 2026-04-12
---

# Phase 19 Plan 13: i18n, Themes, Shortcuts, Bookmarks & Bulk Ops Summary

**next-intl i18n foundation with English message catalog, 5 switchable report themes with CSS variable overrides, keyboard shortcuts with vim-mode, bookmark/favorites with drag-and-drop dashboard, and bulk operations toolbar**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-12T08:55:04Z
- **Completed:** 2026-04-12T09:01:43Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Created comprehensive i18n English message catalog covering all report labels, sections, errors, health indicators, schedule messages, bulk operations, and ICU format strings (D-86/87)
- Built report theme system with 5 themes (Professional, Construction, Corporate, Minimal, Executive) applied via CSS custom properties with preview-on-hover, enterprise white-labeling support, and CSS sanitization (D-107/109, T-19-35)
- Implemented keyboard shortcuts for print/export/share/refresh/help with optional vim-mode navigation (D-108)
- Created bookmark/favorites system with star toggle, localStorage persistence, and drag-and-drop dashboard layout (D-111)
- Built bulk operations toolbar with delete/export/revoke/pause/resume actions, confirmation dialogs for destructive ops, and 50-item limit (D-110, T-19-34)

## Task Commits

Each task was committed atomically:

1. **Task 1: i18n setup with next-intl + report themes + keyboard shortcuts** - `7c98b46` (feat)
2. **Task 2: Bookmarks/favorites + bulk operations bar** - `19ee1a1` (feat)

## Files Created/Modified
- `web/src/lib/reports/i18n-messages/en.json` - English translations for all report UI strings with ICU message format
- `web/src/i18n.ts` - next-intl configuration with getRequestConfig, English default locale
- `web/src/middleware.ts` - Added i18n comment for future locale expansion
- `web/src/lib/reports/report-themes.ts` - 5 report themes with CSS variable system, sanitization, white-label support
- `web/src/app/reports/components/ReportThemeSwitcher.tsx` - Theme dropdown with preview, localStorage persistence, branding
- `web/src/app/reports/components/KeyboardShortcuts.tsx` - Keyboard handler with help panel and vim-mode
- `web/src/app/reports/components/BookmarkButton.tsx` - Star toggle + BookmarkDashboard with drag-and-drop grid
- `web/src/app/reports/components/BulkOperationsBar.tsx` - Fixed bottom toolbar with action buttons and confirmation dialog

## Decisions Made
- i18n uses next-intl getRequestConfig with English-only to start per RESEARCH.md pitfall 8 -- extensible to additional locales without route rewriting
- Report themes apply CSS custom properties to container element (not global) for isolation
- Custom CSS themes sanitized against expression(), javascript:, @import, and script injection patterns (T-19-35)
- Keyboard shortcuts exclude input/textarea/select elements to prevent browser conflicts
- Bookmarks stored in localStorage with 50-item cap to prevent unbounded growth
- Bulk operations limited to 50 items per request with mandatory confirmation for destructive actions (T-19-34)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- i18n message catalog ready for use with next-intl useTranslations hook in any report component
- Theme system ready for integration into report layout and PDF export
- Keyboard shortcuts ready to wire into report page actions
- Bookmark and bulk operations components ready for integration into report list views

## Self-Check: PASSED

- All 8 files verified on disk
- Commit 7c98b46 verified in git log (Task 1)
- Commit 19ee1a1 verified in git log (Task 2)

---
*Phase: 19-reporting-dashboards*
*Completed: 2026-04-12*
