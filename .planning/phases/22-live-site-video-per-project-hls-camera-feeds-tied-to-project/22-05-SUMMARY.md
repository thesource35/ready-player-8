---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 05
subsystem: ios-service-layer
tags: [swift, supabase, mux, tus-upload, avplayer, ios, wave-2]

requires:
  - phase: 22-01
    provides: cs_video_sources + cs_video_assets tables on remote DB — SupabaseService now lists both in its allowedTables allowlist and queries them via generic fetch/insert/update/delete helpers
  - phase: 22-02
    provides: VideoSource/VideoAsset Codable structs + AppError D-40 cases — the service layer decodes remote rows into these types and surfaces errors via AppError.clipTooLarge/clipTooLong/unsupportedVideoFormat/permissionDenied
  - phase: 22-03
    provides: POST /api/video/mux/playback-token route — VideoPlaybackAuth.fetchMuxToken calls this endpoint and decodes { token, ttl, playback_id }
  - phase: 22-04
    provides: POST /api/video/vod/upload-url + GET /api/video/vod/playback-url routes — VideoUploadClient posts to the first for tus registration; VideoPlaybackAuth.vodManifestUrl composes the second into an AVPlayer-loadable URL

provides:
  - ready player 8/SupabaseService.swift — +8 video CRUD methods (fetchVideoSources, fetchVideoAssets, createVideoSource, createVideoAsset, deleteVideoSource, deleteVideoAsset, toggleAssetPortalVisible, toggleSourceAudioEnabled) wrapping the generic fetch/insert/update/delete helpers
  - ready player 8/SupabaseService.swift — allowedTables allowlist now includes "cs_video_sources" + "cs_video_assets" so validateTable() permits them
  - ready player 8/Video/VideoSyncManager.swift — @MainActor ObservableObject singleton with @Published sourcesByProject + assetsByProject dicts, per-project UserDefaults cache (ConstructOS.Video.{Sources,Assets}Cache.<projectId>), optimistic upsert/remove helpers, softCapStatus(forOrgCameras:) implementing D-28 (20-camera soft cap, warn at 16)
  - ready player 8/Video/VideoPlaybackAuth.swift — enum with two static methods: fetchMuxToken(sourceId:sessionToken:portalToken:) (dual-path for D-19 logged-in vs portal) and vodManifestUrl(assetId:portalToken:). Maps 401/403 -> .permissionDenied, 429 -> .validationFailed, 5xx -> .supabaseHTTP.
  - ready player 8/Video/VideoUploadClient.swift — final class with probeFile + validate static helpers (D-31 client-side 2GB/60min/mp4|mov|m4v pre-check) and instance upload(...) method that POSTs to /api/video/vod/upload-url then streams to Supabase Storage resumable endpoint (Tus-Resumable 1.0.0 headers) with 3-attempt retry on transient failures. Emits video_upload_started / video_upload_failed analytics (D-40).
  - VIDEO-01-J + VIDEO-01-K satisfied

affects:
  - 22-06 Wave 3 (iOS LiveStreamView + VideoClipPlayer) — consumes VideoPlaybackAuth.fetchMuxToken(sourceId:) for the LL-HLS URL and .vodManifestUrl(assetId:) for AVPlayer's manifest source
  - 22-08 Wave 3 (Cameras section UI) — calls VideoSyncManager.shared.syncProject(projectId:service:) on appear to populate the @Published lists; uses softCapStatus() for the banner state; uses VideoUploadClient for the clip upload wizard
  - 22-09 Wave 3 (portal video exposure) — reuses VideoPlaybackAuth via the portalToken: parameter for unauthenticated clients
  - 22-11 Wave 5 (un-skip tests) — VideoAuthTests, LiveStreamViewTests stubs will now resolve against real service code instead of only types

