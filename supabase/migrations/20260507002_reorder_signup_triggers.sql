-- Reorder auth.users signup triggers so org provision runs FIRST.
--
-- 2026-05-07: surfaced when sign-up rolled back with
--   "null value in column org_id of relation cs_user_profiles
--    violates not-null constraint"
-- even after 20260507001 added an autofill BEFORE INSERT trigger on
-- cs_user_profiles. Root cause: trigger ordering on auth.users.
--
-- Postgres fires triggers in ALPHABETICAL ORDER by trigger name. The
-- existing trigger names sorted as:
--   1. on_auth_user_created             (legacy, undocumented in repo;
--                                        added via dashboard SQL editor;
--                                        directly inserts cs_user_profiles)
--   2. on_auth_user_created_org_provision
--                                       (from 20260413001;
--                                        creates cs_organizations + user_orgs)
--
-- So `on_auth_user_created` ran FIRST, tried to insert cs_user_profiles,
-- the autofill trigger on cs_user_profiles looked for the user's primary
-- org in user_orgs -- but user_orgs was still empty because the org
-- provision trigger hadn't fired yet. Result: org_id stayed null, the
-- NOT NULL constraint blew up, the entire signup transaction rolled back.
--
-- Fix: rename the org-provision trigger with an "aa_" prefix so it sorts
-- BEFORE on_auth_user_created, runs first, populates user_orgs, and the
-- autofill trigger downstream finds the row it needs.
--
-- We keep the function name (handle_new_user_org_provision) untouched so
-- nothing else has to change. Only the trigger NAME on auth.users moves.

drop trigger if exists on_auth_user_created_org_provision on auth.users;

create trigger aa_on_auth_user_created_org_provision
  after insert on auth.users
  for each row
  execute function public.handle_new_user_org_provision();
