-- Phase: Group D — formalize "user-personal, by design" RLS for 5 wealth/psychology tables.
--
-- Closes the multi-tenancy migration series at the documentation level.
-- These tables hold personal financial + psychological data that intentionally
-- does NOT participate in multi-tenancy. Each row is private to one user; no
-- org member, owner, or admin should ever see another user's data.
--
-- Documented as a deliberate design decision per 999.4 + 999.5 production-
-- readiness sweep. Without this migration, the absence of org_id columns on
-- these tables looked like an oversight ("did we forget to migrate them?").
-- This file makes the decision explicit and grep-able.
--
-- Tables in scope (5 of the 8 originally categorized as Group D):
--
--   cs_decision_journal       -- Power Thinking framework: user's decision logs
--   cs_leverage_snapshots     -- Leverage System: user's category scores over time
--   cs_psychology_sessions    -- Psychology Decoder: user's mindset quiz history
--   cs_wealth_opportunities   -- Opportunity Filter: user's scored opportunities
--   cs_wealth_tracking        -- Money Lens: user's revenue/expense entries
--
-- Why these specifically?
--   They map to the 5 tabs of the iOS "Wealth Suite" (per CLAUDE.md):
--     Money Lens, Psychology Decoder, Power Thinking, Leverage System,
--     Opportunity Filter.
--   These are personal financial-coaching / introspection tools, NOT
--   multi-user collaboration features. Treating them as org-shared would
--   be a privacy regression.
--
-- Group D tables NOT in this migration (deferred to per-table judgment):
--   cs_reminders         -- ambiguous: could be personal OR project-scoped
--   cs_schedule_events   -- ambiguous: could be personal calendar OR project Gantt
--   cs_todos             -- ambiguous: could be personal OR project task list
--
-- Pattern (uniform across all 5 tables):
--   - RLS enabled
--   - SELECT/INSERT/UPDATE/DELETE policies all gated by `user_id = auth.uid()`
--   - No org_id reference anywhere — staying user-personal is the contract
--   - service-role bypasses RLS (for admin operations like account deletion
--     cascade or data export tools), same as every other table

-- ---- cs_decision_journal ----

alter table cs_decision_journal enable row level security;
drop policy if exists cs_decision_journal_select on cs_decision_journal;
drop policy if exists cs_decision_journal_insert on cs_decision_journal;
drop policy if exists cs_decision_journal_update on cs_decision_journal;
drop policy if exists cs_decision_journal_delete on cs_decision_journal;

create policy cs_decision_journal_select on cs_decision_journal for select to authenticated
  using (user_id = auth.uid());
create policy cs_decision_journal_insert on cs_decision_journal for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_decision_journal_update on cs_decision_journal for update to authenticated
  using (user_id = auth.uid());
create policy cs_decision_journal_delete on cs_decision_journal for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_leverage_snapshots ----

alter table cs_leverage_snapshots enable row level security;
drop policy if exists cs_leverage_snapshots_select on cs_leverage_snapshots;
drop policy if exists cs_leverage_snapshots_insert on cs_leverage_snapshots;
drop policy if exists cs_leverage_snapshots_update on cs_leverage_snapshots;
drop policy if exists cs_leverage_snapshots_delete on cs_leverage_snapshots;

create policy cs_leverage_snapshots_select on cs_leverage_snapshots for select to authenticated
  using (user_id = auth.uid());
create policy cs_leverage_snapshots_insert on cs_leverage_snapshots for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_leverage_snapshots_update on cs_leverage_snapshots for update to authenticated
  using (user_id = auth.uid());
create policy cs_leverage_snapshots_delete on cs_leverage_snapshots for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_psychology_sessions ----

alter table cs_psychology_sessions enable row level security;
drop policy if exists cs_psychology_sessions_select on cs_psychology_sessions;
drop policy if exists cs_psychology_sessions_insert on cs_psychology_sessions;
drop policy if exists cs_psychology_sessions_update on cs_psychology_sessions;
drop policy if exists cs_psychology_sessions_delete on cs_psychology_sessions;

create policy cs_psychology_sessions_select on cs_psychology_sessions for select to authenticated
  using (user_id = auth.uid());
create policy cs_psychology_sessions_insert on cs_psychology_sessions for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_psychology_sessions_update on cs_psychology_sessions for update to authenticated
  using (user_id = auth.uid());
create policy cs_psychology_sessions_delete on cs_psychology_sessions for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_wealth_opportunities ----

alter table cs_wealth_opportunities enable row level security;
drop policy if exists cs_wealth_opportunities_select on cs_wealth_opportunities;
drop policy if exists cs_wealth_opportunities_insert on cs_wealth_opportunities;
drop policy if exists cs_wealth_opportunities_update on cs_wealth_opportunities;
drop policy if exists cs_wealth_opportunities_delete on cs_wealth_opportunities;

create policy cs_wealth_opportunities_select on cs_wealth_opportunities for select to authenticated
  using (user_id = auth.uid());
create policy cs_wealth_opportunities_insert on cs_wealth_opportunities for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_wealth_opportunities_update on cs_wealth_opportunities for update to authenticated
  using (user_id = auth.uid());
create policy cs_wealth_opportunities_delete on cs_wealth_opportunities for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_wealth_tracking ----

alter table cs_wealth_tracking enable row level security;
drop policy if exists cs_wealth_tracking_select on cs_wealth_tracking;
drop policy if exists cs_wealth_tracking_insert on cs_wealth_tracking;
drop policy if exists cs_wealth_tracking_update on cs_wealth_tracking;
drop policy if exists cs_wealth_tracking_delete on cs_wealth_tracking;

create policy cs_wealth_tracking_select on cs_wealth_tracking for select to authenticated
  using (user_id = auth.uid());
create policy cs_wealth_tracking_insert on cs_wealth_tracking for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_wealth_tracking_update on cs_wealth_tracking for update to authenticated
  using (user_id = auth.uid());
create policy cs_wealth_tracking_delete on cs_wealth_tracking for delete to authenticated
  using (user_id = auth.uid());

-- =============================================================================
-- Multi-tenancy migration series — final tally
-- =============================================================================
-- Foundation (1 migration):
--   20260413001 -- user_orgs + cs_organizations + auth trigger + backfill
--
-- Schema work (1 migration):
--   20260428002 -- org_id columns on cs_projects, cs_contracts,
--                  cs_team_members, cs_user_profiles
--
-- RLS migrations (3 migrations):
--   20260428003 -- Group B: 12 project-scoped tables × 4 policies = 48
--   20260428004 -- Group E: 10 ambiguous tables, 5 access patterns, 30 policies
--   20260428005 -- Group D: 5 user-personal tables × 4 policies = 20
--
-- Final state on prod (44 of 48 cs_* tables with explicit RLS):
--   29 org-scoped (Groups A + C + B)
--    7 user-personal (5 from Group D + 2 from Group E: cs_ai_messages, cs_credentials)
--    5 public read (Group E social/reference)
--    2 service-role only (Group E system-internal)
--    1 cs_organizations (set up in 20260413001)
--   = 44 with explicit policies
--
-- Tables NOT covered (3 ambiguous Group D — deferred):
--   cs_reminders         -- needs per-table judgment
--   cs_schedule_events   -- needs per-table judgment
--   cs_todos             -- needs per-table judgment
--
-- These 3 retain whatever RLS state was set up by their original phase
-- migrations (likely user_id-based or none). They'll need explicit policy
-- decisions in a follow-up phase once the personal-vs-project semantic is
-- nailed down for each.
