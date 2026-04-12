// CSV export generators for report data
// D-48: Summary and detailed CSV modes
// D-114: QuickBooks-compatible financial export format

import type { ProjectReport, BudgetSection, ScheduleSection, IssuesSection, SafetySection } from "./types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function escapeCSV(value: string | number | null | undefined): string {
  if (value === null || value === undefined) return "";
  const str = String(value);
  // Escape double quotes and wrap in quotes if contains comma, newline, or quote
  if (str.includes(",") || str.includes("\n") || str.includes('"')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function row(values: (string | number | null | undefined)[]): string {
  return values.map(escapeCSV).join(",");
}

// ---------------------------------------------------------------------------
// D-48: Summary CSV — flat table with key metrics as columns
// ---------------------------------------------------------------------------

export function generateSummaryCSV(report: ProjectReport): string {
  const lines: string[] = [];

  // Header
  lines.push(row([
    "Project",
    "Client",
    "Health Score",
    "Health Status",
    "Budget (Contract Value)",
    "Total Billed",
    "% Complete",
    "Change Order Net",
    "Open Issues",
    "Critical Issues",
    "Safety Incidents",
    "Days Since Last Incident",
    "Generated At",
  ]));

  // Data row
  const budget = report.budget;
  const issues = report.issues;
  const safety = report.safety;

  lines.push(row([
    report.project_name,
    report.client_name,
    report.health.score,
    report.health.label,
    budget?.contractValue ?? 0,
    budget?.totalBilled ?? 0,
    budget?.percentComplete ?? 0,
    budget?.changeOrderNet ?? 0,
    issues?.totalOpen ?? 0,
    issues?.criticalOpen ?? 0,
    safety?.totalIncidents ?? 0,
    safety?.daysSinceLastIncident ?? 0,
    report.generated_at,
  ]));

  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// D-48: Detailed CSV — multi-section with headers per section
// ---------------------------------------------------------------------------

export function generateDetailedCSV(report: ProjectReport): string {
  const lines: string[] = [];

  // Project header
  lines.push("# Project Report");
  lines.push(row(["Project", report.project_name]));
  lines.push(row(["Client", report.client_name]));
  lines.push(row(["Health Score", report.health.score]));
  lines.push(row(["Health Status", report.health.label]));
  lines.push(row(["Generated", report.generated_at]));
  lines.push("");

  // Budget section
  if (report.budget) {
    const b: BudgetSection = report.budget;
    lines.push("# Budget");
    lines.push(row(["Metric", "Value"]));
    lines.push(row(["Contract Value", b.contractValue]));
    lines.push(row(["Total Billed", b.totalBilled]));
    lines.push(row(["% Complete", b.percentComplete]));
    lines.push(row(["Change Order Net", b.changeOrderNet]));
    lines.push(row(["Retainage", b.retainage]));
    lines.push(row(["Spent", b.spent]));
    lines.push(row(["Remaining", b.remaining]));
    lines.push("");
  }

  // Schedule section
  if (report.schedule) {
    const s: ScheduleSection = report.schedule;
    lines.push("# Schedule");
    lines.push(row(["Milestone", "% Complete", "Status"]));
    for (const m of s.milestones) {
      lines.push(row([m.name, m.percentComplete, m.status]));
    }
    lines.push(row(["Total Milestones", s.totalCount]));
    lines.push(row(["Delayed", s.delayedCount]));
    lines.push("");
  }

  // Issues section
  if (report.issues) {
    const iss: IssuesSection = report.issues;
    lines.push("# RFIs");
    lines.push(row(["ID", "Subject", "Status", "Created"]));
    for (const r of iss.rfis) {
      lines.push(row([r.id, r.subject, r.status, r.created_at]));
    }
    lines.push("");
    lines.push("# Change Orders");
    lines.push(row(["ID", "Description", "Amount", "Status"]));
    for (const co of iss.changeOrders) {
      lines.push(row([co.id, co.description, co.amount, co.status]));
    }
    lines.push("");
  }

  // Safety section
  if (report.safety) {
    const saf: SafetySection = report.safety;
    lines.push("# Safety");
    lines.push(row(["Total Incidents", saf.totalIncidents]));
    lines.push(row(["Days Since Last", saf.daysSinceLastIncident]));
    lines.push(row(["Minor", saf.severityBreakdown.minor]));
    lines.push(row(["Moderate", saf.severityBreakdown.moderate]));
    lines.push(row(["Serious", saf.severityBreakdown.serious]));
    lines.push("");
    lines.push(row(["ID", "Description", "Severity", "Date"]));
    for (const inc of saf.incidents) {
      lines.push(row([inc.id, inc.description, inc.severity, inc.date]));
    }
    lines.push("");
  }

  return lines.join("\n");
}

// ---------------------------------------------------------------------------
// D-114: QuickBooks-compatible financial export
// Standard CSV with account/amount columns for import into QuickBooks
// ---------------------------------------------------------------------------

export function generateQuickBooksCSV(report: ProjectReport): string {
  const lines: string[] = [];

  // QuickBooks journal entry import format
  lines.push(row(["Date", "Account", "Description", "Debit", "Credit", "Memo"]));

  const date = report.generated_at.split("T")[0] ?? new Date().toISOString().split("T")[0];
  const projectName = report.project_name;

  if (report.budget) {
    const b = report.budget;
    // Contract revenue
    lines.push(row([date, "Accounts Receivable", `${projectName} - Contract Value`, b.contractValue, "", `Project: ${projectName}`]));
    lines.push(row([date, "Contract Revenue", `${projectName} - Contract Value`, "", b.contractValue, `Project: ${projectName}`]));

    // Billings
    if (b.totalBilled > 0) {
      lines.push(row([date, "Cash/Bank", `${projectName} - Billings Received`, b.totalBilled, "", `Project: ${projectName}`]));
      lines.push(row([date, "Accounts Receivable", `${projectName} - Billings Applied`, "", b.totalBilled, `Project: ${projectName}`]));
    }

    // Change orders
    if (b.changeOrderNet !== 0) {
      const isPositive = b.changeOrderNet > 0;
      lines.push(row([
        date,
        "Change Order Adjustments",
        `${projectName} - Change Orders`,
        isPositive ? b.changeOrderNet : "",
        isPositive ? "" : Math.abs(b.changeOrderNet),
        `Project: ${projectName}`,
      ]));
    }

    // Retainage
    if (b.retainage > 0) {
      lines.push(row([date, "Retainage Receivable", `${projectName} - Retainage`, b.retainage, "", `Project: ${projectName}`]));
    }
  }

  return lines.join("\n");
}
