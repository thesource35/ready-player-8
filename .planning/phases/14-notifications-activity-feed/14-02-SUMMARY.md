# Plan 14-02 — Summary

**Status:** Complete
**Date:** 2026-04-11
**Duration:** Single session

## What Was Built

Server-side notification brain: two Supabase Edge Functions and a pg_cron schedule.

### notifications-fanout Edge Function
- Receives Database Webhook POSTs on `cs_activity_events` INSERT
- Resolves recipients from `cs_project_members`, excludes actor
- Bulk-inserts `cs_notifications` rows (single round-trip)
- Push gating: only `bid_deadline`, `safety_alert`, `assigned_task` categories trigger APNs (D-16 hard line)
- APNs HTTP/2 via ES256 JWT signed with `djwt@v3.0.2`, P-256 key imported via `crypto.subtle.importKey`
- JWT cached for 50 minutes (Apple requires <60 min freshness)
- 410/400 APNs responses delete stale `cs_device_tokens` rows
- Auth: verifies `Authorization` header matches `SUPABASE_SERVICE_ROLE_KEY` (T-14-06/07)

### notifications-schedule Edge Function
- Scans `cs_contracts.bid_deadline` for 3 windows: day-of, +1 day, +3 days
- Inserts `cs_activity_events` with `category='bid_deadline'` through the same fanout path (D-03/D-17)
- De-dupe guard: skips if identical event exists within 20-hour window
- Auth: same service-role header verification

### pg_cron Migration
- `20260407002_phase14_pgcron_schedule.sql` — schedules `notifications-nightly-scheduler` at 13:00 UTC daily
- Uses Supabase Vault for `project_url` and `service_role_key` (Supabase managed Postgres denies `ALTER DATABASE` to non-superusers)
- Idempotent: unschedules any previous version before re-creating

## Artifacts

| File | Purpose |
|------|---------|
| `supabase/functions/notifications-fanout/index.ts` | Fanout + push logic with testable `handle()` export |
| `supabase/functions/notifications-fanout/apns.ts` | APNs HTTP/2 client with ES256 JWT signing |
| `supabase/functions/notifications-fanout/index.test.ts` | 6 Deno tests for handle() |
| `supabase/functions/notifications-fanout/apns.test.ts` | 4 Deno tests for JWT signing + APNs headers |
| `supabase/functions/notifications-schedule/index.ts` | Nightly bid-deadline scanner |
| `supabase/migrations/20260407002_phase14_pgcron_schedule.sql` | pg_cron job installation |

## Test Results

10/10 Deno tests pass:
- `apns.test.ts`: ES256 JWT header/claims, JWT caching, 410 error handling, required APNs headers
- `index.test.ts`: auth rejection, null project_id skip, generic category no-push (D-16), safety_alert push, actor exclusion, PUSH_CATEGORIES export

## Deviations

| Rule | Description |
|------|-------------|
| [Rule 1 - Bug] | Deno 2.x `Uint8Array` → `BufferSource` type error in `importKey` — fixed by passing `.buffer as ArrayBuffer` |
| [Rule 1 - Bug] | Test stub builder methods had overly specific parameter types — widened to `unknown` with internal casts |

## Key Details

- **djwt version:** `v3.0.2` (pinned in import URL)
- **APNS_HOST:** `https://api.sandbox.push.apple.com` (sandbox for dev; switch to `api.push.apple.com` for TestFlight/prod)
- **Vault secrets required:** `project_url`, `service_role_key` (for pg_cron → Edge Function invocation)
- **Supabase secrets required:** `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_AUTH_KEY_P8`, `APNS_BUNDLE_ID`, `APNS_HOST`

## Commit

- `e7843f0` — fix(14-02): resolve Deno 2.x type errors in fanout tests and apns module
