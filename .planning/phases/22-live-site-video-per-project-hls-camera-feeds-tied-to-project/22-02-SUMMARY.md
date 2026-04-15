---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 02
subsystem: shared-vocabulary
tags: [swift, typescript, apperror, codable, coding-keys, enums, appstorage, wave-1]

requires:
  - phase: 22-01
    provides: cs_video_sources + cs_video_assets row shape — Swift CodingKeys and TS types mirror these 13/19 columns exactly so models decode without drift
  - phase: 22-00
    provides: Wave 0 test scaffolding — VideoModelTests.swift stub already on main; real tests land in downstream iOS plans (22-05, 22-06)

provides:
  - 9 new AppError cases per D-40 (unsupportedVideoFormat, clipTooLong, clipTooLarge, audioConsentRequired, transcodeTimeout, muxIngestFailed, muxDeleteFailed, cameraLimitReached, webhookSignatureInvalid) with user-facing copy verbatim from 22-UI-SPEC.md "Error states" table, plus severity/isRetryable classifications
  - Top-level `enum ConstructOS {}` namespace container in ThemeAndModels.swift (previously referenced via string AppStorage keys but never declared as a Swift type) — unblocks type-checked AppStorage key helpers
  - New file "ready player 8/Video/VideoModels.swift" declaring 5 enums (VideoKind, VideoSourceType, VideoAssetKind, VideoSourceStatus, VideoAssetStatus) and 2 Codable structs (VideoSource, VideoAsset) with CodingKeys mapping camelCase Swift to snake_case DB columns
  - `ConstructOS.Video` nested enum exposing `defaultQualityKey`, `muxEnvironmentKey`, and `lastPlayedAssetIdKey(projectId:)` for D-26 type-checked AppStorage access
  - web/src/lib/video/types.ts with matching TS unions + row-shape types (snake_case) + D-28/D-31/D-14/D-37 numeric constants (CAMERA_SOFT_CAP, MAX_UPLOAD_SIZE_BYTES, MUX_PLAYBACK_JWT_TTL_SECONDS, PLAYBACK_TOKEN_RATE_LIMIT_PER_MIN)
  - web/src/lib/video/errors.ts exporting `VideoErrorCode` const object (12 entries: 9 D-40 + 3 common error codes), `VideoErrorCodeValue` derived type, `VideoErrorBody` response shape, and `videoError()` builder helper
  - web/src/lib/supabase/types.ts re-exports all 9 new Phase 22 types so any `@/lib/supabase/types` consumer picks them up without path changes
  - VIDEO-01-M (error taxonomy) satisfied; VIDEO-01-A already satisfied by 22-01 (schema) — this plan adds the matching Swift/TS model surface

affects:
  - 22-03 Wave 2 (Mux server routes — throws `.muxIngestFailed` / `.muxDeleteFailed`; returns VideoErrorCode in NextResponse bodies; webhook route throws `.webhookSignatureInvalid` on HMAC mismatch)
  - 22-04 Wave 2 (VOD tus/upload + worker — throws `.clipTooLarge` / `.clipTooLong` / `.unsupportedVideoFormat` via VideoErrorCode; worker polls until `VideoAssetStatus.ready` or `.transcodeTimeout`)
  - 22-05 Wave 2 (iOS SupabaseService video auth client — decodes VideoSource/VideoAsset via CodingKeys; reads/writes `ConstructOS.Video.*` AppStorage keys)
  - 22-06 Wave 3 (iOS LiveStreamView + VideoClipPlayer — consumes VideoSource/VideoAsset + VideoAssetStatus state machine for player UI)
  - 22-08 Wave 3 (Cameras section UI — renders VideoSource list, toggles portal_visible per VideoAsset; hits `.cameraLimitReached` at CAMERA_SOFT_CAP)
  - 22-09 Wave 3 (Portal exposure — filters VideoSourceType != 'drone', checks portal_visible, uses VideoErrorCode.PermissionDenied)
  - 22-10 Wave 4 (Retention prune — reads retention_expires_at from VideoAsset)

