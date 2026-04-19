---
phase: 27-portal-map-navigation-link
plan: 03
subsystem: portal
tags: [nextjs, react, client-component, portal, mobile-nav, navigation, typescript, testing]

# Dependency graph
requires:
  - phase: 27-portal-map-navigation-link
    plan: 01
    provides: showMapLink server-computed boolean threaded through PortalShell
  - phase: 27-portal-map-navigation-link
    plan: 02
    provides: PortalHeader client-component pattern (usePathname + next/link + file-local jsdom pragma)
provides:
  - MobilePortalNav with required showMapLink boolean prop
  - 6th MapPin entry rendered as Next.js Link (not scroll button)
  - Route-aware active state via usePathname().endsWith("/map")
  - Early-return guard widened to render when sections empty + showMapLink=true (D-07 parity)
affects:
  - 27-06 (phase verification — mobile nav half of INT-07 now satisfied)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mixed-role <nav> container: 5 section scroll <button>s + 1 Map <a> (Next.js Link) as siblings under the same nav aria-label"
    - "Scoped active-state derivation: section active tracks IntersectionObserver (existing); Map active tracks usePathname (new) — two orthogonal sources, zero cross-talk"
    - "jsdom IntersectionObserver stub in beforeAll() — pre-existing useEffect calls `new IntersectionObserver()`, which jsdom does not implement. A 5-line class mock (observe/disconnect/unobserve/takeRecords + no-op props) unblocks all 6 tests without touching the component."
    - "RGB-or-HEX style assertion pattern — jsdom normalizes `#9CA3AF` to `rgb(156, 163, 175)` in the serialized style attribute; test regex accepts either form so the assertion tracks intent, not serialization format"

key-files:
  created:
    - "web/src/app/components/portal/MobilePortalNav.test.tsx"
  modified:
    - "web/src/app/components/portal/MobilePortalNav.tsx"

key-decisions:
  - "Added an IntersectionObserver stub in the test file's beforeAll() rather than modifying the component to guard `typeof IntersectionObserver !== 'undefined'`. The component correctly uses IntersectionObserver in a 'use client' useEffect — that is the real-browser contract. The stub belongs in the jsdom-only test environment, not in production code. Recorded as a Rule 3 auto-fix."
  - "Widened the inactive-color assertion regex to `/#9CA3AF|rgb\\(156,\\s*163,\\s*175\\)/`. jsdom's HTML serializer converts `color: #9CA3AF` inline CSS to `color: rgb(156, 163, 175)` when reading `getAttribute('style')`. The component ships the hex literal; the test now tolerates jsdom's representation drift. Recorded as a Rule 3 auto-fix."
  - "Did NOT include Map in the swipe-cycle enabledSections.findIndex() logic. Per D-17, only the 5 section icons participate in scroll-tracking / swipe navigation. Map is a route link — clicking navigates the page; it is not part of the scroll-based section cycle."
  - "MAP_PIN_ICON hoisted as a module-level const OUTSIDE SECTION_ICONS — 'map' is not a valid PortalSectionKey, so adding it to the SECTION_ICONS Record would require widening the key union (breaking change) or using a non-type-safe string. A separate const preserves PortalSectionKey's integrity."

patterns-established:
  - "Server-computed gate + client-rendered surface (same as Plan 02): `showMapLink` arrives as a server-computed boolean (Plan 01), MobilePortalNav hydrates and uses `usePathname()` only for the Map icon's active-state color. The GATE value never requires a client round-trip, so the initial server HTML matches the hydrated output for any given route — no D-10 hydration flash."
  - "jsdom IntersectionObserver stub pattern for testing components that observe DOM scroll state under a jsdom environment. Minimal 5-method shape works with any observer-using component."

requirements-completed: [INT-07, PORTAL-03, MAP-04]

# Metrics
duration: 11min
completed: 2026-04-19
---

# Phase 27 Plan 03: MobilePortalNav Map Icon Summary

**MobilePortalNav now renders a 6th MapPin icon as a Next.js `<Link>` (not a scroll button) when `showMapLink=true`, with route-aware active state via `usePathname()` — delivering the mobile navigation half of INT-07.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-04-19T00:17:00Z
- **Completed:** 2026-04-19T00:28:00Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 1
- **Files created:** 1

