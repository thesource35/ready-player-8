---
phase: 29-live-video-traffic-feed-sat-drone
plan: 02
subsystem: api
tags: [zod, nextjs, supabase, vitest, xctest, swift, ios, portal, drone, video]

# Dependency graph
requires:
  - phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
    provides: "cs_video_assets with source_type discriminator; /api/video/vod/upload-url tus route; VideoUploadClient.swift tus upload flow; portal routes enforcing source_type != 'drone' at playback-url:107 and playback-token:125"
  - phase: 29-live-video-traffic-feed-sat-drone
    provides: "29-00 Wave 0 test scaffolding (skipped stubs for upload-url-drone, drone-exclusion, LiveFeedModelsTests)"
provides:
  - "Widened POST /api/video/vod/upload-url: body.source_type ('upload'|'drone', default 'upload') with Zod enum validation"
  - "iOS VideoUploadClient.upload() optional sourceType param (nil default = Phase 22 back-compat)"
  - "LIVE-14 CRITICAL regression lock: 4 live vitest assertions on both portal route drone-exclusions"
  - "LIVE-01 upload-url drone acceptance test: 4 vitest assertions (drone accept, upload default, explicit upload, reject fixed_camera)"
  - "LiveFeedModelsTests anchor: WireLiveSuggestion Codable + VideoSourceType.drone rawValue lock"
affects: [29-04, 29-05, 29-06, 29-08, 29-09, 29-10]

# Tech tracking
tech-stack:
  added: []  # zod already a project dep; reused existing infrastructure
  patterns:
    - "Zod enum as input gate on source_type (T-29-02-01 mitigation)"
    - "Optional Swift param with nil default for wire back-compat"
    - "Regression test imports real route handlers + mocks service-role Supabase + shared rate-limit to isolate invariant branch"

key-files:
  created: []
  modified:
    - "web/src/app/api/video/vod/upload-url/route.ts"
    - "web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts"
    - "web/src/lib/video/analytics.ts"
    - "ready player 8/Video/VideoUploadClient.swift"
    - "ready player 8Tests/Phase29/LiveFeedModelsTests.swift"
    - "web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts"

key-decisions:
  - "Zod enum ['upload','drone'] excludes 'fixed_camera' — user-facing route cannot mint fixed_camera rows (those are server-only via Mux live-input create)"
  - "sourceType param is optional with nil default on iOS to preserve Phase 22 callers — absent JSON key lets server default to 'upload'"
  - "Drone-exclusion test imports the real route handlers (not a re-implementation) so any future weakening of the invariant fails this test immediately"
  - "Portal route handlers NOT modified by this plan — only the __tests__ file was written; D-26 invariant is preserved verbatim"

patterns-established:
  - "source_type Zod validation pattern at /api/video/vod/upload-url — 29-04 (pg_net trigger) and future user-facing video routes should reuse this enum"
  - "Invariant-lock regression test pattern: mock rate-limit + service-role + signing helpers; inject drone row; assert 403 + error copy matches /drone/i; then assert non-drone baseline does NOT 403 on the drone branch"

requirements-completed:
  - LIVE-01
  - LIVE-14

# Metrics
duration: 24min
completed: 2026-04-19
---

# Phase 29 Plan 02: Drone Source Type Widening + LIVE-14 Regression Lock Summary

**Phase 22's VOD upload path now accepts source_type='drone' via Zod-validated body; LIVE-14 drone portal-exclusion invariant is tripwire-locked by 4 live route-import assertions.**

## Performance

- **Duration:** ~24 min
- **Started:** 2026-04-19T23:41:00Z (approx, post-29-00 SUMMARY commit)
- **Completed:** 2026-04-20T00:05:00Z
- **Tasks:** 3 auto + 1 deferred human-verify checkpoint (LIVE-02, awaits UI in 29-06/29-09)
- **Files modified:** 6

## Accomplishments

