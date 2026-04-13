---
phase: 20-client-portal-sharing
verified: 2026-04-13T14:05:00Z
status: human_needed
score: 4/4 must-haves verified
gaps: []
human_verification:
  - test: "Open a portal URL in a browser and verify branded header, health badge, collapsible sections, and cookie consent banner render correctly"
    expected: "Branded portal page with company logo, project name, section anchors, health badge, and collapsible sections with live Supabase data"
    why_human: "Visual rendering, layout correctness, and branding application cannot be verified programmatically"
  - test: "Create a portal link from /portals page, select a template, set expiry, and verify the URL is copied to clipboard"
    expected: "Portal link created successfully, URL copied, toast notification shown, link appears in management table"
    why_human: "End-to-end user flow involving clipboard, toast UI, and dialog interaction requires visual verification"
  - test: "Open portal on mobile viewport (375px) and verify bottom navigation, 2-column photo grid, and section stacking"
    expected: "Mobile bottom nav visible, sections stack vertically, photos in 2-column grid, swipe navigation works"
    why_human: "Responsive layout and touch interactions cannot be verified without a browser"
  - test: "Edit company branding at /settings/branding -- change colors, upload logo, verify contrast warning on bad color pair"
    expected: "Theme editor loads with color pickers, preset themes, logo upload. Low-contrast color pair shows warning text."
    why_human: "Visual UI for color pickers, drag-and-drop upload, and contrast warning display requires human eyes"
  - test: "Open an invalid portal URL like /portal/nonexistent/nonexistent and verify 404 page renders"
    expected: "Generic 'Page not found' message after brief delay (200ms enumeration protection)"
    why_human: "Visual confirmation of error page styling and timing behavior"
---

# Phase 20: Client Portal & Sharing Verification Report

