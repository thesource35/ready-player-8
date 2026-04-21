# Requirements: ConstructionOS v2.1 Gap Closure & Feature Completion

**Defined:** 2026-04-14 (carried from v2.0 after milestone scope reduction)
**Core Value:** Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## Requirement Status Legend

Phase 28 reconciliation (D-09) introduces a three-state convention for inline tick boxes and the Traceability table at the bottom of this file:

- `[x]` **Satisfied** — code evidence green AND (no UAT needed OR UAT complete with pass verdict)
- `[~]` **Partial** — code evidence green, but UAT enumerated in the owning VERIFICATION.md and not yet walked (or user deferred)
- `[ ]` **Unsatisfied** — code evidence missing in the owning phase; a remediation phase owns the fix

Downstream tools and reviewers MUST treat `[~]` as distinct from `[x]` (partial is not passing) and distinct from `[ ]` (work is done, human sign-off is the only missing piece).

## v2.1 Requirements

27 requirements carried from v2.0. Phase code exists on `main`; verification, wiring, and cross-phase integration are the remaining work.

### Notifications & Activity Feed

- [ ] **NOTIF-01**: User can view in-app notification list with unread count badge
- [x] **NOTIF-02**: User can view activity timeline per project (chronological action log)
- [ ] **NOTIF-03**: User can mark notifications as read (individually or all)
- [x] **NOTIF-04**: User can dismiss notifications
- [ ] **NOTIF-05**: User receives push notifications on iOS for bid deadlines, safety alerts, and assigned tasks

### Document Management

- [~] **DOC-01**: User can upload files (PDF, images, drawings) to Supabase Storage
- [x] **DOC-02**: User can download attached files
- [x] **DOC-03**: User can attach files to projects, RFIs, submittals, and change orders
- [~] **DOC-04**: User can preview PDFs and images in-app without downloading
- [~] **DOC-05**: User can view version history of revised documents

### Team & Crew Management

- [x] **TEAM-01**: User can create team member profiles with role, trade, and contact info
- [x] **TEAM-02**: User can assign team members to projects with role assignments
- [x] **TEAM-03**: User can track certifications and licenses with expiration dates
- [x] **TEAM-04**: User receives alerts when certifications are nearing expiration
- [x] **TEAM-05**: User can create daily crew assignments per project

### Reporting & Dashboards

- [~] **REPORT-01**: User can generate single-project summary report (budget, schedule, issues, team)
- [~] **REPORT-02**: User can view cross-project financial rollup dashboard
- [~] **REPORT-03**: User can export reports to PDF
- [~] **REPORT-04**: User can view chart visualizations (bar/line/pie) for budgets, timelines, and safety metrics

### Field Tools

- [~] **FIELD-01**: User can capture photos with automatic GPS location and timestamp tagging
- [x] **FIELD-02**: User can attach photos to punch items, daily logs, and safety incidents
- [x] **FIELD-03**: User can annotate/markup photos to highlight issues
- [~] **FIELD-04**: User can create daily logs from pre-filled templates based on project context

### Calendar & Scheduling

- [~] **CAL-01**: User can view a timeline of all projects with milestones and bid due dates
- [~] **CAL-02**: User can view a Gantt chart with task bars and dependencies
- [x] **CAL-03**: Timeline highlights milestone markers (bid due, project start/end, inspections)
- [~] **CAL-04**: User can drag items on timeline to reschedule them

### Live Site Video (Phase 22)

VIDEO-01 expanded into 16 sub-requirements during Phase 22 planning (2026-04-15). Every sub-requirement is claimed by at least one plan's `requirements` frontmatter field.

