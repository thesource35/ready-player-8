---
phase: 17-calendar-scheduling
plan: 01
subsystem: calendar-scheduling
tags: [schema, rls, supabase, security, org-scoping]
status: complete
completed: 2026-04-08
requirements: [CAL-01, CAL-02]
dependency_graph:
  requires: [17-00]
  provides: [cs_project_tasks, cs_task_dependencies, updateOwnedRow-org-scoped]
  affects: [17-02, 17-03, 17-04]
tech_stack:
  added: []
  patterns: [generated-column-duration, org-scoped-rls, FK-cascade]
key_files:
  created:
    - supabase/migrations/20260409001_phase17_project_tasks.sql
  modified:
    - web/src/lib/supabase/fetch.ts
decisions:
  - Mirror cs_projects RLS policy expression exactly (no new shape invented)
  - duration_days as GENERATED STORED column (not trigger) to keep reads cheap
  - updateOwnedRow refetches org_id per call (no request cache) — Phase 17 PATCH is low volume
metrics:
  tasks: 3
  files: 2
  duration: ~1 session
---

# Phase 17 Plan 01: Schema + updateOwnedRow Hardening Summary

Ships cs_project_tasks and cs_task_dependencies with org-scoped RLS, generated duration_days, and FK cycle-safe dependency constraints; hardens updateOwnedRow to scope updates by org_id (T-17-02) so Plan 02 PATCH routes are safe by default.

## What Shipped

- **Migration (20260409001_phase17_project_tasks.sql)** — Both tables with org_id, FK to cs_projects/cs_project_tasks, generated `duration_days` stored column, check constraints (percent_complete 0–100, predecessor ≠ successor), unique(predecessor_task_id, successor_task_id), indexes on project_id, (start_date,end_date), predecessor_task_id, successor_task_id. RLS enabled with policies mirroring cs_projects shape.
- **updateOwnedRow hardening (web/src/lib/supabase/fetch.ts)** — Resolves authenticated user's org_id via user_orgs lookup and adds `.eq('org_id', userOrgId)` to the update query. Returns null on missing user or missing org membership. Signature unchanged; tagged with `T-17-02` comment.
- **db push approved by user** — Task 3 checkpoint cleared.

## Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Migration for cs_project_tasks + cs_task_dependencies + RLS | e61e06c |
| 2 | updateOwnedRow org_id scoping (T-17-02) | f79a38c |
| 3 | supabase db push (human-action checkpoint) | approved |

## Decisions Made

- **RLS shape:** Copied cs_projects policy expression verbatim (`org_id = (select org_id from user_orgs where user_id = auth.uid())`) rather than inventing a new pattern — keeps Phase 17 tables behavior-identical to existing org-scoped tables.
- **duration_days:** Generated stored column instead of trigger — simpler, cheaper reads, matches Postgres idioms.
- **No request cache for org_id lookup in updateOwnedRow:** Phase 17 PATCH traffic is low; added complexity not justified. Revisit if profiling shows hot path.

## Deviations from Plan

None — plan executed as written. RED tests from Plan 17-00 for updateOwnedRow went GREEN after Task 2.

## Known Stubs

None.

## Follow-up Risks (for Plan 17-02)

- **[UNRESOLVED] user_orgs table existence not verified at schema level.** updateOwnedRow now depends on `user_orgs` being present with `(user_id, org_id)` columns. If `user_orgs` does not exist (or is named differently, e.g. `org_members`), the org_id lookup will silently return no row, causing updateOwnedRow to return null — which upstream API routes in Plan 17-02 may interpret as "not found" rather than "misconfigured". This is the **silent-match-zero failure mode**: PATCH requests would return 404 on every call with no log signal.
  - **Mitigation for 17-02:** Before wiring PATCH routes, Plan 17-02 Task 1 should (a) verify `user_orgs` exists in Supabase (grep migrations + live query), (b) add an explicit log/throw in updateOwnedRow when the org_id lookup itself fails vs. returns no row for a valid user, and (c) add an integration test that inserts a known user→org mapping and confirms PATCH round-trips.
  - **Severity:** High if missed — would block entire Phase 17 PATCH surface with no visible error.

## Threat Flags

None beyond threat model (T-17-01, T-17-02 both mitigated).

## Self-Check: PASSED

- supabase/migrations/20260409001_phase17_project_tasks.sql — FOUND
- web/src/lib/supabase/fetch.ts — FOUND (modified)
- Commit e61e06c — FOUND
- Commit f79a38c — FOUND
