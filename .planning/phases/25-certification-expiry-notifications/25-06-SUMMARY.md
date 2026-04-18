---
phase: 25-certification-expiry-notifications
plan: 06
subsystem: api, ui, database
tags: [mcp, swift, react, supabase, certifications, compliance, reporting]

# Dependency graph
requires:
  - phase: 25-certification-expiry-notifications
    provides: "cert urgency utilities, cs_certifications table, team API routes, iOS cert views, web cert pages"
provides:
  - "get_expiring_certs MCP tool for AI cert queries"
  - "CertComplianceWidget on reports dashboard"
  - "cert renewal trigger migration on remote DB"
affects: [25-07-verification, reporting-dashboards]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MCP tool with date-range filtering and member name resolution"
    - "Client-side cert compliance widget using certUrgency shared utility"

key-files:
  created:
    - web/src/app/reports/components/CertComplianceWidget.tsx
    - supabase/migrations/20260418001_phase25_cert_renewal_trigger.sql
  modified:
    - ready player 8/MCPServer.swift
    - web/src/app/reports/page.tsx

key-decisions:
  - "CertComplianceWidget as client component using /api/team/certifications fetch (reports page is use-client)"
  - "MCP tool filters by expires_at <= targetDate OR status == expired for comprehensive results"

patterns-established:
  - "MCP tool date-range pattern: compute target date string, filter in-memory after bulk fetch"
  - "Compliance widget pattern: aggregate urgency counts from shared certUrgency utility"

requirements-completed: [TEAM-04, NOTIF-04]

# Metrics
duration: 15min
completed: 2026-04-18
---

# Phase 25 Plan 06: MCP Tool + Cert Compliance Widget + DB Migration Summary

**get_expiring_certs MCP tool for Angelic AI cert queries, CertComplianceWidget on reports dashboard, and cert renewal trigger migration deployed to remote Supabase**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-18T13:30:00Z
- **Completed:** 2026-04-18T13:45:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 4

## Accomplishments
- Angelic AI can now answer "which certs expire this month?" via get_expiring_certs MCP tool with member name resolution
- Reports dashboard shows cert compliance widget with Valid/Expiring Soon/Urgent+Expired counts and renewal rate
- Database migration for cert renewal trigger and cleanup trigger deployed to remote Supabase instance
- Human verification approved all UI surfaces (urgency badges, deep-link, renewal CTA, CarPlay tab, widget, MCP tool)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add get_expiring_certs MCP tool and cert compliance widget** - `b54c344` (feat)
2. **Task 2: Push database migration to remote** - remote DB operation (no git commit)
3. **Task 3: Checkpoint: Human verification** - approved by user

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified
- `ready player 8/MCPServer.swift` - Added get_expiring_certs tool definition, execution with date filtering and member lookup, daysUntil helper
- `web/src/app/reports/components/CertComplianceWidget.tsx` - New client component showing cert compliance counts (safe/warning/urgent/expired) with renewal rate
- `web/src/app/reports/page.tsx` - Added CertComplianceWidget import and render in reports dashboard
- `supabase/migrations/20260418001_phase25_cert_renewal_trigger.sql` - emit_cert_renewal_event and cleanup_cert_notifications triggers pushed to remote

## Decisions Made
- CertComplianceWidget built as client component with useEffect fetch since reports page uses "use client" directive
- MCP tool filters certs by expires_at <= targetDate OR status == "expired" to catch both upcoming and already-expired
- Migration history repair was needed before push (orphaned remote versions reconciled)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration history repair before push**
- **Found during:** Task 2 (Push database migration)
- **Issue:** Orphaned remote migration versions prevented clean supabase db push
- **Fix:** Reconciled migration history before pushing the Phase 25 migration
- **Files modified:** Remote Supabase migration history only
- **Verification:** supabase db push completed successfully
- **Committed in:** N/A (remote DB operation)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Migration history fix was necessary to deploy the trigger. No scope creep.

## Issues Encountered
None beyond the migration history repair documented above.

## User Setup Required
None - database migration already pushed to remote. No additional configuration needed.

## Next Phase Readiness
- Phase 25 is now feature-complete pending final 25-07 verification plan
- All cert notification infrastructure deployed: edge function, fanout, iOS UI, web UI, MCP tool, compliance widget, DB triggers
- INT-06 (cert expiration does not trigger notifications) can be closed after 25-07 verification

## Self-Check: PASSED

- FOUND: ready player 8/MCPServer.swift
- FOUND: web/src/app/reports/components/CertComplianceWidget.tsx
- FOUND: web/src/app/reports/page.tsx
- FOUND: commit b54c344

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