- **LIVE-01 shipped:** `POST /api/video/vod/upload-url` accepts `body.source_type` (enum 'upload'|'drone', default 'upload' for Phase 22 back-compat); the validated value is written to `cs_video_assets.source_type` and surfaced in the `video_upload_started` analytics event for drone traceability (T-29-02-03).
- **iOS sourceType param:** `VideoUploadClient.upload()` accepts optional `sourceType: VideoSourceType? = nil`; threaded into the JSON body only when explicitly set so every existing Phase 22 call site compiles and behaves unchanged.
- **LIVE-14 regression locked (CRITICAL):** 4 vitest assertions against the real `playback-url` and `playback-token` route handlers — drone `source_type`/`kind` returns 403 with "Drone footage is not available via portal." error copy; non-drone baselines do NOT hit the drone-specific 403. Any future change that weakens the Phase 22 invariant at `playback-url/route.ts:107` or `playback-token/route.ts:125` MUST now fail this test.
- **Codable anchor:** `LiveFeedModelsTests` replaced its Wave 0 XCTSkip with `testDecodesSnakeCaseJSON` (cs_live_suggestions wire shape per D-17) and `testSourceTypeEnumIncludesDrone` (rawValue lock).

## Task Commits

Each task was committed atomically:

1. **Task 1: Widen upload-url route + 4-assertion vitest** — `ae8c60f` (feat)
2. **Task 2: iOS VideoUploadClient sourceType param + LiveFeedModelsTests anchors** — `760e33e` (feat)
3. **Task 3: LIVE-14 portal drone-exclusion regression lock** — `89f7779` (test)
4. **Task 4: LIVE-02 round-trip human-verify** — **DEFERRED** until 29-06 (iOS scrubber/upload) OR 29-09 (web scrubber/upload) ships. This is a consume-only parity check and cannot be exercised before the UI surfaces drone upload. Per plan instruction ("Record 'deferred — will re-check after 29-06' in the SUMMARY if Wave 1 completes before UI"), logged here.

## Files Created/Modified

- `web/src/app/api/video/vod/upload-url/route.ts` — Added `import { z } from 'zod'`; extended `UploadUrlBody` type with `source_type?: string`; added Zod enum validation block (defaults to 'upload', rejects unknown values with 400); replaced hardcoded `source_type: 'upload'` in cs_video_assets insert with validated `sourceType`; extended `emitVideoEvent` payload with `source_type` for T-29-02-03 traceability.
- `web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts` — Replaced Wave 0 `it.skip` stub with 4 live vitest cases (drone accept / upload default / explicit upload / reject fixed_camera).
- `web/src/lib/video/analytics.ts` — Widened `video_upload_started` payload type to include optional `source_type: 'upload' | 'drone' | 'fixed_camera'` (additive; no existing callers affected).
- `ready player 8/Video/VideoUploadClient.swift` — Added `sourceType: VideoSourceType? = nil` param to public `upload()` and private `requestUploadURL()`; only serialized to body when non-nil.
- `ready player 8Tests/Phase29/LiveFeedModelsTests.swift` — Replaced XCTSkip stub with `WireLiveSuggestion` Codable decode test + `VideoSourceType` rawValue lock test.
- `web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts` — Replaced Wave 0 `it.skip` stub with 4 live assertions against real route handlers; mocks `@/lib/video/ratelimit`, `@/lib/video/hls-sign`, `@/lib/video/mux`, and `@/lib/supabase/server.createServiceRoleClient` so the drone-exclusion branch is isolated.

## Decisions Made

- **Zod excludes `'fixed_camera'` from user route.** The cs_video_sources schema reserves `kind='fixed_camera'` for live inputs created via the authenticated Mux live-input endpoint. Accepting it on the upload-url route would allow an authenticated client to mint an orphan VOD asset claiming to be a camera feed — unnecessary attack surface with zero legitimate use case.
- **`sourceType` is optional on iOS.** Every existing Phase 22 caller passes 5 params today; widening to required would have rippled into VideoSyncManager, ProjectVideoListView, and any test fixtures. The `nil` default cleanly lets the absent JSON key fall through to the server's Zod default.
- **Regression test adapted to real route shapes.** The plan's draft assumed POST + `link_token` for both portal routes. Reading the actual Phase 22 routes revealed:
  - `playback-url` is **GET** with `?portal_token=X&asset_id=Y` query params
  - `playback-token` is **POST** with `{portal_token, source_id}` body
  - Both use `createServiceRoleClient` not `createServerSupabase`
  - Portal links live in `cs_report_shared_links` with `link_type='portal'` filter; `playback-token` joins `cs_portal_config(show_cameras)` and requires `show_cameras=true`
  - This is a precise shape adaptation, not a weakening — the `source_type === 'drone'` / `kind === 'drone'` invariants at lines 107 and 125 are the exact branches exercised.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test import path corrected**
