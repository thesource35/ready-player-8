---
phase: 19-reporting-dashboards
plan: 08
subsystem: scheduling
tags: [schedule-crud, vercel-cron, email-delivery, resend, react-email, bulk-ops]

# Dependency graph
requires: [19-04]
provides:
  - Schedule CRUD API at /api/reports/schedule (GET/POST/PUT/DELETE)
  - Vercel Cron handler at /api/reports/cron with CRON_SECRET auth
  - Branded email template via @react-email/components
  - Schedule management page at /reports/schedules
affects: [19-09, 19-10]

# Tech tracking
tech-stack:
  added: ["@react-email/components"]
  patterns: [vercel-cron-bearer-auth, resend-email-delivery, service-role-supabase-client]

key-files:
  created:
    - web/src/app/api/reports/schedule/route.ts
    - web/src/app/api/reports/cron/route.ts
    - web/src/lib/reports/email-template.tsx
    - web/vercel.json
    - web/src/app/reports/schedules/page.tsx
    - web/src/app/reports/components/ScheduleManagement.tsx
  modified: []

key-decisions:
  - "Service-role Supabase client for cron handler (bypasses RLS for system-level schedule processing)"
  - "renderReportEmail is async (react-email render returns Promise in v1.x)"
  - "Recipients validated against user_orgs and cs_team_members tables with fallback to creator-only"

patterns-established:
  - "Vercel Cron pattern: bearer token auth -> query due items -> process each -> advance next_run"
  - "Schedule CRUD: Zod validation + recipient team-member check + next_run_at computation"
  - "Bulk operations: select-all checkbox + per-item checkboxes + bulk action buttons"

requirements-completed: [REPORT-01, REPORT-02]

# Metrics
duration: 10min
completed: 2026-04-12
---

# Phase 19 Plan 08: Scheduled Email Delivery Summary

**Schedule CRUD API with Zod validation and team-member recipient checks, Vercel Cron handler with bearer token auth and delivery logging, branded React Email template with health badge and inline metrics, and schedule management UI with bulk operations and 14-day mini-calendar**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-12T05:31:06Z
- **Completed:** 2026-04-12T05:41:28Z
- **Tasks:** 2
- **Files created:** 6

## Accomplishments

- Built schedule CRUD API (GET/POST/PUT/DELETE) with Zod input validation, frequency-based next_run_at computation, and recipient validation against user_orgs/cs_team_members (D-50e)
- POST supports send_now and send_test actions that trigger immediate email delivery via Resend (D-50g, D-50o)
- Built Vercel Cron handler that verifies CRON_SECRET bearer token (T-19-19), queries due schedules, processes each with portfolio data aggregation, sends via Resend, logs to cs_report_delivery_log (D-50h), and advances next_run_at
- Cron handler auto-pauses schedules when user has no active projects (D-50f) and emits notifications for delivery success/failure (D-50d)
- Built branded React Email template with ConstructionOS header, health score badge with color coding, 4 inline metric cards (projects, budget, issues, health), CTA button to live report, and footer (D-50c)
- Created vercel.json with */15 cron schedule for /api/reports/cron (D-50i)
- Built ScheduleManagement component with card-based schedule list, create schedule modal (frequency/day/time/timezone/recipients), Pause/Resume/Send Now/Send Test/Delete actions per card
- Added bulk operations: select-all, bulk pause/resume/delete (D-110)
- Added 14-day mini-calendar showing upcoming deliveries (D-118) and sortable schedule list

## Task Commits

Each task was committed atomically:

1. **Task 1: Schedule CRUD API + Cron handler + email template** - `5d7de2a` (feat)
2. **Task 2: Schedule management UI page** - `a639697` (feat)

## Files Created

- `web/src/app/api/reports/schedule/route.ts` - Schedule CRUD with GET/POST/PUT/DELETE, Zod validation, send_now/send_test, recipient team-member validation
- `web/src/app/api/reports/cron/route.ts` - Vercel Cron handler with bearer auth, due schedule processing, Resend email delivery, delivery logging, auto-pause
- `web/src/lib/reports/email-template.tsx` - React Email branded template with health badge, inline metrics, CTA link
- `web/vercel.json` - Cron configuration for /api/reports/cron at */15 frequency
- `web/src/app/reports/schedules/page.tsx` - Schedule management page with loading/error states
- `web/src/app/reports/components/ScheduleManagement.tsx` - Schedule cards, create modal, bulk ops, mini-calendar, sort controls

## Decisions Made

- Service-role Supabase client used for cron handler since it runs as system (not a user) and needs to bypass RLS to read all users' schedules
- renderReportEmail is async because @react-email/components render() returns a Promise in the installed version
- Recipients validated against both user_orgs (org membership) and cs_team_members (Phase 15 crew data) with graceful fallback if tables don't exist

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None - all security surfaces covered by plan's threat model (T-19-19 through T-19-22).

## Issues Encountered

None.

## User Setup Required

- **CRON_SECRET** environment variable must be set in Vercel for cron endpoint authentication
- **RESEND_API_KEY** environment variable must be set for email delivery (graceful degradation if missing)

## Next Phase Readiness

- Schedule API ready for consumption by other plans
- Cron handler processes due schedules automatically every 15 minutes
- Email template reusable for other notification types
- Schedule management UI integrated into Reports tab via existing layout

## Self-Check: PASSED

---
*Phase: 19-reporting-dashboards*
*Completed: 2026-04-12*
