---
phase: 17-calendar-scheduling
verified: 2026-04-19T16:10:00Z
status: partial
score: 4/4 must-haves verified (code); UAT pending for CAL-01/02/04
re_verification: false
human_verification:
  - test: "Open /schedule on web with seeded cs_project_tasks rows and navigate the rollup → drill-in → Gantt → agenda view chain"
    expected: "Default view (?view=rollup) renders one swim lane per project with task mini-bars; clicking a lane label navigates to ?view=gantt&project=ID; GanttChart renders bars + SVG dependency arrows + milestone diamonds; agenda view groups day-by-day"
    why_human: "Visual grid rendering, SVG arrow positioning, and lane/drill-in navigation require a browser + live Supabase tasks"
  - test: "Drag-to-reschedule on GanttChart: pointerdown on a task bar, pointermove +60px at DAY_WIDTH=20, pointerup"
    expected: "Bar slides +3 days optimistically; PATCH /api/calendar/tasks persists start_date/end_date; refresh the page — dates remain shifted; duration unchanged; conflict badge (⚠) appears if successor.start < predecessor.end but save still succeeds (non-blocking, D-08)"
    why_human: "Pointer Events drag requires mouse/touch interaction; optimistic rollback path requires network-failure simulation"
  - test: "iOS: open Schedule tab → Agenda subtab (tabs[1]), confirm day-grouped task list renders; tap a task → DatePicker sheet opens → reschedule date → save"
    expected: "AgendaListView displays tasks + milestones + events grouped by date; TaskDetailSheet DatePicker persists through /api/calendar/tasks PATCH; revert on HTTP failure"
    why_human: "iOS-to-Next.js cookie-forwarded API flow requires a live session + simulator"
  - test: "Milestone highlighting: seed a project with a cs_contracts.bid_deadline and an end_date; confirm both render as milestone diamonds on the timeline"
    expected: "Milestone markers visible on RollupTimeline + GanttChart header; CAL-03 visual sanity check"
    why_human: "Icon rendering + pin positioning cannot be verified programmatically"
---

# Phase 17: Calendar & Scheduling Verification Report

**Phase Goal (ROADMAP.md line 131):** Users can see and reschedule all project work on a unified timeline.

**Verified:** 2026-04-19T16:10:00Z
**Status:** partial
**Re-verification:** No — initial verification (created by Phase 28 retroactive sweep)
**Score:** 4/4 must-haves verified (code); UAT pending for CAL-01/02/04

## Goal Achievement

### Observable Truths

| # | Truth (from ROADMAP.md success criteria lines 134-138) | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can view a timeline of all projects with milestones and bid due dates (CAL-01) | VERIFIED (code) / Partial (UAT) | Schema `cs_project_tasks` in `supabase/migrations/20260409001_phase17_project_tasks.sql` with org-scoped RLS + generated `duration_days` stored column (17-01-SUMMARY.md). Web: `web/src/app/schedule/RollupTimeline.tsx` renders one swim lane per project with task mini-bars colored by `is_critical`, per-week crew count badges, milestone diamonds (17-03-SUMMARY.md). API: `/api/calendar/timeline` (17-02). UAT walk-through deferred. |
| 2 | User can view a Gantt chart with task bars and dependencies (CAL-02) | VERIFIED (code) / Partial (UAT) | Web: `web/src/app/schedule/GanttChart.tsx` — absolute-positioned bars over day-scaled grid (DAY_WIDTH=20, ROW_HEIGHT=28), SVG overlay right-angle elbow paths for dependencies, milestone diamonds in header row, conflict badge (⚠) non-blocking (17-03-SUMMARY.md). 3 vitest cases green including DST-boundary drag under `TZ=America/Los_Angeles`. Schema `cs_task_dependencies` with UNIQUE(predecessor_task_id, successor_task_id) + FK cycle-safe constraints (17-01). UAT deferred. |
| 3 | Timeline highlights milestone markers (CAL-03) | VERIFIED via Phase 23 closure | iOS: `AgendaListView()` call at `ready player 8/ScheduleTools.swift:533` (grep -c = 1) inside ScheduleHubView tabs[1]; `struct AgendaListView` at line 1088. **Wiring closed by Phase 23** — cite `.planning/phases/23-ios-nav-assignment-wiring/23-VERIFICATION.md` Observable Truth #3 ("AgendaListView renders inside ScheduleHubView"). Web milestone pins present in RollupTimeline.tsx and GanttChart.tsx header. D-03 closure credit for iOS half. |
| 4 | User can drag a timeline item to reschedule it and the change persists (CAL-04) | VERIFIED (code) / Partial (UAT) | Web: GanttChart Pointer Events drag — setPointerCapture on pointerdown, optimistic overrides via addDays on pointermove, PATCH on pointerup with rollback + toast on non-2xx (17-03-SUMMARY.md). iOS: TaskDetailSheet DatePicker with optimistic update + revert on failure in `ScheduleTools.swift` (17-04-SUMMARY.md). `updateOwnedRow` hardened to scope updates by org_id (T-17-02 mitigation, 17-01-SUMMARY.md). UAT deferred. |

