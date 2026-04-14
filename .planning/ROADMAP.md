# Roadmap: ConstructionOS

## Milestones

- ✅ **v1.0 Production Hardening** — Phases 1-12 (shipped 2026-04-06) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Feature Expansion** — Phases 13-22 (in progress)

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
- [x] **Phase 14: Notifications & Activity Feed** (5/5 plans) — completed 2026-04-11
- [x] **Phase 15: Team & Crew Management** (4/4 plans) — completed 2026-04-08
- [x] **Phase 16: Field Tools** — GPS-tagged photos, annotations, daily log templates (completed 2026-04-08)
- [x] **Phase 17: Calendar & Scheduling** — Project timeline, Gantt chart, drag-to-reschedule (completed 2026-04-11)
- [x] **Phase 18: Enhanced AI (Angelic AI v2)** — Context-aware chat, RFI/CO generation, bid analysis (completed 2026-04-11)
- [x] **Phase 19: Reporting & Dashboards** — Project reports, cross-project rollups, PDF export, charts (completed 2026-04-12)
- [x] **Phase 20: Client Portal & Sharing** — Shareable read-only project URLs with branding (completed 2026-04-13)
- [x] **Phase 21: Live Satellite & Traffic Maps** — Satellite imagery, real-time traffic overlays, equipment tracking across all map features (completed 2026-04-14)
- [ ] **Phase 23: iOS Navigation & Assignment Wiring** — Gap closure: wire orphaned iOS views (Team/Crew/Certifications/Agenda) into NavTab; fix DailyCrewView upsert
- [ ] **Phase 24: Document → Activity Event Emission** — Gap closure: document routes emit `cs_activity_events` so activity feed is populated
- [ ] **Phase 25: Certification Expiry Notifications** — Gap closure: cert-expiry cron + notification emission to satisfy TEAM-04, NOTIF-04
- [ ] **Phase 26: Documents RLS Table Reconciliation** — Gap closure: resolve RLS references to non-existent cs_rfis/cs_submittals/cs_change_orders
- [ ] **Phase 27: Portal → Map Navigation Link** — Gap closure: portal home links to /map sub-route when enabled
- [ ] **Phase 28: Retroactive Verification Sweep (Phases 13–19)** — Gap closure: create missing VERIFICATION.md files to close partial requirements

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
- [x] 17-04-PLAN.md — Wave 4 iOS agenda + tap-to-reschedule sheet in ScheduleTools.swift
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
**Plans**: 4 plans
- [x] 18-00-PLAN.md — Wave 0 test scaffolding (vitest stubs for tool definitions)
- [x] 18-01-PLAN.md — Wave 1 web tools module + chat route upgrade (AI SDK tool calling with Supabase)
- [x] 18-02-PLAN.md — Wave 1 iOS MCPToolServer async upgrade (live Supabase data + new tools)
- [x] 18-03-PLAN.md — Wave 2 iOS draft rendering + end-to-end verification checkpoint
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
**Plans**: 18 plans
Plans:
- [x] 19-01-PLAN.md — Wave 1 TDD: npm deps, report types, aggregation functions with 100% coverage
- [x] 19-02-PLAN.md — Wave 1 Recharts chart components + StatCard/HealthBadge/Skeleton UI atoms
- [x] 19-03-PLAN.md — Wave 1 Database schema (8 cs_report_* tables, RLS, indexes, views)
- [x] 19-04-PLAN.md — Wave 2 API routes: /api/reports/project/[id], /api/reports/rollup, /api/reports/health
- [x] 19-05-PLAN.md — Wave 3 Web report pages: landing, single-project report with all sections, nav integration
- [x] 19-06-PLAN.md — Wave 3 Web portfolio rollup: sortable table, portfolio charts, timeline, comparison
- [x] 19-07-PLAN.md — Wave 4 PDF export: jsPDF + html2canvas, preview, multi-format export (CSV/Excel/PPTX/JSON)
- [x] 19-08-PLAN.md — Wave 4 Email scheduling: CRUD API, Vercel Cron, Resend template, schedule management UI
- [x] 19-09-PLAN.md — Wave 4 Shareable links + multi-format export generators (CSV/Excel/PPTX) + access control
- [x] 19-10-PLAN.md — Wave 4 iOS: ReportsView + ProjectReportView + PortfolioRollupView + SwiftUI Charts
- [x] 19-11-PLAN.md — Wave 4 iOS: PDF generation + schedule management + Siri/Spotlight/CarPlay stubs
- [x] 19-12-PLAN.md — Wave 5 Collaboration: comments, annotations (Fabric.js), version history with diffs
- [x] 19-13-PLAN.md — Wave 5 i18n (next-intl) + report themes + keyboard shortcuts + bookmarks + bulk ops
- [x] 19-14-PLAN.md — Wave 5 Notifications + automation rules + embed codes + analytics (PostHog)
- [x] 19-15-PLAN.md — Wave 5 Feature discovery + demo report + templates + audit dashboard + CSV import
- [x] 19-16-PLAN.md — Wave 5 Caching + feature flags + data retention + PWA offline + data backup
- [x] 19-17-PLAN.md — Wave 5 iOS: WidgetKit + Siri Shortcuts + accessibility + high contrast + String Catalogs
- [x] 19-18-PLAN.md — Wave 6 Testing: integration + E2E Playwright + iOS XCTests + conditional formatting + print CSS
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
**Plans**: 10 plans
Plans:
- [x] 20-01-PLAN.md — Wave 0: npm deps, portal types, design tokens, test stubs
- [x] 20-02-PLAN.md — Wave 1: Database schema (4 tables + shared_links extension), query modules, BLOCKING db push
- [x] 20-03-PLAN.md — Wave 2: Portal API routes (7 endpoints) + CSS sanitizer + image processor + slug generator
- [x] 20-04-PLAN.md — Wave 3: Public portal page (SSR) + portal shell/header/footer + section components
- [x] 20-05-PLAN.md — Wave 3: Photo timeline + lightbox + ZIP download + portal PDF export
- [x] 20-06-PLAN.md — Wave 4: Web portal management UI (dashboard, create dialog, section editor, analytics)
- [x] 20-07-PLAN.md — Wave 4: Branding theme editor + preset picker + logo upload + branded emails
- [x] 20-08-PLAN.md — Wave 5: iOS portal views + SupabaseService portal extensions
- [x] 20-09-PLAN.md — Wave 5: Security hardening + all test implementations + audit log API + IP blocker
- [x] 20-10-PLAN.md — Wave 6: Final integration (PDF button, mobile nav, webhooks, E2E tests, human verification)
**UI hint**: yes

