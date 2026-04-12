// Report constants for Phase 19 — Reporting & Dashboards
// Health thresholds, chart colors, section labels, themes, and PDF settings.

// ---------- Health Thresholds (UI-SPEC health score color mapping) ----------

export const HEALTH_THRESHOLDS = {
  green: { min: 80 },
  gold: { min: 60 },
  red: { min: 0 },
} as const;

// ---------- Chart Colors (UI-SPEC chart color palette) ----------

export const CHART_COLORS = {
  primary: "#F29E3D",
  secondary: "#4AC4CC",
  positive: "#69D294",
  tertiary: "#8A8FCC",
  quaternary: "#FCC757",
  alert: "#D94D48",
} as const;

// ---------- Section Labels ----------

export const SECTION_LABELS: Record<string, string> = {
  health: "Health Score",
  budget: "Budget & Financials",
  schedule: "Schedule & Milestones",
  issues: "Issues & Risks",
  team: "Team & Activity",
  safety: "Safety",
  ai_insights: "AI Insights",
  documents: "Documents",
  photos: "Photos",
};

// ---------- Report Themes (D-109) ----------

export const REPORT_THEMES = {
  professional: {
    name: "Professional",
    headerBg: "#1A2332",
    headerText: "#FFFFFF",
    accentColor: "#F29E3D",
    bodyBg: "#FFFFFF",
    bodyText: "#1A2332",
    tableBorder: "#E5E7EB",
    tableHeaderBg: "#F3F4F6",
  },
  construction: {
    name: "Construction",
    headerBg: "#F29E3D",
    headerText: "#FFFFFF",
    accentColor: "#4AC4CC",
    bodyBg: "#FFFBF5",
    bodyText: "#1A2332",
    tableBorder: "#E8D5B7",
    tableHeaderBg: "#FFF3E0",
  },
  corporate: {
    name: "Corporate",
    headerBg: "#0F1C24",
    headerText: "#FFFFFF",
    accentColor: "#4AC4CC",
    bodyBg: "#FFFFFF",
    bodyText: "#0F1C24",
    tableBorder: "#D1D5DB",
    tableHeaderBg: "#EFF6FF",
  },
  minimal: {
    name: "Minimal",
    headerBg: "#FFFFFF",
    headerText: "#111827",
    accentColor: "#6B7280",
    bodyBg: "#FFFFFF",
    bodyText: "#374151",
    tableBorder: "#F3F4F6",
    tableHeaderBg: "#FAFAFA",
  },
  executive: {
    name: "Executive",
    headerBg: "#1E293B",
    headerText: "#F8FAFC",
    accentColor: "#FCC757",
    bodyBg: "#F8FAFC",
    bodyText: "#1E293B",
    tableBorder: "#CBD5E1",
    tableHeaderBg: "#E2E8F0",
  },
} as const;

// ---------- PDF Settings (UI-SPEC PDF layout) ----------

export const PDF_SETTINGS = {
  margins: 0.75, // inches
  letterWidth: 8.5,
  letterHeight: 11,
  a4Width: 8.27,
  a4Height: 11.69,
  fontSizes: {
    title: 24,
    heading: 18,
    body: 10,
    label: 8,
  },
} as const;

// ---------- Feature Coverage (D-16c) ----------

/** Total tracked features per project: projects, contracts, tasks, team, field, documents */
export const FEATURE_TOTAL = 6;
