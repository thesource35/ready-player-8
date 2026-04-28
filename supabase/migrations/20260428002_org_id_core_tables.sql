-- Phase: Core org_id propagation to cs_projects + cs_contracts + cs_team_members + cs_user_profiles.
--
-- Continues the multi-tenancy migration started by 20260413001_user_orgs_multi_tenancy.sql.
-- That migration created user_orgs + cs_organizations and backfilled one org per existing user.
-- This migration extends org_id to the 4 core business tables that previously only had user_id.
--
-- Tables affected (ordered by dependency):
--   1. cs_user_profiles  (each user's profile gets their primary org_id)
--   2. cs_projects       (root business entity — Group B tables inherit via project_id FK)
--   3. cs_contracts      (parallel business entity)
--   4. cs_team_members   (org membership augmenting user_orgs with role/title metadata)
--
-- Pattern per table:
--   1. ALTER TABLE ADD COLUMN org_id uuid NULL  (must allow NULL during backfill)
--   2. UPDATE ... SET org_id = (primary org from user_orgs)
--   3. ALTER COLUMN org_id SET NOT NULL  (constraint NOW that all rows are filled)
--   4. ALTER TABLE ADD FOREIGN KEY org_id → cs_organizations(id) ON DELETE RESTRICT
--   5. CREATE INDEX on org_id (RLS subquery performance)
--   6. RLS policies: org members can read; row.user_id = auth.uid() can write own; owner/admin can write any
--
-- NOT included in this migration (deferred to follow-up phases):
--   - Group B project-scoped tables (cs_rfis, cs_change_orders, cs_notifications, etc.) —
--     they inherit org access via cs_projects.org_id JOIN, but their RLS policies still
--     reference the old user_id pattern. Will be updated in a subsequent migration once
--     we verify this foundation works.
--   - Group D personal/wealth tables (cs_decision_journal, cs_leverage_snapshots,
--     cs_psychology_sessions, cs_wealth_*) — explicit design decision to keep these
--     user-personal. RLS stays user_id-based. NOT multi-tenant.
--   - Group E ambiguous tables (cs_certifications, cs_endorsements, cs_market_data, etc.) —
--     need per-table architectural decisions, out of scope tonight.
--   - Reconciliation of 5 existing cs_equipment rows whose org_id doesn't match any of
--     the new cs_organizations.id values. Acceptable orphan for pre-launch dev/test data.

-- =============================================================================
-- Helper: derive primary org for a given user_id (from user_orgs)
-- =============================================================================
-- Used by all 4 backfill UPDATEs below. Returns NULL if user has no user_orgs row.
-- Inline subquery rather than a function — keeps the migration self-contained.

-- =============================================================================
-- 1. cs_user_profiles
-- =============================================================================

alter table cs_user_profiles add column if not exists org_id uuid;

update cs_user_profiles
set org_id = (
  select org_id from user_orgs
  where user_orgs.user_id = cs_user_profiles.user_id
    and user_orgs.is_primary = true
  limit 1
)
where org_id is null;

-- Catch any rows whose user_id doesn't have a user_orgs entry — should be 0 after the
-- prior migration's backfill, but guard against weirdness.
do $$
declare
  unfilled integer;
begin
  select count(*) into unfilled from cs_user_profiles where org_id is null;
  if unfilled > 0 then
    raise warning 'cs_user_profiles: % rows have NULL org_id after backfill (probably orphaned user_id values)', unfilled;
  end if;
end $$;

-- Only enforce NOT NULL if backfill was complete; otherwise leave nullable for orphan handling
do $$
begin
  if not exists (select 1 from cs_user_profiles where org_id is null) then
    alter table cs_user_profiles alter column org_id set not null;
  end if;
end $$;

alter table cs_user_profiles
  drop constraint if exists cs_user_profiles_org_id_fkey,
  add constraint cs_user_profiles_org_id_fkey
    foreign key (org_id) references cs_organizations(id) on delete restrict;

create index if not exists cs_user_profiles_org_idx on cs_user_profiles(org_id);

-- =============================================================================
-- 2. cs_projects
-- =============================================================================

alter table cs_projects add column if not exists org_id uuid;

update cs_projects
set org_id = (
  select org_id from user_orgs
  where user_orgs.user_id = cs_projects.user_id
    and user_orgs.is_primary = true
  limit 1
)
where org_id is null and user_id is not null;

do $$
declare
  unfilled integer;
begin
  select count(*) into unfilled from cs_projects where org_id is null;
  if unfilled > 0 then
    raise warning 'cs_projects: % rows have NULL org_id after backfill', unfilled;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from cs_projects where org_id is null) then
    alter table cs_projects alter column org_id set not null;
  end if;
end $$;

alter table cs_projects
  drop constraint if exists cs_projects_org_id_fkey,
  add constraint cs_projects_org_id_fkey
    foreign key (org_id) references cs_organizations(id) on delete restrict;

create index if not exists cs_projects_org_idx on cs_projects(org_id);