**Phase Goal:** Users can share a branded read-only project view with clients
**Verified:** 2026-04-13T14:05:00Z
**Status:** human_needed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can generate a shareable read-only URL for a project | VERIFIED | `web/src/app/api/portal/create/route.ts` exports POST handler, imports `createPortalLink` from portalQueries which uses `crypto.randomUUID()` for token generation. Management page at `/portals` calls this API. iOS `PortalShareSheet.swift` also creates links via SupabaseService. |
| 2 | User can configure portal section visibility (budget, schedule, photos) | VERIFIED | `SectionVisibilityEditor.tsx` (360 lines) provides toggle grid for 5 sections with SECTION_ORDER. Portal SSR page at `[slug]/[project]/page.tsx` conditionally queries only enabled sections (lines 341-379). Budget defaults to disabled in all TEMPLATE_DEFAULTS. `shouldShowAmounts()` gates dollar values. |
| 3 | Client viewers see a chronological progress photo timeline | VERIFIED | `PhotoTimeline.tsx` uses `groupPhotosByDate()` from photoHelpers.ts for vertical chronological layout. `PhotoLightbox.tsx` provides fullscreen view with swipe/zoom. `PhotoCard.tsx` shows captions, GPS location, annotation badges. API at `/api/portal/photos/route.ts` provides paginated data. Download route strips EXIF GPS. |
| 4 | Portal page displays the company's logo and brand colors | VERIFIED | `PortalShell.tsx` applies branding via CSS custom properties (`--portal-primary`, etc.) from CompanyBranding data. `PortalHeader.tsx` renders company logo. `ThemeEditor.tsx` provides full brand customization with 5 preset themes. `contrastValidator.ts` validates WCAG AA 4.5:1 ratio. Branding settings at `/settings/branding`. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `web/src/lib/portal/types.ts` | Portal type definitions | VERIFIED | 162 lines, exports PortalConfig, CompanyBranding, PortalSectionsConfig, TEMPLATE_DEFAULTS, SECTION_ORDER, PORTAL_RATE_LIMITS |
| `web/src/lib/design-tokens.ts` | Design token system | VERIFIED | 156 lines, exports tokens and portalPresetThemes |
| `web/src/lib/portal/portalQueries.ts` | Portal CRUD functions | VERIFIED | 423 lines, exports createPortalLink, getPortalBySlug, getPortalByToken, updatePortalConfig, revokePortalLink, deletePortalLink, listPortalLinks |
| `web/src/lib/portal/brandingQueries.ts` | Branding CRUD functions | VERIFIED | 207 lines, exports getCompanyBranding, upsertCompanyBranding, getPortalBrandingOverride, getBrandingForPortal |
| `web/src/lib/portal/analyticsQueries.ts` | Analytics functions | VERIFIED | 220 lines, exports recordPortalView, getPortalAnalytics, getPortalViewCount |
| `web/src/lib/portal/cssSanitizer.ts` | CSS sanitization | VERIFIED | 119 lines, exports sanitizePortalCSS with FORBIDDEN_CSS_PATTERNS and ALLOWED_PROPERTIES |
| `web/src/lib/portal/imageProcessor.ts` | Image processing | VERIFIED | 261 lines, exports processUploadedImage, validateImageUpload, stripSensitiveExif, validateSVG |
| `web/src/lib/portal/contrastValidator.ts` | WCAG contrast validation | VERIFIED | 95 lines, exports checkContrastRatio, getContrastWarning with 4.5:1 threshold |
| `web/src/app/portal/[slug]/[project]/page.tsx` | Public portal SSR page | VERIFIED | 540 lines, service-role Supabase client, section-gated queries, budget masking, 200ms delay on 404 |
| `web/src/app/portal/layout.tsx` | Portal layout with noindex | VERIFIED | Contains `<meta name="robots" content="noindex, nofollow" />` |
| `web/src/app/components/portal/PortalShell.tsx` | Portal wrapper with branding | VERIFIED | 302 lines, applies CSS custom properties from CompanyBranding |
| `web/src/app/portals/page.tsx` | Portal management dashboard | VERIFIED | 344 lines, authenticated page with create dialog and link table |
| `web/src/app/settings/branding/page.tsx` | Branding settings page | VERIFIED | 449 lines, theme editor with save/export/import/reset |
| `web/src/app/api/portal/create/route.ts` | Portal creation endpoint | VERIFIED | Exports POST, imports createPortalLink, uses rateLimit and getAuthenticatedClient |
| `web/src/app/api/portal/[id]/config/route.ts` | Config management | VERIFIED | Exports GET and PUT handlers |
| `web/src/app/api/portal/[id]/revoke/route.ts` | Revocation endpoint | VERIFIED | Exports POST handler |
| `web/src/app/api/portal/branding/route.ts` | Branding API | VERIFIED | Exports GET and PUT handlers |
| `web/src/app/api/portal/branding/upload/route.ts` | Image upload | VERIFIED | Exports POST handler |
| `web/src/app/api/portal/analytics/route.ts` | Analytics API | VERIFIED | Exports GET handler |
| `web/src/app/api/portal/preview/route.ts` | Preview API | VERIFIED | Exports GET handler |
| `web/src/app/api/portal/photos/route.ts` | Photo data API | VERIFIED | Exports GET with pagination |
| `web/src/app/api/portal/photos/download/route.ts` | Photo download | VERIFIED | Exports GET with EXIF stripping |
| `web/src/app/api/portal/[id]/audit/route.ts` | Audit log API | VERIFIED | Exports GET handler |
| `web/src/app/api/portal/list/route.ts` | Portal list API | VERIFIED | Added during Plan 06 execution |
| `.planning/phases/20-client-portal-sharing/migrations/001_portal_schema.sql` | Database schema | VERIFIED | Creates cs_portal_config, cs_company_branding, cs_portal_analytics, cs_portal_audit_log with RLS |
| Portal UI components (27 files) | Section components, header, footer, etc. | VERIFIED | All 27 .tsx files present in web/src/app/components/portal/ |
| `ready player 8/Portal/` iOS views (4 files) | iOS portal management | VERIFIED | PortalManagementView, PortalConfigView, PortalShareSheet, CompanyBrandingView all present |
| `ready player 8/SupabaseService.swift` | Portal DTOs and CRUD | VERIFIED | Contains SupabasePortalConfig, SupabaseCompanyBranding structs and createPortalLink, fetchPortalLinks methods |
| `web/e2e/portal.spec.ts` | E2E tests | VERIFIED | Playwright test file present |
| `ready player 8Tests/PortalTests/PortalTests.swift` | iOS XCTests | VERIFIED | XCTest file present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| portal create route | portalQueries.ts | `import { createPortalLink }` | WIRED | Line 4 of create/route.ts |
| portal SSR page | analyticsQueries.ts | `import { recordPortalView }` | WIRED | Line 4 of page.tsx |
| portal SSR page | brandingQueries.ts | `import { getBrandingForPortal, getCompanyBranding }` | WIRED | Line 3 of page.tsx |
| portal SSR page | PortalShell component | `import PortalShell` | WIRED | Line 15 of page.tsx |
| PortalShell | CompanyBranding type | CSS custom properties applied | WIRED | --portal-primary etc. at line 82 |
| portals management page | /api/portal/create | `fetch("/api/portal/create"` | WIRED | Line 30 and 125 of portals/page.tsx |
| PortalCreateDialog | /api/portal/create | `fetch("/api/portal/create"` | WIRED | Line 125 |
| iOS PortalManagementView | SupabaseService | `SupabaseService.shared` | WIRED | Line 17 |
| ThemeEditor | contrastValidator | `import { checkContrastRatio }` | WIRED | Confirmed in ThemeEditor.tsx |
| cssSanitizer tests | cssSanitizer module | `import { sanitizePortalCSS }` | WIRED | Tests import and test the real function |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| portal/[slug]/[project]/page.tsx | portalConfig, sectionData | Supabase service-role client queries cs_portal_config, cs_projects, cs_documents | Yes -- real DB queries with `.from().select().eq()` | FLOWING |
| PortalShell.tsx | branding, sections | Props from SSR page (passed from Supabase query results) | Yes -- data flows from page.tsx queries | FLOWING |
| portals/page.tsx | portalLinks | fetch("/api/portal/list") -> portalQueries.listPortalLinks() -> Supabase | Yes -- authenticated Supabase query | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Portal tests pass | `npx vitest run src/lib/portal/__tests__/` | 87 passed (87), 8 files, 0 failures | PASS |
| No test stubs remaining | grep for it.todo | 0 matches across all test files | PASS |
| No TODO/FIXME in portal lib | grep for TODO/FIXME | 0 matches in web/src/lib/portal/ | PASS |
| No TODO/FIXME in portal components | grep for TODO/FIXME | 0 matches (only "placeholder" in input placeholder attrs) | PASS |
| TypeScript portal types exported | types.ts has PortalConfig, CompanyBranding, TEMPLATE_DEFAULTS | All present | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PORTAL-01 | Plans 01-10 | User can generate a shareable read-only project URL | SATISFIED | Create API route, portalQueries.createPortalLink with crypto.randomUUID(), management UI, iOS share sheet |
| PORTAL-02 | Plans 01-10 | User can configure portal visibility per section | SATISFIED | SectionVisibilityEditor, TEMPLATE_DEFAULTS, shouldShowAmounts(), portal SSR only queries enabled sections |
| PORTAL-03 | Plans 01, 05, 09, 10 | Client viewers see a progress photo timeline | SATISFIED | PhotoTimeline, PhotoCard, PhotoLightbox, DateFilter, photo API with pagination, EXIF stripping |
| PORTAL-04 | Plans 01-10 | Portal page displays company branding (logo, colors) | SATISFIED | PortalShell CSS custom properties, ThemeEditor, 5 preset themes, contrastValidator, branding settings page |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | - | - | - | No blocking anti-patterns detected |

