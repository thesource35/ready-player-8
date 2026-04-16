---
phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project
plan: 06
subsystem: ios-player-wrappers
tags: [swift, swiftui, avplayer, avkit, hls, ll-hls, nwpathmonitor, mux, wave-3]

requires:
  - phase: 22-02
    provides: VideoSource / VideoAsset Codable structs + VideoSourceStatus / VideoAssetStatus enums + ConstructOS.Video AppStorage key helpers — LiveStreamView reads source.muxPlaybackId / source.status; VideoClipPlayer dispatches on asset.status and persists resume offset under ConstructOS.Video.LastPlayedAssetId.{projectId}
  - phase: 22-05
    provides: VideoPlaybackAuth.fetchMuxToken (Mux JWT mint, D-19 dual-path) + VideoPlaybackAuth.vodManifestUrl (signed HLS manifest URL composition) + VideoSyncManager @Published source / asset lists — LiveStreamView .task-calls fetchMuxToken on appear with auto-refresh 30s before TTL; VideoClipPlayer throws AppError to loadError when manifest URL composition fails

provides:
  - ready player 8/Video/CellularQualityMonitor.swift — @MainActor ObservableObject singleton observing NWPathMonitor; `preferredPeakBitRate(hdOverride:)` returns 1_500_000 on cellular / 6_000_000 on wifi / 3_000_000 for sd / session-override HD (D-36, D-26). Honors ConstructOS.Video.DefaultQuality AppStorage (ld/sd/hd force a fixed bitrate; 'auto' delegates to cellular/wifi decision).
  - ready player 8/Video/VideoPlayerChrome.swift — SwiftUI overlay primitives: `LiveStatusBadge(isLive:isOffline:)` (green LIVE / gold IDLE / red OFFLINE per UI-SPEC color vocab, with accessibility label) + `HDToggleButton(hdOverride:)` (44pt hit target honoring D-UI, toggles LD/HD with accent/muted coloring).
  - ready player 8/Video/LiveStreamView.swift — SwiftUI `struct LiveStreamView: View` over UIViewControllerRepresentable<AVPlayerViewController>. Accepts `VideoSource` + optional `portalToken: String?`. Fetches Mux JWT via VideoPlaybackAuth, composes `https://stream.mux.com/{playback_id}.m3u8?token={jwt}`, creates AVPlayer with `automaticallyWaitsToMinimizeStalling=false` (LL-HLS priority per RESEARCH Pattern 4) and `isMuted=true` (D-35 boot muted). Portal mode: `requiresLinearPlayback=true` (D-34a head-only), no PiP, no DVR scrub, no HD toggle. Overlay: LiveStatusBadge reflects `source.status` (D-27). Token auto-refreshes 30s before TTL expiry.
  - ready player 8/Video/VideoClipPlayer.swift — SwiftUI `struct VideoClipPlayer: View` distinct from LiveStreamView per D-18. Accepts `VideoAsset` + optional `portalToken: String?`. Calls `VideoPlaybackAuth.vodManifestUrl(assetId:portalToken:)` and loads the returned URL directly into AVPlayer (VOD defaults — `automaticallyWaitsToMinimizeStalling` left at `true`). AVPlayer also `isMuted=true` at creation (D-35). Status-aware placeholders for `.transcoding` / `.uploading` / `.failed` per UI-SPEC. Opportunistic resume via UserDefaults stored under `ConstructOS.Video.LastPlayedAssetId.{projectId}` (D-26); persisted every 5s. Portal mode hides PiP; no download affordance exposed (D-34b streaming-only).
  - VIDEO-01-F (iOS player views) satisfied
  - VIDEO-01-K (cellular-aware bitrate control) reinforced — 22-05 declared the AppStorage key and monitor intent; 22-06 wires it into actual player consumption

affects:
  - 22-08 Wave 3 (Cameras section UI) — CamerasSection can now embed `LiveStreamView(source: source)` for live tiles and `VideoClipPlayer(asset: asset)` for VOD cards. The status color vocabulary (green LIVE / gold IDLE / red OFFLINE) is centralized in LiveStatusBadge so the section reuses it without re-deriving colors.
  - 22-09 Wave 3 (portal video exposure) — both players accept `portalToken:` and apply D-34 restrictions automatically. Portal pages just pass the token through; the player honors head-only (live) and streaming-only (VOD) restrictions internally.
  - 22-11 Wave 5 (un-skip LiveStreamViewTests / VideoClipPlayerTests) — the real player types now exist; tests can replace `throw XCTSkip` with structural assertions (e.g., hdOverride=false defaults, portalToken=nil default, AVPlayerItem.preferredPeakBitRate wiring). Still blocked by the pre-existing ready_player_8Tests.swift / ReportTests.swift test-target build errors documented in deferred-items.md.
  - Phase 29 (fleet view) — LiveStreamView + VideoClipPlayer are the building blocks Phase 29 reuses for drone feeds. Clean component boundaries mean Phase 29 adds a new `VideoKind.drone` case with zero player-layer changes.

