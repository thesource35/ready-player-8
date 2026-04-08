-- Phase 15: Team & Crew Management schema (D-01..D-08)
create extension if not exists pgcrypto;

create type cs_team_member_kind as enum ('internal','subcontractor','vendor');

create table cs_team_members (
  id          uuid primary key default gen_random_uuid(),
  kind        cs_team_member_kind not null,
  user_id     uuid references auth.users(id) on delete set null,
  name        text not null,
  role        text,
  trade       text,
  email       text,
  phone       text,
  company     text,
  notes       text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index cs_team_members_user_idx  on cs_team_members(user_id) where user_id is not null;
create index cs_team_members_kind_idx  on cs_team_members(kind);
create index cs_team_members_trade_idx on cs_team_members(trade);

create table cs_project_assignments (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references cs_projects(id) on delete cascade,
  member_id       uuid not null references cs_team_members(id) on delete cascade,
  role_on_project text,
  start_date      date,
  end_date        date,
  status          text not null default 'active',
  created_at      timestamptz not null default now()
);
create index cs_project_assignments_project_idx on cs_project_assignments(project_id);
create index cs_project_assignments_member_idx  on cs_project_assignments(member_id);
create unique index cs_project_assignments_unique_active
  on cs_project_assignments(project_id, member_id) where status = 'active';

create table cs_certifications (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references cs_team_members(id) on delete cascade,
  name         text not null,
  issuer       text,
  number       text,
  issued_date  date,
  expires_at   date,
  document_id  uuid references cs_documents(id) on delete set null,
  status       text not null default 'active',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index cs_certifications_member_idx  on cs_certifications(member_id);
create index cs_certifications_expires_idx on cs_certifications(expires_at) where status = 'active';
create index cs_certifications_status_idx  on cs_certifications(status);

create table cs_daily_crew (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references cs_projects(id) on delete cascade,
  assignment_date date not null,
  member_ids      jsonb not null default '[]'::jsonb,
  -- NOTE: member_ids may contain stale ids if a member is later deleted; intentional for v1 audit (Pitfall 8)
  notes           text,
  created_by      uuid references auth.users(id) on delete set null,
  created_at      timestamptz not null default now()
);
create unique index cs_daily_crew_one_per_day on cs_daily_crew(project_id, assignment_date);
create index cs_daily_crew_date_idx on cs_daily_crew(assignment_date);

-- Reuse existing updated_at trigger from 001_updated_at_triggers.sql
create trigger set_cs_team_members_updated_at  before update on cs_team_members  for each row execute function set_updated_at();
create trigger set_cs_certifications_updated_at before update on cs_certifications for each row execute function set_updated_at();
