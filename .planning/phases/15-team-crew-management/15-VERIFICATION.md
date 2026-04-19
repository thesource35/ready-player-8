---
phase: 15-team-crew-management
verified: 2026-04-19T16:00:00Z
status: passed
score: 5/5 must-haves verified
re_verification: false
human_verification:
  - test: "iOS: open the app on simulator, tap the TEAM tab, confirm Members/Assignments sub-views render; tap CERTS, confirm CertificationsView with escalating colors; tap DAILY CREW, confirm the picker selects a real project and save-persists via upsert"
    expected: "All three orphaned-from-audit views are reachable via NavTab; DailyCrew save returns 200/204 (not 409) on second-save"
    why_human: "End-to-end navigation + server round-trip on iOS simulator requires a real build + live Supabase credentials — the code is proven compile-clean and NavTab-wired via Phase 23 but a user tap-through belt-and-suspenders the happy path"
  - test: "Web: open /team with a signed-in user with a cs_team_members row, confirm Members table renders; navigate to /team/assignments, /team/certifications, confirm red/amber color-coding on expiring certs"
    expected: "Three /team sub-pages render real rows; cert near expiration shows amber, expired shows red"
    why_human: "Color-coding and active-user session require a browser and a seeded Supabase project"
  - test: "Cert expiry end-to-end: insert a cs_certifications row with expires_at = today + 30 days and status = 'active'; wait for the 13:15 UTC pg_cron cert-expiry-scan run (or invoke manually); verify cs_activity_events row is created with category='assigned_task' and cs_notifications downstream"
    expected: "cert-expiry-scan inserts exactly one cs_activity_events row for the 30-day threshold; fanout creates cs_notifications rows for project assignees; on iOS push cert-specific title + body arrives if Apple Developer portal is configured (Phase 25 human item)"
    why_human: "Cron timing + real DB + real device push tier requires physical access"
---

# Phase 15: Team & Crew Management Verification Report

**Phase Goal (ROADMAP.md line 94):** Users can manage team members, assignments, and credentials.

**Verified:** 2026-04-19T16:00:00Z
**Status:** passed
**Re-verification:** No — initial verification (created by Phase 28 retroactive sweep)
**Score:** 5/5 must-haves verified

> **D-04 disclosure:** This VERIFICATION.md stays code-level and phase-scoped. For integration concerns (NavTab wiring, DailyCrew upsert, cert notifications) it cites Phase 23 and Phase 25 closure artifacts rather than re-running the evidence. Phase 15 itself shipped schemas, RLS, and Team/Certs/DailyCrew views; the cross-phase stitching landed in Phases 23 and 25.

## Goal Achievement

### Observable Truths

