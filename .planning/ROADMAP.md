# Roadmap: ConstructionOS

## Milestones

- ✅ **v1.0 Production Hardening** — Phases 1-12 (shipped 2026-04-06) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Feature Expansion** — Phases 13-21 (in progress)

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

### v2.0 Feature Expansion

- [x] **Phase 13: Document Management Foundation** (5/5 plans) — completed 2026-04-08
- [~] **Phase 14: Notifications & Activity Feed** (4/5 plans) — 14-02 outstanding
- [x] **Phase 15: Team & Crew Management** (4/4 plans) — completed 2026-04-08
- [x] **Phase 16: Field Tools** — GPS-tagged photos, annotations, daily log templates (completed 2026-04-08)
- [ ] **Phase 17: Calendar & Scheduling** — Project timeline, Gantt chart, drag-to-reschedule
- [ ] **Phase 18: Enhanced AI (Angelic AI v2)** — Context-aware chat, RFI/CO generation, bid analysis
- [ ] **Phase 19: Reporting & Dashboards** — Project reports, cross-project rollups, PDF export, charts
- [ ] **Phase 20: Client Portal & Sharing** — Shareable read-only project URLs with branding

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
- [ ] 15-01-PLAN.md — Wave 0 schema + RLS + test stubs + db push (BLOCKING)
- [ ] 15-02-PLAN.md — Wave 1 cert-expiry-scan Edge Function + pg_cron
- [ ] 15-03-PLAN.md — Wave 2 web /team route + API routes + DailyCrewSection
- [ ] 15-04-PLAN.md — Wave 2 iOS TeamView + CertificationsView + DailyCrewView
**UI hint**: yes

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
- [ ] 17-04-PLAN.md — Wave 4 iOS agenda + tap-to-reschedule sheet in ScheduleTools.swift
**UI hint**: yes

### Phase 18: Enhanced AI (Angelic AI v2)
**Goal**: AI uses live project data to assist with construction-specific tasks
**Depends on**: Phases 13-17 (rich data to read)
**Requirements**: AI-01, AI-02, AI-03, AI-04
**Success Criteria** (what must be TRUE):
  1. AI chat responses reference the user's current projects and contracts
  2. User can have AI generate an RFI document from a chat conversation
  3. User can have AI draft a change order from a natural language description
  4. User can ask AI to analyze a bid's competitiveness against market data
**Plans**: TBD
**UI hint**: yes

### Phase 19: Reporting & Dashboards
**Goal**: Users can view aggregated metrics and export shareable reports
**Depends on**: Phases 13-18 (aggregates data from all features)
**Requirements**: REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Success Criteria** (what must be TRUE):
  1. User can generate a single-project summary report covering budget, schedule, issues, and team
  2. User can view a cross-project financial rollup dashboard
  3. User can export a report to PDF
  4. User can view bar/line/pie chart visualizations for budgets, timelines, and safety metrics
**Plans**: TBD
**UI hint**: yes

### Phase 20: Client Portal & Sharing
**Goal**: Users can share a branded read-only project view with clients
**Depends on**: Phase 13 (documents), Phase 16 (photos), Phase 19 (charts)
**Requirements**: PORTAL-01, PORTAL-02, PORTAL-03, PORTAL-04
**Success Criteria** (what must be TRUE):
  1. User can generate a shareable read-only URL for a project
  2. User can configure portal section visibility (budget, schedule, photos)
  3. Client viewers see a chronological progress photo timeline
  4. Portal page displays the company's logo and brand colors
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|---------------|--------|-----------|
| 1-12 | v1.0 | 36/36 | Complete | 2026-04-06 |
| 13. Document Management Foundation | v2.0 | 5/5 | Complete | 2026-04-08 |
| 14. Notifications & Activity Feed | v2.0 | 4/5 | In Progress | - |
| 15. Team & Crew Management | v2.0 | 4/4 | Complete | 2026-04-08 |
| 16. Field Tools | v2.0 | 6/6 | Complete   | 2026-04-08 |
| 17. Calendar & Scheduling | v2.0 | 4/5 | In Progress|  |
| 18. Enhanced AI (Angelic AI v2) | v2.0 | 0/0 | Not started | - |
| 19. Reporting & Dashboards | v2.0 | 0/0 | Not started | - |
| 20. Client Portal & Sharing | v2.0 | 0/0 | Not started | - |
