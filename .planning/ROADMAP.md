# Roadmap: ConstructionOS

## Milestones

- ✅ **v1.0 Production Hardening** — Phases 1-12 (shipped 2026-04-06) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Portal & AI Expansion** — Phases 18, 20, 21 (shipped 2026-04-14) — [archive](milestones/v2.0-ROADMAP.md)
- 🚧 **v2.1 Gap Closure & Feature Completion** — Phases 13-17, 19, 22-28 (in progress)

## Phases

<details>
<summary>✅ v1.0 Production Hardening (Phases 1-12) — SHIPPED 2026-04-06</summary>

- [x] Phase 1: Secrets & Infrastructure Cleanup (3/3 plans) — completed 2026-04-05
- [x] Phase 2: Authentication (3/3 plans) — completed 2026-04-06
- [x] Phase 3: Row-Level Security (2/2 plans) — completed 2026-04-06
- [x] Phase 4: iOS Crash Safety (2/2 plans) — completed 2026-04-06
- [x] Phase 5: iOS Error Handling & State Persistence (4/4 plans) — completed 2026-04-06
- [x] Phase 6: Web Security & Validation (3/3 plans) — completed 2026-04-06
- [x] Phase 7: Web Error Handling & Consistency (3/3 plans) — completed 2026-04-06
- [x] Phase 8: Web UX & Loading States (3/3 plans) — completed 2026-04-06
- [x] Phase 9: Web Performance & Dynamic Content (5/5 plans) — completed 2026-04-06
- [x] Phase 10: Accessibility & SEO (3/3 plans) — completed 2026-04-06
- [x] Phase 11: iOS Tests (2/2 plans) — completed 2026-04-06
- [x] Phase 12: Web Tests (3/3 plans) — completed 2026-04-06

</details>

<details>
<summary>✅ v2.0 Portal & AI Expansion (Phases 18, 20, 21) — SHIPPED 2026-04-14</summary>

- [x] Phase 18: Enhanced AI (Angelic AI v2) (4/4 plans) — completed 2026-04-11
- [x] Phase 20: Client Portal & Sharing (10/10 plans) — completed 2026-04-13
- [x] Phase 21: Live Satellite & Traffic Maps (6/6 plans) — completed 2026-04-14

**Scope note:** Original v2.0 included Phases 13-22. After audit (see `milestones/v2.0-MILESTONE-AUDIT.md`), scope was reduced to verified phases. Remaining phases carried to v2.1.

</details>

### 🚧 v2.1 Gap Closure & Feature Completion

Phase code exists on `main` from original v2.0 work — verification, wiring, and integration gaps are the remaining work.

