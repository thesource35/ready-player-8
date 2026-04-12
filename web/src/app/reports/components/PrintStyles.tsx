/**
 * PrintStyles: Print-friendly CSS for report pages.
 * Per D-21: @media print rules for clean output.
 * Per D-108: Triggered by Cmd+P (browser print dialog).
 *
 * Renders a <style> tag with @media print rules.
 * Import and include in report pages for print support.
 *
 * Security note: The CSS content is a static string literal with no user input.
 * dangerouslySetInnerHTML is safe here as no dynamic data is interpolated.
 */

const PRINT_CSS = `
@media print {
  /* White background for all print output */
  body,
  html,
  main,
  #__next {
    background: #ffffff !important;
    color: #000000 !important;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  /* Hide navigation, export buttons, filter bars, tooltips */
  nav,
  aside,
  header > nav,
  [data-testid="sidebar"],
  [data-testid="nav"],
  [class*="Sidebar"],
  [class*="sidebar"],
  [class*="Navigation"],
  [class*="navigation"],
  footer {
    display: none !important;
  }

  /* Hide interactive controls */
  button,
  [role="button"],
  [data-testid*="export"],
  [data-testid*="filter"],
  [class*="ExportButton"],
  [class*="FilterBar"],
  [class*="filter-bar"],
  [class*="Tooltip"],
  [class*="tooltip"],
  [class*="BookmarkButton"],
  [class*="KeyboardShortcuts"],
  [class*="FeatureDiscovery"],
  [class*="CollaborationPanel"],
  [class*="AnnotationCanvas"],
  [class*="OfflineBanner"] {
    display: none !important;
  }

  /* Show all sections expanded (no collapse) */
  details {
    display: block !important;
  }
  details > summary {
    display: none !important;
  }
  [data-collapsed="true"],
  [aria-expanded="false"] + [role="region"] {
    display: block !important;
    height: auto !important;
    overflow: visible !important;
  }

  /* Chart images at full size */
  .recharts-wrapper,
  .recharts-surface,
  svg[class*="recharts"],
  [data-testid*="chart"],
  [class*="Chart"] {
    width: 100% !important;
    max-width: 100% !important;
    height: auto !important;
    page-break-inside: avoid;
  }

  /* Table borders visible */
  table {
    border-collapse: collapse !important;
    width: 100% !important;
  }
  table th,
  table td {
    border: 1px solid #333333 !important;
    padding: 6px 10px !important;
    color: #000000 !important;
    background: #ffffff !important;
    font-size: 11pt !important;
  }
  table th {
    background: #f0f0f0 !important;
    font-weight: 700 !important;
  }

  /* Page break before each major section */
  [data-testid*="section"],
  [class*="Section"]:not(:first-child),
  [class*="section"]:not(:first-child) {
    page-break-before: always;
  }

  /* Prevent orphaned headers */
  h1, h2, h3, h4, h5, h6 {
    page-break-after: avoid;
    color: #000000 !important;
  }

  /* Prevent page breaks inside cards */
  [class*="StatCard"],
  [class*="stat-card"],
  [class*="Card"],
  [data-testid*="card"] {
    page-break-inside: avoid;
    border: 1px solid #cccccc !important;
    background: #ffffff !important;
    color: #000000 !important;
  }

  /* Report container full width */
  [class*="report"],
  [class*="Report"],
  main > div {
    max-width: 100% !important;
    margin: 0 !important;
    padding: 10mm !important;
  }

  /* Ensure text is readable */
  p, span, div, li, td, th {
    color: #000000 !important;
  }

  /* Links show URL in print */
  a[href]:not([href^="#"])::after {
    content: " (" attr(href) ")";
    font-size: 9pt;
    color: #666666;
  }

  /* Health badges readable in B&W */
  [class*="HealthBadge"],
  [data-testid*="health"] {
    border: 2px solid #000000 !important;
    background: #ffffff !important;
    color: #000000 !important;
  }

  /* Page margins */
  @page {
    margin: 15mm;
    size: A4 portrait;
  }

  /* First page: no top margin for header */
  @page :first {
    margin-top: 10mm;
  }
}
`;

export default function PrintStyles() {
  // Static CSS string -- no user input, safe to inject
  // eslint-disable-next-line react/no-danger
  return <style dangerouslySetInnerHTML={{ __html: PRINT_CSS }} />;
}
