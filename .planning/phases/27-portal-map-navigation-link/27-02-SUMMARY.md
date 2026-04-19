---
phase: 27-portal-map-navigation-link
plan: 02
subsystem: portal
tags: [nextjs, react, client-component, portal, navigation, typescript, testing]

# Dependency graph
requires:
  - phase: 27-portal-map-navigation-link
    plan: 01
    provides: showMapLink optional placeholder prop on PortalHeaderProps; PortalShell forwards showMapLink from server
provides:
  - PortalHeader as "use client" component with required showMapLink boolean
  - Route-aware Map anchor (last entry on portal home) + Overview anchor (first entry on /map)
  - Shared ANCHOR_STYLE constant for visual parity between section anchors and Map/Overview links
  - Vitest pattern for DOM tests in a node-default environment via file-local `// @vitest-environment jsdom` pragma
affects:
  - 27-03 (MobilePortalNav Map tab will follow the same usePathname pattern and showMapLink contract)
  - 27-06 (phase verification — desktop nav half of INT-07 now satisfied)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Client component conversion for route-awareness via usePathname() — SSR still produces initial HTML, client takes over pathname read on hydration (D-10 no-flash preserved because showMapLink is server-computed)"
    - "File-local vitest environment pragma (`// @vitest-environment jsdom` on line 1) to opt a single test file into jsdom while vitest.config.ts keeps the project default at `node`"
    - "afterEach(cleanup) + mockReset pattern so multi-test DOM state does not leak between cases"
    - "Shared inline style object (ANCHOR_STYLE) to guarantee visual parity between section anchors and nav links in a single place"

key-files:
  created:
    - "web/src/app/components/portal/PortalHeader.test.tsx"
  modified:
    - "web/src/app/components/portal/PortalHeader.tsx"

key-decisions:
  - "Extracted ANCHOR_STYLE to a module-level const — Plan's Step E showed the object duplicated inline three times. Consolidating into one reference guarantees D-02/D-24 visual parity holds forever and keeps the diff minimal if the anchor styling ever evolves."
  - "Added `afterEach(() => { cleanup(); mockPathname.mockReset(); })` in the test file even though the plan did not call it out — without cleanup, @testing-library/react renders accumulate in the shared jsdom `document`, making `getByRole('link', { name: 'Map' })` throw `Found multiple elements` across runs. This is a Rule 3 auto-fix (blocking issue for test completion)."
  - "Switched `.toHaveTextContent(...)` (jest-dom matcher) to `.textContent` + `.toBe(...)` (native vitest) because `@testing-library/jest-dom` is not installed and importing it was out of scope. Native `textContent` gives equivalent assertion strength for literal-string labels."
  - "Inlined JSX children as `>Map</Link>` / `>Overview</Link>` instead of placing the label on its own indented line. This is a pure formatting choice driven by the plan's AC 8 / AC 9 grep patterns (`>Map<`, `>Overview<`), which require the literal on the same line as the closing `>`. No runtime behavior change."

patterns-established:
  - "Server-computed gate + client-rendered surface: `showMapLink` arrives as a server-computed boolean (Plan 01), PortalHeader hydrates as a client component and uses `usePathname()` only to pick WHICH of {Map, Overview} renders. The GATE value never requires a client round-trip, so the initial server HTML matches the hydrated output for any given route — no D-10 hydration flash."
  - "`// @vitest-environment jsdom` pragma on first line unlocks DOM-rendering tests under a project whose default vitest environment is `node`, with zero config change."

requirements-completed: [INT-07, PORTAL-03, MAP-04]

# Metrics
duration: 14min
completed: 2026-04-19
---

# Phase 27 Plan 02: PortalHeader Map + Overview Anchor Render Summary

**PortalHeader is now a `"use client"` component that reads `usePathname()` and renders a route-aware Map anchor (last on home) or Overview anchor (first on /map), gated by the server-computed `showMapLink` prop — delivering the desktop navigation half of INT-07.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-04-19T03:58:00Z
- **Completed:** 2026-04-19T04:12:00Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 1
- **Files created:** 1

