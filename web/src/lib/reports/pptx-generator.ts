// PowerPoint export generator using pptxgenjs
// D-47: Each section as a slide with chart images

import PptxGenJS from "pptxgenjs";
import type { ProjectReport } from "./types";

// ---------------------------------------------------------------------------
// Color constants matching ConstructionOS theme
// ---------------------------------------------------------------------------

const COLORS = {
  bg: "0a1628",
  surface: "111827",
  text: "e0e0e0",
  muted: "6b7280",
  accent: "d4a843",
  green: "10b981",
  gold: "f59e0b",
  red: "ef4444",
  white: "ffffff",
};

const healthColorMap: Record<string, string> = {
  green: COLORS.green,
  gold: COLORS.gold,
  red: COLORS.red,
};

// ---------------------------------------------------------------------------
// D-47: Generate PowerPoint presentation
// Each report section becomes a slide. Chart images are optional base64.
// ---------------------------------------------------------------------------

export type ChartImages = {
  budget?: string;   // base64 PNG of budget pie chart
  schedule?: string; // base64 PNG of schedule bar chart
  safety?: string;   // base64 PNG of safety line chart
};

export async function generatePPTX(
  report: ProjectReport,
  chartImages?: ChartImages
): Promise<Uint8Array> {
  const pptx = new PptxGenJS();

  pptx.author = "ConstructionOS";
  pptx.title = `${report.project_name} Report`;
  pptx.subject = "Project Report";

  // Slide 1: Title slide with project name, health score, date
  const titleSlide = pptx.addSlide();
  titleSlide.background = { color: COLORS.bg };
  titleSlide.addText("CONSTRUCTIONOS", {
    x: 0.5,
    y: 0.5,
    w: 9,
    h: 0.4,
    fontSize: 11,
    color: COLORS.muted,
    fontFace: "Arial",
    charSpacing: 4,
  });
  titleSlide.addText(report.project_name, {
    x: 0.5,
    y: 1.5,
    w: 9,
    h: 1,
    fontSize: 36,
    bold: true,
    color: COLORS.white,
    fontFace: "Arial",
  });
  titleSlide.addText(`Client: ${report.client_name}`, {
    x: 0.5,
    y: 2.6,
    w: 9,
    h: 0.4,
    fontSize: 16,
    color: COLORS.muted,
    fontFace: "Arial",
  });
  const hColor = healthColorMap[report.health.color] ?? COLORS.gold;
  titleSlide.addText(`Health: ${report.health.score} - ${report.health.label}`, {
    x: 0.5,
    y: 3.4,
    w: 9,
    h: 0.5,
    fontSize: 20,
    bold: true,
    color: hColor,
    fontFace: "Arial",
  });
  titleSlide.addText(`Generated: ${new Date(report.generated_at).toLocaleDateString()}`, {
    x: 0.5,
    y: 4.5,
    w: 9,
    h: 0.4,
    fontSize: 12,
    color: COLORS.muted,
    fontFace: "Arial",
  });

  // Slide 2: Budget overview with optional pie chart image
  if (report.budget) {
    const budgetSlide = pptx.addSlide();
    budgetSlide.background = { color: COLORS.bg };
    budgetSlide.addText("BUDGET OVERVIEW", {
      x: 0.5, y: 0.3, w: 9, h: 0.5,
      fontSize: 22, bold: true, color: COLORS.accent, fontFace: "Arial",
    });

    const b = report.budget;
    const fmt = (v: number) =>
      v >= 1_000_000
        ? `$${(v / 1_000_000).toFixed(2)}M`
        : `$${v.toLocaleString()}`;

    const budgetRows: Array<[string, string]> = [
      ["Contract Value", fmt(b.contractValue)],
      ["Total Billed", fmt(b.totalBilled)],
      ["% Complete", `${b.percentComplete.toFixed(1)}%`],
      ["Change Orders", fmt(b.changeOrderNet)],
      ["Remaining", fmt(b.remaining)],
      ["Retainage", fmt(b.retainage)],
    ];

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const tableRows: any[][] = budgetRows.map(([label, value]) => [
      { text: label, options: { fontSize: 14, color: COLORS.text, fontFace: "Arial" } },
      { text: value, options: { fontSize: 14, bold: true, color: COLORS.white, fontFace: "Arial", align: "right" } },
    ]);

    budgetSlide.addTable(tableRows, {
      x: 0.5, y: 1.2, w: 5, h: 3,
      border: { type: "none" },
      colW: [3, 2],
    });

    if (chartImages?.budget) {
      budgetSlide.addImage({
        data: chartImages.budget,
        x: 5.8, y: 1.2, w: 3.7, h: 3,
      });
    }
  }

  // Slide 3: Schedule with optional bar chart image
  if (report.schedule) {
    const scheduleSlide = pptx.addSlide();
    scheduleSlide.background = { color: COLORS.bg };
    scheduleSlide.addText("SCHEDULE", {
      x: 0.5, y: 0.3, w: 9, h: 0.5,
      fontSize: 22, bold: true, color: COLORS.accent, fontFace: "Arial",
    });

    const s = report.schedule;
    scheduleSlide.addText(
      `${s.totalCount - s.delayedCount} of ${s.totalCount} milestones on track`,
      {
        x: 0.5, y: 1.0, w: 9, h: 0.4,
        fontSize: 16, color: COLORS.text, fontFace: "Arial",
      }
    );

    // Top milestones table
    const milestoneRows = s.milestones.slice(0, 6).map((m) => [
      { text: m.name, options: { fontSize: 12, color: COLORS.text, fontFace: "Arial" } },
      { text: `${m.percentComplete}%`, options: { fontSize: 12, bold: true, color: m.percentComplete >= 100 ? COLORS.green : COLORS.gold, fontFace: "Arial", align: "right" as const } },
      { text: m.status, options: { fontSize: 12, color: COLORS.muted, fontFace: "Arial" } },
    ]);

    if (milestoneRows.length > 0) {
      scheduleSlide.addTable(milestoneRows, {
        x: 0.5, y: 1.6, w: 5, h: 2.5,
        border: { type: "none" },
        colW: [2.5, 1, 1.5],
      });
    }

    if (chartImages?.schedule) {
      scheduleSlide.addImage({
        data: chartImages.schedule,
        x: 5.8, y: 1.2, w: 3.7, h: 3,
      });
    }
  }

  // Slide 4: Safety with optional line chart image
  if (report.safety) {
    const safetySlide = pptx.addSlide();
    safetySlide.background = { color: COLORS.bg };
    safetySlide.addText("SAFETY", {
      x: 0.5, y: 0.3, w: 9, h: 0.5,
      fontSize: 22, bold: true, color: COLORS.accent, fontFace: "Arial",
    });

    const saf = report.safety;
    const safetyMetrics: Array<[string, string]> = [
      ["Total Incidents", String(saf.totalIncidents)],
      ["Days Since Last Incident", String(saf.daysSinceLastIncident)],
      ["Minor", String(saf.severityBreakdown.minor)],
      ["Moderate", String(saf.severityBreakdown.moderate)],
      ["Serious", String(saf.severityBreakdown.serious)],
    ];

    const safetyRows = safetyMetrics.map(([label, value]) => [
      { text: label, options: { fontSize: 14, color: COLORS.text, fontFace: "Arial" } },
      { text: value, options: { fontSize: 14, bold: true, color: COLORS.white, fontFace: "Arial", align: "right" as const } },
    ]);

    safetySlide.addTable(safetyRows, {
      x: 0.5, y: 1.2, w: 5, h: 2.5,
      border: { type: "none" },
      colW: [3, 2],
    });

    if (chartImages?.safety) {
      safetySlide.addImage({
        data: chartImages.safety,
        x: 5.8, y: 1.2, w: 3.7, h: 3,
      });
    }
  }

  // Slide 5: Team summary
  if (report.team) {
    const teamSlide = pptx.addSlide();
    teamSlide.background = { color: COLORS.bg };
    teamSlide.addText("TEAM", {
      x: 0.5, y: 0.3, w: 9, h: 0.5,
      fontSize: 22, bold: true, color: COLORS.accent, fontFace: "Arial",
    });

    const t = report.team;
    teamSlide.addText(`${t.memberCount} Team Members`, {
      x: 0.5, y: 1.0, w: 9, h: 0.5,
      fontSize: 18, color: COLORS.white, fontFace: "Arial",
    });

    // Role breakdown
    const roleEntries = Object.entries(t.roleBreakdown);
    if (roleEntries.length > 0) {
      const roleRows = roleEntries.map(([role, count]) => [
        { text: role, options: { fontSize: 13, color: COLORS.text, fontFace: "Arial" } },
        { text: String(count), options: { fontSize: 13, bold: true, color: COLORS.white, fontFace: "Arial", align: "right" as const } },
      ]);

      teamSlide.addTable(roleRows, {
        x: 0.5, y: 1.8, w: 4, h: 2,
        border: { type: "none" },
        colW: [2.5, 1.5],
      });
    }
  }

  // Slide 6: Key insights (if available)
  if (report.ai_insights) {
    const insightsSlide = pptx.addSlide();
    insightsSlide.background = { color: COLORS.bg };
    insightsSlide.addText("KEY INSIGHTS", {
      x: 0.5, y: 0.3, w: 9, h: 0.5,
      fontSize: 22, bold: true, color: COLORS.accent, fontFace: "Arial",
    });

    insightsSlide.addText(report.ai_insights.summary, {
      x: 0.5, y: 1.0, w: 9, h: 1,
      fontSize: 14, color: COLORS.text, fontFace: "Arial",
    });

    const recs = report.ai_insights.recommendations.slice(0, 5);
    recs.forEach((rec, i) => {
      insightsSlide.addText(`${rec.actionable ? "[Action]" : "[Info]"} ${rec.text}`, {
        x: 0.5, y: 2.2 + i * 0.5, w: 9, h: 0.4,
        fontSize: 12, color: rec.actionable ? COLORS.gold : COLORS.muted, fontFace: "Arial",
        bullet: true,
      });
    });
  }

  // Generate output as Uint8Array
  const output = await pptx.write({ outputType: "uint8array" });
  return output as Uint8Array;
}
