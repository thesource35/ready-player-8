---
phase: quick
plan: 01
subsystem: web
tags: [typescript, rate-limiting, security, auth, types]
dependency_graph:
  requires: []
  provides: [clean-tsc, csrf-billing, auth-layout]
  affects: [web/src/lib/supabase/types.ts, web/src/app/api/*, web/src/app/layout.tsx, web/next.config.ts]
tech_stack:
  added: ["@upstash/ratelimit", "@upstash/redis", "vitest"]
  patterns: [middleware-rate-limiting, csrf-origin-check, auth-gate]
key_files:
  created:
    - web/src/lib/mock-data.ts
    - web/src/lib/nav.ts
    - web/src/lib/rate-limit.ts
    - web/src/lib/supabase/fetch.ts
    - web/src/lib/supabase/env.ts
    - web/src/lib/csrf.ts
    - web/src/lib/validation.ts
    - web/src/lib/billing/plans.ts
    - web/src/lib/billing/square.ts
    - web/src/lib/links/externalLinks.ts
    - web/src/lib/links/linkHealth.ts
    - web/src/app/components/NavAuthLinks.tsx
    - web/src/app/api/contracts/route.ts
    - web/src/app/api/feed/route.ts
    - web/src/app/api/projects/route.ts
    - web/src/app/api/tasks/route.ts
    - web/src/app/api/punch/route.ts
    - web/src/app/api/ops/route.ts
    - web/src/app/api/link-health/route.ts
    - web/src/app/api/billing/checkout/route.ts
  modified:
    - web/src/lib/supabase/types.ts
    - web/src/app/api/chat/route.ts
    - web/src/app/api/leads/route.ts
    - web/src/app/api/chat/route.test.ts
    - web/src/app/api/leads/route.test.ts
    - web/src/app/layout.tsx
    - web/next.config.ts
    - web/package.json
decisions:
  - "Changed Project.score from string to number to match actual data usage"
  - "Added start_date and end_date optional fields to Project type for mock data compatibility"
  - "Kept legacy checkRateLimit/getLegacyRateLimitHeaders exports in rate-limit.ts for backward compatibility but removed all route-level usage"
metrics:
  duration_seconds: 1472
  completed: "2026-04-06T23:50:00Z"
  tasks_completed: 3
  tasks_total: 3
  files_changed: 26
---

# Quick Task 260406-rcz: Fix All 8 Partial Requirements and TypeScript Errors

Zero TypeScript errors achieved by fixing type mismatches (Project.score string->number, missing user_id fields, missing OpsAlert/Rfi/ChangeOrder exports), removing invalid Next.js 16 eslint config, fixing AI SDK maxTokens->maxOutputTokens rename, installing missing dependencies, and tracking untracked source files. Legacy per-route checkRateLimit removed from all 9 API routes (middleware handles rate limiting). Billing checkout secured with CSRF + auth. Layout now uses auth-aware NavAuthLinks component.

## Task Results

### Task 1: Fix all TypeScript type errors and config
**Commit:** d91cb98
**Result:** `npx tsc --noEmit` passes with zero errors (was 34+ errors).

Changes:
- `types.ts`: Project.score string->number, added user_id to Project/Contract/FeedPost/PunchItem, added start_date/end_date to Project, exported OpsAlert/Rfi/ChangeOrder interfaces
- `chat/route.ts`: maxTokens -> maxOutputTokens (AI SDK rename)
- `next.config.ts`: removed invalid eslint block (not in NextConfig for Next.js 16)
- `projects/route.ts`: score assignment updated for number type
- Installed @upstash/ratelimit, @upstash/redis, vitest
- Tracked 20+ untracked source files (mock-data, nav, route files, lib modules)

### Task 2: Remove legacy rate limiting and add billing security
**Commit:** de0372e
**Result:** Zero route files import checkRateLimit. Billing checkout has CSRF + auth. All 12 tests pass.

Changes:
- Removed checkRateLimit import + usage from: contracts, feed, projects, tasks, punch, ops, link-health, chat, leads routes
- Added verifyCsrfOrigin + createServerSupabase auth check to billing/checkout POST
- Updated chat and leads test files: removed rate-limit mocks and 429 test cases
- Added Zod validation to leads route

### Task 3: Wire NavAuthLinks into layout and track nav.ts
**Commit:** b724f42
**Result:** layout.tsx imports and renders NavAuthLinks. nav.ts is git-tracked.

Changes:
- Replaced static sign-in/get-started links with NavAuthLinks component
- NavAuthLinks captures redirect URL and uses Next.js Link components

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] Added start_date/end_date to Project type**
- **Found during:** Task 1
- **Issue:** mock-data.ts uses start_date and end_date on Project objects, but these fields were not in the type definition, causing TS errors
- **Fix:** Added start_date?: string and end_date?: string optional fields to Project interface
- **Files modified:** web/src/lib/supabase/types.ts
- **Commit:** d91cb98

**2. [Rule 3 - Blocking] Missing lib modules and route files in worktree**
- **Found during:** Task 1
- **Issue:** Worktree was based on earlier commit missing many files that existed in the main repo (rate-limit.ts, fetch.ts, csrf.ts, validation.ts, billing/plans.ts, etc.)
- **Fix:** Copied all missing source files from main repo to worktree and tracked them
- **Files modified:** 20+ files
- **Commit:** d91cb98

**3. [Rule 3 - Blocking] Missing npm dependencies**
- **Found during:** Task 1
- **Issue:** @upstash/ratelimit, @upstash/redis not in package.json; vitest not installed in worktree
- **Fix:** Installed all three packages
- **Files modified:** web/package.json, web/package-lock.json
- **Commit:** d91cb98

**4. [Rule 2 - Missing] Added Zod validation to leads route**
- **Found during:** Task 2
- **Issue:** Updated leads route needed validation via leadSchema (imported from @/lib/validation) to maintain the validation that was part of the refactored version
- **Fix:** Wrote leads route with leadSchema validation and CSRF check, without legacy rate limiting
- **Files modified:** web/src/app/api/leads/route.ts
- **Commit:** de0372e

## Verification Results

| Check | Result |
|-------|--------|
| `npx tsc --noEmit` | PASS (0 errors) |
| `npx vitest run` | PASS (12 tests, 2 files) |
| checkRateLimit in routes | 0 occurrences |
| billing CSRF check | Present |
| billing auth check | Present |
| NavAuthLinks in layout | Imported + rendered |
| nav.ts tracked | Yes |

## Self-Check: PASSED