## Accomplishments

- `MobilePortalNavProps` extended with required `showMapLink: boolean` field (D-19)
- `MAP_PIN_ICON` module-level const added (Lucide-style 20×20 stroke-2 inline SVG, D-25)
- `Link` imported from `next/link`; `usePathname` imported from `next/navigation` (Plan 02 pattern)
- `const isOnMap = pathname.endsWith("/map")` derived inside function body
- Early-return guard widened from `enabledSections.length === 0` to `enabledSections.length === 0 && !showMapLink` — nav now renders when sections are empty but showMapLink=true (D-07 parity)
- 6th Map entry renders as `<Link href="./map" prefetch={true}>` AFTER the 5 section `<button>` map (D-16)
- Active state styling (`color: var(--portal-primary, #2563EB)`, `fontWeight: 600`) when `isOnMap === true` (D-17)
- Inactive state styling (`color: #9CA3AF`, `fontWeight: 400`) on portal home
- `aria-label="Navigate to Map"` + `aria-current={isOnMap ? "page" : undefined}` for a11y (D-17)
- Existing IntersectionObserver useEffect and touchstart/touchend swipe useEffect preserved UNCHANGED — the 5 section icons still use scroll-based active tracking; Map is route-driven and NOT part of the swipe cycle
- 6 unit tests GREEN covering D-08 gate, D-16 Link-not-scroll-button, D-17 route-aware active + inactive states, D-19 prop, D-25 MapPin SVG, and "Map-alone" render when all sections disabled

## Confirmation of Plan 06 boundary

**Plan 06 owns the PortalShell consumer wiring.** This plan modifies ONLY the MobilePortalNav component file itself and its test file. PortalShell.tsx is untouched. `grep MobilePortalNav web/src/` confirms the only reference in PortalShell is a comment ("Forwarded to PortalHeader (and MobilePortalNav in Plan 03)") — there is no render-call-site anywhere in web/ today, and adding one is explicitly Plan 06's scope.

## Confirmation: test file starts with jsdom pragma

```
$ head -1 web/src/app/components/portal/MobilePortalNav.test.tsx
// @vitest-environment jsdom
```

Line 1 is exactly `// @vitest-environment jsdom`. Without it, `render()` from `@testing-library/react` throws `ReferenceError: document is not defined` under vitest.config.ts's default `environment: "node"`.

## Task Commits

TDD cycle for Task 1:

1. **Task 1 RED — 6 failing tests committed** `daea04b` (test)
2. **Task 1 GREEN — implementation + IntersectionObserver stub fix** `14add7c` (feat)

_No REFACTOR commit — the GREEN implementation landed clean. Two auto-fixes (IntersectionObserver stub + RGB/HEX regex) were bundled into the GREEN commit because without them the newly-passing implementation tests would still have failed under jsdom._

## Files Created/Modified

- `web/src/app/components/portal/MobilePortalNav.tsx` — added imports for `Link` + `usePathname`, `MAP_PIN_ICON` module const, `showMapLink` required prop, `pathname`/`isOnMap` derivation, widened early-return guard, 6th Map `<Link>` rendered conditional on `showMapLink` inside the `<nav>` after the 5 section buttons
- `web/src/app/components/portal/MobilePortalNav.test.tsx` — created; 6 vitest cases under `// @vitest-environment jsdom` pragma; mocks `next/navigation` via `vi.mock`; `beforeAll` installs a minimal IntersectionObserver stub on globalThis; `afterEach(cleanup + mockReset)` to avoid DOM/mock leakage

## MobilePortalNavProps shape after extension

```typescript
type MobilePortalNavProps = {
  sections: { key: PortalSectionKey; label: string; enabled: boolean }[];
  // Phase 27 D-19 — when true, renders the 6th MapPin icon.
  showMapLink: boolean;
};
```

## Test count and pass status

```
Test Files  1 passed (1)
     Tests  6 passed (6)
  Duration  ~912ms
```

All 6 cases pass:
1. `D-08 gate: renders exactly 5 nav items when showMapLink=false` — PASS
2. `D-16,D-19,D-25: renders 6th MapPin entry when showMapLink=true` — PASS
3. `D-16: Map entry is a Next.js Link (anchor), NOT a scroll button` — PASS
4. `D-17: Map entry shows active state when usePathname ends with /map` — PASS
5. `D-17: Map entry shows inactive state on portal home` — PASS
6. `renders Map alone when sections all disabled + showMapLink=true` — PASS