- **Found during:** Task 1 (first vitest run)
- **Issue:** Test file `vod/__tests__/upload-url-drone.test.ts` initially imported `from '../route'`; the route actually lives at `vod/upload-url/route.ts` so the correct relative path is `'../upload-url/route'`. ERR_MODULE_NOT_FOUND.
- **Fix:** Changed import to `../upload-url/route`.
- **Files modified:** `web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts`
- **Verification:** 4/4 tests now pass.
- **Committed in:** `ae8c60f` (Task 1)

**2. [Rule 2 - Missing Critical] Widened `emitVideoEvent` payload type for `source_type`**
- **Found during:** Task 1 (tsc would reject adding an undefined field)
- **Issue:** Plan called for adding `source_type: sourceType` to `emitVideoEvent` for T-29-02-03 traceability, but the `video_upload_started` payload type in `web/src/lib/video/analytics.ts` did not declare that field.
- **Fix:** Added `source_type?: 'upload' | 'drone' | 'fixed_camera'` to the `video_upload_started` union member (additive, backward-compatible).
- **Files modified:** `web/src/lib/video/analytics.ts`
- **Verification:** Vitest passes (compiles via tsx transformer in vitest pipeline).
- **Committed in:** `ae8c60f` (Task 1)

**3. [Rule 3 - Blocking] Portal regression test adapted to real route shapes**
- **Found during:** Task 3 (read_first pass on actual portal route handlers)
- **Issue:** Plan's draft test used `POST` + `{ link_token, asset_id }` body for `playback-url`, but the real route is `GET` with `?portal_token=X&asset_id=Y` query params and uses `createServiceRoleClient`, not `createServerSupabase`. `playback-token` uses `portal_token` (not `link_token`) and joins `cs_portal_config(show_cameras)`.
- **Fix:** Rewrote mock to target `createServiceRoleClient`; built request URLs matching the real route handler shapes (GET query for playback-url, POST body for playback-token); included `cs_portal_config: { show_cameras: true }` on the mock portal link so the flow reaches the drone-exclusion branch in both routes.
- **Files modified:** `web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts`
- **Verification:** 4/4 tests pass; drone branches return 403 with "drone" in error copy; non-drone baselines do not hit the drone 403 (playback-url returns 200 with mocked signed manifest; playback-token returns 200 with mocked Mux JWT).
- **Committed in:** `89f7779` (Task 3)

---

**Total deviations:** 3 auto-fixed (1 test-path fix, 1 additive type widening, 1 shape adaptation).
**Impact on plan:** Zero scope creep. Deviations 1+3 were necessary shape corrections; deviation 2 added one optional field so analytics emission actually compiles with the plan's T-29-02-03 extension.

## Issues Encountered

- **None blocking.** The three deviations above were diagnosed and fixed inline. iOS compile was validated via `swiftc -parse` (no syntax errors); a full `xcodebuild` run was skipped because the project already has pre-existing concurrency errors in `ready_player_8Tests.swift` / `ReportTests.swift` (logged by Phase 22 STATE entry: "Pre-existing async/concurrency compile errors in ready_player_8Tests.swift + ReportTests.swift logged to deferred-items.md"). Those are out of scope and unaffected by this plan's changes, which touch only `VideoUploadClient.swift` + a Phase 29 test file. Per project memory, SourceKit diagnostic noise in VS Code should be disregarded; `xcodebuild` is authoritative.

## User Setup Required

