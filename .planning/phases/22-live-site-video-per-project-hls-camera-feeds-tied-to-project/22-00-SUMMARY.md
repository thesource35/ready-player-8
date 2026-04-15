---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 00
subsystem: testing
tags: [vitest, xctest, mux, ffmpeg, hls, scaffolding, wave-0]

requires:
  - phase: v2.1 tooling
    provides: vitest 4.1.4 installed in web/, XCTest target in "ready player 8Tests/", Node 20 runtime

provides:
  - 9 vitest stub files under web/src/__tests__/video/ covering every /api/video/* route that downstream plans 22-03/04/05/08/09/10 will implement
  - 4 iOS XCTest stub files under ready player 8Tests/VideoTests/ matching VideoSource/VideoAsset model, LiveStreamView, VideoClipPlayer, and VideoAuth test targets
  - Worker subdirectory skeleton (worker/) with package.json, tsconfig, vitest config, Dockerfile, and smoke test — ready for Wave 2 plan 22-04 to fill in
  - 4 realistic Mux webhook JSON fixtures (active, disconnected, idle, asset-ready) matching envelope verified in 22-RESEARCH.md
  - tiny.mp4 placeholder (0-byte; Wave 2 will regenerate via ffmpeg lavfi testsrc)

affects:
  - 22-02 Wave 1 (iOS VideoSource/VideoAsset model — VIDEO-01-A)
  - 22-03 Wave 2 (Mux live input + JWT + webhook + rate limits — VIDEO-01-E)
  - 22-04 Wave 2 (ffmpeg transcode worker — VIDEO-01-H)
  - 22-05 Wave 2 (SupabaseService video auth client — VIDEO-01-I)
  - 22-06 Wave 3 (iOS LiveStreamView + VideoClipPlayer — VIDEO-01-J)
  - 22-08 Wave 3 (Cameras section UI + upload validation — VIDEO-01-L)
  - 22-09 Wave 3 (Portal video auth guards — VIDEO-01-M)
  - 22-10 Wave 4 (Retention prune — VIDEO-01-N)

tech-stack:
  added:
    - vitest (already present in web; extending coverage)
    - hono (listed as worker dependency; not yet installed)
    - @supabase/supabase-js (worker dependency)
  patterns:
    - Every Wave 0 test file carries `// Owner: 22-NN-PLAN.md Wave K` comment linking it to the downstream plan that will implement the real test, preventing orphaned stubs
    - Every stub uses it.skip (vitest) or throw XCTSkip (iOS) — green CI today, explicit TODO tomorrow
    - Worker lives in worker/ sibling to web/ (NOT in web/ monorepo) per 22-RESEARCH.md Fly.io deployment target
    - Mux webhook fixtures use the exact envelope verified in research (type, object, id, created_at, data)

key-files:
  created:
    - web/src/__tests__/video/mux-live-input.test.ts
    - web/src/__tests__/video/mux-jwt.test.ts
    - web/src/__tests__/video/mux-webhook.test.ts
    - web/src/__tests__/video/vod-playback.test.ts
    - web/src/__tests__/video/retention.test.ts
    - web/src/__tests__/video/portal-video-auth.test.ts
    - web/src/__tests__/video/cameras-section.test.tsx
    - web/src/__tests__/video/upload-validation.test.ts
    - web/src/__tests__/video/ratelimit.test.ts
    - web/src/__tests__/video/fixtures/mock-mux-webhook-active.json
    - web/src/__tests__/video/fixtures/mock-mux-webhook-disconnected.json
    - web/src/__tests__/video/fixtures/mock-mux-webhook-idle.json
    - web/src/__tests__/video/fixtures/mock-mux-webhook-asset-ready.json
    - web/src/__tests__/video/fixtures/tiny.mp4
    - ready player 8Tests/VideoTests/VideoModelTests.swift
    - ready player 8Tests/VideoTests/LiveStreamViewTests.swift
    - ready player 8Tests/VideoTests/VideoClipPlayerTests.swift
    - ready player 8Tests/VideoTests/VideoAuthTests.swift
    - worker/package.json
    - worker/tsconfig.json
    - worker/vitest.config.ts
    - worker/Dockerfile
    - worker/.dockerignore
    - worker/.gitignore
    - worker/__tests__/transcode.smoke.test.ts
    - worker/README.md
    - .planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/deferred-items.md
  modified: []

key-decisions:
  - "tiny.mp4 committed as 0-byte placeholder (ffmpeg unavailable locally); Wave 2 worker plan 22-04 regenerates via `ffmpeg -f lavfi -i testsrc=...`"
  - "iPhone 17 simulator used for xcodebuild target (iPhone 15 not installed on this machine); structural verification substituted for end-to-end run because of pre-existing unrelated compile errors in ready_player_8Tests.swift + ReportTests.swift"
  - "worker/ lives as sibling to web/ (not nested) per 22-RESEARCH.md Fly.io architecture; standalone package.json, NOT part of web's npm workspace"
  - "Deferred fix of pre-existing async/concurrency errors in ready_player_8Tests.swift and ReportTests.swift — logged to deferred-items.md for Phase 28 retroactive sweep or a dedicated quick task"

patterns-established:
  - "Owner comment pattern: `// Owner: 22-NN-PLAN.md Wave K — <req-id>` on every stub file; lets downstream executors grep for their owned files"
  - "Stub body pattern: single it.skip / throw XCTSkip with explicit TODO text citing plan and requirement ID"
  - "Fixture pattern: Mux webhook JSON under `web/src/__tests__/video/fixtures/` named `mock-mux-webhook-<event>.json`, matching official envelope fields (type, object, id, created_at, data)"

requirements-completed:
  - VIDEO-00

duration: 7min
completed: 2026-04-15
---

# Phase 22 Plan 00: Wave 0 Test Scaffolding Summary

**Test layout locked for Phase 22 — 9 vitest stubs, 4 XCTest stubs, 4 Mux webhook fixtures, and a worker skeleton; every Wave 1-4 `<automated>` command now resolves to a real file before those plans run.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-15T06:39:53Z
- **Completed:** 2026-04-15T06:46:27Z
- **Tasks:** 3
- **Files created:** 27

## Accomplishments

- 9 web vitest stub files committed, all run green as skipped (`vitest --run src/__tests__/video/` → 9 skipped / 0 failed in 747ms)
- 4 iOS XCTest stub files committed under a new `VideoTests/` subdirectory; PBXFileSystemSynchronizedRootGroup will auto-include on next build
- Standalone `worker/` subdirectory created with package.json (`constructionos-video-worker`), tsconfig (NodeNext), vitest config, Dockerfile (node:20-bookworm-slim + ffmpeg), and a smoke-test stub
- 4 Mux webhook JSON fixtures committed matching the envelope verified in 22-RESEARCH.md (type, object, id, created_at, data)
- Every stub file carries an explicit `// Owner: 22-NN-PLAN.md Wave K` comment citing the downstream plan and requirement ID — prevents orphaned stubs
- VIDEO-00 (Wave 0 scaffolding) requirement satisfied

## Task Commits

Each task was committed atomically:

1. **Task 1: Create web test file scaffolding + Mux webhook fixtures** — `d234b30` (test)
2. **Task 2: Create iOS XCTest scaffolding under ready player 8Tests/VideoTests/** — `950966f` (test)
3. **Task 3: Create worker/ subdirectory skeleton** — `40a535a` (chore)

**Plan metadata commit:** pending (this SUMMARY + STATE + ROADMAP will be committed together next).

## Files Created/Modified

### Web test stubs (9)
- `web/src/__tests__/video/mux-live-input.test.ts` — owner 22-03 (POST /api/video/mux/create-live-input schema)
- `web/src/__tests__/video/mux-jwt.test.ts` — owner 22-03 (signPlaybackJWT claims + RS256)
- `web/src/__tests__/video/mux-webhook.test.ts` — owner 22-03 (Mux-Signature HMAC + dedupe)
- `web/src/__tests__/video/vod-playback.test.ts` — owner 22-04 (manifest batch-sign + Content-Type)
- `web/src/__tests__/video/retention.test.ts` — owner 22-10 (retention_expires_at prune + Mux delete)
- `web/src/__tests__/video/portal-video-auth.test.ts` — owner 22-09 (drone/portal_visible/show_cameras guards)
- `web/src/__tests__/video/cameras-section.test.tsx` — owner 22-08 (empty/live/clip/soft-cap UI states)
- `web/src/__tests__/video/upload-validation.test.ts` — owner 22-08 (size/duration/format guards)
- `web/src/__tests__/video/ratelimit.test.ts` — owner 22-03 (30 req/min/IP + Retry-After)

### Fixtures (5)
- `web/src/__tests__/video/fixtures/mock-mux-webhook-active.json` — `type: video.live_stream.active`
- `web/src/__tests__/video/fixtures/mock-mux-webhook-disconnected.json` — `type: video.live_stream.disconnected`
- `web/src/__tests__/video/fixtures/mock-mux-webhook-idle.json` — `type: video.live_stream.idle`
- `web/src/__tests__/video/fixtures/mock-mux-webhook-asset-ready.json` — `type: video.asset.ready`
- `web/src/__tests__/video/fixtures/tiny.mp4` — 0-byte placeholder (regenerated in Wave 2 by plan 22-04)

### iOS XCTest stubs (4)
- `ready player 8Tests/VideoTests/VideoModelTests.swift` — owner 22-02 Wave 1 (VIDEO-01-A)
- `ready player 8Tests/VideoTests/LiveStreamViewTests.swift` — owner 22-06 Wave 3 (VIDEO-01-J)
- `ready player 8Tests/VideoTests/VideoClipPlayerTests.swift` — owner 22-06 Wave 3 (VIDEO-01-J)
- `ready player 8Tests/VideoTests/VideoAuthTests.swift` — owner 22-05 Wave 2 (VIDEO-01-I)

### Worker skeleton (8)
- `worker/package.json` — `constructionos-video-worker` (hono, supabase-js, vitest, tsx)
- `worker/tsconfig.json` — NodeNext ES2022 strict, outDir dist, rootDir src
- `worker/vitest.config.ts` — node env, `__tests__/**/*.test.ts`
- `worker/Dockerfile` — node:20-bookworm-slim + ffmpeg, port 8080, CMD `node dist/server.js`
- `worker/.dockerignore` — excludes node_modules/dist/__tests__/.env
- `worker/.gitignore` — excludes node_modules/dist/.env
- `worker/__tests__/transcode.smoke.test.ts` — owner 22-04 Wave 2 smoke stub
- `worker/README.md` — worker role, flow (POST /transcode → ffmpeg → HLS → update row), Fly.io target

### Planning artifacts (1)
- `.planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/deferred-items.md` — records pre-existing async/concurrency errors in ready_player_8Tests.swift and ReportTests.swift for Phase 28 retroactive sweep

## Decisions Made

- **tiny.mp4 as 0-byte placeholder** — ffmpeg is not installed on this workstation. The plan explicitly allows this fallback (line 151: "If ffmpeg is unavailable locally, commit a placeholder 0-byte file named tiny.mp4 and flag in task Done — Wave 1 worker plan will regenerate"). Wave 2 plan 22-04 will regenerate via `ffmpeg -f lavfi -i testsrc=duration=5:size=320x240:rate=30 ... tiny.mp4`.
- **iPhone 17 simulator for xcodebuild destination** — iPhone 15 simulator (named in the plan's verify command) is not installed. iPhone 17 is the closest available and covers the iOS 18.2+ deployment target.
- **Task 2 verified structurally, not via xcodebuild test** — pre-existing async/concurrency compile errors in sibling files (ready_player_8Tests.swift, ReportTests.swift) prevent the whole test target from building. These are unrelated to Phase 22 and out of scope per GSD scope boundary rules. Logged to deferred-items.md. All four new VideoTests/*.swift files satisfy the structural acceptance criteria (exist, contain `throw XCTSkip(`, `// Owner: 22-`, `@testable import ready_player_8`).
- **No npm install in worker/** — plan explicitly defers install to Wave 2 executor (line 312) so they can pin exact working versions.

## Deviations from Plan

### Deviation 1: Simulator destination

- **Rule:** Rule 3 (blocking) — simulator name in verify command did not resolve on the host
- **Found during:** Task 2 verify
- **Issue:** `xcodebuild -destination 'platform=iOS Simulator,name=iPhone 15'` — iPhone 15 simulator not installed
- **Fix:** Used iPhone 17 (available and supports iOS 18.2+ deployment target); verification logic unchanged
- **Files modified:** none (command-line flag only)
- **Committed in:** n/a (verification-only change)

### Deviation 2: Structural verification for Task 2

- **Rule:** Rule 3 (blocking) surfaced pre-existing failures out of scope
- **Found during:** Task 2 verify (`xcodebuild test -only-testing:"ready player 8Tests/VideoTests"`)
- **Issue:** Build fails before test run because `ready_player_8Tests.swift` (45+ errors) and `ReportTests.swift` have pre-existing `'async' call in a function that does not support concurrency` errors. These files predate Phase 22 and are owned by earlier phases (13–17). Same build failure reproduces with `build-for-testing` alone, confirming the issue is not introduced by Wave 0 files.
- **Fix:** Per GSD scope boundary ("only auto-fix issues DIRECTLY caused by the current task's changes"), did NOT fix. Logged to `deferred-items.md` for Phase 28 retroactive sweep or a dedicated quick task. Substituted structural verification (file existence + required literals) for end-to-end xcodebuild test run. All four new VideoTests files pass structural acceptance criteria.
- **Files modified:** `.planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/deferred-items.md` (added)
- **Committed in:** `950966f`

---

**Total deviations:** 2 (1 blocking environmental, 1 scope-boundary deferral)
**Impact on plan:** Wave 0 scope fully delivered. No scope creep. Downstream iOS plans (22-02, 22-05, 22-06) should either incidentally fix the ready_player_8Tests.swift file as part of their first iOS commit or rely on compile-only verification until a dedicated fix lands.

## Known Stubs

All files created in this plan are intentional stubs — that is the plan's deliverable. Each is tracked by its `// Owner: 22-NN-PLAN.md Wave K` comment:

| File | Owner plan | Wave |
|------|-----------|------|
| web/src/__tests__/video/mux-live-input.test.ts | 22-03 | 2 |
| web/src/__tests__/video/mux-jwt.test.ts | 22-03 | 2 |
| web/src/__tests__/video/mux-webhook.test.ts | 22-03 | 2 |
| web/src/__tests__/video/vod-playback.test.ts | 22-04 | 2 |
| web/src/__tests__/video/retention.test.ts | 22-10 | 4 |
| web/src/__tests__/video/portal-video-auth.test.ts | 22-09 | 3 |
| web/src/__tests__/video/cameras-section.test.tsx | 22-08 | 3 |
| web/src/__tests__/video/upload-validation.test.ts | 22-08 | 3 |
| web/src/__tests__/video/ratelimit.test.ts | 22-03 | 2 |
| ready player 8Tests/VideoTests/VideoModelTests.swift | 22-02 | 1 |
| ready player 8Tests/VideoTests/LiveStreamViewTests.swift | 22-06 | 3 |
| ready player 8Tests/VideoTests/VideoClipPlayerTests.swift | 22-06 | 3 |
| ready player 8Tests/VideoTests/VideoAuthTests.swift | 22-05 | 2 |
| worker/__tests__/transcode.smoke.test.ts | 22-04 | 2 |
| web/src/__tests__/video/fixtures/tiny.mp4 | 22-04 | 2 (regenerated via ffmpeg) |

These stubs are intentional scaffolding per the plan's objective ("prevent MISSING verify commands in Waves 1-4") — not production stubs that would affect user-facing behavior.

## Issues Encountered

- **ffmpeg not installed locally** — handled via plan-specified fallback (0-byte tiny.mp4, Wave 2 regenerates).
- **iPhone 15 simulator not installed** — substituted iPhone 17 (deviation 1).
- **Pre-existing iOS test compile errors** — out of scope (deviation 2, logged to deferred-items.md).

## User Setup Required

None — this plan only creates skipped test stubs and a Dockerfile. No environment variables, no external services, no user action needed before downstream waves run.

## Next Phase Readiness

- Waves 1–4 of Phase 22 can now cite concrete `<automated>` commands against files already committed on `main`.
- Wave 2 plan 22-04 should be the first to `cd worker/ && npm install`; exact dep versions are pinned but not locked yet (no package-lock.json).
- Wave 2 plan 22-04 will also regenerate `tiny.mp4` via `ffmpeg -f lavfi -i testsrc=...` to replace the 0-byte placeholder.
- Before any iOS XCTest task in 22-02/05/06 runs its full `xcodebuild test` verify, either (a) a quick task fixes the pre-existing async errors in `ready_player_8Tests.swift` + `ReportTests.swift`, or (b) each iOS plan's first task includes that fix incidentally, or (c) iOS plans accept compile-only verification until Phase 28.

---

*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Completed: 2026-04-15*

## Self-Check: PASSED

All 28 files claimed above exist on disk. All 3 task commits (`d234b30`, `950966f`, `40a535a`) exist in git log.