- [x] **VIDEO-01-A**: Data model — `cs_video_sources` (per camera) and `cs_video_assets` (per clip or live session) exist with `source_type` discriminator for Phase 29 row-only extension, `audio_enabled`, `portal_visible`, `retention_expires_at`, and `name` columns per D-07/D-08/D-21/D-35/D-38 (Plans 22-01, 22-02)
- [x] **VIDEO-01-B**: RLS — `cs_video_sources` and `cs_video_assets` enforce org-scoped SELECT/INSERT/UPDATE via `user_orgs`; DELETE role-gated (owner/admin or created_by self) per D-16/D-39 (Plan 22-01)
- [x] **VIDEO-01-C**: Storage — private `videos` Supabase bucket with org-path RLS, 2 GB file_size_limit, MP4/MOV/m3u8/ts/jpeg MIME allowlist per D-12/D-17/D-31 (Plan 22-01)
- [x] **VIDEO-01-D**: Live ingest — POST /api/video/mux/create-live-input creates Mux live_input (LL-HLS, 60s reconnect_window, signed playback, DVR archive) and inserts cs_video_sources row with atomic rollback on failure per D-03/D-04/D-29 (Plan 22-03)
- [x] **VIDEO-01-E**: Playback auth (live) — POST /api/video/mux/playback-token mints RS256 Mux JWT bound to playback_id with TTL ≤ 5 min per D-14 (Plan 22-03)
- [x] **VIDEO-01-F**: Playback wrappers — iOS `LiveStreamView` + `VideoClipPlayer` over AVPlayer; web `<LiveStreamView>` + `<VideoClipPlayer>` over @mux/mux-player-react; both accept optional portalToken per D-18/D-19 (Plans 22-06, 22-07)
- [x] **VIDEO-01-G**: VOD upload — tus resumable upload to Supabase Storage with 6 MB chunks, 3× retry, client-side D-31 pre-check (2 GB / 60 min / MP4 or MOV) per D-05/D-24/D-31 (Plans 22-04, 22-08)
- [x] **VIDEO-01-H**: VOD transcode — ffmpeg worker on Fly.io single-bitrate HLS output (1280x720@2500k, hls_time 6) with ffprobe codec pre-check + 2x retry on failure per D-05/D-06/D-33 (Plan 22-04)
- [x] **VIDEO-01-I**: VOD playback — GET /api/video/vod/playback-url returns HLS manifest with batch-signed per-segment URLs (Supabase-directory-signing workaround) and TTL = 1 h per D-13/D-14 (Plan 22-04)
- [x] **VIDEO-01-J**: iOS service layer — SupabaseService extensions, VideoSyncManager cache, VideoPlaybackAuth client, VideoUploadClient with probeFile + retry (Plan 22-05)
- [x] **VIDEO-01-K**: Cellular auto-downgrade — iOS NWPathMonitor defaults player to 480p on cellular; ConstructOS.Video.DefaultQuality AppStorage override; HD toggle overlay current-session only per D-26/D-36 (Plans 22-05, 22-06)
- [x] **VIDEO-01-L**: Portal exposure — cs_portal_config.show_cameras toggle + per-clip portal_visible; /api/portal/video/playback-token + /api/portal/video/playback-url enforce drone exclusion + head-only live + streaming-only VOD per D-15/D-21/D-22/D-34 (Plans 22-01, 22-09)
- [x] **VIDEO-01-M**: Error taxonomy — 9 new AppError cases (unsupportedVideoFormat, clipTooLong, clipTooLarge, audioConsentRequired, transcodeTimeout, muxIngestFailed, muxDeleteFailed, cameraLimitReached, webhookSignatureInvalid); wire-portable VideoErrorCode enum for web per D-40 discretion (Plan 22-02)
- [x] **VIDEO-01-N**: Webhook security — Mux HMAC verify + cs_video_webhook_events dedupe table with 7-day prune; 5-min disconnect-grace window (D-27) before closing live asset rows per D-32/D-27 (Plans 22-01 [dedupe table], 22-03 [HMAC verify + grace], 22-10 [7-day prune])
- [x] **VIDEO-01-O**: Retention + lifecycle — daily cron prunes VOD (30 d) + live assets (24 h after ended_at) + Mux archived assets; archives idle fixed_camera sources after 30 d + disables Mux live_input; prunes webhook-events older than 7 d; every-5-min backstop requeues stuck uploads per D-09/D-10/D-30/D-32 (Plan 22-10)
- [x] **VIDEO-01-P**: Analytics — 8 D-40 events (video_upload_started/failed, video_transcode_succeeded/failed, live_stream_started/disconnected, video_playback_started, portal_video_view) wired at all call sites with org/project/user context; no PII in payloads (Plan 22-11)

