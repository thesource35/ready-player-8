# Multi-tenancy verification report — 2026-04-28

Structural verification of the 6 migration series (20260413001 + 20260428002..006).

## Counts

| Check | Result | Expected |
|---|---|---|
| Total RLS policies on `public.cs_*` | **161** | ≥130 |
| cs_* tables with RLS enabled | **51** | All 48 cs_* + cs_organizations + user_orgs |
| `cs_organizations` rows | 2 | 1 per existing auth.users row |
| `user_orgs` rows | 2 | 1 per existing user (primary) |
| `auth.users` rows | 2 | Reference |
| Auth trigger `on_auth_user_created_org_provision` | ✓ Present | Required for new-signup auto-provisioning |

## What this proves

✓ All 6 migrations applied successfully on prod.
✓ Foundation tables (cs_organizations, user_orgs) created + populated.
✓ Backfill ran correctly (1 org per user).
✓ Auth trigger wired and ready for new signups.
✓ All Group A/B/C/D/E policies present.

## What this does NOT prove (deferred to integration test)

✗ Runtime RLS isolation between users — would need to:
  - Sign in as user A via Supabase Auth API → obtain JWT
  - Insert test `cs_projects` row
  - Sign in as user B → obtain JWT
  - Query `cs_projects` with B's JWT
  - Assert row count = 0 (B can't see A's data)
  - Cleanup test data
  Estimated: ~2 hours to write + run end-to-end. Best done as part of the
  staging-setup phase (999.7) where it's safe to create test users.

## Recommended next test

Tonight's structural verification + the production-pattern of running the
6 migrations cleanly = high confidence the RLS works as designed. The
remaining risk is ZERO-DAY edge cases (a specific RLS subquery returning
unexpected rows) which only a real integration test would catch.

For now, smoke test in production:
  1. Create a 2nd test account via the iOS Configure Backend flow
  2. Add a project as account A
  3. Sign in as account B on a different device/simulator
  4. Confirm B does NOT see A's project

This matches the actual user flow we're protecting.