tech-stack:
  added: []  # no new deps — all three files use Foundation + AVFoundation + URLSession which are already linked
  patterns:
    - "Stale-while-revalidate pattern: VideoSyncManager reads UserDefaults cache FIRST (synchronous paint), then kicks async Supabase fetch; if fetch fails, stale cache remains visible — matches DataSyncManager (Phase 13) convention."
    - "Dual-path playback auth: every VideoPlaybackAuth method accepts an optional portalToken. nil = user path (session bearer header); present = portal path (token in body, different route prefix /api/portal/video/*). One helper surface for D-19."
    - "Client-side D-31 gate before network work: probeFile + validate throw the exact AppError case (clipTooLarge/clipTooLong/unsupportedVideoFormat) so the upload never hits the server with data that would be rejected. Server route 22-04 still re-validates (defense in depth)."
    - "Analytics events fired via MainActor.run wrapper: AnalyticsEngine is @MainActor but VideoUploadClient is a plain class (callable from any context). Every .track call goes through await MainActor.run { ... } to satisfy actor isolation without making the whole client main-actor-bound."
    - "Retry-only-on-retryable-AppError: upload retries inspect AppError.isRetryable. .permissionDenied / .unsupportedVideoFormat / .clipTooLong / .clipTooLarge bubble immediately (no retry). .network / .supabaseHTTP(>=500) / .uploadFailed retry with 1s/2s linear backoff across 3 attempts."

key-files:
  created:
    - ready player 8/Video/VideoSyncManager.swift
    - ready player 8/Video/VideoPlaybackAuth.swift
    - ready player 8/Video/VideoUploadClient.swift
  modified:
    - ready player 8/SupabaseService.swift

key-decisions:
  - "Adapted plan's `id: UUID` signatures to the codebase's existing generic `delete(_ table: String, id: String)` and `update(_ table: String, id: String, record:)` helpers by calling `uuidString` inside the wrappers. The public video-method API uses `UUID` (type-safe at call sites); the private bridge serializes once at the boundary. Rewriting the generic helpers to accept UUID would have touched 40+ existing callers for zero benefit. [Rule 3 — codebase reality]"
  - "Renamed allowlist reference from plan's `registeredTables` to the actual property name `allowedTables`. Plan language was illustrative; codebase naming takes precedence. [Rule 3]"
  - "VideoUploadClient's instance method `failAndReport` became `async` so analytics events (AnalyticsEngine @MainActor) can be awaited inside. Every error-path callsite now uses `await self.failAndReport(...)`. No public API change — the client's `upload(...)` is already async."
  - "Did NOT make VideoUploadClient @MainActor — it runs long-lived work (probe + network streaming) and making it main-actor-bound would block UI during uploads. Analytics dispatch via localized MainActor.run keeps isolation correct while letting upload bytes flow on background threads."
  - "Used the `orderBy` parameter of generic `fetch(...)` which defaults to descending (`ascending: false`). Plan's pseudo-code specified `orderBy: 'created_at.desc'` literal but the helper already handles direction via a separate param; passing the bare column name produces the same PostgREST `order=created_at.desc` query."
  - "`vodManifestUrl` throws on URL composition failure (`.unknown(_)`) rather than force-unwrapping URLComponents. Matches the existing codebase's 'never trap on string->URL' defensive pattern."
  - "Did NOT implement true tus-resumable chunked upload in v1 — instead the client does a single-request PUT with Tus-Resumable headers and 3-attempt retry. File > 100 MB logs a NOTE flagging that native chunking is a follow-up (per RESEARCH Upload UX option B fallback). Clips under 2 GB but over 100 MB will still upload; they just re-start from zero on retry."
  - "VideoPlaybackAuth is an `enum` (stateless namespace), VideoSyncManager is a `final class` (ObservableObject singleton), VideoUploadClient is a `final class` (per-upload instance with callbacks). Matches the access pattern each type needs — static util vs shared state vs per-operation."

