---
phase: 06-web-security-validation
plan: 01
subsystem: api
tags: [zod, csrf, hmac, webhook, paddle, validation, security]

requires:
  - phase: 02-authentication
    provides: Supabase Auth with session management and cs_user_profiles table
provides:
  - Shared Zod validation library (emailSchema, phoneSchema, leadSchema)
  - CSRF origin-checking utility (verifyCsrfOrigin)
  - Hardened /api/leads with input validation and CSRF
  - CSRF protection on all 8 mutating API routes
  - Paddle webhook with HMAC-SHA256 signature verification
  - Subscription tier upsert from Paddle events
affects: [web-testing, billing, api-routes]

tech-stack:
  added: [zod (already in deps, now actively used)]
  patterns: [CSRF origin check on all mutating routes, Zod safeParse for input validation, HMAC webhook signature verification]

key-files:
  created:
    - web/src/lib/validation.ts
    - web/src/lib/csrf.ts
  modified:
    - web/src/app/api/leads/route.ts
    - web/src/app/api/webhooks/paddle/route.ts
    - web/src/app/ai/page.tsx
    - web/src/app/api/chat/route.ts
    - web/src/app/api/projects/route.ts
    - web/src/app/api/contracts/route.ts
    - web/src/app/api/feed/route.ts
    - web/src/app/api/jobs/route.ts
    - web/src/app/api/punch/route.ts
    - web/src/app/api/tasks/route.ts

key-decisions:
  - "Used origin-based CSRF check (comparing Origin to Host header) rather than token-based CSRF -- simpler, no state needed, sufficient for API routes with auth"
  - "Paddle HMAC uses hex comparison (not base64) matching Paddle's signature format"
  - "Skipped ops route (GET-only) and billing/checkout (not yet created) for CSRF -- only routes with actual mutating handlers were modified"

patterns-established:
  - "CSRF pattern: import verifyCsrfOrigin, check before auth, return 403 on mismatch"
  - "Validation pattern: Zod safeParse with flatten().fieldErrors for structured 400 responses"
  - "Webhook pattern: req.text() for raw body, verify signature, then JSON.parse"

requirements-completed: [WEB-01, WEB-02, WEB-03, WEB-04, WEB-05]

duration: 9min
completed: 2026-04-05
---

# Phase 6 Plan 1: API Security Hardening Summary

**Zod input validation on /api/leads, CSRF origin protection on 8 mutating routes, Paddle HMAC-SHA256 webhook verification with subscription tier upsert**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-05T18:53:41Z
- **Completed:** 2026-04-05T19:02:20Z
- **Tasks:** 3
- **Files modified:** 12

## Accomplishments
- Created shared validation library with Zod schemas (email, phone, lead) and CSRF origin-checking utility
- Added CSRF origin checks to all 8 API routes with mutating handlers (POST/PATCH/DELETE)
- Rewrote Paddle webhook with HMAC-SHA256 signature verification, replay protection, and subscription tier upsert to cs_user_profiles
- Removed environment variable name from AI page client-visible fallback text

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Failing tests for validation and CSRF** - `7d91c40` (test)
2. **Task 1 GREEN: Zod validation, CSRF utility, hardened leads, sanitized AI text** - `e3c8887` (feat)
3. **Task 2: CSRF origin check on all mutating API routes** - `30b5203` (feat)
4. **Task 3: Paddle webhook HMAC verification and subscription upsert** - `5b1ceab` (feat)

## Files Created/Modified
- `web/src/lib/validation.ts` - Shared Zod schemas: emailSchema, phoneSchema, leadSchema
- `web/src/lib/csrf.ts` - Origin-checking CSRF protection utility
- `web/src/__tests__/validation.test.ts` - 12 tests for validation schemas and CSRF
- `web/src/app/api/leads/route.ts` - Zod safeParse validation + CSRF check
- `web/src/app/api/webhooks/paddle/route.ts` - HMAC-SHA256 signature verification + subscription upsert
- `web/src/app/ai/page.tsx` - Removed env var name from fallback text
- `web/src/app/api/chat/route.ts` - Added CSRF origin check
- `web/src/app/api/projects/route.ts` - Added CSRF to POST and DELETE
- `web/src/app/api/contracts/route.ts` - Added CSRF to POST
- `web/src/app/api/feed/route.ts` - Added CSRF to POST
- `web/src/app/api/jobs/route.ts` - Added CSRF to POST
- `web/src/app/api/punch/route.ts` - Added CSRF to POST and PATCH
- `web/src/app/api/tasks/route.ts` - Added CSRF to POST, PATCH, and DELETE

## Decisions Made
- Used origin-based CSRF check (comparing Origin to Host header) rather than token-based CSRF -- simpler, no state needed, sufficient for API routes with auth
- Paddle HMAC uses hex comparison (not base64) matching Paddle's signature format
- Added 5-minute timestamp replay protection on Paddle webhooks
- Skipped ops route (GET-only) and billing/checkout (not yet created) for CSRF

## Deviations from Plan

### Scope Adjustments

**1. ops route has no mutating handlers**
- **Found during:** Task 2
- **Issue:** Plan listed ops route for CSRF but it only exports GET
- **Resolution:** Skipped -- no POST/PATCH/DELETE to protect
- **Impact:** None -- GET routes don't need CSRF

**2. billing/checkout route does not exist**
- **Found during:** Task 2
- **Issue:** Plan listed billing/checkout route but directory/file doesn't exist
- **Resolution:** Skipped -- nothing to modify
- **Impact:** None -- when route is created, CSRF should be added

---

**Total deviations:** 2 scope adjustments (no auto-fixes needed)
**Impact on plan:** 8 routes protected instead of planned 10 -- the 2 missing routes either have no mutating handlers or don't exist yet. All existing mutating routes are covered.

## Issues Encountered
- Pre-existing api.test.ts failure (missing @/lib/seo module) unrelated to this plan -- not addressed per scope boundary rule

## User Setup Required

None - no external service configuration required. PADDLE_WEBHOOK_SECRET environment variable is already referenced in the existing route and should be configured in the deployment environment.

## Next Phase Readiness
- All mutating API routes now have CSRF protection
- Shared validation library ready for use by other routes
- Paddle webhook ready for production once PADDLE_WEBHOOK_SECRET is configured
- PRODUCT_TIER_MAP in paddle webhook needs to be updated with actual Paddle product IDs

## Self-Check: PASSED

All 13 created/modified files verified present. All 4 task commits verified in git log.

---
*Phase: 06-web-security-validation*
*Completed: 2026-04-05*