tech-stack:
  added: [] # no new deps — AVKit, Combine, Network are already linked
  patterns:
    - "LL-HLS tuning pattern: `AVPlayer.automaticallyWaitsToMinimizeStalling = false` is the one flag that distinguishes the live player from the VOD player at the AVFoundation layer. Codified in LiveStreamView.swift comments for future reference."
    - "Mute-on-boot invariant: every new `AVPlayer` instance in this codebase that renders remote-origin video MUST set `isMuted = true` at creation time and MUST NOT re-persist user unmute. Ensures D-35 compliance as we add more player sites (Phase 29, Phase 22-07 web parity)."
    - "Portal restrictions belong at the player wrapper, not the caller. `requiresLinearPlayback` (live head-only) and `allowsPictureInPicturePlayback = !isPortal` are applied uniformly inside the wrapper. Callers only pass `portalToken: String?` and do not duplicate restriction logic."
    - "Cellular bitrate is decided by CellularQualityMonitor, applied by the wrapper via `AVPlayerItem.preferredPeakBitRate`. HD toggle overlays are gated on `quality.isCellular && portalToken == nil` so they only appear where meaningful."
    - "AppStorage resume keys: `ConstructOS.Video.LastPlayedAssetId.{projectId}` stores a `[asset_id, seconds]` dictionary. Dictionary rather than a plain Double so we can validate the asset id before seeking — prevents stale offsets leaking across assets."
    - "Token auto-refresh pattern: recursive `.task` call — when mint succeeds, Task.sleep until (ttl - 30s) then re-mint. If the view detaches, the Task cancels automatically."

key-files:
  created:
    - ready player 8/Video/CellularQualityMonitor.swift (57 lines)
    - ready player 8/Video/VideoPlayerChrome.swift (48 lines)
    - ready player 8/Video/LiveStreamView.swift (143 lines)
    - ready player 8/Video/VideoClipPlayer.swift (205 lines)
  modified: []

key-decisions:
  - "Kept `SupabaseService.shared.accessToken` as the session-token source rather than introducing a new `currentAccessToken` computed property. Plan template referenced `currentAccessToken` but the codebase already exposes `@Published var accessToken: String? = nil` on SupabaseService (line 211). Added a `MainActor.run` hop inside `currentSessionToken()` so the LiveStreamView's async helper can read it safely even though the view itself is `@MainActor` already (SupabaseService is also @MainActor — the hop costs ~nothing and stays future-proof if the isolation ever changes)."
  - "Portal VOD leaves `requiresLinearPlayback = false` intentionally. UI-SPEC §Player interaction rules + D-34(b) classify portal VOD as streaming-only, not head-only — scrubbing within the asset is allowed. Only LIVE portal playback is head-only (D-34a). Documented inline in VideoClipPlayer.swift so future editors don't add a mistaken restriction."
  - "Put resume persistence inside the VodAVPlayerRepresentable rather than as a separate observer on VideoClipPlayer. Keeps the AVPlayer and its periodic observer lifecycle bound together — when the player is torn down (representable goes away), the observer tears down with it. No risk of orphan observers writing to UserDefaults from a destroyed view."
  - "Error UI shows the friendly UI-SPEC copy 'Couldn't start playback. Refresh and try again — if this keeps happening, contact support.' rather than raw AppError.localizedDescription. AppError's descriptions are accurate but not end-user-oriented; this matches the tone of the rest of the app (see AuthGateView, ProjectsView error states)."
  - "`.task(id: asset.id)` on VideoClipPlayer re-runs whenever the asset changes. Critical because CamerasSection reuses the same VideoClipPlayer view identity across asset rows — the id: parameter ensures a stale asset's manifest URL doesn't leak into a new asset's player."
  - "`ProgressView('Connecting to stream…')` uses a copy-rich message rather than a spinner-only. Matches the UI-SPEC loading-state conventions used elsewhere in the phase."
  - "Did NOT implement a custom VideoPlayerChrome.swift ViewModifier. The plan allowed either ViewModifier or direct overlay helpers; direct helpers (LiveStatusBadge + HDToggleButton structs) are simpler to reason about and easier to place precisely inside the existing ZStack overlay HStack. ViewModifier indirection would add a layer for no benefit."