- [x] **Phase 13: Document Management Foundation** (5/5 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 14: Notifications & Activity Feed** (5/5 plans) — code complete 2026-04-11, verification pending
- [x] **Phase 15: Team & Crew Management** (4/4 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 16: Field Tools** (6/6 plans) — code complete 2026-04-08, verification pending
- [x] **Phase 17: Calendar & Scheduling** (5/5 plans) — code complete 2026-04-11, verification pending
- [x] **Phase 19: Reporting & Dashboards** (18/18 plans) — code complete 2026-04-12, verification pending
- [ ] **Phase 22: Live Site Video** — TBD, never planned (0 plans)
- [ ] **Phase 23: iOS Navigation & Assignment Wiring** — Gap closure: INT-03/04/05 closed by quick task 260414-n4w; phase formalizes verification
- [ ] **Phase 24: Document → Activity Event Emission** — Gap closure: document routes emit `cs_activity_events` (INT-02)
- [ ] **Phase 25: Certification Expiry Notifications** — Gap closure: cert-expiry cron + notification emission (INT-06)
- [ ] **Phase 26: Documents RLS Table Reconciliation** — Gap closure: resolve RLS references to non-existent tables (INT-01)
- [ ] **Phase 27: Portal → Map Navigation Link** — Gap closure: portal home links to `/map` sub-route when enabled (INT-07)
- [ ] **Phase 28: Retroactive Verification Sweep (Phases 13–19)** — Gap closure: create missing VERIFICATION.md files, reconcile REQUIREMENTS.md

## Phase Details

### Phase 13: Document Management Foundation
**Goal**: Users can upload, attach, preview, and version files across all entity types
**Depends on**: v1.0 (auth, RLS, Supabase)
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-04, DOC-05
**Success Criteria** (what must be TRUE):
  1. User can upload a PDF or image to Supabase Storage from iOS and web
  2. User can download any attached file
  3. User can attach files to a project, RFI, submittal, or change order
  4. User can preview PDFs and images in-app without downloading
  5. User can view a list of prior versions of a revised document
**Plans**: 5 plans
- [x] 13-01-PLAN.md — Schema, Storage bucket, RLS policies (Wave 0, BLOCKING db push)
- [x] 13-02-PLAN.md — Web API routes (upload, sign, versions, attach, list)
- [x] 13-03-PLAN.md — iOS storage layer (SupabaseService extensions, HEIC, DocumentSyncManager)
- [ ] 13-04-PLAN.md — Web UI integration (AttachmentList, Preview, VersionHistory on 4 entity pages)
- [x] 13-05-PLAN.md — iOS UI integration (DocumentAttachmentsView on 4 entity surfaces)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 14: Notifications & Activity Feed
**Goal**: Users see what changed, what needs attention, and what's coming due
**Depends on**: Phase 13 (document events feed activity)
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05
**Success Criteria** (what must be TRUE):
  1. User sees a notification list with an unread count badge
  2. User can view a chronological activity timeline per project
  3. User can mark notifications as read individually or all at once
  4. User can dismiss notifications
  5. User receives iOS push notifications for bid deadlines, safety alerts, and assigned tasks
**Plans**: TBD
**UI hint**: yes
**v2.1 status**: verification pending (see Phases 24, 25, 28)

### Phase 15: Team & Crew Management
**Goal**: Users can manage team members, assignments, and credentials
**Depends on**: Phase 14 (cert expiration alerts use notifications)
**Requirements**: TEAM-01, TEAM-02, TEAM-03, TEAM-04, TEAM-05
**Success Criteria** (what must be TRUE):
  1. User can create a team member profile with role, trade, and contact info
  2. User can assign team members to projects with specific roles
  3. User can record certifications and licenses with expiration dates
  4. User receives an alert when a certification is nearing expiration
  5. User can create a daily crew assignment for a project
**Plans**: 4 plans
- [x] 15-01-PLAN.md — Wave 0 schema + RLS + test stubs + db push (BLOCKING)
- [x] 15-02-PLAN.md — Wave 1 cert-expiry-scan Edge Function + pg_cron
- [x] 15-03-PLAN.md — Wave 2 web /team route + API routes + DailyCrewSection
- [x] 15-04-PLAN.md — Wave 2 iOS TeamView + CertificationsView + DailyCrewView
**UI hint**: yes
**v2.1 status**: iOS nav wiring closed by quick task 260414-n4w; cert notification emission still open (Phase 25)

### Phase 16: Field Tools
**Goal**: Field users can capture, annotate, and log work from the jobsite
**Depends on**: Phase 13 (photos are documents), Phase 15 (logs reference crew)
**Requirements**: FIELD-01, FIELD-02, FIELD-03, FIELD-04
**Success Criteria** (what must be TRUE):
  1. User can capture a photo with GPS location and timestamp automatically tagged
  2. User can attach photos to punch items, daily logs, and safety incidents
  3. User can draw annotations/markup on a photo to highlight an issue
  4. User can create a daily log from a pre-filled template based on project context
**Plans**: 6 plans
- [x] 16-00-PLAN.md — Wave 0 test scaffolding (LocationProviding, OpenMeteoClient, fixtures, UAT)
- [x] 16-01-PLAN.md — Wave 1 schema (enum extension migration + columns/tables/RLS + Info.plist)
- [x] 16-02-PLAN.md — Wave 2 iOS capture pipeline + attach extension (FIELD-01, FIELD-02 iOS)
- [x] 16-03-PLAN.md — Wave 2 web /field photo browser + attach Server Actions (FIELD-02 web)
- [x] 16-04-PLAN.md — Wave 3 photo annotation, both platforms (FIELD-03)
- [x] 16-05-PLAN.md — Wave 3 daily logs with layered templates, both platforms (FIELD-04)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 17: Calendar & Scheduling
**Goal**: Users can see and reschedule all project work on a unified timeline
**Depends on**: Phase 15 (assignments appear on calendar)
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04
**Success Criteria** (what must be TRUE):
  1. User can view a timeline of all projects with milestones and bid due dates
  2. User can view a Gantt chart with task bars and dependencies
  3. Timeline highlights milestone markers (bid due, project start/end, inspections)
  4. User can drag a timeline item to reschedule it and the change persists
**Plans**: 5 plans
- [x] 17-00-PLAN.md — Wave 0 test scaffolding (vitest stubs + iOS XCTest stubs + updateOwnedRow scoping check)
- [x] 17-01-PLAN.md — Wave 1 schema (cs_project_tasks + cs_task_dependencies + RLS + updateOwnedRow org_id scoping, BLOCKING db push)
- [x] 17-02-PLAN.md — Wave 2 Next.js API routes (/api/calendar/tasks, dependencies with cycle detection, timeline rollup with derived milestones)
- [x] 17-03-PLAN.md — Wave 3 web /schedule rebuild (RollupTimeline + GanttChart with Pointer Events drag + AgendaView)
- [x] 17-04-PLAN.md — Wave 4 iOS agenda + tap-to-reschedule sheet in ScheduleTools.swift
**UI hint**: yes
**v2.1 status**: AgendaListView wiring closed by quick task 260414-n4w; verification pending (see Phase 28)

### Phase 19: Reporting & Dashboards
**Goal**: Users can view aggregated metrics and export shareable reports
**Depends on**: Phases 13-18 (aggregates data from all features)
**Requirements**: REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Success Criteria** (what must be TRUE):
  1. User can generate a single-project summary report covering budget, schedule, issues, and team
  2. User can view a cross-project financial rollup dashboard
  3. User can export a report to PDF
  4. User can view bar/line/pie chart visualizations for budgets, timelines, and safety metrics
**Plans**: 18 plans
- [x] 19-01 through 19-18 — see archive for details (all 18 plans complete)
**UI hint**: yes
**v2.1 status**: verification pending (see Phase 28)

### Phase 22: Live Site Video — per-project HLS camera feeds
**Goal:** [To be planned]
**Requirements**: VIDEO-01 (TBD)
**Depends on:** Phase 21
**Plans:** 0 plans — never planned
- [ ] TBD (run /gsd-plan-phase 22 to break down)

### Phase 23: iOS Navigation & Assignment Wiring
**Goal:** Existing iOS views (TeamView, CertificationsView, DailyCrewView, AgendaListView) are reachable from user navigation; daily crew edits do not 409
**Depends on:** Phase 15, Phase 17
**Requirements:** TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03
**Gap Closure:** Closes INT-03, INT-04, INT-05 · FLOW-03, FLOW-04, FLOW-05
**Status:** Code closed by quick task 260414-n4w on 2026-04-14; phase formalizes verification artifacts

### Phase 24: Document → Activity Event Emission
**Goal:** Every document mutation emits a row into `cs_activity_events` so the activity feed populates for document ops
**Depends on:** Phase 13, Phase 14
**Requirements:** DOC-02, NOTIF-02
**Gap Closure:** Closes INT-02 · FLOW-01

### Phase 25: Certification Expiry Notifications
**Goal:** Users receive notifications when certifications approach expiration
**Depends on:** Phase 14, Phase 15
**Requirements:** TEAM-04, NOTIF-04
**Gap Closure:** Closes INT-06 · FLOW-02

### Phase 26: Documents RLS Table Reconciliation
**Goal:** RLS predicates for document attachments cover all referenced entity types without silent skip
**Depends on:** Phase 13
**Requirements:** DOC-03, DOC-04
**Gap Closure:** Closes INT-01

### Phase 27: Portal → Map Navigation Link
**Goal:** Portal viewers can reach the `/map` sub-route when the admin enabled it
**Depends on:** Phase 20 (shipped v2.0), Phase 21 (shipped v2.0)
**Requirements:** (integration-only — supports PORTAL-03, MAP-04)
**Gap Closure:** Closes INT-07

### Phase 28: Retroactive Verification Sweep (Phases 13–19)
**Goal:** Every v2.0-originated phase marked complete has a VERIFICATION.md proving goal-backward coverage, and REQUIREMENTS.md reflects the true state
**Depends on:** Phases 23, 24, 25, 26 (must run after code gaps are closed)
**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-05, FIELD-01, FIELD-02, FIELD-03, FIELD-04, CAL-01, CAL-02, CAL-04, REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Gap Closure:** Closes all "partial — no VERIFICATION.md" audit gaps; reconciles REQUIREMENTS.md traceability

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|---------------|--------|-----------|
| 1-12 | v1.0 | 36/36 | Complete | 2026-04-06 |
| 18. Enhanced AI (Angelic AI v2) | v2.0 | 4/4 | Complete | 2026-04-11 |
| 20. Client Portal & Sharing | v2.0 | 10/10 | Complete | 2026-04-13 |
| 21. Live Satellite & Traffic Maps | v2.0 | 6/6 | Complete | 2026-04-14 |
| 13. Document Management Foundation | v2.1 | 5/5 | Code Complete | 2026-04-08 |
| 14. Notifications & Activity Feed | v2.1 | 5/5 | Code Complete | 2026-04-11 |
| 15. Team & Crew Management | v2.1 | 4/4 | Code Complete | 2026-04-08 |
| 16. Field Tools | v2.1 | 6/6 | Code Complete | 2026-04-08 |
| 17. Calendar & Scheduling | v2.1 | 5/5 | Code Complete | 2026-04-11 |
| 19. Reporting & Dashboards | v2.1 | 18/18 | Code Complete | 2026-04-12 |
| 22. Live Site Video | v2.1 | 0/? | Not planned | — |
| 23. iOS Navigation & Assignment Wiring | v2.1 | 1/2 | In Progress|  |
| 24. Document → Activity Event Emission | v2.1 | 0/? | Planned | — |
| 25. Certification Expiry Notifications | v2.1 | 0/? | Planned | — |
| 26. Documents RLS Table Reconciliation | v2.1 | 0/? | Planned | — |
| 27. Portal → Map Navigation Link | v2.1 | 0/? | Planned | — |
| 28. Retroactive Verification Sweep (Phases 13–19) | v2.1 | 0/? | Planned | — |
