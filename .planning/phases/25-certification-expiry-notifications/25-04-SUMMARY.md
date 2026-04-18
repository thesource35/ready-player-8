---
phase: 25-certification-expiry-notifications
plan: 04
subsystem: ui
tags: [certifications, urgency, vitest, deep-link, css-animation, next.js]

requires:
  - phase: 25-certification-expiry-notifications
    provides: "cs_certifications table, cert expiry trigger (plans 01-02)"
provides:
  - "Shared urgency utility at @/lib/certifications/urgency (getUrgencyInfo, certUrgency, urgencyColor, urgencyLabel)"
  - "Enhanced cert page with urgency badges, summary banner, deep-link highlight, Update Cert CTA"
  - "Vitest test suite for urgency thresholds and deep-link security"
affects: [25-06-cert-compliance-widget, 25-07-verification]

tech-stack:
  added: []
  patterns: ["Shared urgency calculation utility for cert expiry color/label/level", "CSS keyframe pulse animation for urgent/expired badges", "UUID-validated deep-link query param with scroll-on-mount"]

key-files:
  created:
    - web/src/lib/certifications/urgency.ts
    - web/src/app/team/certifications/CertHighlightScroller.tsx
    - web/src/__tests__/cert-urgency.test.ts
  modified:
    - web/src/app/team/certifications/page.tsx

key-decisions:
  - "Extracted CertHighlightScroller to separate file for proper 'use client' directive in Next.js server component page"
  - "Used noon UTC (T12:00:00Z) for vitest fake timers to avoid timezone boundary failures across CI environments"

patterns-established:
  - "Shared urgency utility pattern: single source of truth for cert expiry calculation reused across page and widget"
  - "Deep-link highlight pattern: UUID-validated query param + scrollMarginTop + client scroller component"

requirements-completed: [TEAM-04, NOTIF-04]

duration: 69min
completed: 2026-04-18
---

# Phase 25 Plan 04: Web Cert Urgency UI Summary

**Shared cert urgency utility with color-coded badges, pulse animation, summary banner, deep-link highlight, and 12 vitest tests**

## Performance

- **Duration:** 69 min
- **Started:** 2026-04-18T07:05:04Z
- **Completed:** 2026-04-18T08:13:59Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Extracted shared urgency calculation utility at `@/lib/certifications/urgency` with 4 exported functions for reuse by Plan 06
- Enhanced cert page with urgency badges (green/amber/red), pulse animation on urgent/expired, summary banner, deep-link highlight, and Update Cert CTA
- 12 vitest tests covering all urgency thresholds, convenience aliases, and deep-link URL injection security

## Task Commits

Each task was committed atomically:

1. **Task 1: Create shared urgency utility and enhance cert page** - `83eca5f` (feat)
2. **Task 2: Add vitest unit tests for urgency and deep-link security** - `98928cc` (test)

## Files Created/Modified
- `web/src/lib/certifications/urgency.ts` - Shared urgency calculation: getUrgencyInfo, certUrgency, urgencyColor, urgencyLabel
- `web/src/app/team/certifications/page.tsx` - Enhanced with urgency badges, summary banner, deep-link highlight, Update Cert CTA
- `web/src/app/team/certifications/CertHighlightScroller.tsx` - Client component for scroll-to-highlighted-cert on mount
- `web/src/__tests__/cert-urgency.test.ts` - 12 vitest tests for urgency thresholds and deep-link security

## Decisions Made
- Extracted CertHighlightScroller to separate file because Next.js server component pages cannot contain inline "use client" components
- Used noon UTC for vitest fake timers to avoid timezone boundary failures where midnight UTC maps to previous day in western timezones

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed timezone-sensitive vitest fake timer setup**
- **Found during:** Task 2 (vitest tests)
- **Issue:** Plan specified `new Date("2026-06-01T00:00:00Z")` for fake timers, but midnight UTC causes `new Date().setHours(0,0,0,0)` to resolve to May 31st in western timezones, failing "Expires today" assertions
- **Fix:** Changed to `new Date("2026-06-01T12:00:00Z")` (noon UTC) so local date is June 1st in all practical timezones
- **Files modified:** web/src/__tests__/cert-urgency.test.ts
- **Verification:** All 12 tests pass
- **Committed in:** 98928cc (Task 2 commit)

**2. [Rule 3 - Blocking] Extracted CertHighlightScroller to separate client component file**
- **Found during:** Task 1 (cert page enhancement)
- **Issue:** Plan specified inline client component with "use client" at bottom of server component file, which is not valid in Next.js App Router
- **Fix:** Created `CertHighlightScroller.tsx` as separate file with "use client" directive, imported into page
- **Files modified:** web/src/app/team/certifications/CertHighlightScroller.tsx, web/src/app/team/certifications/page.tsx
- **Verification:** Page imports and renders client component correctly
- **Committed in:** 83eca5f (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes necessary for correctness. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Shared urgency utility ready for Plan 06 CertComplianceWidget import (`certUrgency` alias)
- Cert page deep-link URL pattern (`/team/certifications?highlight={certId}`) available for notification links
- All must_haves from plan frontmatter satisfied

## Self-Check: PASSED

All 4 created files verified on disk. Both task commits (83eca5f, 98928cc) verified in git log.

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
