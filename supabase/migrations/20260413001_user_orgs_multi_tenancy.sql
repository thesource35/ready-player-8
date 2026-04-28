-- Phase: Multi-tenancy foundation (user_orgs + cs_organizations).
-- Surfaced 2026-04-27 during 999.4 DB integrity recovery — RLS policies in
-- Phase 21+22+29 reference user_orgs but it was never created in any prior
-- migration. Existing Phase 21 cs_equipment table on remote has been in a
-- broken-RLS state since it shipped (subquery returns empty → deny all).
--
-- This migration creates the multi-tenancy foundation. After applying:
--   1. user_orgs exists → Phase 21 cs_equipment RLS starts working
--   2. Phase 22 + 29 migrations can be retried successfully
--   3. New signups get auto-provisioned via a trigger on auth.users
--   4. Existing users get backfilled with a new owner-of-their-own-org row
--
-- Defaults locked in 2026-04-28 design session:
--   Q1: multi-org membership (composite PK)
--   Q2: 3 roles — owner / admin / member
--   Q3: signup auto-creates org; invitations come later (separate flow)
--   Q4: backfill = one new org per existing auth.users row
--   Q5: cs_organizations metadata table created
--
-- NOT INCLUDED in this migration (deferred):
--   - cs_org_invitations table for the invitation flow (separate phase)
--   - Reconciling existing cs_projects/cs_equipment/etc rows whose org_id
--     doesn't match any newly-backfilled cs_organizations.id — those rows
--     become orphaned by RLS until manually reconciled. If the project
--     currently has production data, this needs a separate data-migration
--     pass per affected table BEFORE applying this migration.

-- =============================================================================
-- 1. Tables (both created BEFORE any RLS policies — policies on
--    cs_organizations reference user_orgs and vice-versa, so both tables
--    must exist before any policy creation runs).
-- =============================================================================

create table if not exists cs_organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 200),
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  plan_tier text not null default 'free' check (plan_tier in ('free', 'starter', 'pro', 'enterprise')),
  billing_provider text null check (billing_provider is null or billing_provider in ('paddle', 'square')),
  external_billing_id text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists cs_organizations_owner_idx on cs_organizations(owner_user_id);

create table if not exists user_orgs (
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid not null references cs_organizations(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member')),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (user_id, org_id)
);

create index if not exists user_orgs_org_idx on user_orgs(org_id);
create index if not exists user_orgs_user_idx on user_orgs(user_id);

-- A user has at most ONE primary org (partial unique index).
create unique index if not exists user_orgs_primary_idx on user_orgs(user_id) where is_primary = true;

-- =============================================================================
-- 2. RLS — enable + policies (now that both tables exist, mutual references work)
-- =============================================================================

alter table cs_organizations enable row level security;
alter table user_orgs enable row level security;

-- ---- cs_organizations policies ----

-- Members of an org can read its metadata
create policy cs_organizations_select on cs_organizations for select to authenticated
  using (id in (select org_id from user_orgs where user_id = auth.uid()));

-- Only owner can update their org's metadata
create policy cs_organizations_update on cs_organizations for update to authenticated
  using (id in (select org_id from user_orgs where user_id = auth.uid() and role = 'owner'));

-- Owner can delete (cascades to user_orgs membership rows)
create policy cs_organizations_delete on cs_organizations for delete to authenticated
  using (id in (select org_id from user_orgs where user_id = auth.uid() and role = 'owner'));

-- INSERT is gated to the auth-trigger function (SECURITY DEFINER bypasses RLS).
-- No client-side INSERT policy — orgs are created via signup trigger or via
-- a future invitation/admin flow.

-- ---- user_orgs policies ----

-- Users can see their own membership rows AND other members of their orgs
create policy user_orgs_select on user_orgs for select to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

-- Only owner/admin can add members (gated by SECURITY DEFINER functions later)
create policy user_orgs_insert on user_orgs for insert to authenticated
  with check (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));

-- Only owner/admin can change roles, AND no one can change their own role to bypass owner check
create policy user_orgs_update on user_orgs for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin')));

-- Owner/admin can remove members; users can remove themselves
create policy user_orgs_delete on user_orgs for delete to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
  );

-- =============================================================================
-- 3. Auth trigger — auto-provision org for new signups
-- =============================================================================

create or replace function public.handle_new_user_org_provision()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  new_org_id uuid;
  derived_name text;
begin
  derived_name := coalesce(split_part(new.email, '@', 1), 'user') || '''s organization';
  new_org_id := gen_random_uuid();

  insert into cs_organizations (id, name, owner_user_id)
  values (new_org_id, derived_name, new.id);

  insert into user_orgs (user_id, org_id, role, is_primary)
  values (new.id, new_org_id, 'owner', true);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_org_provision on auth.users;
create trigger on_auth_user_created_org_provision
  after insert on auth.users
  for each row
  execute function public.handle_new_user_org_provision();

-- =============================================================================
-- 4. Backfill — one new org per existing auth.users
-- =============================================================================
-- Idempotent: skips users who already have a user_orgs row (e.g. if migration
-- gets re-run, or if the trigger above already fired for some users).

do $$
declare
  user_rec record;
  new_org_id uuid;
  derived_name text;
begin
  for user_rec in
    select u.id, u.email
    from auth.users u
    where not exists (select 1 from user_orgs uo where uo.user_id = u.id)
  loop
    derived_name := coalesce(split_part(user_rec.email, '@', 1), 'user') || '''s organization';
    new_org_id := gen_random_uuid();

    insert into cs_organizations (id, name, owner_user_id)
    values (new_org_id, derived_name, user_rec.id);

    insert into user_orgs (user_id, org_id, role, is_primary)
    values (user_rec.id, new_org_id, 'owner', true);
  end loop;
end $$;

-- =============================================================================
-- Notes for downstream phases
-- =============================================================================
-- Phase 22 + 29 RLS policies that reference `user_orgs` will now work
-- correctly: the subquery `(select org_id from user_orgs where user_id =
-- auth.uid())` resolves to the user's primary org plus any guest memberships.
--
-- ⚠️ Existing data with orphaned org_ids:
-- If cs_projects, cs_contracts, cs_equipment, etc. have rows with org_id
-- values that DON'T match any cs_organizations.id (likely — those tables
-- pre-date this migration), those rows will be invisible to all users via
-- RLS until reconciled. Reconciliation strategies:
--   (a) Run a per-table UPDATE to set org_id = (the user's new primary org_id)
--       based on user_id ownership
--   (b) Create cs_organizations rows that match the existing org_id values
--       and add user_orgs memberships pointing at them
--   (c) Accept the orphan and start fresh
-- This is a separate per-table data-migration concern — out of scope for the
-- foundation migration above.