tech-stack:
  added: []  # types-only plan — no new runtime deps
  patterns:
    - "Namespace-scoped constants: `ConstructOS.{Feature}.{Property}` — now supported via top-level `enum ConstructOS {}` + extensions (e.g., `extension ConstructOS { enum Video { ... } }`). Future features can add `extension ConstructOS { enum Field { ... } }` without touching ThemeAndModels.swift."
    - "Wire format = snake_case (DB-shaped); app shape remapping via Swift CodingKeys is the one and only translation boundary. TS types are intentionally snake_case to match raw Supabase row shape — consumers that prefer camelCase remap explicitly."
    - "Error taxonomy symmetry: every Swift AppError.{case} has a matching VideoErrorCode string value. API routes return `{ error, code, retryable }`; iOS decodes `code` back to AppError via a switch at the networking layer (pattern consumed by 22-03/04/05)."
    - "Shared constants live in types.ts (TS) — Swift versions will land in the plan that first needs them (22-08 for CAMERA_SOFT_CAP, 22-04 for MAX_UPLOAD_SIZE_BYTES) rather than pre-declaring dead constants here."

key-files:
  created:
    - ready player 8/Video/VideoModels.swift
    - web/src/lib/video/types.ts
    - web/src/lib/video/errors.ts
  modified:
    - ready player 8/AppError.swift
    - ready player 8/ThemeAndModels.swift
    - web/src/lib/supabase/types.ts

key-decisions:
  - "Left `case unsupportedFileType(String)` intact in AppError rather than collapsing it into the new `.unsupportedVideoFormat(details:)` — pre-existing callers for non-video uploads (profile photos, document attachments) already depend on it. The new video case adds codec-aware copy without breaking the generic one."
  - "Added `enum ConstructOS {}` in ThemeAndModels.swift (top-level) rather than in VideoModels.swift — putting the root namespace in the canonical models file lets future non-video features (ConstructOS.Field, ConstructOS.Notifications) extend it without implicit dependencies on Video."
  - "TS types use snake_case field names (matching DB columns) rather than the camelCase Swift shape — consumers that do app-shape remapping (hooks, components) own the translation. Keeps wire decoding trivial and matches existing Phase 14/15 convention in supabase/types.ts (e.g., `created_at`, `user_id`)."
  - "VideoErrorCode adds 3 non-D-40 codes (PermissionDenied, RateLimited, PlaybackTokenMintFailed) used by every /api/video/* route but not part of the 9 specific video-failure cases — these map to existing AppError cases (permissionDenied, network-derived retries, uploadFailed respectively) or are surfaced as generic HTTP 401/429/500 with the extra code as a diagnostic breadcrumb."
  - "Deferred camelCase-vs-snake_case constants (CAMERA_SOFT_CAP, MAX_UPLOAD_SIZE_BYTES) to TS only for now. Swift side will import these as needed in 22-04/22-08; no point declaring dead constants in VideoModels.swift before the consuming plan lands."

patterns-established:
  - "AppError extension ritual: insert new cases BEFORE `.unknown(String)` (the catch-all sentinel) to preserve switch-case source ordering; always extend `errorDescription`, `severity`, AND `isRetryable` in the same commit."
  - "ConstructOS namespace extension pattern: `extension ConstructOS { enum Video { ... } }` — every feature gets its own nested enum so grepping `ConstructOS.Video` shows 100 percent of video keys in one listing."
  - "Every Phase 22 /api/video/* route MUST return `{ error: string, code: VideoErrorCodeValue, retryable: boolean }` — consumed by iOS via `videoError()` helper as the single JSON shape."

requirements-completed:
  - VIDEO-01-M

duration: 9min
completed: 2026-04-15
---

# Phase 22 Plan 02: Shared Vocabulary Summary

