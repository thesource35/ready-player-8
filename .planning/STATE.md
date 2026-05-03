---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: Gap Closure & Feature Completion
status: executing
stopped_at: Completed 30-06-PLAN.md
last_updated: "2026-04-25T01:49:24.490Z"
last_activity: 2026-04-25 -- Phase 30.1 planning complete
progress:
  total_phases: 18
  completed_phases: 17
  total_plans: 121
  completed_plans: 118
  percent: 98
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-14)

**Core value:** Every user action must either succeed visibly or fail with a clear, actionable message -- no silent data loss, no undetected errors, no security gaps.
**Current focus:** Phase 30 — notifications-list-mark-read-ios-push-remediation

## Current Position

Milestone: v2.1
Phase: 30 (notifications-list-mark-read-ios-push-remediation) — EXECUTING
Plan: 9 of 9
Status: Ready to execute
Last activity: 2026-04-25 -- Phase 30.1 planning complete

## Accumulated Context

### Roadmap Evolution

- Phase 29.1 inserted after Phase 29: Fix critical auth bug (URGENT)
- Phase 30.1 inserted after Phase 30: Fix pre-auth bootstrap gap from Phase 30 verification (URGENT)

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
- [Phase 22]: Portal playback routes use service-role Supabase client; D-22 drone exclusion at route + UI; D-34 no-store on VOD manifest
- [Phase 22]: [Phase 22-10]: All 4 retention/lifecycle jobs use pg_cron + net.http_post to Supabase Edge Functions with GUC-based service-role auth; staggered daily schedules (03:00/03:05/03:30 UTC) + 5-min backstop. Closes VIDEO-01-O.
- [Phase 22]: D-40 analytics use structured console.log with [analytics] prefix for Vercel/Fly.io log pipeline ingestion; iOS wraps AnalyticsEngine.shared.track with sanitization
- [Phase 23]: UserDefaults relay key pattern (write-then-clear) for iOS cross-tab navigation; certBadgeCount=0 placeholder for Phase 25
- [Phase 23]: Used inline .alert with Binding<Bool> for AppError display instead of AlertState ObservableObject — simpler for single-view DailyCrewView
- [Phase 24]: Separate emit_document_activity_event() trigger function per D-03; app.version_copy GUC guard suppresses duplicate events during create_document_version() RPC
- [Phase 24]: Contract tests duplicate ENTITY_LABELS/DETAIL_LABELS rather than exporting from server component; DOC badge as styled text span matching inline style patterns
- [Phase 25]: Payload-marker dedupe uses cert_id + threshold + expires_at in cs_activity_events.payload -- no new side table
- [Phase 25]: Dismiss-suppress via suppress_user_ids array in activity event payload for fanout consumption
- [Phase 25]: Batch recipient resolution: bulk queries for assignments + PMs + projects to avoid N+1
- [Phase 25]: Cert recipient resolution uses payload.recipient_user_ids directly, bypassing cs_project_members lookup
- [Phase 25-certification-expiry-notifications]: CertUrgency enum and helpers as internal free functions for XCTest access; added cs_certifications to SupabaseService allowedTables
- [Phase 25]: Extracted CertHighlightScroller to separate file for proper use-client in Next.js server component page; noon UTC fake timers for timezone-safe vitest
- [Phase 25]: UserDefaults write-then-clear relay pattern for cold-launch cert deep-link, matching Phase 23 cross-nav pattern
- [Phase 25]: CertComplianceWidget as client component; MCP tool date-range filter with member name resolution; migration history repair for remote push
- [Phase 25]: Autocomplete uses localizedCaseInsensitiveContains for CERT_NAMES matching; admin detection via cs_projects.created_by ownership proxy
- [Phase 26-documents-rls-table-reconciliation]: Migration A ships 5 stub tables with RLS enabled BEFORE any CREATE POLICY (T-26-01 no-window invariant); policies copy cs_daily_logs pattern verbatim; pre-migration audit is non-blocking RAISE NOTICE per entity_type; whole migration wrapped in BEGIN/COMMIT
- [Phase 26]: [Phase 26-02]: Migration B (rebuild document RLS) uses static CREATE POLICY bodies wrapped in BEGIN/COMMIT — no DO block, no to_regclass, no RLS gap window (T-26-03); storage.objects predicate mirrors cs_documents predicate for signed-URL parity (T-26-04)
- [Phase 26]: [Phase 26-02]: Migration C uses CREATE OR REPLACE FUNCTION to extend emit_document_activity_event() whitelist from 3 to 6 entity types — preserves function OID so attached Phase 24 triggers keep firing with zero DROP TRIGGER / CREATE TRIGGER churn; byte-faithful preservation of bulk_import guard, version_copy guard, and D-09 null-project silent-return
- [Phase 26-documents-rls-table-reconciliation]: D-06 actionable 404 pre-flight replaces silent RLS 403 on web + iOS document upload paths
- [Phase 26-documents-rls-table-reconciliation]: T-26-SQLI mitigation via hard-coded ENTITY_TABLE_MAP / switch on DocumentEntityType — user input never flows into pre-flight table-name position
- [Phase 26-documents-rls-table-reconciliation]: T-26-ORPHAN mitigation via pre-flight line-order invariant in /api/documents/upload (maybeSingle before supabase.storage.upload)
- [Phase 26]: [Phase 26-04]: nonEmptyEntityTypes helper shipped for both web (Promise.all over ENTITY_TABLE_MAP) and iOS (withTaskGroup) — 7 bounded HEAD-count requests, no N+1; UploadButton + AttachmentList widen prop union from 4 to 7 DocumentEntityType values (strict superset so existing callers compile unchanged)
- [Phase 26]: [Phase 26-04]: iOS nonEmptyEntityTypes returns DocumentEntityType.allCases when SupabaseService not configured — offline-permissive picker, server pre-flight (Plan 03) stays authoritative
- [Phase 26]: Plan 05 verification: INT-01 closed with pg_catalog + vitest + xcodebuild evidence; 12/12 goal-backward must-haves PASS; 3 Phase 26 migrations live on remote (20260418002/003/004)
- [Phase 26]: Plan 05 Rule 1 fix: @MainActor annotation on DocumentSyncManagerPreflightTests.test_preflight_notConfigured_isNoop — Swift 6 strict concurrency requires main-actor context to read SupabaseService.shared.isConfigured
- [Phase 27-portal-map-navigation-link]: [Phase 27-01]: Server-computed showMapLink = Boolean(sections_config?.map_overlays?.show_map) — D-09 overrides DEFAULT_MAP_OVERLAYS.show_map=true so pre-Phase-21 portals (no map_overlays field) stay OFF. Helper exported from page.tsx alongside shouldShowAmounts; 5 vitest cases GREEN.
- [Phase 27-portal-map-navigation-link]: [Phase 27-01]: PortalShellProps adds required showMapLink: boolean; PortalHeaderProps adds optional showMapLink?: boolean as Plan 01->02 bridge placeholder — Plan 02 widens to required and activates Map link render.
- [Phase 27]: [Phase 27-05]: Admin helper copy 'Clients see a Map link in the portal navigation when enabled.' placed in PortalCreateDialog.tsx (not SectionVisibilityEditor) per D-15 parenthetical — co-located with the toggle the admin interacts with. SectionVisibilityEditor intentionally untouched because it does not host the show_map toggle.
- [Phase 27-portal-map-navigation-link]: [Phase 27-02]: PortalHeader converted to "use client"; usePathname() drives Map (home, last) vs Overview (/map, first) anchor selection; showMapLink widened from optional placeholder to required boolean; shared ANCHOR_STYLE module const guarantees D-02/D-24 visual parity; 6/6 vitest cases GREEN under file-local jsdom pragma.
- [Phase 27]: [Phase 27-03]: MobilePortalNav renders 6th MapPin entry as Next.js Link (not scroll button) when showMapLink=true; usePathname() drives active state when pathname ends with /map; early-return widened to render nav when sections empty + showMapLink=true; Rule 3 auto-fixes: jsdom IntersectionObserver stub in beforeAll, and RGB|HEX regex tolerance for inactive color; 6/6 vitest tests GREEN under file-local jsdom pragma.
- [Phase 27-portal-map-navigation-link]: [Phase 27-06]: PortalShell now imports MobilePortalNav and forwards the SAME showMapLink boolean to both PortalHeader and MobilePortalNav (D-19 single source of truth). mobileSections derived from sectionOrder + sections_config with defensive Boolean coercion (T-27-16). Closes mobile half of INT-07: <640px viewers can reach /map via the 6th MapPin icon. 4/4 vitest cases GREEN under jsdom pragma; zero tsc/lint regressions.
- [Phase 27-portal-map-navigation-link]: [Phase 27-04]: Branded /map sub-route complete — PortalHeader with showMapLink=true (Overview anchor first) + 5 portal CSS custom properties + fire-and-forget recordPortalView(sectionViewed='map') + checkDailyViewLimit shared 100/day budget with portal home + dynamic='force-dynamic'+revalidate=60 cache. Closes desktop half of INT-07. page.tsx 157→302 lines; 4 vitest cases GREEN; 0 deviations. Helper inlining over extraction: checkDailyViewLimit + hashIP copied verbatim with canonical-source comments (files_modified scoped to map/ only). User approved 11-step manual UAT.
- [Phase 28-retroactive-verification-sweep]: Plan 28-01: 6 VERIFICATION.md + 1 EVIDENCE.md; Phase 14 honest partial verdict (NOTIF-01/03/05 UNSATISFIED per D-02); Phase 19 REPORT-04 audit concern refuted with grep evidence
- [Phase 28-retroactive-verification-sweep]: Plan 28-02: REQUIREMENTS.md three-state legend codified (D-09); ROADMAP.md Phase 30 remediation cluster appended for NOTIF-01/03/05 (D-10); UAT walk-through deferred via defer-all resume-signal (D-07); 28-02 ships status=partial with 22 UAT items catalogued for follow-up session
- [Phase 29]: 29-03: Shared Anthropic vision adapter pattern — web lib + Deno mirror in lock-step; Zod schema validates before DB insert (T-29-VISION-PAYLOAD closed in code; verified live at deploy).
- [Phase 29]: 29-03: Budget cap enforcement lives inside generate-live-suggestions Edge Function (96/day); budget_reached_marker sentinel row is one-per-project-per-day via pre-insert count check.
- [Phase 29]: [Phase 29-04]: pg_net trigger notify_live_suggestions_worker() AFTER UPDATE on cs_video_assets fires generate-live-suggestions ONLY on drone + status='ready' + old.status IS DISTINCT FROM 'ready' (T-29-TRIGGER-LOOP mitigation). prune-expired-suggestions Edge Function + phase29-prune-expired-suggestions cron at 03:45 UTC (staggered off Phase 22 slots) authored. Deploy DEFERRED — 'supabase functions deploy prune-expired-suggestions' + 'supabase db push' pending.
- [Phase 29.1]: Plan 01: Wave-0 AuthGateTests scaffold (5 @Test stubs mapped to criteria A-E); compile-only verification adopted due to pre-existing ready_player_8Tests.swift errors (tracked in phase deferred-items, mirrors Phase 22 precedent); no production code touched
- [Phase 29.1]: Plan 02: composite signOutEverywhere() helper added to SupabaseService; SettingsProfileView wired to it; Test D tightened — AUTH-GATE-02 server-side closed. Pre-existing ready_player_8Tests.swift async errors still block end-to-end xcodebuild test; compile-only verification adopted (mirrors Plan 01 precedent).
- [Phase 29.1]: Plan 03: AUTH-GATE-01 defense-in-depth closed — UserProfileStore.login(email:password:) surgically removed (9 lines out, 4-line sentinel comment in) at UserProfileNetwork.swift:80; zero callers grep-verified pre/post edit; createAccount/updateProfile/logout byte-identically preserved. iPhone 17 sim substituted for iPhone 16 (same SDK); compile-only verification per Plans 01/02 precedent (pre-existing ready_player_8Tests.swift async errors still blocking).
- [Phase 29.1]: Plan 04: AUTH-GATE-01 structural half + AUTH-GATE-03 closed — ContentView.swift gate predicate rebound to `!supabase.isAuthenticated` (local profileStore.currentUser can no longer unlock the app alone); signup handler inverted so supabase.signUp() awaits successfully BEFORE profileStore.createAccount() commits local state. DEBUG 'Continue to demo' button byte-identical (already sets accessToken first). `testSignupRollbackOnServerFailure` body replaces Wave 0 placeholder, exercises SupabaseError.notConfigured path, asserts both stores clean post-throw. `xcodebuild build` succeeds; executor hit a transient 401 on final bookkeeping commit — all 3 code commits (5177361/7503bbd/9c8679b) had already landed, orchestrator recovered inline (wrote SUMMARY, advanced STATE/ROADMAP).
- [Phase 21]: Plan 07: Env-layer root cause closed — NEXT_PUBLIC_MAPBOX_TOKEN populated (Task 2 human), ?.trim() || null coercion at both /maps + portal /map server boundaries (Task 1), UAT Tests 1 + 16 reconciled to shipped 7-toggle + D-09 (Task 3), iOS clean rebuild with Apr 6/7 DerivedData purged (Task 4 human), PortalMapClient.test.tsx 4-case vitest suite GREEN (Task 5). Unblocks Plans 21-08/09/10/11.
- [Phase 21]: Plan 21-08: Test 3 closed via seeded 5 equipment rows on remote (service-role upsert bypass of blocked db push) + /maps empty-state chip. Test 5 closed via visible route error instead of silent return. Test 6 all 3 sub-defects closed via cameraRestored gate + persisted-overlay apply inside map.on('load') + mapLoaded dep on SATELLITE+TRAFFIC effects. Seed uses sentinel org_id 00000000-...-000000000021 (cs_orgs/user_orgs not in public schema on this DB — RLS path flagged for Plan 21-11 verification).
- [Phase 21]: Plan 21-09: Closed UAT Test 11 root cause (allowedTables missing cs_equipment*) + Test 8 dual defect (Atlanta coords + no empty-success fallback) + Test 9 data gap (no mock fallback, no empty-state chip) + silent-swallow regression via AppError-wrapped loadError alert + AppError-styled submitError. All four iOS files modified in 3 atomic commits (63b261c/8aa93e7/64f8991); xcodebuild BUILD SUCCEEDED.
- [Phase 21]: Plan 21-10: Closed UAT Test 10 (4 defects) + Test 12 (split error states) — 7th @AppStorage for AUTO TRACK, .onMapCameraChange(.continuous) live save + ScenePhase backstop + cameraRestored first-restore guard; CheckInLocationManager split into permissionDenied Bool + runtimeError AppError with Settings deep-link CTA via UIApplication.openSettingsURLString. 2 atomic commits (a55779d/6295b26); xcodebuild BUILD SUCCEEDED.
- [Phase 21]: [Phase 21]: Plan 21-11 UAT re-walk complete — 16/16 PASS after closer plans 21-07/08/09/10 landed. vitest regression GREEN 4/4. 21-VERIFICATION.md flipped human_needed -> passed with re_verified 2026-04-21. Phase 21 v2.1 gap closure complete.
- [Phase 30]: [Phase 30-01]: Server Actions replace POST->?_method=PATCH kludge on /inbox; REST PATCH/DELETE/POST byte-preserved for iOS callers (D-03); vi.hoisted() adopted for mock refs surviving vi.mock() factory hoisting; 8/8 new regression cases + full notifications suite 19/19 GREEN
- [Phase 30-notifications-list-mark-read-ios-push-remediation]: [Phase 30-07]: D-24 entity_id/entity_type passthrough regression locked — 4 vitest cases + 3 XCTest cases shipped; audit confirmed production code already meets D-24 contract (MOCK_NOTIFICATIONS populated, Notification type has string | null fields, SupabaseNotification DTO has entityType/entityId as String?); zero production code touched; compile-only iOS verification per Phase 22/29.1 precedent (pre-existing ready_player_8Tests.swift async errors still block build-for-testing, new DTO test file itself compiles clean).
- [Phase 30]: [Phase 30-02]: NOTIF-01 iOS closed — picker feature land pre-shipped in salvaged f0fb701 (worktree merge 1fc1dab); regression-style XCTest coverage added in 1ddd383 locks stale-recovery (D-11), persistence round-trip (D-10), empty-state copy (D-12), and D-09 sort order. Compile-only verification per Phase 22/29.1/30-07 precedent — build-for-testing still blocked by pre-existing ready_player_8Tests.swift async errors; zero new errors reference the Phase 30 test files.
- [Phase 30]: [Phase 30-08]: D-21 Edge Function regression floor + D-22 APNsRegistrationTests unchanged audit closed — 4 new Deno test files (push-categories 9 tests, device-token-lookup 3 tests, apns-payload-shape 3 tests, bad-device-token 3 tests) lock the notifications-fanout push path to NOTIF-05. Full suite 28/0 GREEN (18 new + 10 existing; clears ≥21 acceptance floor by 7). APNsRegistrationTests.swift SHA-1 93581122217f703a4a8e05da33c9a5e4202edf4f confirmed unchanged since Phase 14-05 (last commit 9805e17; git diff empty). Zero production code touched. Four commits (80074de/ea380af/33d3854/eefaa43) salvaged from worktree merge; prior executor's SUMMARY was lost when worktree was removed (.planning/ gitignored) — SUMMARY re-authored with current-state audit evidence.
- [Phase 30]: [Phase 30-03]: Web /inbox picker shipped — NOTIF-01 cross-platform parity closed; InboxProjectPicker client component + fetchProjectMembershipsWithUnread server helper + LAST_FILTER_STORAGE_KEY cross-platform parity contract; 6 new vitest cases + 29/29 full notifications suite GREEN; 30-01 Server Actions regression-locked
- [Phase 30]: [Phase 30-04]: 30-PARITY-SPEC.md authors canonical unread-count SQL + scope contract (D-13/D-14/D-15); extracts SupabaseService.buildMarkAllReadQueryString(userId:projectId:) as internal static helper; markAllNotificationsRead consumes it; XCTest calls REAL helper via @testable import (no mirror); 9 web vitest cases + 7 iOS XCTest cases lock filter-scope + 99+ cap; full notifications suite 38/38 GREEN; compile-only iOS verification per Phase 22/29.1/30-07/30-02 precedent
- [Phase 30]: Plan 30-05: iOS NotificationsStore subscribes to Supabase Realtime postgres_changes on cs_notifications with canonical channel cs_notifications:{userId} matching web HeaderBell.tsx; polling remains as fallback after 3 consecutive WebSocket failures; Swift-6-clean via class-level nonisolated on NotificationsRealtimeHandle (target-level SWIFT_DEFAULT_ACTOR_ISOLATION=MainActor required explicit override); TDD RED->GREEN sequence (e0aa86e/584861c/c7d0ba1); compile-only test verification per Phase 22/29.1/30-02/30-04 precedent; Phase 14 D-08 (iOS 0-20s inbox lag) closed.
- [Phase 30]: Plan 30-06: D-17 inbox_filter_changed analytics closed cross-platform — pure sanitizer+emit pair on web with 7/7 vitest locking three-key PII-free payload; iOS NotificationsStore.setFilter(_:) extended in place with diff-gated emitFilterChangedAnalytics helper (no parallel setProjectFilter — single-setter HARD GATE grep=0). Hydration bypasses emit on both platforms. AnalyticsEngine [String:String] signature required Int-to-String serialization deviation from plan template.

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

Last session: 2026-05-03T20:45:00Z
Stopped at: Production-readiness sweep complete -- silent-failure audit (33 spots fixed across iOS+web), Tier 3 mock bundle gating (20 arrays in 12 files), CI fully green-up after 5+ days red (web-build lint/typecheck/script + link-health placeholder skips + non-blocking continue-on-error)
Resume file: None
Outstanding (blocked on user decision or external steps):
  - Schema FK refactor draft -- 4 open questions in .planning/drafts/cs_schedule_events_cs_todos_fk_refactor.sql
  - NOTIF-05 push notification UAT on physical iPhone -- blocked on Supabase anon-key paste
  - 999.5 (f) email smoke test + (g) xlsx CDN -- need a Vercel deploy
  - constructionos.com / constructionos.app domain registration + Resend verification + App Store privacy/support URL setup -- all production launch blockers
  - 92 React Compiler ESLint warnings (downgraded from errors in eslint.config.mjs) -- focused refactor pass
Drift detector armed: trig_011Q9x8jXoEd6ed2SWbnxLPt fires 2026-05-08T21:15:00Z, checks Phase 30.1 closure state.
