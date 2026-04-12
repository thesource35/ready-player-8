// Chart configuration constants for Phase 19 — Reporting & Dashboards
// Shared styles, colors, and animation config for all Recharts components.
// Per UI-SPEC: chart container, tooltip, axis, grid, animation specs.

export const CHART_TOOLTIP_STYLE = {
  background: "var(--surface)",
  border: "1px solid var(--border)",
  borderRadius: 8,
  padding: 8,
  fontSize: 12,
  fontWeight: 400,
} as const;

export const CHART_AXIS_STYLE = {
  fontSize: 8,
  fontWeight: 400,
  fill: "var(--muted)",
} as const;

export const CHART_GRID_STYLE = {
  stroke: "var(--border)",
  strokeOpacity: 0.3,
} as const;

/** D-26b: animation duration 600ms ease-out */
export const CHART_ANIMATION = {
  duration: 600,
  easing: "ease-out" as const,
};

/** UI-SPEC chart color palette ordered by series */
export const CHART_SERIES_COLORS = [
  "#F29E3D", // accent — primary series
  "#4AC4CC", // cyan — secondary series
  "#69D294", // green — positive/completed
  "#8A8FCC", // purple — tertiary
  "#FCC757", // gold — quaternary
  "#D94D48", // red — alert
] as const;

/** UI-SPEC chart height: 240px default, 180px for mini widgets */
export const CHART_HEIGHT = {
  default: 240,
  mini: 180,
} as const;

/** UI-SPEC chart container wrapper style */
export const CHART_WRAPPER_STYLE = {
  background: "var(--panel)",
  borderRadius: 14,
  padding: 16,
  marginBottom: 16,
  position: "relative" as const,
} as const;

/** UI-SPEC chart title style: 12px 800 uppercase letterSpacing 1 */
export const CHART_TITLE_STYLE = {
  fontSize: 12,
  fontWeight: 800,
  letterSpacing: 1,
  color: "var(--text)",
  marginBottom: 12,
  textTransform: "uppercase" as const,
} as const;
