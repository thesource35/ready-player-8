-- Phase: Group B project-scoped RLS — propagate org-based access to 12 tables.
--
-- Continues the multi-tenancy migration. Foundation (user_orgs + cs_organizations)
-- shipped 20260413001; core tables (cs_projects + 3 more) gained org_id 20260428002.
-- This migration updates RLS on the 12 project-scoped tables that have project_id
-- but no direct org_id column. Their access flows through cs_projects.org_id.
--
-- Tables affected (Group B from the 2026-04-28 audit):
--   cs_activity_events       cs_ops_alerts            cs_punch_pro      cs_timecards
--   cs_change_orders         cs_project_assignments   cs_rfis           cs_transactions
--   cs_daily_crew            cs_project_members       cs_tax_expenses
--   cs_notifications
--
-- Pattern per table: 4 policies (SELECT/INSERT/UPDATE/DELETE), each gated by:
--   project_id in (
--     select id from cs_projects
--     where org_id in (select org_id from user_orgs where user_id = auth.uid())
--   )
--
-- This is a two-hop RLS subquery (table → cs_projects → user_orgs). PostgreSQL
-- handles it but the cs_projects.org_id index (created in 20260428002) makes
-- the inner subquery cheap. The user_orgs.user_id index makes the outer
-- subquery cheap. Net: no perf concern at expected scales.
--
-- DELETE is restricted to org owner/admin (consistent with cs_projects pattern).
-- INSERT/UPDATE require simple org membership (not role-restricted).
--
-- Tables NOT included (separate decisions):
--   - Group A (cs_documents, cs_equipment, cs_video_*, cs_safety_incidents, etc.)
--     already have direct org_id; their RLS was set up by Phase 22 et al.
--   - Group D personal/wealth tables — stay user_id-based.
--   - Group E ambiguous tables — per-table judgment needed.

-- =============================================================================
-- Helper note: each table follows the IDENTICAL 4-policy pattern below.
-- DROP IF EXISTS on each policy first so re-running the migration is idempotent.
-- =============================================================================

-- ---- cs_activity_events ----

alter table cs_activity_events enable row level security;
drop policy if exists cs_activity_events_select on cs_activity_events;
drop policy if exists cs_activity_events_insert on cs_activity_events;
drop policy if exists cs_activity_events_update on cs_activity_events;
drop policy if exists cs_activity_events_delete on cs_activity_events;

create policy cs_activity_events_select on cs_activity_events for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_activity_events_insert on cs_activity_events for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_activity_events_update on cs_activity_events for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_activity_events_delete on cs_activity_events for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_change_orders ----

alter table cs_change_orders enable row level security;
drop policy if exists cs_change_orders_select on cs_change_orders;
drop policy if exists cs_change_orders_insert on cs_change_orders;
drop policy if exists cs_change_orders_update on cs_change_orders;
drop policy if exists cs_change_orders_delete on cs_change_orders;

create policy cs_change_orders_select on cs_change_orders for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_change_orders_insert on cs_change_orders for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_change_orders_update on cs_change_orders for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_change_orders_delete on cs_change_orders for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_daily_crew ----

alter table cs_daily_crew enable row level security;
drop policy if exists cs_daily_crew_select on cs_daily_crew;
drop policy if exists cs_daily_crew_insert on cs_daily_crew;
drop policy if exists cs_daily_crew_update on cs_daily_crew;
drop policy if exists cs_daily_crew_delete on cs_daily_crew;

create policy cs_daily_crew_select on cs_daily_crew for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_daily_crew_insert on cs_daily_crew for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_daily_crew_update on cs_daily_crew for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_daily_crew_delete on cs_daily_crew for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_notifications ----

alter table cs_notifications enable row level security;
drop policy if exists cs_notifications_select on cs_notifications;
drop policy if exists cs_notifications_insert on cs_notifications;
drop policy if exists cs_notifications_update on cs_notifications;
drop policy if exists cs_notifications_delete on cs_notifications;

create policy cs_notifications_select on cs_notifications for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_notifications_insert on cs_notifications for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_notifications_update on cs_notifications for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_notifications_delete on cs_notifications for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_ops_alerts ----