**Cross-platform video contract locked: 9 AppError cases + VideoSource/VideoAsset structs on iOS, matching TS unions + row-shape types + VideoErrorCode taxonomy on web. Every downstream Wave 2-4 plan now `import`s compile-time-checked types — zero drift risk between Swift and TypeScript.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-04-15T20:30:00Z (approx)
- **Completed:** 2026-04-15T20:45:00Z (approx)
- **Tasks:** 2
- **Files created:** 3
- **Files modified:** 3

## Accomplishments

- **9 new AppError cases** added to `ready player 8/AppError.swift` matching D-40 exactly: `unsupportedVideoFormat(details:)`, `clipTooLong(maxMinutes:)`, `clipTooLarge(maxGB:)`, `audioConsentRequired`, `transcodeTimeout`, `muxIngestFailed(reason:)`, `muxDeleteFailed(reason:)`, `cameraLimitReached(cap:)`, `webhookSignatureInvalid`. `errorDescription` copy taken verbatim from 22-UI-SPEC.md "Error states" table. `isRetryable` classifies ingest/delete/transcode as retryable (true); format/size/duration/consent/limit/signature as non-retryable (false). `severity` classifies mux/transcode/signature as `.error`, format/size/consent/limit as `.warning`.
- **iOS model layer** in new `ready player 8/Video/VideoModels.swift` (auto-included via PBXFileSystemSynchronizedRootGroup): 5 enums + 2 Codable structs. VideoKind and VideoSourceType both declare `fixedCamera/drone/upload` with identical rawValues (`fixed_camera`, `drone`, `upload`) — Phase 29 relies on this discriminator symmetry per D-08. VideoSource has 13 stored properties matching cs_video_sources; VideoAsset has 19 matching cs_video_assets including `portal_visible` (D-21) and `name` (D-38). CodingKeys map camelCase Swift to snake_case DB columns.
- **ConstructOS namespace bootstrapped.** Previously referenced only as a string prefix for AppStorage keys (`ConstructOS.Wealth.*`, `ConstructOS.AngelicAI.*`), now exists as a top-level `enum ConstructOS {}` in ThemeAndModels.swift. `extension ConstructOS { enum Video { ... } }` in VideoModels.swift adds `defaultQualityKey`, `muxEnvironmentKey`, and the parameterized `lastPlayedAssetIdKey(projectId:)` helper — all compile-time-checked string constants per D-26.
- **TS types mirror Swift exactly** in `web/src/lib/video/types.ts`: `VideoKind`, `VideoSourceType`, `VideoAssetKind`, `VideoSourceStatus`, `VideoAssetStatus`, `VideoDefaultQuality` string unions + `VideoSource` / `VideoAsset` / `VideoWebhookEvent` row-shape types. Eight numeric/literal constants: `CAMERA_SOFT_CAP=20`, `CAMERA_WARNING_THRESHOLD=16`, `MAX_UPLOAD_SIZE_BYTES=2GB`, `MAX_UPLOAD_DURATION_SECONDS=3600`, `ALLOWED_UPLOAD_CONTAINERS`, `ALLOWED_UPLOAD_MIME_TYPES`, `MUX_PLAYBACK_JWT_TTL_SECONDS=300`, `VOD_SIGNED_URL_TTL_SECONDS=3600`, `PLAYBACK_TOKEN_RATE_LIMIT_PER_MIN=30`.
- **Error taxonomy** in `web/src/lib/video/errors.ts`: `VideoErrorCode` const object with all 9 D-40 codes (`video.unsupported_format`, `video.clip_too_long`, etc.) plus 3 common codes (`PermissionDenied`, `RateLimited`, `PlaybackTokenMintFailed`); `VideoErrorCodeValue` union type; `VideoErrorBody` response shape `{ error, code, retryable }`; `videoError()` helper for building NextResponse bodies.
- **Supabase types re-exports.** Appended 9 Phase 22 type re-exports to `web/src/lib/supabase/types.ts` so every downstream consumer that imports from `@/lib/supabase/types` resolves video types transparently.
- **iOS build is clean** (`xcodebuild -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17' build` → `** BUILD SUCCEEDED **`).
- **Web typecheck is clean** (`cd web && npx tsc --noEmit` → exit 0).

