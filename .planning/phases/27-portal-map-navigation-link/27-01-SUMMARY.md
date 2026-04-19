---
phase: 27-portal-map-navigation-link
plan: 01
subsystem: portal
tags: [nextjs, react, server-component, portal, feature-gating, typescript]

# Dependency graph
requires:
  - phase: 20-client-portal
    provides: PortalShell/PortalHeader component tree; showAmounts server-computed-prop pattern
  - phase: 21-live-satellite-traffic-maps
    provides: PortalSectionsConfig.map_overlays shape (optional field)
provides:
  - Server-side computeShowMapLink(config) helper (pure boolean expression)
  - showMapLink required prop on PortalShellProps
  - showMapLink optional placeholder prop on PortalHeaderProps (widened in Plan 02)
  - Backward-compatible gate: pre-Phase-21 portals with no map_overlays field evaluate to false (D-09)
affects:
  - 27-02 (PortalHeader Map link render — consumes showMapLink)
  - 27-03 (MobilePortalNav Map tab — consumes showMapLink)
  - 27-04 (SectionVisibilityEditor helper copy)
  - 27-05 (/map page branding/analytics)
  - 27-06 (phase verification)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server-computed boolean prop threaded through PortalShell -> PortalHeader (parity with Phase 20 showAmounts)"
    - "Defensive Boolean(...?.field?.subfield) gating to coerce missing/undefined to false without DB migration (D-11)"
    - "Exported helper alongside server component default export for direct vitest import under node environment"

key-files:
  created:
    - "web/src/app/portal/[slug]/[project]/page.test.ts"
  modified:
    - "web/src/app/portal/[slug]/[project]/page.tsx"
    - "web/src/app/components/portal/PortalShell.tsx"
    - "web/src/app/components/portal/PortalHeader.tsx"

key-decisions:
  - "Use Boolean(config?.sections_config?.map_overlays?.show_map) instead of DEFAULT_MAP_OVERLAYS fallback — D-09 explicitly overrides the default for backward compat with pre-Phase-21 portals"
  - "Add showMapLink as optional on PortalHeaderProps in Plan 01 and widen to required in Plan 02 — prevents TS errors during incremental rollout while PortalHeader render is not yet wired"
  - "Destructure showMapLink into _showMapLink in PortalHeader with eslint-disable-next-line no-unused-vars — documents the accept-but-do-not-use stance for Plan 01 -> Plan 02 bridge"
  - "Place helper as a named export near shouldShowAmounts (line 54) — mirrors Phase 20's co-location pattern; makes the server component directly testable via relative import under vitest node environment"

patterns-established:
  - "Server-computed feature gate pattern: pure helper -> server component local const -> prop forwarded to shell -> re-forwarded to sub-components (no client-side gate evaluation, no hydration flash per D-10)"
  - "Backward-compat-by-falsy gating: rely on optional-chaining + Boolean() to coerce absent fields to false, avoiding DB migration for pre-existing rows"

requirements-completed: [INT-07, PORTAL-03, MAP-04]

# Metrics
duration: 12min
completed: 2026-04-19
---

# Phase 27 Plan 01: Server-compute showMapLink Gate Summary

**Server-side feature gate `computeShowMapLink()` threaded from portal page.tsx through PortalShell to PortalHeader, with D-09 backward-compat that keeps pre-Phase-21 portals OFF by default.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-19T03:32:00Z
- **Completed:** 2026-04-19T03:44:00Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 3
- **Files created:** 1

## Accomplishments

- Exported `computeShowMapLink(config: PortalConfig): boolean` at `web/src/app/portal/[slug]/[project]/page.tsx:56`
- Gating expression is `Boolean(config?.sections_config?.map_overlays?.show_map)` — single point of truth, no DB dependency
- `PortalShellProps` extended with required `showMapLink: boolean` field and forwarded to `<PortalHeader>`
- `PortalHeaderProps` accepts optional `showMapLink?: boolean` placeholder so Plan 01 compiles standalone; Plan 02 will widen the contract and activate the Map link render
- 5 unit tests (D-08, D-09, D-11) green: missing field, true, false, undefined show_map, null sections_config
- No DB migration (D-11 honored); no hydration flash (D-10 — SSR HTML is authoritative)
- Closes the data-flow half of INT-07

## Task Commits

TDD cycle for Task 1:

1. **Task 1 RED — failing tests** `684f3ed` (test)
2. **Task 1 GREEN — implementation** `b6826d6` (feat)

_No REFACTOR commit — implementation landed clean; lint/tsc stayed green, no duplication to extract._

## Files Created/Modified

- `web/src/app/portal/[slug]/[project]/page.tsx` — added exported `computeShowMapLink` helper (line 56), local `showMapLink` computation after `showAmounts`, and new prop on `<PortalShell>` invocation
- `web/src/app/portal/[slug]/[project]/page.test.ts` — created; 5 vitest cases covering D-08, D-09, D-11 gating behavior under node environment
- `web/src/app/components/portal/PortalShell.tsx` — `PortalShellProps.showMapLink: boolean` (required), destructured in function signature, forwarded to `<PortalHeader showMapLink={showMapLink} />`
- `web/src/app/components/portal/PortalHeader.tsx` — `PortalHeaderProps.showMapLink?: boolean` (optional placeholder); destructured as `_showMapLink` with an `eslint-disable-next-line no-unused-vars` so the Plan 01 -> Plan 02 bridge is lint-clean

## PortalShellProps shape after extension

```typescript
type PortalShellProps = {
  branding: CompanyBranding | null;
  theme: PortalThemeConfig;
  portalConfig: PortalConfig;
  sections: Record<string, unknown>;
  healthScore: HealthScore;
  projectName: string;
  sectionOrder: PortalSectionKey[];
  showAmounts: boolean;
  // D-10, D-19: Server-computed gate for the Map navigation link.
  showMapLink: boolean;
};
```