### Phase 21: Live Satellite & Traffic Maps
**Goal**: All map features show satellite imagery with real-time traffic overlays and construction site activity
**Depends on**: Phase 16 (GPS-tagged photos on maps), Phase 20 (portal may embed maps)
**Requirements**: MAP-01, MAP-02, MAP-03, MAP-04
**Success Criteria** (what must be TRUE):
  1. User can toggle between standard, satellite, and hybrid map layers on all map views
  2. User can see real-time traffic flow overlays on project area maps
  3. User can view construction equipment/vehicle locations on a project site map
  4. All map features (MapsView iOS, /maps web, field photos, project locations) use the enhanced map system
**Plans**: 6 plans
Plans:
- [x] 21-01-PLAN.md — Foundation: types, test stubs, Supabase schema + RLS
- [x] 21-02-PLAN.md — iOS Swift foundation: EquipmentModels + SupabaseService equipment methods
- [x] 21-03-PLAN.md — Web maps enhancement: traffic, equipment, photos, API routes
- [x] 21-04-PLAN.md — iOS MapsView: traffic toggle, equipment markers, camera persistence
- [x] 21-05-PLAN.md — iOS equipment check-in flow + delivery routes
- [x] 21-06-PLAN.md — Portal map overlay configuration (D-13)
**UI hint**: yes

### Phase 23: iOS Navigation & Assignment Wiring
**Goal:** Existing iOS views (TeamView, CertificationsView, DailyCrewView, AgendaListView) are reachable from user navigation; daily crew edits do not 409
**Depends on:** Phase 15, Phase 17
**Requirements:** TEAM-01, TEAM-02, TEAM-03, TEAM-05, CAL-03
**Gap Closure:** Closes INT-03, INT-04, INT-05 · FLOW-03, FLOW-04, FLOW-05
**Success Criteria:**
  1. NavTab enum in ContentView.swift includes team/crew/certifications cases
  2. Tapping each new tab opens the corresponding existing view
  3. AgendaListView renders inside ScheduleHubView (not just defined in ScheduleTools.swift)
  4. DailyCrewView.swift:145 upsert succeeds on edit of an existing row (no 409)

### Phase 24: Document → Activity Event Emission
**Goal:** Every document mutation emits a row into `cs_activity_events` so the activity feed populates for document ops
**Depends on:** Phase 13, Phase 14
**Requirements:** DOC-02, NOTIF-02
**Gap Closure:** Closes INT-02 · FLOW-01
**Success Criteria:**
  1. Upload, delete, attach, and new-version routes write to `cs_activity_events`
  2. Event shape includes action, entity_type, entity_id, actor, metadata
  3. Project activity page displays a document event end-to-end

