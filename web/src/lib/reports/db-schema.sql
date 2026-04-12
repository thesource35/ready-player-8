-- ============================================================================
-- ConstructionOS Reporting & Dashboards — Database Schema
-- Phase 19: Report tables, RLS policies, and indexes
-- ============================================================================
-- Run this in your Supabase SQL editor to create all report tables.
-- Prerequisites: auth.users table (Supabase Auth), existing cs_projects table.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. cs_report_schedules
--    Stores scheduled email report configurations (D-54, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_schedules (
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

-- ---------------------------------------------------------------------------
-- 2. cs_report_delivery_log
--    Tracks each scheduled report delivery attempt (D-50h, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_delivery_log (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid references cs_report_schedules(id) on delete set null,
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  recipients uuid[] not null default '{}',
  status text not null check (status in ('sent', 'failed', 'partial')),
  error_message text,
  pdf_storage_path text,
  email_html text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 3. cs_report_shared_links
--    Time-limited shareable report links (D-64b, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_shared_links (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  project_id uuid,
  report_type text not null check (report_type in ('project', 'rollup')),
  expires_at timestamptz not null default (now() + interval '30 days'),
  view_count int not null default 0,
  max_views_per_day int not null default 100,
  is_revoked boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 4. cs_report_history
--    Snapshot archive of generated reports (D-99, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  project_id uuid,
  report_type text not null check (report_type in ('project', 'rollup')),
  snapshot_data jsonb not null default '{}',
  pdf_storage_path text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 5. cs_report_templates
--    User-defined report templates with layout config (D-93, D-94, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  name text not null,
  description text,
  template_config jsonb not null default '{}',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 6. cs_report_comments
--    Threaded comments on report sections (D-98, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  report_history_id uuid not null references cs_report_history(id) on delete cascade,
  section text not null,
  content text not null,
  parent_id uuid references cs_report_comments(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 7. cs_report_annotations
--    Chart annotations stored as Fabric.js JSON (D-98, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_annotations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid,
  report_history_id uuid not null references cs_report_history(id) on delete cascade,
  chart_id text not null,
  fabric_json jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. cs_report_audit_log
--    Immutable audit trail for report access/actions (D-112, D-91, D-92)
-- ---------------------------------------------------------------------------
create table cs_report_audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  org_id uuid,
  action text not null check (action in ('viewed', 'exported', 'shared', 'scheduled', 'commented', 'annotated')),
  report_type text,
  project_id uuid,
  device_info text,
  metadata jsonb,
  created_at timestamptz not null default now()
);


-- ============================================================================
-- ROW LEVEL SECURITY (D-63)
-- ============================================================================

alter table cs_report_schedules enable row level security;
alter table cs_report_delivery_log enable row level security;
alter table cs_report_shared_links enable row level security;
alter table cs_report_history enable row level security;
alter table cs_report_templates enable row level security;
alter table cs_report_comments enable row level security;
alter table cs_report_annotations enable row level security;
alter table cs_report_audit_log enable row level security;


-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Helper: check org membership (reusable subquery)
-- Assumes a user_orgs table with (user_id, org_id) columns exists.
-- If user_orgs does not exist, org_id-based policies will deny access
-- and only user_id = auth.uid() will grant access.

-- ---------------------------------------------------------------------------
-- cs_report_schedules policies
-- ---------------------------------------------------------------------------
create policy "report_schedules_select" on cs_report_schedules
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_schedules_insert" on cs_report_schedules
  for insert with check (user_id = auth.uid());

create policy "report_schedules_update" on cs_report_schedules
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "report_schedules_delete" on cs_report_schedules
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_delivery_log policies
-- ---------------------------------------------------------------------------
create policy "report_delivery_log_select" on cs_report_delivery_log
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_delivery_log_insert" on cs_report_delivery_log
  for insert with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_shared_links policies
-- ---------------------------------------------------------------------------
create policy "report_shared_links_select" on cs_report_shared_links
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_shared_links_insert" on cs_report_shared_links
  for insert with check (user_id = auth.uid());

create policy "report_shared_links_update" on cs_report_shared_links
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "report_shared_links_delete" on cs_report_shared_links
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_history policies
-- ---------------------------------------------------------------------------
create policy "report_history_select" on cs_report_history
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_history_insert" on cs_report_history
  for insert with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_templates policies
-- ---------------------------------------------------------------------------
create policy "report_templates_select" on cs_report_templates
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_templates_insert" on cs_report_templates
  for insert with check (user_id = auth.uid());

create policy "report_templates_update" on cs_report_templates
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "report_templates_delete" on cs_report_templates
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_comments policies
-- ---------------------------------------------------------------------------
create policy "report_comments_select" on cs_report_comments
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_comments_insert" on cs_report_comments
  for insert with check (user_id = auth.uid());

create policy "report_comments_update" on cs_report_comments
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "report_comments_delete" on cs_report_comments
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_annotations policies
-- ---------------------------------------------------------------------------
create policy "report_annotations_select" on cs_report_annotations
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

create policy "report_annotations_insert" on cs_report_annotations
  for insert with check (user_id = auth.uid());

create policy "report_annotations_update" on cs_report_annotations
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "report_annotations_delete" on cs_report_annotations
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- cs_report_audit_log policies (T-19-06: INSERT-only for non-owners)
-- ---------------------------------------------------------------------------
create policy "report_audit_log_select" on cs_report_audit_log
  for select using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

-- Any authenticated user can insert audit entries (logging should not be blocked)
create policy "report_audit_log_insert" on cs_report_audit_log
  for insert with check (auth.uid() is not null);

-- No UPDATE or DELETE policies on audit log — immutable by design (T-19-06)


-- ============================================================================
-- INDEXES (D-61)
-- ============================================================================

-- Schedules: find active schedules due for execution
create index idx_report_schedules_next_run
  on cs_report_schedules (next_run_at)
  where is_active = true;

-- Schedules: lookup by user
create index idx_report_schedules_user
  on cs_report_schedules (user_id);

-- Delivery log: find deliveries for a schedule (most recent first)
create index idx_report_delivery_log_schedule
  on cs_report_delivery_log (schedule_id, created_at desc);

-- Shared links: fast token lookup for public access (non-revoked only)
create index idx_report_shared_links_token
  on cs_report_shared_links (token)
  where is_revoked = false;

-- Shared links: find links by user
create index idx_report_shared_links_user
  on cs_report_shared_links (user_id);

-- History: find reports for a project (most recent first)
create index idx_report_history_project
  on cs_report_history (project_id, created_at desc);

-- History: find reports by user
create index idx_report_history_user
  on cs_report_history (user_id, created_at desc);

-- Comments: find comments for a report history entry
create index idx_report_comments_history
  on cs_report_comments (report_history_id);

-- Annotations: find annotations for a report history entry
create index idx_report_annotations_history
  on cs_report_annotations (report_history_id);

-- Audit log: find audit entries by user (most recent first)
create index idx_report_audit_log_user
  on cs_report_audit_log (user_id, created_at desc);

-- Audit log: find entries by action type
create index idx_report_audit_log_action
  on cs_report_audit_log (action, created_at desc);


-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Auto-update updated_at on cs_report_schedules
create or replace function update_report_schedules_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_report_schedules_updated_at
  before update on cs_report_schedules
  for each row execute function update_report_schedules_updated_at();

-- Auto-update updated_at on cs_report_templates
create or replace function update_report_templates_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_report_templates_updated_at
  before update on cs_report_templates
  for each row execute function update_report_templates_updated_at();
