---
phase: 09-web-performance-dynamic-content
plan: 01
subsystem: api
tags: [upstash, redis, rate-limiting, jwt, middleware, performance]

# Dependency graph
requires: []
provides:
  - "Dual-mode rate limiter (Upstash Redis + in-memory fallback)"
  - "Middleware-level rate limiting for all /api/* routes with standard headers"
  - "JWT fast-path session validation without DB round-trip"
affects: [11-testing, 09-web-performance-dynamic-content]

# Tech tracking
tech-stack:
  added: ["@upstash/ratelimit", "@upstash/redis"]
  patterns: ["dual-mode service (cloud primary, local fallback)", "JWT decode fast-path with full-auth fallback", "per-route rate limit config"]

key-files:
  created: []
  modified:
    - web/src/lib/rate-limit.ts
    - web/src/middleware.ts
    - web/src/app/api/chat/route.ts
    - web/src/app/api/leads/route.ts
    - web/package.json

key-decisions:
  - "Cached Upstash Ratelimit instances per unique config to avoid re-creating on every request"
  - "Used x-forwarded-for + x-real-ip for IP identification (no request.ip in Next.js 16 types)"
  - "JWT decode is fast-path only; getUser() fallback preserved for token refresh and expired tokens"
  - "Kept backward-compatible checkRateLimit and getLegacyRateLimitHeaders exports for existing route consumers"

patterns-established:
  - "Dual-mode pattern: check env vars to select cloud vs local implementation with identical interface"
  - "Per-route rate limit config via ROUTE_LIMITS map with startsWith matching"
  - "JWT fast-path in middleware: decode cookie, check expiry with 60s buffer, skip DB call when valid"

requirements-completed: [PERF-01, PERF-06, PERF-07]

# Metrics
duration: 6min
completed: 2026-04-06
---

# Phase 9 Plan 1: Rate Limiting & JWT Session Validation Summary

**Upstash Redis dual-mode rate limiter with per-route config in middleware and JWT decode fast-path for session validation**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-06T02:11:23Z
- **Completed:** 2026-04-06T02:17:25Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Dual-mode rate limiter: Upstash Redis for distributed production use, in-memory Map fallback for dev/single-instance
- Per-route rate limit config: /api/chat (10/min), /api/leads (5/min), /api/export (3/min), default (30/min)
- All /api/* requests now pass through middleware rate limiting with X-RateLimit-Limit/Remaining/Reset headers
- JWT decode fast-path eliminates getUser() DB round-trip for valid, non-expired sessions
- Backward-compatible exports preserved so existing chat and leads routes continue working

## Task Commits

Each task was committed atomically:

1. **Task 1: Install Upstash packages and refactor rate-limit.ts to dual-mode** - `9c6cc0e` (feat)
2. **Task 2: Wire rate limiting into middleware and add JWT session validation** - `0554df0` (feat)

## Files Created/Modified
- `web/src/lib/rate-limit.ts` - Dual-mode rate limiter with Upstash Redis primary, in-memory fallback, per-route config
- `web/src/middleware.ts` - Rate limiting on /api/* routes, JWT decode fast-path, getUser() fallback
- `web/src/app/api/chat/route.ts` - Updated import to use getLegacyRateLimitHeaders
- `web/src/app/api/leads/route.ts` - Updated import to use getLegacyRateLimitHeaders
- `web/package.json` - Added @upstash/ratelimit and @upstash/redis dependencies

## Decisions Made
- Cached Upstash Ratelimit instances per unique route config key to avoid creating new Redis connections on every request
- Used x-forwarded-for and x-real-ip headers instead of request.ip (not available in Next.js 16 types)
- JWT decode uses 60-second buffer before expiry to avoid race conditions with token refresh
- Renamed old getRateLimitHeaders to getLegacyRateLimitHeaders to avoid signature collision with new version

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed getRateLimitHeaders signature collision breaking existing consumers**
- **Found during:** Task 1 (rate-limit.ts refactor)
- **Issue:** New getRateLimitHeaders(result) signature conflicted with old getRateLimitHeaders(ip, limit) used by chat and leads routes, causing TS2554 errors
- **Fix:** Renamed old function to getLegacyRateLimitHeaders and updated imports in chat/route.ts and leads/route.ts
- **Files modified:** web/src/lib/rate-limit.ts, web/src/app/api/chat/route.ts, web/src/app/api/leads/route.ts
- **Verification:** npx tsc --noEmit shows zero rate-limit related errors
- **Committed in:** 9c6cc0e (Task 1 commit)

**2. [Rule 1 - Bug] Fixed request.ip type error in middleware**
- **Found during:** Task 2 (middleware refactor)
- **Issue:** request.ip property does not exist on NextRequest in Next.js 16 types
- **Fix:** Replaced request.ip with request.headers.get("x-real-ip") as fallback after x-forwarded-for
- **Files modified:** web/src/middleware.ts
- **Verification:** npx tsc --noEmit shows zero middleware errors
- **Committed in:** 0554df0 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes necessary for TypeScript compilation. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required

For production distributed rate limiting, set these environment variables:
- `UPSTASH_REDIS_REST_URL` - Upstash Redis REST API URL
- `UPSTASH_REDIS_REST_TOKEN` - Upstash Redis REST API token

Without these, the rate limiter falls back to in-memory mode (suitable for development).

## Next Phase Readiness
- Rate limiting infrastructure ready for all current and future /api/* routes
- JWT fast-path reduces latency on every authenticated page load
- Existing route-level rate limiting in chat and leads still works (backward compatible)

## Self-Check: PASSED

All 6 files verified present. Both task commits (9c6cc0e, 0554df0) confirmed in git log.

---
*Phase: 09-web-performance-dynamic-content*
*Completed: 2026-04-06*