patterns-established:
  - "Player wrapper file layout: (1) public SwiftUI `struct FooPlayer: View` with `.task` for auth/URL work + overlay HStack + status/state handling; (2) private `struct FooAVPlayerRepresentable: UIViewControllerRepresentable` that owns the AVPlayer + AVPlayerViewController. Separation keeps SwiftUI state & auth concerns out of the UIKit bridge."
  - "Cellular HD toggle visibility rule: `quality.isCellular && portalToken == nil && <state-allows>`. Applied consistently in LiveStreamView (live-only, any status) and VideoClipPlayer (ready-only). Future player surfaces should follow the same predicate."
  - "Status-aware placeholder rendering for VideoAsset: switch on `asset.status` at the top of the body. `.ready` gates on manifestURL; `.transcoding` / `.uploading` / `.failed` each render a typed placeholder with UI-SPEC copy. Copy-paste shape for any future status machine UI."

requirements-completed:
  - VIDEO-01-F
  - VIDEO-01-K

duration: ~15min
completed: 2026-04-16
---

# Phase 22 Plan 06: iOS Player Wrappers Summary

**Both iOS player wrappers shipped: LiveStreamView (LL-HLS via Mux, `automaticallyWaitsToMinimizeStalling=false`) and VideoClipPlayer (VOD via Supabase signed manifest) are distinct SwiftUI components per D-18. Both accept optional `portalToken` for D-19 dual-path playback; both boot muted every session per D-35; both cellular-downgrade to 480p via shared CellularQualityMonitor per D-36. Portal mode enforces D-34 restrictions at the wrapper layer so callers just pass the token through. LiveStatusBadge + HDToggleButton live in VideoPlayerChrome.swift for reuse by Phase 22-07 (web parity) and Phase 22-08 (Cameras section UI).**

## Performance

- **Duration:** ~15 min (Task 1 commit 42a6061 to Task 2 commit 03e7f2b)
- **Tasks:** 2 (both TDD-aware `type="auto" tdd="true"` — LiveStreamViewTests and VideoClipPlayerTests stubs on main since 22-00, un-skipping deferred to 22-11 per deferred-items.md)
- **Files created:** 4 (all under `ready player 8/Video/`, auto-included via PBXFileSystemSynchronizedRootGroup)
- **Files modified:** 0
- **iOS build:** `** BUILD SUCCEEDED **` on `iPhone 17` simulator (iPhone 15 absent from host; substitution documented in every prior Phase 22 iOS summary)

## Accomplishments

