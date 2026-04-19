---
phase: 27-portal-map-navigation-link
plan: 05
subsystem: ui
tags: [portal, admin-ui, react, nextjs, helper-copy, discoverability]

# Dependency graph
requires:
  - phase: 27-portal-map-navigation-link
    provides: Show Map toggle in PortalCreateDialog (checkbox bound to mapOverlays.show_map — pre-existing lines 512-535)
provides:
  - Static admin helper copy beneath Show Map checkbox explaining the client-viewer effect of the toggle
  - Closes the admin-facing discoverability half of INT-07 (D-15)
affects: [portal-admin-ui, portal create/edit dialog, future phases that add a Show Map toggle to SectionVisibilityEditor]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inline helper copy directly beneath the toggle it describes — co-location over documentation"
    - "Reuse of existing design tokens (fontSize.xs / gray[500]) for secondary metadata text"
    - "D-## (Phase ##) source marker in JSX comment so future readers can trace back to the decision"

key-files:
  created: []
  modified:
    - "web/src/app/components/portal/PortalCreateDialog.tsx — inserted 11-line helper <p> block at lines 536-546"

key-decisions:
  - "Helper placed in PortalCreateDialog.tsx (not SectionVisibilityEditor.tsx) because the show_map toggle lives in PortalCreateDialog — honors D-15 parenthetical 'or the component that toggles map_overlays.show_map' and puts the helper exactly where the admin decision is made"
  - "Exact D-15 string used verbatim: 'Clients see a Map link in the portal navigation when enabled.'"
  - "24px left indent matches the paddingLeft used by the nested overlay options block immediately below, producing visual alignment with the checkbox label content"

patterns-established:
  - "Admin helper copy pattern: <p> with xs font + gray[500] + 24px left indent + 1.4 lineHeight + D-## (Phase ##) marker comment — reusable for any future 'explain what this toggle does' copy in portal admin surface"

requirements-completed: [INT-07, PORTAL-03, MAP-04]

# Metrics
duration: 4min
completed: 2026-04-19
---

# Phase 27 Plan 05: Admin Helper Copy for Show Map Toggle Summary

**Static helper string "Clients see a Map link in the portal navigation when enabled." rendered beneath the Show Map checkbox in PortalCreateDialog, closing the admin-facing discoverability half of INT-07 per D-15.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-19T03:51:09Z
- **Completed:** 2026-04-19T03:55:19Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added single-sentence helper copy beneath Show Map checkbox so admins understand the client-viewer effect of enabling the toggle
- Zero new UI primitives introduced; zero LivePreviewPanel modifications — honors D-15 "No new UI" constraint
- SectionVisibilityEditor.tsx intentionally left untouched per the plan's discrepancy_note

## Task Commits

1. **Task 1: Add admin helper copy beneath Show Map toggle** — `885cc04` (feat)

## Files Created/Modified

- `web/src/app/components/portal/PortalCreateDialog.tsx` — inserted a static `<p>` at lines 536-546 with the D-15 helper string, using existing design tokens (`tokens.typography.fontSize.xs`, `tokens.colors.gray[500]`), a 24px left margin for visual alignment with the checkbox label content, and a `D-15 (Phase 27)` comment marker on line 536

## Helper String Verification

- **Exact string** (verbatim from D-15): `Clients see a Map link in the portal navigation when enabled.`
- **Location:** `web/src/app/components/portal/PortalCreateDialog.tsx` line 545 (inside `<p>` spanning 537-546)
- **Preceding element:** `</label>` closing the Show Map checkbox row on line 535
- **Following element:** `{mapOverlays.show_map && (` conditional block on line 547
- **Grep-confirmed placement:** `grep -B 10 -A 3 "Clients see a Map link" ... | grep -E "</label>|mapOverlays.show_map"` returns 2 matches (sandwich intact)

## SectionVisibilityEditor.tsx Intentionally Not Modified

Per the plan's `<discrepancy_note>`:

- D-15 reads "Add helper copy to the existing `SectionVisibilityEditor` **(or the component that toggles `map_overlays.show_map`)**"
- Code reality: `SectionVisibilityEditor.tsx` only renders the 5 standard section toggles (`schedule`, `budget`, `photos`, `change_orders`, `documents`) via `SECTION_ORDER`. It does NOT own the `map_overlays.show_map` toggle.
- The actual Show Map toggle lives in `PortalCreateDialog.tsx` lines 512-535.
- Therefore the helper was placed in `PortalCreateDialog.tsx` — co-located with the toggle the admin actually interacts with. This is the user-friendliest placement: the helper appears exactly where the admin is making the decision.
- Confirmed via `grep -c "Clients see a Map link" SectionVisibilityEditor.tsx` = 0.

**Future-phase note:** If a future phase introduces a Show Map toggle to `SectionVisibilityEditor` (for example, as part of an edit-existing-portal flow), the same helper string SHOULD be duplicated there so the helper stays adjacent to the toggle wherever it appears. That is OUT OF SCOPE for Phase 27.

## Decisions Made

- Placement decision: PortalCreateDialog over SectionVisibilityEditor (rationale above). This honors the D-15 parenthetical and follows the user-facing principle "put the helper where the control lives."
- Style decision: `fontSize.xs` + `gray[500]` produces subtle, secondary text that does not visually compete with the checkbox label; `24px` left indent matches the nested overlay options block immediately below for visual alignment.
- Marker decision: Included `D-15 (Phase 27)` source marker in the JSX comment so future readers can trace the helper back to the originating decision record without git archaeology.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None. All 7 acceptance criteria passed on the first attempt:

1. Helper string matches exactly once in PortalCreateDialog.tsx — PASS (1 match)
2. `D-15.*Phase 27` comment marker present — PASS (line 536)
3. `Clients see a Map link` absent from SectionVisibilityEditor.tsx — PASS (0 matches)
4. No LivePreview Phase 27/D-15 changes — PASS (0 matches)
5. Placement between `</label>` and `{mapOverlays.show_map && (` — PASS (2 matches in -B 10/-A 3 window)
6. `tsc --noEmit` shows 0 PortalCreateDialog errors — PASS
7. `npm run lint` introduces 0 new warnings/errors on PortalCreateDialog — PASS (repo has 11,084 pre-existing lint issues across other files; zero on this file)

## User Setup Required

None - no external service configuration required. This is a pure UI string addition; no env vars, no DB changes, no API keys.

## Next Phase Readiness

- INT-07 admin-facing discoverability half CLOSED
- Remaining INT-07 work (client-facing Map link rendering) belongs to Plans 27-02/03/04 and Phase 27 verification
- No new blockers introduced

## Self-Check: PASSED

- FOUND: web/src/app/components/portal/PortalCreateDialog.tsx (modified, 11 lines inserted)
- FOUND: commit 885cc04 in `git log` with message `feat(27-05): add admin helper copy beneath Show Map toggle`
- FOUND: helper string verbatim at line 545 of PortalCreateDialog.tsx
- FOUND: D-15 (Phase 27) marker comment at line 536

---
*Phase: 27-portal-map-navigation-link*
*Completed: 2026-04-19*
