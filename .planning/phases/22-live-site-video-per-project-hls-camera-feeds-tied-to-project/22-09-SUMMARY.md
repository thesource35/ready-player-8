---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 09
subsystem: api, ui
tags: [mux, jwt, hls, portal, video, supabase, swiftui, next.js]

# Dependency graph
requires:
  - phase: 22-01
    provides: cs_portal_config.show_cameras column, cs_video_sources/assets tables, portal_visible column
  - phase: 22-03
    provides: Mux playback JWT minting (signPlaybackJWT), rate limiting infra
  - phase: 22-04
    provides: VOD HLS manifest signing (signHlsManifest), Supabase storage layout
  - phase: 22-06
    provides: iOS LiveStreamView + VideoClipPlayer with portalToken support
  - phase: 22-07
    provides: Web LiveStreamView + VideoClipPlayer with portalToken support
  - phase: 22-08
    provides: ClipCard with portal toggle stub, CamerasSection wired into project page
provides:
  - Portal-scoped playback auth routes (playback-token for live, playback-url for VOD)
  - Portal page Cameras section conditionally rendered when show_cameras=true
  - Show cameras toggle in web PortalToggleRow + iOS PortalConfigView
  - Per-clip portal_visible toggle wired in ClipCard (owner/admin only, drone disabled)
  - D-22 drone exclusion enforced at route level and UI level
  - D-34 head-only live + streaming-only VOD (no-store cache) for portal viewers
  - D-37 rate limiting on portal video endpoints (30 req/min/IP)
affects: [22-10, 22-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Portal video auth: service-role Supabase client validates portal_token + cross-checks project_id before minting scoped JWT/signed URL"
    - "Portal section visibility: server-side show_cameras check gates entire Cameras section render"
    - "Drone exclusion: enforced at both route layer (403) and UI layer (disabled toggle with tooltip)"

key-files:
  created:
    - web/src/app/api/portal/video/playback-token/route.ts
    - web/src/app/api/portal/video/playback-url/route.ts
    - web/src/app/portal/[slug]/[project]/cameras/PortalCamerasSection.tsx
    - web/src/app/projects/[id]/cameras/PortalToggleRow.tsx
  modified:
    - web/src/app/portal/[slug]/[project]/page.tsx
    - web/src/app/projects/[id]/cameras/ClipCard.tsx
    - web/src/lib/portal/types.ts
    - ready player 8/Portal/PortalConfigView.swift
    - ready player 8/SupabaseService.swift
    - web/src/__tests__/video/portal-video-auth.test.ts

key-decisions:
  - "Portal playback routes use service-role Supabase client since portal viewers are unauthenticated — portal_token is sole credential"
  - "D-22 drone exclusion enforced redundantly at route + UI for defense-in-depth"
  - "VOD manifest returned with Cache-Control: private, max-age=0, no-store per D-34(b) streaming-only requirement"

patterns-established:
  - "Portal auth pattern: validate portal_token -> check link active -> cross-check project_id -> enforce source_type/visibility -> mint scoped credential"
  - "Portal section gating: show_cameras boolean in cs_portal_config controls server-side conditional render of entire section"

requirements-completed: [VIDEO-01-L]

# Metrics
duration: 8min
completed: 2026-04-15
---

# Phase 22 Plan 09: Portal Video Exposure Summary

**Portal-scoped playback auth routes (live JWT + VOD signed manifest) with show_cameras toggle, per-clip portal_visible wiring, and D-22 drone exclusion at route + UI layers**

## Performance

- **Duration:** 8 min (continuation from checkpoint)
- **Started:** 2026-04-15T00:00:00Z
- **Completed:** 2026-04-15T00:08:00Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 10

## Accomplishments
- Portal playback-token route mints Mux JWT for live cameras after validating portal_token, show_cameras, project_id match, and drone exclusion (D-22)
- Portal playback-url route signs HLS manifest for VOD clips with portal_visible check, no-store cache header (D-34), and drone block
- Portal page conditionally renders PortalCamerasSection when cs_portal_config.show_cameras=true
- Show cameras toggle wired in web PortalToggleRow and iOS PortalConfigView with Supabase persistence
- Per-clip portal_visible toggle un-stubbed in ClipCard with share/remove context menu items and drone disabled tooltip
- Both portal routes rate-limited to 30 req/min/IP (D-37) and return 410 on expired/revoked links

## Task Commits

Each task was committed atomically:

1. **Task 1: Portal playback auth routes** - `f9bd447` (feat)
2. **Task 2: Portal page Cameras section + Show cameras toggle + per-clip portal toggle** - `a9a89bd` (feat)
3. **Task 3: Human-verify checkpoint** - approved (no commit)

**Plan metadata:** [pending final commit]

_Note: TDD tasks have test + implementation in single commits_

## Files Created/Modified
- `web/src/app/api/portal/video/playback-token/route.ts` - POST route: validates portal_token, enforces show_cameras + drone block, mints Mux JWT
- `web/src/app/api/portal/video/playback-url/route.ts` - GET route: validates portal_token, enforces portal_visible + drone block, signs HLS manifest with no-store
- `web/src/app/portal/[slug]/[project]/cameras/PortalCamerasSection.tsx` - Client component rendering live streams + VOD clips in portal context
- `web/src/app/projects/[id]/cameras/PortalToggleRow.tsx` - Show cameras toggle for portal config editor
- `web/src/app/portal/[slug]/[project]/page.tsx` - Added show_cameras to config select + conditional PortalCamerasSection render
- `web/src/app/projects/[id]/cameras/ClipCard.tsx` - Un-stubbed portal_visible toggle with share/remove actions + drone disabled state
- `web/src/lib/portal/types.ts` - Added show_cameras field to PortalConfig type
- `ready player 8/Portal/PortalConfigView.swift` - Added Show cameras Toggle row + showCameras property
- `ready player 8/SupabaseService.swift` - Added show_cameras CodingKey mapping
- `web/src/__tests__/video/portal-video-auth.test.ts` - 9 test cases covering portal auth scenarios

## Decisions Made
- Portal playback routes use service-role Supabase client since portal viewers are unauthenticated — portal_token is the sole credential
- D-22 drone exclusion enforced redundantly at route level (403) and UI level (disabled toggle with tooltip) for defense-in-depth
- VOD manifest returned with `Cache-Control: private, max-age=0, no-store` per D-34(b) streaming-only requirement
- Live JWT TTL set to 300s (5 min) matching existing playback-token route pattern

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Portal video exposure is complete end-to-end
- Ready for 22-10 (retention + lifecycle cron) which prunes expired assets and webhook events
- Ready for 22-11 (analytics events) which wires portal_video_view at these new call sites

## Self-Check: PASSED

- All 4 created files exist on disk
- Both task commits (f9bd447, a9a89bd) found in git log

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Completed: 2026-04-15*
