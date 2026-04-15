# Requirements: ConstructionOS v2.1 Gap Closure & Feature Completion

**Defined:** 2026-04-14 (carried from v2.0 after milestone scope reduction)
**Core Value:** Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## v2.1 Requirements

27 requirements carried from v2.0. Phase code exists on `main`; verification, wiring, and cross-phase integration are the remaining work.

### Notifications & Activity Feed

- [ ] **NOTIF-01**: User can view in-app notification list with unread count badge
- [ ] **NOTIF-02**: User can view activity timeline per project (chronological action log)
- [ ] **NOTIF-03**: User can mark notifications as read (individually or all)
- [ ] **NOTIF-04**: User can dismiss notifications
- [ ] **NOTIF-05**: User receives push notifications on iOS for bid deadlines, safety alerts, and assigned tasks

### Document Management

- [ ] **DOC-01**: User can upload files (PDF, images, drawings) to Supabase Storage
- [ ] **DOC-02**: User can download attached files
- [ ] **DOC-03**: User can attach files to projects, RFIs, submittals, and change orders
- [ ] **DOC-04**: User can preview PDFs and images in-app without downloading
- [ ] **DOC-05**: User can view version history of revised documents

### Team & Crew Management

- [x] **TEAM-01**: User can create team member profiles with role, trade, and contact info
- [x] **TEAM-02**: User can assign team members to projects with role assignments
- [x] **TEAM-03**: User can track certifications and licenses with expiration dates
- [ ] **TEAM-04**: User receives alerts when certifications are nearing expiration
- [x] **TEAM-05**: User can create daily crew assignments per project

### Reporting & Dashboards

- [ ] **REPORT-01**: User can generate single-project summary report (budget, schedule, issues, team)
- [ ] **REPORT-02**: User can view cross-project financial rollup dashboard
- [ ] **REPORT-03**: User can export reports to PDF
- [ ] **REPORT-04**: User can view chart visualizations (bar/line/pie) for budgets, timelines, and safety metrics

### Field Tools

- [ ] **FIELD-01**: User can capture photos with automatic GPS location and timestamp tagging
- [ ] **FIELD-02**: User can attach photos to punch items, daily logs, and safety incidents
- [ ] **FIELD-03**: User can annotate/markup photos to highlight issues
- [ ] **FIELD-04**: User can create daily logs from pre-filled templates based on project context

### Calendar & Scheduling

- [ ] **CAL-01**: User can view a timeline of all projects with milestones and bid due dates
- [ ] **CAL-02**: User can view a Gantt chart with task bars and dependencies
- [x] **CAL-03**: Timeline highlights milestone markers (bid due, project start/end, inspections)
- [ ] **CAL-04**: User can drag items on timeline to reschedule them

### Live Site Video (Phase 22)

VIDEO-01 expanded into 16 sub-requirements during Phase 22 planning (2026-04-15). Every sub-requirement is claimed by at least one plan's `requirements` frontmatter field.

