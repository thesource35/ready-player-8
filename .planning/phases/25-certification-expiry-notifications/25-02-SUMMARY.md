---
phase: 25-certification-expiry-notifications
plan: 02
subsystem: notifications
tags: [apns, push-notifications, edge-functions, supabase, swift, certifications]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: "Fanout pipeline (notifications-fanout Edge Function), APNs infrastructure, PUSH_CATEGORIES gating"
  - phase: 25-01
    provides: "Cert-expiry-scan Edge Function producing activity events with recipient_user_ids and suppress_user_ids"
provides:
  - "Cert-specific push copy (threshold-based titles, member+cert body)"
  - "suppress_user_ids filtering in fanout"
  - "cert-expiry APNs category with VIEW_CERT action"
  - "iOS cert-expiry notification category registration"
affects: [25-03, 25-04, 25-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Cert events bypass project_id member lookup via payload.recipient_user_ids"
    - "suppress_user_ids Set filtering for per-user dismiss suppression"
    - "UNNotificationCategory merge pattern to preserve existing categories"

key-files:
  created: []
  modified:
    - supabase/functions/notifications-fanout/index.ts
    - ready player 8/ready_player_8App.swift

key-decisions:
  - "Cert recipient resolution uses payload.recipient_user_ids directly, bypassing cs_project_members lookup"
  - "suppress_user_ids applied as post-resolution filter via Set for O(1) lookups"
  - "APNs category set in aps object (not top-level) per Apple spec"
  - "Notification categories registered in App init() with merge to preserve existing registrations"

patterns-established:
  - "Entity-type branching in titleFor/bodyFor for domain-specific notification copy"
  - "Payload-carried recipient lists for events that resolve recipients upstream"

requirements-completed: [TEAM-04, NOTIF-04]

# Metrics
duration: 4min
completed: 2026-04-18
---

# Phase 25 Plan 02: Cert Push Copy & iOS Category Registration Summary

**Cert-specific fanout with threshold titles, member+cert body, suppress_user_ids filtering, cert-expiry APNs category, and iOS VIEW_CERT lock screen action**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-18T05:58:01Z
- **Completed:** 2026-04-18T06:02:07Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Fanout generates threshold-specific push titles ("Cert Expiring in 7 Days", "Cert Expires Today", "Cert Has Expired")
- Push body shows "John Doe: OSHA 30 + Forklift" format with member name and cert names
- Dismissed users filtered from recipients via suppress_user_ids Set
- APNs payload includes cert-expiry category and cert_id for deep-link routing
- iOS registers cert-expiry notification category on launch with "View Cert" action button
- Non-cert notification flow completely unchanged

## Task Commits

Each task was committed atomically:

1. **Task 1: Enhance fanout for cert-specific copy and suppress_user_ids** - `59502ca` (feat)
2. **Task 2: Register cert-expiry APNs notification category on iOS** - `a8e811a` (feat)

## Files Created/Modified
- `supabase/functions/notifications-fanout/index.ts` - Cert-specific titleFor/bodyFor, recipient_user_ids resolution, suppress_user_ids filtering, APNs cert-expiry category + cert_id + subtitle
- `ready player 8/ready_player_8App.swift` - UNNotificationCategory registration for cert-expiry with VIEW_CERT action, called from App init()

## Decisions Made
- Cert recipient resolution uses payload.recipient_user_ids directly — bypasses cs_project_members lookup since cert-expiry-scan already resolved PMs + member user_id upstream
- suppress_user_ids applied via Set for O(1) membership checks after recipient resolution
- APNs category placed inside aps object per Apple specification
- Notification categories registered in App init() using merge pattern (getNotificationCategories then insert + set) to avoid overwriting any future category registrations
- Project name subtitle resolved via single cs_projects query only when project_id is present

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Fanout now produces cert-specific pushes — ready for Plan 03 (iOS urgency badges + deep-link UI)
- cert-expiry APNs category registered — Plan 05 (deep-link routing) can add UNUserNotificationCenterDelegate to handle VIEW_CERT action taps
- Non-cert flows unchanged — no regression risk

## Self-Check: PASSED

- All 2 modified files exist on disk
- Commit 59502ca found in git log
- Commit a8e811a found in git log
- SUMMARY.md created at expected path

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
