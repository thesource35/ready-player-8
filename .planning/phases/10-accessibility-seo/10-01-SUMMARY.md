---
phase: 10-accessibility-seo
plan: 01
subsystem: seo
tags: [metadata, sitemap, robots, opengraph, pwa, next-metadata]

requires: []
provides:
  - "SEO metadata exports on all 25 previously-missing pages via layout.tsx"
  - "Dynamic sitemap.xml generation at /sitemap.xml with 38 public routes"
  - "robots.txt generation at /robots.txt blocking /api/, /auth/, /preview/"
  - "OpenGraph image (1200x630) for social sharing"
  - "192x192 PWA icon for Add to Home Screen"
  - "getPageMetadata helper in web/src/lib/seo.ts"
affects: [accessibility-seo, web-pages]

tech-stack:
  added: [Next.js MetadataRoute API]
  patterns: [layout.tsx metadata export pattern, getPageMetadata centralized SEO]

key-files:
  created:
    - web/src/lib/seo.ts
    - web/src/app/sitemap.ts
    - web/src/app/robots.ts
    - web/public/og-image.png
    - web/public/icon-192.png
    - web/src/app/analytics/layout.tsx
    - web/src/app/clients/layout.tsx
    - web/src/app/compliance/layout.tsx
    - web/src/app/contractors/layout.tsx
    - web/src/app/cos-network/layout.tsx
    - web/src/app/electrical/layout.tsx
    - web/src/app/empire/layout.tsx
    - web/src/app/field/layout.tsx
    - web/src/app/finance/layout.tsx
    - web/src/app/hub/layout.tsx
    - web/src/app/market/layout.tsx
    - web/src/app/pricing/layout.tsx
    - web/src/app/privacy/layout.tsx
    - web/src/app/roofing/layout.tsx
    - web/src/app/scanner/layout.tsx
    - web/src/app/schedule/layout.tsx
    - web/src/app/security/layout.tsx
    - web/src/app/settings/layout.tsx
    - web/src/app/smart-build/layout.tsx
    - web/src/app/support/layout.tsx
    - web/src/app/tax/layout.tsx
    - web/src/app/tech/layout.tsx
    - web/src/app/terms/layout.tsx
    - web/src/app/training/layout.tsx
    - web/src/app/wealth/layout.tsx
  modified:
    - web/src/app/layout.tsx
    - web/public/manifest.json

key-decisions:
  - "Created seo.ts in this worktree since it did not exist at the worktree base (Rule 3 blocking dependency)"
  - "Generated OG image programmatically using pure Python PNG creation (no Pillow/ImageMagick available)"

patterns-established:
  - "layout.tsx metadata pattern: import getPageMetadata, export const metadata, passthrough Layout"
  - "Centralized SEO via seo.ts base object with OG images propagating to all pages"

requirements-completed: [SEO-01, SEO-02, SEO-03, SEO-04, SEO-05, INFRA-04]

duration: 4min
completed: 2026-04-06
---

# Phase 10 Plan 01: SEO Metadata, Sitemap, Robots, OG Image, and PWA Icon Summary

**25 page metadata layouts, dynamic sitemap/robots.txt, OpenGraph image, and 192x192 PWA icon for search discovery and social sharing**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-06T05:48:10Z
- **Completed:** 2026-04-06T05:51:44Z
- **Tasks:** 3
- **Files modified:** 33

## Accomplishments
- All 25 missing pages now export SEO metadata (title, description, openGraph) via layout.tsx
- Dynamic sitemap.xml serves 38 public routes, excluding private paths
- robots.txt blocks crawlers from /api/, /auth/, /preview/
- 1200x630 OG image created for social sharing across all pages
- 192x192 PWA icon generated and added to manifest.json

## Task Commits

Each task was committed atomically:

1. **Task 1: Create metadata layout.tsx for all 25 missing pages** - `8bf2484` (feat)
2. **Task 2: Add sitemap.ts, robots.ts, OG image reference, and OG image file** - `5ad97a9` (feat)
3. **Task 3: Add 192x192 PWA icon to manifest and generate icon file** - `587221d` (feat)

## Files Created/Modified
- `web/src/lib/seo.ts` - Centralized SEO metadata with getPageMetadata helper and OG image base config
- `web/src/app/*/layout.tsx` (x25) - Per-page metadata exports using getPageMetadata
- `web/src/app/sitemap.ts` - Dynamic sitemap generation with 38 public routes
- `web/src/app/robots.ts` - Robots.txt with allow/disallow rules
- `web/public/og-image.png` - 1200x630 OG image with COS branding
- `web/public/icon-192.png` - 192x192 PWA icon resized from logo.png
- `web/src/app/layout.tsx` - Added OG images to openGraph and twitter metadata
- `web/public/manifest.json` - Added 192x192 icon entry

## Decisions Made
- Created seo.ts from the main repo version since it did not exist at the worktree base commit (Rule 3 - blocking dependency for all layout.tsx imports)
- Generated OG image programmatically with pure Python (struct/zlib) since Pillow and ImageMagick were unavailable
- Used sips (macOS built-in) to resize logo.png to 192x192 for the PWA icon

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created seo.ts missing from worktree base**
- **Found during:** Task 1 (layout.tsx creation)
- **Issue:** web/src/lib/seo.ts did not exist in this worktree (exists in main repo from another branch). All 25 layout.tsx files import from it.
- **Fix:** Created seo.ts matching the main repo version with all page metadata entries
- **Files modified:** web/src/lib/seo.ts
- **Verification:** All layout files can resolve their import
- **Committed in:** 8bf2484 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential for Task 1 to function. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All SEO infrastructure in place for search engine discovery
- Social sharing will show branded OG image
- PWA installation has proper icon
- Ready for remaining accessibility and SEO plans in Phase 10

## Self-Check: PASSED

All 9 key files verified present. All 3 task commits verified in git log.