## Acceptance Criteria Verification

| AC | Check | Expected | Actual |
|----|-------|----------|--------|
| 1 | `head -1 MobilePortalNav.test.tsx` | `// @vitest-environment jsdom` | `// @vitest-environment jsdom` |
| 2 | `grep -c 'import Link from "next/link"' MobilePortalNav.tsx` | 1 | 1 (line 10) |
| 3 | `grep -c 'import { usePathname } from "next/navigation"' MobilePortalNav.tsx` | 1 | 1 (line 11) |
| 4 | `grep -c MAP_PIN_ICON MobilePortalNav.tsx` | >=2 | 2 (decl line 20, usage line 231) |
| 5 | `grep -c 'showMapLink: boolean;' MobilePortalNav.tsx` | 1 | 1 |
| 6 | `grep -c 'href="\./map"' MobilePortalNav.tsx` | 1 | 1 |
| 7 | `grep -c isOnMap MobilePortalNav.tsx` | >=3 | 4 (decl + 3 uses) |
| 8 | `grep -E 'aria-current.*isOnMap' \| wc -l` | >=1 | 1 |
| 9 | `grep -n 'M21 10c0 7-9 13-9 13' \| wc -l` | >=1 | 1 |
| 10 | `grep -c 'enabledSections.length === 0 && !showMapLink' MobilePortalNav.tsx` | 1 | 1 |
| 11 | `npm test -- --run MobilePortalNav.test` | 6 passed | 6 passed |
| 12 | `npx tsc --noEmit` errors | 0 | 0 |

## Decisions Made

- **IntersectionObserver stub placed in test, not component** — The component correctly uses the real IntersectionObserver API under its `"use client"` directive. That is the production contract. Polluting the component with `typeof IntersectionObserver !== 'undefined'` guards would degrade production behavior for a test-environment gap. The stub belongs in the test file's `beforeAll()`, where it is scoped and explicit.
- **`RGB|HEX` regex for inactive-color assertion** — jsdom serializes inline `style={{ color: "#9CA3AF" }}` as `color: rgb(156, 163, 175)` when read via `getAttribute('style')`. The regex `/#9CA3AF|rgb\(156,\s*163,\s*175\)/` tracks assertion intent ("element uses the inactive-muted color") rather than the exact byte-level format, so it passes under both jsdom and a real browser environment.
- **Map NOT part of swipe-cycle enabledSections logic** — D-17 explicitly says "Portal-home sections continue to use the existing IntersectionObserver active tracking". The swipe handler's `enabledSections.findIndex(...)` is scoped to the 5 section icons. Adding Map to that array would make a left-swipe from "documents" navigate to `/map` (wrong behavior — user expected to stay on home).
- **MAP_PIN_ICON as standalone const (not in SECTION_ICONS)** — `SECTION_ICONS: Record<PortalSectionKey, React.ReactNode>` requires every key to be a valid `PortalSectionKey`. Adding `"map"` would either require widening the type union (breaking change with cascading test updates) or using a non-type-safe string key. A standalone const preserves `PortalSectionKey` integrity with zero ripple.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] jsdom does not implement IntersectionObserver**
- **Found during:** Task 1 GREEN (first test run after implementation)
- **Issue:** `MobilePortalNav.tsx:88` constructs `new IntersectionObserver(...)` inside a `useEffect`. jsdom's global scope has no `IntersectionObserver`, so the first `render()` throws `ReferenceError: IntersectionObserver is not defined`. This blocked 5 of 6 tests (the 6th, "Map alone", passed because the IntersectionObserver `useEffect` early-returns when `enabledSections.length === 0`).
- **Fix:** Added a `beforeAll()` block in the test file installing a minimal 5-method class mock (`observe`, `disconnect`, `unobserve`, `takeRecords`, + `root`/`rootMargin`/`thresholds` props) onto `globalThis`. Zero component changes.
- **Files modified:** `web/src/app/components/portal/MobilePortalNav.test.tsx`
- **Commit:** `14add7c` (bundled into GREEN commit)

