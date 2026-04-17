---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 10
subsystem: infra
tags: [pg_cron, supabase-edge-functions, mux, retention, lifecycle, deno]

requires:
  - phase: 22-01
    provides: "cs_video_sources, cs_video_assets, cs_video_webhook_events tables + videos storage bucket"
  - phase: 22-03
    provides: "Mux live input creation + webhook HMAC verify + dedupe table"
  - phase: 22-04
    provides: "VOD upload pipeline + ffmpeg worker + signed HLS playback"
provides:
  - "Daily prune of expired VOD (30d) and live (24h) assets with storage + Mux archive cleanup"
  - "Daily archive of idle fixed_camera sources (30d) with Mux live_input disable"
  - "Daily prune of webhook-events dedupe table (7d retention)"
  - "Every-5-min backstop requeue for stuck VOD uploads"
  - "pg_cron migration scheduling all 4 jobs with GUC-based secret interpolation"
affects: [22-11, phase-28-verification]

tech-stack:
  added: []
  patterns:
    - "pg_cron + net.http_post to Supabase Edge Functions with service-role auth via GUC"
    - "Graceful partial failure: per-row try/catch with structured JSON report logging"
    - "Mux REST API for asset deletion (Basic auth) and live-stream disable"

key-files:
  created:
    - supabase/functions/prune-expired-videos/index.ts
    - supabase/functions/prune-expired-videos/deno.json
    - supabase/functions/archive-idle-sources/index.ts
    - supabase/functions/archive-idle-sources/deno.json
    - supabase/functions/prune-webhook-events/index.ts
    - supabase/functions/requeue-stuck-uploads/index.ts
    - supabase/migrations/20260415007_phase22_retention_cron.sql
  modified: []

key-decisions:
  - "All 4 jobs use edge functions invoked by pg_cron via net.http_post (consistent with Phase 14/15 pattern)"
  - "GUC-based secret interpolation keeps credentials out of migration SQL"
  - "Staggered daily schedules (03:00, 03:05, 03:30 UTC) prevent resource contention"

patterns-established:
  - "Retention cron pattern: pg_cron daily schedule + edge function with service-role auth check + per-row try/catch + structured JSON report"

requirements-completed: [VIDEO-01-O]

duration: 12min
completed: 2026-04-17
---

# Phase 22 Plan 10: Retention + Lifecycle Jobs Summary

**4 pg_cron-scheduled Supabase Edge Functions for VOD/live retention pruning, idle source archival, webhook-events dedupe cleanup, and stuck-upload requeue backstop**

## Performance

- **Duration:** 12 min
- **Started:** 2026-04-17T07:55:00Z
- **Completed:** 2026-04-17T08:11:27Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- 4 Deno edge functions implementing retention (D-09/D-10), idle-source archival (D-30), webhook-events prune (D-32), and upload backstop (RESEARCH)
- pg_cron migration scheduling all 4 jobs with staggered daily times and 5-min interval for backstop
- Mux API integration for asset deletion and live-stream disable within retention functions
- All functions enforce service-role auth, handle partial failures gracefully, and produce structured JSON logs

## Task Commits

Each task was committed atomically:

1. **Task 1: 4 Supabase Edge Functions** - `25d138e` (feat)
2. **Task 2: pg_cron schedule migration** - `08f1c26` (feat)
3. **Task 3: Deploy + apply cron migration** - human-action checkpoint (user confirmed "deployed")

## Files Created/Modified

- `supabase/functions/prune-expired-videos/index.ts` - Daily VOD (30d) + live (24h) retention prune with Mux archive deletion
- `supabase/functions/prune-expired-videos/deno.json` - Minimal Deno config
- `supabase/functions/archive-idle-sources/index.ts` - Daily idle fixed_camera auto-archive + Mux live_input disable
- `supabase/functions/archive-idle-sources/deno.json` - Minimal Deno config
- `supabase/functions/prune-webhook-events/index.ts` - 7-day webhook-events dedupe prune
- `supabase/functions/requeue-stuck-uploads/index.ts` - 5-min backstop for stuck uploading assets
- `supabase/migrations/20260415007_phase22_retention_cron.sql` - pg_cron schedules for all 4 jobs with GUC-based auth

## Decisions Made

- All 4 jobs use edge functions invoked by pg_cron via net.http_post (consistent with Phase 14/15 cron pattern)
- GUC-based secret interpolation (app.supabase_service_role_key) keeps credentials out of migration SQL
- Staggered daily schedules (03:00, 03:05, 03:30 UTC) prevent resource contention between retention jobs

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

Deployment-time operator steps (completed by user during Task 3):
- Deploy 4 edge functions via `supabase functions deploy`
- Set Mux + worker secrets via `supabase secrets set`
- Apply migration via `supabase db push`
- Set database-level GUCs for app.supabase_url and app.supabase_service_role_key

## Next Phase Readiness

- Retention lifecycle is fully automated -- Phase 22 video infrastructure is now self-maintaining
- Plan 22-11 (analytics) and 22-12 (iOS integration tests) remain to complete Phase 22

## Self-Check: PASSED

- All 5 key files: FOUND
- Commit 25d138e (Task 1): FOUND
- Commit 08f1c26 (Task 2): FOUND
- Task 3: Human-action checkpoint, user confirmed "deployed"

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Completed: 2026-04-17*
