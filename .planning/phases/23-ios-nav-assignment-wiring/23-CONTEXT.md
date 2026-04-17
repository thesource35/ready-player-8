# Phase 23: iOS Navigation & Assignment Wiring — Context

**Gathered:** 2026-04-17 (updated — full re-discussion)
**Status:** Ready for planning
**Source:** Gap-closure phase (v2.1 milestone); scope derived from v2.0 audit + quick task 260414-n4w closure

<domain>

## Phase Boundary

**Goal (from ROADMAP.md):** Existing iOS views (TeamView, CertificationsView, DailyCrewView, AgendaListView) are reachable from user navigation; daily crew edits do not 409.

**Requirements:** TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03
**Gap Closure:** Closes INT-03, INT-04, INT-05 · FLOW-03, FLOW-04, FLOW-05

**What this phase delivers:**
1. A production-usable project picker on DailyCrewView (replacing the current `mockProjects.first` stub wired by quick task 260414-n4w)
2. Cross-navigation links between ProjectDetail→DailyCrew and AgendaListView→DailyCrew
3. A goal-backward VERIFICATION.md that proves all 5 ROADMAP success criteria with code/grep evidence, device checklist, and screenshot requirements
4. Accessibility: VoiceOver labels on picker and save, state announcements

**What's already done (out of scope for this phase):**
- NavTab wiring for `.team`, `.certifications`, `.dailyCrew` — closed by `44a7dd3` / 260414-n4w
- `SupabaseService.upsert(_:record:onConflict:)` helper — added in `44a7dd3`
- `DailyCrewView.save()` insert → upsert switch — completed in `44a7dd3`
- `ScheduleHubView` Agenda tab rendering `AgendaListView` — completed in `44a7dd3`
- `cs_daily_crew` UNIQUE(project_id, assignment_date) — already exists as a UNIQUE INDEX in `supabase/migrations/20260408002_phase15_team.sql:66`

</domain>

<decisions>

## Implementation Decisions

### Project Picker (D-01 through D-06)

- **D-01: Placement & style.** Inline at the top of `DailyCrewView`, above the date picker. Renders as a searchable `Picker` with `.searchable` modifier for larger project lists. Each row shows: project name, status badge (colored dot), and last crew assignment date.
- **D-02: Data source.** Joined Supabase query — fetch `cs_projects` joined with latest `cs_daily_crew.assignment_date` per project. Falls back to `mockSupabaseProjects` when `supabase.isConfigured` is false or projects array is empty.
- **D-03: Selection state.** `@AppStorage("ConstructOS.Team.LastDailyCrewProjectId")` persists last selection across launches. Stale project ID fallback: Claude's discretion (auto-select first available, optionally with toast).
- **D-04: Empty state.** When zero projects exist, show "No projects yet — create one in the Projects tab first." matching the existing `members.isEmpty` pattern.
- **D-05: Unsaved changes guard.** When switching projects, show confirmation alert if crew list has been modified but not saved. Prevents accidental data loss.
- **D-06: Auto-save on date change.** When user changes the date picker, auto-save current crew assignments before loading the new date's crew. Prevents data loss during date navigation.

### NavTab Routing (D-07 through D-11)

- **D-07: Tab grouping.** Team/Certifications/DailyCrew tabs remain in the `intel` navigation group. No group restructuring.
- **D-08: Tab labels & icons.** Keep current: TEAM (person.3.fill), CERTS (checkmark.seal.fill), DAILY CREW (person.badge.clock). No changes.
- **D-09: Badge placeholders.** Add `.badge(0)` modifier on the CERTS tab as a placeholder hook. Phase 25 (Certification Expiry Notifications) will set the real count.
- **D-10: Deep-linking.** Basic deep-link: set `selectedTab = .team` when a team-related notification is tapped. Full deep-linking infrastructure belongs to Phase 14.
- **D-11: Call-site.** `ContentView.swift:744` uses zero-arg `DailyCrewView()`. Signature is a deliberate breaking change — `DailyCrewView` has one call-site.

### Cross-Navigation (D-12 through D-14)

- **D-12: ProjectDetail → DailyCrew.** Tapping "View Crew" from ProjectDetail auto-selects that project in DailyCrewView. Context passed via AppStorage relay (write project ID before switching tabs). Claude's discretion on exact mechanism.
- **D-13: AgendaListView → DailyCrew.** "View Crew" button on each day row in AgendaListView. Switches active tab to `.dailyCrew` with the selected date pre-set via AppStorage.
- **D-14: Tab switching mechanism.** Use existing `selectedTab` binding to switch tabs programmatically. No NavigationStack refactor needed.

### Upsert Conflict Handling (D-15 through D-18)

- **D-15: Concurrency model.** Last-write-wins via PostgREST merge-duplicates. Simple, matches existing patterns. Daily crew rarely has concurrent editors.
- **D-16: Save feedback.** Toast message: "Crew saved for [date]". Matches existing save patterns in ProjectsView and ContractsView.
- **D-17: Error handling.** AppError toast with actionable message. If `error.isRetryable`, show Retry button. Follows v1.0 error handling patterns.
- **D-18: Double-tap prevention.** Disable save button + show ProgressView spinner while `saving == true`. Re-enable on completion.

### Offline Behavior (D-19)

- **D-19: Offline fallback.** Mock data fallback — show `mockSupabaseProjects` + mock crew members when Supabase unreachable. Matches existing pattern across the app. Edits against mock data are not persisted.

### Accessibility (D-20 through D-21)

