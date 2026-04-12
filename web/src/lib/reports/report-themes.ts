// Report themes (D-109) — CSS variable overrides for report rendering.
// Each theme provides colors, font scale, and border radius.
// Custom CSS themes for enterprise accept raw CSS string (D-107).

// ---------- Types ----------

export type ReportTheme = {
  name: string;
  colors: {
    bg: string;
    surface: string;
    accent: string;
    text: string;
    muted: string;
    border: string;
    headerBg: string;
    headerText: string;
  };
  fontScale: number;
  borderRadius: number;
};

export type CustomTheme = ReportTheme & {
  /** Raw CSS string for enterprise custom styling (D-107). Only CSS property declarations allowed. */
  customCSS?: string;
};

// ---------- Sanitization (T-19-35) ----------

const FORBIDDEN_CSS_PATTERNS = [
  /expression\s*\(/i,
  /javascript\s*:/i,
  /url\s*\(\s*["']?\s*data\s*:/i,
  /@import/i,
  /<script/i,
  /behavior\s*:/i,
  /-moz-binding/i,
];

/** Sanitize custom CSS to prevent script injection (T-19-35). */
export function sanitizeCustomCSS(css: string): string {
  let sanitized = css;
  for (const pattern of FORBIDDEN_CSS_PATTERNS) {
    sanitized = sanitized.replace(pattern, "/* blocked */");
  }
  // Limit length to 10KB
  return sanitized.slice(0, 10_000);
}

// ---------- Built-in Themes ----------

export const REPORT_THEMES: Record<string, ReportTheme> = {
  professional: {
    name: "Professional",
    colors: {
      bg: "#0F1C24",
      surface: "#1A2332",
      accent: "#F29E3D",
      text: "#E8ECF0",
      muted: "#6B7B8D",
      border: "#2A3544",
      headerBg: "#1A2332",
      headerText: "#FFFFFF",
    },
    fontScale: 1,
    borderRadius: 10,
  },
  construction: {
    name: "Construction",
    colors: {
      bg: "#1A1408",
      surface: "#2A2010",
      accent: "#F29E3D",
      text: "#F5E6C8",
      muted: "#8B7355",
      border: "#3D3018",
      headerBg: "#F29E3D",
      headerText: "#FFFFFF",
    },
    fontScale: 1.05,
    borderRadius: 8,
  },
  corporate: {
    name: "Corporate",
    colors: {
      bg: "#0A1628",
      surface: "#132240",
      accent: "#4AC4CC",
      text: "#D0D8E8",
      muted: "#5A6A80",
      border: "#1E3050",
      headerBg: "#0F1C24",
      headerText: "#FFFFFF",
    },
    fontScale: 1,
    borderRadius: 6,
  },
  minimal: {
    name: "Minimal",
    colors: {
      bg: "#FAFAFA",
      surface: "#FFFFFF",
      accent: "#6B7280",
      text: "#111827",
      muted: "#9CA3AF",
      border: "#E5E7EB",
      headerBg: "#FFFFFF",
      headerText: "#111827",
    },
    fontScale: 0.95,
    borderRadius: 4,
  },
  executive: {
    name: "Executive",
    colors: {
      bg: "#0F172A",
      surface: "#1E293B",
      accent: "#FCC757",
      text: "#F8FAFC",
      muted: "#64748B",
      border: "#334155",
      headerBg: "#1E293B",
      headerText: "#F8FAFC",
    },
    fontScale: 1.05,
    borderRadius: 12,
  },
};

/** Default theme key */
export const DEFAULT_THEME = "professional";

/** Get theme by key, falling back to professional */
export function getTheme(key: string): ReportTheme {
  return REPORT_THEMES[key] ?? REPORT_THEMES[DEFAULT_THEME];
}

/** Apply theme to a container element via CSS custom properties */
export function applyThemeToElement(el: HTMLElement, theme: ReportTheme): void {
  const { colors, fontScale, borderRadius } = theme;
  el.style.setProperty("--report-bg", colors.bg);
  el.style.setProperty("--report-surface", colors.surface);
  el.style.setProperty("--report-accent", colors.accent);
  el.style.setProperty("--report-text", colors.text);
  el.style.setProperty("--report-muted", colors.muted);
  el.style.setProperty("--report-border", colors.border);
  el.style.setProperty("--report-header-bg", colors.headerBg);
  el.style.setProperty("--report-header-text", colors.headerText);
  el.style.setProperty("--report-font-scale", String(fontScale));
  el.style.setProperty("--report-radius", `${borderRadius}px`);
}

/** Build a white-label theme from company branding (D-107) */
export function createBrandedTheme(
  base: string,
  options: { logoUrl?: string; primaryColor?: string; companyName?: string }
): ReportTheme & { logoUrl?: string; companyName?: string } {
  const baseTheme = getTheme(base);
  return {
    ...baseTheme,
    name: options.companyName ? `${options.companyName} Theme` : baseTheme.name,
    colors: {
      ...baseTheme.colors,
      ...(options.primaryColor ? { accent: options.primaryColor } : {}),
    },
    logoUrl: options.logoUrl,
    companyName: options.companyName,
  };
}
