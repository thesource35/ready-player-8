---
phase: 23-ios-nav-assignment-wiring
plan: 01
subsystem: ios-ui
tags: [swift, swiftui, picker, dailycrew, team-05, supabase]
dependency-graph:
  requires:
    - quick-task: 260414-n4w (NavTab wiring, upsert helper, AgendaListView — commit 44a7dd3)
    - phase: 15-team-crew-management (DailyCrewView base implementation)
  provides:
    - Production-usable project picker on DailyCrewView
    - DailyCrewView() zero-arg initializer (internal projectId state)
    - Persisted last-picked project via @AppStorage
  affects:
    - ready player 8/DailyCrewView.swift (picker + state + loader added; projectId param removed)
    - ready player 8/ContentView.swift:744 (call-site converted to zero-arg)
tech-stack:
  added: []
  patterns:
    - Hybrid Supabase/mock fallback (mirrors ProjectsView.swift:6-18)
    - Menu picker styling (mirrors ContractsView.swift:389 / ProjectsView.swift:450)
    - @AppStorage persistence under ConstructOS.{Feature}.{Property} namespace
key-files:
  created: []
  modified:
    - ready player 8/DailyCrewView.swift
    - ready player 8/ContentView.swift
decisions:
  - Used SupabaseService.shared directly (not @EnvironmentObject) to match the
    pattern already in ProjectsView.swift:15 — keeps DailyCrewView instantiable
    zero-arg from anywhere in the router without requiring env-object plumbing.
  - Auto-select first displayProjects entry when selectedProjectId is empty, so
    a first-time user sees a populated picker and can save immediately.
  - Compared SupabaseProject.id (String?) directly against selectedProjectId
    instead of UUID.uuidString conversion — SupabaseProject.id is already a
    String in SupabaseService.swift:1152, not a UUID.
  - Batched T-23-01-01 through T-23-01-05 into a single atomic commit because
    removing the projectId parameter breaks the ContentView call-site at
    compile time. Splitting them would yield a broken-build intermediate
    commit.
requirements-addressed: [TEAM-05]
metrics:
  duration-seconds: 137
  tasks-completed: 6
  files-modified: 2
  commits: 1
  completed-date: 2026-04-14
---

# Phase 23 Plan 01: DailyCrewView Project Picker Summary

Replaced the hardcoded `mockProjects.first?.id.uuidString` projectId stub with an in-view Menu picker. `DailyCrewView` now owns its own project selection via `@AppStorage("ConstructOS.Team.LastDailyCrewProjectId")`, is instantiated zero-arg (`DailyCrewView()`), hybridly loads `SupabaseProject` data from either the live Supabase backend or the shared `mockSupabaseProjects` fallback, and renders a clear empty-state CTA if no projects exist — satisfying TEAM-05 end-to-end.

## Commits

| Hash     | Type | Message                                             |
| -------- | ---- | --------------------------------------------------- |
| 6969ac0  | feat | feat(23-01): DailyCrewView project picker (TEAM-05) |

## Tasks Executed

| Task          | Status | Notes                                                                       |
| ------------- | ------ | --------------------------------------------------------------------------- |
| T-23-01-01    | ✅     | Added `projects` state, `selectedProjectId` @AppStorage, `supabase` ref, `displayProjects`, `selectedProject`, `loadProjects()` and extended `.task` modifier |
| T-23-01-02    | ✅     | Removed `let projectId: String`; all `save()` / `loadCrew()` references rewritten to use `selectedProjectId` |
| T-23-01-03    | ✅     | Added `projectPicker` computed sub-view (Menu) above DatePicker             |
| T-23-01-04    | ✅     | Empty-projects gate wraps the DatePicker/member list with CTA to Projects tab; also disables Save button when `selectedProjectId.isEmpty` for defensive safety |
| T-23-01-05    | ✅     | ContentView.swift:744 changed to `DailyCrewView()`; stale TODO comment removed |
| T-23-01-06    | ✅     | `xcodebuild -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build` → `** BUILD SUCCEEDED **` |

## Verification

All four plan-specified grep assertions pass:

```
# check 1: no projectId param/variable in DailyCrewView (only comments)
$ grep -n "projectId" "ready player 8/DailyCrewView.swift" | grep -v "selectedProjectId\|project_id"
5:// quick task 260414-n4w. projectId is now internal state (AppStorage-backed)
16:    // Phase 23-01: projectId becomes internal; persists last selection across launches.
43:            // Phase 23-01: Project picker (replaces parameterized projectId).
# (3 matches — all comments documenting the change, zero functional references)

# check 2: zero-arg call-site
$ grep -n "DailyCrewView(" "ready player 8/ContentView.swift"
744:        case .dailyCrew: DailyCrewView()

# check 3: Menu present
$ grep -n "Menu {" "ready player 8/DailyCrewView.swift"
140:        Menu {

# check 4: AppStorage key present
$ grep -n "ConstructOS.Team.LastDailyCrewProjectId" "ready player 8/DailyCrewView.swift"
17:    @AppStorage("ConstructOS.Team.LastDailyCrewProjectId") private var selectedProjectId: String = ""
```

