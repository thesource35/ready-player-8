---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 08
subsystem: ui
tags: [swiftui, react, video, cameras, tus-upload, mux, hls, project-detail]

# Dependency graph
requires:
  - phase: 22-05
    provides: iOS VideoSyncManager + VideoUploadClient + SupabaseService video CRUD
  - phase: 22-06
    provides: iOS LiveStreamView + VideoClipPlayer + CellularQualityMonitor + VideoPlayerChrome
  - phase: 22-07
    provides: Web LiveStreamView + VideoClipPlayer + usePlaybackToken hook
provides:
  - iOS CamerasSection wired into ProjectDetail (CameraCard, ClipCard, AddCameraWizard, ClipUploadSheet)
  - Web CamerasSection wired into project detail page (CameraCard, ClipCard, AddCameraWizard, ClipUploadCard, SoftCapBanner)
  - Full camera registration wizard (2-step, Mux create-live-input, RTMP+key copy)
  - Clip upload UI (tus resumable, D-31 pre-check, progress bar)
  - Soft-cap banner (warning at 16, disable at 20 per D-28)
  - Audio jurisdiction warning + confirmation modal per D-35
  - Portal visibility toggle + drone exclusion per D-22/D-39
affects: [22-09-portal-video, 22-10-retention-lifecycle, 22-11-analytics, 22-12-verification]

# Tech tracking
tech-stack:
  added: [tus-js-client@^4.3.1]
  patterns: [2-step wizard with credential-reveal-once, tus resumable upload with 6MB chunks + retry, soft-cap banner pattern, status-aware card rendering with 200ms fade animations]

key-files:
  created:
    - "ready player 8/Video/CameraCard.swift"
    - "ready player 8/Video/ClipCard.swift"
    - "ready player 8/Video/AddCameraWizard.swift"
    - "ready player 8/Video/ClipUploadSheet.swift"
    - "ready player 8/Video/CamerasSection.swift"
    - web/src/app/projects/[id]/cameras/CamerasSection.tsx
    - web/src/app/projects/[id]/cameras/CameraCard.tsx
    - web/src/app/projects/[id]/cameras/ClipCard.tsx
    - web/src/app/projects/[id]/cameras/AddCameraWizard.tsx
    - web/src/app/projects/[id]/cameras/ClipUploadCard.tsx
    - web/src/app/projects/[id]/cameras/SoftCapBanner.tsx
  modified:
    - "ready player 8/ProjectsView.swift"
    - web/src/app/projects/[id]/page.tsx
    - web/package.json

key-decisions:
  - "tus-js-client ^4.3.1 for web resumable uploads (per RESEARCH.md verified version for Supabase)"
  - "CamerasSection is a client component that hydrates after server render — loading shimmer shows ~300ms on first load"

patterns-established:
  - "2-step wizard: step 1 collects user input, step 2 reveals server-generated credentials (show-once pattern for stream keys)"
  - "Soft-cap banner: warning at 80% capacity (gold), disable at 100% (red) with contact-support CTA"
  - "Status-aware cards: 200ms ease-out fade on all status transitions (green/gold/red vocabulary from UI-SPEC.md)"

requirements-completed: [VIDEO-01-D, VIDEO-01-G]

# Metrics
duration: 45min
completed: 2026-04-15
---

# Phase 22 Plan 08: Cameras Section UI Summary

**Full CamerasSection surface on iOS + web: 2-step camera wizard with Mux RTMP credentials, tus resumable clip upload with D-31 pre-checks, soft-cap banner (16/20), portal toggles, and status-animated cards wired into ProjectDetail**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-15T00:00:00Z
- **Completed:** 2026-04-15T01:00:00Z
- **Tasks:** 3 (2 auto + 1 human-verify)
- **Files modified:** 15

## Accomplishments
- iOS CamerasSection with CameraCard, ClipCard, AddCameraWizard, ClipUploadSheet wired into ProjectDetail via ProjectsView.swift
- Web CamerasSection with 6 components (CameraCard, ClipCard, AddCameraWizard, ClipUploadCard, SoftCapBanner, CamerasSection) wired into project detail page.tsx
- tus-js-client installed for web resumable uploads with 6MB chunks and retry delays [0, 3000, 5000, 10000, 20000]
- UI-SPEC.md copy contracts honored: empty states, audio jurisdiction warning, soft-cap banner, destructive delete modals
- 200ms ease-out status transition animations on both platforms

## Task Commits

Each task was committed atomically:

1. **Task 1: iOS CameraCard + ClipCard + AddCameraWizard + ClipUploadSheet + CamerasSection** - `00dfa95` (feat)
2. **Task 2: Web CamerasSection + cards + wizard + upload card + soft-cap banner + wire into page.tsx** - `bdeec02` (feat)
3. **Task 3: Human-verify Cameras section renders on both platforms** - user approved, no commit needed

**Plan metadata:** (this commit) (docs: complete plan)

## Files Created/Modified
- `ready player 8/Video/CameraCard.swift` - iOS camera card with status badge + thumbnail + name/location
- `ready player 8/Video/ClipCard.swift` - iOS clip card with status-aware UI (ready/transcoding/uploading/failed) + portal/drone pills
- `ready player 8/Video/AddCameraWizard.swift` - iOS 2-step wizard (name+audio -> RTMP URL+stream key)
- `ready player 8/Video/ClipUploadSheet.swift` - iOS upload sheet with PhotosPicker + fileImporter + VideoUploadClient
- `ready player 8/Video/CamerasSection.swift` - iOS parent container with soft-cap banner + live cameras grid + recent clips
- `ready player 8/ProjectsView.swift` - Wired CamerasSection into ProjectDetail
- `web/src/app/projects/[id]/cameras/CamerasSection.tsx` - Web client component with polling + empty states
- `web/src/app/projects/[id]/cameras/CameraCard.tsx` - Web camera card with status badges
- `web/src/app/projects/[id]/cameras/ClipCard.tsx` - Web clip card with status-aware rendering + portal toggle
- `web/src/app/projects/[id]/cameras/AddCameraWizard.tsx` - Web 2-step wizard with audio jurisdiction warning
- `web/src/app/projects/[id]/cameras/ClipUploadCard.tsx` - Web drag-drop upload with tus-js-client
- `web/src/app/projects/[id]/cameras/SoftCapBanner.tsx` - Web soft-cap banner (warning at 16, disable at 20)
- `web/src/app/projects/[id]/page.tsx` - Wired CamerasSection into project detail page
- `web/package.json` - Added tus-js-client@^4.3.1

## Decisions Made
- Used tus-js-client ^4.3.1 for web resumable uploads (per RESEARCH.md verified Supabase compatibility)
- CamerasSection is a client component that hydrates after server render; loading shimmer covers ~300ms initial fetch

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- CamerasSection surface complete on both platforms; portal video exposure (22-09), retention lifecycle (22-10), and analytics (22-11) can proceed
- All Wave 3 UI dependencies satisfied for downstream plans

## Self-Check: PASSED

- All 11 created files exist on disk
- Commit 00dfa95 (Task 1 iOS) verified in git log
- Commit bdeec02 (Task 2 web) verified in git log

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Completed: 2026-04-15*