**Soft cap + audio posture:** VIDEO-01-D also implements D-28 20-camera soft cap (warning at 16, disable at 20) and D-35 audio-opt-in with jurisdiction-warning confirmation + mute-on-boot in every player.

### Live Video Traffic Feed (Phase 29)

Phase 29 composes Phase 22's shipped video pipeline + Phase 21's map surface + Anthropic Claude vision into a new top-level "Live Feed" tab surfacing drone-clip playback, per-project + Fleet views, and scheduled AI observation cards. Added 2026-04-19 per Phase 29 RESEARCH LIVE-01..LIVE-14 namespace.

- [x] **LIVE-01**: Drone upload path — `/api/video/vod/upload-url` accepts `source_type: 'drone'` from request body (enum check `'upload' | 'drone'`) and inserts `cs_video_assets` row with the drone discriminator; iOS `VideoUploadClient.upload()` gains optional `sourceType` param per D-08/D-10/D-11 (Plans 29-02)
- [~] **LIVE-02**: Drone HLS playback parity — drone-typed `cs_video_assets` rows play through existing `@mux/mux-player-react VideoClipPlayer` (web) and `VideoClipPlayer` + `VideoPlaybackAuth.vodManifestUrl` (iOS) with ZERO new player components per D-10 (Plans 29-02 verify, 29-06/29-09 consume) — *code green; end-to-end drone upload → transcode → playback on both platforms pending human UAT*
- [~] **LIVE-03**: Live Feed surface — iOS `NavTab.liveFeed` case in `intel` group renders `LiveFeedView`; web `/live-feed/page.tsx` server component + nav entry returns 200 per D-04/D-05 (Plans 29-05 iOS, 29-08 web) — *code green (BUILD SUCCEEDED + 8 vitest GREEN); human nav walk-through pending*
- [~] **LIVE-04**: Project switcher + Fleet toggle persistence — selection persists to `ConstructOS.LiveFeed.LastSelectedProjectId`; Fleet toggle persists to `ConstructOS.LiveFeed.LastFleetSelection` on both platforms per D-06/D-07/D-23 (Plans 29-05 iOS, 29-08 web) — *code green; persistence verified via unit tests; multi-session persistence pending human UAT*
- [x] **LIVE-05**: `cs_live_suggestions` schema — new table with `id/project_id/org_id/generated_at/source_asset_id/model/suggestion_text/action_hint jsonb/dismissed_at/dismissed_by` columns + 3 indexes + RLS (org_id IN user_orgs pattern, mirrors cs_equipment) per D-17/D-24 (Plan 29-01) — *remote DB verified 2026-04-19: 2 policies, 3 indexes, 3 FKs*
- [~] **LIVE-06**: `generate-live-suggestions` Edge Function — Deno function iterating active projects, budget pre-check (96/day), reads poster.jpg via 60s signed URL, calls Anthropic vision Haiku default, inserts cs_live_suggestions rows; scheduled via pg_cron `*/15 * * * *` per D-14/D-15/D-25 (Plan 29-03) — *pg_cron schedule registered + Edge Function deployed; observing first real 15-min tick generating a suggestion pending*
- [~] **LIVE-07**: Per-upload pg_net trigger — `trg_notify_live_suggestions` on `cs_video_assets AFTER UPDATE` fires when `source_type='drone' AND new.status='ready' AND old.status IS DISTINCT FROM 'ready'`, invoking Edge Function with `?project_id=X` per D-14/D-25 (Plan 29-04) — *trigger registered on remote; first real drone upload → suggestion generation pending*
- [x] **LIVE-08**: Anthropic vision adapter — shared prompt builder + JSON schema validator in `web/src/lib/live-feed/anthropic-vision.ts` used by both the Edge Function (via mirrored copy) and `/api/live-feed/analyze/route.ts`; malformed Anthropic responses are logged and dropped, never persisted per D-13/D-15/D-16 (Plans 29-03, 29-10) — *8 vitest GREEN incl. malformed-payload rejection*
- [~] **LIVE-09**: Suggestion cards — iOS `LiveSuggestionCardRow` (horizontal swipable) + web `LiveSuggestionStream` (vertical side panel) render cards with severity-colored border (green/gold/red per UI-SPEC) and swipe/click dismiss updating `dismissed_at + dismissed_by` per D-13/D-17 (Plans 29-07 iOS, 29-10 web) — *code green (3 vitest + 3 XCTest GREEN); real suggestion dismiss flow pending human UAT*
- [~] **LIVE-10**: Unified Traffic card — `TrafficUnifiedCard` combines Phase 21 road-traffic tile summary with on-site-movement summary derived from latest suggestion's `action_hint.structured_fields` per D-18 (Plans 29-07 iOS, 29-10 web) — *on-site section wired; road-traffic Phase 21 tile integration deferred to follow-up per CONTEXT Claude's Discretion — static "Light" placeholder ships v1*
- [~] **LIVE-11**: Cost cap UX — `GET /api/live-feed/budget?project_id=X` returns `{used, remaining, resetsAt, cap:96}`; `BudgetBadge` visible in Live Feed header on both platforms with healthy/warning/reached states; `AnalyzeNowButton` disabled at ≥96/day with tooltip per D-22 (Plans 29-07 iOS, 29-10 web) — *code green (4 vitest GREEN); cap-reached disabled-button state pending human UAT under real load*
- [~] **LIVE-12**: 24h scrubber window — `DroneScrubberTimeline` queries `cs_video_assets WHERE source_type='drone' AND created_at > now() - interval '24h'`; older clips surface via separate `ProjectDroneLibrary{Sheet|Panel}` within Phase 22's 30d retention per D-09 (Plans 29-06 iOS, 29-09 web) — *5 vitest partition tests GREEN; real 24h/>24h clip visibility pending human UAT*
- [~] **LIVE-13**: `prune-expired-suggestions` Edge Function — Deno function deleting rows with `generated_at < now() - interval '7d'`; scheduled via pg_cron at `45 3 * * *` (03:45 UTC) staggering off Phase 22's 03:00/03:05/03:30 slots per D-21 (Plan 29-04) — *pg_cron schedule registered + Edge Function deployed; first real >7d row prune pending observation window*
- [x] **LIVE-14**: Portal drone-exclusion regression test — vitest asserts both portal routes return 403 for drone assets: `web/src/app/api/portal/video/playback-url/route.ts` line 107 (`asset.source_type === 'drone'`) and `playback-token/route.ts` line 125 (`source.kind === 'drone'`). **CRITICAL — lands in Wave 1**, not deferred, per D-26 (Plan 29-02) — *4/4 vitest GREEN; zero portal files modified by any Phase 29 plan*

