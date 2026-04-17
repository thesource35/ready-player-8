---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 07
subsystem: web-player
tags: [react, mux-player-react, hls, ll-hls, vod, portal, css-modules, wave-3]

requires:
  - phase: 22-02
    provides: VideoSource/VideoAsset TS types + VideoErrorCode taxonomy — LiveStreamView reads source.status for badge rendering; VideoClipPlayer switches on asset.status for status-aware placeholders; usePlaybackToken references VideoErrorCode.PlaybackTokenMintFailed as fallback error code
  - phase: 22-03
    provides: POST /api/video/mux/playback-token route returning { token, ttl, playback_id } — consumed by usePlaybackToken hook for signed Mux JWT mint
  - phase: 22-04
    provides: GET /api/video/vod/playback-url route returning signed HLS manifest — consumed by VideoClipPlayer via src prop

provides:
  - web/src/app/projects/[id]/cameras/usePlaybackToken.ts — React hook that POSTs to /api/video/mux/playback-token (or portal path when portalToken supplied), returns { token, playbackId, ttl, loading, error, refresh }, auto-refreshes 30s before TTL expiry
  - web/src/app/projects/[id]/cameras/LiveStreamView.tsx — Client component wrapping @mux/mux-player-react for LL-HLS live streams; accepts VideoSource + optional portalToken; renders loading/error/offline branches per UI-SPEC copy; portal mode: targetLiveWindow=0 head-only (D-34a)
  - web/src/app/projects/[id]/cameras/VideoClipPlayer.tsx — Client component wrapping @mux/mux-player-react for VOD; accepts VideoAsset + optional portalToken; 4-status switch (uploading/transcoding/failed/ready); portal mode hides download (D-34b)
  - web/src/app/projects/[id]/cameras/playerChrome.module.css — 16:9 container, status badge overlay (green LIVE pulse / red OFFLINE / gold IDLE), gold shimmer transcoding animation, portalNoDownload CSS
  - VIDEO-01-F (web player views) satisfied, VIDEO-01-K reinforced

affects:
  - 22-08 Wave 3 (Cameras section UI) — CamerasSection can embed <LiveStreamView source={source} /> and <VideoClipPlayer asset={asset} /> directly. Status badge vocabulary is centralized in playerChrome.module.css.
  - 22-09 Wave 3 (portal exposure) — both players accept portalToken and apply D-34 restrictions automatically; portal pages just pass the token through
  - 22-11 Wave 5 (un-skip tests) — 14 player/hook specs are GREEN and running; the cameras-section.test.tsx stub remains for 22-08 to fill

tech-stack:
  added:
    - "@mux/mux-player-react ^3.11.7 (React wrapper over mux-player web component; internal hls.js for non-Safari)"
  patterns:
    - "Mux Player prop plumbing: streamType='ll-live' for live, 'on-demand' for VOD; tokens.playback for signed JWT; accentColor for scrubber; targetLiveWindow=0 collapses DVR for portal head-only."
    - "Boot-muted invariant: every MuxPlayer instance MUST set `muted` prop. User unmute is scoped to the instance; no localStorage persistence (D-35)."
    - "Portal download suppression: CSS module class `.portalNoDownload` targets mux-player shadow-DOM slots + CSS variable overrides to hide the download button. Paired approach for resilience across minor mux-player updates."
    - "Status-aware placeholder rendering pattern for VideoAsset: switch on asset.status at the top of the component body; 'ready' gates on manifestUrl; uploading/transcoding/failed each render typed placeholders from playerChrome.module.css."

key-files:
  created:
    - web/src/app/projects/[id]/cameras/usePlaybackToken.ts
    - web/src/app/projects/[id]/cameras/LiveStreamView.tsx
    - web/src/app/projects/[id]/cameras/VideoClipPlayer.tsx
    - web/src/app/projects/[id]/cameras/playerChrome.module.css
    - web/src/app/projects/[id]/cameras/__tests__/usePlaybackToken.test.tsx
    - web/src/app/projects/[id]/cameras/__tests__/players.test.tsx
  modified:
    - web/package.json
    - web/package-lock.json

key-decisions:
  - "Used @mux/mux-player-react import (not next/dynamic lazy) because the library already ships with 'use client' directive and renders a <mux-player> web component that degrades gracefully during SSR. No need for dynamic import indirection."
  - "Portal head-only (D-34a) implemented via MuxPlayer targetLiveWindow={0} prop rather than CSS pointer-events: none. targetLiveWindow=0 is the Mux-documented approach for collapsing the DVR seek range — it removes the scrub bar entirely at the media level rather than just hiding it visually."
  - "VideoClipPlayer builds the manifest URL inline using a pure function (buildManifestUrl) rather than a hook. Since the component just needs the URL string — no async fetch, no state — a function call is simpler and avoids unnecessary rerenders."
  - "Test structure: separate test files per component boundary (usePlaybackToken.test.tsx for the hook, players.test.tsx for both render components). Hook tests use vi.useFakeTimers for the auto-refresh schedule; player tests mock @mux/mux-player-react entirely and verify prop plumbing + branch coverage."

