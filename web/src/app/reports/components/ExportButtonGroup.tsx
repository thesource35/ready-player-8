"use client";

// Export button group — Phase 19 Plan 07
// D-47: PDF, CSV, Excel, PowerPoint, JSON export buttons
// D-48: CSV dropdown with Summary and Detailed options
// D-64b: Share Report button with clipboard copy
// D-34m: Export All Reports batch button

import { useState, useCallback } from "react";
import { generateReportPDF, generateRollupPDF, generateFilename } from "@/lib/reports/pdf-generator";
import type { ProjectReport, PortfolioRollup } from "@/lib/reports/types";

// ---------- Types ----------

type ExportButtonGroupProps = {
  reportData: ProjectReport | PortfolioRollup;
  reportRef: React.RefObject<HTMLDivElement | null>;
  projectName: string;
  onPreviewPDF?: () => void;
  isRollup?: boolean;
};

type ExportStatus = "idle" | "exporting" | "success" | "error";

// ---------- Helpers ----------

/** Trigger a browser download from a Blob */
function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

/** D-47: Convert report data to formatted JSON */
function exportJSON(data: ProjectReport | PortfolioRollup, projectName: string): void {
  const json = JSON.stringify(data, null, 2);
  const blob = new Blob([json], { type: "application/json" });
  const safeName = projectName.replace(/[^a-zA-Z0-9\s-]/g, "").replace(/\s+/g, "-");
  const date = new Date().toISOString().slice(0, 10);
  downloadBlob(blob, `${safeName}-Report-${date}.json`);
}

/** D-48: Convert report data to CSV (summary or detailed) */
function exportCSV(
  data: ProjectReport | PortfolioRollup,
  projectName: string,
  detailed: boolean,
): void {
  const rows: string[][] = [];
  const safeName = projectName.replace(/[^a-zA-Z0-9\s-]/g, "").replace(/\s+/g, "-");
  const date = new Date().toISOString().slice(0, 10);

  if ("project_id" in data) {
    // Single project report
    const report = data as ProjectReport;
    if (detailed) {
      rows.push(["Section", "Metric", "Value"]);
      rows.push(["Project", "Name", report.project_name]);
      rows.push(["Project", "Client", report.client_name]);
      rows.push(["Health", "Score", String(report.health.score)]);
      rows.push(["Health", "Status", report.health.label]);
      if (report.budget) {
        rows.push(["Budget", "Contract Value", String(report.budget.contractValue)]);
        rows.push(["Budget", "Total Billed", String(report.budget.totalBilled)]);
        rows.push(["Budget", "Percent Complete", String(report.budget.percentComplete)]);
        rows.push(["Budget", "Change Order Net", String(report.budget.changeOrderNet)]);
        rows.push(["Budget", "Retainage", String(report.budget.retainage)]);
      }
      if (report.safety) {
        rows.push(["Safety", "Total Incidents", String(report.safety.totalIncidents)]);
        rows.push(["Safety", "Days Since Last", String(report.safety.daysSinceLastIncident)]);
      }
      if (report.team) {
        rows.push(["Team", "Member Count", String(report.team.memberCount)]);
      }
    } else {
      // Summary: flat single-row table
      rows.push(["Project", "Client", "Health", "Score", "Budget", "Billed", "Safety Incidents", "Team Size"]);
      rows.push([
        report.project_name,
        report.client_name,
        report.health.label,
        String(report.health.score),
        String(report.budget?.contractValue ?? 0),
        String(report.budget?.totalBilled ?? 0),
        String(report.safety?.totalIncidents ?? 0),
        String(report.team?.memberCount ?? 0),
      ]);
    }
  } else {
    // Portfolio rollup
    const rollup = data as PortfolioRollup;
    rows.push(["Project", "Status", "Health", "Score", "Contract Value", "Billed", "Complete %", "Open Issues", "Safety Incidents"]);
    for (const p of rollup.projects) {
      rows.push([
        p.name,
        p.status,
        p.health.label,
        String(p.health.score),
        String(p.contractValue),
        String(p.billed),
        String(p.percentComplete),
        String(p.openIssues),
        String(p.safetyIncidents),
      ]);
    }
  }

  const csvContent = rows.map((row) => row.map((cell) => `"${cell.replace(/"/g, '""')}"`).join(",")).join("\n");
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8" });
  const suffix = detailed ? "Detailed" : "Summary";
  downloadBlob(blob, `${safeName}-Report-${suffix}-${date}.csv`);
}