**Deploy-time operator steps (from RESEARCH §Environment Availability):**
- `supabase secrets set ANTHROPIC_API_KEY=<key>` (new, required before Edge Function invocation)
- Phase 22's existing Vault secrets `project_url` + `service_role_key` are reused for pg_cron HTTP POST auth

### Auth Gate (Phase 29.1)

3 requirements added 2026-04-21 to close the critical auth bug RESEARCH identified on the iOS platform. Web platform unaffected (web middleware already gates on `supabase.auth.getUser()` correctly).

- [x] **AUTH-GATE-01**: iOS auth gate predicate (`ContentView.swift:~638`) is driven by `SupabaseService.isAuthenticated` (Keychain-backed accessToken) rather than local `UserProfileStore.currentUser` (UserDefaults). Defense-in-depth includes removal of `UserProfileStore.login(email:password:)` password-free shim (Plan 03). See RESEARCH §Candidate 1.
- [x] **AUTH-GATE-02**: `SupabaseService.signOutEverywhere()` is a composite helper that clears BOTH Keychain auth tokens AND UserDefaults-backed `UserProfileStore.currentUser`. Settings Sign Out button wired to the composite helper. See RESEARCH §Fix 3, PITFALL-03.
- [x] **AUTH-GATE-03**: Signup is server-first — `SupabaseService.signUp()` is awaited before `UserProfileStore.createAccount()` commits local state. Supabase failure leaves `currentUser == nil` and shows retryable error copy (UI-SPEC §Copywriting Contract T4). See RESEARCH §Candidate 2.