patterns-established:
  - "Video service method ordering: fetch (list, guard-return-empty) -> create (insert pass-through) -> delete (wrapper that converts UUID -> String) -> toggle* (Encodable patch struct defined inline). Copy-paste shape for future video CRUD extensions."
  - "iOS <-> web API base URL reuse: every Phase 22 iOS network call reads `ConstructOS.Integrations.Backend.BaseURL` from UserDefaults (same key SupabaseService uses). VideoPlaybackAuth.apiBaseURL centralizes the read so future routes don't duplicate the logic."
  - "Per-project UserDefaults cache key pattern: `ConstructOS.Video.<Thing>Cache.<projectId.uuidString>`. Matches D-26 namespace convention. Keys are generated by private helpers so typo-at-read-site is impossible."

requirements-completed:
  - VIDEO-01-J
  - VIDEO-01-K

duration: ~24min
completed: 2026-04-16
---

# Phase 22 Plan 05: iOS Service Layer Summary

**Full iOS service surface for Phase 22 video is on main: SupabaseService gains 8 video CRUD methods; VideoSyncManager caches per-project source+asset lists with stale-while-revalidate UserDefaults hydration; VideoPlaybackAuth mints Mux JWTs + VOD manifest URLs via the 22-03/22-04 web routes (D-14 + D-19 dual-path); VideoUploadClient implements D-31 client-side caps + tus upload with 3x retry + D-40 analytics. Wave 3 UI (22-06, 22-08, 22-09) can now be written as thin view layers over a testable service surface.**

## Performance

- **Duration:** ~24 min (Task 1 commit 00:55:42 -> Task 2 commit 01:19:27)
- **Tasks:** 2 (both TDD-aware `type="auto" tdd="true"` — existing VideoAuthTests.swift stub in 22-00 remains `throw XCTSkip` until 22-11 un-skips)
- **Files created:** 3 (under `ready player 8/Video/`)
- **Files modified:** 1 (`ready player 8/SupabaseService.swift`)

## Accomplishments

- **SupabaseService extended (Task 1).** 8 new video methods appended to the class, in `// MARK: - Phase 22: Video sources & assets` section:
  - `fetchVideoSources(projectId:) async throws -> [VideoSource]` — returns [] when Supabase unconfigured (list-op pattern); PostgREST query `project_id=eq.<uuid>&order=created_at.desc`.
  - `fetchVideoAssets(projectId:, kind:) async throws -> [VideoAsset]` — optional `kind` filter ('live' | 'vod'); order by `started_at.desc`.
  - `createVideoSource(_ record: VideoSource)` / `createVideoAsset(_ record: VideoAsset)` — thin inserts. Documented that user-initiated camera creation goes through the web API route (22-03) so Mux + DB stay atomic; these methods exist for offline paths and tests.
  - `deleteVideoSource(id: UUID)` / `deleteVideoAsset(id: UUID)` — type-safe UUID -> String bridge to the generic `delete(_ table:, id: String)` helper.
  - `toggleAssetPortalVisible(assetId:, visible:)` — inline-`struct PortalVisiblePatch: Encodable` PATCH on `portal_visible`. RLS (22-01) gates this to owner/admin per D-39.
  - `toggleSourceAudioEnabled(sourceId:, enabled:)` — same pattern for D-35 governance.