## Accomplishments

- Added `"use client"` directive at line 1 of PortalHeader.tsx
- Imported `Link` from `next/link` and `usePathname` from `next/navigation`
- Widened `PortalHeaderProps.showMapLink` from `?: boolean` (Plan 01 placeholder) to required `boolean` (Phase 27 D-19)
- Added `const isOnMap = pathname.endsWith("/map")` derived inside the function body
- Extended the nav-render gate from `sectionAnchors.length > 0` to `sectionAnchors.length > 0 || showMapLink` so the nav still renders when all sections are empty but show_map is on (D-07)
- Rendered Overview `<Link href="..">` as the FIRST nav child when `showMapLink && isOnMap` (D-05, D-26)
- Rendered Map `<Link href="./map">` as the LAST nav child when `showMapLink && !isOnMap` (D-01, D-03, D-23, D-24)
- Both new links use `prefetch={true}` (D-04 client-side nav, no full-page reload)
- Both new links consume the shared `ANCHOR_STYLE` module-level constant so visual parity with existing section anchors is preserved (D-02) with zero icon/divider markup (D-24)
- Created `PortalHeader.test.tsx` with `// @vitest-environment jsdom` as line 1 (Blocker 2 fix — without it, render() throws ReferenceError: document is not defined)
- 6 unit tests GREEN covering D-01/03/23, D-04, D-05/26, D-07, D-08 gate (two orientations), Map as last + Overview as first
- PortalShell.tsx required no changes (Plan 01 already threads `showMapLink` into PortalHeader)

## Confirmation checklist

- PortalHeader is now a client component (`head -1 PortalHeader.tsx` == `"use client";`)
- Test file starts with the jsdom pragma (`head -1 PortalHeader.test.tsx` == `// @vitest-environment jsdom`)
- Exact relative hrefs used:
  - Map link: `href="./map"` (resolves against current route segment to `/portal/[slug]/[project]/map`)
  - Overview link: `href=".."` (resolves up one segment from `/map` back to `/portal/[slug]/[project]`)
- Test count: 6 unit tests, 6 passed, 0 failed, ~907ms

## Task Commits

TDD cycle for Task 1:

1. **Task 1 RED — 6 failing tests committed** `47b8c58` (test)
2. **Task 1 GREEN — implementation + test cleanup fix** `4849760` (feat)

_No REFACTOR commit — the GREEN implementation landed clean. The cleanup/mockReset fix to the test file was bundled into the GREEN commit because without it the newly-passing implementation tests would still have reported `Found multiple elements` across the cross-test DOM leak._

## Files Created/Modified

- `web/src/app/components/portal/PortalHeader.tsx` — converted to client component (`"use client"`), imports for `Link` + `usePathname`, `showMapLink` widened to required boolean, `isOnMap` derived from `usePathname()`, nav-gate widened to `(sectionAnchors.length > 0 || showMapLink)`, Overview link (first, on /map) + Map link (last, on home) added using shared `ANCHOR_STYLE`
- `web/src/app/components/portal/PortalHeader.test.tsx` — created; 6 vitest cases under `// @vitest-environment jsdom` pragma; mocks `next/navigation` via `vi.mock`; `afterEach(cleanup + mockReset)` to avoid DOM/mock leakage

## PortalHeaderProps shape after widening

```typescript
type PortalHeaderProps = {
  companyName: string;
  logoUrl?: string;
  projectName: string;
  sectionAnchors: { id: string; label: string }[];
  lastUpdated: string;
  // Phase 27 D-19 -- required, single source of truth for desktop + mobile.
  // Server-computed in portal page.tsx and threaded through PortalShell.
  showMapLink: boolean;
};
```

## Test count and pass status

```
Test Files  1 passed (1)
     Tests  6 passed (6)
  Duration  ~907ms
```