- **D-20: Picker VoiceOver.** Standard labels — `accessibilityLabel` on Menu: "Select project, currently [project name]". Each row reads name + status.
- **D-21: Save state announcements.** `.accessibilityValue` announces saving/saved/failed states on the Save button. Matches v1.0 accessibility patterns (182+ VoiceOver labels).

### Verification (D-22 through D-24)

- **D-22: Verification format.** Follow Phase 18 VERIFICATION.md format: Observable Truths table + Required Artifacts table + Key Link Verification. Additionally includes device checklist and screenshot evidence requirements.
- **D-23: Re-verification.** Re-verify all 5 truths against the latest codebase. Set `re_verification: true` since original verification was 2026-04-14.
- **D-24: Test strategy.** XCTest regression tests deferred to Phase 28 (Retroactive Verification Sweep). VERIFICATION.md proves ROADMAP criteria; new decisions tracked via CONTEXT.md and UAT.

### Claude's Discretion

- Exact button/picker styling (use `Theme.accent`, match ContractsView/ProjectsView patterns)
- Whether to auto-select the first project if none persisted (recommend: yes)
- Layout spacing within DailyCrewView header
- Exact mechanism for AppStorage relay in cross-navigation (D-12, D-13)
- Searchable picker implementation details (`.searchable` vs `Picker` with search)
- Stale project ID fallback behavior (auto-select first, with or without toast)

</decisions>

<canonical_refs>

## Canonical References

Downstream agents MUST read these before implementing.

### Code patterns to mirror

- `ready player 8/ProjectsView.swift:6-18` — Hybrid mock/Supabase project loading pattern
- `ready player 8/ProjectsView.swift:450` — Menu picker pattern
- `ready player 8/ContractsView.swift:389` — Alternative Menu pattern
- `ready player 8/DailyCrewView.swift` — current state after 260414-n4w; lines 1-5 show Phase 15 MARK; `save()` uses upsert
- `ready player 8/ContentView.swift:558-560` — NavTab cases for team/certifications/dailyCrew
- `ready player 8/ContentView.swift:740-744` — Switch arms rendering the 3 views
- `ready player 8/ScheduleTools.swift:506,533` — AgendaListView rendering in ScheduleHubView

### Data contracts

- `supabase/migrations/20260408002_phase15_team.sql:56-67` — `cs_daily_crew` schema with unique index
- `ready player 8/SupabaseService.swift::upsert` (~line 711) — generic upsert helper introduced by 260414-n4w

### Prior work to cite in VERIFICATION.md

- `.planning/quick/260414-n4w-fix-4-v2-0-audit-integration-blockers-wi/260414-n4w-SUMMARY.md` — complete list of grep assertions proving INT-03/04/05 closure
- `44a7dd3` commit — NavTab + upsert + AgendaListView wiring

### Requirements traceability

- `.planning/REQUIREMENTS.md` (v2.1) — TEAM-01/02/03/05, CAL-03 status
- `.planning/milestones/v2.0-MILESTONE-AUDIT.md` — original gap evidence (INT-03/04/05, FLOW-03/04/05)

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets
- `SupabaseService.upsert()` — generic upsert with `onConflict` param, ready to use
- `mockSupabaseProjects` — defined in ProjectsView.swift scope, used for offline fallback
- `Theme` struct — full color system for consistent picker styling
- `AppError` enum — `.network()`, `.supabaseHTTP()` for error toasts
- `AnalyticsEngine.shared` — VoiceOver announcement pattern from v1.0

### Established Patterns
- Hybrid data loading: `supabase.isConfigured ? realData : mockData` — used in every data view
- `@AppStorage` for persisting UI state across launches — convention: `ConstructOS.{Feature}.{Property}`
- Toast-based save feedback — consistent across ProjectsView and ContractsView
- `Menu`-style pickers for entity selection — ContractsView and ProjectsView

### Integration Points
- `ContentView.swift:744` — sole call-site for DailyCrewView (zero-arg)
- `ContentView.swift:593-595` — navItems registration for 3 team tabs in intel group
- `ScheduleTools.swift:533` — AgendaListView rendered at tab index 1
- `selectedTab` binding in ContentView — used for programmatic tab switching

</code_context>

<specifics>

## Specific Ideas

- Project picker rows should show **name + status badge + last crew date** — richer than a plain name list
- Searchable picker for scaling to larger project lists (10+)
- Auto-save on date change but warn-and-confirm on project switch — natural asymmetry (date browsing is lightweight, project switching is heavy)
- "View Crew" link from AgendaListView switches to DailyCrew tab (not sheet/push) — stays consistent with flat tab navigation

</specifics>

<deferred>

## Deferred Ideas

- **User-configurable tab order** — drag-to-reorder across all 13+ tabs. New capability, belongs in its own phase (UX polish).
- **Offline queue + sync for crew edits** — flagged as out-of-scope in PROJECT.md ("Offline queue / local-first architecture — future project"). Mock fallback for now.
- **Project creation from picker** — if no projects exist, inline creation is UX polish, out of scope.
- **Cross-project daily crew copying** — "copy yesterday's crew from another project" — defer as Phase 15.x or v2.2 feature.
- **Certification expiry notifications** — TEAM-04, handled by Phase 25.
- **iOS XCTest coverage** for NavTab routing, upsert, agenda rendering — deferred to Phase 28.

</deferred>

---

*Phase: 23-ios-nav-assignment-wiring*
*Context gathered: 2026-04-17 — full re-discussion (7 areas, 21 decisions)*