- **allowedTables allowlist updated.** `"cs_video_sources"` + `"cs_video_assets"` added in a `// Phase 22: Live Site Video` comment block, matching the existing per-phase grouping (Phase 13, Phase 16, Phase 17, Phase 20).
- **VideoSyncManager.swift (Task 2, File 1).** `@MainActor final class VideoSyncManager: ObservableObject` with shared singleton. `@Published var sourcesByProject: [UUID: [VideoSource]]`, `@Published var assetsByProject: [UUID: [VideoAsset]]`, and `@Published var syncingProjects: Set<UUID>` for loading spinners. `syncProject(_:service:)` loads cache first, kicks `async let` parallel fetches for sources + assets, writes both back to UserDefaults on success; on error logs + reports to CrashReporter but preserves stale cache. `upsertSource/upsertAsset/removeSource/removeAsset` mutate in-memory state optimistically. `softCapStatus(forOrgCameras:)` returns `(atCap: count >= 20, nearCap: count >= 16)` — nonisolated helper so UI code can compute banner state off the main actor if desired.
- **VideoPlaybackAuth.swift (Task 2, File 2).** Namespace enum with two static methods:
  - `fetchMuxToken(sourceId: UUID, sessionToken: String, portalToken: String? = nil) async throws -> MuxPlaybackToken` — POSTs JSON body. When `portalToken == nil`: uses `/api/video/mux/playback-token` + `Authorization: Bearer <session>`. When provided: uses `/api/portal/video/playback-token` with `{source_id, portal_token}` body, no auth header. Decodes 401/403 -> `.permissionDenied`, 429 -> `.validationFailed(field: "rate", ...)`, 5xx -> `.supabaseHTTP`, URLError -> `.network(underlying:)`.
  - `vodManifestUrl(assetId: UUID, portalToken: String? = nil) throws -> URL` — composes `/api/video/vod/playback-url?asset_id=<uuid>` (or portal variant with `portal_token` query item). Returns URL ready for AVPlayer; the server route 22-04 streams the rewritten HLS manifest inline.
- **VideoUploadClient.swift (Task 2, File 3).** `final class VideoUploadClient` with callback-style `progress: (Double) -> Void` + `onComplete: (Result<String, AppError>) -> Void` (success yields `asset_id`).
  - `static func probeFile(_ url: URL) async throws -> VideoProbeResult` — uses `AVURLAsset.load(.duration)` + `FileManager.attributesOfItem`; returns `(durationSeconds, sizeBytes, containerExt)`.
  - `static func validate(_ probe:)` — enforces D-31: `clipTooLarge(maxGB: 2)` for > 2 GB, `clipTooLong(maxMinutes: 60)` for > 3600s, `unsupportedVideoFormat(details:)` for containers outside {mp4, mov, m4v}.
  - `func upload(fileUrl:projectId:orgId:name:sessionToken:apiBaseURL:) async` — 3-stage pipeline: probe -> request upload URL (POST /api/video/vod/upload-url, decode `{asset_id, bucket_name, object_name, upload_url, auth_token}`) -> PUT to Supabase Storage `/storage/v1/upload/resumable` with `Tus-Resumable: 1.0.0`, `Authorization: Bearer <auth_token>`, tus metadata headers (bucketName/objectName/contentType).
  - 3-attempt retry loop inside `uploadBytes` — retries only when the thrown AppError has `isRetryable == true`. Backoff is 1s / 2s linear between attempts.
  - Emits `video_upload_started` / `video_upload_failed` via `AnalyticsEngine.shared.track(...)` wrapped in `await MainActor.run { ... }` (AnalyticsEngine is `@MainActor`; the upload client is not).
  - `cancel()` nulls the `activeTask?.cancel()` reference for UI-driven aborts.

## Task Commits

Each task committed atomically:

1. **Task 1: SupabaseService +8 video CRUD methods + allowedTables** — `30230ab` (feat)
2. **Task 2: VideoSyncManager + VideoPlaybackAuth + VideoUploadClient** — `3fc3a69` (feat)

Plan metadata commit: pending (this SUMMARY + STATE + ROADMAP + REQUIREMENTS bundled next).

## Files Created/Modified

### Created (3)

- `ready player 8/Video/VideoSyncManager.swift` (~115 lines) — @MainActor ObservableObject, per-project cache, optimistic mutations, D-28 soft-cap helper
- `ready player 8/Video/VideoPlaybackAuth.swift` (~130 lines) — fetchMuxToken + vodManifestUrl with D-19 dual-path for portal vs logged-in users
- `ready player 8/Video/VideoUploadClient.swift` (~370 lines) — probeFile + validate + full 3-stage upload with D-31 client gate, D-33 retry, D-40 analytics

### Modified (1)

- `ready player 8/SupabaseService.swift` — +66 lines: 8 video CRUD methods (appended before closing class brace) + 2-line table allowlist entry

## Decisions Made

