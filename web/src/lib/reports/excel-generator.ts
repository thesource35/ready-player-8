// Excel export generator using SheetJS (xlsx)
// D-47: xlsx with formatted columns, multiple sheets

import * as XLSX from "xlsx";
import type { ProjectReport } from "./types";

// ---------------------------------------------------------------------------
// D-47: Generate Excel workbook with multiple sheets
// ---------------------------------------------------------------------------

export function generateExcel(report: ProjectReport): Buffer {
  const wb = XLSX.utils.book_new();

  // Sheet 1: Summary — KPI metrics
  const summaryData = [
    ["Project Report Summary"],
    [],
    ["Project", report.project_name],
    ["Client", report.client_name],
    ["Health Score", report.health.score],
    ["Health Status", report.health.label],
    ["Generated", report.generated_at],
    [],
    ["Key Metrics"],
    ["Metric", "Value"],
    ["Contract Value", report.budget?.contractValue ?? 0],
    ["Total Billed", report.budget?.totalBilled ?? 0],
    ["% Complete", report.budget?.percentComplete ?? 0],
    ["Open Issues", report.issues?.totalOpen ?? 0],
    ["Safety Incidents", report.safety?.totalIncidents ?? 0],
  ];
  const summarySheet = XLSX.utils.aoa_to_sheet(summaryData);
  // Column widths
  summarySheet["!cols"] = [{ wch: 20 }, { wch: 30 }];
  XLSX.utils.book_append_sheet(wb, summarySheet, "Summary");

  // Sheet 2: Budget — financial details with formatted currency columns
  if (report.budget) {
    const b = report.budget;
    const budgetData = [
      ["Budget Details"],
      [],
      ["Metric", "Amount"],
      ["Contract Value", b.contractValue],
      ["Total Billed", b.totalBilled],
      ["% Complete", b.percentComplete],
      ["Change Order Net", b.changeOrderNet],
      ["Retainage", b.retainage],
      ["Spent", b.spent],
      ["Remaining", b.remaining],
    ];
    const budgetSheet = XLSX.utils.aoa_to_sheet(budgetData);
    budgetSheet["!cols"] = [{ wch: 20 }, { wch: 20 }];
    XLSX.utils.book_append_sheet(wb, budgetSheet, "Budget");
  }

  // Sheet 3: Schedule — milestones with % complete
  if (report.schedule) {
    const s = report.schedule;
    const scheduleData = [
      ["Schedule"],
      [],
      ["Total Milestones", s.totalCount],
      ["Delayed", s.delayedCount],
      [],
      ["Milestone", "% Complete", "Status"],
      ...s.milestones.map((m) => [m.name, m.percentComplete, m.status]),
    ];
    const scheduleSheet = XLSX.utils.aoa_to_sheet(scheduleData);
    scheduleSheet["!cols"] = [{ wch: 30 }, { wch: 15 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(wb, scheduleSheet, "Schedule");
  }

  // Sheet 4: Issues — RFIs and change orders
  if (report.issues) {
    const iss = report.issues;
    const issuesData = [
      ["Issues & Risks"],
      [],
      ["Open Issues", iss.totalOpen],
      ["Critical", iss.criticalOpen],
      [],
      ["RFIs"],
      ["ID", "Subject", "Status", "Created"],
      ...iss.rfis.map((r) => [r.id, r.subject, r.status, r.created_at]),
      [],
      ["Change Orders"],
      ["ID", "Description", "Amount", "Status"],
      ...iss.changeOrders.map((co) => [co.id, co.description, co.amount, co.status]),
    ];
    const issuesSheet = XLSX.utils.aoa_to_sheet(issuesData);
    issuesSheet["!cols"] = [{ wch: 15 }, { wch: 35 }, { wch: 15 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(wb, issuesSheet, "Issues");
  }

  // Sheet 5: Safety — incident data
  if (report.safety) {
    const saf = report.safety;
    const safetyData = [
      ["Safety"],
      [],
      ["Total Incidents", saf.totalIncidents],
      ["Days Since Last Incident", saf.daysSinceLastIncident],
      ["Minor", saf.severityBreakdown.minor],
      ["Moderate", saf.severityBreakdown.moderate],
      ["Serious", saf.severityBreakdown.serious],
      [],
      ["Incident Log"],
      ["ID", "Description", "Severity", "Date"],
      ...saf.incidents.map((inc) => [inc.id, inc.description, inc.severity, inc.date]),
    ];
    const safetySheet = XLSX.utils.aoa_to_sheet(safetyData);
    safetySheet["!cols"] = [{ wch: 15 }, { wch: 35 }, { wch: 12 }, { wch: 15 }];
    XLSX.utils.book_append_sheet(wb, safetySheet, "Safety");
  }

  // Sheet 6: Charts — placeholder for chart images (per RESEARCH.md pitfall 6)
  // Chart images must be rendered client-side and passed as base64.
  // This sheet provides a placeholder with instructions.
  const chartsData = [
    ["Charts"],
    [],
    ["Note: Chart images are generated client-side."],
    ["To include charts in Excel, use the client-side export"],
    ["which captures rendered chart images as base64."],
  ];
  const chartsSheet = XLSX.utils.aoa_to_sheet(chartsData);
  chartsSheet["!cols"] = [{ wch: 50 }];
  XLSX.utils.book_append_sheet(wb, chartsSheet, "Charts");

  // Write to buffer
  const buf = XLSX.write(wb, { type: "buffer", bookType: "xlsx" });
  return buf as Buffer;
}