## Task Commits

Each task committed atomically:

1. **Task 1: 9 AppError video cases + iOS model types + ConstructOS namespace** — `5bf4561` (feat)
2. **Task 2: TS VideoSource/VideoAsset types + VideoErrorCode taxonomy + re-exports** — `65ba99f` (feat)

**Plan metadata commit:** pending (this SUMMARY + STATE + ROADMAP + REQUIREMENTS).

## Files Created/Modified

### Created
- `ready player 8/Video/VideoModels.swift` (~117 lines) — VideoKind, VideoSourceType, VideoAssetKind, VideoSourceStatus, VideoAssetStatus enums; VideoSource (13 props) + VideoAsset (19 props) Codable/Identifiable/Hashable structs with snake_case CodingKeys; `extension ConstructOS { enum Video { ... } }` with 3 AppStorage key helpers
- `web/src/lib/video/types.ts` (~80 lines) — 6 string-union types, 3 row-shape types (VideoSource, VideoAsset, VideoWebhookEvent), 8 literal/numeric constants (D-28/D-31/D-14/D-37)
- `web/src/lib/video/errors.ts` (~32 lines) — VideoErrorCode const (12 entries), VideoErrorCodeValue derived union, VideoErrorBody response shape, videoError() builder

### Modified
- `ready player 8/AppError.swift` — 9 new cases inserted before `.unknown(String)`; 9 new `errorDescription` branches with 22-UI-SPEC verbatim copy; `isRetryable` and `severity` extended with explicit video-case classifications
- `ready player 8/ThemeAndModels.swift` — top-level `enum ConstructOS {}` namespace container added (6 lines + doc comment)
- `web/src/lib/supabase/types.ts` — 11-line re-export block appended at EOF so `@/lib/supabase/types` consumers resolve video types

## Decisions Made