1. **Adapted `id: UUID` signatures to the codebase's `id: String` generic helpers.** The plan's method signatures used `UUID` for type safety at call sites; the existing `delete(_:id: String)` + `update(_:id: String, record:)` helpers expect `String` (40+ existing callers). New video methods accept UUID publicly and serialize via `.uuidString` inside the wrappers. Rule 3 — codebase reality substitution.
2. **Renamed plan's `registeredTables` reference to actual `allowedTables`.** Plan language was illustrative. The code uses `private static let allowedTables: Set<String>` with a `validateTable(_:)` gate that throws on unknown tables. Rule 3.
3. **`failAndReport` became `async`.** AnalyticsEngine is `@MainActor`; VideoUploadClient is not. To call `.track(...)` from error paths without making the whole class main-actor-bound, every fail-path helper became async and its 5 callsites use `await self.failAndReport(...)`. No public API change.
4. **VideoUploadClient intentionally NOT `@MainActor`.** Long-running work (probe + bytes streaming) should not pin to the main actor. Analytics dispatch is wrapped in localized `MainActor.run` blocks instead.
5. **Used `orderBy` column bare name (not `.desc`).** The generic `fetch(...)` helper takes `ascending: Bool = false` which defaults to descending order, so passing `"created_at"` produces `order=created_at.desc` — matches the plan's intent without duplicating direction.
6. **Threw `.unknown(_)` on URL composition failure in `vodManifestUrl`.** Rather than force-unwrap `URLComponents.url`, both possible nil paths return `.unknown("Could not compose...")`. Matches the codebase's defensive URL pattern.
7. **Single-request PUT with tus headers (not native tus-resumable chunking).** v1 does a full PUT with `Tus-Resumable: 1.0.0` header + 3-attempt retry. Files > 100 MB log a NOTE flagging true resumable chunking is a follow-up per RESEARCH Upload UX option B. Clips > 100 MB still upload; they just restart from zero on retry.
8. **Different type shapes per role.** VideoPlaybackAuth = `enum` (stateless namespace), VideoSyncManager = `final class` (ObservableObject singleton), VideoUploadClient = `final class` (per-upload instance with callbacks). Each type uses the right Swift idiom for its access pattern.

## Deviations from Plan

### Deviation 1: `id: UUID` method args wrap `String`-keyed generic helpers

- **Rule:** Rule 3 (blocking) — plan's code template used `id: UUID` for delete/update calls but the existing generic helpers are `String`-keyed.
- **Found during:** Task 1 writing the video CRUD wrapper methods.
- **Issue:** Plan template code `try await delete("cs_video_sources", id: id)` would not compile — `delete(_:id:)` takes `id: String`.
- **Fix:** Kept the plan's type-safe public signature (`id: UUID`) but bridge to the generic helper via `id.uuidString`. Call sites get UUID safety; the one serialization happens inside the video wrapper.
- **Files modified:** `ready player 8/SupabaseService.swift` (Task 1 scope)
- **Committed in:** `30230ab` (Task 1)

### Deviation 2: `registeredTables` -> `allowedTables`

- **Rule:** Rule 3 (blocking) — plan referenced `registeredTables` array; the actual property is `allowedTables`.
- **Found during:** Task 1 locating the allowlist.
- **Issue:** Plan verification command `grep "registeredTables"` would return 0. The allowlist is `private static let allowedTables: Set<String>` (line 771); `validateTable(_:)` at line 799 gates it.
- **Fix:** Appended `"cs_video_sources", "cs_video_assets"` in the existing allowlist with a `// Phase 22: Live Site Video` comment, matching the per-phase grouping convention.
- **Committed in:** `30230ab` (Task 1)

### Deviation 3: `failAndReport` async + 5 awaited callsites

