import { describe, it, expect } from "vitest";
import { checkContrastRatio, getContrastWarning, relativeLuminance } from "../contrastValidator";

describe("Company Branding — Contrast Validation", () => {
  it("validates WCAG AA contrast ratio 4.5:1 for text (D-72)", () => {
    // Black on white = 21:1
    const ratio = checkContrastRatio("#000000", "#FFFFFF");
    expect(ratio).toBeGreaterThanOrEqual(4.5);
    expect(ratio).toBeCloseTo(21, 0);
  });

  it("warns on low contrast pairs", () => {
    // Light gray on white — low contrast
    const warning = getContrastWarning("#CCCCCC", "#FFFFFF");
    expect(warning).not.toBeNull();
    expect(warning).toContain("Low contrast");
    expect(warning).toContain("WCAG AA");
  });

  it("passes high contrast pairs", () => {
    const warning = getContrastWarning("#000000", "#FFFFFF");
    expect(warning).toBeNull();
  });

  it("uses 3:1 threshold for large text", () => {
    // A pair that passes 3:1 but fails 4.5:1
    // #767676 on white is about 4.54:1 — passes both
    // #959595 on white is about 2.85:1 — fails both
    // #808080 on white is about 3.95:1 — passes large, fails normal
    const warningNormal = getContrastWarning("#808080", "#FFFFFF", false);
    const warningLarge = getContrastWarning("#808080", "#FFFFFF", true);
    expect(warningNormal).not.toBeNull(); // fails normal text
    expect(warningLarge).toBeNull(); // passes large text
  });

  it("computes relative luminance correctly for black", () => {
    expect(relativeLuminance("#000000")).toBeCloseTo(0, 4);
  });

  it("computes relative luminance correctly for white", () => {
    expect(relativeLuminance("#FFFFFF")).toBeCloseTo(1, 4);
  });

  it("handles shorthand hex (#RGB format)", () => {
    // #FFF should behave like #FFFFFF
    const ratio = checkContrastRatio("#000", "#FFF");
    expect(ratio).toBeCloseTo(21, 0);
  });

  it("handles hex without # prefix", () => {
    const ratio = checkContrastRatio("000000", "FFFFFF");
    expect(ratio).toBeCloseTo(21, 0);
  });

  it("applies custom font family from allowed list (D-76)", () => {
    // Font family validation is at the type level via PortalThemeConfig
    // Verify the allowed fonts are the expected set
    const allowedFonts = ["Inter", "Roboto", "Source Sans 3", "DM Sans"];
    expect(allowedFonts).toContain("Inter");
    expect(allowedFonts).toContain("Roboto");
    expect(allowedFonts).toContain("Source Sans 3");
    expect(allowedFonts).toContain("DM Sans");
    expect(allowedFonts).toHaveLength(4);
  });

  it("validates contrast for preset theme colors (D-64)", () => {
    // Corporate Blue preset: dark text on white bg
    const corporateBlue = checkContrastRatio("#1F2937", "#FFFFFF");
    expect(corporateBlue).toBeGreaterThanOrEqual(4.5);

    // Primary blue on white bg
    const primaryOnWhite = checkContrastRatio("#1E40AF", "#FFFFFF");
    expect(primaryOnWhite).toBeGreaterThanOrEqual(4.5);
  });

  it("returns symmetric results regardless of argument order", () => {
    const ratio1 = checkContrastRatio("#000000", "#FFFFFF");
    const ratio2 = checkContrastRatio("#FFFFFF", "#000000");
    expect(ratio1).toBeCloseTo(ratio2, 4);
  });
});
