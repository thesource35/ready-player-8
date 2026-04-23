# Roadmap: ConstructionOS

## Milestones

- ✅ **v1.0 Production Hardening** — Phases 1-12 (shipped 2026-04-06) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Portal & AI Expansion** — Phases 18, 20, 21 (shipped 2026-04-14) — [archive](milestones/v2.0-ROADMAP.md)
- 🚧 **v2.1 Gap Closure & Feature Completion** — Phases 13-17, 19, 22-28 (in progress)

## Phases

<details>
<summary>✅ v1.0 Production Hardening (Phases 1-12) — SHIPPED 2026-04-06</summary>

- [x] Phase 1: Secrets & Infrastructure Cleanup (3/3 plans) — completed 2026-04-05
- [x] Phase 2: Authentication (3/3 plans) — completed 2026-04-06
- [x] Phase 3: Row-Level Security (2/2 plans) — completed 2026-04-06
- [x] Phase 4: iOS Crash Safety (2/2 plans) — completed 2026-04-06
- [x] Phase 5: iOS Error Handling & State Persistence (4/4 plans) — completed 2026-04-06
- [x] Phase 6: Web Security & Validation (3/3 plans) — completed 2026-04-06
- [x] Phase 7: Web Error Handling & Consistency (3/3 plans) — completed 2026-04-06
- [x] Phase 8: Web UX & Loading States (3/3 plans) — completed 2026-04-06
- [x] Phase 9: Web Performance & Dynamic Content (5/5 plans) — completed 2026-04-06
- [x] Phase 10: Accessibility & SEO (3/3 plans) — completed 2026-04-06
- [x] Phase 11: iOS Tests (2/2 plans) — completed 2026-04-06
- [x] Phase 12: Web Tests (3/3 plans) — completed 2026-04-06

</details>

<details>
<summary>✅ v2.0 Portal & AI Expansion (Phases 18, 20, 21) — SHIPPED 2026-04-14</summary>

- [x] Phase 18: Enhanced AI (Angelic AI v2) (4/4 plans) — completed 2026-04-11
- [x] Phase 20: Client Portal & Sharing (10/10 plans) — completed 2026-04-13
- [x] Phase 21: Live Satellite & Traffic Maps (6/6 plans shipped) — completed 2026-04-14; UAT gap closure in v2.1 adds plans 07-11 (see below)

**Scope note:** Original v2.0 included Phases 13-22. After audit (see `milestones/v2.0-MILESTONE-AUDIT.md`), scope was reduced to verified phases. Remaining phases carried to v2.1.

</details>

### 🚧 v2.1 Gap Closure & Feature Completion

Phase code exists on `main` from original v2.0 work — verification, wiring, and integration gaps are the remaining work.