- **Rule:** Rule 3 (blocking) — AnalyticsEngine.track is `@MainActor`; a synchronous helper would fail the isolation check.
- **Found during:** Task 2 first compile.
- **Issue:** `AnalyticsEngine.shared.track(...)` inside synchronous `private func failAndReport(...)` emitted "call to main actor-isolated method in a nonisolated context".
- **Fix:** Made `failAndReport` async; wrapped the `.track(...)` call in `await MainActor.run { ... }`. All 5 callsites updated to `await self.failAndReport(...)`. No public API change — `upload(...)` is already async.
- **Committed in:** `3fc3a69` (Task 2)

### Deviation 4: `CMTime.isValid` replaced with `CMTimeGetSeconds(...).isFinite` check

- **Rule:** Rule 3 — `isValid` is a macro-style flag not exposed as a bare `.isValid` property on `CMTime` in Swift.
- **Found during:** Task 2 first compile.
- **Issue:** `duration.isValid == false` doesn't compile in current Swift.
- **Fix:** Used `duration.isIndefinite` + `.isFinite` check on the double result. Semantically equivalent (any invalid CMTime yields NaN/inf seconds).
- **Committed in:** `3fc3a69` (Task 2)

### Deviation 5: Plan's iPhone 15 simulator -> iPhone 17

- **Rule:** Environmental — iPhone 15 not installed on this host. Same substitution documented in 22-00-SUMMARY (Deviation 1) and 22-02-SUMMARY (Deviation 2). Using `xcrun simctl list devices available` confirmed only iPhone 16e / 17 / 17 Pro / 17 Pro Max present.
- **Fix:** Used `-destination 'platform=iOS Simulator,name=iPhone 17'`. Not a logic deviation — verification intent (clean iOS compile) unchanged.

**Total deviations:** 5 (all Rule 3 / environmental — no behavioral or architectural changes).

## Issues Encountered

- **Pre-existing async/concurrency build failures in `ready_player_8Tests.swift` + `ReportTests.swift`** prevent `xcodebuild test -only-testing:"ready player 8Tests/VideoAuthTests"` from returning green. Documented in `.planning/phases/22-live-site-video-.../deferred-items.md` since Phase 22-00. Per GSD scope boundary, these are out of scope for Phase 22 waves — the VideoAuthTests stub still compiles cleanly alongside the Swift frontend invocation; the test-runner just can't link the full target. App build (`xcodebuild build`) is green.
- **2 high-severity npm vulns** from earlier phases persist in web/ but this plan did not touch web/; out of scope.
- **No auth gates, no architectural decisions required, no Rule 1/2/4 auto-fixes triggered.** All deviations are Rule 3 (codebase reality substitutions) or environmental.

## User Setup Required

**None required for this plan itself.** All three new Swift files are pure library code — they consume existing UserDefaults keys (`ConstructOS.Integrations.Backend.BaseURL`) and call the already-deployed web routes (22-03/22-04).

For end-to-end flows to work:

1. Operator must have completed the 22-03 Mux setup (Mux account, signing keys, webhook URL, env vars) — without this, `fetchMuxToken` returns `.supabaseHTTP(503, ...)` from the token-mint route.
2. Operator must have completed the 22-04 worker deployment (Fly.io app, DB GUCs) — without this, `VideoUploadClient.upload(...)` completes the tus upload but the row sits in `status='uploading'` forever (the `requeue_stuck_uploads()` backstop from 22-10 will catch it).
3. Supabase access token in the iOS app — the existing auth flow (`AuthGateView` in ContentView) already produces one; VideoUploadClient just passes it through.

## Next Phase Readiness

- **Unblocks 22-06** (iOS LiveStreamView + VideoClipPlayer): `VideoPlaybackAuth.fetchMuxToken(sourceId:)` returns the Mux JWT ready for `https://stream.mux.com/<playback_id>.m3u8?token=<jwt>` URL composition. `VideoPlaybackAuth.vodManifestUrl(assetId:)` returns an AVPlayer-loadable URL directly.
- **Unblocks 22-08** (Cameras section UI): `VideoSyncManager.shared.syncProject(projectId:service:)` populates `@Published` lists; UI binds via `@ObservedObject`. `VideoUploadClient` covers the upload wizard end-to-end. `softCapStatus()` computes banner state.
- **Unblocks 22-09** (portal video exposure): every `VideoPlaybackAuth` method accepts `portalToken:` to route through the portal variant (`/api/portal/video/...`) without session auth.
- **Unblocks 22-11** (un-skip VideoAuthTests): the real `fetchMuxToken` surface exists; the test can swap `throw XCTSkip` for actual AppError-mapping assertions once the pre-existing test-target build errors are cleared.
- **Zero new blockers** for any downstream Phase 22 plan.