Build verification:
- Simulator: `iPhone 17 Pro` (iOS 26.2 SDK)
- Result: `** BUILD SUCCEEDED **`
- No warnings about unused `projectId`, unresolved `mockSupabaseProjects`, or incompatible `SupabaseService.fetch` signatures

## Decisions Made

1. **SupabaseService injection pattern** — Used `private let supabase = SupabaseService.shared` (mirroring `ProjectsView.swift:15`) instead of `@EnvironmentObject` or `@StateObject`. Rationale: keeps `DailyCrewView()` instantiation side-effect-free and matches the dominant pattern in the codebase; env-object plumbing is reserved for the root `ContentView`.

2. **ID comparison style** — `SupabaseProject.id` is declared `var id: String?` in `SupabaseService.swift:1152`, so comparisons use `$0.id == selectedProjectId` directly. The plan's example used `$0.id.uuidString == …`, which would have been a type error — noted and corrected during implementation (no deviation, just plan-text inaccuracy that the implementation resolved correctly).

3. **Supabase fetch arguments** — The plan suggested `query: "order=created_at.desc"` as a raw string. The actual `SupabaseService.fetch` signature (SupabaseService.swift:639) takes structured params: `query: [String: String]`, `orderBy: String?`, `ascending: Bool`. Implementation uses `orderBy: "created_at", ascending: false`.

4. **Atomic commit vs. split commits** — Plan lists T-23-01-02 (remove param) and T-23-01-05 (update call-site) as separate tasks, but T-23-01-02 in isolation yields a broken build. Batched all six tasks into one commit per the executor's own critical-notes guidance ("preserve compilability between commits").

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `SupabaseProject.id` is `String?`, not UUID**

- **Found during:** T-23-01-01 (adding `selectedProject` computed property)
- **Issue:** Plan's example code used `$0.id.uuidString == selectedProjectId`, but `SupabaseProject.id` is `var id: String?` (SupabaseService.swift:1152). `.uuidString` would be a type error.
- **Fix:** Compared `$0.id == selectedProjectId` directly.
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** 6969ac0

**2. [Rule 3 - Blocking] `SupabaseService.fetch` signature mismatch**

- **Found during:** T-23-01-01 (implementing `loadProjects()`)
- **Issue:** Plan's example used `try await supabase.fetch("cs_projects", query: "order=created_at.desc")` as a single-string query. Actual signature takes `query: [String: String]`, `orderBy: String?`, `ascending: Bool`.
- **Fix:** Called `supabase.fetch("cs_projects", orderBy: "created_at", ascending: false)` using the real API.
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** 6969ac0

**3. [Rule 2 - Correctness] Save button guard for empty selection**

- **Found during:** T-23-01-04 (empty-state handling)
- **Issue:** Plan only gated the members/date UI with `displayProjects.isEmpty`. But a user could theoretically hit Save while `selectedProjectId` is empty (e.g., before `.task` finishes, or if mock fallback is also empty). Saving with an empty `project_id` would POST invalid data to Supabase.
- **Fix:** Added `.disabled(saving || selectedProjectId.isEmpty)` on the Save button and early-return guard in `save()` with user-visible toast "Pick a project first."
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** 6969ac0

**4. [Rule 3 - Blocking] Task ordering in `.task` modifier**

- **Found during:** T-23-01-01 (plan step 5)
- **Issue:** Plan asked for `.task { await loadProjects(); if selectedProjectId.isEmpty { selectedProjectId = displayProjects.first?.id.uuidString ?? "" }; await loadCrew() }` but (a) `loadMembers()` was not re-wired (original view called it in its `.task`) and (b) `.first?.id.uuidString` is a type error because id is already a `String?`.
- **Fix:** Extended the `.task` block to: `await loadProjects()` → auto-select default → `await loadMembers()` → `await loadCrew()`. Used `.first?.id` (String?) directly.
- **Files modified:** ready player 8/DailyCrewView.swift
- **Commit:** 6969ac0

### Authentication Gates

None. No auth flow touched.

## Known Stubs

None. The `mockSupabaseProjects` fallback is intentional — it's the existing app-wide offline-fallback pattern used by `ProjectsView.swift:18`. The same data backs the Projects dashboard; if a user sees demo projects there, they see the same in the DailyCrew picker (expected behavior, not a stub).

## Threat Flags

No new threat surface introduced. `DailyCrewView.save()` continues to use the existing `SupabaseService.upsert` with the same `(project_id, assignment_date)` natural key and auth path — the picker simply chooses which `project_id` to write.

## Self-Check: PASSED

- ✅ File exists: `/Users/beverlyhunter/Desktop/ready player 8/ready player 8/DailyCrewView.swift`
- ✅ File exists: `/Users/beverlyhunter/Desktop/ready player 8/ready player 8/ContentView.swift`
- ✅ Commit exists: `6969ac0 feat(23-01): DailyCrewView project picker (TEAM-05)`
- ✅ Build succeeded: `** BUILD SUCCEEDED **` (iPhone 17 Pro simulator, iOS 26.2 SDK)
- ✅ All four plan grep assertions pass
