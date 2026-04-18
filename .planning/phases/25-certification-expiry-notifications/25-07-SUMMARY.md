---
phase: 25-certification-expiry-notifications
plan: 07
subsystem: ui
tags: [swiftui, autocomplete, nextjs, admin-badge, certifications]

# Dependency graph
requires:
  - phase: 25-03
    provides: CertUrgency enum, urgency badges, AddCertSheet, EditCertSheet in CertificationsView.swift
  - phase: 25-04
    provides: Urgency badges, summary banner, CertHighlightScroller on web cert page
provides:
  - Autocomplete cert name input in iOS AddCertSheet replacing Picker
  - Admin-only cert scan status badge on web certifications page
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [autocomplete-textfield-with-suggestions, admin-gated-server-badge]

key-files:
  created: []
  modified:
    - ready player 8/CertificationsView.swift
    - web/src/app/team/certifications/page.tsx

key-decisions:
  - "Autocomplete uses localizedCaseInsensitiveContains for case-insensitive matching against CERT_NAMES"
  - "Admin detection via cs_projects.created_by ownership proxy -- lightweight, no separate roles table needed"

patterns-established:
  - "Autocomplete TextField pattern: single @State var + filteredNames computed property + showSuggestions toggle"
  - "Admin-gated server component badge: query admin status server-side, conditionally render badge in JSX"

requirements-completed: [TEAM-04, NOTIF-04]

# Metrics
duration: 3min
completed: 2026-04-18
---

# Phase 25 Plan 07: Cert Name Autocomplete + Admin Scan Badge Summary

**Autocomplete cert name input in iOS AddCertSheet with CERT_NAMES suggestions, plus admin-only scan status badge on web certifications page**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-18T13:55:01Z
- **Completed:** 2026-04-18T13:58:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Replaced Picker-based cert name selection with autocomplete TextField showing filtered CERT_NAMES suggestions
- Preserved free-text entry for regional/specialty cert names not in CERT_NAMES
- Added admin-only status badge showing last scan time and 24h alert count on web cert page
- Admin detection uses server-side project ownership check (not client-side)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace Picker with autocomplete TextField in iOS AddCertSheet** - `5e5e3cd` (feat)
2. **Task 2: Add admin-only cert scan status badge to web certifications page** - `651a2fc` (feat)

## Files Created/Modified
- `ready player 8/CertificationsView.swift` - Replaced Picker+customName with certName TextField, filteredCertNames computed property, showSuggestions state
- `web/src/app/team/certifications/page.tsx` - Added timeAgo helper, admin check via cs_projects ownership, cs_activity_events scan query, admin badge JSX with aria-label

## Decisions Made
- Used localizedCaseInsensitiveContains for cert name filtering -- natural Swift API for fuzzy matching
- Admin detection via cs_projects.created_by match -- avoids need for separate roles table while providing reasonable admin proxy
- Scan status derived from cs_activity_events with entity_type=certifications -- reuses existing activity infrastructure

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 25 (certification-expiry-notifications) is now complete with all 7 plans executed
- All cert UX decisions (D-31 autocomplete, D-38 admin badge) are implemented
- Ready for Phase 26 (Documents RLS Table Reconciliation) or Phase 28 verification sweep

---
*Phase: 25-certification-expiry-notifications*
*Completed: 2026-04-18*
