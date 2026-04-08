---
phase: 15
plan: 01
subsystem: team-crew-management
tags: [schema, rls, migration, wave-0]
requires: [cs_projects, cs_documents, cs_project_members]
provides: [cs_team_members, cs_project_assignments, cs_certifications, cs_daily_crew]
affects: [supabase-schema]
tech_stack:
  added: []
  patterns: [rls-via-cs_project_members, jsonb-member-ids-audit]
key_files:
  created:
    - supabase/migrations/20260408_phase15_team.sql
    - supabase/migrations/20260408_phase15_team_rls.sql
    - web/src/lib/team/__tests__/team.test.ts
    - ready player 8Tests/TeamServiceTests.swift
  modified: []
decisions:
  - "Followed 15-01-PLAN D-07 JSONB member_ids (not CONTEXT.md's normalized two-table — plan is source of truth for execution)"
  - "db push blocked by pre-existing Phase 13 RLS migration referencing non-existent cs_submittals table"
metrics:
  duration: ~5min
  completed: 2026-04-08
---

# Phase 15 Plan 01: Team & Crew Schema Summary

Wave 0 schema for Team & Crew Management — 4 tables (cs_team_members, cs_project_assignments, cs_certifications, cs_daily_crew) with RLS scoped via cs_project_members, plus vitest/XCTest Wave 0 stubs.

## Tasks Completed

| # | Task | Commit |
|---|------|--------|
| 1 | Schema migration (4 tables + indexes + FKs) | a4a9515 |
| 2 | RLS migration + Wave 0 test stubs | 3c42aa0 |
| 3 | `supabase db push` | **BLOCKED** — see below |

## Files Created

- `supabase/migrations/20260408_phase15_team.sql` — 4 tables, enum `cs_team_member_kind`, indexes (unique active assignment, one-per-day crew, cert expiry partial), FKs to cs_projects/cs_documents/auth.users
- `supabase/migrations/20260408_phase15_team_rls.sql` — RLS enabled on all 4 tables, policies scoped via `cs_project_members` (team_members permissive select, assignments/certifications/daily_crew membership-gated)
- `web/src/lib/team/__tests__/team.test.ts` — 5 todo stubs for TEAM-01/02/03/05
- `ready player 8Tests/TeamServiceTests.swift` — 2 XCTSkip stubs

## Verification

- vitest: `npx vitest run src/lib/team` — 1 skipped, 5 todo, green
- All acceptance-criteria greps pass

## Deviations from Plan

None on tasks 1 & 2 — files written verbatim from plan.

## BLOCKER: supabase db push failed

`supabase db push` failed on `20260406_documents_rls.sql` (Phase 13, NOT this plan):

```
ERROR: relation "cs_submittals" does not exist (SQLSTATE 42P01)
At statement: 0  (create policy "select documents via attachments" on cs_documents ...)
```

### Root cause

`supabase migration list` shows the remote is behind local by 6 migrations:
- 20260406_documents_rls.sql (Phase 13 RLS) — **fails**
- 20260407_phase14_notifications.sql
- 20260407_phase14_notifications_rls.sql
- 20260407_phase14_pgcron_schedule.sql
- 20260408_phase15_team.sql (this plan)
- 20260408_phase15_team_rls.sql (this plan)

The Phase 13 documents RLS migration references `cs_submittals`, `cs_rfis`, `cs_change_orders` which exist in code as DTOs but were never created as live Supabase tables. This is a pre-existing infra drift from Phase 13, out of scope for 15-01.

### Recommended resolution paths (user decision required)

1. **Create missing precursor tables** — scaffold `cs_submittals`, `cs_rfis`, `cs_change_orders` stub tables before the Phase 13 RLS migration runs.
2. **Patch Phase 13 RLS migration** — drop the entity_type branches for not-yet-existing tables, or guard with `to_regclass(...) is not null` checks.
3. **Manual partial push** — apply only Phase 14 + Phase 15 migrations via Supabase SQL editor, bypassing the broken Phase 13 RLS file.

Until resolved, downstream plans 15-02 (cert sweep Edge Function), 15-03 (web /team), and 15-04 (iOS) cannot execute against live schema.

## Self-Check: PASSED

- `supabase/migrations/20260408_phase15_team.sql` — FOUND
- `supabase/migrations/20260408_phase15_team_rls.sql` — FOUND
- `web/src/lib/team/__tests__/team.test.ts` — FOUND
- `ready player 8Tests/TeamServiceTests.swift` — FOUND
- commit a4a9515 — FOUND
- commit 3c42aa0 — FOUND