**2. [Rule 3 - Blocking] jsdom normalizes inline color #9CA3AF to rgb(156, 163, 175)**
- **Found during:** Task 1 GREEN (after IntersectionObserver fix)
- **Issue:** Test 5 asserted `expect(style).toMatch(/#9CA3AF/)` against `getAttribute('style')`. jsdom's CSS serializer converts the hex literal to `rgb(156, 163, 175)` in the returned string, so the hex-only regex never matched. Component behavior is correct; the assertion format was too strict.
- **Fix:** Widened the regex to `/#9CA3AF|rgb\(156,\s*163,\s*175\)/` to accept either form. Semantically equivalent; passes under jsdom today and would also pass under a real browser in the (unlikely) case the browser preserves the hex literal.
- **Files modified:** `web/src/app/components/portal/MobilePortalNav.test.tsx`
- **Commit:** `14add7c`

### Explicit non-deviations

- Component code (`MobilePortalNav.tsx`) was NOT modified for either blocker. Both auto-fixes are test-environment-only — the production component behaves correctly under a real browser's IntersectionObserver + CSS engine.
- Plan's Step I (`npm run lint`) — global lint run reports 3051 pre-existing errors + 8033 pre-existing warnings across unrelated files (useFetch.ts cascading-renders, entityPickerQuery.test.ts `_cols` unused, daily-log-create.test.ts `_row` unused, dataMasking.test.ts unused import, portalCreate.test.ts unused import, middleware.test.ts `_url/_key/_config` unused). `grep MobilePortalNav` against the lint output returns zero matches — my changed files introduce ZERO new lint warnings/errors. Scope-boundary rule applied: out-of-scope lint issues deferred (pre-existing, not caused by this plan).

## Authentication Gates

None — pure client-side component edit, no auth surface.

## Known Stubs

None. `showMapLink` arrives as a server-computed boolean from Plan 01; the Map `<Link>` has a real `href="./map"` that will navigate to `/portal/[slug]/[project]/map` once Plan 04 lands that route. The `IntersectionObserver` stub is test-env-only and explicitly labeled as a Rule 3 auto-fix.

## Threat Flags

No new security surface introduced beyond what was accepted in the plan's `<threat_model>` block (T-27-07 cosmetic-only usePathname, T-27-08 standard a11y label, T-27-09 no new listeners). `usePathname()` drives ONLY the Map icon's color + `aria-current`. The `href` is a static literal `"./map"`; pathname never flows into hrefs, data fetches, or auth checks.

## Issues Encountered

- Two jsdom-environment blockers (IntersectionObserver missing + CSS color normalization) required Rule 3 auto-fixes in the test file. Both were test-env gaps invisible until `npm test` ran; neither changed component behavior.

## User Setup Required

None. Pure code change. The Map link will become usable once Plan 06 wires `<MobilePortalNav showMapLink={showMapLink} />` into PortalShell and Plan 04 lands the `/map` route. Until then, the component's rendering + prop gating are independently verifiable via the 6-test suite.

## Next Plan Readiness

- Plan 04 (`/map` page implementation) unblocked — when the /map route lands, MobilePortalNav's route-aware active state will automatically light up because `usePathname().endsWith("/map")` will evaluate `true`.
- Plan 06 (PortalShell consumer wiring) unblocked — ready to render `<MobilePortalNav sections={...} showMapLink={showMapLink} />` using the same `showMapLink` that PortalShell already accepts and forwards to PortalHeader (Plan 01).
- No blockers for downstream plans.

## Self-Check: PASSED

- FOUND: `web/src/app/components/portal/MobilePortalNav.tsx` (modified; Link + usePathname imports, MAP_PIN_ICON const, showMapLink prop, isOnMap derivation, widened early-return, 6th Map Link)
- FOUND: `web/src/app/components/portal/MobilePortalNav.test.tsx` (created; jsdom pragma line 1; IntersectionObserver stub in beforeAll; 6 tests)
- FOUND: commit `daea04b` (test RED) in `git log`
- FOUND: commit `14add7c` (feat GREEN) in `git log`

---
*Phase: 27-portal-map-navigation-link*
*Plan: 03*
*Completed: 2026-04-19*