patterns-established:
  - "Player wrapper file layout (web): 'use client' directive → MuxPlayer import → type import from @/lib/video/types → local hook import → CSS module import → status branches → MuxPlayer render. Both LiveStreamView and VideoClipPlayer follow this shape."
  - "Fake-timer + flush pattern for testing hooks with setTimeout-based refresh: call vi.useFakeTimers() in beforeEach, use `await act(async () => { await vi.advanceTimersByTimeAsync(0) })` to drain the microtask queue between assertions. Avoids the waitFor timeout deadlock that occurs when testing-library polls with real timers against a frozen clock."

requirements-completed:
  - VIDEO-01-F
  - VIDEO-01-K

duration: 12min
completed: 2026-04-16
---

# Phase 22 Plan 07: Web Player Wrappers Summary

**Two client-side Mux Player wrappers shipped: LiveStreamView (LL-HLS, accent scrubber, portal head-only via targetLiveWindow=0) and VideoClipPlayer (on-demand, 4-status placeholders, portal download suppression via CSS shadow-DOM targeting), both boot-muted per D-35, powered by the usePlaybackToken auto-refresh hook (30s before TTL expiry). 14 vitest specs GREEN.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-04-16T06:10:00Z
- **Completed:** 2026-04-16T06:22:00Z
- **Tasks:** 2 (both TDD `tdd="true"` — RED then GREEN)
- **Files created:** 6 (4 source + 2 test)
- **Files modified:** 2 (package.json + package-lock.json)

## Accomplishments

- **usePlaybackToken hook.** React hook that POSTs to `/api/video/mux/playback-token` (default path) or `/api/portal/video/playback-token` (when `portalToken` supplied, D-19). Returns `{ token, playbackId, ttl, loading, error, refresh }`. Auto-refreshes 30s before TTL expiry via setTimeout; tears down on unmount via cancelledRef guard + clearTimeout. 5 GREEN specs cover routing, auto-refresh schedule, error surface, and cleanup.

- **LiveStreamView.** Client component wrapping `@mux/mux-player-react` with `streamType="ll-live"`. Fetches signed JWT via usePlaybackToken, passes it to `tokens={{ playback: token }}`. Status branches: `"offline"` renders red OFFLINE badge + placeholder; `loading` renders "Connecting to stream..." per UI-SPEC; `error` renders "Couldn't start playback..." UI-SPEC copy with Retry button; `active`/`idle` renders MuxPlayer with live status badge (green pulsing LIVE / gold IDLE). Portal mode: `targetLiveWindow={0}` collapses DVR (D-34a), `nohotkeys` blocks keyboard scrub. Boot muted (D-35). Accent scrubber via `accentColor="var(--accent)"`.

- **VideoClipPlayer.** Client component wrapping `@mux/mux-player-react` with `streamType="on-demand"` and `src` pointed at the signed HLS manifest route. 4-status switch: `uploading` shows "Uploading..." placeholder, `transcoding` shows gold shimmer + "Transcoding..." text, `failed` shows "Transcode failed..." UI-SPEC copy with last_error detail, `ready` renders MuxPlayer. Portal mode: portalNoDownload CSS class suppresses download button via shadow-DOM targeting. `disablePictureInPicture` per UI-SPEC (no PiP in web v1). Boot muted (D-35).

- **playerChrome.module.css.** 16:9 `.container` with `var(--panel)` background and 14px border-radius. Status badge overlay (`.badge` absolute top-left, 10px/800 uppercase letter-spaced). Status dot classes: `.badgeDotLive` (green with 2s pulse animation), `.badgeDotOffline` (red), `.badgeDotIdle` (gold). `.portalNoDownload` hides Mux download control via `::part()` + `media-download-button` selectors. `.shimmer` gold-gradient keyframe for transcoding state. `.retryButton` accent-filled CTA.

- **@mux/mux-player-react v3.11.7 installed.** Single dependency addition — internally bundles hls.js for non-Safari browsers; no separate hls.js dependency required.

## Task Commits

Each task committed atomically (TDD RED → GREEN pattern):

1. **Task 1 RED: usePlaybackToken test stubs** — `d7097ef` (test)
2. **Task 1 GREEN: @mux/mux-player-react + usePlaybackToken hook** — `fad0966` (feat)
3. **Task 2 RED: LiveStreamView + VideoClipPlayer test stubs** — `0fffe96` (test)
4. **Task 2 GREEN: LiveStreamView + VideoClipPlayer + playerChrome CSS** — `6869b01` (feat)