- [x] **Phase 13: Document Management Foundation** (5/5 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 14: Notifications & Activity Feed** (5/5 plans) — code complete 2026-04-11, verification pending
- [x] **Phase 15: Team & Crew Management** (4/4 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 16: Field Tools** (6/6 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 17: Calendar & Scheduling** (5/5 plans) — code complete 2026-04-11, verification pending
- [x] **Phase 19: Reporting & Dashboards** (18/18 plans) — code complete 2026-04-12, verification pending
- [x] **Phase 22: Live Site Video** — planned 2026-04-15 (12 plans, 4 waves); 2/12 executed (22-00 Wave 0 scaffolding + 22-01 Wave 1 schema) (completed 2026-04-17)
- [x] **Phase 23: iOS Nav & Assignment Wiring + Web Parity** (5 plans, 2 waves) — Plans 01-02 complete; plans 03-05 add cross-nav, save hardening, accessibility on both platforms (completed 2026-04-17)
- [x] **Phase 24: Document → Activity Event Emission** (2 plans, 2 waves) — Gap closure: document routes emit `cs_activity_events` (INT-02) (completed 2026-04-17)
- [x] **Phase 25: Certification Expiry Notifications** (7 plans, 3 waves) — Gap closure: cert-expiry cron + notification emission (INT-06) (completed 2026-04-18)
- [x] **Phase 26: Documents RLS Table Reconciliation** (5 plans, 4 waves) — Gap closure: stub tables + rebuilt RLS + pre-flight + trigger extension (INT-01) (completed 2026-04-18)
- [x] **Phase 27: Portal → Map Navigation Link** (6 plans, 3 waves) — Gap closure: portal home links to `/map` sub-route when enabled (INT-07) (completed 2026-04-19)
- [x] **Phase 28: Retroactive Verification Sweep (Phases 13–19)** — Gap closure: create missing VERIFICATION.md files, reconcile REQUIREMENTS.md (completed 2026-04-19)

## Phase Details

### Phase 13: Document Management Foundation
**Goal**: Users can upload, attach, preview, and version files across all entity types
**Depends on**: v1.0 (auth, RLS, Supabase)
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-04, DOC-05
**Success Criteria** (what must be TRUE):
  1. User can upload a PDF or image to Supabase Storage from iOS and web
  2. User can download any attached file
  3. User can attach files to a project, RFI, submittal, or change order
  4. User can preview PDFs and images in-app without downloading
  5. User can view a list of prior versions of a revised document
**Plans**: 5 plans
- [x] 13-01-PLAN.md — Schema, Storage bucket, RLS policies (Wave 0, BLOCKING db push)
- [x] 13-02-PLAN.md — Web API routes (upload, sign, versions, attach, list)
- [x] 13-03-PLAN.md — iOS storage layer (SupabaseService extensions, HEIC, DocumentSyncManager)
- [ ] 13-04-PLAN.md — Web UI integration (AttachmentList, Preview, VersionHistory on 4 entity pages)
- [x] 13-05-PLAN.md — iOS UI integration (DocumentAttachmentsView on 4 entity surfaces)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 14: Notifications & Activity Feed
**Goal**: Users see what changed, what needs attention, and what's coming due
**Depends on**: Phase 13 (document events feed activity)
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05
**Success Criteria** (what must be TRUE):
  1. User sees a notification list with an unread count badge
  2. User can view a chronological activity timeline per project
  3. User can mark notifications as read individually or all at once
  4. User can dismiss notifications
  5. User receives iOS push notifications for bid deadlines, safety alerts, and assigned tasks
**Plans**: TBD
**UI hint**: yes
**v2.1 status**: verification pending (see Phases 24, 25, 28)

### Phase 15: Team & Crew Management
**Goal**: Users can manage team members, assignments, and credentials
**Depends on**: Phase 14 (cert expiration alerts use notifications)
**Requirements**: TEAM-01, TEAM-02, TEAM-03, TEAM-04, TEAM-05
**Success Criteria** (what must be TRUE):
  1. User can create a team member profile with role, trade, and contact info
  2. User can assign team members to projects with specific roles
  3. User can record certifications and licenses with expiration dates
  4. User receives an alert when a certification is nearing expiration
  5. User can create a daily crew assignment for a project
**Plans**: 4 plans
- [x] 15-01-PLAN.md — Wave 0 schema + RLS + test stubs + db push (BLOCKING)
- [x] 15-02-PLAN.md — Wave 1 cert-expiry-scan Edge Function + pg_cron
- [x] 15-03-PLAN.md — Wave 2 web /team route + API routes + DailyCrewSection
- [x] 15-04-PLAN.md — Wave 2 iOS TeamView + CertificationsView + DailyCrewView
**UI hint**: yes
**v2.1 status**: iOS nav wiring closed by quick task 260414-n4w; cert notification emission still open (Phase 25)

### Phase 16: Field Tools
**Goal**: Field users can capture, annotate, and log work from the jobsite
**Depends on**: Phase 13 (photos are documents), Phase 15 (logs reference crew)
**Requirements**: FIELD-01, FIELD-02, FIELD-03, FIELD-04
**Success Criteria** (what must be TRUE):
  1. User can capture a photo with GPS location and timestamp automatically tagged
  2. User can attach photos to punch items, daily logs, and safety incidents
  3. User can draw annotations/markup on a photo to highlight an issue
  4. User can create a daily log from a pre-filled template based on project context
**Plans**: 6 plans
- [x] 16-00-PLAN.md — Wave 0 test scaffolding (LocationProviding, OpenMeteoClient, fixtures, UAT)
- [x] 16-01-PLAN.md — Wave 1 schema (enum extension migration + columns/tables/RLS + Info.plist)
- [x] 16-02-PLAN.md — Wave 2 iOS capture pipeline + attach extension (FIELD-01, FIELD-02 iOS)
- [x] 16-03-PLAN.md — Wave 2 web /field photo browser + attach Server Actions (FIELD-02 web)
- [x] 16-04-PLAN.md — Wave 3 photo annotation, both platforms (FIELD-03)
- [x] 16-05-PLAN.md — Wave 3 daily logs with layered templates, both platforms (FIELD-04)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 17: Calendar & Scheduling
**Goal**: Users can see and reschedule all project work on a unified timeline
**Depends on**: Phase 15 (assignments appear on calendar)
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04
**Success Criteria** (what must be TRUE):
  1. User can view a timeline of all projects with milestones and bid due dates
  2. User can view a Gantt chart with task bars and dependencies
  3. Timeline highlights milestone markers (bid due, project start/end, inspections)
  4. User can drag a timeline item to reschedule it and the change persists
**Plans**: 5 plans
- [x] 17-00-PLAN.md — Wave 0 test scaffolding (vitest stubs + iOS XCTest stubs + updateOwnedRow scoping check)
- [x] 17-01-PLAN.md — Wave 1 schema (cs_project_tasks + cs_task_dependencies + RLS + updateOwnedRow org_id scoping, BLOCKING db push)
- [x] 17-02-PLAN.md — Wave 2 Next.js API routes (/api/calendar/tasks, dependencies with cycle detection, timeline rollup with derived milestones)
- [x] 17-03-PLAN.md — Wave 3 web /schedule rebuild (RollupTimeline + GanttChart with Pointer Events drag + AgendaView)
- [x] 17-04-PLAN.md — Wave 4 iOS agenda + tap-to-reschedule sheet in ScheduleTools.swift
**UI hint**: yes
**v2.1 status**: AgendaListView wiring closed by quick task 260414-n4w; verification pending (see Phase 28)

### Phase 19: Reporting & Dashboards
**Goal**: Users can view aggregated metrics and export shareable reports
**Depends on**: Phases 13-18 (aggregates data from all features)
**Requirements**: REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Success Criteria** (what must be TRUE):
  1. User can generate a single-project summary report covering budget, schedule, issues, and team
  2. User can view a cross-project financial rollup dashboard
  3. User can export a report to PDF
  4. User can view bar/line/pie chart visualizations for budgets, timelines, and safety metrics
**Plans**: 18 plans
- [x] 19-01 through 19-18 — see archive for details (all 18 plans complete)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 22: Live Site Video — per-project HLS camera feeds
**Goal:** Deliver per-project live camera feeds + recorded-clip VOD, viewable on iOS and web via HLS, with opt-in client-portal exposure. Mux owns the live ingest + LL-HLS pipeline; a Fly.io-hosted ffmpeg worker transcodes uploads into Supabase Storage. Two-table data model (`cs_video_sources` + `cs_video_assets`) with a `source_type` discriminator so Phase 29 extends row-only.
**Depends on:** Phase 21 (RLS + AppStorage patterns), Phase 20 (portal-link schema extension), Phase 13 (upload UX + signed-URL pattern)
**Requirements**: VIDEO-01-A..P (16 sub-requirements, see REQUIREMENTS.md)
**Success Criteria** (what must be TRUE):
  1. User can register a jobsite camera in ProjectDetail → Cameras (wizard creates Mux live_input, shows RTMP URL + stream key once)
  2. User can watch a live LL-HLS stream within 3-5 s glass-to-glass on iOS + web with 24 h DVR scrubback
  3. User can upload MP4/MOV clips (≤ 2 GB / ≤ 60 min) that transcode to HLS in the background and play back on both platforms
  4. User can toggle a Phase 20 portal link to `show_cameras=true` and flag individual clips `portal_visible=true`; portal viewers get head-only live + streaming-only VOD; drone-typed assets are NEVER exposed
  5. Retention is self-maintaining: 30 d VOD / 24 h live / 30 d idle-source archive / 7 d webhook-events / 5-min stuck-upload requeue — all via pg_cron + Supabase Edge Functions
  6. Every user action either succeeds visibly or surfaces an AppError with actionable copy — no silent failures in the Mux, upload, transcode, or portal paths
  7. All 8 D-40 analytics events emit at their defined call sites with project/org/user context (portal_link_id for portal events)
**Plans:** 12/12 plans complete
- [x] 22-00-PLAN.md — Wave 0 test scaffolding (9 web stubs + 4 iOS stubs + worker skeleton + Mux webhook fixtures + tiny.mp4)
- [x] 22-01-PLAN.md — Wave 1 schema migrations: cs_video_sources, cs_video_assets, cs_video_webhook_events, cs_portal_config.show_cameras, 'videos' bucket + storage RLS, pg_net DB webhook trigger (applied to remote 2026-04-15)
- [x] 22-02-PLAN.md — Wave 1 shared model types (Swift structs + TS types + 9 AppError cases + VideoErrorCode wire taxonomy)
- [x] 22-03-PLAN.md — Wave 2 Mux server integration: SDK wrapper + HMAC verify + create/delete live-input + playback-token + webhook receiver with D-27 5-min grace
- [x] 22-04-PLAN.md — Wave 2 VOD pipeline: tus upload-url route, HLS manifest sign+rewrite route, ffmpeg worker container on Fly.io with codec check + 2x retry
- [x] 22-05-PLAN.md — Wave 2 iOS service layer: SupabaseService extensions, VideoSyncManager, VideoPlaybackAuth, VideoUploadClient
- [x] 22-06-PLAN.md — Wave 3 iOS player wrappers: LiveStreamView (LL-HLS, mute-on-boot), VideoClipPlayer, CellularQualityMonitor (D-36), VideoPlayerChrome
- [x] 22-07-PLAN.md — Wave 3 web player wrappers: LiveStreamView + VideoClipPlayer via @mux/mux-player-react, usePlaybackToken hook with auto-refresh
- [x] 22-08-PLAN.md — Wave 3 Cameras section UI: wizard (with audio jurisdiction warning), upload sheet, cards, soft-cap banner, per-clip portal toggle — both platforms
- [x] 22-09-PLAN.md — Wave 4 portal exposure: portal playback-token + playback-url routes with D-22/D-34 enforcement, Show cameras toggle on Phase 20 portal editor (web + iOS)
- [x] 22-10-PLAN.md — Wave 4 retention + lifecycle: 4 Supabase Edge Functions + pg_cron schedules (daily prune/archive, 7-day dedupe prune, 5-min stuck-upload backstop)
- [x] 22-11-PLAN.md — Wave 4 analytics wiring + un-skip Wave 0 tests + VERIFICATION.md for manual UAT
**UI hint**: yes (ProjectDetail → new Cameras section per D-20; no top-level nav tab — reserved for Phase 29)
**Blocks**: Phase 29 (Live Video Traffic Feed) — Phase 29 is row-only extension of this schema

### Phase 23: iOS Navigation & Assignment Wiring
**Goal:** Existing iOS views (TeamView, CertificationsView, DailyCrewView, AgendaListView) are reachable from user navigation; daily crew edits do not 409. Cross-navigation, save hardening, and accessibility on both iOS and web.
**Depends on:** Phase 15, Phase 17
**Requirements:** TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03
**Gap Closure:** Closes INT-03, INT-04, INT-05 · FLOW-03, FLOW-04, FLOW-05
**Plans:** 5/5 plans complete
- [x] 23-01-PLAN.md — DailyCrewView project picker (iOS, Wave 1)
- [x] 23-02-PLAN.md — VERIFICATION.md + REQUIREMENTS.md updates (Wave 2)
- [x] 23-03-PLAN.md — Cross-navigation + badge + deep-link + web nav wiring (iOS + Web, Wave 1)
- [x] 23-04-PLAN.md — Save-flow hardening: dirty tracking, unsaved guard, auto-save, error handling, spinner (iOS + Web, Wave 1)
- [x] 23-05-PLAN.md — Accessibility labels + state announcements + offline indicator (iOS + Web, Wave 2)

### Phase 24: Document → Activity Event Emission
**Goal:** Every document mutation emits a row into `cs_activity_events` so the activity feed populates for document ops
**Depends on:** Phase 13, Phase 14
**Requirements:** DOC-02, NOTIF-02
**Gap Closure:** Closes INT-02 · FLOW-01
**Plans:** 2/2 plans complete

Plans:
- [x] 24-01-PLAN.md — Trigger function + trigger attachments + backfill + emission tests (Wave 1)
- [x] 24-02-PLAN.md — Activity feed rendering updates + rendering tests + human verification (Wave 2)

### Phase 25: Certification Expiry Notifications
**Goal:** Users receive notifications when certifications approach expiration
**Depends on:** Phase 14, Phase 15
**Requirements:** TEAM-04, NOTIF-04
**Gap Closure:** Closes INT-06 · FLOW-02
**Plans:** 7/7 plans complete

Plans:
- [x] 25-01-PLAN.md — Edge Function expansion: multi-threshold, batch, dedupe, grouping, cert renewal trigger (Wave 1)
- [x] 25-02-PLAN.md — Fanout enhancements: cert-specific push copy, APNs category registration (Wave 1)
- [x] 25-03-PLAN.md — iOS urgency badges, summary banner, renewal CTA, pulse animation, XCTest (Wave 2)
- [x] 25-04-PLAN.md — Web urgency badges, summary banner, deep-link highlight, renewal CTA, vitest (Wave 2)
- [x] 25-05-PLAN.md — iOS deep-link routing (cold + warm launch), CarPlay cert tab, analytics, badge count (Wave 2)
- [x] 25-06-PLAN.md — MCP tool, cert compliance widget, db push, manual test plan (Wave 3)
- [x] 25-07-PLAN.md — Cert name autocomplete (iOS + web), admin scan status badge (Wave 3)

### Phase 26: Documents RLS Table Reconciliation
**Goal:** RLS predicates for document attachments cover all referenced entity types without silent skip
**Depends on:** Phase 13
**Requirements:** DOC-03, DOC-04
**Gap Closure:** Closes INT-01
**Plans:** 5/5 plans complete

Plans:
- [x] 26-01-stub-tables-and-rls-PLAN.md — Migration A: 5 stub tables + RLS + pre-migration audit (Wave 1)
- [x] 26-02-rebuilt-document-rls-and-trigger-PLAN.md — Migration B: rebuild Phase 13 policies for all 7 entity types + Migration C: extend Phase 24 trigger whitelist (Wave 1)
- [x] 26-03-api-preflight-and-validation-PLAN.md — Web validation.ts 7 values + API pre-flight + iOS DocumentSyncManager pre-flight + drift-guard tests (Wave 2)
- [x] 26-04-ui-picker-empty-table-filter-PLAN.md — nonEmptyEntityTypes helper + component prop widening (web + iOS) (Wave 3)
- [x] 26-05-schema-push-and-verification-PLAN.md — [BLOCKING] supabase db push + DB/app verification + VERIFICATION.md (Wave 4)

### Phase 27: Portal → Map Navigation Link
**Goal:** Portal viewers can reach the `/map` sub-route when the admin enabled it
**Depends on:** Phase 20 (shipped v2.0), Phase 21 (shipped v2.0)
**Requirements:** INT-07 (primary), PORTAL-03, MAP-04 (supporting — integration-only)
**Gap Closure:** Closes INT-07
**Plans:** 6/6 plans complete

Plans:
- [x] 27-01-PLAN.md — Server-side compute showMapLink + thread through PortalShell (Wave 1)
- [x] 27-02-PLAN.md — PortalHeader Map anchor (last on home) + Overview anchor (first on /map) via usePathname (Wave 2)
- [x] 27-03-PLAN.md — MobilePortalNav 6th MapPin icon with route-aware active state (Wave 2)
- [x] 27-04-PLAN.md — /map page: branding inheritance + PortalHeader + analytics + rate limit + cache config (Wave 3)
- [x] 27-05-PLAN.md — Admin helper copy beneath Show Map toggle in PortalCreateDialog (Wave 1)
- [x] 27-06-PLAN.md — Wire MobilePortalNav into PortalShell so mobile viewers reach /map (Wave 2)

### Phase 28: Retroactive Verification Sweep (Phases 13–19)
**Goal:** Every v2.0-originated phase marked complete has a VERIFICATION.md proving goal-backward coverage, and REQUIREMENTS.md reflects the true state
**Depends on:** Phases 23, 24, 25, 26 (must run after code gaps are closed)
**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-05, FIELD-01, FIELD-02, FIELD-03, FIELD-04, CAL-01, CAL-02, CAL-04, REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Gap Closure:** Closes all "partial — no VERIFICATION.md" audit gaps; reconciles REQUIREMENTS.md traceability

### Phase 21: Live Satellite & Traffic Maps — UAT Gap Closure
**Goal:** Close all 16 Phase-21 UAT failures diagnosed in `21-UAT.md` (2026-04-21). Three remediation buckets: environment/build prereqs, web + iOS code defects, spec-vs-code reconciliation. Followed by full UAT re-walk.
**Depends on:** Phase 21 (shipped v2.0), Phase 27 (D-09 decision)
**Requirements:** MAP-01, MAP-02, MAP-03, MAP-04 (re-verification)
**Gap Closure:** Closes all 16 UAT failures; flips 21-VERIFICATION.md from human_needed to passed when ≥ 14/16 pass on re-walk
**Plans:** 11/11 plans complete

Plans:
- [x] 21-07-PLAN.md — Wave 1: env/build prereqs (Mapbox token + dev cache reset + iOS clean rebuild) + UAT text reconciliation for Tests 1 and 16 (D-09 aware)
- [x] 21-08-PLAN.md — Wave 2 web: equipment seed migration + empty-state chip + camera/overlay race fix + visible route error (Tests 3, 5, 6)
- [x] 21-09-PLAN.md — Wave 2 iOS: allowedTables extension + CrashReporter UI surfacing + mock relocation + empty-successful fallback + photo mock + "0 photos with GPS" chip (Tests 8, 9, 11)
- [x] 21-10-PLAN.md — Wave 3 iOS: AUTO TRACK AppStorage + onMapCameraChange + ScenePhase save + clobber guard + permission-denial Settings deep-link (Tests 10, 12)
- [x] 21-11-PLAN.md — Wave 4: full 16-test UAT re-walk + 21-UAT.md/21-VERIFICATION.md reconciliation (blocking human checkpoints)


## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|---------------|--------|-----------|
| 1-12 | v1.0 | 36/36 | Complete | 2026-04-06 |
| 18. Enhanced AI (Angelic AI v2) | v2.0 | 4/4 | Complete | 2026-04-11 |
| 20. Client Portal & Sharing | v2.0 | 10/10 | Complete | 2026-04-13 |
| 21. Live Satellite & Traffic Maps | v2.0 | 11/11 | Complete    | 2026-04-22 |
| 21. Live Satellite & Traffic Maps — UAT Gap Closure | v2.1 | 4/5 | In Progress | — |
| 13. Document Management Foundation | v2.1 | 5/5 | Code Complete | 2026-04-08 |
| 14. Notifications & Activity Feed | v2.1 | 5/5 | Code Complete | 2026-04-11 |
| 15. Team & Crew Management | v2.1 | 4/4 | Code Complete | 2026-04-08 |
| 16. Field Tools | v2.1 | 6/6 | Code Complete | 2026-04-08 |
| 17. Calendar & Scheduling | v2.1 | 5/5 | Code Complete | 2026-04-11 |
| 19. Reporting & Dashboards | v2.1 | 18/18 | Code Complete | 2026-04-12 |
| 22. Live Site Video | v2.1 | 12/12 | Complete    | 2026-04-17 |
| 23. iOS Nav & Assignment Wiring | v2.1 | 5/5 | Complete    | 2026-04-17 |
| 24. Document → Activity Event Emission | v2.1 | 2/2 | Complete    | 2026-04-17 |
| 25. Certification Expiry Notifications | v2.1 | 7/7 | Complete    | 2026-04-18 |
| 26. Documents RLS Table Reconciliation | v2.1 | 5/5 | Complete    | 2026-04-19 |
| 27. Portal → Map Navigation Link | v2.1 | 6/6 | Complete    | 2026-04-19 |
| 28. Retroactive Verification Sweep (Phases 13–19) | v2.1 | 2/2 | Complete    | 2026-04-19 |
| 29. Live Video Traffic Feed (Sat + Drone + Suggestions) | v2.1 | 11/11 | Complete    | 2026-04-20 |
| 30. Notifications List + Mark-Read + iOS Push Remediation | v2.1 | 4/9 | In Progress|  |

## Backlog

| # | Name | Captured | Notes |
|---|------|----------|-------|
| 999.1 | Multi-party video calls | 2026-04-23 | Extend in-app conversations to support 3+ participants on a video call. Likely touches Angelic AI surface + any existing 1:1 video primitive; needs WebRTC/SFU decision, presence/mute/leave controls, recording posture, and call lifecycle schema. Scope TBD — promote via `/gsd-add-phase` when a milestone covers it. |
| 999.2 | Multi-party phone (voice) calls | 2026-04-23 | Group voice call variant of 999.1 — N participants on an audio-only bridge. Needs decision on whether this shares infra with 999.1 (audio-only WebRTC track) or routes through a carrier bridge (Twilio/Agora). Scope TBD. |

### Phase 29: Live Video Traffic Feed (Sat + Drone + Suggestions)

**Goal:** [To be planned — promoted from backlog 2026-04-14]
**Requirements:** TBD
**Depends on:** Phase 21 (Live Satellite Traffic Maps), Phase 22 (Live Site Video)
**Plans:** 11/11 plans complete

Plans:
- [x] TBD (run /gsd-plan-phase 29 to break down) (completed 2026-04-20)

### Phase 29.1: Fix critical auth bug (INSERTED)

**Goal:** iOS auth gate derives its "is the user logged in" decision from the Supabase-issued access token (not local UserDefaults profile state); signup is server-first so Supabase failures cannot leave a zombie local account; signOut clears both Keychain auth tokens and UserDefaults profile state.
**Requirements**: AUTH-GATE-01, AUTH-GATE-02, AUTH-GATE-03
**Depends on:** Phase 29
**Plans:** 5/5 plans complete

Plans:
- [x] 29.1-01-PLAN.md — Wave 0 AuthGateTests.swift scaffolding (5 @Test stubs for criteria A-E)
- [x] 29.1-02-PLAN.md — Wave 1 SupabaseService.signOutEverywhere() + SettingsProfileView wire-up (AUTH-GATE-02)
- [x] 29.1-03-PLAN.md — Wave 1 remove UserProfileStore.login(email:password:) dead shim (AUTH-GATE-01 defense-in-depth)
- [x] 29.1-04-PLAN.md — Wave 2 ContentView gate predicate swap + signup ordering inversion (AUTH-GATE-01 + AUTH-GATE-03)
- [x] 29.1-05-PLAN.md — Wave 3 VERIFICATION.md + REQUIREMENTS.md AUTH-GATE entries + human UAT walkthrough

### Phase 30: Notifications List + Mark-Read + iOS Push Remediation

**Goal:** User can view a notification list with unread count badge on web parity with iOS, mark notifications as read individually (per-row) or all at once on both platforms, and receive iOS push notifications for bid deadlines, safety alerts, and assigned tasks on a real device.
**Depends on:** Phase 28
**Requirements:** NOTIF-01, NOTIF-03, NOTIF-05
**Plans:** 4/9 plans executed

Plans:
- [x] 30-01-PLAN.md — Web Server Action mark-read refactor (D-01..D-04) — NOTIF-03
- [x] 30-02-PLAN.md — iOS project-picker + filter persistence + stale recovery + empty state (D-05, D-10..D-12) — NOTIF-01
- [ ] 30-03-PLAN.md — Web project-picker dropdown + URL searchParam (D-06..D-12) — NOTIF-01
- [ ] 30-04-PLAN.md — Filter-scoped mark-all + bell-badge parity + 30-PARITY-SPEC.md + 99+ cap tests (D-13..D-15) — NOTIF-01, NOTIF-03
- [ ] 30-05-PLAN.md — iOS Realtime subscription on cs_notifications (D-16) — NOTIF-01
- [ ] 30-06-PLAN.md — Cross-platform inbox_filter_changed analytics (D-17) — NOTIF-01
- [x] 30-07-PLAN.md — entity_id/entity_type passthrough audit (D-24) — NOTIF-01
- [x] 30-08-PLAN.md — Push Edge Function Deno-test coverage (D-21) + APNsRegistrationTests unchanged audit (D-22) — NOTIF-05
- [ ] 30-09-PLAN.md — 30-DEPLOY-STEPS.md (D-19) + real-device UAT walkthrough with 3 screenshots (D-18) — NOTIF-05 [autonomous: false]

**Deferred (explicitly excluded from this phase):**
- D-20: APNs production cutover (aps-environment=production, APNS_HOST=api.push.apple.com) — future phase, NOT pre-registered on roadmap per CONTEXT.md
- D-23: Notification-tap deep-link routing (UNUserNotificationCenterDelegate + userInfo payload) — future phase; D-24 future-prep keeps it cheap

**Evidence basis (from 28-01 VERIFICATION.md):**
- NOTIF-01: iOS InboxView project-filter UI missing (14-04-SUMMARY.md KL #4); web has no NotificationsStore/InboxView equivalent (grep returns 0 files).
- NOTIF-03: Web per-row mark-read form submits POST to `/api/notifications/[id]?_method=PATCH` but route only exports PATCH/DELETE (14-03-SUMMARY.md KL #1). iOS side works; cross-platform success criterion unmet.
- NOTIF-05: `aps-environment` entitlement set but Apple Developer portal Push Notifications capability toggle never recorded; no real-device delivery test on file (14-05-SUMMARY.md "Manual Steps Required Before Push Delivery Works").
