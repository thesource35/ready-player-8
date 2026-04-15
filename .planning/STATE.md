---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: Gap Closure & Feature Completion
status: executing
stopped_at: Completed 22-01-PLAN.md (Wave 1 schema migrations applied to remote)
last_updated: "2026-04-15T07:45:00.000Z"
last_activity: 2026-04-15
progress:
  total_phases: 14
  completed_phases: 7
  total_plans: 57
  completed_plans: 47
  percent: 82
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-14)

**Core value:** Every user action must either succeed visibly or fail with a clear, actionable message -- no silent data loss, no undetected errors, no security gaps.
**Current focus:** Phase 22 — live-site-video-per-project-hls-camera-feeds-tied-to-project

## Current Position

Milestone: v2.1
Phase: 22 (live-site-video-per-project-hls-camera-feeds-tied-to-project) — EXECUTING
Plan: 3 of 12 (22-01 complete; 22-02 next)
Status: Ready to execute
Last activity: 2026-04-15

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions table for full history.

v2.0 closing decisions:

- Reduced v2.0 scope to phases 18, 20, 21 after 2026-04-14 audit found 6/9 phases unverified and 4 critical integration blockers
- Phases 13–17, 19 code left on `main` but milestone ownership reassigned to v2.1 pending verification
- Quick task 260414-n4w closed INT-03/04/05 (iOS NavTab wiring, DailyCrewView upsert, AgendaListView wiring) immediately before milestone close
- Milestone renamed from "Feature Expansion" to "Portal & AI Expansion" to reflect actual shipped surface
- [Phase 23]: DailyCrewView projectId becomes internal @AppStorage state; zero-arg init lets NavTab routing instantiate it directly (Phase 23-01)
- [Phase 23]: Phase 23 closed: VERIFICATION.md proves 5/5 goal-backward criteria (INT-03/04/05 CLOSED, FLOW-03/04/05 RESTORED); 5 requirements flipped to Satisfied
- [Phase 22]: [Phase 22]: Wave 0 scaffolding complete — 9 vitest stubs, 4 XCTest stubs, worker/ skeleton, 4 Mux webhook fixtures. Every Wave 1-4 automated verify command now resolves to a file on main.
- [Phase 22]: [Phase 22]: Pre-existing async/concurrency compile errors in ready_player_8Tests.swift + ReportTests.swift logged to deferred-items.md; Phase 22 iOS waves must either bundle a fix or use compile-only verification until Phase 28.
- [Phase 22-01]: Wave 1 schema live in remote DB — 6 migrations applied (cs_video_sources, cs_video_assets, cs_video_webhook_events, cs_portal_config.show_cameras, 'videos' storage bucket + RLS, pg_net trg_notify_ffmpeg_worker). Closes VIDEO-01-A/B/C/N-dedupe. Deploy-time GUC contract: app.ffmpeg_worker_url + app.ffmpeg_worker_secret set via ALTER DATABASE SET post-22-04; trigger no-ops when unset.
- [Phase 22-01]: Storage path layout standardized as `<org_id>/<project_id>/<asset_id>/<filename>` so storage.foldername(name)[1]::uuid reliably extracts org_id for RLS — binding constraint on all Wave 2 upload routes (22-04, 22-08).

### Pending Todos

None.

### v2.1 Open Blockers

- INT-01: RLS references non-existent cs_rfis/cs_submittals/cs_change_orders — Phase 26
- INT-02: Document routes do not emit cs_activity_events — Phase 24
- INT-06: Cert expiration does not trigger notifications — Phase 25
- INT-07: Portal home has no /map navigation link — Phase 27
- 15 human UAT items across phases 20, 21 remain unchecked (browser/device required)
- Phase 22 deploy-time GUCs (app.ffmpeg_worker_url + app.ffmpeg_worker_secret) must be set on remote DB post-22-04 before VOD trigger dispatch works end-to-end

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260406-rcz | Fix all 8 partial requirements and 36 TS errors from v1.0 milestone audit | 2026-04-07 | 1fe77a6 | [260406-rcz-fix-all-8-partial-requirements-and-36-ts](./quick/260406-rcz-fix-all-8-partial-requirements-and-36-ts/) |
| 260414-n4w | Fix 4 v2.0 audit integration blockers (INT-03/04/05 + STATE cleanup) | 2026-04-14 | 44a7dd3 | [260414-n4w-fix-4-v2-0-audit-integration-blockers-wi](./quick/260414-n4w-fix-4-v2-0-audit-integration-blockers-wi/) |

## Session Continuity

Last session: 2026-04-15T07:45:00.000Z
Stopped at: Completed 22-01-PLAN.md (Wave 1 schema migrations applied to remote)
Resume file: None