### Human Verification Required

### 1. Portal Rendering and Branding
**Test:** Open a portal URL in browser and verify branded layout
**Expected:** Branded header with logo, health badge, collapsible sections, cookie consent banner
**Why human:** Visual rendering and branding CSS application cannot be verified programmatically

### 2. Portal Creation Flow
**Test:** Create portal link from /portals page with template selection and expiry
**Expected:** Link created, URL copied to clipboard, toast shown, link in management table
**Why human:** End-to-end user flow with clipboard, dialog, and toast requires visual confirmation

### 3. Mobile Responsive Layout
**Test:** Open portal on 375px viewport, verify bottom nav and 2-column photo grid
**Expected:** Mobile bottom nav visible, sections stack vertically, swipe navigation works
**Why human:** Responsive layout and touch interactions require a browser

### 4. Branding Theme Editor
**Test:** Edit company branding at /settings/branding, change colors, upload logo, test contrast warning
**Expected:** Color pickers, preset themes, logo upload, WCAG contrast warning on bad pairs
**Why human:** Visual UI elements like color pickers and drag-and-drop cannot be verified programmatically

### 5. Error Pages
**Test:** Open /portal/nonexistent/nonexistent
**Expected:** Generic "Page not found" after 200ms delay
**Why human:** Visual confirmation of error page and timing

### Gaps Summary

No gaps found. All 4 roadmap success criteria are verified at the code level:

1. **Shareable read-only URL** -- Complete API layer (create, config, revoke, preview, analytics, list), management UI, iOS views
2. **Section visibility configuration** -- SectionVisibilityEditor with 5 toggles, template defaults, budget masking, server-side section gating
3. **Photo timeline** -- Vertical chronological timeline with lazy loading, lightbox, date filter, EXIF stripping, ZIP download
4. **Company branding** -- Full theme editor with 5 presets, WCAG contrast validation, logo upload, custom CSS, branded emails

Additionally: 87 passing unit tests, E2E Playwright tests, iOS XCTests, SQL schema with RLS, audit logging, IP blocking, PDF export, and webhook events.

Status is human_needed because visual rendering, responsive layout, and end-to-end user flows require browser-based verification.

---

_Verified: 2026-04-13T14:05:00Z_
_Verifier: Claude (gsd-verifier)_
