# Phase 23: iOS Navigation & Assignment Wiring — Context

**Gathered:** 2026-04-14
**Status:** Ready for planning
**Source:** Gap-closure phase (v2.1 milestone); scope derived from v2.0 audit + quick task 260414-n4w closure

<domain>

## Phase Boundary

**Goal (from ROADMAP.md):** Existing iOS views (TeamView, CertificationsView, DailyCrewView, AgendaListView) are reachable from user navigation; daily crew edits do not 409.

**Requirements:** TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03
**Gap Closure:** Closes INT-03, INT-04, INT-05 · FLOW-03, FLOW-04, FLOW-05

**What this phase delivers:**
1. A production-usable project picker on DailyCrewView (replacing the current `mockProjects.first` stub wired by quick task 260414-n4w)
2. A goal-backward VERIFICATION.md that proves all 5 ROADMAP success criteria hold with concrete code/grep evidence

**What's already done (out of scope for this phase):**
- NavTab wiring for `.team`, `.certifications`, `.dailyCrew` — closed by `44a7dd3` / 260414-n4w
- `SupabaseService.upsert(_:record:onConflict:)` helper — added in `44a7dd3`
- `DailyCrewView.save()` insert → upsert switch — completed in `44a7dd3`
- `ScheduleHubView` Agenda tab rendering `AgendaListView` — completed in `44a7dd3`
- `cs_daily_crew` UNIQUE(project_id, assignment_date) — already exists as a UNIQUE INDEX in `supabase/migrations/20260408002_phase15_team.sql:66` (`cs_daily_crew_one_per_day`); PostgREST upsert merges correctly

</domain>

<decisions>

## Implementation Decisions

### Project Picker (Plan 23-01)

- **Placement:** Inline at the top of `DailyCrewView`, above the date picker. Renders as a `Menu`-style dropdown matching the pattern used in `ContractsView.swift:389` and `ProjectsView.swift:450`.
- **Data source:** `SupabaseProject` list — follow the hybrid pattern from `ProjectsView`: `supabase.isConfigured ? projects : mockSupabaseProjects`. Load via `@State private var projects: [SupabaseProject]` with `.task { await loadProjects() }`.
- **Selection state:** `@State private var selectedProjectId: String?` — when changed, triggers `await loadCrew()` to refresh the member list.
- **Empty state:** When zero projects exist (offline + no mock fallback), show "No projects yet — create one in the Projects tab first." in the same style as the existing `members.isEmpty` branch.
- **Call-site change:** `ContentView.swift:745` changes from `DailyCrewView(projectId: mockProjects.first?.id.uuidString ?? "")` to `DailyCrewView()` — the projectId becomes internal state. Signature change is a deliberate breaking change — `DailyCrewView` has one call-site.
- **Persist selection:** `@AppStorage("ConstructOS.Team.LastDailyCrewProjectId")` so reopening the tab restores the last picked project.

### VERIFICATION.md (Plan 23-02)

- **Structure:** Follow the Phase 18 VERIFICATION.md format (Observable Truths table + Required Artifacts table + Key Link Verification).
- **Status:** `passed` if all 5 truths verified code-only; `human_needed` if any truth requires simulator/device run.
- **Re-verification:** This is the first VERIFICATION.md for Phase 23, so `re_verification: false`.
- **Evidence discipline:** Every truth must cite file:line and grep output. No prose claims without code evidence.

### Claude's Discretion

- Exact button styling for the project picker (use `Theme.accent`, match ContractsView's Menu styling)
- Whether to auto-select the first project if none persisted (recommend: yes, matches ProjectsView default behavior)
- Layout spacing within DailyCrewView header

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before implementing.

### Code patterns to mirror

- `ready player 8/ProjectsView.swift:6-18` — Hybrid mock/Supabase project loading pattern
- `ready player 8/ProjectsView.swift:450` — Menu picker pattern
- `ready player 8/ContractsView.swift:389` — Alternative Menu pattern
- `ready player 8/DailyCrewView.swift` — current state after 260414-n4w; lines 1-5 show Phase 15 MARK; `save()` uses upsert

### Data contracts

- `supabase/migrations/20260408002_phase15_team.sql:56-67` — `cs_daily_crew` schema with unique index
- `ready player 8/SupabaseService.swift::upsert` (~line 711) — generic upsert helper introduced by 260414-n4w

### Prior work to cite in VERIFICATION.md

- `.planning/quick/260414-n4w-fix-4-v2-0-audit-integration-blockers-wi/260414-n4w-SUMMARY.md` — complete list of grep assertions proving INT-03/04/05 closure
- `44a7dd3` commit — NavTab + upsert + AgendaListView wiring

### Requirements traceability

- `.planning/REQUIREMENTS.md` (v2.1) — TEAM-01/02/03/05, CAL-03 status: Pending
- `.planning/milestones/v2.0-MILESTONE-AUDIT.md` — original gap evidence (INT-03/04/05, FLOW-03/04/05)

</canonical_refs>

<specifics>

## Specific Details

- **Call-site of DailyCrewView:** Only `ContentView.swift:745` — safe to change signature
- **Existing mock fallback:** `mockSupabaseProjects` is defined in ProjectsView.swift scope; reuse pattern
- **AppStorage key convention:** `ConstructOS.{Feature}.{Property}` per CLAUDE.md user memory
- **Tap target minimum:** 48pt per UI spec already followed in DailyCrewView:60

</specifics>

<deferred>

## Deferred to Later Phases

- **iOS XCTest coverage** for NavTab routing, upsert behavior, agenda rendering — deferred to Phase 28 (Retroactive Verification Sweep) or a dedicated tests phase
- **Project creation from picker** — if no projects exist, current design shows empty-state text. Inline project creation is UX polish, out of scope.
- **Cross-project daily crew copying** — user might want "copy yesterday's crew from another project" — defer as Phase 15.x or v2.2 feature
- **Certification expiry notifications** — TEAM-04, handled by separate Phase 25

</deferred>

---

*Phase: 23-ios-nav-assignment-wiring*
*Context gathered: 2026-04-14 — narrow gap-closure scope (2 plans)*