All 6 cases pass:
1. `D-01,D-03,D-23: renders Map anchor as last nav child when showMapLink=true on home` — PASS
2. `D-04: Map anchor uses href='./map' (Next.js Link relative)` — PASS
3. `D-05,D-26: renders Overview anchor as first nav child when showMapLink=true on /map` — PASS
4. `D-08 gate: hides Map and Overview anchors when showMapLink=false on home` — PASS
5. `D-08 gate: hides Map and Overview anchors when showMapLink=false on /map` — PASS
6. `D-07: renders Map anchor when sections empty + showMapLink=true on home` — PASS

## Acceptance Criteria Verification

| AC | Check | Expected | Actual |
|----|-------|----------|--------|
| 1 | `head -1 PortalHeader.tsx` | `"use client";` | `"use client";` |
| 2 | `head -1 PortalHeader.test.tsx` | `// @vitest-environment jsdom` | `// @vitest-environment jsdom` |
| 3 | `grep -c 'import Link from "next/link"' PortalHeader.tsx` | 1 | 1 |
| 4 | `grep -c 'import { usePathname } from "next/navigation"' PortalHeader.tsx` | 1 | 1 |
| 5 | `grep -c 'showMapLink: boolean;' PortalHeader.tsx` | 1 | 1 |
| 6 | `grep -c 'href="\./map"' PortalHeader.tsx` | 1 | 1 |
| 7 | `grep -c 'href="\.\."' PortalHeader.tsx` | 1 | 1 |
| 8 | `grep -c '>Map<' PortalHeader.tsx` | 1 | 1 |
| 9 | `grep -c '>Overview<' PortalHeader.tsx` | 1 | 1 |
| 10 | `grep -c 'isOnMap' PortalHeader.tsx` | >=3 | 3 |
| 11 | `grep -c 'sectionAnchors.length > 0 \|\| showMapLink' PortalHeader.tsx` | 1 | 1 |
| 12 | `npm test -- --run PortalHeader.test` | 6 passed | 6 passed |
| 13 | `npx tsc --noEmit` errors | 0 | 0 |

## Decisions Made

- **ANCHOR_STYLE hoisted to module-level const** — The plan's Step E pseudo-code duplicated the inline style object in three places (Overview link, map of section anchors, Map link). Extracting to a single module-level constant keeps the diff minimal, satisfies D-02/D-24 visual parity in one place, and makes future style iteration impossible to get wrong by drift.
- **afterEach(cleanup) + mockPathname.mockReset() added to test file** — The plan's test example did not include cleanup. Without it, React trees from earlier tests accumulate in the shared jsdom document, producing `Found multiple elements` errors on the 2nd+ test case. Adding `afterEach` is the standard @testing-library/react pattern and was required for all 6 tests to pass. Recorded as a Rule 3 auto-fix.
- **Swapped `.toHaveTextContent(x)` for `.textContent === x`** — The plan's pseudo-tests used a jest-dom matcher. `@testing-library/jest-dom` is NOT in devDependencies. Rather than install it (out of scope for this plan), I switched to native `.textContent` + `.toBe(...)` which gives equivalent assertion strength on the literal-string labels "Map" and "Overview".
- **Inlined JSX children as `>Map</Link>` / `>Overview</Link>` on the same line as the opening-tag close** — required by AC 8 and AC 9 grep patterns (`>Map<`, `>Overview<`). This is a formatting-only choice; no runtime difference from multi-line JSX children.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test cleanup was missing from the plan's test template**
- **Found during:** Task 1 GREEN (first test run after implementation)
- **Issue:** `@testing-library/react`'s `render()` does not auto-clean between tests. Without `afterEach(cleanup)`, the 2nd test's `getByRole('link', { name: 'Map' })` throws `Found multiple elements with the role "link" and name "Map"` because the 1st test's Map anchor is still in the jsdom `document`.
- **Fix:** Added `import { afterEach } from "vitest"`, `import { cleanup } from "@testing-library/react"`, and an `afterEach(() => { cleanup(); mockPathname.mockReset(); })` block before the `describe`. Both pieces (DOM cleanup + mock reset) are required because mocks also leak by default.
- **Files modified:** `web/src/app/components/portal/PortalHeader.test.tsx`
- **Commit:** `4849760` (bundled into GREEN commit — without this the implementation tests would have failed even though the code was correct)