1. **Preserve `AppError.unsupportedFileType(String)` alongside new `.unsupportedVideoFormat(details:)`.** Pre-existing non-video callers (profile photos, document attachments) depend on the generic case. The video-specific case adds codec-aware copy without breaking callers.
2. **`enum ConstructOS {}` lives in ThemeAndModels.swift (root), not VideoModels.swift.** Future features extend `ConstructOS` without implicit dependencies on Video — `extension ConstructOS { enum Field { ... } }` in FieldModels.swift (Phase 28), etc.
3. **TS row-shape types use snake_case.** Matches existing Phase 14/15 convention in supabase/types.ts (`created_at`, `user_id`). Consumers that prefer camelCase app-shape remap at hook/component boundary. Wire decoding stays trivial.
4. **VideoErrorCode exports 3 non-D-40 codes.** `PermissionDenied`, `RateLimited`, `PlaybackTokenMintFailed` are not part of the 9 specific video-failure cases but are common to every /api/video/* route — they map to existing AppError cases (permissionDenied / network / uploadFailed) or generic HTTP statuses. Keeping them in the same taxonomy simplifies route handler code.
5. **Deferred Swift-side constants (CAMERA_SOFT_CAP, MAX_UPLOAD_SIZE_BYTES, etc.) to consumers.** No point declaring dead constants in VideoModels.swift before 22-04/22-08 need them. Swift will redeclare or import as needed.

## Deviations from Plan

**None.** Plan executed exactly as written. Both tasks' acceptance criteria passed on first write. Swift compiled clean on iPhone 17 simulator (iPhone 15 absent from this host, same substitution documented in 22-00-SUMMARY Deviation 1). Web typecheck exited 0 with no regressions.

Note on the plan's `<verify>` command for Task 1: it prescribed `-destination 'platform=iOS Simulator,name=iPhone 15'` but iPhone 15 is not installed on this machine. Substituted iPhone 17 per precedent set in 22-00. This is an environmental substitution, not a logic deviation — verification intent (clean iOS compile) is unchanged.

## Issues Encountered

- **`npm run typecheck` script does not exist** in web/package.json — substituted `npx tsc --noEmit` (the plan's own fallback directive). Exit code 0, no diagnostics emitted.
- No other issues. No authentication gates, no architectural decisions required, no Rule 1-4 auto-fixes triggered.

## User Setup Required

None — this plan only adds type declarations and error taxonomy constants. No new runtime dependencies, no environment variables, no external services, no operator actions before downstream waves run.

## Next Phase Readiness

- **Unblocks 22-03** (Mux server integration): route handlers can `import { VideoErrorCode, videoError } from '@/lib/video/errors'` and throw `AppError.muxIngestFailed(reason:)` on the iOS side of the request; webhook verifier returns `videoError(VideoErrorCode.WebhookSignatureInvalid, ...)` on HMAC mismatch.
- **Unblocks 22-04** (VOD pipeline): upload route imports `MAX_UPLOAD_SIZE_BYTES`, `MAX_UPLOAD_DURATION_SECONDS`, `ALLOWED_UPLOAD_MIME_TYPES` for D-31 server-side guards; worker polls `VideoAssetStatus.ready` or `.failed` state machine; returns `VideoErrorCode.TranscodeTimeout` after 10 min.
- **Unblocks 22-05** (iOS service layer): SupabaseService can declare `fetchVideoSources(projectId:) async throws -> [VideoSource]` returning the exact Codable type; AppStorage access uses `ConstructOS.Video.defaultQualityKey` etc. instead of raw strings.
- **Unblocks 22-06** (iOS player views): LiveStreamView dispatches on `VideoSourceStatus`; VideoClipPlayer dispatches on `VideoAssetStatus`; both decode `VideoAsset.muxPlaybackId` for player URL construction.
- **Unblocks 22-08** (Cameras section): UI imports `CAMERA_SOFT_CAP` + `CAMERA_WARNING_THRESHOLD` for the soft-cap warning banner; form validates against `ALLOWED_UPLOAD_CONTAINERS` for client-side D-31 pre-check.
- **Unblocks 22-09** (portal exposure): portal route filters `source_type !== 'drone'` (D-08 exclusion) using `VideoSourceType` union exhaustiveness; returns `VideoErrorCode.PermissionDenied` when `show_cameras=false`.
- **Unblocks 22-10** (retention): prune job reads `retention_expires_at` from `VideoAsset` rows.
- **Zero blockers** for any downstream Phase 22 plan.

## Known Stubs

None in this plan's deliverables. All declarations are load-bearing contracts that downstream plans will consume. The `ConstructOS.Video.lastPlayedAssetIdKey(projectId:)` helper is a helper function, not a stub.

## Threat Flags

None. This plan adds type declarations and constants only. No new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes were introduced.

---

## Self-Check: PASSED

Verified files exist:

- FOUND: ready player 8/Video/VideoModels.swift
- FOUND: web/src/lib/video/types.ts
- FOUND: web/src/lib/video/errors.ts
- FOUND: ready player 8/AppError.swift (modified — +60 lines)
- FOUND: ready player 8/ThemeAndModels.swift (modified — +6 lines)
- FOUND: web/src/lib/supabase/types.ts (modified — +12 lines)

Verified commits exist in git log:

- FOUND: 5bf4561 (Task 1 — feat: 9 video AppError cases + iOS VideoSource/VideoAsset models)
- FOUND: 65ba99f (Task 2 — feat: TS VideoSource/VideoAsset types + VideoErrorCode taxonomy)

Verified builds:

- iOS: `xcodebuild -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17' build` → `** BUILD SUCCEEDED **`
- Web: `cd web && npx tsc --noEmit` → EXIT=0

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Plan: 22-02 (Wave 1 shared vocabulary)*
*Completed: 2026-04-15*
