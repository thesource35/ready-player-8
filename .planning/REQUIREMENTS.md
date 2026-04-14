# Requirements: ConstructionOS v2.1 Gap Closure & Feature Completion

**Defined:** 2026-04-14 (carried from v2.0 after milestone scope reduction)
**Core Value:** Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## v2.1 Requirements

27 requirements carried from v2.0. Phase code exists on `main`; verification, wiring, and cross-phase integration are the remaining work.

### Notifications & Activity Feed

- [ ] **NOTIF-01**: User can view in-app notification list with unread count badge
- [ ] **NOTIF-02**: User can view activity timeline per project (chronological action log)
- [ ] **NOTIF-03**: User can mark notifications as read (individually or all)
- [ ] **NOTIF-04**: User can dismiss notifications
- [ ] **NOTIF-05**: User receives push notifications on iOS for bid deadlines, safety alerts, and assigned tasks

### Document Management

- [ ] **DOC-01**: User can upload files (PDF, images, drawings) to Supabase Storage
- [ ] **DOC-02**: User can download attached files
- [ ] **DOC-03**: User can attach files to projects, RFIs, submittals, and change orders
- [ ] **DOC-04**: User can preview PDFs and images in-app without downloading
- [ ] **DOC-05**: User can view version history of revised documents

### Team & Crew Management

- [ ] **TEAM-01**: User can create team member profiles with role, trade, and contact info
- [ ] **TEAM-02**: User can assign team members to projects with role assignments
- [ ] **TEAM-03**: User can track certifications and licenses with expiration dates
- [ ] **TEAM-04**: User receives alerts when certifications are nearing expiration
- [ ] **TEAM-05**: User can create daily crew assignments per project

### Reporting & Dashboards

- [ ] **REPORT-01**: User can generate single-project summary report (budget, schedule, issues, team)
- [ ] **REPORT-02**: User can view cross-project financial rollup dashboard
- [ ] **REPORT-03**: User can export reports to PDF
- [ ] **REPORT-04**: User can view chart visualizations (bar/line/pie) for budgets, timelines, and safety metrics

### Field Tools

- [ ] **FIELD-01**: User can capture photos with automatic GPS location and timestamp tagging
- [ ] **FIELD-02**: User can attach photos to punch items, daily logs, and safety incidents
- [ ] **FIELD-03**: User can annotate/markup photos to highlight issues
- [ ] **FIELD-04**: User can create daily logs from pre-filled templates based on project context

### Calendar & Scheduling

- [ ] **CAL-01**: User can view a timeline of all projects with milestones and bid due dates
- [ ] **CAL-02**: User can view a Gantt chart with task bars and dependencies
- [ ] **CAL-03**: Timeline highlights milestone markers (bid due, project start/end, inspections)
- [ ] **CAL-04**: User can drag items on timeline to reschedule them

### Live Site Video (Phase 22 — not yet planned)

- [ ] **VIDEO-01**: Per-project HLS camera feeds tied to project sites (TBD — planning required)

## Carried Integration Blockers

These gaps were identified in the v2.0 milestone audit and remain open at v2.1 start.

| ID | Severity | Description | Affects | Owning v2.1 phase |
|----|----------|-------------|---------|-------------------|
| INT-01 | high | RLS references non-existent `cs_rfis`/`cs_submittals`/`cs_change_orders` | DOC-03, DOC-04 | Phase 26 |
| INT-02 | high | Document routes do not emit `cs_activity_events` | DOC-02, NOTIF-02 | Phase 24 |
| INT-06 | critical | Cert expiration does not trigger notifications | NOTIF-04, TEAM-04 | Phase 25 |
| INT-07 | medium | Portal home has no navigation to `/map` sub-route | (supports PORTAL-03, MAP-04) | Phase 27 |

**Closed by quick task 260414-n4w (2026-04-14):**
- ~~INT-03~~: iOS Team/Crew/Certs views not wired to NavTab
- ~~INT-04~~: DailyCrewView uses insert not upsert
- ~~INT-05~~: AgendaListView not wired into ScheduleHubView

## Future Requirements

Deferred to v2.2 or later.

### Notifications

- **NOTIF-F1**: Email notification delivery
- **NOTIF-F2**: Web push notifications (browser)
- **NOTIF-F3**: Notification preference settings per category

### Documents

- **DOC-F1**: Folder organization
- **DOC-F2**: PDF annotation/markup
- **DOC-F3**: Full-text search across documents

### Reporting

- **REPORT-F1**: Custom dashboard builder
- **REPORT-F2**: Scheduled report delivery via email
- **REPORT-F3**: Excel/CSV export

### AI

- **AI-F1**: MCP tool integration for external data sources
- **AI-F2**: Voice-to-text input

### Field

- **FIELD-F1**: Offline photo queue with sync on reconnect
- **FIELD-F2**: Voice memo capture

## Out of Scope (carried from v2.0)

| Feature | Reason |
|---------|--------|
| Real-time collaboration / conflict resolution | Architecture change — future milestone |
| Offline-first / local data sync queue | Future milestone — requires architectural rework |
| Breaking apart monolithic ContentView.swift | Separate refactoring initiative |
| OAuth login (Google, Apple) | Deferred beyond v2.1 |
| Payment processing for client portal | Read-only portals only |
| Mobile-native client portal app | Web portal sufficient |
| Real-time crew GPS tracking | Privacy concerns — defer until policy defined |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| NOTIF-01 | Phase 28 (verification) | Pending |
| NOTIF-02 | Phase 24 (gap closure) | Pending |
| NOTIF-03 | Phase 28 (verification) | Pending |
| NOTIF-04 | Phase 25 (gap closure) | Pending |
| NOTIF-05 | Phase 28 (verification) | Pending |
| DOC-01 | Phase 28 (verification) | Pending |
| DOC-02 | Phase 24 (gap closure) | Pending |
| DOC-03 | Phase 26 (gap closure) | Pending |
| DOC-04 | Phase 26 (gap closure) | Pending |
| DOC-05 | Phase 28 (verification) | Pending |
| TEAM-01 | Phase 28 (verification) | Pending |
| TEAM-02 | Phase 28 (verification) | Pending |
| TEAM-03 | Phase 28 (verification) | Pending |
| TEAM-04 | Phase 25 (gap closure) | Pending |
| TEAM-05 | Phase 28 (verification) | Pending |
| FIELD-01 | Phase 28 (verification) | Pending |
| FIELD-02 | Phase 28 (verification) | Pending |
| FIELD-03 | Phase 28 (verification) | Pending |
| FIELD-04 | Phase 28 (verification) | Pending |
| CAL-01 | Phase 28 (verification) | Pending |
| CAL-02 | Phase 28 (verification) | Pending |
| CAL-03 | Phase 28 (verification) | Pending |
| CAL-04 | Phase 28 (verification) | Pending |
| REPORT-01 | Phase 28 (verification) | Pending |
| REPORT-02 | Phase 28 (verification) | Pending |
| REPORT-03 | Phase 28 (verification) | Pending |
| REPORT-04 | Phase 28 (verification) | Pending |
| VIDEO-01 | Phase 22 (TBD) | Not planned |

**Coverage:**
- v2.1 requirements: 28 total (27 carryover + 1 Phase 22)
- Mapped to phases: 28
- Unmapped: 0
- Shipped in v2.0: 0 (see `milestones/v2.0-REQUIREMENTS.md` for AI/PORTAL/MAP — 12 shipped)

---
*v2.1 requirements carried forward 2026-04-14 after v2.0 milestone scope reduction. See `milestones/v2.0-MILESTONE-AUDIT.md` for the audit that drove the scope change.*
