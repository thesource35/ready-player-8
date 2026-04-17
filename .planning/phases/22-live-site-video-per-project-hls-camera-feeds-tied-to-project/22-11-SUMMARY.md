---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 11
subsystem: analytics, testing
tags: [analytics, d-40, vitest, xctest, mux, hls, wave-4]

requires:
  - phase: 22-03
    provides: Mux webhook route, signPlaybackJWT, rate-limit wrapper, create-live-input route
  - phase: 22-04
    provides: VOD upload-url route, transcode worker, signHlsManifest
  - phase: 22-09
    provides: Portal playback-token + playback-url routes
  - phase: 22-00
    provides: Wave 0 test stubs (9 vitest + 4 XCTest) that this plan un-skips

provides:
  - web/src/lib/video/analytics.ts with emitVideoEvent helper + 8 D-40 event type definitions
  - ready player 8/Video/VideoAnalytics.swift with sanitized AnalyticsEngine wrapper for iOS
  - D-40 analytics events wired at all 8 call sites (upload, transcode, live, playback, portal)
  - All Wave 0 test stubs un-skipped with real assertions (39 passing web tests, 7 iOS XCTest methods)
  - 22-VERIFICATION.md documenting 7 manual UAT categories for phase gate

affects: []

tech-stack:
  added: []
  patterns:
    - "D-40 structured log pattern: emitVideoEvent logs JSON with [analytics] prefix for pipeline ingestion from Vercel/Fly.io logs"
    - "iOS VideoAnalytics enum wraps AnalyticsEngine.shared.track with sanitization (removes stream_key, signed_url)"
    - "Worker uses inline console.log('[analytics]', JSON.stringify({...})) since it runs outside web runtime"

key-files:
  created:
    - web/src/lib/video/analytics.ts
    - ready player 8/Video/VideoAnalytics.swift
    - .planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/22-VERIFICATION.md
  modified:
    - web/src/app/api/video/mux/webhook/route.ts
    - web/src/app/api/video/vod/upload-url/route.ts
    - worker/src/transcode.ts
    - web/src/app/api/portal/video/playback-token/route.ts
    - web/src/app/api/portal/video/playback-url/route.ts
    - ready player 8/Video/LiveStreamView.swift
    - ready player 8/Video/VideoClipPlayer.swift
    - web/src/__tests__/video/mux-jwt.test.ts
    - web/src/__tests__/video/mux-webhook.test.ts
    - web/src/__tests__/video/vod-playback.test.ts
    - web/src/__tests__/video/portal-video-auth.test.ts
    - web/src/__tests__/video/ratelimit.test.ts
    - web/src/__tests__/video/upload-validation.test.ts
    - web/src/__tests__/video/retention.test.ts
    - web/src/__tests__/video/mux-live-input.test.ts
    - web/src/__tests__/video/cameras-section.test.tsx
    - ready player 8Tests/VideoTests/VideoModelTests.swift
    - ready player 8Tests/VideoTests/VideoAuthTests.swift

key-decisions:
  - "VideoUploadClient.swift already emitted video_upload_started/failed via AnalyticsEngine.shared.track directly (from 22-05); left as-is rather than migrating to VideoAnalytics wrapper since the event names match D-40 exactly"
  - "Worker transcode analytics use inline console.log('[analytics]', ...) rather than importing emitVideoEvent because the worker runs on Fly.io outside the web runtime"
  - "Portal playback-token route now selects org_id from cs_video_sources to populate portal_video_view event payload correctly"
  - "portal_video_view for live cameras uses open live asset id when available, falls back to stable 'live:{source_id}' placeholder"

requirements-completed:
  - VIDEO-01-P

duration: 6min
completed: 2026-04-17
---

# Phase 22 Plan 11: D-40 Analytics Events + Wave 0 Test Un-skip Summary

**All 8 D-40 video analytics events wired at correct call sites across web API, worker, and iOS client; all Wave 0 test stubs un-skipped with 39 passing web tests and 7 iOS XCTest methods; VERIFICATION.md written for manual UAT gate.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-17T08:18:30Z
- **Completed:** 2026-04-17T08:24:30Z
- **Tasks:** 2 automated + 1 checkpoint (pending)
- **Files created:** 3
- **Files modified:** 18

## Accomplishments