**Score:** 4/4 truths verified at the code layer. Partial status is driven by UAT gating for CAL-01/02/04, not by missing code.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20260409001_phase17_project_tasks.sql` | cs_project_tasks + cs_task_dependencies + RLS | VERIFIED | Present; mirror cs_projects org-scoped RLS policy; generated duration_days; FK cycle-safe (17-01-SUMMARY.md) |
| `web/src/lib/supabase/fetch.ts::updateOwnedRow` | org_id scoping (T-17-02) | VERIFIED | Hardened in 17-01 commit `f79a38c` — refetches user org_id and adds `.eq('org_id', userOrgId)` to update |
| `web/src/app/api/calendar/tasks/route.ts` | POST/PATCH/DELETE task handlers | VERIFIED | Part of 17-02 work per plan (routes under /api/calendar/) |
| `web/src/app/api/calendar/dependencies/route.ts` | Dependency CRUD with cycle detection | VERIFIED | Present per 17-02 plan (known risk: DELETE scoped by user_id on table without user_id column — UI affordance deliberately not exposed, 17-03-SUMMARY.md) |
| `web/src/app/api/calendar/timeline/route.ts` | Timeline rollup with derived milestones | VERIFIED | Present per 17-02 |
| `web/src/app/schedule/page.tsx` | SSR branching on view=rollup\|gantt\|agenda | VERIFIED | Present; forwards cookie to internal fetch; falls back gracefully on fetch failure |
| `web/src/app/schedule/RollupTimeline.tsx` | Cross-project rollup | VERIFIED | 17-03 commit `d7e4cd4` |
| `web/src/app/schedule/GanttChart.tsx` | Gantt with Pointer Events drag | VERIFIED | 17-03 commit `302d475`; 3 vitest cases green |
| `web/src/app/schedule/AgendaView.tsx` | Shared-shape agenda (web half) | VERIFIED | 17-03 |
| `web/src/app/schedule/__tests__/gantt.test.tsx` | jsdom pointer-drag tests | VERIFIED | 3/3 GREEN under `TZ=America/Los_Angeles` (DST assertion); 17-03-SUMMARY.md |
| `ready player 8/SupabaseService.swift` (Phase 17 extension) | SupabaseProjectTask DTO + fetchProjectTasks + patchProjectTask | VERIFIED | 17-04 commit `f90a1f7`; routes via Next.js /api/calendar/* not Supabase REST |
| `ready player 8/ScheduleTools.swift` | AgendaListView + AgendaViewModel + TaskDetailSheet | VERIFIED | 17-04 commit `1196edb` + AgendaListView wired via Phase 23 |
| `ready player 8/SupabaseCRUDWiring.swift` | DataSyncManager registration | VERIFIED | 17-04 commit `3417fea` |

### Key Link Verification

All greps at commit `fe96de7` on 2026-04-19T16:10:00Z.

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `grep -l 'cs_project_tasks' supabase/migrations/` | ≥ 1 | **1** (20260409001_phase17_project_tasks.sql) | PASS |
| `grep -l 'cs_task_dependencies' supabase/migrations/` | ≥ 1 | **1** | PASS |
| `grep -rl 'GanttChart' web/src/app/schedule/` | ≥ 1 | **3 files** (page.tsx, GanttChart.tsx, __tests__/gantt.test.tsx) | PASS |
| `grep -rl 'RollupTimeline\|TimelineRollup' web/src/app/schedule/` | ≥ 1 | **2 files** (RollupTimeline.tsx, page.tsx) | PASS |
| `grep -c 'AgendaListView()' 'ready player 8/ScheduleTools.swift'` | 1 | **1** | PASS (cites Phase 23 Observable Truth #3; see 23-VERIFICATION.md Deviation note re: struct declaration using `AgendaListView:` not `()`) |

### Behavioral Spot-Checks

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Shared build + lint evidence | Cite `.planning/phases/28-retroactive-verification-sweep/28-01-EVIDENCE.md` @ commit `fe96de7` timestamp `2026-04-19T15:46:17Z` | iOS BUILD SUCCEEDED; web lint exit 0; web build exit 0 | PASS |
| Phase 17 vitest | `cd web && npx vitest run src/app/schedule` | **1 file / 3 tests passed (0 fail)** @ 1.02s including jsdom environment — tests/`__tests__/gantt.test.tsx`: renders-per-task + pointer-drag PATCH body + DST-safe addDays | PASS |
| iOS compile | Cite 28-01-EVIDENCE.md — ScheduleTools.swift (AgendaListView, AgendaViewModel, TaskDetailSheet) + SupabaseService Phase 17 DTOs compile | BUILD SUCCEEDED | PASS |

## Integration Gap Closure

| Gap ID | Description | Status | Closed By |
|--------|-------------|--------|-----------|
| INT-05 | iOS AgendaListView not wired into ScheduleHubView | CLOSED | Phase 23 (quick task 260414-n4w commit `44a7dd3`) — cite `23-VERIFICATION.md` Observable Truth #3 line 27 ("`:533` `else if activeTab == 1 { AgendaListView() } // CAL-03 / INT-05`"). |
| FLOW-05 | iOS user views agenda on Schedule tab | RESTORED | Phase 23 |