alter table cs_ops_alerts enable row level security;
drop policy if exists cs_ops_alerts_select on cs_ops_alerts;
drop policy if exists cs_ops_alerts_insert on cs_ops_alerts;
drop policy if exists cs_ops_alerts_update on cs_ops_alerts;
drop policy if exists cs_ops_alerts_delete on cs_ops_alerts;

create policy cs_ops_alerts_select on cs_ops_alerts for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_ops_alerts_insert on cs_ops_alerts for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_ops_alerts_update on cs_ops_alerts for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_ops_alerts_delete on cs_ops_alerts for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_project_assignments ----

alter table cs_project_assignments enable row level security;
drop policy if exists cs_project_assignments_select on cs_project_assignments;
drop policy if exists cs_project_assignments_insert on cs_project_assignments;
drop policy if exists cs_project_assignments_update on cs_project_assignments;
drop policy if exists cs_project_assignments_delete on cs_project_assignments;

create policy cs_project_assignments_select on cs_project_assignments for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_project_assignments_insert on cs_project_assignments for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));
create policy cs_project_assignments_update on cs_project_assignments for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));
create policy cs_project_assignments_delete on cs_project_assignments for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_project_members ----

alter table cs_project_members enable row level security;
drop policy if exists cs_project_members_select on cs_project_members;
drop policy if exists cs_project_members_insert on cs_project_members;
drop policy if exists cs_project_members_update on cs_project_members;
drop policy if exists cs_project_members_delete on cs_project_members;

create policy cs_project_members_select on cs_project_members for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_project_members_insert on cs_project_members for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));
create policy cs_project_members_update on cs_project_members for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));
create policy cs_project_members_delete on cs_project_members for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_punch_pro ----

alter table cs_punch_pro enable row level security;
drop policy if exists cs_punch_pro_select on cs_punch_pro;
drop policy if exists cs_punch_pro_insert on cs_punch_pro;
drop policy if exists cs_punch_pro_update on cs_punch_pro;
drop policy if exists cs_punch_pro_delete on cs_punch_pro;

create policy cs_punch_pro_select on cs_punch_pro for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_punch_pro_insert on cs_punch_pro for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_punch_pro_update on cs_punch_pro for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_punch_pro_delete on cs_punch_pro for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_rfis ----

alter table cs_rfis enable row level security;
drop policy if exists cs_rfis_select on cs_rfis;
drop policy if exists cs_rfis_insert on cs_rfis;
drop policy if exists cs_rfis_update on cs_rfis;
drop policy if exists cs_rfis_delete on cs_rfis;

create policy cs_rfis_select on cs_rfis for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_rfis_insert on cs_rfis for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_rfis_update on cs_rfis for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_rfis_delete on cs_rfis for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_tax_expenses ----

alter table cs_tax_expenses enable row level security;
drop policy if exists cs_tax_expenses_select on cs_tax_expenses;
drop policy if exists cs_tax_expenses_insert on cs_tax_expenses;
drop policy if exists cs_tax_expenses_update on cs_tax_expenses;
drop policy if exists cs_tax_expenses_delete on cs_tax_expenses;

create policy cs_tax_expenses_select on cs_tax_expenses for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_tax_expenses_insert on cs_tax_expenses for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_tax_expenses_update on cs_tax_expenses for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_tax_expenses_delete on cs_tax_expenses for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_timecards ----

alter table cs_timecards enable row level security;
drop policy if exists cs_timecards_select on cs_timecards;
drop policy if exists cs_timecards_insert on cs_timecards;
drop policy if exists cs_timecards_update on cs_timecards;
drop policy if exists cs_timecards_delete on cs_timecards;

create policy cs_timecards_select on cs_timecards for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_timecards_insert on cs_timecards for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_timecards_update on cs_timecards for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_timecards_delete on cs_timecards for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));

-- ---- cs_transactions ----

alter table cs_transactions enable row level security;
drop policy if exists cs_transactions_select on cs_transactions;
drop policy if exists cs_transactions_insert on cs_transactions;
drop policy if exists cs_transactions_update on cs_transactions;
drop policy if exists cs_transactions_delete on cs_transactions;

create policy cs_transactions_select on cs_transactions for select to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_transactions_insert on cs_transactions for insert to authenticated
  with check (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_transactions_update on cs_transactions for update to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid())));
create policy cs_transactions_delete on cs_transactions for delete to authenticated
  using (project_id in (select id from cs_projects where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))));
