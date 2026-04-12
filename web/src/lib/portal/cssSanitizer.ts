// CSS sanitization for portal custom CSS (D-117, T-20-10)
// Extends the report-themes.ts sanitizeCustomCSS pattern with property whitelist

// Forbidden patterns — XSS vectors that must never appear in custom CSS
const FORBIDDEN_CSS_PATTERNS = [
  /expression\s*\(/i,
  /javascript\s*:/i,
  /url\s*\(\s*["']?\s*data\s*:/i,
  /@import/i,
  /<script/i,
  /behavior\s*:/i,
  /-moz-binding/i,
  /\\00/i,                            // null byte injection
  /url\s*\(\s*["']?\s*javascript/i,   // javascript: in url()
];

// Allowed CSS properties whitelist — only safe visual properties
const ALLOWED_PROPERTIES = new Set([
  "color",
  "background-color",
  "background",
  "border",
  "border-color",
  "border-radius",
  "font-family",
  "font-size",
  "font-weight",
  "line-height",
  "letter-spacing",
  "text-align",
  "text-decoration",
  "text-transform",
  "padding",
  "padding-top",
  "padding-right",
  "padding-bottom",
  "padding-left",
  "margin",
  "margin-top",
  "margin-right",
  "margin-bottom",
  "margin-left",
  "width",
  "max-width",
  "min-width",
  "height",
  "max-height",
  "min-height",
  "display",
  "flex",
  "flex-direction",
  "align-items",
  "justify-content",
  "gap",
  "opacity",
  "box-shadow",
  "transition",
]);

const MAX_CSS_LENGTH = 10_000; // 10KB limit (D-117)

/**
 * Sanitize custom CSS for portal branding.
 * - Strips forbidden patterns (XSS vectors) and replaces with comments
 * - Warns on properties not in the allowed whitelist
 * - Enforces 10KB max length
 *
 * Returns both the sanitized CSS and an array of warning messages.
 */
export function sanitizePortalCSS(css: string): {
  sanitized: string;
  warnings: string[];
} {
  const warnings: string[] = [];

  if (!css || typeof css !== "string") {
    return { sanitized: "", warnings: [] };
  }

  // Enforce size limit
  let sanitized = css;
  if (sanitized.length > MAX_CSS_LENGTH) {
    sanitized = sanitized.slice(0, MAX_CSS_LENGTH);
    warnings.push(`CSS truncated to ${MAX_CSS_LENGTH} characters (10KB limit)`);
  }

  // Strip forbidden patterns
  for (const pattern of FORBIDDEN_CSS_PATTERNS) {
    if (pattern.test(sanitized)) {
      warnings.push(`Blocked forbidden CSS pattern: ${pattern.source}`);
      sanitized = sanitized.replace(new RegExp(pattern.source, "gi"), "/* blocked */");
    }
  }

  // Parse CSS declarations and warn on disallowed properties
  // Match property names in declarations (property: value;)
  const declarationRegex = /([a-z-]+)\s*:/gi;
  let match: RegExpExecArray | null;
  const checkedProperties = new Set<string>();

  while ((match = declarationRegex.exec(sanitized)) !== null) {
    const property = match[1].toLowerCase();
    // Skip CSS selectors and pseudo-classes that look like properties
    if (property.startsWith("-") && !ALLOWED_PROPERTIES.has(property)) {
      // Vendor prefixes — warn but allow
      if (!checkedProperties.has(property)) {
        checkedProperties.add(property);
        warnings.push(`Vendor-prefixed property "${property}" — review recommended`);
      }
      continue;
    }
    if (!ALLOWED_PROPERTIES.has(property) && !checkedProperties.has(property)) {
      checkedProperties.add(property);
      warnings.push(`CSS property "${property}" is not in the allowed whitelist`);
    }
  }

  return { sanitized, warnings };
}