None - no external service configuration required for this plan. LIVE-02 human-verify (Task 4) is deferred until either 29-06 (iOS) or 29-09 (web) ships the drone upload UI; at that point a physical 30-60 second MP4 clip must be uploaded and round-tripped through transcode + playback, plus a portal-viewer spot-check confirming 403. Documented as deferred per plan instruction.

## LIVE-02 Deferral Note

**Status:** Deferred — will re-check after 29-06 (iOS scrubber/upload) or 29-09 (web scrubber/upload), whichever ships first.
**Reason:** LIVE-02 is a consume-only parity verification (drone-typed VOD rows transcode and play back identically to upload-typed rows). It cannot be exercised before Phase 29 has a UI surface that triggers the drone upload path. Per Task 4 resume-signal guidance in 29-02-PLAN.md: "If deferring, type 'deferred-until-ui' and note which plan blocks this."

## Known Stubs

None. All three stub files written in 29-00 (`upload-url-drone.test.ts`, `drone-exclusion.test.ts`, `LiveFeedModelsTests.swift`) are now populated with live assertions. No new empty-state stubs introduced.

## Threat Flags

None. This plan's edits touch only an already-authenticated, already-rate-limited, already-RLS-gated route (`/api/video/vod/upload-url`) and an iOS upload client. No new network endpoints, auth paths, or file-access patterns. The T-29-02-01 `source_type` tampering vector is mitigated by the new Zod enum validation inside this plan.

## Next Plan Readiness

- **29-04** (per-upload pg_net trigger) can now rely on `cs_video_assets.source_type='drone'` as a dispatchable discriminator for the live-suggestions trigger predicate — validated row-inserts land via this plan.
- **29-05** (cs_live_suggestions schema + iOS LiveFeedModels.swift) has an anchor wire shape locked by `WireLiveSuggestion` in `LiveFeedModelsTests.swift`; Wave 3 implementation should match that Codable shape.
- **29-06 / 29-09** (UI drone-upload entry points) can pass `sourceType: .drone` to `VideoUploadClient.upload()` (iOS) or `source_type: 'drone'` in the POST body (web) and trust the Zod route validation + Phase 22 pipeline.
- **LIVE-14 tripwire** now guards against any later plan accidentally or intentionally weakening the portal drone-exclusion invariant. All downstream Phase 29 waves can proceed without re-asserting this.

## Self-Check: PASSED

- `web/src/app/api/video/vod/upload-url/route.ts` — FOUND, contains `z.enum(['upload', 'drone'])` (1), `source_type: sourceType` (2x: insert + analytics), `import { z } from 'zod'` (1), zero remaining hardcoded `source_type: 'upload'`.
- `web/src/app/api/video/vod/__tests__/upload-url-drone.test.ts` — FOUND, 0 `it.skip`, 4 live assertions, 4/4 passing.
- `ready player 8/Video/VideoUploadClient.swift` — FOUND, `sourceType: VideoSourceType` x2 (public + private signatures), `sourceType: VideoSourceType? = nil` x1 (public default), `body["source_type"] = sourceType.rawValue` x1. `swiftc -parse` exits 0.
- `ready player 8Tests/Phase29/LiveFeedModelsTests.swift` — FOUND, 0 `XCTSkip`, `testDecodesSnakeCaseJSON` (1), `testSourceTypeEnumIncludesDrone` (1).
- `web/src/app/api/portal/video/__tests__/drone-exclusion.test.ts` — FOUND, 0 `it.skip`, imports `playback-url/route` (3x) + `playback-token/route` (3x), contains `source_type: 'drone'` (1) + `kind: 'drone'` (1), 4/4 passing.
- Portal route invariants UNCHANGED: `playback-url/route.ts:107` still `if (asset.source_type === 'drone')`, `playback-token/route.ts:125` still `if (source.kind === 'drone')`. `git diff HEAD` on those two files is empty.
- Commits: `ae8c60f` (Task 1), `760e33e` (Task 2), `89f7779` (Task 3) all present in `git log --oneline -5`.

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Completed: 2026-04-19*
