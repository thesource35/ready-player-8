---
phase: 15
plan: 03
subsystem: web-team-crew
tags: [web, nextjs, team, crew, zod, vitest]
requires: [15-01]
provides: [web-team-ui, web-team-api, team-schemas]
affects: [web/src/app/team, web/src/app/api/team, web/src/app/projects/[id]]
tech-stack:
  added: [zod schemas for team routes]
  patterns: [createServerSupabase + zod safeParse, Next 16 async params, shared schema module]
key-files:
  created:
    - web/src/lib/team/trades.ts
    - web/src/lib/team/schemas.ts
    - web/src/app/api/team/route.ts
    - web/src/app/api/team/assignments/route.ts
    - web/src/app/api/team/certifications/route.ts
    - web/src/app/api/projects/[id]/daily-crew/route.ts
    - web/src/app/team/page.tsx
    - web/src/app/team/assignments/page.tsx
    - web/src/app/team/certifications/page.tsx
    - web/src/app/projects/[id]/DailyCrewSection.tsx
  modified:
    - web/src/lib/supabase/types.ts
    - web/src/lib/team/__tests__/team.test.ts
decisions:
  - Shared zod schemas extracted to web/src/lib/team/schemas.ts so route handlers and vitest tests import the same source of truth
  - Schema-level tests (no Supabase mocking) — zod validates the trust boundary directly
metrics:
  duration: resumed across sessions
  completed: 2026-04-07
---

# Phase 15 Plan 03: Web Team & Crew Management Summary

Wave 2 web parity for Phase 15 — builds `/team` (Members, Assignments, Certifications), four mutation API routes with zod validation, per-project Daily Crew section, and a real vitest suite replacing Wave 0 `it.todo` stubs. Implements TEAM-01, TEAM-02, TEAM-03, TEAM-05 on web.

## Tasks Completed

### Task 1: Types + TRADES + 4 API routes (commit a205ad4e)
- Appended `TeamMember`, `ProjectAssignment`, `Certification`, `DailyCrew` types to `web/src/lib/supabase/types.ts`.
- Created `web/src/lib/team/trades.ts` with canonical `TRADES` and `CERT_NAMES` constants.
- Created `web/src/lib/team/schemas.ts` with shared zod schemas (`memberSchema`, `assignmentSchema`, `certSchema`, `dailyCrewSchema`).
- Created four API routes, each gated on `supabase.auth.getUser()` with 401 on anonymous, 400 on invalid JSON, 400 on zod failure, 500 on DB error:
  - `POST/GET/PATCH/DELETE /api/team`
  - `POST /api/team/assignments` (returns 409 on Postgres 23505 unique violation)
  - `POST /api/team/certifications` (accepts optional `document_id` FK to `cs_documents`)
  - `POST/GET /api/projects/[id]/daily-crew` (upsert on `project_id,assignment_date`)
- Next 16 async params honored (`params: Promise<{ id: string }>` then `await params`).

### Task 2: `/team` sub-views + DailyCrewSection (commit a205ad4e)
- `web/src/app/team/page.tsx` — server component, reads `cs_team_members`, renders Members table.
- `web/src/app/team/assignments/page.tsx` — reads `cs_project_assignments` with joins to team members + projects.
- `web/src/app/team/certifications/page.tsx` — reads `cs_certifications` with color-coded expiry (red < today, amber < +30d).
- `web/src/app/projects/[id]/DailyCrewSection.tsx` — client component mounted on project detail page; GET/POST daily crew with member checkboxes + notes + date picker.

### Task 3: Real vitest tests (commit b980f82)
Replaced six `it.todo` stubs with **20 concrete schema assertions**:

- **TEAM-01 (6 tests)**: rejects empty name, rejects whitespace-only name, rejects invalid kind enum, accepts internal member with trade/role, accepts subcontractor with company/email, rejects malformed email.
- **TEAM-02 (5 tests)**: requires uuid project_id, requires uuid member_id, defaults status to "active", rejects invalid status, rejects malformed start_date.
- **TEAM-03 (5 tests)**: rejects bad expires_at format, accepts optional document_id uuid FK, rejects non-uuid document_id, accepts cert without document_id, rejects empty cert name.
- **TEAM-05 (4 tests)**: requires YYYY-MM-DD assignment_date, defaults member_ids to [], accepts full payload, rejects non-uuid member id.

Tests target the shared schemas directly — no Supabase mocking needed since zod is the trust boundary enforced by the route handlers.

## Verification

```
cd web && npm test -- --run
 Test Files  18 passed (18)
      Tests  132 passed | 6 todo (138)
```

Lint clean on the modified test file (`npx eslint src/lib/team/__tests__/team.test.ts` — no output). Repo-wide `npm run lint` shows pre-existing warnings/errors in unrelated files (`useFetch.ts`, `middleware.test.ts`, etc.) — out of scope for this plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UUID literals must pass zod uuid validation**
- **Found during:** Task 3 test run
- **Issue:** Initial test constants used `00000000-0000-0000-0000-000000000000` and `11111111-1111-1111-1111-111111111111`, which zod's `z.string().uuid()` rejects because the version nibble must be 1-5 and the variant nibble must be 8-b.
- **Fix:** Replaced with valid v4 UUIDs (`a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d`, `f1e2d3c4-b5a6-4978-8b6c-5d4e3f2a1b0c`).
- **Files modified:** web/src/lib/team/__tests__/team.test.ts
- **Commit:** b980f82

No other deviations. Task 1 and Task 2 had already been committed as a205ad4e in a prior session — resumed here to land Task 3 only.

## Deferred / Out of Scope

- **Live `supabase db push`** for Phase 15 migrations is deferred at the phase level due to the Phase 13 drift blocker documented in STATE.md. Schema changes from 15-01 still need to be applied to the live Supabase project before these routes will function against real data.
- **Route-level integration tests** (mocking `createServerSupabase`) deferred — schema tests cover the validation trust boundary, which is the STRIDE-mitigated surface (T-15-10, T-15-13). Auth gate (T-15-11) and unique-violation handling are straightforward enough to defer until a broader route-test harness is introduced.
- Pre-existing repo-wide lint issues (`useFetch.ts` set-state-in-effect, unused `_url` in `middleware.test.ts`, etc.) untouched — unrelated to this plan.

## Commits

- `a205ad4e` — Task 1 + Task 2 (types, TRADES, 4 API routes, 4 pages, DailyCrewSection)
- `b980f82`  — Task 3 (real vitest tests replacing Wave 0 stubs)

## Self-Check: PASSED
- web/src/lib/team/__tests__/team.test.ts exists and contains no `it.todo`
- web/src/lib/team/schemas.ts exists with `memberSchema`, `assignmentSchema`, `certSchema`, `dailyCrewSchema`
- web/src/app/api/team/route.ts imports from `@/lib/team/schemas`
- Commits a205ad4e and b980f82 present in `git log`
- `npm test -- --run` exits 0 with 132 passed / 6 todo (todos are from other unrelated Wave 0 stubs outside this plan)