- [x] **VIDEO-01-A**: Data model — `cs_video_sources` (per camera) and `cs_video_assets` (per clip or live session) exist with `source_type` discriminator for Phase 29 row-only extension, `audio_enabled`, `portal_visible`, `retention_expires_at`, and `name` columns per D-07/D-08/D-21/D-35/D-38 (Plans 22-01, 22-02)
- [x] **VIDEO-01-B**: RLS — `cs_video_sources` and `cs_video_assets` enforce org-scoped SELECT/INSERT/UPDATE via `user_orgs`; DELETE role-gated (owner/admin or created_by self) per D-16/D-39 (Plan 22-01)
- [x] **VIDEO-01-C**: Storage — private `videos` Supabase bucket with org-path RLS, 2 GB file_size_limit, MP4/MOV/m3u8/ts/jpeg MIME allowlist per D-12/D-17/D-31 (Plan 22-01)
- [x] **VIDEO-01-D**: Live ingest — POST /api/video/mux/create-live-input creates Mux live_input (LL-HLS, 60s reconnect_window, signed playback, DVR archive) and inserts cs_video_sources row with atomic rollback on failure per D-03/D-04/D-29 (Plan 22-03)
- [x] **VIDEO-01-E**: Playback auth (live) — POST /api/video/mux/playback-token mints RS256 Mux JWT bound to playback_id with TTL ≤ 5 min per D-14 (Plan 22-03)
- [x] **VIDEO-01-F**: Playback wrappers — iOS `LiveStreamView` + `VideoClipPlayer` over AVPlayer; web `<LiveStreamView>` + `<VideoClipPlayer>` over @mux/mux-player-react; both accept optional portalToken per D-18/D-19 (Plans 22-06, 22-07)
- [ ] **VIDEO-01-G**: VOD upload — tus resumable upload to Supabase Storage with 6 MB chunks, 3× retry, client-side D-31 pre-check (2 GB / 60 min / MP4 or MOV) per D-05/D-24/D-31 (Plans 22-04, 22-08)
- [ ] **VIDEO-01-H**: VOD transcode — ffmpeg worker on Fly.io single-bitrate HLS output (1280x720@2500k, hls_time 6) with ffprobe codec pre-check + 2x retry on failure per D-05/D-06/D-33 (Plan 22-04)
- [ ] **VIDEO-01-I**: VOD playback — GET /api/video/vod/playback-url returns HLS manifest with batch-signed per-segment URLs (Supabase-directory-signing workaround) and TTL = 1 h per D-13/D-14 (Plan 22-04)
- [ ] **VIDEO-01-J**: iOS service layer — SupabaseService extensions, VideoSyncManager cache, VideoPlaybackAuth client, VideoUploadClient with probeFile + retry (Plan 22-05)
- [ ] **VIDEO-01-K**: Cellular auto-downgrade — iOS NWPathMonitor defaults player to 480p on cellular; ConstructOS.Video.DefaultQuality AppStorage override; HD toggle overlay current-session only per D-26/D-36 (Plans 22-05, 22-06)
- [x] **VIDEO-01-L**: Portal exposure — cs_portal_config.show_cameras toggle + per-clip portal_visible; /api/portal/video/playback-token + /api/portal/video/playback-url enforce drone exclusion + head-only live + streaming-only VOD per D-15/D-21/D-22/D-34 (Plans 22-01, 22-09)
- [x] **VIDEO-01-M**: Error taxonomy — 9 new AppError cases (unsupportedVideoFormat, clipTooLong, clipTooLarge, audioConsentRequired, transcodeTimeout, muxIngestFailed, muxDeleteFailed, cameraLimitReached, webhookSignatureInvalid); wire-portable VideoErrorCode enum for web per D-40 discretion (Plan 22-02)
- [x] **VIDEO-01-N**: Webhook security — Mux HMAC verify + cs_video_webhook_events dedupe table with 7-day prune; 5-min disconnect-grace window (D-27) before closing live asset rows per D-32/D-27 (Plans 22-01 [dedupe table], 22-03 [HMAC verify + grace], 22-10 [7-day prune])
- [ ] **VIDEO-01-O**: Retention + lifecycle — daily cron prunes VOD (30 d) + live assets (24 h after ended_at) + Mux archived assets; archives idle fixed_camera sources after 30 d + disables Mux live_input; prunes webhook-events older than 7 d; every-5-min backstop requeues stuck uploads per D-09/D-10/D-30/D-32 (Plan 22-10)
- [ ] **VIDEO-01-P**: Analytics — 8 D-40 events (video_upload_started/failed, video_transcode_succeeded/failed, live_stream_started/disconnected, video_playback_started, portal_video_view) wired at all call sites with org/project/user context; no PII in payloads (Plan 22-11)

**Soft cap + audio posture:** VIDEO-01-D also implements D-28 20-camera soft cap (warning at 16, disable at 20) and D-35 audio-opt-in with jurisdiction-warning confirmation + mute-on-boot in every player.

## Carried Integration Blockers

These gaps were identified in the v2.0 milestone audit and remain open at v2.1 start.

| ID | Severity | Description | Affects | Owning v2.1 phase |
|----|----------|-------------|---------|-------------------|
| INT-01 | high | RLS references non-existent `cs_rfis`/`cs_submittals`/`cs_change_orders` | DOC-03, DOC-04 | Phase 26 |
| INT-02 | high | Document routes do not emit `cs_activity_events` | DOC-02, NOTIF-02 | Phase 24 |
| INT-06 | critical | Cert expiration does not trigger notifications | NOTIF-04, TEAM-04 | Phase 25 |
| INT-07 | medium | Portal home has no navigation to `/map` sub-route | (supports PORTAL-03, MAP-04) | Phase 27 |

**Closed by quick task 260414-n4w (2026-04-14):**
- ~~INT-03~~: iOS Team/Crew/Certs views not wired to NavTab
- ~~INT-04~~: DailyCrewView uses insert not upsert
- ~~INT-05~~: AgendaListView not wired into ScheduleHubView

## Future Requirements

Deferred to v2.2 or later.

### Notifications

- **NOTIF-F1**: Email notification delivery
- **NOTIF-F2**: Web push notifications (browser)
- **NOTIF-F3**: Notification preference settings per category

### Documents

- **DOC-F1**: Folder organization
- **DOC-F2**: PDF annotation/markup
- **DOC-F3**: Full-text search across documents