-- =============================================================================
-- 3. cs_contracts
-- =============================================================================

alter table cs_contracts add column if not exists org_id uuid;

update cs_contracts
set org_id = (
  select org_id from user_orgs
  where user_orgs.user_id = cs_contracts.user_id
    and user_orgs.is_primary = true
  limit 1
)
where org_id is null and user_id is not null;

do $$
declare
  unfilled integer;
begin
  select count(*) into unfilled from cs_contracts where org_id is null;
  if unfilled > 0 then
    raise warning 'cs_contracts: % rows have NULL org_id after backfill', unfilled;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from cs_contracts where org_id is null) then
    alter table cs_contracts alter column org_id set not null;
  end if;
end $$;

alter table cs_contracts
  drop constraint if exists cs_contracts_org_id_fkey,
  add constraint cs_contracts_org_id_fkey
    foreign key (org_id) references cs_organizations(id) on delete restrict;

create index if not exists cs_contracts_org_idx on cs_contracts(org_id);

-- =============================================================================
-- 4. cs_team_members
-- =============================================================================

alter table cs_team_members add column if not exists org_id uuid;

update cs_team_members
set org_id = (
  select org_id from user_orgs
  where user_orgs.user_id = cs_team_members.user_id
    and user_orgs.is_primary = true
  limit 1
)
where org_id is null and user_id is not null;

do $$
declare
  unfilled integer;
begin
  select count(*) into unfilled from cs_team_members where org_id is null;
  if unfilled > 0 then
    raise warning 'cs_team_members: % rows have NULL org_id after backfill', unfilled;
  end if;
end $$;

do $$
begin
  if not exists (select 1 from cs_team_members where org_id is null) then
    alter table cs_team_members alter column org_id set not null;
  end if;
end $$;

alter table cs_team_members
  drop constraint if exists cs_team_members_org_id_fkey,
  add constraint cs_team_members_org_id_fkey
    foreign key (org_id) references cs_organizations(id) on delete restrict;

create index if not exists cs_team_members_org_idx on cs_team_members(org_id);

-- =============================================================================
-- 5. RLS — org-scoped policies on the 4 tables
-- =============================================================================

-- ---- cs_user_profiles ----

alter table cs_user_profiles enable row level security;

drop policy if exists cs_user_profiles_select on cs_user_profiles;
drop policy if exists cs_user_profiles_insert on cs_user_profiles;
drop policy if exists cs_user_profiles_update on cs_user_profiles;
drop policy if exists cs_user_profiles_delete on cs_user_profiles;

-- A user can see their own profile + other members of their orgs see basic info
create policy cs_user_profiles_select on cs_user_profiles for select to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

-- Self-only insert (signup flow creates own profile)
create policy cs_user_profiles_insert on cs_user_profiles for insert to authenticated
  with check (user_id = auth.uid());

-- Self-only update; admins of the org can also update
create policy cs_user_profiles_update on cs_user_profiles for update to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
  );

-- Self-only delete (account deletion); owner of org can also delete (e.g. removing terminated employee)
create policy cs_user_profiles_delete on cs_user_profiles for delete to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid() and role = 'owner')
  );

-- ---- cs_projects ----

alter table cs_projects enable row level security;

drop policy if exists cs_projects_select on cs_projects;
drop policy if exists cs_projects_insert on cs_projects;
drop policy if exists cs_projects_update on cs_projects;
drop policy if exists cs_projects_delete on cs_projects;

create policy cs_projects_select on cs_projects for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_projects_insert on cs_projects for insert to authenticated
  with check (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_projects_update on cs_projects for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_projects_delete on cs_projects for delete to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));

-- ---- cs_contracts ----

alter table cs_contracts enable row level security;

drop policy if exists cs_contracts_select on cs_contracts;
drop policy if exists cs_contracts_insert on cs_contracts;
drop policy if exists cs_contracts_update on cs_contracts;
drop policy if exists cs_contracts_delete on cs_contracts;

create policy cs_contracts_select on cs_contracts for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_contracts_insert on cs_contracts for insert to authenticated
  with check (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_contracts_update on cs_contracts for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_contracts_delete on cs_contracts for delete to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));

-- ---- cs_team_members ----

alter table cs_team_members enable row level security;

drop policy if exists cs_team_members_select on cs_team_members;
drop policy if exists cs_team_members_insert on cs_team_members;
drop policy if exists cs_team_members_update on cs_team_members;
drop policy if exists cs_team_members_delete on cs_team_members;

create policy cs_team_members_select on cs_team_members for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- Only owner/admin can add team members (owner/admin invites or HR-flow)
create policy cs_team_members_insert on cs_team_members for insert to authenticated
  with check (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));

-- Only owner/admin can update; team member can update their own record
create policy cs_team_members_update on cs_team_members for update to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
  );

-- Only owner/admin can delete (= remove team member)
create policy cs_team_members_delete on cs_team_members for delete to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));