Plan metadata commit: pending (this SUMMARY + STATE + ROADMAP bundle).

## Files Created/Modified

### Created (6)

- `web/src/app/projects/[id]/cameras/usePlaybackToken.ts` (~95 lines) — Hook with auto-refresh, cancelledRef guard, dual-path routing
- `web/src/app/projects/[id]/cameras/LiveStreamView.tsx` (~100 lines) — LL-HLS player with status branches, portal head-only
- `web/src/app/projects/[id]/cameras/VideoClipPlayer.tsx` (~85 lines) — VOD player with 4-status switch, portal download suppression
- `web/src/app/projects/[id]/cameras/playerChrome.module.css` (~120 lines) — Container, badge, shimmer, portal download override
- `web/src/app/projects/[id]/cameras/__tests__/usePlaybackToken.test.tsx` (~135 lines) — 5 hook specs
- `web/src/app/projects/[id]/cameras/__tests__/players.test.tsx` (~165 lines) — 9 component specs

### Modified (2)

- `web/package.json` — +@mux/mux-player-react ^3.11.7
- `web/package-lock.json` — lockfile updated

## Decisions Made

1. **Direct import, not next/dynamic.** `@mux/mux-player-react` ships with `"use client"` in its ESM entry and renders a `<mux-player>` web component with `suppressHydrationWarning`. SSR renders the custom element tag harmlessly; client hydration activates the player. Dynamic import indirection would add complexity without benefit.
2. **targetLiveWindow=0 for portal head-only.** This is the Mux-documented prop for collapsing the DVR seek range at the media level. Superior to a CSS `pointer-events: none` fallback because it prevents scrubbing via keyboard, API, and touch — not just click.
3. **buildManifestUrl as a pure function.** VideoClipPlayer doesn't need async state for its URL — the manifest URL is computed synchronously from props. Using a hook would add unnecessary rerenders.
4. **Separate test files per component boundary.** Hook tests require fake timers for auto-refresh; player tests require jsdom + render + mock. Separating them keeps each test file focused and avoids timer/render interaction issues.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed waitFor timeout deadlock in hook tests**
- **Found during:** Task 1 GREEN (test run)
- **Issue:** Original tests used `waitFor(() => expect(result.current.token)...)` with `vi.useFakeTimers()` — waitFor's internal polling uses real timers, which are frozen, causing all 5 tests to timeout after 5s.
- **Fix:** Replaced `waitFor` with direct `await act(async () => { await vi.advanceTimersByTimeAsync(0) })` flush pattern. This drains the Promise microtask queue without relying on real-timer polling.
- **Files modified:** `web/src/app/projects/[id]/cameras/__tests__/usePlaybackToken.test.tsx`
- **Committed in:** `fad0966` (Task 1 GREEN commit)

**Total deviations:** 1 auto-fixed (Rule 1 — test bug fix). No behavioral or architectural changes.

## Issues Encountered

- **`getByText(/Offline/i)` matched two elements** in the offline-state test (the badge "OFFLINE" text and the "Offline · last seen recently" placeholder). Fixed by switching to `getByTestId("live-offline")` which is unambiguous.
- No authentication gates. No architectural decisions required. No Rule 4 triggers.

## User Setup Required

None for this plan itself. LiveStreamView and VideoClipPlayer are pure client components that consume the Mux JWT mint (22-03) and VOD manifest (22-04) routes already on main. The operator setup requirements from 22-03 (Mux API tokens, webhook registration) and 22-04 (Fly.io worker deployment) must be completed before end-to-end playback works.

## Next Phase Readiness

- **Unblocks 22-08** (Cameras section UI): CamerasSection can embed `<LiveStreamView source={source} />` for live camera tiles and `<VideoClipPlayer asset={asset} />` for VOD clip cards. The status badge vocabulary (green/gold/red) is centralized in playerChrome.module.css for reuse.
- **Unblocks 22-09** (portal exposure): Both players accept `portalToken` prop and apply D-34 restrictions internally. Portal pages just pass the token through.
- **Unblocks 22-11** (un-skip tests): The 14 specs under `cameras/__tests__/` are already running; the cameras-section.test.tsx stub in `__tests__/video/` remains for 22-08.
- **Zero blockers** for any downstream Phase 22 plan.

## Known Stubs

None. All four source files are load-bearing production code:
- usePlaybackToken wires real fetch calls to real API routes
- LiveStreamView and VideoClipPlayer render real MuxPlayer instances
- playerChrome.module.css provides real styling consumed by both components

## Threat Flags

None. This plan is pure client code consuming already-documented trust boundaries (22-03/22-04 server routes). No new network endpoints, auth paths, or trust-boundary schema changes. The portalToken parameter is a pass-through string validated server-side by the portal playback routes.

---

## Self-Check: PASSED