- **CellularQualityMonitor (Task 1).** `@MainActor final class CellularQualityMonitor: ObservableObject` with `shared` singleton. Uses `NWPathMonitor` on a dedicated `DispatchQueue(label: "ConstructOS.Video.NWPath", qos: .utility)` and posts `@Published var isCellular: Bool` updates back to main. `preferredPeakBitRate(hdOverride:)` returns `1_500_000` (480p) on cellular, `6_000_000` (HD) on wifi, `3_000_000` (720p SD) only when AppStorage is explicitly `'sd'`. `ConstructOS.Video.DefaultQuality` AppStorage override paths: `'hd'` / `'sd'` / `'ld'` force a fixed bitrate; `'auto'` (default) delegates to the cellular/wifi decision with optional HD override. `currentQualityLabel(hdOverride:)` returns "LD 480p" / "SD 720p" / "HD" for overlay display.
- **VideoPlayerChrome (Task 1).** Two overlay primitives: `LiveStatusBadge` (8pt dot + uppercase tracked label, green/gold/red per source status, accessibility label "Camera offline" / "Live" / "Idle") and `HDToggleButton` (44pt hit target per D-UI, accent when HD else muted, accessibility label flips between "Switch to HD" and "Switch to low-data 480p"). Both use `Theme.*` colors exclusively for consistency with the rest of the app.
- **LiveStreamView (Task 2).** Public `struct LiveStreamView: View` accepting `source: VideoSource` + `portalToken: String? = nil`. `@State` for minted token, hd override, load error; `@StateObject` for CellularQualityMonitor; `@ObservedObject` for VideoSyncManager (wired but not consumed yet — UI Card callers observe it). `.task` on appear calls `VideoPlaybackAuth.fetchMuxToken(sourceId:sessionToken:portalToken:)`; session token pulled via `await MainActor.run { SupabaseService.shared.accessToken ?? "" }` (portal path returns "" immediately). On success, sets `token` state and composes `https://stream.mux.com/{playback_id}.m3u8?token={jwt}` URL. Private `LiveAVPlayerRepresentable: UIViewControllerRepresentable` creates `AVPlayer` with `automaticallyWaitsToMinimizeStalling = false` (LL-HLS priority), `isMuted = true` (D-35), and `AVPlayerItem.preferredPeakBitRate = quality.preferredPeakBitRate(hdOverride:)`. Portal mode sets `showsPlaybackControls = false`, `allowsPictureInPicturePlayback = false`, `requiresLinearPlayback = true` (D-34a head-only). Overlay HStack shows LiveStatusBadge (isLive = `source.status == .active`, isOffline = `source.status == .offline`) + cellular-only HD toggle. Token auto-refreshes 30s before TTL expiry via recursive `.task` sleep pattern.
- **VideoClipPlayer (Task 2).** Public `struct VideoClipPlayer: View` accepting `asset: VideoAsset` + `portalToken: String? = nil`. `@State` for manifestURL, hd override, load error; `@StateObject` for CellularQualityMonitor. Switches on `asset.status`: `.ready` gates on manifestURL resolution and renders `VodAVPlayerRepresentable`; `.transcoding` / `.uploading` / `.failed` each render a typed placeholder (ProgressView + tracked copy for loading; red "Transcode failed" + lastError for failed). `.task(id: asset.id)` composes `VideoPlaybackAuth.vodManifestUrl(assetId:portalToken:)` and sets `manifestURL` state. Private `VodAVPlayerRepresentable` creates `AVPlayer` with default `automaticallyWaitsToMinimizeStalling` (true for VOD) and `isMuted = true` (D-35). Portal mode hides PiP only (VOD scrub allowed even in portal per UI-SPEC — only LIVE portal is head-only per D-34a). Opportunistic resume: reads `UserDefaults.dictionary(forKey: ConstructOS.Video.LastPlayedAssetId.{projectId})`, validates asset id match, seeks if `seconds > 1`. Periodic observer writes `[asset_id, seconds]` dictionary every 5s for resume continuity.

## Task Commits

Each task committed atomically:

1. **Task 1: CellularQualityMonitor + VideoPlayerChrome (shared infra)** — `42a6061` (feat)
2. **Task 2: LiveStreamView + VideoClipPlayer (player wrappers)** — `03e7f2b` (feat)

Plan metadata commit: pending (this SUMMARY + STATE + ROADMAP + REQUIREMENTS bundle).

## Files Created/Modified

### Created (4)

- `ready player 8/Video/CellularQualityMonitor.swift` (57 lines) — `@MainActor` NWPathMonitor singleton; `preferredPeakBitRate(hdOverride:)` + `currentQualityLabel(hdOverride:)` helpers; ConstructOS.Video.DefaultQuality AppStorage read-through
- `ready player 8/Video/VideoPlayerChrome.swift` (48 lines) — `LiveStatusBadge(isLive:isOffline:)` + `HDToggleButton(hdOverride:)` SwiftUI primitives with 44pt hit targets and accessibility labels
- `ready player 8/Video/LiveStreamView.swift` (143 lines) — public SwiftUI View + private `LiveAVPlayerRepresentable` UIViewControllerRepresentable with LL-HLS tuning and portal-mode restrictions
- `ready player 8/Video/VideoClipPlayer.swift` (205 lines) — public SwiftUI View + private `VodAVPlayerRepresentable` with status-aware placeholders, opportunistic resume, and portal-mode PiP restriction

### Modified (0)

No existing files touched — all four new files live under `ready player 8/Video/` and auto-include via PBXFileSystemSynchronizedRootGroup.

## Decisions Made