/** D-47: Export to Excel using xlsx (SheetJS) */
async function exportExcel(
  data: ProjectReport | PortfolioRollup,
  projectName: string,
): Promise<void> {
  const XLSX = await import("xlsx");
  const wb = XLSX.utils.book_new();
  const safeName = projectName.replace(/[^a-zA-Z0-9\s-]/g, "").replace(/\s+/g, "-");
  const date = new Date().toISOString().slice(0, 10);

  if ("project_id" in data) {
    const report = data as ProjectReport;

    // Overview sheet
    const overview = [
      { Field: "Project", Value: report.project_name },
      { Field: "Client", Value: report.client_name },
      { Field: "Health Score", Value: report.health.score },
      { Field: "Health Status", Value: report.health.label },
      { Field: "Generated", Value: report.generated_at },
    ];
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(overview), "Overview");

    // Budget sheet
    if (report.budget) {
      const budgetRows = [
        { Metric: "Contract Value", Value: report.budget.contractValue },
        { Metric: "Total Billed", Value: report.budget.totalBilled },
        { Metric: "Percent Complete", Value: report.budget.percentComplete },
        { Metric: "Change Order Net", Value: report.budget.changeOrderNet },
        { Metric: "Retainage", Value: report.budget.retainage },
        { Metric: "Spent", Value: report.budget.spent },
        { Metric: "Remaining", Value: report.budget.remaining },
      ];
      XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(budgetRows), "Budget");
    }

    // Safety sheet
    if (report.safety) {
      const safetyRows = report.safety.incidents.map((inc) => ({
        Description: inc.description,
        Severity: inc.severity,
        Date: inc.date,
      }));
      if (safetyRows.length > 0) {
        XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(safetyRows), "Safety");
      }
    }

    // Schedule sheet
    if (report.schedule) {
      const schedRows = report.schedule.milestones.map((m) => ({
        Milestone: m.name,
        "% Complete": m.percentComplete,
        Status: m.status,
      }));
      if (schedRows.length > 0) {
        XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(schedRows), "Schedule");
      }
    }
  } else {
    const rollup = data as PortfolioRollup;
    const rows = rollup.projects.map((p) => ({
      Project: p.name,
      Status: p.status,
      "Health Score": p.health.score,
      "Health Status": p.health.label,
      "Contract Value": p.contractValue,
      Billed: p.billed,
      "% Complete": p.percentComplete,
      "Open Issues": p.openIssues,
      "Safety Incidents": p.safetyIncidents,
    }));
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(rows), "Portfolio");
  }

  const buffer = XLSX.write(wb, { bookType: "xlsx", type: "array" });
  const blob = new Blob([buffer], { type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" });
  downloadBlob(blob, `${safeName}-Report-${date}.xlsx`);
}

/** D-47: Export to PowerPoint using pptxgenjs */
async function exportPowerPoint(
  data: ProjectReport | PortfolioRollup,
  projectName: string,
): Promise<void> {
  const PptxGenJS = (await import("pptxgenjs")).default;
  const pptx = new PptxGenJS();
  pptx.title = `${projectName} Report`;

  const safeName = projectName.replace(/[^a-zA-Z0-9\s-]/g, "").replace(/\s+/g, "-");
  const date = new Date().toISOString().slice(0, 10);

  // Title slide
  const titleSlide = pptx.addSlide();
  titleSlide.addText(`${projectName} Report`, {
    x: 0.5,
    y: 1.5,
    w: 9,
    h: 1.5,
    fontSize: 36,
    bold: true,
    color: "1A2332",
    align: "center",
  });
  titleSlide.addText(`Generated ${new Date().toLocaleDateString()}`, {
    x: 0.5,
    y: 3.0,
    w: 9,
    fontSize: 14,
    color: "9EBDC2",
    align: "center",
  });

  if ("project_id" in data) {
    const report = data as ProjectReport;

    // Health slide
    const healthSlide = pptx.addSlide();
    healthSlide.addText("Health Overview", { x: 0.5, y: 0.3, w: 9, fontSize: 24, bold: true, color: "1A2332" });
    healthSlide.addText(`Score: ${report.health.score}  |  Status: ${report.health.label}`, {
      x: 0.5, y: 1.2, w: 9, fontSize: 18, color: "333333",
    });

    // Budget slide
    if (report.budget) {
      const budgetSlide = pptx.addSlide();
      budgetSlide.addText("Budget & Financials", { x: 0.5, y: 0.3, w: 9, fontSize: 24, bold: true, color: "1A2332" });
      const budgetLines = [
        `Contract Value: $${report.budget.contractValue.toLocaleString()}`,
        `Total Billed: $${report.budget.totalBilled.toLocaleString()}`,
        `Change Orders: $${report.budget.changeOrderNet.toLocaleString()}`,
        `Completion: ${report.budget.percentComplete}%`,
      ];
      budgetSlide.addText(budgetLines.join("\n"), {
        x: 0.5, y: 1.2, w: 9, h: 3, fontSize: 16, color: "333333", lineSpacingMultiple: 1.5,
      });
    }

    // Safety slide
    if (report.safety) {
      const safetySlide = pptx.addSlide();
      safetySlide.addText("Safety", { x: 0.5, y: 0.3, w: 9, fontSize: 24, bold: true, color: "1A2332" });
      safetySlide.addText(
        `Total Incidents: ${report.safety.totalIncidents}\nDays Since Last: ${report.safety.daysSinceLastIncident}`,
        { x: 0.5, y: 1.2, w: 9, fontSize: 16, color: "333333", lineSpacingMultiple: 1.5 },
      );
    }
  } else {
    const rollup = data as PortfolioRollup;
    const summarySlide = pptx.addSlide();
    summarySlide.addText("Portfolio Summary", { x: 0.5, y: 0.3, w: 9, fontSize: 24, bold: true, color: "1A2332" });

    const tableData: Array<Array<{ text: string; options?: { bold?: boolean; fontSize?: number } }>> = [
      [
        { text: "Project", options: { bold: true, fontSize: 10 } },
        { text: "Health", options: { bold: true, fontSize: 10 } },
        { text: "Contract", options: { bold: true, fontSize: 10 } },
        { text: "% Complete", options: { bold: true, fontSize: 10 } },
      ],
    ];
    for (const p of rollup.projects.slice(0, 10)) {
      tableData.push([
        { text: p.name, options: { fontSize: 9 } },
        { text: `${p.health.score} (${p.health.label})`, options: { fontSize: 9 } },
        { text: `$${p.contractValue.toLocaleString()}`, options: { fontSize: 9 } },
        { text: `${p.percentComplete}%`, options: { fontSize: 9 } },
      ]);
    }

    summarySlide.addTable(tableData, { x: 0.5, y: 1.0, w: 9 });
  }

  const pptxBlob = await pptx.write({ outputType: "blob" }) as Blob;
  downloadBlob(pptxBlob, `${safeName}-Report-${date}.pptx`);
}

// ---------- Button Styles ----------

const primaryStyle: React.CSSProperties = {
  background: "var(--accent)",
  color: "var(--bg)",
  fontSize: 12,
  fontWeight: 800,
  padding: "8px 24px",
  borderRadius: 8,
  border: "none",
  cursor: "pointer",
};

const secondaryStyle: React.CSSProperties = {
  background: "var(--surface)",
  color: "var(--text)",
  fontSize: 8,
  fontWeight: 800,
  padding: "8px 16px",
  borderRadius: 8,
  border: "1px solid var(--border)",
  cursor: "pointer",
  position: "relative" as const,
};

// ---------- Component ----------

export function ExportButtonGroup({
  reportData,
  reportRef,
  projectName,
  onPreviewPDF,
  isRollup = false,
}: ExportButtonGroupProps) {
  const [pdfStatus, setPdfStatus] = useState<ExportStatus>("idle");
  const [excelStatus, setExcelStatus] = useState<ExportStatus>("idle");
  const [pptxStatus, setPptxStatus] = useState<ExportStatus>("idle");
  const [csvDropdown, setCsvDropdown] = useState(false);
  const [shareToast, setShareToast] = useState(false);
  const [batchExporting, setBatchExporting] = useState(false);

  // D-29: Export PDF — opens preview or direct download
  const handleExportPDF = useCallback(async () => {
    if (onPreviewPDF) {
      onPreviewPDF();
      return;
    }

    if (!reportRef.current) return;
    setPdfStatus("exporting");
    try {
      const generator = isRollup ? generateRollupPDF : generateReportPDF;
      const blob = await generator({
        reportElement: reportRef.current,
        projectName,
      });
      downloadBlob(blob, generateFilename(projectName));
      setPdfStatus("success");
      setTimeout(() => setPdfStatus("idle"), 2000);
    } catch (err) {
      console.error("[ExportButtonGroup] PDF export failed:", err);
      setPdfStatus("error");
      setTimeout(() => setPdfStatus("idle"), 3000);
    }
  }, [reportRef, projectName, onPreviewPDF, isRollup]);

  // D-47: Export Excel
  const handleExportExcel = useCallback(async () => {
    setExcelStatus("exporting");
    try {
      await exportExcel(reportData, projectName);
      setExcelStatus("success");
      setTimeout(() => setExcelStatus("idle"), 2000);
    } catch (err) {
      console.error("[ExportButtonGroup] Excel export failed:", err);
      setExcelStatus("error");
      setTimeout(() => setExcelStatus("idle"), 3000);
    }
  }, [reportData, projectName]);

  // D-47: Export PowerPoint
  const handleExportPPTX = useCallback(async () => {
    setPptxStatus("exporting");
    try {
      await exportPowerPoint(reportData, projectName);
      setPptxStatus("success");
      setTimeout(() => setPptxStatus("idle"), 2000);
    } catch (err) {
      console.error("[ExportButtonGroup] PPTX export failed:", err);
      setPptxStatus("error");
      setTimeout(() => setPptxStatus("idle"), 3000);
    }
  }, [reportData, projectName]);

  // D-64b: Share Report — copy link to clipboard
  const handleShare = useCallback(async () => {
    try {
      const url = window.location.href;
      await navigator.clipboard.writeText(url);
      setShareToast(true);
      setTimeout(() => setShareToast(false), 2000);
    } catch {
      // Fallback for clipboard API
      const textArea = document.createElement("textarea");
      textArea.value = window.location.href;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      setShareToast(true);
      setTimeout(() => setShareToast(false), 2000);
    }
  }, []);

  // D-34m: Export All Reports (batch)
  const handleBatchExport = useCallback(async () => {
    setBatchExporting(true);
    try {
      // Export all formats in sequence
      if (reportRef.current) {
        const generator = isRollup ? generateRollupPDF : generateReportPDF;
        const pdfBlob = await generator({
          reportElement: reportRef.current,
          projectName,
        });
        downloadBlob(pdfBlob, generateFilename(projectName));
      }
      exportCSV(reportData, projectName, false);
      exportCSV(reportData, projectName, true);
      await exportExcel(reportData, projectName);
      exportJSON(reportData, projectName);
    } catch (err) {
      console.error("[ExportButtonGroup] Batch export failed:", err);
    } finally {
      setBatchExporting(false);
    }
  }, [reportRef, reportData, projectName, isRollup]);

  const statusLabel = (status: ExportStatus, defaultLabel: string): string => {
    switch (status) {
      case "exporting":
        return "Exporting...";
      case "success":
        return "Done!";
      case "error":
        return "Failed";
      default:
        return defaultLabel;
    }
  };

  return (
    <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
      {/* Primary CTA: Export PDF */}
      <button
        onClick={handleExportPDF}
        disabled={pdfStatus === "exporting"}
        aria-busy={pdfStatus === "exporting"}
        style={{
          ...primaryStyle,
          opacity: pdfStatus === "exporting" ? 0.7 : 1,
        }}
      >
        {statusLabel(pdfStatus, "Export PDF")}
      </button>

      {/* D-48: CSV dropdown with Summary/Detailed options */}
      <div style={{ position: "relative" }}>
        <button
          onClick={() => setCsvDropdown(!csvDropdown)}
          style={secondaryStyle}
          aria-expanded={csvDropdown}
          aria-haspopup="true"
        >
          Export CSV &#9662;
        </button>
        {csvDropdown && (
          <div
            style={{
              position: "absolute",
              top: "100%",
              left: 0,
              marginTop: 4,
              background: "var(--panel)",
              border: "1px solid var(--border)",
              borderRadius: 8,
              overflow: "hidden",
              zIndex: 100,
              minWidth: 140,
            }}
          >
            <button
              onClick={() => {
                exportCSV(reportData, projectName, false);
                setCsvDropdown(false);
              }}
              style={{
                display: "block",
                width: "100%",
                padding: "8px 12px",
                fontSize: 10,
                fontWeight: 600,
                color: "var(--text)",
                background: "transparent",
                border: "none",
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              Summary CSV
            </button>
            <button
              onClick={() => {
                exportCSV(reportData, projectName, true);
                setCsvDropdown(false);
              }}
              style={{
                display: "block",
                width: "100%",
                padding: "8px 12px",
                fontSize: 10,
                fontWeight: 600,
                color: "var(--text)",
                background: "transparent",
                border: "none",
                borderTop: "1px solid var(--border)",
                cursor: "pointer",
                textAlign: "left",
              }}
            >
              Detailed CSV
            </button>
          </div>
        )}
      </div>

      {/* D-47: Export Excel */}
      <button
        onClick={handleExportExcel}
        disabled={excelStatus === "exporting"}
        style={{
          ...secondaryStyle,
          opacity: excelStatus === "exporting" ? 0.7 : 1,
        }}
      >
        {statusLabel(excelStatus, "Export Excel")}
      </button>

      {/* D-47: Export PowerPoint */}
      <button
        onClick={handleExportPPTX}
        disabled={pptxStatus === "exporting"}
        style={{
          ...secondaryStyle,
          opacity: pptxStatus === "exporting" ? 0.7 : 1,
        }}
      >
        {statusLabel(pptxStatus, "Export PowerPoint")}
      </button>

      {/* D-47: Export JSON */}
      <button
        onClick={() => exportJSON(reportData, projectName)}
        style={secondaryStyle}
      >
        Export JSON
      </button>

      {/* D-64b: Share Report */}
      <div style={{ position: "relative" }}>
        <button onClick={handleShare} style={secondaryStyle}>
          Share Report
        </button>
        {shareToast && (
          <div
            role="status"
            aria-live="polite"
            style={{
              position: "absolute",
              top: "100%",
              left: "50%",
              transform: "translateX(-50%)",
              marginTop: 4,
              background: "var(--green)",
              color: "#fff",
              fontSize: 8,
              fontWeight: 800,
              padding: "4px 10px",
              borderRadius: 6,
              whiteSpace: "nowrap",
              zIndex: 100,
            }}
          >
            Link copied
          </div>
        )}
      </div>

      {/* D-34m: Export All Reports (batch) */}
      <button
        onClick={handleBatchExport}
        disabled={batchExporting}
        style={{
          ...secondaryStyle,
          opacity: batchExporting ? 0.7 : 1,
        }}
      >
        {batchExporting ? "Exporting All..." : "Export All Reports"}
      </button>
    </div>
  );
}
