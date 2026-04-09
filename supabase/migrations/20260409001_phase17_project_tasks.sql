-- Phase 17: Calendar & Scheduling schema (D-01, D-02)
-- Creates cs_project_tasks (Gantt rows) and cs_task_dependencies (FS/SS/FF/SF edges).
-- Threat T-17-01: RLS enabled on both tables. Project-wide convention in this
-- codebase is `to authenticated using (true)` (see 20260408003_phase15_team_rls.sql);
-- org_id columns are included on both tables now so a future hardening migration
-- can tighten policies without a table rewrite.

create extension if not exists pgcrypto;

create table if not exists cs_project_tasks (
  id                uuid primary key default gen_random_uuid(),
  org_id            uuid not null,
  project_id        uuid not null references cs_projects(id) on delete cascade,
  name              text not null,
  trade             text,
  start_date        date not null,
  end_date          date not null,
  duration_days     int generated always as (end_date - start_date + 1) stored,
  percent_complete  int not null default 0 check (percent_complete between 0 and 100),
  is_critical       boolean not null default false,
  created_by        uuid references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_by        uuid references auth.users(id) on delete set null,
  updated_at        timestamptz not null default now()
);
create index if not exists cs_project_tasks_project_idx on cs_project_tasks(project_id);
create index if not exists cs_project_tasks_date_idx    on cs_project_tasks(start_date, end_date);
create index if not exists cs_project_tasks_org_idx     on cs_project_tasks(org_id);

create table if not exists cs_task_dependencies (
  id                   uuid primary key default gen_random_uuid(),
  org_id               uuid not null,
  predecessor_task_id  uuid not null references cs_project_tasks(id) on delete cascade,
  successor_task_id    uuid not null references cs_project_tasks(id) on delete cascade,
  dep_type             text not null default 'FS' check (dep_type in ('FS','SS','FF','SF')),
  lag_days             int  not null default 0,
  created_at           timestamptz not null default now(),
  unique (predecessor_task_id, successor_task_id),
  check  (predecessor_task_id <> successor_task_id)
);
create index if not exists cs_task_dependencies_pred_idx on cs_task_dependencies(predecessor_task_id);
create index if not exists cs_task_dependencies_succ_idx on cs_task_dependencies(successor_task_id);
create index if not exists cs_task_dependencies_org_idx  on cs_task_dependencies(org_id);

-- Reuse the existing updated_at trigger function from 001_updated_at_triggers.sql
drop trigger if exists set_cs_project_tasks_updated_at on cs_project_tasks;
create trigger set_cs_project_tasks_updated_at
  before update on cs_project_tasks
  for each row execute function update_updated_at_column();

-- Row level security (T-17-01)
alter table cs_project_tasks      enable row level security;
alter table cs_task_dependencies  enable row level security;

create policy cs_project_tasks_select on cs_project_tasks for select to authenticated using (true);
create policy cs_project_tasks_write  on cs_project_tasks for all    to authenticated using (true) with check (true);

create policy cs_task_dependencies_select on cs_task_dependencies for select to authenticated using (true);
create policy cs_task_dependencies_write  on cs_task_dependencies for all    to authenticated using (true) with check (true);

comment on table cs_project_tasks     is 'Phase 17 Gantt task rows — D-01';
comment on table cs_task_dependencies is 'Phase 17 task dependency edges — D-02';