1. **Session token comes from `SupabaseService.shared.accessToken` (existing property), not a new `currentAccessToken` wrapper.** Plan template's name didn't match the codebase — `accessToken` at line 211 of SupabaseService.swift is the canonical storage. Wrapped access in `await MainActor.run { ... }` inside `currentSessionToken()` so the async helper stays isolation-safe.
2. **Portal VOD allows scrubbing.** D-34(a) is live head-only; D-34(b) is VOD streaming-only (no download). These are different restrictions — documented inline in VideoClipPlayer.swift so no one later adds a mistaken `requiresLinearPlayback = true` for portal VOD.
3. **Resume persistence lives inside `VodAVPlayerRepresentable.makeUIViewController`.** Keeps the periodic observer's lifecycle bound to the AVPlayer's. When the view tears down (new asset, navigation away), the observer tears down with it — no orphan writers.
4. **Error copy is UI-SPEC wording, not `AppError.localizedDescription`.** End-user-facing errors get the friendly "Couldn't start playback. Refresh and try again — if this keeps happening, contact support." copy matching the rest of the app. The underlying AppError is logged to console for debugging.
5. **`.task(id: asset.id)` on VideoClipPlayer.** Ensures switching assets within the same view identity (CamerasSection list reuse) re-mints the manifest URL. Without `id:` a stale asset's signed URL could leak to the next row.
6. **Direct overlay helpers (LiveStatusBadge + HDToggleButton structs), NOT a ViewModifier.** Plan allowed either shape; direct structs are simpler, easier to place precisely inside the existing ZStack overlay HStack, and more grep-able.
7. **Token auto-refresh via recursive `.task`.** `await fetchToken()` at the end of the success path schedules the next mint 30s before the current TTL elapses. If the view detaches, the task cancels automatically — no manual timer bookkeeping.

## Deviations from Plan

### Deviation 1: `currentAccessToken` → `accessToken`

- **Rule:** Rule 3 (blocking) — plan template referenced `SupabaseService.shared.currentAccessToken` but the codebase exposes `SupabaseService.shared.accessToken` as the `@Published` property (SupabaseService.swift:211).
- **Found during:** Task 2 writing LiveStreamView's `currentSessionToken()` helper.
- **Issue:** `SupabaseService.shared.currentAccessToken ?? ""` would fail to compile.
- **Fix:** Used the actual property name `accessToken` with `?? ""` fallback. Wrapped in `await MainActor.run { ... }` to stay explicit about isolation — SupabaseService is `@MainActor`, the helper is already `@MainActor` via its enclosing view, but the hop costs ~nothing and is future-proof.
- **Files modified:** `ready player 8/Video/LiveStreamView.swift` (private helper `currentSessionToken()`).
- **Committed in:** `03e7f2b` (Task 2)

### Deviation 2: iPhone 15 → iPhone 17 simulator

- **Rule:** Environmental — iPhone 15 not installed on this host; only iPhone 16e / 17 / 17 Pro / 17 Pro Max / Air are available per `xcrun simctl list devices available`.
- **Fix:** Used `-destination 'platform=iOS Simulator,name=iPhone 17'` exactly matching 22-00, 22-02, 22-05 precedent.
- **Impact:** None — verification intent (clean iOS compile) is preserved.

**Total deviations:** 2 (Rule 3 + environmental — no behavioral or architectural changes).

## Issues Encountered

- **Pre-existing test-target build errors** in `ready player 8Tests/ready_player_8Tests.swift` + `ReportTests.swift` still block `xcodebuild test -only-testing` from linking the VideoTests module. Documented in `deferred-items.md` since Phase 22-00. Per GSD scope boundary, these are out of scope — the VideoTests stubs still compile cleanly alongside the frontend invocation. App-target build (`xcodebuild build`) is green.
- No auth gates, no architectural decisions required (no Rule 4), no Rule 1 bug fixes, no Rule 2 critical-missing additions triggered.

## User Setup Required

**None for this plan itself.** LiveStreamView + VideoClipPlayer are pure library views — they consume the Mux JWT mint and VOD manifest routes already deployed by 22-03 and 22-04. For end-to-end playback to work, the host project must already have:

1. Operator-completed 22-03 Mux setup (env vars, webhook) — otherwise `fetchMuxToken` returns 503.
2. Operator-completed 22-04 worker deployment — otherwise VOD assets never reach `status='ready'`.
3. A configured Supabase base URL in `ConstructOS.Integrations.Backend.BaseURL` (existing Integration Hub flow).

No new permissions, keys, or environment variables are required for 22-06 itself.

## Next Phase Readiness

