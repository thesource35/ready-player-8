---
phase: 25-certification-expiry-notifications
plan: 03
subsystem: ui
tags: [swiftui, xctest, urgency, accessibility, voiceover, animation]

requires:
  - phase: 25-certification-expiry-notifications
    provides: "cert-expiry-scan edge function and renewal triggers from plans 01-02"
provides:
  - "CertUrgency enum with safe/warning/urgent/expired tiers"
  - "Urgency badges with pulse animation on cert cards"
  - "Summary banner showing expiring/expired cert counts"
  - "EditCertSheet for one-tap cert renewal"
  - "parseCertDeepLink for notification deep-link routing"
  - "ConstructOS.CertBadgeCount UserDefaults relay for ContentView badge"
  - "11 XCTests for urgency calculation and deep-link parsing"
affects: [25-04, 25-05, 25-06, 25-07]

tech-stack:
  added: []
  patterns: ["Internal free functions for XCTest access (certUrgency, urgencyColor, parseCertDeepLink)", "Pulse animation via @State opacity + repeatForever"]

key-files:
  created:
    - "ready player 8Tests/CertUrgencyTests.swift"
  modified:
    - "ready player 8/CertificationsView.swift"
    - "ready player 8/SupabaseService.swift"

key-decisions:
  - "CertUrgency enum and helper functions as internal free functions (not private) to enable XCTest access without @testable workarounds"
  - "Added cs_certifications and cs_team_members to SupabaseService allowedTables (was missing, blocking update calls)"

patterns-established:
  - "Urgency tier pattern: safe (>30d), warning (7-30d), urgent (<=7d), expired (<=0d) with startOfDay normalization"
  - "UserDefaults relay pattern for cross-tab badge counts (ConstructOS.CertBadgeCount)"

requirements-completed: [TEAM-04]

duration: 24min
completed: 2026-04-18
---

# Phase 25 Plan 03: iOS Cert Urgency Badges Summary

**Urgency badges with pulse animation, summary banner, renewal CTA with edit sheet, VoiceOver labels, and 11 XCTests on iOS CertificationsView**

## Performance

- **Duration:** 24 min
- **Started:** 2026-04-18T06:22:59Z
- **Completed:** 2026-04-18T06:47:15Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- CertUrgency enum with 4 tiers (safe/warning/urgent/expired) and pulse behavior for expired certs
- Summary banner at top of cert list showing expiring/expired counts with warning icon
- EditCertSheet with DatePicker for one-tap cert renewal that flips status to active
- VoiceOver accessibility labels for all urgency tiers
- 11 XCTests covering urgency calculation boundaries, pulse behavior, and deep-link parsing
- Wired urgentCertCount to ConstructOS.CertBadgeCount UserDefaults key for ContentView badge

## Task Commits

Each task was committed atomically:

1. **Task 1: Create XCTest for urgency color calculation and deep-link parsing** - `e1af125` (test)
2. **Task 2: Add urgency badges, summary banner, renewal CTA, and pulse to CertificationsView** - `ab18c90` (feat)

## Files Created/Modified
- `ready player 8Tests/CertUrgencyTests.swift` - 11 XCTests for urgency tiers, pulse, and deep-link parsing
- `ready player 8/CertificationsView.swift` - CertUrgency enum, urgency badges, summary banner, EditCertSheet, renewal CTA, pulse animation, accessibility labels
- `ready player 8/SupabaseService.swift` - Added cs_certifications and cs_team_members to allowedTables

## Decisions Made
- CertUrgency enum and helper functions placed as internal free functions (not struct methods) so XCTest can call them via @testable import
- Added cs_certifications and cs_team_members to SupabaseService.allowedTables -- these were missing, which would have blocked the update() call in EditCertSheet

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added cs_certifications and cs_team_members to SupabaseService allowedTables**
- **Found during:** Task 2 (CertificationsView implementation)
- **Issue:** cs_certifications was not in SupabaseService.allowedTables, so update() calls from EditCertSheet would throw "Invalid table name" error. cs_team_members was also missing (used by existing load() via syncTable).
- **Fix:** Added both tables to the allowedTables set in SupabaseService.swift
- **Files modified:** ready player 8/SupabaseService.swift
- **Verification:** Confirmed table names present in allowedTables set
- **Committed in:** ab18c90 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential fix for cert update functionality. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Urgency model (CertUrgency enum) ready for web parity in plan 04
- parseCertDeepLink ready for notification tap routing in plan 05
- ConstructOS.CertBadgeCount relay wired for ContentView badge consumption
- EditCertSheet renewal flow triggers existing cert renewal trigger from plan 02

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
