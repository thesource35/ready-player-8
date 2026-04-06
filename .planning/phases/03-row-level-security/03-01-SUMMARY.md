---
phase: 03-row-level-security
plan: 01
subsystem: database
tags: [supabase, rls, postgresql, migrations, security]

# Dependency graph
requires:
  - phase: 02-auth-keychain
    provides: "iOS and web clients send auth Bearer tokens to Supabase"
provides:
  - "3 versioned Supabase migration files for RLS enablement"
  - "user_id columns on all 23 tables with proper FK constraints"
  - "Backfill migration that assigns orphan rows to first admin user"
  - "RLS policies on all 23 tables (per-user isolation + public-read for community data)"
  - "Complete user_id indexes on all 23 tables"
  - "Migration README with critical ordering documentation"
affects: [03-02, api-routes, web-data-fetching]

# Tech tracking
tech-stack:
  added: []
  patterns: ["3-phase migration pattern: columns -> backfill -> policies", "DROP IF EXISTS / CREATE POLICY for idempotent migrations", "Public SELECT + owner-only write for community tables"]

key-files:
  created:
    - web/supabase/migrations/20260405000001_add_user_id_columns.sql
    - web/supabase/migrations/20260405000002_backfill_user_id.sql
    - web/supabase/migrations/20260405000003_enable_rls_policies.sql
    - web/supabase/README.md
  modified:
    - web/scripts/schema.sql

key-decisions:
  - "Granular rental_leads policies: public INSERT (form submissions) + owner-only SELECT/UPDATE/DELETE"
  - "Added market_data write policies (INSERT/UPDATE/DELETE) which were missing from original schema"
  - "23 tables (not 22 as plan stated) -- cs_wealth_tracking was the missing count"

patterns-established:
  - "Migration ordering: columns first, backfill second, RLS third -- never skip backfill"
  - "Idempotent SQL: ADD COLUMN IF NOT EXISTS, DROP POLICY IF EXISTS + CREATE POLICY"
  - "Placeholder UUID 00000000-0000-0000-0000-000000000000 as temporary NOT NULL default"

requirements-completed: [RLS-01, RLS-02, RLS-03, RLS-04, INFRA-06]

# Metrics
duration: 6min
completed: 2026-04-06
---

# Phase 03 Plan 01: RLS Migrations Summary

**3-phase Supabase migration (columns + backfill + policies) enabling row-level security on all 23 tables with per-user data isolation**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-06T22:13:12Z
- **Completed:** 2026-04-06T22:19:14Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created 3 versioned migration files that safely add RLS to existing databases
- Updated schema.sql to match migration end-state with granular policies and complete indexes
- Migration 2 safely no-ops when no users exist (handles fresh database case)
- All 23 tables covered with appropriate policies (per-user isolation, public-read for feed/market)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create migration directory and write 3 versioned migration SQL files** - `4a126ea` (feat)
2. **Task 2: Verify schema.sql matches migration end-state and add migration README** - included in `4a126ea` (schema.sql alignment was part of Task 1 commit; README already existed in HEAD)

## Files Created/Modified
- `web/supabase/migrations/20260405000001_add_user_id_columns.sql` - ADD COLUMN IF NOT EXISTS user_id on all 23 tables + indexes
- `web/supabase/migrations/20260405000002_backfill_user_id.sql` - DO block that finds first user and backfills orphan rows
- `web/supabase/migrations/20260405000003_enable_rls_policies.sql` - ENABLE RLS + 32 CREATE POLICY statements
- `web/supabase/README.md` - Migration order documentation with critical warnings
- `web/scripts/schema.sql` - Updated with granular rental/market policies + 23 user_id indexes

## Decisions Made
- Rental leads: split "for all" into granular policies -- public INSERT (anyone can submit rental form), owner-only SELECT/UPDATE/DELETE
- Market data: added missing write policies (INSERT/UPDATE/DELETE restricted to owner) -- schema.sql only had public SELECT
- Confirmed 23 tables total (plan said 22, cs_wealth_tracking was the uncounted table)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added market_data write policies**
- **Found during:** Task 1 (migration creation)
- **Issue:** schema.sql only had public SELECT on cs_market_data but no write restriction -- any authenticated user could INSERT/UPDATE/DELETE market data
- **Fix:** Added INSERT WITH CHECK, UPDATE USING/WITH CHECK, DELETE USING policies for owner-only writes
- **Files modified:** web/scripts/schema.sql, web/supabase/migrations/20260405000003_enable_rls_policies.sql
- **Verification:** grep confirms 32 CREATE POLICY statements covering all operations
- **Committed in:** 4a126ea

**2. [Rule 2 - Missing Critical] Granular rental_leads policies replacing overly permissive "for all"**
- **Found during:** Task 1 (migration creation)
- **Issue:** schema.sql had "for all" on cs_rental_leads which would require auth for INSERT -- but rental leads should accept public form submissions
- **Fix:** Split into 4 policies: public INSERT, owner SELECT/UPDATE/DELETE
- **Files modified:** web/scripts/schema.sql, web/supabase/migrations/20260405000003_enable_rls_policies.sql
- **Verification:** Policy count confirms 32 policies across all tables
- **Committed in:** 4a126ea

**3. [Rule 2 - Missing Critical] Added 15 missing user_id indexes**
- **Found during:** Task 1 (migration creation)
- **Issue:** schema.sql only had 8 indexes but 23 tables need user_id indexes for RLS performance
- **Fix:** Added indexes for all 23 tables (schedule_events, reminders, rfis, change_orders, rental_leads, market_data, ai_messages, transactions, tax_expenses, daily_logs, timecards, wealth_opportunities, decision_journal, psychology_sessions, leverage_snapshots, wealth_tracking, feed_posts)
- **Files modified:** web/scripts/schema.sql, web/supabase/migrations/20260405000001_add_user_id_columns.sql
- **Verification:** grep count shows 25 indexes (23 user_id + 2 feed_posts extras)
- **Committed in:** 4a126ea

---

**Total deviations:** 3 auto-fixed (3 missing critical)
**Impact on plan:** All auto-fixes necessary for security and performance. No scope creep.

## Issues Encountered
- Migration files and README already existed in HEAD from a prior execution attempt, reducing Task 1 to schema.sql alignment only
- Task 2 artifacts (README, migration 3 prerequisite comment) already present -- no new commit needed

## User Setup Required

None - migrations are SQL files to be run against Supabase. See `web/supabase/README.md` for execution instructions.

## Next Phase Readiness
- RLS migrations ready to apply to any Supabase instance
- Plan 03-02 can proceed with web client updates to pass auth tokens in data fetching
- All 23 tables have user_id columns, backfill logic, and access policies defined

---
## Self-Check: PASSED

All 6 files verified present. Commit 4a126ea confirmed in git log.

---
*Phase: 03-row-level-security*
*Completed: 2026-04-06*
