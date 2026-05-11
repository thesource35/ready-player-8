-- Promote cs_report_schedules from web/src/lib/reports/db-schema.sql to a real migration.
--
-- Origin: Phase 19-08 (commit 5d7de2a) shipped the cron route + 3 other consumers
-- that import cs_report_schedules, but the schema lived only in
-- web/src/lib/reports/db-schema.sql and was never promoted to a numbered migration.
-- Result: all 4 routes 500 with "Failed to fetch schedules" because the table
-- doesn't exist on remote.
--
-- RLS modernization: the orphan's SELECT policy used the recursive pattern
--   org_id in (select org_id from user_orgs where user_id = auth.uid())
-- which causes Postgres 42P17 infinite recursion (same bug fixed for user_orgs
-- in 20260509001_fix_user_orgs_rls_recursion.sql). Rewrite the SELECT policy to
-- use the public.user_org_ids() SECURITY DEFINER helper from that fix.
--
-- Scope: cs_report_schedules ONLY. The 7 other reporting tables in db-schema.sql
-- remain orphan -- their consuming code paths are shipped but degraded, no
-- regression by leaving them. Promote in a future scoped phase if needed.
--
-- Idempotency: IF NOT EXISTS + DROP POLICY IF EXISTS guards so re-running the
-- migration on a partial state doesn't fail.

create table if not exists cs_report_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  name text not null default 'Portfolio Report',
  frequency text not null check (frequency in ('daily', 'weekly', 'biweekly', 'monthly')),
  day_of_week int check (day_of_week >= 0 and day_of_week <= 6),
  day_of_month int check (day_of_month >= 1 and day_of_month <= 31),
  time_utc time not null default '08:00:00',
  timezone text not null default 'America/New_York',
  recipients uuid[] not null default '{}',
  sections text[] not null default '{}',
  is_active boolean not null default true,
  last_run_at timestamptz,
  next_run_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table cs_report_schedules enable row level security;

create index if not exists idx_report_schedules_next_run
  on cs_report_schedules (next_run_at);

create index if not exists idx_report_schedules_user
  on cs_report_schedules (user_id);

drop policy if exists "report_schedules_select" on cs_report_schedules;
create policy "report_schedules_select" on cs_report_schedules
  for select to authenticated using (
    user_id = auth.uid()
    or org_id in (select public.user_org_ids())
  );

drop policy if exists "report_schedules_insert" on cs_report_schedules;
create policy "report_schedules_insert" on cs_report_schedules
  for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "report_schedules_update" on cs_report_schedules;
create policy "report_schedules_update" on cs_report_schedules
  for update to authenticated using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "report_schedules_delete" on cs_report_schedules;
create policy "report_schedules_delete" on cs_report_schedules
  for delete to authenticated using (user_id = auth.uid());