**2. [Rule 3 - Blocking] `.toHaveTextContent(...)` chai matcher does not exist in vanilla vitest**
- **Found during:** Task 1 GREEN (first test run after implementation)
- **Issue:** The plan's test pseudo-code used `.toHaveTextContent("Map")`, which is a `@testing-library/jest-dom` matcher. That library is NOT installed in web/package.json devDependencies, and vitest threw `Invalid Chai property: toHaveTextContent`.
- **Fix:** Rewrote the 3 affected assertions to `expect(el.textContent).toBe("Map" | "Overview")`. Semantically equivalent for label strings; no new dependency required.
- **Files modified:** `web/src/app/components/portal/PortalHeader.test.tsx`
- **Commit:** `4849760`

### Explicit non-deviations

- `@testing-library/react` is installed (verified via `ls web/node_modules/@testing-library/`) — no Wave 0 gap.
- `jsdom` ^29.0.2 is installed (verified via `ls web/node_modules/jsdom`) — the file-local pragma works out of the box.
- `web/vitest.config.ts` was NOT modified. The project-wide default remains `environment: "node"` as documented in the plan's `<vitest_environment>` block.

## Authentication Gates

None — this plan is a pure client-side component edit with no auth surface.

## Known Stubs

None. `showMapLink` arrives as a server-computed boolean from Plan 01; no placeholder data in this plan. The Map link is a real Next.js `<Link>` that will navigate to `/portal/[slug]/[project]/map` once that route exists (scoped to Plan 04). If a user clicks it before Plan 04 lands, Next.js returns the standard 404 page — expected behavior during incremental rollout.

## Threat Flags

No new security surface. `usePathname()` is browser-controlled but the only consumer is an anchor-label selection switch (`isOnMap ? Overview : Map`). The pathname value does not flow into hrefs, data fetches, or auth checks — both hrefs are static literals (`"./map"` and `".."`). Threats T-27-04 (pathname tampering), T-27-05 (hydration flash), and T-27-06 (href spoofing) from the plan's threat_model are all addressed as noted there; no new threats emerged during implementation.

## Issues Encountered

- Two blockers in the plan's test pseudo-code required Rule 3 auto-fixes (see "Deviations" section above). Both were tooling/library gaps invisible until `npm test` ran; neither changed component behavior.

## User Setup Required

None. Pure code change. The Map link will become usable once Plan 04 (`/map` route) lands; until then, rendering + prop gating are independently verifiable via the 6-test suite.

## Next Plan Readiness

- Plan 03 (MobilePortalNav Map tab) unblocked — same `usePathname` + `showMapLink` pattern applies; the Phase 27 plan already noted MobilePortalNav is already `"use client"` so no conversion needed there.
- Plan 04 (`/map` page implementation) unblocked — the Overview return-link is already in place; when a user lands on `/map`, PortalHeader will render the Overview anchor in the first nav slot with `href=".."` → portal home.
- No blockers for downstream plans.

## Self-Check: PASSED

- FOUND: `web/src/app/components/portal/PortalHeader.tsx` (modified; "use client" line 1; isOnMap + Map link + Overview link; ANCHOR_STYLE hoisted)
- FOUND: `web/src/app/components/portal/PortalHeader.test.tsx` (created; jsdom pragma line 1; 6 tests)
- FOUND: commit `47b8c58` (test RED) in `git log`
- FOUND: commit `4849760` (feat GREEN) in `git log`

---
*Phase: 27-portal-map-navigation-link*
*Plan: 02*
*Completed: 2026-04-19*
