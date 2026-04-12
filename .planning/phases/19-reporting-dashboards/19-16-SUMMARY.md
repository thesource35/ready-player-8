---
phase: 19-reporting-dashboards
plan: 16
subsystem: infra
tags: [caching, swr, feature-flags, data-retention, pwa, service-worker, offline, export, rate-limiting]

# Dependency graph
requires:
  - phase: 19-reporting-dashboards
    provides: Report pages, components, and API routes (plan 05)
provides:
  - Multi-layer caching with client dedup, server in-memory, and edge cache headers
  - Report-specific rate limiting (general 60/min, PDF 10/min, batch 3/min)
  - Feature flag gradual rollout with deterministic userId hashing
  - Configurable data retention policy with cleanup and expiry warnings
  - Full data export/backup request function
  - Service Worker for offline report viewing (cache-first, network-first, stale-while-revalidate)
  - Offline banner component with auto-dismiss
  - Data export backup UI component with progress indicator
affects: [19-17, 19-18]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Multi-layer caching: client dedup (5s) -> server Map (1min TTL) -> edge Cache-Control headers (s-maxage=60)"
    - "Service Worker cache strategies: cache-first for static, network-first for API, stale-while-revalidate for images"
    - "Deterministic feature flag rollout via userId hash bucketing against REPORT_ROLLOUT_PERCENT env var"

key-files:
  created:
    - web/src/lib/reports/caching.ts
    - web/src/lib/reports/feature-flags.ts
    - web/src/lib/reports/data-retention.ts
    - web/src/lib/reports/pwa-sw.ts
    - web/public/sw-reports.js
    - web/src/app/reports/components/OfflineBanner.tsx
    - web/src/app/reports/components/DataExportBackup.tsx
  modified: []

key-decisions:
  - "SWR-compatible config object instead of SWR library dependency (no new package needed)"
  - "Feature flags default to 100% rollout via REPORT_ROLLOUT_PERCENT env var"
  - "Service Worker scoped to /reports path only"

patterns-established:
  - "Report caching: REPORT_SWR_CONFIG for client, serverCache for server, edgeCacheHeaders for edge"
  - "Offline detection: OfflineBanner listens online/offline events with auto-dismiss toast"

requirements-completed: [REPORT-01]

# Metrics
duration: 5min
completed: 2026-04-12
---

# Phase 19 Plan 16: Caching, Feature Flags, Offline & Backup Summary

**Multi-layer caching with rate limiting, percentage-based feature flag rollout, Service Worker offline viewing, and full data export backup**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-12T09:42:13Z
- **Completed:** 2026-04-12T09:47:10Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Built 3-layer caching infrastructure: client dedup (5s), server in-memory (1min TTL), edge Cache-Control headers with stale-while-revalidate (D-59)
- Implemented report-specific rate limiting with Upstash Redis + in-memory fallback: 60/min general, 10/min PDF, 3/min batch export (D-62b)
- Created deterministic feature flag rollout using userId hash bucketing with REPORT_ROLLOUT_PERCENT env var (D-95)
- Built configurable data retention policy (6mo/1yr/2yr/unlimited) with cleanup and expiry warning functions (D-96)
- Created Service Worker with cache-first/network-first/stale-while-revalidate strategies for offline report viewing (D-113)
- Built OfflineBanner component with var(--gold) background and "Back online" auto-dismiss toast (D-113)
- Built DataExportBackup component with progress indicator and ZIP download for full data export (D-97)

## Task Commits

Each task was committed atomically:

1. **Task 1: Multi-layer caching + feature flags + data retention** - `7ed1f4f` (feat)
2. **Task 2: PWA offline + Service Worker + data backup export** - `44888ee` (feat)

## Files Created/Modified
- `web/src/lib/reports/caching.ts` - SWR config, server cache, edge headers, cache invalidation, rate limiting
- `web/src/lib/reports/feature-flags.ts` - Percentage-based rollout with beta opt-in and env var control
- `web/src/lib/reports/data-retention.ts` - Retention policy, cleanup, expiry warnings, full export request
- `web/src/lib/reports/pwa-sw.ts` - SW registration, manual cache ops, connectivity detection
- `web/public/sw-reports.js` - Service Worker with 3 cache strategies and message handling
- `web/src/app/reports/components/OfflineBanner.tsx` - Sticky offline/online status banner
- `web/src/app/reports/components/DataExportBackup.tsx` - Export UI with progress bar and download

## Decisions Made
- Used SWR-compatible config object rather than adding SWR as a dependency (avoids new package, components use native fetch with dedup wrapper)
- Feature flags default to 100% rollout so reporting is available to all users unless explicitly gated
- Service Worker scoped to /reports path only to avoid interfering with other app functionality

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed strict null check on SW controller**
- **Found during:** Task 2 (TypeScript verification)
- **Issue:** `navigator.serviceWorker.controller` is possibly null in `clearReportCache()`
- **Fix:** Added null guard with early return before postMessage call
- **Files modified:** web/src/lib/reports/pwa-sw.ts
- **Verification:** `npx tsc --noEmit` passes with zero errors in report files
- **Committed in:** 44888ee (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor strict null safety fix. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviation.

## User Setup Required
None - no external service configuration required. Feature flags default to 100% rollout. Service Worker registers automatically on report pages.

## Next Phase Readiness
- Caching layer ready for use by all report API routes and pages
- Feature flags ready for gradual rollout control via REPORT_ROLLOUT_PERCENT env var
- Service Worker ready to be registered from report page layout
- OfflineBanner and DataExportBackup components ready for integration into report views
- Data retention cleanup functions ready for cron job integration

## Self-Check: PASSED

- All 7 files verified on disk
- Commit 7ed1f4f verified in git log (Task 1)
- Commit 44888ee verified in git log (Task 2)
- Zero TypeScript errors in report files (full tsc --noEmit clean)

---
*Phase: 19-reporting-dashboards*
*Completed: 2026-04-12*