### Reporting

- **REPORT-F1**: Custom dashboard builder
- **REPORT-F2**: Scheduled report delivery via email
- **REPORT-F3**: Excel/CSV export

### AI

- **AI-F1**: MCP tool integration for external data sources
- **AI-F2**: Voice-to-text input

### Field

- **FIELD-F1**: Offline photo queue with sync on reconnect
- **FIELD-F2**: Voice memo capture

## Out of Scope (carried from v2.0)

| Feature | Reason |
|---------|--------|
| Real-time collaboration / conflict resolution | Architecture change — future milestone |
| Offline-first / local data sync queue | Future milestone — requires architectural rework |
| Breaking apart monolithic ContentView.swift | Separate refactoring initiative |
| OAuth login (Google, Apple) | Deferred beyond v2.1 |
| Payment processing for client portal | Read-only portals only |
| Mobile-native client portal app | Web portal sufficient |
| Real-time crew GPS tracking | Privacy concerns — defer until policy defined |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| NOTIF-01 | Phase 28 (verification) | Pending |
| NOTIF-02 | Phase 24 (gap closure) | Pending |
| NOTIF-03 | Phase 28 (verification) | Pending |
| NOTIF-04 | Phase 25 (gap closure) | Pending |
| NOTIF-05 | Phase 28 (verification) | Pending |
| DOC-01 | Phase 28 (verification) | Pending |
| DOC-02 | Phase 24 (gap closure) | Pending |
| DOC-03 | Phase 26 (gap closure) | Pending |
| DOC-04 | Phase 26 (gap closure) | Pending |
| DOC-05 | Phase 28 (verification) | Pending |
| TEAM-01 | Phase 23 | Satisfied |
| TEAM-02 | Phase 23 | Satisfied |
| TEAM-03 | Phase 23 | Satisfied |
| TEAM-04 | Phase 25 (gap closure) | Pending |
| TEAM-05 | Phase 23 | Satisfied |
| FIELD-01 | Phase 28 (verification) | Pending |
| FIELD-02 | Phase 28 (verification) | Pending |
| FIELD-03 | Phase 28 (verification) | Pending |
| FIELD-04 | Phase 28 (verification) | Pending |
| CAL-01 | Phase 28 (verification) | Pending |
| CAL-02 | Phase 28 (verification) | Pending |
| CAL-03 | Phase 23 | Satisfied |
| CAL-04 | Phase 28 (verification) | Pending |
| REPORT-01 | Phase 28 (verification) | Pending |
| REPORT-02 | Phase 28 (verification) | Pending |
| REPORT-03 | Phase 28 (verification) | Pending |
| REPORT-04 | Phase 28 (verification) | Pending |
| VIDEO-01-A | Phase 22 (22-01) | Satisfied |
| VIDEO-01-B | Phase 22 (22-01) | Satisfied |
| VIDEO-01-C | Phase 22 (22-01) | Satisfied |
| VIDEO-01-D | Phase 22 (planned) | Complete |
| VIDEO-01-E | Phase 22 (planned) | Complete |
| VIDEO-01-F | Phase 22 (planned) | Complete |
| VIDEO-01-G | Phase 22 (planned) | Pending |
| VIDEO-01-H | Phase 22 (planned) | Pending |
| VIDEO-01-I | Phase 22 (planned) | Pending |
| VIDEO-01-J | Phase 22 (planned) | Pending |
| VIDEO-01-K | Phase 22 (planned) | Pending |
| VIDEO-01-L | Phase 22 (planned) | Complete |
| VIDEO-01-M | Phase 22 (planned) | Complete |
| VIDEO-01-N | Phase 22 (22-01 dedupe table; 22-03 HMAC verify; 22-10 7-day prune) | Satisfied |
| VIDEO-01-O | Phase 22 (planned) | Pending |
| VIDEO-01-P | Phase 22 (planned) | Pending |

**Coverage:**
- v2.1 requirements: 43 total (27 carryover + 16 Phase 22 sub-requirements VIDEO-01-A..P)
- Mapped to phases: 43
- Unmapped: 0
- **Satisfied so far (v2.1): 9** — TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03 (Phase 23, 2026-04-14) + VIDEO-01-A, VIDEO-01-B, VIDEO-01-C, VIDEO-01-N (Phase 22-01, 2026-04-15)
- Shipped in v2.0: 0 (see `milestones/v2.0-REQUIREMENTS.md` for AI/PORTAL/MAP — 12 shipped)

---
*v2.1 requirements carried forward 2026-04-14 after v2.0 milestone scope reduction. See `milestones/v2.0-MILESTONE-AUDIT.md` for the audit that drove the scope change.*
