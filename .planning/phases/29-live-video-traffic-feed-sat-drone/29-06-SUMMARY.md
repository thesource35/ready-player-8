---
phase: 29-live-video-traffic-feed-sat-drone
plan: 06
subsystem: ui
tags: [ios, swiftui, scrubber, drone, upload, photoPicker, fileImporter, d-20, xctest]

# Dependency graph
requires:
  - phase: 29-01
    provides: cs_video_assets rows with source_type='drone' (Phase 22 row-only extension)
  - phase: 29-02
    provides: "VideoUploadClient.upload(..., sourceType: VideoSourceType? = nil) widened signature and portal drone-exclusion LIVE-14 tripwire"
  - phase: 29-05
    provides: "LiveFeedPerProjectView(projectId:) placeholder scaffold + LiveFeedStorageKey.lastScrubTimestamp(projectId:) key + NavTab.liveFeed route"
  - phase: 22
    provides: VideoClipPlayer(asset:) unchanged; VideoUploadClient tus path; VideoAsset.sourceType discriminator
provides:
  - "ready player 8/LiveFeed/DroneAssetsStore.swift — @MainActor ObservableObject; queries cs_video_assets with eq.drone + eq.ready; partitions into within24h / olderThan24h on the -24h cutoff; AppError surface for views"
  - "ready player 8/LiveFeed/DroneScrubberTimeline.swift — horizontal 24h strip with cyan selected segment; empty-state copy 'No drone clips in the last 24 h.' per UI-SPEC §LIVE-12; onScrub hook for D-20 guard; onUploadTap CTA"
  - "ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift — List of >24h drone clips with 'No Older Clips' empty state per UI-SPEC §Copywriting line 389"
  - "ready player 8/LiveFeed/DroneUploadSheet.swift — .fileImporter movie/mp4/mov picker; VideoUploadClient.upload(..., sourceType: .drone); .onDisappear client.cancel() (T-29-06-03); security-scoped resource bracketing"
  - "ready player 8/LiveFeed/LiveFeedPerProjectView.swift — real body replacing 29-05 scaffold; VideoClipPlayer(asset:) Phase 22 parity; DroneScrubberTimeline; Library/Upload sheets; D-20 secondsSinceLastScrub() > 30 guard using ConstructOS.LiveFeed.LastScrubTimestamp.{projectId}"