### Phase 25: Certification Expiry Notifications
**Goal:** Users receive notifications when certifications approach expiration
**Depends on:** Phase 14, Phase 15
**Requirements:** TEAM-04, NOTIF-04
**Gap Closure:** Closes INT-06 · FLOW-02
**Success Criteria:**
  1. Daily cron scans `cs_certifications.expires_at`
  2. Certs ≤30 days out emit `cs_notifications` rows (once per threshold crossing)
  3. Manual expiration changes in `/api/team/certifications/route.ts` also emit
  4. iOS push path delivers an alert in a manual end-to-end test

### Phase 26: Documents RLS Table Reconciliation
**Goal:** RLS predicates for document attachments cover all referenced entity types without silent skip
**Depends on:** Phase 13
**Requirements:** DOC-03, DOC-04
**Gap Closure:** Closes INT-01
**Success Criteria:**
  1. Either the `cs_rfis`, `cs_submittals`, `cs_change_orders` tables exist with owner columns, OR the RLS migration no longer references them
  2. `to_regclass` guarded-skip is removed (no silently-skipped RLS predicates)
  3. Forward migration applies cleanly and RLS enforces on all entity types

### Phase 27: Portal → Map Navigation Link
**Goal:** Portal viewers can reach the /map sub-route when the admin enabled it
**Depends on:** Phase 20, Phase 21
**Requirements:** (integration-only — supports PORTAL-03, MAP-04)
**Gap Closure:** Closes INT-07
**Success Criteria:**
  1. When `show_map` flag is true, `portal/[slug]/[project]/page.tsx` renders a visible link/button to the map sub-route
  2. When the flag is false, no link appears

### Phase 28: Retroactive Verification Sweep (Phases 13–19)
**Goal:** Every v2.0 phase marked complete has a VERIFICATION.md proving goal-backward coverage, and REQUIREMENTS.md reflects the true state
**Depends on:** Phases 23, 24, 25, 26 (must run after code gaps are closed)
**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-05, FIELD-01, FIELD-02, FIELD-03, FIELD-04, CAL-01, CAL-02, CAL-04, REPORT-01, REPORT-02, REPORT-03, REPORT-04
**Gap Closure:** Closes all "partial — no VERIFICATION.md" audit gaps; reconciles REQUIREMENTS.md traceability
**Success Criteria:**
  1. Phases 13, 14, 16, 17, 19 have a VERIFICATION.md (Phase 15 covered by Phase 23, Phase 18 already verified)
  2. Each requirement traced to its phase has verification evidence
  3. REQUIREMENTS.md checkboxes reflect verified state; coverage count matches

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|---------------|--------|-----------|
| 1-12 | v1.0 | 36/36 | Complete | 2026-04-06 |
| 13. Document Management Foundation | v2.0 | 5/5 | Complete | 2026-04-08 |
| 14. Notifications & Activity Feed | v2.0 | 5/5 | Complete | 2026-04-11 |
| 15. Team & Crew Management | v2.0 | 4/4 | Complete | 2026-04-08 |
| 16. Field Tools | v2.0 | 6/6 | Complete   | 2026-04-08 |
| 17. Calendar & Scheduling | v2.0 | 5/5 | Complete | 2026-04-11 |
| 18. Enhanced AI (Angelic AI v2) | v2.0 | 4/4 | Complete    | 2026-04-11 |
| 19. Reporting & Dashboards | v2.0 | 18/18 | Complete    | 2026-04-12 |
| 20. Client Portal & Sharing | v2.0 | 10/10 | Complete    | 2026-04-13 |
| 21. Live Satellite & Traffic Maps | v2.0 | 6/6 | Complete    | 2026-04-14 |
| 23. iOS Navigation & Assignment Wiring | v2.0 | 0/? | Planned | — |
| 24. Document → Activity Event Emission | v2.0 | 0/? | Planned | — |
| 25. Certification Expiry Notifications | v2.0 | 0/? | Planned | — |
| 26. Documents RLS Table Reconciliation | v2.0 | 0/? | Planned | — |
| 27. Portal → Map Navigation Link | v2.0 | 0/? | Planned | — |
| 28. Retroactive Verification Sweep (Phases 13–19) | v2.0 | 0/? | Planned | — |

### Phase 22: Live Site Video — per-project HLS camera feeds tied to project sites, tap marker on Maps tab to open floating video tile; iOS AVPlayer + web hls.js; portal viewers see feeds only if admin enabled per portal (lockable like map_overlays pattern from 21-06). Sources: HLS .m3u8 URLs (IP cameras, drones, YouTube Live, DOT traffic cams).

**Goal:** [To be planned]
**Requirements**: TBD
**Depends on:** Phase 21
**Plans:** 0 plans

Plans:
- [ ] TBD (run /gsd-plan-phase 22 to break down)