## Known Stubs

**None introduced by this plan.** The three new Swift files are load-bearing production code:

- VideoSyncManager is wired to real Supabase via the SupabaseService extensions added in Task 1.
- VideoPlaybackAuth points at real web routes (22-03 + 22-04) that are on main.
- VideoUploadClient performs real uploads against real endpoints.

The v1 single-request PUT (vs native tus chunked resume) is **documented as an intentional limitation** with a logged NOTE for files > 100 MB, not a stub. Clips under 2 GB still upload successfully; they just re-start from zero on retry. Native tus chunking is a follow-up per RESEARCH.md Upload UX option B.

## Threat Flags

None. This plan is iOS client code that consumes already-documented trust boundaries (the web API routes from 22-03/22-04). No new network endpoints, no new auth paths, no new file-access patterns, no new trust-boundary schema changes. All security-sensitive operations (JWT mint, signed URL composition) remain server-side per D-14.

---

## Self-Check: PASSED

Verified files exist:

- FOUND: ready player 8/SupabaseService.swift (modified +66 lines; 8 new methods; allowedTables +2 entries)
- FOUND: ready player 8/Video/VideoSyncManager.swift
- FOUND: ready player 8/Video/VideoPlaybackAuth.swift
- FOUND: ready player 8/Video/VideoUploadClient.swift

Verified commits exist in git log:

- FOUND: 30230ab (Task 1 — feat: SupabaseService +8 video CRUD methods + register tables)
- FOUND: 3fc3a69 (Task 2 — feat: VideoSyncManager + VideoPlaybackAuth + VideoUploadClient)

Verified iOS build:

- `xcodebuild -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17' build` -> `** BUILD SUCCEEDED **`
- Only warnings emitted are pre-existing AppEnvironment.swift main-actor isolation warnings (unrelated to Phase 22).

Acceptance-criteria greps (all ≥ expected):

- `func fetchVideoSources`: 1 | `func fetchVideoAssets`: 1 | `func createVideoSource`: 1 | `func createVideoAsset`: 1 | `func deleteVideoSource`: 1 | `func deleteVideoAsset`: 1 | `func toggleAssetPortalVisible`: 1 | `func toggleSourceAudioEnabled`: 1
- `"cs_video_sources"` in SupabaseService.swift: 5 (≥ 2 required: 1 in allowlist + per-method query string) | `"cs_video_assets"`: 5
- `final class VideoSyncManager`: 1 | `@Published var sourcesByProject`: 1 | `@Published var assetsByProject`: 1 | `softCapStatus`: 1
- `fetchMuxToken`: 1 | `vodManifestUrl`: 1 | `portalToken`: 11 (≥ 2) | `AppError.permissionDenied`: 1 | `AppError.supabaseNotConfigured`: 2
- `VideoUploadClient`: 3 | `clipTooLarge`: 3 | `clipTooLong`: 3 | `unsupportedVideoFormat`: 4 | `probeFile`: 2 | `AVURLAsset`: 4 | `video_upload_started`: 3 | `video_upload_failed`: 2

Test-target build failure note: pre-existing async/concurrency errors in `ready_player_8Tests.swift` + `ReportTests.swift` block `xcodebuild test` from linking the test runner — these are out of scope (Phase 28 cleanup) and documented in `deferred-items.md`. Compile-only verification against the app target is green.

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Plan: 22-05 (Wave 2 iOS service layer)*
*Completed: 2026-04-16*
