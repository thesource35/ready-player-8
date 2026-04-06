---
phase: 03-row-level-security
plan: 02
subsystem: web-api
tags: [rls, ownership, defense-in-depth, security]
dependency_graph:
  requires: [03-01]
  provides: [api-ownership-checks, auth-aware-jobs]
  affects: [web/src/app/api/jobs/route.ts]
tech_stack:
  added: []
  patterns: [ownership-verified-mutations, auth-aware-queries]
key_files:
  created: []
  modified:
    - web/src/app/api/jobs/route.ts
decisions:
  - Jobs POST uses serverSupabase from loadUserProfile() instead of service role createClient
metrics:
  duration: 3m
  completed: "2026-04-06T22:28:32Z"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 03 Plan 02: API Ownership Checks and Jobs Auth-Aware Client Summary

Jobs POST handler replaced service role key with auth-aware serverSupabase client; all PATCH/DELETE ownership checks were already in place from plan 03-01.

## Task Results

| Task | Name | Status | Commit | Key Files |
|------|------|--------|--------|-----------|
| 1 | Add ownership checks to PATCH/DELETE routes | Already complete (03-01) | N/A | web/src/lib/supabase/fetch.ts, web/src/app/api/punch/route.ts, web/src/app/api/tasks/route.ts, web/src/app/api/projects/route.ts |
| 2 | Fix Jobs API to use auth-aware client | Done | 3787d85 | web/src/app/api/jobs/route.ts |

## What Changed

### Task 1: Ownership Checks (Already Complete)
Plan 03-01 already implemented all ownership checks:
- `updateOwnedRow` and `deleteOwnedRow` exported from `fetch.ts` with `.eq("user_id", userId)` filter
- `punch/route.ts` PATCH uses `updateOwnedRow` with `user.id`
- `tasks/route.ts` PATCH uses `updateOwnedRow`, DELETE uses `deleteOwnedRow`
- `projects/route.ts` DELETE uses `deleteOwnedRow`
- All routes return 404 "Not found or not owned" when row does not belong to user

### Task 2: Jobs API Auth-Aware Client
- **GET handler**: Already used `createServerSupabase()` (done in 03-01)
- **POST handler**: Replaced `createClient(url, key)` (service role) with `serverSupabase` from `loadUserProfile()` -- the auth-aware client that respects RLS
- Removed unused imports: `createClient` from `@supabase/supabase-js`, `getSupabaseServerKey` and `getSupabaseUrl` from `@/lib/supabase/env`
- Contact email still hidden for unauthenticated users (GET), fallback jobs still returned when no live data

## Deviations from Plan

### Task 1 Already Complete
- **Found during:** Task 1 verification
- **Issue:** All ownership checks (updateOwnedRow/deleteOwnedRow in fetch.ts, usage in punch/tasks/projects routes) were already implemented by plan 03-01
- **Action:** Verified completeness, no code changes needed for Task 1

## Verification Results

- `grep -rn "createClient.*getSupabaseServerKey" web/src/app/api/jobs/` -- 0 matches (PASS)
- `grep -rn "updateOwnedRow\|deleteOwnedRow" web/src/app/api/` -- matches in punch, tasks, projects (PASS)
- `grep -rn "eq.*user_id" web/src/lib/supabase/fetch.ts` -- matches in updateOwnedRow and deleteOwnedRow (PASS)
- No TypeScript errors introduced (pre-existing errors from missing node_modules only)

## Threat Mitigations Applied

| Threat ID | Status | Implementation |
|-----------|--------|----------------|
| T-03-05 | Mitigated | All PATCH/DELETE routes use .eq("user_id", userId) via updateOwnedRow/deleteOwnedRow |
| T-03-06 | Mitigated | Jobs API GET and POST both use auth-aware createServerSupabase, no service role key |
| T-03-07 | Accepted | contactEmail hidden from unauthenticated users in GET response |
| T-03-08 | Mitigated | Ownership check + RLS prevents access to other users' rows even with guessed UUIDs |

## Self-Check: PASSED

All files exist, commit 3787d85 verified.