| # | Truth (from ROADMAP.md success criteria lines 97-102) | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can create a team member profile with role, trade, and contact info (TEAM-01) | VERIFIED | Schema `cs_team_members` in `supabase/migrations/20260408002_phase15_team.sql` (grep -c = 8 references including indexes, RLS, FKs). iOS: `ready player 8/TeamView.swift` with AddTeamMemberSheet + TeamMemberDraft validation (15-04-SUMMARY.md). Web: `/team` page + `POST /api/team` route with memberSchema zod validation (15-03-SUMMARY.md: 6 TEAM-01 tests in `src/lib/team/__tests__/team.test.ts`). **NavTab reachability closed by Phase 23** — cite `.planning/phases/23-ios-nav-assignment-wiring/23-VERIFICATION.md` Observable Truth #1 (ContentView.swift:558 `case team = "team"`) and #2 (line 740 `case .team: TeamView()`). D-03 hybrid credit. |
| 2 | User can assign team members to projects with specific roles (TEAM-02) | VERIFIED | Schema `cs_project_assignments` in 20260408002 migration with `UNIQUE active assignment` partial index (15-01-SUMMARY.md). iOS: TeamView Assignments sub-view wired to DataSyncManager.syncTable (15-04-SUMMARY.md Must-Haves Verified checklist). Web: `POST /api/team/assignments` route with 409 on unique-violation + assignmentSchema (15-03-SUMMARY.md: 5 TEAM-02 tests). NavTab reachability via Phase 23 (same citation as TEAM-01). |
| 3 | User can record certifications and licenses with expiration dates (TEAM-03) | VERIFIED | Schema `cs_certifications` in 20260408002 migration with `cert expiry partial` index for efficient upcoming-expiry scans (15-01-SUMMARY.md). iOS: `ready player 8/CertificationsView.swift` with 28pt expiry headline + AddCertSheet (15-04-SUMMARY.md, "dominant 28pt expiry headline"). Web: `POST /api/team/certifications` with optional document_id FK + `/team/certifications` page with red (<today) / amber (<+30d) color-coding (15-03-SUMMARY.md: 5 TEAM-03 tests). NavTab reachability via Phase 23 Observable Truth #1 — `case certifications = "certifications"` at ContentView.swift:559. |
| 4 | User receives an alert when a certification is nearing expiration (TEAM-04) | VERIFIED via Phase 25 closure | Phase 15 shipped the scaffolding: `supabase/functions/cert-expiry-scan/index.ts` (initial Phase 15-02 single-30-day check) + `supabase/migrations/20260408_phase15_pgcron_cert_sweep.sql` (daily 13:15 UTC schedule). **Phase 25 closed the full notification loop** — cite `.planning/phases/25-certification-expiry-notifications/25-01-SUMMARY.md` (Edge Function rewritten for 30d/7d/day-of/weekly post-expiry thresholds with payload-marker dedupe + member grouping + rate cap; cert renewal AFTER UPDATE trigger) and `.planning/phases/25-certification-expiry-notifications/25-02-SUMMARY.md` (cert-specific push copy + VIEW_CERT APNs category + iOS UNNotificationCategory merge pattern). 14 Deno tests in cert-expiry-scan index.test.ts pass. D-03 closure credit; D-04 phase-scoping respected (Phase 15 does not re-verify Phase 25's cert chain). |
| 5 | User can create a daily crew assignment for a project (TEAM-05) | VERIFIED | Schema `cs_daily_crew` in 20260408002 migration with `cs_daily_crew_one_per_day` unique index on (project_id, assignment_date) — 15-01-SUMMARY.md. iOS: `ready player 8/DailyCrewView.swift` with 48pt tap-target checkboxes (15-04-SUMMARY.md). **NavTab reachability + INT-04 insert→upsert bug fix both closed by Phase 23** — cite `23-VERIFICATION.md` Observable Truth #4 (`grep -c '\.insert("cs_daily_crew"' 'ready player 8/DailyCrewView.swift'` → 0 matches; `grep -c '\.upsert(' 'ready player 8/DailyCrewView.swift'` → 1 match) and Plan 23-01 project picker commit `6969ac0`. Web: `POST /api/projects/[id]/daily-crew` upsert on `project_id,assignment_date` (15-03-SUMMARY.md: 4 TEAM-05 tests). |

**Score:** 5/5 truths verified. `status: passed` per D-08.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20260408002_phase15_team.sql` | 4 tables + indexes + FKs | VERIFIED | Present; applied remotely (confirmed by 16-01-SUMMARY.md "Phase 15 team tables" push log line) |
| `supabase/migrations/20260408003_phase15_team_rls.sql` | RLS on all 4 tables via cs_project_members | VERIFIED | Present; 15-01-SUMMARY.md |
| `supabase/migrations/20260408_phase15_pgcron_cert_sweep.sql` | 13:15 UTC pg_cron job | VERIFIED | Present; idempotent unschedule guard (15-02-SUMMARY.md) |
| `supabase/functions/cert-expiry-scan/index.ts` | Edge Function (initial 15-02 version, rewritten in 25-01) | VERIFIED | Present; 15-02-SUMMARY.md; 25-01-SUMMARY.md tracks the rewrite to multi-threshold |
| `web/src/lib/team/schemas.ts` | Shared zod schemas | VERIFIED | memberSchema, assignmentSchema, certSchema, dailyCrewSchema present (15-03) |
| `web/src/lib/team/trades.ts` | TRADES + CERT_NAMES constants | VERIFIED | Present (15-03) |
| `web/src/app/api/team/route.ts` | POST/GET/PATCH/DELETE | VERIFIED | Present |
| `web/src/app/api/team/assignments/route.ts` | POST with 409 on dupe | VERIFIED | Present |
| `web/src/app/api/team/certifications/route.ts` | POST with document_id FK | VERIFIED | Present; Phase 25 Plan 07 added admin scan status badge |
| `web/src/app/api/projects/[id]/daily-crew/route.ts` | POST upsert + GET | VERIFIED | Present (15-03) |
| `web/src/app/team/page.tsx` | Members table SSR | VERIFIED | Present |
| `web/src/app/team/assignments/page.tsx` | Assignments SSR | VERIFIED | Present |
| `web/src/app/team/certifications/page.tsx` | Cert list with color-coded expiry + Phase 25 admin badge | VERIFIED | Present |
| `web/src/app/projects/[id]/DailyCrewSection.tsx` | Client DailyCrew component | VERIFIED | Present (15-03) |
| `ready player 8/TeamView.swift` | Team + Assignments + Certifications sub-views | VERIFIED | Present (15-04) |
| `ready player 8/CertificationsView.swift` | 28pt expiry headline | VERIFIED | Present; Phase 25 Plan 03 added CertUrgency badges + pulse animation |
| `ready player 8/DailyCrewView.swift` | 48pt tap targets + upsert save | VERIFIED | Present; Phase 23 Plan 01 added project picker + AppStorage |
| `ready player 8Tests/TeamServiceTests.swift` | TeamMemberDraft validation | VERIFIED | 3 real assertions (15-04 replaced XCSkip) |
| `web/src/lib/team/__tests__/team.test.ts` | 20 schema assertions | VERIFIED | 20 tests green (15-03 Task 3) |

### Key Link Verification

All greps at commit `fe96de7` on 2026-04-19T16:00:00Z.

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `grep -c 'cs_team_members' supabase/migrations/20260408002_phase15_team.sql` | ≥ 1 | **8** | PASS |
| `grep -c 'cs_certifications' supabase/migrations/20260408002_phase15_team.sql` | ≥ 1 | **6** | PASS |
| `grep -c 'cs_daily_crew' supabase/migrations/20260408002_phase15_team.sql` | ≥ 1 | **3** | PASS |
| `grep -c 'case team = "team"' 'ready player 8/ContentView.swift'` | 1 | **1** | PASS (cites Phase 23 Observable Truth #1) |
| `grep -c '\.upsert(' 'ready player 8/DailyCrewView.swift'` | 1 | **1** | PASS (cites Phase 23 Observable Truth #4) |

### Behavioral Spot-Checks

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Shared build + lint evidence | Cite `.planning/phases/28-retroactive-verification-sweep/28-01-EVIDENCE.md` @ commit `fe96de7` timestamp `2026-04-19T15:46:17Z` | iOS BUILD SUCCEEDED; web lint exit 0; web build exit 0 | PASS |
| Phase 15 vitest | `cd web && npx vitest run src/lib/team` | **1 file / 20 tests passed (0 fail)** @ 193ms | PASS |
| iOS compile | Cite 28-01-EVIDENCE.md — TeamView, CertificationsView, DailyCrewView all compile with Phase 15 DTOs in SupabaseService.swift | BUILD SUCCEEDED | PASS |
| Deno cert-expiry-scan tests | Cite `.planning/phases/25-certification-expiry-notifications/25-01-SUMMARY.md` — 14/14 Deno tests green for multi-threshold + dedupe + recipient resolution | PASS (cite-only) | PASS |

## Integration Gap Closure

The v2.0 audit flagged four Phase-15 integration blockers — all closed in v2.1:

| Gap ID | Description | Status | Closed By |
|--------|-------------|--------|-----------|
| INT-03 | iOS team/certs/daily-crew views orphaned from NavTab | CLOSED | Quick task 260414-n4w (commit `44a7dd3`) + Plan 23-01 (commit `6969ac0`). Cite `23-VERIFICATION.md` Observable Truths #1, #2 and Integration Gap Closure table. |
| INT-04 | DailyCrewView insert → 409 on edit | CLOSED | Quick task 260414-n4w — `SupabaseService.upsert` helper + DailyCrewView.save() migrated to upsert with `on_conflict=project_id,assignment_date`. Cite `23-VERIFICATION.md` Observable Truth #4. |
| INT-05 | AgendaListView not wired into ScheduleHubView (CAL-03; affects TEAM-05 flow indirectly) | CLOSED | Phase 23 — `23-VERIFICATION.md` Observable Truth #3 (ScheduleTools.swift:533 `AgendaListView()`). |
| INT-06 | Cert expiration does not trigger notifications (affects TEAM-04) | CLOSED | Phase 25 Plans 01 + 02 — cite `25-01-SUMMARY.md` + `25-02-SUMMARY.md`. |

| Flow ID | Status | Closure |
|---------|--------|---------|
| FLOW-03 (iOS user navigates to Team/Crew/Certs) | RESTORED | Phase 23 |
| FLOW-04 (iOS user edits daily crew) | RESTORED | Phase 23 |
| FLOW-02 (cert expiration → notification → iOS push) | RESTORED | Phase 25 (real-device push subject to 14-05 Apple Developer portal step, inherited from NOTIF-05 — see 14-VERIFICATION.md) |

## Dependent Requirements Status

| Requirement | Before | After | Evidence |
|-------------|--------|-------|----------|
| **TEAM-01** — Team member CRUD | Pending (v2.0 audit) | Satisfied | Schema + TeamView + /team page + NavTab reachable (Phase 23) |
| **TEAM-02** — Project assignments | Pending | Satisfied | Schema + TeamView Assignments + /api/team/assignments (409 dupe) + NavTab reachable |
| **TEAM-03** — Certifications with expiration | Pending | Satisfied | Schema + CertificationsView + /team/certifications + NavTab reachable |
| **TEAM-04** — Cert expiry alert | Pending | Satisfied | Phase 15 scaffold + Phase 25 multi-threshold + cert-specific push |
| **TEAM-05** — Daily crew assignment | Pending | Satisfied | Schema + DailyCrewView (upsert via Phase 23) + /api/projects/[id]/daily-crew + project picker (Plan 23-01) |

## Nyquist Note

`15-VALIDATION.md` is in **draft** status (`nyquist_compliant: true`, `wave_0_complete: false` per 15-VALIDATION.md frontmatter — per `v2.0-MILESTONE-AUDIT.md` Nyquist table). Flip via `/gsd-validate-phase 15`. Out of scope for Phase 28 per D-12.

## Deviations from Plan

### D-04 phase-scoping applied

Per D-04, Phase 15 VERIFICATION.md stays code-level and phase-scoped. Integration Gap Closure citations above delegate the NavTab/upsert evidence to Phase 23's VERIFICATION.md and the cert-notification evidence to Phase 25's SUMMARYs (Phase 25 does not yet have its own VERIFICATION.md — acceptable per D-03 hybrid-closure language which allows SUMMARY citations).

### D-03 hybrid closure credit applied

- INT-03/04/05 + FLOW-03/04/05 coverage cites `23-VERIFICATION.md` (a passed verification, not a SUMMARY).
- INT-06 + TEAM-04 coverage cites `25-01-SUMMARY.md` and `25-02-SUMMARY.md` (SUMMARYs until Phase 25's own retroactive VERIFICATION lands).

No re-verification of the Phase 23 or Phase 25 artifacts was performed in this plan.

---

_Verified: 2026-04-19T16:00:00Z_
_Verifier: Claude (gsd-executor running plan 28-01)_
_Evidence anchors: 28-01-EVIDENCE.md @ commit `fe96de7`, 23-VERIFICATION.md (INT-03/04/05), 25-01-SUMMARY.md + 25-02-SUMMARY.md (INT-06)_