Flipped from `[~]` to `[x]` 2026-04-21 after the 3-scenario human UAT walkthrough (VALIDATION.md §Manual-Only Verifications) returned PASS on iOS Simulator (iPhone 17, iOS 26.2 SDK). See `.planning/phases/29.1-fix-critical-auth-bug/29.1-VERIFICATION.md` §UAT Verdict.

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
| NOTIF-01 | Phase 30 (remediation planned) | Unsatisfied |
| NOTIF-02 | Phase 28 (verified); UAT deferred 2026-04-19 | Satisfied |
| NOTIF-03 | Phase 30 (remediation planned) | Unsatisfied |
| NOTIF-04 | Phase 28 (verified) | Satisfied |
| NOTIF-05 | Phase 30 (remediation planned); UAT deferred 2026-04-19 | Unsatisfied |
| DOC-01 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| DOC-02 | Phase 28 (verified) | Satisfied |
| DOC-03 | Phase 28 (verified) | Satisfied |
| DOC-04 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| DOC-05 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| TEAM-01 | Phase 23 | Satisfied |
| TEAM-02 | Phase 23 | Satisfied |
| TEAM-03 | Phase 23 | Satisfied |
| TEAM-04 | Phase 25 (gap closure) | Complete |
| TEAM-05 | Phase 23 | Satisfied |
| FIELD-01 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| FIELD-02 | Phase 28 (verified) | Satisfied |
| FIELD-03 | Phase 28 (verified); UAT deferred 2026-04-19 | Satisfied |
| FIELD-04 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| CAL-01 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| CAL-02 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| CAL-03 | Phase 23 | Satisfied |
| CAL-04 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| REPORT-01 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| REPORT-02 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| REPORT-03 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| REPORT-04 | Phase 28 (verified) + UAT pending; UAT deferred 2026-04-19 | Partial |
| VIDEO-01-A | Phase 22 (22-01) | Satisfied |
| VIDEO-01-B | Phase 22 (22-01) | Satisfied |
| VIDEO-01-C | Phase 22 (22-01) | Satisfied |
| VIDEO-01-D | Phase 22 (planned) | Complete |
| VIDEO-01-E | Phase 22 (planned) | Complete |
| VIDEO-01-F | Phase 22 (planned) | Complete |
| VIDEO-01-G | Phase 22 (planned) | Complete |
| VIDEO-01-H | Phase 22 (planned) | Complete |
| VIDEO-01-I | Phase 22 (planned) | Complete |
| VIDEO-01-J | Phase 22 (planned) | Complete |
| VIDEO-01-K | Phase 22 (planned) | Complete |
| VIDEO-01-L | Phase 22 (planned) | Complete |
| VIDEO-01-M | Phase 22 (planned) | Complete |
| VIDEO-01-N | Phase 22 (22-01 dedupe table; 22-03 HMAC verify; 22-10 7-day prune) | Satisfied |
| VIDEO-01-O | Phase 22 (planned) | Complete |
| VIDEO-01-P | Phase 22 (planned) | Complete |
| LIVE-01 | Phase 29 (29-02) | Satisfied |
| LIVE-02 | Phase 29 (29-02 verify + 29-06/29-09 consume) | Partial |
| LIVE-03 | Phase 29 (29-05 iOS + 29-08 web) | Partial |
| LIVE-04 | Phase 29 (29-05 iOS + 29-08 web) | Partial |
| LIVE-05 | Phase 29 (29-01) | Satisfied |
| LIVE-06 | Phase 29 (29-03) | Partial |
| LIVE-07 | Phase 29 (29-04) | Partial |
| LIVE-08 | Phase 29 (29-03 + 29-10) | Satisfied |
| LIVE-09 | Phase 29 (29-07 iOS + 29-10 web) | Partial |
| LIVE-10 | Phase 29 (29-07 iOS + 29-10 web) | Partial |
| LIVE-11 | Phase 29 (29-07 iOS + 29-10 web) | Partial |
| LIVE-12 | Phase 29 (29-06 iOS + 29-09 web) | Partial |
| LIVE-13 | Phase 29 (29-04) | Partial |
| LIVE-14 | Phase 29 (29-02) | Satisfied |
| AUTH-GATE-01 | Phase 29.1 (29.1-04 + 29.1-03) | Satisfied |
| AUTH-GATE-02 | Phase 29.1 (29.1-02) | Satisfied |
| AUTH-GATE-03 | Phase 29.1 (29.1-04) | Satisfied |

