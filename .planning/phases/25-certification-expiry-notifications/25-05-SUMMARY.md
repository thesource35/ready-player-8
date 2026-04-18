---
phase: 25-certification-expiry-notifications
plan: 05
subsystem: ios
tags: [push-notifications, deep-link, carplay, apns, analytics, swiftui]

requires:
  - phase: 25-01
    provides: "Supabase Edge Function sends cert-expiry push with cert_id in payload"
  - phase: 25-02
    provides: "cert-expiry APNs category registered with VIEW_CERT action"
  - phase: 25-03
    provides: "CertUrgency enum and urgency calculation in CertificationsView"
provides:
  - "UNUserNotificationCenterDelegate routing cert push taps to CertificationsView"
  - "Cold-launch deep-link via PendingCertDeepLink AppStorage relay"
  - "Warm-launch deep-link via NavToCert NotificationCenter publisher"
  - "Live certBadgeCount wired into NavigationRailView and NavigationTabsView"
  - "CarPlay Certifications tab with expiring/expired count summary"
  - "cert_alert_opened analytics event on notification tap"
affects: [25-06, 25-07, 28-verification-sweep]

tech-stack:
  added: []
  patterns: [UNUserNotificationCenterDelegate async delegate, AppStorage relay for cold-launch deep-link, NavToCert NotificationCenter publisher]

key-files:
  created: []
  modified:
    - "ready player 8/ready_player_8App.swift"
    - "ready player 8/ContentView.swift"

key-decisions:
  - "Used UserDefaults write-then-clear relay pattern (PendingCertDeepLink) for cold-launch deep-link, matching Phase 23 cross-nav pattern"
  - "HighlightCertId stored for CertificationsView to consume for scroll-to highlighting"

patterns-established:
  - "Cert deep-link relay: AppDelegate writes PendingCertDeepLink + posts NavToCert; ContentView consumes both paths"
  - "CarPlay cert status reads CertBadgeCount from UserDefaults for at-a-glance summary"

requirements-completed: [TEAM-04]

duration: 36min
completed: 2026-04-18
---

# Phase 25 Plan 05: iOS Push Deep-Link and CarPlay Cert Tab Summary

**Push notification deep-link routing to CertificationsView via AppDelegate + live certBadgeCount in NavigationRail/Tabs + CarPlay cert status tab**

## Performance

- **Duration:** 36 min
- **Started:** 2026-04-18T08:31:37Z
- **Completed:** 2026-04-18T09:07:27Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- AppDelegate now conforms to UNUserNotificationCenterDelegate, routing cert push taps to CertificationsView via both cold-launch (UserDefaults relay) and warm-launch (NotificationCenter publisher) paths
- NavigationRailView and NavigationTabsView display live certBadgeCount from @AppStorage instead of hardcoded 0
- CarPlay root template includes a Certifications tab showing expiring/expired cert count summary
- cert_alert_opened analytics event fires when user taps a cert push notification

## Task Commits

Each task was committed atomically:

1. **Task 1: Add UNUserNotificationCenterDelegate for deep-link routing** - `95888d4` (feat)
2. **Task 2: Wire deep-link receiver and certBadgeCount in ContentView** - `cbf9626` (feat)

## Files Created/Modified
- `ready player 8/ready_player_8App.swift` - AppDelegate gains UNUserNotificationCenterDelegate with didReceive/willPresent, CarPlay gets cert tab with certStatusSummary/certStatusDetail helpers
- `ready player 8/ContentView.swift` - NavToCert onReceive handler, cold-launch PendingCertDeepLink check in onAppear, @AppStorage certBadgeCount replaces hardcoded 0

## Decisions Made
- Used UserDefaults write-then-clear relay pattern (PendingCertDeepLink) for cold-launch deep-link, consistent with Phase 23 cross-nav pattern
- HighlightCertId stored as separate UserDefaults key for CertificationsView to consume independently
- cert_renewed_after_alert analytics deferred to CertificationsView (Plan 03 scope) per plan guidance

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Deep-link routing complete; Plan 06 (web cert dashboard) and Plan 07 (testing) can proceed
- CertificationsView needs to consume HighlightCertId for scroll-to-cert highlighting (may be Plan 03 or future plan scope)
- cert_renewed_after_alert analytics should be wired in CertificationsView EditCertSheet.save()

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
