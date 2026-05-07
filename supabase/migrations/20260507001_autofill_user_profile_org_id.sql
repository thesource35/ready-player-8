-- Auto-populate cs_user_profiles.org_id from user_orgs if the client INSERT
-- omits it. Closes the schema-vs-client drift introduced by 20260428002,
-- which added org_id NOT NULL to cs_user_profiles but didn't update iOS
-- (and any pre-multi-tenancy clients) to provide org_id at signup time.
--
-- 2026-05-07: surfaced when a fresh signup attempt failed with
--   ERROR: null value in column "org_id" of relation "cs_user_profiles"
--          violates not-null constraint
-- Without this trigger, every new end-user signup 500s after the
-- on_auth_user_created_org_provision trigger creates the user_orgs row
-- but iOS still tries to insert cs_user_profiles without org_id.
--
-- The fix: BEFORE INSERT trigger that looks up the user's primary org from
-- user_orgs and fills it in. Since on_auth_user_created_org_provision
-- (defined in 20260413001) always creates a primary org for a brand-new
-- auth.users row, the lookup always finds a row in user_orgs by the time
-- iOS gets to inserting cs_user_profiles.
--
-- iOS isn't required to provide org_id; if it does, we respect it (no
-- override). This keeps the door open for multi-org membership later
-- where iOS picks which org the new profile belongs to.

create or replace function autofill_user_profile_org_id()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.org_id is null then
    select org_id
      into new.org_id
      from user_orgs
     where user_id = new.user_id
       and is_primary = true
     limit 1;
  end if;
  return new;
end;
$$;

drop trigger if exists autofill_user_profile_org_id_trg on cs_user_profiles;
create trigger autofill_user_profile_org_id_trg
  before insert on cs_user_profiles
  for each row
  execute function autofill_user_profile_org_id();
