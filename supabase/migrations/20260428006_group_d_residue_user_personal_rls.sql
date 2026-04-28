-- Phase: Group D residue — RLS for the 3 ambiguous wealth/personal tables.
--
-- Closes the multi-tenancy series TRULY at the end. The 5 clearly user-
-- personal tables got their RLS in 20260428005; these 3 needed per-table
-- judgment because their semantic could plausibly be either personal OR
-- org-scoped. Audit decision (2026-04-28): all 3 stay user-personal,
-- pending schema upgrades that would enable proper multi-user sharing.
--
-- Tables in scope:
--
--   cs_reminders         -- "remind me about X" — inherently personal
--   cs_schedule_events   -- calendar events with attendees: see notes below
--   cs_todos             -- personal task list with assigned_to: see notes below
--
-- Why user-personal (not org-scoped) for cs_schedule_events + cs_todos?
--
--   These tables have soft references to other entities — `project_ref`
--   (text, not uuid FK to cs_projects), `attendees` (text[]), `assigned_to`
--   (text). Without real FKs, there's no way to do org-scoped RLS via
--   JOIN. Org-scoping would require:
--     1. Convert project_ref text -> project_id uuid + FK to cs_projects(id)
--     2. Replace attendees text[] with a separate cs_event_attendees table
--        (composite PK: event_id + user_id) for proper many-to-many
--     3. Convert assigned_to text -> assigned_user_id uuid + FK to auth.users
--   That's a feature/schema migration of its own (~half day), not a
--   tonight task.
--
--   Pragmatic decision: keep user-personal. Each user sees only their own
--   reminders/events/todos. Future: when the schema is upgraded with real
--   FKs, this RLS can be loosened to support proper team collaboration.
--
-- Captured as 999.5/999.7 followup: "schema soft-refs prevent multi-user
-- collaboration on cs_schedule_events + cs_todos."

-- ---- cs_reminders ----

alter table cs_reminders enable row level security;
drop policy if exists cs_reminders_select on cs_reminders;
drop policy if exists cs_reminders_insert on cs_reminders;
drop policy if exists cs_reminders_update on cs_reminders;
drop policy if exists cs_reminders_delete on cs_reminders;

create policy cs_reminders_select on cs_reminders for select to authenticated
  using (user_id = auth.uid());
create policy cs_reminders_insert on cs_reminders for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_reminders_update on cs_reminders for update to authenticated
  using (user_id = auth.uid());
create policy cs_reminders_delete on cs_reminders for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_schedule_events ----

alter table cs_schedule_events enable row level security;
drop policy if exists cs_schedule_events_select on cs_schedule_events;
drop policy if exists cs_schedule_events_insert on cs_schedule_events;
drop policy if exists cs_schedule_events_update on cs_schedule_events;
drop policy if exists cs_schedule_events_delete on cs_schedule_events;

create policy cs_schedule_events_select on cs_schedule_events for select to authenticated
  using (user_id = auth.uid());
create policy cs_schedule_events_insert on cs_schedule_events for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_schedule_events_update on cs_schedule_events for update to authenticated
  using (user_id = auth.uid());
create policy cs_schedule_events_delete on cs_schedule_events for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_todos ----

alter table cs_todos enable row level security;
drop policy if exists cs_todos_select on cs_todos;
drop policy if exists cs_todos_insert on cs_todos;
drop policy if exists cs_todos_update on cs_todos;
drop policy if exists cs_todos_delete on cs_todos;

create policy cs_todos_select on cs_todos for select to authenticated
  using (user_id = auth.uid());
create policy cs_todos_insert on cs_todos for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_todos_update on cs_todos for update to authenticated
  using (user_id = auth.uid());
create policy cs_todos_delete on cs_todos for delete to authenticated
  using (user_id = auth.uid());

-- =============================================================================
-- Multi-tenancy migration series — REAL FINAL TALLY
-- =============================================================================
-- 6 migrations shipped:
--
--   20260413001 -- Foundation: user_orgs + cs_organizations + auth trigger + backfill
--   20260428002 -- Core: org_id columns on cs_projects + 3 more
--   20260428003 -- Group B: 12 project-scoped tables × 4 policies = 48
--   20260428004 -- Group E: 10 ambiguous tables, 5 access patterns, 30 policies
--   20260428005 -- Group D: 5 user-personal wealth/psychology tables × 4 = 20
--   20260428006 -- Group D residue: 3 ambiguous tables × 4 policies = 12 (this file)
--
-- 47 of 48 cs_* tables now have explicit RLS:
--   30 org-scoped
--   10 user-personal (5 Group D + 3 Group D residue + 2 Group E user-personal)
--    5 public read (Group E social/reference)
--    2 service-role only (Group E system-internal)
--   = 47 total + 1 cs_organizations (set up by 20260413001) = 48
--
-- The user_orgs gap that's been blocking proper multi-tenancy since
-- Phase 21 shipped is now COMPLETELY resolved at the policy level.
--
-- Outstanding architectural debt (separate phases):
--
--   1. Schema soft-refs prevent multi-user collaboration on
--      cs_schedule_events + cs_todos (text-based project_ref, attendees,
--      assigned_to). Convert to real FKs when collaboration features
--      are scoped.
--
--   2. cs_organizations.id rows on remote DON'T match the org_id values
--      that pre-existed in cs_equipment (5 orphan rows). Acceptable for
--      pre-launch dev/test; document for first real-customer migration.
--
--   3. supabase/migrations/ still cannot bootstrap a fresh DB cleanly
--      (999.7) — the baseline migration captured 19 missing tables but
--      the lexicographic-sort dependency loop (20260406001 vs 20260406_)
--      remains. Needs a focused refactor to consolidate.