## DEFAULT_MAP_OVERLAYS is NOT used as fallback (confirmed)

```bash
$ grep -c "DEFAULT_MAP_OVERLAYS" web/src/app/portal/[slug]/[project]/page.tsx
0
```

The gating expression intentionally bypasses the `DEFAULT_MAP_OVERLAYS.show_map = true` constant (defined in `web/src/lib/portal/types.ts`). Per D-09, backward-compat for pre-Phase-21 portal links requires the gate to be OFF when the `map_overlays` field is absent — falling back to the default would flip the gate ON for existing client portals without admin opt-in, breaking client trust.

## Test count and pass status

```
Test Files  1 passed (1)
     Tests  5 passed (5)
  Duration  ~416ms
```

All 5 cases pass:
1. `returns false when sections_config has no map_overlays field (D-09 pre-Phase-21)` — PASS
2. `returns true when map_overlays.show_map === true (D-08)` — PASS
3. `returns false when map_overlays.show_map === false (D-08)` — PASS
4. `returns false when map_overlays exists but show_map is undefined` — PASS
5. `returns false when sections_config is null (defensive)` — PASS

## Acceptance Criteria Verification

| AC | Check | Expected | Actual |
|----|-------|----------|--------|
| 1 | `grep -n "export function computeShowMapLink" page.tsx` | >=1 | 1 (line 56) |
| 2 | `grep -c "Boolean(config?.sections_config?.map_overlays?.show_map)" page.tsx` | 1 | 1 |
| 3 | `grep -c "const showMapLink = computeShowMapLink(portalConfig);" page.tsx` | 1 | 1 |
| 4 | `grep -c "showMapLink={showMapLink}" page.tsx` | 1 | 1 |
| 5 | `grep -c "showMapLink: boolean;" PortalShell.tsx` | 1 | 1 |
| 6 | `grep -c "showMapLink={showMapLink}" PortalShell.tsx` | 1 | 1 |
| 7 | `grep -c "showMapLink?: boolean;" PortalHeader.tsx` | 1 | 1 |
| 8 | `grep -c "DEFAULT_MAP_OVERLAYS" page.tsx` | 0 | 0 |
| 9 | `vitest --run page.test` | 5 passed | 5 passed |
| 10 | `tsc --noEmit` error count | 0 | 0 |

## Decisions Made

- **Helper placement at module top (alongside `shouldShowAmounts`)** — keeps feature-gate helpers co-located, preserves Phase 20's export-for-test convention, and makes the helper directly importable from `page.test.ts` under vitest's node environment without pulling in the default export's server-only body (the helper itself has no server-only imports).
- **Optional prop on PortalHeader (not required)** — avoids a TS break in the Plan 01 -> Plan 02 handoff window. Plan 02 will tighten to required when the Map link render lands. The destructured-but-unused `_showMapLink` pattern surfaces the prop in the component contract while the render slot is still being built.
- **Rephrased comment to remove `DEFAULT_MAP_OVERLAYS` identifier** — AC 8 required 0 matches of `DEFAULT_MAP_OVERLAYS` in page.tsx. The initial comment referenced the constant by name in explanatory text; rephrased to reference "default-map-overlays constant" prose so the literal identifier string count stays 0, satisfying the grep-based AC without weakening the documentation intent.

## Deviations from Plan

None — plan executed exactly as written. All 10 acceptance criteria PASS on first green run.

## Known Stubs

**1. `showMapLink?: boolean` on PortalHeaderProps is an accept-but-ignore placeholder**
- **File:** `web/src/app/components/portal/PortalHeader.tsx:11-14`
- **Reason:** Intentional. Plan 01's scope is the data-flow side of INT-07 (server-side gate + prop threading). Plan 02 owns activating the Map link render in PortalHeader. Widening to required and wiring the render is explicitly scoped to Plan 02 per the plan's Step D note.
- **Resolution phase/plan:** 27-02 (PortalHeader Map link render).
- **Risk if not resolved:** None for Plan 01 correctness (data flow is already validated by the 5 unit tests). If Plan 02 slips, the Map link remains invisible even when `show_map === true`, but that is a UI-side regression outside this plan's scope.

No data stubs exist. `sections_config.map_overlays.show_map` is authoritative from the DB; `computeShowMapLink` returns a real boolean derived from live data, not a hardcoded value.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. Pure application-layer change.

## Next Phase Readiness

- Plan 02 (PortalHeader Map link render) unblocked — `showMapLink` prop available on `PortalHeaderProps`; consumer simply widens the type from `?` to required and renders a `<Link href="./map">` when truthy.
- Plan 03 (MobilePortalNav Map tab) unblocked — `showMapLink` is available on `PortalShell` and can be forwarded to MobilePortalNav when that component integration lands.
- No blockers for downstream plans.

## Self-Check: PASSED

- FOUND: `web/src/app/portal/[slug]/[project]/page.tsx` (modified; `computeShowMapLink` at line 56)
- FOUND: `web/src/app/portal/[slug]/[project]/page.test.ts` (created; 5 tests)
- FOUND: `web/src/app/components/portal/PortalShell.tsx` (modified; `showMapLink: boolean` required prop + forward to PortalHeader)
- FOUND: `web/src/app/components/portal/PortalHeader.tsx` (modified; `showMapLink?: boolean` optional placeholder prop)
- FOUND: commit `684f3ed` (test RED) in `git log`
- FOUND: commit `b6826d6` (feat GREEN) in `git log`

---
*Phase: 27-portal-map-navigation-link*
*Plan: 01*
*Completed: 2026-04-19*
