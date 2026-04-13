// WCAG contrast ratio validation (D-72)
// Implements WCAG 2.1 AA contrast requirements:
// - 4.5:1 for normal text
// - 3:1 for large text (18pt+ or 14pt+ bold)

/**
 * Convert a hex color string to RGB components.
 * Accepts #RGB, #RRGGBB, or RRGGBB formats.
 */
function hexToRgb(hex: string): { r: number; g: number; b: number } {
  let cleaned = hex.replace(/^#/, "");

  // Expand shorthand (#RGB -> #RRGGBB)
  if (cleaned.length === 3) {
    cleaned = cleaned[0] + cleaned[0] + cleaned[1] + cleaned[1] + cleaned[2] + cleaned[2];
  }

  if (cleaned.length !== 6) {
    return { r: 0, g: 0, b: 0 };
  }

  const num = parseInt(cleaned, 16);
  return {
    r: (num >> 16) & 255,
    g: (num >> 8) & 255,
    b: num & 255,
  };
}

/**
 * Compute the WCAG relative luminance of a hex color.
 * Uses the sRGB gamma correction formula per WCAG 2.1.
 *
 * @see https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
 */
export function relativeLuminance(hex: string): number {
  const { r, g, b } = hexToRgb(hex);

  // Normalize to 0-1 range
  const rNorm = r / 255;
  const gNorm = g / 255;
  const bNorm = b / 255;

  // Apply sRGB gamma correction
  const rLinear = rNorm <= 0.04045 ? rNorm / 12.92 : Math.pow((rNorm + 0.055) / 1.055, 2.4);
  const gLinear = gNorm <= 0.04045 ? gNorm / 12.92 : Math.pow((gNorm + 0.055) / 1.055, 2.4);
  const bLinear = bNorm <= 0.04045 ? bNorm / 12.92 : Math.pow((bNorm + 0.055) / 1.055, 2.4);

  // Luminance coefficients per WCAG specification
  return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
}

/**
 * Compute the WCAG contrast ratio between two hex colors.
 * Returns a value between 1 (no contrast) and 21 (maximum contrast).
 *
 * Formula: (L1 + 0.05) / (L2 + 0.05) where L1 is the lighter color.
 *
 * @see https://www.w3.org/TR/WCAG21/#dfn-contrast-ratio
 */
export function checkContrastRatio(foreground: string, background: string): number {
  const lumFg = relativeLuminance(foreground);
  const lumBg = relativeLuminance(background);

  const lighter = Math.max(lumFg, lumBg);
  const darker = Math.min(lumFg, lumBg);

  return (lighter + 0.05) / (darker + 0.05);
}

/**
 * Get a user-facing warning message if the foreground/background color pair
 * fails WCAG AA contrast requirements.
 *
 * Returns null if the pair passes AA for normal text (4.5:1).
 * Returns a warning string if contrast is insufficient.
 *
 * @param fg - Foreground (text) color as hex
 * @param bg - Background color as hex
 * @param largeText - Whether text is large (18pt+ or 14pt+ bold). Uses 3:1 threshold.
 */
export function getContrastWarning(
  fg: string,
  bg: string,
  largeText = false
): string | null {
  const ratio = checkContrastRatio(fg, bg);
  const threshold = largeText ? 3 : 4.5;

  if (ratio >= threshold) {
    return null;
  }

  return `Low contrast -- text may be hard to read. Ratio: ${ratio.toFixed(1)}:1 (minimum ${threshold}:1 required for WCAG AA).`;
}