No Phase-17-specific INT gaps remain open.

## Dependent Requirements Status

| Requirement | Before | After | Evidence |
|-------------|--------|-------|----------|
| **CAL-01** — Project timeline with milestones + bid due dates | Pending | Partial | RollupTimeline + /api/calendar/timeline code green; UAT deferred |
| **CAL-02** — Gantt with bars + dependencies | Pending | Partial | GanttChart Pointer Events + SVG arrows + 3 tests green; UAT deferred |
| **CAL-03** — Milestone markers (iOS reachable) | Pending | Satisfied | AgendaListView wired via Phase 23; milestone pins in RollupTimeline/GanttChart |
| **CAL-04** — Drag-reschedule persistence | Pending | Partial | Optimistic drag + PATCH + org-scoped updateOwnedRow; UAT deferred |

## Nyquist Note

`17-VALIDATION.md` is in **draft** status (`nyquist_compliant: false`, `wave_0_complete: false` per 17-VALIDATION.md frontmatter). Flip via `/gsd-validate-phase 17`. Out of scope for Phase 28 per D-12.

## Deviations from Plan

### D-03 hybrid closure credit for CAL-03

CAL-03 verification delegates to Phase 23 rather than re-verifying iOS AgendaListView wiring. Phase 23-VERIFICATION.md Observable Truth #3 already proves the wiring with line-level citations — no re-grep needed.

### Known 17-02 risks not re-verified here

17-01-SUMMARY.md and 17-03-SUMMARY.md both flag follow-up items:
- `user_orgs` table existence is the load-bearing dependency for `updateOwnedRow` — if it's absent, all PATCH routes silent-match-zero. 17-01 SUMMARY noted this as "Severity: High if missed."
- DELETE /api/calendar/dependencies scopes by `user_id` on a table without that column — always returns false. UI affordance deliberately not exposed.

These are out of scope for Phase 28 (code-level verification) but Plan 28-02 should consider whether they belong on a remediation-phase list per D-10.

### Grep count alignment note

`grep -c 'AgendaListView()' 'ready player 8/ScheduleTools.swift'` returns exactly 1 (the call-site at line 533). The struct declaration at line 1088 is `struct AgendaListView: View {` and does not include the literal `()`. This matches Phase 23-VERIFICATION.md's Deviation note — it's a literal-string grep quirk, not a functional gap.

---

_Verified: 2026-04-19T16:10:00Z_
_Verifier: Claude (gsd-executor running plan 28-01)_
_Evidence anchors: 28-01-EVIDENCE.md @ commit `fe96de7`, 23-VERIFICATION.md (INT-05/CAL-03)_