**Coverage (Phase 28 reconciled, D-09 three-state + Phase 29 shipped 2026-04-19 + Phase 29.1 shipped 2026-04-21):**
- v2.1 requirements: 60 total (27 carryover + 16 Phase 22 VIDEO-01-A..P + 14 Phase 29 LIVE-01..LIVE-14 + 3 Phase 29.1 AUTH-GATE-01/02/03)
- Mapped to phases: 60
- Unmapped: 0
- **`[x]` Satisfied: 35** — NOTIF-02, NOTIF-04, DOC-02, DOC-03, TEAM-01..05, CAL-03, FIELD-02, FIELD-03 (12 carryover) + VIDEO-01-A..P (16 Phase 22) + LIVE-01, LIVE-05, LIVE-08, LIVE-14 (4 Phase 29 code-verified) + AUTH-GATE-01, AUTH-GATE-02, AUTH-GATE-03 (3 Phase 29.1 — code green + 3-scenario iOS Simulator UAT PASSED 2026-04-21)
- **`[~]` Partial (code green, UAT pending): 22** — DOC-01, DOC-04, DOC-05, FIELD-01, FIELD-04, CAL-01, CAL-02, CAL-04, REPORT-01..04 (12 carryover) + LIVE-02, LIVE-03, LIVE-04, LIVE-06, LIVE-07, LIVE-09, LIVE-10, LIVE-11, LIVE-12, LIVE-13 (10 Phase 29 — human UAT or first-real-run observation pending)
- **`[ ]` Unsatisfied / Planned: 3** — NOTIF-01, NOTIF-03, NOTIF-05 (Phase 30 remediation planned per D-10)
- Shipped in v2.0: 0 (see `milestones/v2.0-REQUIREMENTS.md` for AI/PORTAL/MAP — 12 shipped)

Methodology (D-09): `[x]` = code evidence green AND (no UAT needed OR UAT complete); `[~]` = code green, UAT enumerated but not yet walked; `[ ]` = code missing in owning phase. See Requirement Status Legend at top of file. AUTH-GATE-01/02/03 added 2026-04-21 per Phase 29.1. AUTH-GATE-01/02/03 UAT walkthrough PASSED 2026-04-21 (3/3 scenarios, iOS Simulator iPhone 17/iOS 26.2 SDK).

---
*v2.1 requirements carried forward 2026-04-14 after v2.0 milestone scope reduction. See `milestones/v2.0-MILESTONE-AUDIT.md` for the audit that drove the scope change.*
*Phase 29 LIVE-01..LIVE-14 added 2026-04-19 during phase planning.*
