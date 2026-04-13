import { describe, it, expect } from "vitest";
import { sanitizePortalCSS } from "../cssSanitizer";

describe("CSS Sanitization", () => {
  it("strips expression() calls", () => {
    const { sanitized, warnings } = sanitizePortalCSS(
      "div { width: expression(document.body.clientWidth) }"
    );
    expect(sanitized).not.toContain("expression");
    expect(sanitized).toContain("/* blocked */");
    expect(warnings.length).toBeGreaterThan(0);
  });

  it("strips javascript: URLs", () => {
    const { sanitized } = sanitizePortalCSS(
      'a { background: url(javascript:alert(1)) }'
    );
    expect(sanitized).not.toContain("javascript");
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips @import rules", () => {
    const { sanitized } = sanitizePortalCSS(
      '@import url("evil.css"); body { color: red }'
    );
    expect(sanitized).not.toContain("@import");
    expect(sanitized).toContain("color");
  });

  it("strips behavior: property", () => {
    const { sanitized } = sanitizePortalCSS(
      "div { behavior: url(xss.htc) }"
    );
    expect(sanitized).not.toContain("behavior");
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips -moz-binding", () => {
    const { sanitized } = sanitizePortalCSS(
      "div { -moz-binding: url(xss) }"
    );
    expect(sanitized).not.toContain("-moz-binding");
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips data: URIs in url()", () => {
    const { sanitized } = sanitizePortalCSS(
      'div { background: url("data:text/html,<script>alert(1)</script>") }'
    );
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips <script tags", () => {
    const { sanitized } = sanitizePortalCSS(
      '<script>alert(1)</script> div { color: red }'
    );
    expect(sanitized).not.toContain("<script");
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips null byte injection", () => {
    const { sanitized } = sanitizePortalCSS(
      "div { color: re\\00d }"
    );
    expect(sanitized).toContain("/* blocked */");
  });

  it("strips javascript: in url() with quotes", () => {
    const { sanitized } = sanitizePortalCSS(
      'div { background: url("javascript:void(0)") }'
    );
    expect(sanitized).not.toContain("javascript");
  });

  it("allows safe visual properties (color, background, border)", () => {
    const css = "div { color: red; background-color: blue; border-radius: 8px; font-size: 14px; padding: 10px }";
    const { sanitized, warnings } = sanitizePortalCSS(css);
    expect(sanitized).toContain("color");
    expect(sanitized).toContain("background-color");
    expect(sanitized).toContain("border-radius");
    expect(sanitized).toContain("font-size");
    expect(sanitized).toContain("padding");
    // No warnings for allowed properties
    const propertyWarnings = warnings.filter((w) => w.includes("not in the allowed whitelist"));
    expect(propertyWarnings).toHaveLength(0);
  });

  it("warns on disallowed properties", () => {
    const { warnings } = sanitizePortalCSS(
      "div { position: absolute; z-index: 9999 }"
    );
    const disallowedWarnings = warnings.filter((w) =>
      w.includes("not in the allowed whitelist")
    );
    expect(disallowedWarnings.length).toBeGreaterThan(0);
  });

  it("limits CSS to 10KB", () => {
    const longCSS = "a".repeat(15000);
    const { sanitized, warnings } = sanitizePortalCSS(longCSS);
    expect(sanitized.length).toBeLessThanOrEqual(10000);
    expect(warnings.some((w) => w.includes("10KB limit"))).toBe(true);
  });

  it("returns empty string for null/undefined input", () => {
    const { sanitized, warnings } = sanitizePortalCSS("");
    expect(sanitized).toBe("");
    expect(warnings).toHaveLength(0);
  });

  it("handles case-insensitive pattern matching", () => {
    const { sanitized } = sanitizePortalCSS(
      "div { width: EXPRESSION(100) }"
    );
    expect(sanitized).not.toMatch(/expression/i);
    expect(sanitized).toContain("/* blocked */");
  });
});