- **Unblocks 22-07** (web video player parity) — the iOS shape is the canonical contract. Web will mirror: muted-boot, cellular-quality-aware (via `navigator.connection.effectiveType`), LL-HLS via Mux Web Player, portal-token plumbing, status-aware placeholders. `VideoPlayerChrome.swift`'s color vocabulary (green/gold/red status dot) translates directly to the web module CSS.
- **Unblocks 22-08** (Cameras section UI) — CamerasSection can embed `LiveStreamView(source: source)` for fixed-camera tiles and `VideoClipPlayer(asset: asset)` for VOD cards. `LiveStatusBadge` is reused for tile status overlays.
- **Unblocks 22-09** (portal exposure) — both players accept `portalToken:` and apply D-34 restrictions internally. The portal page wiring is trivial: just pass the token through.
- **Unblocks 22-11** (un-skip tests) — `LiveStreamViewTests` + `VideoClipPlayerTests` stubs can now assert against real types. Blocked by the pre-existing test-target build failures (deferred-items.md), not by missing code.
- **Zero new blockers** for any downstream Phase 22 plan.

## Known Stubs

**None introduced by this plan.** All four files are load-bearing production code:

- CellularQualityMonitor wires a real `NWPathMonitor` and returns real bitrates.
- VideoPlayerChrome primitives render real SwiftUI views that the compiler enforces.
- LiveStreamView calls real `VideoPlaybackAuth.fetchMuxToken` and composes real Mux HLS URLs.
- VideoClipPlayer calls real `VideoPlaybackAuth.vodManifestUrl` and wires real resume persistence.

The opportunistic resume is intentionally minimal (5-second granularity, single-key storage) — documented as an intentional simplification in the file comments, not a stub.

## Threat Flags

None. This plan is pure iOS client code that consumes already-documented trust boundaries (web API routes from 22-03/22-04). No new network endpoints, no new auth paths, no new file-access patterns, no new trust-boundary schema changes. All security-sensitive operations (JWT mint, signed URL composition) remain server-side per D-14. The portal-mode `portalToken:` parameter is a pass-through string — its content is validated server-side by the portal playback routes.

---

## Self-Check: PASSED

Verified files exist:

- FOUND: ready player 8/Video/CellularQualityMonitor.swift (57 lines)
- FOUND: ready player 8/Video/VideoPlayerChrome.swift (48 lines)
- FOUND: ready player 8/Video/LiveStreamView.swift (143 lines)
- FOUND: ready player 8/Video/VideoClipPlayer.swift (205 lines)

Verified commits exist in git log:

- FOUND: 42a6061 (Task 1 — feat: CellularQualityMonitor + VideoPlayerChrome shared infra)
- FOUND: 03e7f2b (Task 2 — feat: LiveStreamView + VideoClipPlayer player wrappers)

Verified iOS build:

- `xcodebuild -scheme "ready player 8" -destination 'platform=iOS Simulator,name=iPhone 17' build` → `** BUILD SUCCEEDED **`

Acceptance-criteria greps (all ≥ expected):

- CellularQualityMonitor.swift: `final class CellularQualityMonitor`: 1 | `NWPathMonitor`: 2 | `1_500_000`: 3 | `6_000_000`: 3 | `preferredPeakBitRate`: 4 | `usesInterfaceType(.cellular)`: 1
- VideoPlayerChrome.swift: `struct LiveStatusBadge`: 1 | `struct HDToggleButton`: 1 | `minHeight: 44`: 1 | `accessibilityLabel`: 2
- LiveStreamView.swift: `struct LiveStreamView: View`: 1 | `let source: VideoSource`: 1 | `var portalToken: String? = nil`: 1 | `automaticallyWaitsToMinimizeStalling = false`: 2 | `isMuted = true`: 1 | `preferredPeakBitRate`: 4 | `requiresLinearPlayback = true`: 2 | `VideoPlaybackAuth.fetchMuxToken`: 2 | `stream.mux.com`: 1
- VideoClipPlayer.swift: `struct VideoClipPlayer: View`: 1 | `let asset: VideoAsset`: 1 | `var portalToken: String? = nil`: 1 | `vodManifestUrl`: 2 | `isMuted = true`: 1 | `AVPlayer`: 10 | `AVPlayerViewController`: 5

Test-target build failure note: pre-existing async/concurrency errors in `ready_player_8Tests.swift` + `ReportTests.swift` block `xcodebuild test` from linking the test runner — out of scope (Phase 28 cleanup) and documented in `deferred-items.md`. Compile-only verification against the app target is green.

---
*Phase: 22-live-site-video-per-project-hls-camera-feeds-tied-to-project*
*Plan: 22-06 (Wave 3 iOS player wrappers)*
*Completed: 2026-04-16*