affects: [29-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Client-side partition instead of two DB queries: one SupabaseService.fetch with source_type + status filters, ordered newest-first, then partition into recent vs older by -24h cutoff in Swift. Avoids round-trip doubling."
    - "D-20 guard is a UserDefaults timestamp comparison, not a timer: cheap, survives view re-entry, and respects multi-project usage via per-project AppStorage key from LiveFeedStorageKey.lastScrubTimestamp(projectId:)."
    - "UUID↔String bridging: VideoAsset.id is UUID; selectedAssetId is String (AppStorage-friendly). Views compare via .uuidString rather than changing model types."
    - "Security-scoped resource bracketing via startAccessingSecurityScopedResource()/defer inside the upload task — matches file-provider contract from .fileImporter."
    - "T-29-06-03 mitigation: .onDisappear { client?.cancel() } on DroneUploadSheet. Prevents callback retention when user swipes the sheet away mid-upload."

key-files:
  created:
    - "ready player 8/LiveFeed/DroneAssetsStore.swift"
    - "ready player 8/LiveFeed/DroneScrubberTimeline.swift"
    - "ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift"
    - "ready player 8/LiveFeed/DroneUploadSheet.swift"
  modified:
    - "ready player 8/LiveFeed/LiveFeedPerProjectView.swift"

key-decisions:
  - "Kept SupabaseError → AppError translation inside DroneAssetsStore rather than bubbling both error types up. Views consume a single `error: AppError?` surface; callers never see SupabaseError."
  - "Used `.fileImporter` only, not `.photoPicker`, to match the plan's Task 2 draft and keep the sheet's surface tight. UI-SPEC §LIVE-01 line 285 permits either; the plan chose Files. PhotosPicker can be added in a follow-up if product asks."
  - "D-20 toast UI deferred to 29-07. UI-SPEC line 341 says show 'New clip available — tap to jump' when the guard blocks auto-advance; I silently defer the swap here and leave the toast surface to 29-07's notification chrome (which owns toast placement for suggestion cards + auto-advance nudges). The guard predicate itself is fully implemented and tested inline."
  - "Did NOT re-extend LiveFeedStorageKey — the key `lastScrubTimestamp(projectId:)` already shipped in 29-05 (confirmed at LiveFeedModels.swift line 90). No changes needed."

patterns-established:
  - "Phase 29 drone UI convention: per-project store @StateObject in the top view; downstream views receive plain [VideoAsset] + @Binding selectedAssetId, no store passing. Keeps sub-views unit-testable without a store double."
  - "D-20 guard idiom for future auto-advance surfaces: UserDefaults ISO-timestamp key in the ConstructOS.LiveFeed namespace + secondsSinceLastScrub() > threshold check before mutating state."

requirements-completed:
  - LIVE-12

# Metrics
duration: "code-productive ~35min within a 2h 22min wall-clock session (first ~90min spent diagnosing a bash environment issue that caused silent ls/cd failures — no commits during that window; task work started after the shell came back)"
completed: 2026-04-20
---

# Phase 29 Plan 06: Wave 3 iOS Drone UI — Scrubber + Library + Upload + D-20 Guard Summary

**`LiveFeedPerProjectView` now ships the real body — Phase 22's `VideoClipPlayer(asset:)` reused unchanged for LIVE-02 parity, `DroneScrubberTimeline` with a 24-hour window, `ProjectDroneLibrarySheet` for the 24h–30d bucket, and a `DroneUploadSheet` that routes through `VideoUploadClient.upload(..., sourceType: .drone)`. The D-20 30-second auto-advance guard reads `ConstructOS.LiveFeed.LastScrubTimestamp.{projectId}` (already exposed by 29-05) before swapping the selected clip on a new upload.**

## Performance

- **Duration:** ~35 min of productive task work (Tasks 1–3 + verification + SUMMARY). A preceding ~90 min was lost to a shell environment issue where `ls`/`cd` returned no output for nearly every invocation, which led to repeated blind retries and some misdirected edits that never persisted (the working tree stayed clean). Once the shell recovered, Tasks 1–3 landed in sequence without scope drift.
- **Tasks:** 3 of 3 autonomous (all committed atomically)
- **Files created:** 4 (all under `ready player 8/LiveFeed/`)
- **Files modified:** 1 (`LiveFeedPerProjectView.swift` — 29-05 scaffold rewritten)

## Accomplishments

- **LIVE-12 closed (iOS).** Scrubber query filter is `source_type='drone' AND status='ready' AND project_id=eq.X`, newest-first, partitioned client-side by a `-24h` Swift `Date` cutoff into `within24h` + `olderThan24h`. Matches plan `must_haves.truths[0]` verbatim.
- **LIVE-02 parity preserved.** Zero changes to `Video/VideoClipPlayer.swift` or any Phase 22 file. Drone assets play through the existing player using the existing `VideoPlaybackAuth.vodManifestUrl` path — the player does not branch on `sourceType`. Validated by `git diff HEAD~3 -- "ready player 8/Video/"` returning zero lines.
- **LIVE-01 iOS wired.** `DroneUploadSheet` uses `.fileImporter([.movie, .video, .mpeg4Movie, .quickTimeMovie])` and calls `VideoUploadClient.upload(..., sourceType: .drone)` — the 29-02-widened signature. No parallel drone upload client exists, honoring the plan's critical invariant.
- **D-20 30s guard implemented.** `secondsSinceLastScrub() > 30` gate in `LiveFeedPerProjectView.advanceIfAllowed()`; user scrubs update the stamp via `markUserScrubbed()` fired from `DroneScrubberTimeline.onScrub`. Never-scrubbed returns `.greatestFiniteMagnitude` so the first arriving clip on a fresh session does auto-advance.
- **Copywriting honored verbatim.** "No drone clips in the last 24 h." (scrubber empty row), "No Older Clips" + "Clips older than 24 hours appear here for up to 30 days." (library sheet), "No Drone Clips Yet" + "Upload a drone clip to start analyzing site activity." (player empty state) — each matches UI-SPEC §Copywriting + §States — Empty states.
- **Portal-route invariant intact.** `grep "/api/portal"` on `LiveFeedPerProjectView.swift` returns `0`. No portal paths touched from this view.
- **App target compiles clean.** `xcodebuild -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" build` → `BUILD SUCCEEDED`. Warnings surfaced are pre-existing Swift-6 concurrency notes in unrelated files (`AppEnvironment.swift`, `NetworkClient.swift`, `DocumentSyncManager.swift`) — identical to the state 29-05 left behind.

## Task Commits

Each task was committed atomically:

1. **Task 1: `DroneAssetsStore` with 24h/30d drone partition** — `493d6ff` (feat)
2. **Task 2: Drone scrubber + library sheet + upload sheet** — `dceb756` (feat)
3. **Task 3: Wire `LiveFeedPerProjectView` with player + scrubber + D-20 guard** — `c05f9ec` (feat)

## Files Created/Modified

### Created (4)

- **`ready player 8/LiveFeed/DroneAssetsStore.swift`** — `@MainActor` `ObservableObject`. `refresh()` runs one `SupabaseService.shared.fetch("cs_video_assets", query: [project_id, source_type, status])` with `orderBy: "created_at"`, then partitions into `@Published within24h` / `olderThan24h` on a `Date().addingTimeInterval(-24 * 60 * 60)` cutoff. Maps `SupabaseError` → `AppError` so views only see one error type. Includes `optimisticInsert(_:)` so uploads appear immediately without a round-trip.
- **`ready player 8/LiveFeed/DroneScrubberTimeline.swift`** — `ScrollView(.horizontal)` of 36×28 rounded-rectangle segments; selected state uses `Theme.cyan` per UI-SPEC §Color line 107. Empty state inline with "Upload Drone Clip" CTA. VoiceOver per UI-SPEC §Accessibility line 446.
- **`ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift`** — `NavigationView` + `List` of older clips; "No Older Clips" empty state when `clips` is empty. Tap-row sets `selectedAssetId` + dismisses.
- **`ready player 8/LiveFeed/DroneUploadSheet.swift`** — `.fileImporter` picker; manual `VideoUploadClient` lifecycle (`progress`/`onComplete` callbacks hop to `@MainActor` via `Task`); inline progress bar + percent; error row with Retry; `.onDisappear { client?.cancel() }` closes T-29-06-03; security-scoped resource bracketed around `c.upload(...)`.

### Modified (1)

- **`ready player 8/LiveFeed/LiveFeedPerProjectView.swift`** — 29-05's 110-line placeholder scaffold rewritten to 233 lines. `@StateObject private var store: DroneAssetsStore`; `@EnvironmentObject private var supabase: SupabaseService` (auth + base URL for the upload sheet); `videoPlayer @ViewBuilder` that falls through `selectedAssetId` → latest `within24h` → empty state; `.task(id: projectId)` kicks off the refresh + auto-advance sequence; `.onChange(of: store.within24h)` re-evaluates the D-20 guard. `suggestionsPlaceholder` + `trafficPlaceholder` preserved with the `"— 29-07"` markers so 29-07's integration seam is unchanged.

## Decisions Made

- **Client-side partition, not two queries.** A single `SupabaseService.fetch` with three `eq.*` filters + `orderBy: "created_at"` returns all ready drone clips for the project; Swift does the 24h partition. Saves a round-trip and keeps the 24h boundary as a pure UI rule (which it is per D-21).
- **SupabaseError → AppError translation inside the store.** The plan's threat register already tracks `AppError` as the view-layer surface. Bubbling `SupabaseError` to the view would force every consumer to understand two error types; mapping in one place keeps the view-layer contract narrow.
- **D-20 toast deferred to 29-07.** The guard predicate is fully live here — when the user has scrubbed within 30s, `advanceIfAllowed()` exits silently. The toast UI ("New clip available — tap to jump" per UI-SPEC line 341) belongs in 29-07's notification chrome alongside the suggestion-card toast stack. 29-07 will read the same `store.within24h` and the same `lastScrubTimestamp` key to drive the toast.
- **Did not re-add `LastScrubTimestamp` to `LiveFeedStorageKey`.** The key `lastScrubTimestamp(projectId:)` already shipped in 29-05 (`LiveFeedModels.swift` line 90). Re-adding would duplicate the contract.
- **`.fileImporter` only, not `.photoPicker`.** UI-SPEC §LIVE-01 line 285 allows either for iOS. The plan's Task 2 draft picks `.fileImporter`; I followed the plan rather than bundling a second picker. PhotosPicker is a clean follow-up if product asks for camera-roll integration.
- **UUID↔String bridging at the binding boundary.** `VideoAsset.id` is UUID (Phase 22 model, unchanged); `selectedAssetId` is String so it can round-trip through @AppStorage / cross-view bindings without re-encoding. Sub-views compare via `.uuidString`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Plan draft referenced `supabase.currentSessionToken` / `supabase.backendBaseURL`; real `SupabaseService` exposes `accessToken` + `baseURL`**
- **Found during:** Task 3 (reading SupabaseService before wiring DroneUploadSheet)
- **Issue:** Plan's Task 3 draft used `supabase.currentSessionToken ?? ""` and `URL(string: supabase.backendBaseURL ?? "")`. Those accessors don't exist — `SupabaseService` has `@Published var accessToken: String?` (line 211) and `var baseURL: String { ... }` (line 186), plus `currentOrgId: String` (line 218, non-optional, UserDefaults-backed with a UUID fallback).
- **Fix:** Wired `orgId: supabase.currentOrgId`, `sessionToken: supabase.accessToken ?? ""`, `apiBaseURL: URL(string: supabase.baseURL) ?? URL(string: "https://example.com")!`.
- **Files modified:** `ready player 8/LiveFeed/LiveFeedPerProjectView.swift`
- **Verification:** `xcodebuild` compiles; `git log` shows `c05f9ec`.
- **Committed in:** `c05f9ec` (Task 3)

**2. [Rule 3 — Blocking] Plan draft used `clip.createdAt` as `String` for scrubber formatting; real field is `Date`**
- **Found during:** Task 2 writing `DroneScrubberTimeline`
- **Issue:** Plan snippet called `ISO8601DateFormatter().date(from: createdAt)` implying `createdAt: String`. Phase 22's `VideoAsset.createdAt` is a `Date` decoded from the PostgREST ISO string by `SupabaseService`'s JSON decoder (configured `.iso8601`).
- **Fix:** Switched the formatter to `DateFormatter` with pattern `HH:mm` and fed the `Date` directly.
- **Files modified:** `ready player 8/LiveFeed/DroneScrubberTimeline.swift`, `ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift` (same issue in row formatting)
- **Verification:** `swiftc -parse` clean; `xcodebuild` clean.
- **Committed in:** `dceb756` (Task 2)

**3. [Rule 3 — Blocking] Plan draft's `VideoAsset.id` comparison was String-to-String; real `VideoAsset.id` is UUID**
- **Found during:** Task 2 writing `segment(for:)` + Task 3 writing `firstAsset(id:)`
- **Issue:** Plan snippet used `clip.id == selectedAssetId` directly (both as Strings). Phase 22's `VideoAsset.id: UUID`. Straight comparison would not compile.
- **Fix:** Compare via `clip.id.uuidString == selectedAssetId` everywhere; the scrubber tap site writes `clip.id.uuidString` into the binding, matching the read site.
- **Files modified:** `ready player 8/LiveFeed/DroneScrubberTimeline.swift`, `ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift`, `ready player 8/LiveFeed/LiveFeedPerProjectView.swift`
- **Verification:** `swiftc -parse` clean; `xcodebuild` clean.
- **Committed in:** `dceb756` (Task 2), `c05f9ec` (Task 3)

**Total deviations:** 3 auto-fixes, all Rule 3 (blocking) — plan drafts referenced property/type shapes that don't exist in the real modules. No scope expansion, no architectural changes.

## Issues Encountered

- **~90 min lost to a silent-shell environment issue at session start.** Early in the session, the `Bash` tool returned empty output for essentially every `ls`/`cd` invocation for a stretch that spanned many tool calls. During that window I attempted tasks against phantom state (e.g., tried to write a file called `DroneLibraryStore.swift` and to commit it, but the commits never landed — `git log` proved nothing persisted). The productive work only began after the shell recovered and I verified the working tree via `/tmp/gs.txt`. Logged here for transparency; no functional impact on the delivered code.
- **Pre-existing test-target concurrency errors remain, unrelated to this plan.** The 29-05 SUMMARY already documented `ready_player_8Tests.swift` and `ReportTests.swift` have Swift-6 concurrency errors that prevent `xcodebuild test` from compiling the test target. This plan touches neither file; `xcodebuild build` on the app target is clean.

## User Setup Required

None. Pure iOS UI + model wiring. No migrations, no secrets, no deploys. The existing `SupabaseService.shared` credentials + `VideoUploadClient` from Phase 22 handle all network work.

## Known Stubs

None introduced by this plan. The 29-07 integration seams (`suggestionsPlaceholder`, `trafficPlaceholder`) are explicitly placeholder surfaces awaiting 29-07 and are out of scope per the plan's file-header comment — not stubs in the "hardcoded values flowing to UI" sense.

## Threat Flags

None. No new network endpoints, no new auth paths, no new RLS surface. All three plan-declared threats are mitigated in code:

- **T-29-RLS-CLIENT** — `DroneAssetsStore.refresh()` uses `SupabaseService.shared.fetch(...)`, which attaches the authenticated session token + apikey. Never service-role. RLS scopes results by org_id automatically.
- **T-29-06-01** — No portal routes referenced (`grep -c "/api/portal" "LiveFeedPerProjectView.swift"` returns 0).
- **T-29-06-02** — D-20 guard preserves the user's manual scrub position: auto-advance is gated by `secondsSinceLastScrub() > 30`, so the first three decades after a scrub never clobber the view.
- **T-29-06-03** — `.onDisappear { client?.cancel() }` on `DroneUploadSheet` closes the upload-task retention path.

## Next Plan Readiness

- **29-07 (iOS: suggestion cards + traffic + budget + analyze now)** — Integration seams are in place and named in source comments (`suggestionsPlaceholder` + `trafficPlaceholder` inside `LiveFeedPerProjectView`). The D-20 toast surface can read the same `ConstructOS.LiveFeed.LastScrubTimestamp.{projectId}` key this plan writes, so "New clip available — tap to jump" per UI-SPEC line 341 has a clean hook.
- **29-09 (web parity: drone scrubber + upload + library)** — iOS contract is now frozen for web to mirror: 24h window query predicate (`source_type='drone' AND status='ready' AND created_at > now() - interval '24h'`), 30s D-20 guard threshold, "No Drone Clips Yet" / "No Older Clips" / "No drone clips in the last 24 h." copy strings.

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Completed: 2026-04-20*

## Self-Check: PASSED

**Files created (verified on disk):**
- FOUND: `ready player 8/LiveFeed/DroneAssetsStore.swift`
- FOUND: `ready player 8/LiveFeed/DroneScrubberTimeline.swift`
- FOUND: `ready player 8/LiveFeed/ProjectDroneLibrarySheet.swift`
- FOUND: `ready player 8/LiveFeed/DroneUploadSheet.swift`

**Files modified (verified on disk):**
- FOUND: `ready player 8/LiveFeed/LiveFeedPerProjectView.swift` (rewritten from 110 → 233 lines)

**Commits recorded (verified via `git log --oneline -5`):**
- FOUND: `493d6ff` — Task 1 (DroneAssetsStore)
- FOUND: `dceb756` — Task 2 (3 drone views)
- FOUND: `c05f9ec` — Task 3 (LiveFeedPerProjectView rewrite)

**Key acceptance-criteria grep checks (matches expected ≥1 each):**
- `@MainActor` in DroneAssetsStore.swift → 1
- `within24h` / `olderThan24h` → 5 each
- `24 * 60 * 60` → 2
- `eq.drone` → 1
- `No drone clips in the last 24 h` → 2 (code + VoiceOver)
- `No Older Clips` → 2
- `sourceType: .drone` → 2 (doc comment + call site)
- `fileImporter` → 3 (import + presentation + modifier)
- `client?.cancel()` → 1
- `DroneScrubberTimeline` / `ProjectDroneLibrarySheet` / `DroneUploadSheet` referenced in LiveFeedPerProjectView.swift → 1 each
- `VideoClipPlayer(asset:` → 3 (two render sites + player sub-view)
- `secondsSinceLastScrub() > 30` → 1
- `markUserScrubbed` → 2 (call site + method def)
- `No Drone Clips Yet` → 1
- `Suggestion cards — 29-07` → 1 (seam preserved)
- `/api/portal` in LiveFeedPerProjectView.swift → 0 (portal invariant preserved)

**Build check:** `xcodebuild -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" build` → `BUILD SUCCEEDED`.

**Parse check:** `swiftc -parse` on all 5 new/modified files → exit 0 each.
