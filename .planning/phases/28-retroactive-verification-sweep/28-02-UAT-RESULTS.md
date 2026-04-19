# Phase 28 UAT Walk-Through Results

**Session date:** TBD (single batched session per D-07 — awaiting user availability)
**Session duration:** TBD minutes
**Items walked:** 22 (aggregated from human_verification blocks in 28-01's six VERIFICATION.md files)
**Pass:** 0 / **Fail:** 0 / **Defer:** 0 / **Pending:** 22

## Session Pre-Requisites

Before starting the walk-through, confirm:
- iOS Simulator (iPhone 17 Pro, iPhoneSimulator26.2 SDK) booted with the latest `main` build installed
- Web dev server running at `http://localhost:3000` (`cd web && npm run dev`)
- Supabase credentials configured in iOS Integration Hub + web `.env.local`
- Seeded test project with: budget/schedule/safety/team data + a cs_contracts row with bid_deadline + at least one cs_certifications row expiring in ≤30 days
- For NOTIF-05 deferred items: note that real-device push delivery requires Apple Developer portal Push Notifications capability toggle (out of simulator scope)

## UAT Results

| Phase | UAT item | Expected | Result | Notes |
|-------|----------|----------|--------|-------|
| 13 | Upload a PDF and a JPEG to a project entity from the web (/projects/[id]) using the AttachmentList UploadButton | Both files appear in the attachment list with filename, size, MIME type; clicking the row opens DocumentPreview inline (iframe for PDF, img for JPEG) | Pending | |
| 13 | Upload a HEIC photo from iPhone simulator (or real device) via DocumentAttachmentsView on a project, RFI, submittal, and change order | HEIC is converted to JPEG via HEICConverter before upload; the resulting attachment is visible on all 4 entity detail surfaces with correct MIME type image/jpeg; preview opens via PDFKit/AsyncImage | Pending | |
| 13 | Upload a new version of an existing document via /documents/[chainId]/versions on web | Version list shows the prior version with is_current=false and the new version with is_current=true; prior content is still downloadable via signed URL; version_chain_id links both rows | Pending | |
| 13 | Oversized upload (>50MB) and unsupported MIME (e.g. .exe) rejection flow | Web returns 413/415 with a user-readable error toast; iOS surfaces AppError.fileTooLarge / AppError.unsupportedFileType via the Retry affordance | Pending | |
| 14 | Open a project's Activity tab on web (/projects/[id]/activity) after uploading a document via Phase 13 UI | Chronological activity timeline shows the document_uploaded event with the DOC badge, filename, and historical indicator if the event is from the backfill. Also shows project/RFI/change-order events per Phase 14-01 triggers. | Pending | |
| 14 | iOS: install build on a real device, accept the notification permission prompt, sign in, and trigger a cert-expiry event by setting a cs_certifications.expires_at 30 days in the future | iOS receives an APNs push via the Phase 25 cert-expiry-scan Edge Function with the VIEW_CERT category action; tapping the notification opens the Certifications tab | Pending | |
| 15 | iOS: open the app on simulator, tap the TEAM tab, confirm Members/Assignments sub-views render; tap CERTS, confirm CertificationsView with escalating colors; tap DAILY CREW, confirm the picker selects a real project and save-persists via upsert | All three orphaned-from-audit views are reachable via NavTab; DailyCrew save returns 200/204 (not 409) on second-save | Pending | |
| 15 | Web: open /team with a signed-in user with a cs_team_members row, confirm Members table renders; navigate to /team/assignments, /team/certifications, confirm red/amber color-coding on expiring certs | Three /team sub-pages render real rows; cert near expiration shows amber, expired shows red | Pending | |
| 15 | Cert expiry end-to-end: insert a cs_certifications row with expires_at = today + 30 days and status = 'active'; wait for the 13:15 UTC pg_cron cert-expiry-scan run (or invoke manually); verify cs_activity_events row is created with category='assigned_task' and cs_notifications downstream | cert-expiry-scan inserts exactly one cs_activity_events row for the 30-day threshold; fanout creates cs_notifications rows for project assignees; on iOS push cert-specific title + body arrives if Apple Developer portal is configured (Phase 25 human item) | Pending | |
| 16 | 16-UAT.md test 2 retest: iOS GPS photo capture after a4397f9 fix | Field → CAPTURE button in FieldOpsView presents FieldPhotoCaptureView sheet; shutter captures PhotosPicker photo; CLLocationProvider resolves a fresh fix (<60s) with lat/lng/accuracy; photo uploads via DocumentSyncManager with gps_source=fresh (or stale_last_known / manual_pin) and appears in /field/photos web browser | Pending | |
| 16 | 16-UAT.md test 3 retest: web /field/photos browser after a4397f9 upload pipeline fix | Grid of project photos loads with thumbnails, captured_at timestamp, and stale-GPS badge (🕒) where applicable; empty state CTA if no photos | Pending | |
| 16 | 16-UAT.md test 8 retest: iOS DailyLogV2View entry point after 6293af1 fix | Field → Daily Log button in FieldOpsView (line 137 DailyLogV2View presentation) renders the template-resolved daily log for today; executive role hides crew_on_site and visitors; save round-trips and returns 409 on second-save-same-day | Pending | |
| 16 | FIELD-03 annotation UX spot-check on iOS (tests 5 already passed per 16-UAT but belt-and-suspenders recommended after any PencilKit changes) | Open a photo in PhotoAnnotateView.swift → draw strokes → Save → reopen photo → strokes reappear deterministically; original photo unchanged | Pending | |
| 17 | Open /schedule on web with seeded cs_project_tasks rows and navigate the rollup → drill-in → Gantt → agenda view chain | Default view (?view=rollup) renders one swim lane per project with task mini-bars; clicking a lane label navigates to ?view=gantt&project=ID; GanttChart renders bars + SVG dependency arrows + milestone diamonds; agenda view groups day-by-day | Pending | |
| 17 | Drag-to-reschedule on GanttChart: pointerdown on a task bar, pointermove +60px at DAY_WIDTH=20, pointerup | Bar slides +3 days optimistically; PATCH /api/calendar/tasks persists start_date/end_date; refresh the page — dates remain shifted; duration unchanged; conflict badge (⚠) appears if successor.start < predecessor.end but save still succeeds (non-blocking, D-08) | Pending | |
| 17 | iOS: open Schedule tab → Agenda subtab (tabs[1]), confirm day-grouped task list renders; tap a task → DatePicker sheet opens → reschedule date → save | AgendaListView displays tasks + milestones + events grouped by date; TaskDetailSheet DatePicker persists through /api/calendar/tasks PATCH; revert on HTTP failure | Pending | |
| 17 | Milestone highlighting: seed a project with a cs_contracts.bid_deadline and an end_date; confirm both render as milestone diamonds on the timeline | Milestone markers visible on RollupTimeline + GanttChart header; CAL-03 visual sanity check | Pending | |
| 19 | Generate single-project summary report from /reports/project/[id] with a seeded project having budget/schedule/safety/team data | Report page renders all four report sections (Budget, Schedule, Safety, Team) with real Supabase data; HealthBadge + StatCard + chart wrappers render; no console errors | Pending | |
| 19 | View cross-project rollup dashboard at /reports/rollup | Portfolio rollup shows KPI cards, status filter, project list with health badges, monthly spend chart (PortfolioCharts.tsx) | Pending | |
| 19 | Export report to PDF via ExportButtonGroup → PDF button; verify TOC, header/footer branding, executive summary option, password protection option, confidentiality toggle | jsPDF + html2canvas produces a multi-page PDF with headers, footers, smart page breaks, optional executive summary, optional password, and DRAFT watermark if enabled | Pending | |
| 19 | Chart visualization walk-through: open /reports/project/[id] and interact with each of the 5 chart types | BudgetPieChart donut with center %; ScheduleBarChart milestones capped at 8; SafetyLineChart red stroke with dots; ActivityTrendChart purple area; TeamUtilizationChart role bars + workload bars. Tooltips render on hover; ChartExportButton PNG/SVG download works. | Pending | |
| 19 | iOS Reports tab (NavTab.reports in field group) — tap through segmented control Project/Portfolio, view 4 SwiftUI Charts (BudgetPieChartView SectorMark, ScheduleBarChartView BarMark, SafetyLineChartView LineMark, ActivityTrendChartView AreaMark) with pinch-to-zoom + haptics | iOS Reports tab reachable via ContentView NavTab; SwiftUI Charts render with data; pinch-to-zoom works clamped 1-3x; VoiceOver labels read correctly | Pending | |

## Rules of Engagement (Phase B)

1. User states `pass`, `fail`, or `defer` for each row. Claude live-edits the Result column.
2. Failed items must include a user-quoted symptom description in Notes (min 5 words).
3. Deferred items must include a deferral reason in Notes (e.g., "no iOS push certs loaded locally", "not in dev environment").
4. No mid-session halts for bug fixes — failed items become follow-up work via existing or newly appended ROADMAP remediation phases.
5. Session ends when every row has a non-Pending Result.

## Phase C — Post-Session Reconciliation (after user verdicts recorded)

1. Tally Pass/Fail/Defer counts in header.
2. REQUIREMENTS.md tick flips:
   - Any `[~]` Partial that received `pass` → `[x]` Satisfied; Traceability row `Phase 28 (verified)`
   - Any `[x]` or `[~]` that received `fail` → `[ ]` Unsatisfied; Traceability row → matching remediation phase; ROADMAP.md Phase 30+ amended if new failing ID
   - Any `[~]` that received `defer` → stays `[~]` Partial; Traceability row annotated `UAT deferred <reason>`
3. Stage edits for commit.

---

_Aggregated from 28-01 VERIFICATION.md files: 13 (4 items) + 14 (2 items) + 15 (3 items) + 16 (4 items) + 17 (4 items) + 19 (5 items) = 22 items._
_Created: 2026-04-19T16:59:02Z — awaiting single batched UAT session with user._
