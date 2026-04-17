---
phase: 23-ios-nav-assignment-wiring
plan: 03
subsystem: ui
tags: [swiftui, navigation, notificationcenter, nextjs, cross-nav, badge]

requires:
  - phase: 23-01
    provides: DailyCrewView zero-arg init with AppStorage-backed projectId

provides:
  - iOS cross-navigation from ProjectDetail and AgendaListView to DailyCrew tab
  - Badge overlay on CERTS tab (placeholder count=0, ready for Phase 25)
  - NavToTeam deep-link receiver in ContentView
  - Web /team in sidebar nav under INTEL group
  - Web AgendaView VIEW CREW cross-link per day row

affects: [25-cert-notifications, 28-verification-sweep]

tech-stack:
  added: []
  patterns:
    - "UserDefaults relay key pattern: write key, post notification, consumer reads and clears key"
    - "Badge overlay on nav tabs via .overlay(alignment: .topTrailing) with count parameter"

key-files:
  created: []
  modified:
    - ready player 8/ContentView.swift
    - ready player 8/LayoutChrome.swift
    - ready player 8/ProjectsView.swift
    - ready player 8/ScheduleTools.swift
    - ready player 8/DailyCrewView.swift
    - web/src/lib/nav.ts
    - web/src/app/layout.tsx
    - web/src/app/schedule/AgendaView.tsx
    - web/src/app/team/page.tsx
    - web/src/app/team/assignments/page.tsx
    - web/src/app/team/certifications/page.tsx

key-decisions:
  - "UserDefaults relay keys consumed-and-cleared on read to prevent stale state"
  - "certBadgeCount=0 placeholder wired now; Phase 25 replaces with real expiring-certs count"
  - "Web Daily Crew sub-nav link points to /team (project-scoped daily crew is at /projects/[id])"

patterns-established:
  - "Cross-tab navigation via NotificationCenter relay: write context to UserDefaults, post notification, receiver switches activeNav"
  - "Badge overlay parameter on NavigationTabsView/NavigationRailView for future badge sources"

requirements-completed: [TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03]

duration: 10min
completed: 2026-04-17
---

# Phase 23 Plan 03: Cross-Navigation + Badge + Web Nav Wiring Summary

**iOS cross-nav from ProjectDetail/AgendaListView to DailyCrew tab via NotificationCenter relay, CERTS badge overlay placeholder, and web /team sidebar nav with AgendaView crew links**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-17T16:54:58Z
- **Completed:** 2026-04-17T17:05:48Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- iOS ProjectDetailSheet "View Crew" button switches to DailyCrew tab with project pre-selected via UserDefaults relay
- iOS AgendaListView "Crew" button per day section switches to DailyCrew tab with date pre-set via relay
- CERTS tab badge overlay wired in both NavigationTabsView and NavigationRailView (count=0 placeholder for Phase 25)
- NavToTeam and NavToDailyCrew notification receivers added to ContentView
- Web /team added to INTEL sidebar group in both nav.ts and layout.tsx
- Web AgendaView day rows now include VIEW CREW cross-link
- All three team sub-pages (members, assignments, certifications) have Daily Crew sub-nav link

## Task Commits

Each task was committed atomically:

1. **Task 1: iOS cross-navigation + badge + deep-link (D-09/10/12/13/14)** - `8c41ee4` (feat)
2. **Task 2: Web nav wiring + AgendaView cross-link (D-09/13 web)** - `803f742` (feat)

## Files Created/Modified
- `ready player 8/ContentView.swift` - Added NavToDailyCrew and NavToTeam notification receivers
- `ready player 8/LayoutChrome.swift` - Added certBadgeCount parameter and badge overlay to both nav views
- `ready player 8/ProjectsView.swift` - Added "View Crew" button in ProjectDetailSheet
- `ready player 8/ScheduleTools.swift` - Added "Crew" button in AgendaListView day sections
- `ready player 8/DailyCrewView.swift` - Added date relay consumption in .task modifier
- `web/src/lib/nav.ts` - Added /team to INTEL group
- `web/src/app/layout.tsx` - Added /team to inline INTEL navGroups
- `web/src/app/schedule/AgendaView.tsx` - Added VIEW CREW link per day header
- `web/src/app/team/page.tsx` - Added Daily Crew sub-nav link
- `web/src/app/team/assignments/page.tsx` - Added Daily Crew sub-nav link
- `web/src/app/team/certifications/page.tsx` - Added Daily Crew sub-nav link

## Decisions Made
- Used UserDefaults relay key pattern (write-then-clear) for cross-tab context passing -- consistent with existing ConstructOS.NavToProjects pattern
- certBadgeCount hardcoded to 0 as placeholder -- Phase 25 will wire real expiring-certs query
- Web Daily Crew sub-nav link points to /team since daily crew is project-scoped (accessed per-project)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- iPhone 16 simulator not available (Xcode has iPhone 17 series) -- used iPhone 17 Pro instead

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Cross-navigation paths complete; Phase 25 can wire real cert expiry count into certBadgeCount
- Phase 28 verification sweep can confirm all nav paths functional
- Badge overlay ready for any future badge sources (just pass non-zero count)

---
*Phase: 23-ios-nav-assignment-wiring*
*Completed: 2026-04-17*
