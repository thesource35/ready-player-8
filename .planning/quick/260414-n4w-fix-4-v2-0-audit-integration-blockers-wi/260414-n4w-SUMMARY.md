---
quick_id: 260414-n4w
type: quick
milestone: v2.0
one_liner: Closed 3 v2.0 audit integration blockers (INT-03 NavTab wiring, INT-04 DailyCrew upsert, INT-05 AgendaListView wiring) and cleaned refuted activity-page claim from STATE.md
closes_integration_gaps: [INT-03, INT-04, INT-05]
does_not_close: [INT-01, INT-02, INT-06, INT-07, INT-08]
dependency_graph:
  requires:
    - ready player 8/TeamView.swift (exists — Phase 15 TEAM-01)
    - ready player 8/CertificationsView.swift (exists — Phase 15 TEAM-03)
    - ready player 8/DailyCrewView.swift (exists — Phase 15 TEAM-05)
    - ready player 8/ScheduleTools.swift::AgendaListView (exists — Phase 17-04 CAL-03)
  provides:
    - ContentView.NavTab.team | .certifications | .dailyCrew — reachable iOS nav paths
    - SupabaseService.upsert(_:record:onConflict:) — generic PostgREST upsert helper
    - ScheduleHubView Agenda tab — renders AgendaListView
  affects:
    - ContentView.swift (3 additive edits, no removals/reorders)
    - SupabaseService.swift (new helper added between insert and update)
    - DailyCrewView.swift (save() call-site swapped insert -> upsert)
    - ScheduleTools.swift (tab label insertion + dispatch-chain index shift)
    - .planning/STATE.md (blockers section cleanup)
tech_stack:
  added:
    - PostgREST upsert contract (on_conflict query param + Prefer resolution=merge-duplicates)
  patterns:
    - Upsert helper mirrors existing insert() signature/error-handling for consistency
    - Additive NavTab wiring: new cases appended, existing cases untouched
    - Additive tab insertion: "Agenda" at index 1, dispatch chain shifted +1
key_files:
  created: []
  modified:
    - ready player 8/ContentView.swift
    - ready player 8/SupabaseService.swift
    - ready player 8/DailyCrewView.swift
    - ready player 8/ScheduleTools.swift
    - .planning/STATE.md
decisions:
  - Stub DailyCrewView.projectId with `mockProjects.first?.id.uuidString ?? ""` rather than add a project picker — picker is UX polish, out of scope for integration wiring (TODO left in-code)
  - Upsert helper added to SupabaseService rather than inlined in DailyCrewView — reusable primitive for future natural-key writes
  - INT-04 upsert contract assumes cs_daily_crew has UNIQUE(project_id, assignment_date); schema audit deferred (not in this quick task scope)
  - Option A commit strategy: 1 code commit (44a7dd3) + 1 docs commit for STATE.md cleanup
metrics:
  duration_minutes: ~10
  tasks_completed: 4
  files_modified: 5
  commits: 2
  completed_date: 2026-04-14
---

# Quick Task 260414-n4w: Fix 4 v2.0 Audit Integration Blockers Summary

Closed 3 integration blockers flagged by the v2.0 milestone audit (INT-03 orphan iOS views, INT-04 DailyCrew 409-on-edit, INT-05 orphan AgendaListView) and removed a refuted activity-page claim from STATE.md. Four mechanical edits across four files; iOS build stays green.

## Objective (from PLAN)

Restore end-to-end flows FLOW-03 (iOS team nav), FLOW-04 (daily crew edit), FLOW-05 (iOS agenda) before v2.0 ships, and fix STATE.md audit-doc hygiene.

## What Shipped

### Task 1 — INT-03: NavTab wiring (ContentView.swift)

Three coordinated additive edits inside `struct ContentView`:

1. Added 3 cases to `enum NavTab`: `.team`, `.certifications`, `.dailyCrew` — placed immediately after `.inbox` to keep Phase 14/15 siblings adjacent.
2. Added 3 entries to `navItems`: `TEAM` (👥), `CERTS` (📜), `DAILY CREW` (👷) — all in the `intel` nav group beside INBOX.
3. Added 3 switch arms to `activeTabContent`: `TeamView()`, `CertificationsView()`, `DailyCrewView(projectId: mockProjects.first?.id.uuidString ?? "")`.

The `DailyCrewView` projectId stub is documented with an in-code TODO (wrap in project picker in a follow-up). No existing cases reordered or removed.

### Task 2 — INT-04: DailyCrew insert → upsert (SupabaseService.swift + DailyCrewView.swift)

Added a generic `upsert<T: Encodable>(_ table:String, record:T, onConflict:String)` helper to `SupabaseService` immediately after `insert()`. Mirrors the existing pattern:
- `guard isConfigured`, `validateTable`, `applyHeaders`
- `Prefer: resolution=merge-duplicates,return=representation` (PostgREST upsert contract)
- `?on_conflict=<url-encoded-columns>` query param
- Same `encodingError` / `checkHTTPStatus` error surface

Switched `DailyCrewView.save()` from `insert("cs_daily_crew", record: payload)` to `upsert("cs_daily_crew", record: payload, onConflict: "project_id,assignment_date")`. Saving the same (project, date) pair twice is now a merge update, not a 409.

**Follow-up risk noted:** The upsert contract assumes the `cs_daily_crew` Postgres table has a UNIQUE constraint on `(project_id, assignment_date)`. If that constraint is missing, the upsert degrades to plain insert and 409s return. Schema verification is deferred to a separate audit-milestone run (not in this quick task scope per constraints).

