---
phase: 12-web-tests
plan: 01
subsystem: testing
tags: [vitest, unit-tests, api-routes, middleware, rate-limit, csrf, auth]

requires:
  - phase: 09-web-security
    provides: rate-limit, csrf, validation libraries tested here
provides:
  - Chat API route test suite (7 cases)
  - Leads API route test suite (7 cases)
  - Auth middleware test suite (10 cases)
affects: [12-web-tests]

tech-stack:
  added: []
  patterns: [vi.hoisted for mock references in factory functions, vi.stubEnv for env var testing]

key-files:
  created:
    - web/src/app/api/chat/route.test.ts
    - web/src/app/api/leads/route.test.ts
    - web/src/middleware.test.ts
  modified: []

key-decisions:
  - "Used vi.hoisted() pattern for Supabase mock chain to avoid hoisting reference errors"
  - "Reset mocks via vi.clearAllMocks() in afterEach rather than vi.restoreAllMocks() to preserve mock factories"

patterns-established:
  - "API route test pattern: vi.mock modules at top, helper makeRequest(), beforeEach stubs env + resets mocks"
  - "Middleware test pattern: makeFakeJWT helper for JWT fast-path testing, NextRequest construction with cookies"

requirements-completed: [WTEST-01, WTEST-02, WTEST-03]

duration: 7min
completed: 2026-04-06
---

# Phase 12 Plan 01: Web API and Middleware Unit Tests Summary

**24 Vitest unit tests covering Chat API (7), Leads API (7), and auth middleware (10) with full mock isolation for rate limiting, CSRF, Supabase, and AI SDK**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-06T15:45:22Z
- **Completed:** 2026-04-06T15:52:21Z
- **Tasks:** 3/3
- **Files created:** 3

## Accomplishments
- Chat API route fully tested: streaming success, missing key 503, rate limit 429, CSRF 403, invalid body 400, missing messages 400, AI error 502
- Leads API route fully tested: valid submission 200, invalid email 400, missing fields 400, rate limit 429, CSRF 403, no Supabase 503, insert error 500
- Auth middleware fully tested: public routes, static files, API rate limiting, JWT fast-path, expired JWT fallback, no-session redirect, demo mode

## Task Commits

Each task was committed atomically:

1. **Task 1: Chat API route unit tests** - `25cced6` (test)
2. **Task 2: Leads API route unit tests** - `474d820` (test)
3. **Task 3: Auth middleware unit tests** - `571740c` (test)

## Files Created/Modified
- `web/src/app/api/chat/route.test.ts` - 7 test cases for Chat API POST handler
- `web/src/app/api/leads/route.test.ts` - 7 test cases for Leads API POST handler
- `web/src/middleware.test.ts` - 10 test cases for auth/rate-limit middleware

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed mock persistence across tests causing rate limit 429**
- **Found during:** Task 1
- **Issue:** `checkRateLimit` used real in-memory store; first test consumed rate limit slots, causing subsequent tests to get 429
- **Fix:** Added explicit `vi.mocked(checkRateLimit).mockReturnValue(true)` in beforeEach and switched from `vi.restoreAllMocks()` to `vi.clearAllMocks()`
- **Files modified:** web/src/app/api/chat/route.test.ts
- **Commit:** 25cced6

**2. [Rule 3 - Blocking] Fixed vi.mock hoisting error with mockSingle reference**
- **Found during:** Task 2
- **Issue:** `vi.mock` factory referenced `mockSingle` variable declared before it, but `vi.mock` is hoisted above variable declarations
- **Fix:** Used `vi.hoisted()` to declare `mockSingle` in a hoisted scope accessible to mock factories
- **Files modified:** web/src/app/api/leads/route.test.ts
- **Commit:** 474d820

## Self-Check: PASSED
