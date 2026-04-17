---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: Gap Closure & Feature Completion
status: executing
stopped_at: Completed 22-08-PLAN.md (Cameras section UI)
last_updated: "2026-04-17T06:11:30.838Z"
last_activity: 2026-04-17
progress:
  total_phases: 14
  completed_phases: 7
  total_plans: 57
  completed_plans: 54
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-14)

**Core value:** Every user action must either succeed visibly or fail with a clear, actionable message -- no silent data loss, no undetected errors, no security gaps.
**Current focus:** Phase 22 — live-site-video-per-project-hls-camera-feeds-tied-to-project

## Current Position

Milestone: v2.1
Phase: 22 (live-site-video-per-project-hls-camera-feeds-tied-to-project) — EXECUTING
Plan: 10 of 12 (22-01 complete; 22-02 next)
Status: Ready to execute
Last activity: 2026-04-17

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
- [Phase 22]: [Phase 22-02]: Shared video vocabulary locked — 9 AppError cases + VideoSource/VideoAsset structs on iOS, matching TS unions + row-shape types + VideoErrorCode taxonomy on web. Swift CodingKeys map camelCase to DB snake_case; TS types use DB-shaped snake_case directly. ConstructOS {} root namespace bootstrapped in ThemeAndModels.swift to host D-26 AppStorage key helpers (ConstructOS.Video.defaultQualityKey etc.). iOS compiles clean; web tsc --noEmit exits 0. VIDEO-01-M satisfied.
- [Phase 22-03]: Wave 2 Mux server integration complete — 4 /api/video/mux/* routes (create/delete live input, playback JWT, webhook) with rate limiting (D-37 30 req/min/IP), HMAC verify + dedupe (D-32), 5-min disconnect grace (D-27), role-gated delete (D-39), compensating Mux delete on DB insert failure (D-29), soft cap 20/org (D-28), signed playback JWT RS256 TTL=300s (D-14). createServiceRoleClient helper added to supabase/server.ts for trusted webhook receiver use. Closes VIDEO-01-D/E/F/L.
- [Phase 22]: VOD pipeline complete: upload-URL route (D-31 caps + D-24 lazy source) + ffmpeg Fly.io worker (libx264 720p, 2x retry D-33, codec allowlist D-31) + signed-HLS-manifest playback (RESEARCH Pattern 3, 1h TTL D-14, no-store D-34). Worker uses setImmediate fire-and-forget for 202 fast-return.
- [Phase 22]: [Phase 22-05]: iOS service layer complete — SupabaseService +8 video CRUD methods (fetch/create/delete/toggle for sources+assets, allowedTables +2), VideoSyncManager (@MainActor ObservableObject per-project stale-while-revalidate cache, D-28 soft-cap helper), VideoPlaybackAuth (Mux JWT mint + VOD manifest URL composition, D-14 + D-19 dual-path for portal viewers), VideoUploadClient (D-31 client-side caps via AVURLAsset probe, 3-attempt tus-header PUT with retry, D-40 analytics). Wave 3 UI (22-06/22-08/22-09) can now be thin views over the testable service surface. Closes VIDEO-01-J/K.
- [Phase 22]: [Phase 22-06]: iOS player wrappers complete — CellularQualityMonitor (NWPathMonitor singleton; cellular→1.5Mbps, wifi→6Mbps, ConstructOS.Video.DefaultQuality override); VideoPlayerChrome (LiveStatusBadge green/gold/red + HDToggleButton 44pt hit target); LiveStreamView (LL-HLS via Mux with automaticallyWaitsToMinimizeStalling=false, isMuted=true at boot per D-35, requiresLinearPlayback=true in portal mode per D-34a); VideoClipPlayer distinct from LiveStreamView per D-18 (VOD via VideoPlaybackAuth.vodManifestUrl, status-aware placeholders, opportunistic resume under ConstructOS.Video.LastPlayedAssetId.{projectId} per D-26). Both accept optional portalToken (D-19) and apply D-34 restrictions at wrapper layer. Closes VIDEO-01-F, reinforces VIDEO-01-K.
- [Phase 22]: [Phase 22-07]: Web player wrappers complete — @mux/mux-player-react ^3.11.7 installed, LiveStreamView (LL-HLS, portal head-only via targetLiveWindow=0), VideoClipPlayer (VOD 4-status, portal download suppression via CSS), usePlaybackToken hook (auto-refresh 30s before TTL). 14 vitest specs GREEN. Closes VIDEO-01-F web parity, reinforces VIDEO-01-K.
- [Phase 22]: tus-js-client ^4.3.1 for web resumable uploads; CamerasSection client component hydrates after server render

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

Last session: 2026-04-17T06:11:30.834Z
Stopped at: Completed 22-08-PLAN.md (Cameras section UI)
Resume file: None
