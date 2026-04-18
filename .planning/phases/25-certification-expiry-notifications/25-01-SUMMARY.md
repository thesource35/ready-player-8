---
phase: 25-certification-expiry-notifications
plan: 01
subsystem: api
tags: [supabase, edge-function, deno, notifications, certifications, triggers, postgres]

requires:
  - phase: 14-notifications-activity-feed
    provides: notification pipeline (cs_activity_events -> fanout -> APNs)
  - phase: 15-team-crew-management
    provides: cs_certifications table, pg_cron cert-expiry-scan schedule
  - phase: 24-document-activity-event-emission
    provides: AFTER UPDATE trigger function pattern for activity events
provides:
  - Multi-threshold cert expiry scanning (30d/7d/day-of/weekly post-expiry)
  - Payload-marker dedupe for cert notification deduplication
  - Member grouping for consolidated cert alerts
  - Cert renewal AFTER UPDATE trigger emitting activity events
  - Cert deletion cleanup trigger for orphaned notifications
  - 14 Deno tests covering all thresholds and edge cases
affects: [25-02, 25-03, 25-04, 25-05, 25-06, 25-07, notifications-fanout]

tech-stack:
  added: []
  patterns: [payload-marker-dedupe, batch-recipient-resolution, suppress-user-ids, first-deploy-guard, rate-cap-with-urgency-priority]

key-files:
  created:
    - supabase/migrations/20260418001_phase25_cert_renewal_trigger.sql
  modified:
    - supabase/functions/cert-expiry-scan/index.ts
    - supabase/functions/cert-expiry-scan/index.test.ts

key-decisions:
  - "Payload-marker dedupe uses cert_id + threshold + expires_at in cs_activity_events.payload -- no new side table"
  - "Dismiss-suppress implemented via suppress_user_ids array in activity event payload for fanout to consume"
  - "Batch recipient resolution collects all member_ids first then does bulk queries to avoid N+1"
  - "First-deploy guard checks for ANY existing cert activity events to prevent notification flood"

patterns-established:
  - "Payload-marker dedupe: query cs_activity_events with payload->> JSON path filters for idempotent event creation"
  - "Suppress user IDs: include suppress_user_ids array in activity event payload so fanout can skip dismissed users"
  - "Batch recipient resolution: collect member_ids -> bulk query assignments + PMs + projects -> group in-memory"
  - "Rate cap with urgency priority: sort by threshold urgency before insertion, stop at cap"

requirements-completed: [TEAM-04, NOTIF-04]

duration: 6min
completed: 2026-04-18
---

# Phase 25 Plan 01: Cert Expiry Scan Backend Summary

**Multi-threshold cert expiry scanning Edge Function with batch processing, payload-marker dedupe, member grouping, dismiss-suppress, and SQL triggers for renewal/cleanup events**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-18T05:47:26Z
- **Completed:** 2026-04-18T05:53:54Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Rewrote cert-expiry-scan Edge Function from single 30-day check to full 4-threshold escalating cadence (30d/7d/day-of/weekly post-expiry)
- Added batch processing (100/page, 50s timeout), payload-marker dedupe, member grouping, dismiss-suppress, first-deploy guard, and rate cap (200/run)
- Created SQL migration with cert renewal trigger (emit_cert_renewal_event) and cert deletion cleanup trigger (cleanup_cert_notifications)
- Expanded test suite from 4 to 14 Deno tests covering all thresholds, dedupe, grouping, dismiss-suppress, first-deploy guard, rate cap, recipient resolution, and delivery channels

## Task Commits

Each task was committed atomically:

1. **Task 1: Create cert renewal AFTER UPDATE trigger migration** - `246b1fb` (feat)
2. **Task 2: Rewrite cert-expiry-scan Edge Function for full escalating cadence** - `9284312` (feat)
3. **Task 3: Expand cert-expiry-scan tests for all thresholds and behaviors** - `71b34a2` (test)

## Files Created/Modified
- `supabase/migrations/20260418001_phase25_cert_renewal_trigger.sql` - Cert renewal event trigger + cert deletion cleanup trigger
- `supabase/functions/cert-expiry-scan/index.ts` - Full multi-threshold scan with batch processing, dedupe, grouping, dismiss-suppress, rate cap
- `supabase/functions/cert-expiry-scan/index.test.ts` - 14 Deno tests covering all behaviors

## Decisions Made
- Payload-marker dedupe uses cert_id + threshold + expires_at in cs_activity_events.payload (no new side table per D-02)
- Dismiss-suppress implemented via suppress_user_ids array in activity event payload for fanout to consume (keeps Edge Function concern to "create events")
- Batch recipient resolution collects all member_ids first, then does bulk queries for assignments, PMs, team members, and projects to avoid N+1
- First-deploy guard checks for ANY existing cert activity events to prevent notification flood on initial deployment
- UTC date comparison for timezone simplicity (D-26) with comment noting intent

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Edge Function ready for downstream plans: fanout enhancement (25-02), iOS UI (25-03), web UI (25-04)
- Activity events include delivery_channels and suppress_user_ids for fanout to consume
- Cert renewal trigger active and will emit events when certs are renewed
- All 14 tests pass with stub-based approach

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