- **Web analytics helper** (`web/src/lib/video/analytics.ts`): exports `emitVideoEvent` with discriminated union type covering all 8 D-40 events. Defense-in-depth sanitization deletes `stream_key` and `signed_url` from any payload before logging.

- **iOS analytics helper** (`ready player 8/Video/VideoAnalytics.swift`): enum with static methods `uploadStarted`, `uploadFailed`, `playbackStarted` plus a generic `track` wrapper that sanitizes before forwarding to `AnalyticsEngine.shared.track`. All properties are `[String: String]` to match the existing AnalyticsEngine signature.

- **Analytics wired at all 8 D-40 call sites:**
  1. `video_upload_started` -- upload-url route after asset insert
  2. `video_upload_failed` -- iOS VideoUploadClient (pre-existing from 22-05)
  3. `video_transcode_succeeded` -- worker transcode.ts after status=ready
  4. `video_transcode_failed` -- worker transcode.ts catch block
  5. `live_stream_started` -- webhook route on video.live_stream.active
  6. `live_stream_disconnected` -- webhook route on video.live_stream.idle (with session_elapsed_s)
  7. `video_playback_started` -- iOS LiveStreamView on first token fetch + VideoClipPlayer on manifest URL set
  8. `portal_video_view` -- both portal playback-token and playback-url routes

- **All Wave 0 test stubs un-skipped:** 39 web tests pass across 9 files; 7 iOS XCTest methods across 2 files. Zero `it.skip` remaining in `web/src/__tests__/video/`. Zero `XCTSkip` in VideoModelTests and VideoAuthTests.

- **VERIFICATION.md** documents 7 manual UAT categories: Mux live ingest, 24h DVR, VOD upload-to-play, portal exposure, retention prune, analytics events, and rate limiting.

## Task Commits

1. **Task 1: Analytics wiring** -- `436d9b3` (feat)
2. **Task 2: Un-skip tests + VERIFICATION.md** -- `121eca4` (test)
3. **Task 3: Phase-gate checkpoint** -- pending human verification

## Decisions Made

1. **Left VideoUploadClient.swift analytics as-is.** The file already emitted `video_upload_started` and `video_upload_failed` via `AnalyticsEngine.shared.track` (added in plan 22-05). Event names match D-40 exactly. Migrating to the new `VideoAnalytics` wrapper would change behavior for no benefit.

2. **Worker uses inline structured log.** The worker runs on Fly.io outside the Next.js runtime, so it cannot import `emitVideoEvent`. Using `console.log('[analytics]', JSON.stringify({...}))` with the same event schema achieves pipeline compatibility.

3. **Added org_id to portal playback-token source select.** The original query selected only `id, project_id, kind, mux_playback_id`. The `portal_video_view` event payload requires `org_id`, so the select was expanded. No behavioral change to existing logic.

4. **Portal live camera asset_id uses fallback.** When emitting `portal_video_view` for live cameras, the route queries for an open live asset row. If none exists (edge case: stream just started, no asset row yet), it uses `live:{source_id}` as a stable placeholder per the plan's guidance.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Portal video auth mock missing .is() chain method**
- **Found during:** Task 2 test run
- **Issue:** The portal-video-auth test mock's Supabase chain lacked `.is()`, `.order()`, `.limit()` methods needed by the new analytics query in the playback-token route
- **Fix:** Added all missing chainable methods to `makeMockChain()`
- **Files modified:** web/src/__tests__/video/portal-video-auth.test.ts
- **Commit:** 121eca4

**2. [Rule 2 - Critical] Un-skipped mux-live-input.test.ts and cameras-section.test.tsx**
- **Found during:** Task 2 grep for remaining it.skip
- **Issue:** Two files not listed in the plan's Task 2 file list still had `it.skip` stubs. The acceptance criteria requires zero `it.skip` across all `web/src/__tests__/video/*`.
- **Fix:** Replaced stubs with real assertions covering route response shape and UI state constants
- **Files modified:** web/src/__tests__/video/mux-live-input.test.ts, web/src/__tests__/video/cameras-section.test.tsx
- **Commit:** 121eca4

## Known Stubs

None. All test stubs have been replaced with real assertions.

## Threat Flags

None. No new trust boundaries introduced. Analytics payloads are sanitized (stream_key/signed_url removed) and contain only identifiers, never credentials.

---

## Self-Check: PASSED

All 3 created files and 2 task commits verified on disk and in git log.
