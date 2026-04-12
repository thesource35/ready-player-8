---
phase: 19
slug: reporting-dashboards
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-11
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest 3.2.4 (web) + XCTest (iOS) |
| **Config file** | `web/vitest.config.ts` |
| **Quick run command** | `cd web && npx vitest run --reporter=verbose src/lib/reports` |
| **Full suite command** | `cd web && npx vitest run` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd web && npx vitest run --reporter=verbose src/lib/reports`
- **After every plan wave:** Run `cd web && npx vitest run`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-T1 | 01 | 0 | REPORT-01, REPORT-02, REPORT-04 | T-19-01 | Budget parsing clamps to valid ranges | setup | `cd web && node -e "require('recharts'); require('jspdf'); require('html2canvas')" && test -f src/lib/reports/types.ts && test -f src/lib/reports/constants.ts && test -f src/lib/reports/chart-config.ts` | pending | ⬜ |
| 19-01-T2 | 01 | 0 | REPORT-01 | T-19-01, T-19-02 | Aggregation functions handle null/empty inputs | unit (TDD) | `cd web && npx vitest run src/lib/reports/aggregation.test.ts --reporter=verbose` | pending (created by this task) | ⬜ |
| 19-02-T1 | 02 | 1 | REPORT-01 | T-19-03, T-19-06 | Auth check first, RLS enforced | integration | `cd web && npx tsc --noEmit src/app/api/reports/project/[id]/route.ts` | pending | ⬜ |
| 19-02-T2 | 02 | 1 | REPORT-02 | T-19-04, T-19-05 | Sort column whitelist, auth required | integration | `cd web && test -f src/app/api/reports/rollup/route.ts && test -f src/app/api/reports/health/route.ts && grep -c "export async function GET" src/app/api/reports/rollup/route.ts` | pending | ⬜ |
| 19-03-T1 | 03 | 2 | REPORT-01, REPORT-02, REPORT-04 | T-19-07 | Client renders only API-returned data | component | `cd web && ls src/app/reports/components/*.tsx \| wc -l && npx tsc --noEmit` | pending | ⬜ |
| 19-03-T2 | 03 | 2 | REPORT-01, REPORT-02 | T-19-08 | URL param validated by API | page | `cd web && test -f src/app/reports/page.tsx && test -f src/app/reports/project/[id]/page.tsx && test -f src/app/reports/rollup/page.tsx && grep "reports" src/app/layout.tsx` | pending | ⬜ |
| 19-03-T3 | 03 | 2 | REPORT-01, REPORT-04 | -- | Visual verification | checkpoint | `cd web && npx next build` | pending | ⬜ |
| 19-04-T1 | 04 | 3 | REPORT-03 | T-19-09, T-19-10 | Client-side generation, no external input | unit | `cd web && test -f src/lib/reports/pdf-generator.ts && test -f src/app/reports/components/ExportButton.tsx && grep -c "generateReportPDF" src/lib/reports/pdf-generator.ts` | pending | ⬜ |
| 19-04-T2 | 04 | 3 | REPORT-03 | T-19-10 | PDF from user's own auth data | integration | `cd web && grep -c "ExportButton" src/app/reports/project/[id]/page.tsx && grep -c "ExportButton" src/app/reports/rollup/page.tsx` | pending | ⬜ |
| 19-05-T1 | 05 | 3 | REPORT-01, REPORT-02, REPORT-03, REPORT-04 | T-19-11, T-19-13 | Auth token in headers, Codable validation | compile | `cd "/Users/beverlyhunter/Desktop/ready player 8" && test -f "ready player 8/ReportsView.swift" && grep -c "struct ReportsView" "ready player 8/ReportsView.swift" && grep -c "case reports" "ready player 8/ContentView.swift"` | pending | ⬜ |
| 19-05-T2 | 05 | 3 | REPORT-04, REPORT-03 | T-19-12 | PDF temp file in temporaryDirectory | compile | `cd "/Users/beverlyhunter/Desktop/ready player 8" && test -f "ready player 8/ReportCharts.swift" && test -f "ready player 8/ReportPDFGenerator.swift" && grep -c "SectorMark" "ready player 8/ReportCharts.swift"` | pending | ⬜ |
| 19-05-T3 | 05 | 3 | REPORT-01 | T-19-11 | WebURL validated before API calls | compile | `cd "/Users/beverlyhunter/Desktop/ready player 8" && grep -c "Reports.WebURL" "ready player 8/ContentView.swift"` | pending | ⬜ |

*Status: ⬜ pending -- ✅ green -- ❌ red -- ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `web/src/lib/reports/aggregation.test.ts` -- test file created by Plan 19-01 Task 2 (TDD plan)
- [ ] `recharts` installed -- charting library dependency (Plan 19-01 Task 1)
- [ ] `jspdf` + `html2canvas` installed -- PDF generation dependencies (Plan 19-01 Task 1)
- [ ] `web/src/lib/reports/types.ts` -- type contracts (Plan 19-01 Task 1)
- [ ] `web/src/lib/reports/constants.ts` -- shared constants (Plan 19-01 Task 1)

*Wave 0 test infrastructure is covered by Plan 19-01 which creates both the test files and installs dependencies.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PDF visual fidelity | REPORT-03 | PDF rendering varies by browser | Open generated PDF, verify charts render correctly, check page breaks |
| Chart interactivity | REPORT-04 | Requires visual + mouse interaction | Hover tooltips, click-to-filter, zoom/pan on time series charts |
| iOS chart rendering | REPORT-04 | SwiftUI Charts requires simulator | Run on iOS simulator, verify all chart types render |
| Email delivery | REPORT-02 | Requires Resend sandbox (Phase 19b) | Trigger scheduled report, verify email received with PDF attachment |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (Plan 19-01 creates test files)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