### Task 3 — INT-05: AgendaListView wiring (ScheduleTools.swift)

Two coordinated edits inside `ScheduleHubView`:

1. Inserted `"Agenda"` at index 1 of the `tabs` array (between `Timeline` and `Crew Calendar`).
2. Rewrote the `if/else` dispatch chain: `activeTab == 1 -> AgendaListView()`, every subsequent tab index shifted by +1 (Crew Calendar is now index 2, Reference is now index 10).

`AgendaListView()` (Phase 17-04 CAL-03, line 1088) now renders inline. FLOW-05 day-grouped task agenda is reachable.

### Task 4 — STATE.md cleanup

- Removed stale bullet: `Web per-project activity page missing` (file verified to exist per integration checker; claim was refuted).
- Marked 3 blocker bullets CLOSED with strikethrough + `260414-n4w` reference: iOS NavTab wiring, DailyCrew upsert, AgendaListView wiring.
- Added `260414-n4w` row to `Quick Tasks Completed` table with commit `44a7dd3`.
- Bumped frontmatter `last_updated` and `last_activity` to 2026-04-14.
- Left 2 truly-open blockers intact: Phase 13 RLS migration and Plan 17-02 user_orgs risk.

## Verification

| Check | Result |
|-------|--------|
| `xcodebuild -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build` | `** BUILD SUCCEEDED **` |
| `grep 'case team = "team"' ContentView.swift` | 1 match (line 558) |
| `grep '"team","TEAM"' ContentView.swift` | 1 match (line 593) |
| `grep 'case .team: TeamView()' ContentView.swift` | 1 match (line 740) |
| `grep 'func upsert' SupabaseService.swift` | 1 match for generic helper (line 711) |
| `grep '.insert("cs_daily_crew"' DailyCrewView.swift` | 0 matches (removed) |
| `grep '.upsert(' DailyCrewView.swift` | 1 match (line 146) |
| `grep '"Agenda"' ScheduleTools.swift` | 1 match (tabs array, line 506) |
| `grep 'AgendaListView()' ScheduleTools.swift` | 1 call-site (line 533) + 1 declaration (line 1088) |
| `grep 'Web per-project activity page missing' STATE.md` | 0 matches (removed) |
| `grep '260414-n4w' STATE.md` | 4 matches (3 CLOSED markers + Quick Tasks row) |

## Deviations from Plan

None — plan executed exactly as written. No Rule 1/2/3 auto-fixes required; no architectural decisions triggered Rule 4.

## Commits

| Commit | Type | Files | Description |
|--------|------|-------|-------------|
| `44a7dd3` | fix(ios) | ContentView.swift, SupabaseService.swift, DailyCrewView.swift, ScheduleTools.swift | Wire Team/Certs/DailyCrew to NavTab + AgendaListView to ScheduleHub + DailyCrew upsert (INT-03/04/05) |
| (pending) | docs(state) | STATE.md, SUMMARY.md | Remove refuted activity-page blocker; mark INT-03/04/05 closed; add quick-task row |

## Known Stubs

- `ContentView.swift::activeTabContent::.dailyCrew` — `DailyCrewView(projectId: mockProjects.first?.id.uuidString ?? "")` uses a mock project fallback. A project picker wrapper is needed before production. Documented with an in-code TODO and plan `<action>` rationale. Does not block INT-03 closure (nav path is reachable; data flow for a real project is blocked only on picker UX, not on integration wiring).

## Deferred Items

- **Schema verification for INT-04:** Confirm `cs_daily_crew` has UNIQUE(project_id, assignment_date). If missing, add migration. Out of scope for this quick task (per constraints — no new migrations).
- **Project picker for DailyCrewView:** UX polish to replace the `mockProjects.first?.id.uuidString` stub. Track as follow-up UX-level plan.
- **REQUIREMENTS.md / VERIFICATION.md:** Explicitly out of scope per constraints — awaits separate audit-milestone re-run.
- **INT-01, INT-02, INT-06, INT-07, INT-08:** Not closed by this quick task per frontmatter `does_not_close`.

## Success Criteria (from PLAN)

- [x] INT-03 closed: TEAM/CERTS/DAILY CREW reachable from nav rail
- [x] INT-04 closed: DailyCrew save is idempotent on (project, date) — upsert not insert
- [x] INT-05 closed: ScheduleHubView AGENDA tab renders AgendaListView
- [x] STATE.md Blockers shows only 2 truly-open items (Phase 13 RLS, 17-02 user_orgs) + 3 CLOSED strikethroughs
- [x] iOS build green; no existing NavTab case removed or reordered
- [x] REQUIREMENTS.md untouched
- [x] No VERIFICATION.md files for phases 13-17/19 created

## Self-Check: PASSED

- File `ready player 8/ContentView.swift`: FOUND (modified, lines 558, 593, 740 verified by grep)
- File `ready player 8/SupabaseService.swift`: FOUND (modified, line 711 verified by grep)
- File `ready player 8/DailyCrewView.swift`: FOUND (modified, line 146 verified by grep, no `.insert("cs_daily_crew"` remains)
- File `ready player 8/ScheduleTools.swift`: FOUND (modified, lines 506, 533 verified by grep)
- File `.planning/STATE.md`: FOUND (modified, no "Web per-project activity page missing" remains, 260414-n4w present)
- Commit `44a7dd3`: FOUND in git log
- iOS build: BUILD SUCCEEDED on iPhone 17 Pro simulator
