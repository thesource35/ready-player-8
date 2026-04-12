// Design tokens -- single source of truth (D-85, D-103)
// Static config file, no database dependency
// iOS Theme struct and web CSS vars generated from these values

export const tokens = {
  colors: {
    primary: {
      50: "#EFF6FF",
      100: "#DBEAFE",
      200: "#BFDBFE",
      300: "#93C5FD",
      400: "#60A5FA",
      500: "#3B82F6",
      600: "#2563EB",
      700: "#1D4ED8",
      800: "#1E3A5F",
      900: "#1E293B",
    },
    gray: {
      50: "#F8F9FB",
      100: "#F1F3F5",
      200: "#E2E5E9",
      300: "#D1D5DB",
      400: "#9CA3AF",
      500: "#6B7280",
      600: "#4B5563",
      700: "#374151",
      800: "#1F2937",
      900: "#111827",
    },
    semantic: {
      success: "#16A34A",
      warning: "#F59E0B",
      error: "#DC2626",
      info: "#2563EB",
    },
    toast: {
      info: { bg: "#EFF6FF", border: "#2563EB" },
      success: { bg: "#F0FDF4", border: "#16A34A" },
      warning: { bg: "#FFFBEB", border: "#F59E0B" },
      error: { bg: "#FEF2F2", border: "#DC2626" },
    },
  },
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    "2xl": 48,
    "3xl": 64,
  },
  radius: {
    sm: 4,
    md: 8,
    lg: 12,
    xl: 16,
  },
  typography: {
    fontFamily: {
      sans: "Inter, system-ui, -apple-system, sans-serif",
      mono: "JetBrains Mono, monospace",
    },
    fontSize: {
      xs: 12,
      sm: 13,
      md: 14,
      lg: 16,
      xl: 18,
      "2xl": 20,
      "3xl": 28,
    },
    fontWeight: {
      normal: 400,
      medium: 500,
      semibold: 600,
      bold: 700,
      extrabold: 800,
    },
    lineHeight: {
      tight: 1.15,
      snug: 1.2,
      normal: 1.4,
      relaxed: 1.5,
    },
  },
  motion: {
    fast: "150ms",
    normal: "200ms",
    slow: "250ms",
    toast: "300ms",
    shimmer: "1.5s",
    easing: {
      default: "ease-in-out",
      enter: "ease-out",
      exit: "ease-in",
    },
  },
  card: {
    bg: "#FFFFFF",
    border: "1px solid #E2E5E9",
    borderRadius: 8,
    padding: 24,
    hoverBorderColor: "#D1D5DB",
  },
  sidebar: {
    collapsedWidth: 56,
    expandedWidth: 240,
  },
} as const;

// D-64: Portal preset brand themes
export const portalPresetThemes = {
  corporate_blue: {
    name: "Corporate Blue",
    primary: "#2563EB",
    secondary: "#1D4ED8",
    background: "#F8F9FB",
    cardBg: "#FFFFFF",
    text: "#111827",
  },
  warm_stone: {
    name: "Warm Stone",
    primary: "#92400E",
    secondary: "#78350F",
    background: "#FEFDF5",
    cardBg: "#FFFBEB",
    text: "#292524",
  },
  forest_green: {
    name: "Forest Green",
    primary: "#166534",
    secondary: "#14532D",
    background: "#F0FDF4",
    cardBg: "#FFFFFF",
    text: "#14532D",
  },
  slate_gray: {
    name: "Slate Gray",
    primary: "#475569",
    secondary: "#334155",
    background: "#F8FAFC",
    cardBg: "#FFFFFF",
    text: "#0F172A",
  },
  bold_red: {
    name: "Bold Red",
    primary: "#B91C1C",
    secondary: "#991B1B",
    background: "#FEF2F2",
    cardBg: "#FFFFFF",
    text: "#1F2937",
  },
} as const;

export type PortalPresetKey = keyof typeof portalPresetThemes;
