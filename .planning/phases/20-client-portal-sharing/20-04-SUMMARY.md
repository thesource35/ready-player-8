---
phase: 20-client-portal-sharing
plan: 04
subsystem: web-portal-ui
tags: [portal, ssr, branding, sections, health-badge, budget-masking, cache-headers]

requires:
  - phase: 20-02
    provides: Portal query modules (portalQueries, brandingQueries, analyticsQueries)
  - phase: 20-03
    provides: Portal API routes, CSS sanitizer, image processor, slug generator
provides:
  - Public portal SSR page at /portal/[slug]/[project] with branded OG metadata
  - Portal layout with noindex/nofollow and Inter font
  - PortalShell with CSS custom property branding application
  - 11 portal UI components (header, footer, sections, health badge, cookie consent, expired page)
  - Budget masking via shouldShowAmounts() gating
  - Section visibility enforcement (disabled sections never queried)
  - 60s edge cache via Cache-Control headers
affects: [20-05, 20-06, 20-07, 20-10]

tech-stack:
  added: []
  patterns: [portal-ssr-pattern, section-visibility-gating, budget-masking, css-custom-property-branding]

key-files:
  created:
    - web/src/app/portal/layout.tsx
    - web/src/app/portal/[slug]/page.tsx
    - web/src/app/portal/[slug]/[project]/page.tsx
    - web/src/app/components/portal/PortalShell.tsx
    - web/src/app/components/portal/PortalHeader.tsx
    - web/src/app/components/portal/PortalFooter.tsx
    - web/src/app/components/portal/SectionWrapper.tsx
    - web/src/app/components/portal/HealthBadge.tsx
    - web/src/app/components/portal/BudgetSection.tsx
    - web/src/app/components/portal/ScheduleSection.tsx
    - web/src/app/components/portal/ChangeOrdersSection.tsx
    - web/src/app/components/portal/DocumentsSection.tsx
    - web/src/app/components/portal/CookieConsent.tsx
    - web/src/app/components/portal/ExpiredPage.tsx
  modified: []

decisions:
  - "Portal SSR page uses service-role Supabase client for data access (same pattern as shared reports)"
  - "Budget masking checks both section enabled AND show_exact_amounts flag (D-30, D-38)"
  - "Promise.allSettled with 10s per-section timeout for parallel section fetching"
  - "CSS custom properties applied via inline style on PortalShell wrapper div"

self-check: PASSED
---

## Summary

Created the public-facing portal page with SSR rendering and 11 portal UI components. The portal at `/portal/[slug]/[project]` fetches live project data via service-role Supabase client, applies company branding through CSS custom properties, and renders collapsible sections in fixed order. Budget data is masked by default (percentage bars only) unless explicitly enabled. Disabled sections are never queried. Health badge shows green/yellow/red status based on project score. Expired links show branded expired pages; invalid links show generic 404 with 200ms delay. Edge cache set to 60s with 5-minute stale-while-revalidate.

## Tasks

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Create portal layout and public page with SSR + cache headers | ✓ | 86d24b0, 1b5c54e |
| 2 | Create portal shell, header, footer, section wrapper, and section components | ✓ | 1b5c54e |

## Deviations

None — all acceptance criteria verified.
