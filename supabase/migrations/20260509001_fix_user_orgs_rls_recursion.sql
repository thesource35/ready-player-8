-- Fix infinite recursion in user_orgs RLS policies.
--
-- 2026-05-09: every authenticated query that touches user_orgs (or any
-- table whose policy queries user_orgs, like cs_organizations) returned
--   HTTP 500 {"code":"42P17","message":"infinite recursion detected in
--   policy for relation \"user_orgs\""}
-- breaking Maps, Projects, and most multi-tenant tabs in the iOS app.
--
-- Root cause: 20260413001 defined SELECT/INSERT/UPDATE/DELETE policies on
-- user_orgs whose USING/WITH CHECK clauses contained a subquery against
-- user_orgs itself, e.g.
--   using (org_id in (select org_id from user_orgs where user_id = auth.uid()))
-- Postgres has to evaluate the policy to evaluate the subquery, and the
-- subquery is the policy. Detected as recursion -> 42P17.
--
-- Fix: move the lookup into a SECURITY DEFINER function. SECURITY DEFINER
-- functions bypass RLS during their body, so the subquery runs once at
-- function-call time without re-triggering the parent policy.

-- ---------------------------------------------------------------------------
-- Helper: org ids the current user belongs to, optionally filtered by role.
-- ---------------------------------------------------------------------------
create or replace function public.user_org_ids(filter_roles text[] default null)
returns setof uuid
language sql
security definer
stable
set search_path = public
as $$
  select org_id
    from user_orgs
   where user_id = auth.uid()
     and (filter_roles is null or role = any(filter_roles));
$$;

-- Authenticated users may call the helper; service_role already can.
revoke all on function public.user_org_ids(text[]) from public;
grant execute on function public.user_org_ids(text[]) to authenticated, service_role;

-- ---------------------------------------------------------------------------
-- Replace the four recursive policies with non-recursive ones.
-- ---------------------------------------------------------------------------

drop policy if exists user_orgs_select on user_orgs;
create policy user_orgs_select on user_orgs for select to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select public.user_org_ids())
  );

drop policy if exists user_orgs_insert on user_orgs;
create policy user_orgs_insert on user_orgs for insert to authenticated
  with check (
    org_id in (select public.user_org_ids(array['owner', 'admin']))
  );

drop policy if exists user_orgs_update on user_orgs;
create policy user_orgs_update on user_orgs for update to authenticated
  using (
    org_id in (select public.user_org_ids(array['owner', 'admin']))
  );

drop policy if exists user_orgs_delete on user_orgs;
create policy user_orgs_delete on user_orgs for delete to authenticated
  using (
    user_id = auth.uid()
    or org_id in (select public.user_org_ids(array['owner', 'admin']))
  );
