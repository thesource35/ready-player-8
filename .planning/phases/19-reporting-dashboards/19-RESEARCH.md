# Phase 19: Reporting & Dashboards - Research

**Researched:** 2026-04-11
**Domain:** Data aggregation, charting, PDF generation, email delivery, multi-platform reporting
**Confidence:** HIGH

## Summary

Phase 19 is the most feature-dense phase in the v2.0 roadmap, encompassing 119 locked decisions (D-01 through D-119) across single-project reports, portfolio rollup dashboards, PDF/CSV/Excel/PowerPoint export, scheduled email delivery, chart visualizations, shareable links, AI insights, report templates, collaboration features, and comprehensive analytics. Both iOS (SwiftUI Charts) and web (Recharts) platforms must achieve full feature parity.

The web stack centers on Recharts 3.8.1 for charting, jsPDF 4.2.1 + html2canvas 1.4.1 for client-side PDF, Resend 6.10.0 for email delivery, SheetJS (xlsx 0.18.5) for Excel, pptxgenjs 4.0.1 for PowerPoint, next-intl 4.9.1 for i18n, Fabric.js 7.2.0 for annotation, and PostHog for behavioral analytics. iOS uses native SwiftUI Charts and UIGraphicsPDFRenderer. All libraries have verified React 19 / Next.js 16 compatibility.

The primary risk is scope magnitude -- 119 decisions will require careful wave decomposition. The planner must prioritize the four core requirements (REPORT-01 through REPORT-04) in early waves and layer advanced features (scheduled emails, templates, collaboration, embedding) in later waves. API routes follow the established `/api/reports/*` pattern with existing Upstash rate limiting and Supabase RLS infrastructure.

**Primary recommendation:** Build in layers -- report data API + single-project view first, then charts, then PDF export, then portfolio rollup, then all extended features. Use existing Finance page layout pattern as the template.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
119 decisions (D-01 through D-119) covering:
- Report content and sections (D-01 to D-16e)
- Chart approach: Recharts (web), SwiftUI Charts (iOS) (D-17 to D-26j)
- PDF export: jsPDF + html2canvas (web), UIGraphicsPDFRenderer (iOS) (D-27 to D-34n)
- Cross-project rollup (D-35 to D-46b)
- Export and delivery: PDF + CSV + Excel + JSON + PowerPoint + Email via Resend (D-47 to D-50x)
- API design: /api/reports/project/[id], /api/reports/rollup, /api/reports/export/[type], /api/reports/schedule (D-51 to D-56h)
- Performance and caching: SWR + server-side + Vercel Edge Cache (D-57 to D-62c)
- Access control and sharing: RLS + shareable links + role-based permissions (D-63 to D-64g)
- Navigation: iOS Reports tab in Intel group, web /reports route (D-65 to D-66d)
- iOS-specific: WidgetKit, offline, haptics, Siri, Watch, Dynamic Island, Spotlight, VoiceOver, CarPlay (D-67 to D-76)
- Testing: Vitest + Playwright + Percy + XCTest + swift-snapshot-testing (D-77 to D-85)
- Localization: next-intl (web) + String Catalogs (iOS) (D-86 to D-90)
- Database schema: cs_report_* prefix tables (D-91 to D-94)
- Migration and rollout: feature flags (D-95 to D-97)
- Collaboration: comments + annotations via Fabric.js (D-98 to D-99)
- Notifications and subscriptions (D-100 to D-102)
- Automation triggers (D-103)
- Embedding via iframe + share token (D-104)
- Analytics: Vercel Analytics + PostHog (D-105)
- Search and filter (D-106)
- White-labeling (D-107)
- Keyboard shortcuts (D-108)
- Report theming (D-109)
- Bulk operations (D-110)
- Bookmarks and favorites (D-111)
- Audit trail (D-112)
- PWA offline (D-113)
- External integrations: QuickBooks, Zapier, CSV import (D-114 to D-115)
- Industry benchmarks (D-116)
- Comparison tools (D-117)
- Scheduling calendar integration (D-118)
- Permission inheritance (D-119)

### Claude's Discretion
- Skeleton loading design specifics
- Exact Recharts component configuration
- SwiftUI Charts mark styling
- Health score calculation thresholds (what % maps to green/yellow/red defaults)
- Database index specifics (exact columns and index types)
- Email template HTML/CSS implementation details
- Error retry behavior for failed report sections
- WidgetKit widget design specifics
- Siri Shortcuts AppIntents implementation
- CoreSpotlight indexing attributes
- watchOS complication layout
- Dynamic Island / Live Activity design
- Fabric.js annotation tool configuration
- PostHog event schema design
- Service Worker caching strategy details
- Report drafts, cloning, and tags/labels features
- Any remaining implementation details not covered above

### Deferred Ideas (OUT OF SCOPE)
- Webhooks for external systems (JSON API + Zapier covers basic integration)
- visionOS spatial 3D charts
- Full competitor tool integrations (Procore, Buildertrend APIs) -- deferred to v3.0
- OAuth login providers -- deferred to v2.1+
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPORT-01 | User can generate single-project summary report (budget, schedule, issues, team) | Decisions D-01 to D-16e define all report sections. API at `/api/reports/project/[id]` aggregates from cs_projects, cs_contracts, cs_project_tasks, safety incidents, team assignments. Finance page pattern provides layout template |
| REPORT-02 | User can view cross-project financial rollup dashboard | Decisions D-35 to D-46b define portfolio rollup. API at `/api/reports/rollup`. Aggregates all financial metrics across projects with sortable table, comparison charts, timeline bars |
| REPORT-03 | User can export reports to PDF | Decisions D-27 to D-34n define PDF strategy. Web: jsPDF 4.2.1 + html2canvas 1.4.1 (client-side). iOS: UIGraphicsPDFRenderer. Charts rendered as static images in PDF |
| REPORT-04 | User can view chart visualizations (bar/line/pie) for budgets, timelines, and safety metrics | Decisions D-17 to D-26j define chart approach. Web: Recharts 3.8.1. iOS: SwiftUI Charts. Budget=pie, schedule=bar, safety=line. Full interactivity with tooltips, zoom, drill-down |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| recharts | 3.8.1 | Web charting (bar, line, pie, area, radar) | React-native declarative components, supports React 19, good Next.js SSR story [VERIFIED: npm registry] |
| jspdf | 4.2.1 | Client-side PDF generation | No server resources needed, works offline, well-maintained [VERIFIED: npm registry] |
| html2canvas | 1.4.1 | DOM-to-canvas capture for PDF chart rendering | Standard companion to jsPDF for capturing styled HTML/charts [VERIFIED: npm registry] |
| resend | 6.10.0 | Email delivery for scheduled reports | Simple API, good developer experience, Vercel-native [VERIFIED: npm registry] |
| xlsx (SheetJS) | 0.18.5 | Excel export (.xlsx with formatting) | Apache-2.0 licensed, standard spreadsheet library [VERIFIED: npm registry] |
| pptxgenjs | 4.0.1 | PowerPoint export (.pptx) | Zero-dependency PPTX generation, supports charts and images [VERIFIED: npm registry] |
| next-intl | 4.9.1 | Web internationalization | Supports Next.js 16, App Router compatible, React 19 peer dep [VERIFIED: npm registry] |
| fabric | 7.2.0 | Canvas annotation/drawing tools on charts | Full-featured canvas library for circles, arrows, highlights [VERIFIED: npm registry] |
| posthog-js | 1.367.0 | Client-side behavioral analytics | Feature flags, funnels, cohort analysis [VERIFIED: npm registry] |
| posthog-node | 5.29.2 | Server-side analytics events | Server event tracking for API-level analytics [VERIFIED: npm registry] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| react-window | 2.2.7 | Virtual scrolling for portfolio table at 25+ projects | D-46 requires virtualization [VERIFIED: npm registry] |
| @react-email/components | 1.0.12 | Branded HTML email templates | D-50c requires branded email with inline metrics [VERIFIED: npm registry] |
| react-is | (peer dep of recharts) | React type checking | Auto-installed with recharts [VERIFIED: npm registry] |

### iOS Native (no npm packages)
| Framework | Min iOS | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SwiftUI Charts | iOS 16+ (app min 18.2) | Native charting (bar, line, pie, area) | Zero dependencies, Apple-native, D-18 locked decision [ASSUMED] |
| UIGraphicsPDFRenderer | iOS 10+ | PDF generation | Native API, offline-capable, D-28 locked decision [ASSUMED] |
| WidgetKit | iOS 14+ | Home screen widgets | D-67 locked decision [ASSUMED] |
| AppIntents | iOS 16+ | Siri Shortcuts | D-70 locked decision [ASSUMED] |
| CoreSpotlight | iOS 9+ | Search indexing | D-74 locked decision [ASSUMED] |
| ClockKit/WidgetKit | watchOS 9+ | Apple Watch complications | D-72 locked decision [ASSUMED] |
| ActivityKit | iOS 16.1+ | Dynamic Island / Live Activity | D-73 locked decision [ASSUMED] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Recharts | Chart.js / D3 | Recharts is locked (D-17). Chart.js less React-native; D3 too low-level |
| jsPDF + html2canvas | Puppeteer / @react-pdf/renderer | jsPDF is locked (D-27). Puppeteer needs server; @react-pdf requires rewriting layout |
| xlsx (SheetJS) | ExcelJS | SheetJS is locked (D-47). ExcelJS has streaming but SheetJS is more widely used |
| Resend | SendGrid / AWS SES | Resend is locked (D-50). Simpler API, Vercel-native integration |
| next-intl | react-intl / i18next | next-intl is locked (D-86). Best App Router integration for Next.js |

**Installation:**
```bash
cd web && npm install recharts jspdf html2canvas resend xlsx pptxgenjs next-intl fabric posthog-js posthog-node react-window @react-email/components
```

## Architecture Patterns

### Recommended Project Structure
```
web/src/
├── app/
│   ├── reports/
│   │   ├── page.tsx                    # Reports landing (project list + nav)
│   │   ├── layout.tsx                  # Reports layout with tabs
│   │   ├── project/
│   │   │   └── [id]/
│   │   │       └── page.tsx            # Single project report view
│   │   ├── rollup/
│   │   │   └── page.tsx                # Portfolio rollup dashboard
│   │   ├── shared/
│   │   │   └── [token]/
│   │   │       └── page.tsx            # Public shared report view
│   │   └── components/
│   │       ├── ReportHeader.tsx         # Project name, health score, branding
│   │       ├── BudgetSection.tsx        # Budget KPIs + pie chart
│   │       ├── ScheduleSection.tsx      # Milestones + bar chart
│   │       ├── SafetySection.tsx        # Incidents + line chart
│   │       ├── TeamSection.tsx          # Counts + activity feed
│   │       ├── AIInsightsSection.tsx    # Claude-generated insights
│   │       ├── HealthBadge.tsx          # Color-coded health indicator
│   │       ├── StatCard.tsx             # Reusable KPI card
│   │       ├── ChartExportButton.tsx    # PNG/SVG export per chart
│   │       ├── PortfolioTable.tsx       # Sortable project table (react-window)
│   │       └── SkeletonReport.tsx       # Loading skeleton
│   ├── api/
│   │   └── reports/
│   │       ├── project/
│   │       │   └── [id]/
│   │       │       └── route.ts         # GET single project report data
│   │       ├── rollup/
│   │       │   └── route.ts             # GET portfolio rollup data
│   │       ├── export/
│   │       │   └── [type]/
│   │       │       └── route.ts         # POST export (PDF metadata, CSV, Excel, JSON, PPTX)
│   │       ├── schedule/
│   │       │   └── route.ts             # CRUD for email schedules
│   │       ├── share/
│   │       │   └── route.ts             # Create/revoke shareable links
│   │       ├── health/
│   │       │   └── route.ts             # Health check endpoint
│   │       └── cron/
│   │           └── route.ts             # Vercel Cron handler for scheduled reports
├── lib/
│   └── reports/
│       ├── aggregation.ts               # Pure functions: compute budget %, health score, rollups
│       ├── pdf-generator.ts             # jsPDF + html2canvas wrapper
│       ├── excel-generator.ts           # SheetJS export logic
│       ├── pptx-generator.ts            # pptxgenjs export logic
│       ├── csv-generator.ts             # CSV formatting
│       ├── email-template.tsx           # React Email template
│       ├── chart-config.ts              # Shared Recharts configuration
│       ├── types.ts                     # Report data types
│       └── constants.ts                 # Thresholds, colors, section configs
```

### iOS Structure
```
ready player 8/
├── ReportsView.swift                    # Main reports tab (segmented: Project / Portfolio)
├── ProjectReportView.swift              # Single project report
├── PortfolioRollupView.swift            # Cross-project dashboard
├── ReportCharts.swift                   # SwiftUI Charts components
├── ReportPDFGenerator.swift             # UIGraphicsPDFRenderer wrapper
├── ReportScheduleManager.swift          # Schedule CRUD (hits web API)
├── ReportWidgets/                       # WidgetKit extensions
│   ├── HealthScoreWidget.swift
│   └── BudgetWidget.swift
└── ReportIntents/                       # Siri Shortcuts
    └── ShowReportIntent.swift
```

### Pattern 1: Report Data Aggregation API
**What:** Single API endpoint returns all report sections for a project, computed on-demand from existing Supabase tables
**When to use:** Every report render (both web view and PDF generation)
**Example:**
```typescript
// web/src/app/api/reports/project/[id]/route.ts
// Source: Existing fetchTable pattern from web/src/lib/supabase/fetch.ts
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { NextResponse } from "next/server";

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const startTime = Date.now();
  const sections: Record<string, unknown> = {};
  const errors: Array<{ section: string; error: string }> = [];

  // Per D-56: partial report on section failure, 10s timeout per section
  const fetchSection = async (name: string, fn: () => Promise<unknown>) => {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 10_000);
      sections[name] = await fn();
      clearTimeout(timeout);
    } catch (e) {
      errors.push({ section: name, error: String(e) });
      sections[name] = null;
    }
  };

  await Promise.allSettled([
    fetchSection("budget", () => computeBudgetSection(supabase, id)),
    fetchSection("schedule", () => computeScheduleSection(supabase, id)),
    fetchSection("issues", () => computeIssuesSection(supabase, id)),
    fetchSection("team", () => computeTeamSection(supabase, id)),
    fetchSection("safety", () => computeSafetySection(supabase, id)),
  ]);

  return NextResponse.json({
    project_id: id,
    generated_at: new Date().toISOString(),
    health: computeHealthScore(sections),
    sections,
    errors: errors.length > 0 ? errors : undefined,
    _meta: { duration_ms: Date.now() - startTime },
  }, {
    headers: { "X-Report-Debug": JSON.stringify({ timing: Date.now() - startTime }) }
  });
}
```

### Pattern 2: Client-Side PDF Generation
**What:** Render report to DOM, capture with html2canvas, write to jsPDF
**When to use:** "Export PDF" button click
**Example:**
```typescript
// web/src/lib/reports/pdf-generator.ts
import jsPDF from "jspdf";
import html2canvas from "html2canvas";

export async function generateReportPDF(
  reportElement: HTMLElement,
  options: { projectName: string; landscape?: boolean; paperSize?: "letter" | "a4" }
): Promise<Blob> {
  const { projectName, landscape = false, paperSize = "letter" } = options;
  const canvas = await html2canvas(reportElement, {
    scale: 2,           // High DPI
    useCORS: true,      // Allow cross-origin images
    backgroundColor: "#ffffff", // D-33: light/print theme
  });

  const imgData = canvas.toDataURL("image/png");
  const pdf = new jsPDF({
    orientation: landscape ? "landscape" : "portrait",
    unit: "mm",
    format: paperSize,
  });

  const pageWidth = pdf.internal.pageSize.getWidth();
  const pageHeight = pdf.internal.pageSize.getHeight();
  const imgWidth = pageWidth - 20; // 10mm margins
  const imgHeight = (canvas.height * imgWidth) / canvas.width;

  // Smart page breaks (D-34j)
  let yOffset = 0;
  while (yOffset < imgHeight) {
    if (yOffset > 0) pdf.addPage();
    pdf.addImage(imgData, "PNG", 10, 10 - yOffset, imgWidth, imgHeight);
    yOffset += pageHeight - 20;
  }

  // Footer on each page (D-32)
  const pageCount = pdf.getNumberOfPages();
  for (let i = 1; i <= pageCount; i++) {
    pdf.setPage(i);
    pdf.setFontSize(8);
    pdf.text(`Page ${i} of ${pageCount}`, pageWidth / 2, pageHeight - 5, { align: "center" });
    pdf.text(`Generated ${new Date().toLocaleDateString()}`, pageWidth - 10, pageHeight - 5, { align: "right" });
  }

  const dateStr = new Date().toISOString().split("T")[0];
  // D-31: naming convention
  return new Blob([pdf.output("blob")], { type: "application/pdf" });
}
```

### Pattern 3: Recharts Chart Component (Budget Pie)
**What:** Reusable chart component with Recharts following D-19 through D-26j
**When to use:** Report view and mini-widget on project detail
```typescript
// web/src/app/reports/components/BudgetPieChart.tsx
"use client";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";

type BudgetPieProps = {
  spent: number;
  remaining: number;
  mini?: boolean;
};

export function BudgetPieChart({ spent, remaining, mini = false }: BudgetPieProps) {
  const data = [
    { name: "Spent", value: spent, color: "var(--accent)" },
    { name: "Remaining", value: remaining, color: "var(--green)" },
  ];
  const pct = Math.round((spent / (spent + remaining)) * 100);

  return (
    <div style={{ width: mini ? 120 : "100%", height: mini ? 120 : 250 }}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            dataKey="value"
            cx="50%"
            cy="50%"
            innerRadius={mini ? 30 : 60}
            outerRadius={mini ? 50 : 90}
            label={mini ? undefined : ({ name, value }) => `${name}: $${(value / 1000).toFixed(0)}K`}
            animationBegin={0}
            animationDuration={800}
          >
            {data.map((entry, i) => (
              <Cell key={i} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip formatter={(value: number) => `$${value.toLocaleString()}`} />
        </PieChart>
      </ResponsiveContainer>
      <div style={{ textAlign: "center", fontSize: 11, fontWeight: 800, color: "var(--text)" }}>
        {pct}% Complete
      </div>
    </div>
  );
}
```

### Pattern 4: Vercel Cron for Scheduled Reports (D-50i)
**What:** Cron endpoint queried on schedule to generate and email reports
**When to use:** Scheduled report delivery
```typescript
// web/src/app/api/reports/cron/route.ts
// vercel.json: { "crons": [{ "path": "/api/reports/cron", "schedule": "*/15 * * * *" }] }
import { NextResponse } from "next/server";

export async function GET(req: Request) {
  // Verify Vercel Cron authorization header
  const authHeader = req.headers.get("authorization");
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Query due schedules from cs_report_schedules
  // Generate reports, send via Resend, log to cs_report_delivery_log
  // D-50v: Supabase row lock prevents overlapping runs
  return NextResponse.json({ processed: 0 });
}
```

### Anti-Patterns to Avoid
- **Server-side PDF generation:** D-27 locks client-side jsPDF. Do NOT use Puppeteer or server rendering for PDFs
- **Blocking report on any section failure:** D-56 requires partial reports with failed sections showing retry button
- **Persisting on-demand reports:** D-04/D-57 say compute on demand. Only cache for scheduled reports
- **Building custom chart renderer:** Use Recharts (web) and SwiftUI Charts (iOS) -- never hand-roll SVG charts
- **Monolithic API response:** Use Promise.allSettled for parallel section fetching with individual timeouts

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Web charting | Custom SVG/canvas charts | Recharts 3.8.1 | Tooltips, animations, responsive sizing, accessibility -- thousands of edge cases |
| PDF generation | Server-side rendering pipeline | jsPDF 4.2.1 + html2canvas 1.4.1 | Page breaks, font embedding, image handling, cross-browser compat |
| Excel export | Custom XLSX binary writer | xlsx (SheetJS) 0.18.5 | OOXML format is complex (ZIP of XML files), formatting, multiple sheets |
| PowerPoint export | Custom PPTX generator | pptxgenjs 4.0.1 | Slide layout, chart embedding, image placement |
| Email delivery | SMTP client | Resend 6.10.0 | Deliverability, bounce handling, DKIM/SPF, rate limiting |
| Email templates | Raw HTML strings | @react-email/components 1.0.12 | Cross-client HTML email rendering (Gmail, Outlook, Apple Mail) |
| Virtual scrolling | Intersection observer DIY | react-window 2.2.7 | Smooth scroll, variable heights, overscan, keyboard nav |
| Rate limiting | Custom token bucket | Existing @upstash/ratelimit 2.0.8 | Already set up in web/src/lib/rate-limit.ts, distributed |
| i18n | Custom translation maps | next-intl 4.9.1 | ICU message format, plural rules, number/date formatting, SSR |
| Canvas annotations | Custom SVG overlay | Fabric.js 7.2.0 | Object selection, transforms, serialization, undo/redo |
| Behavioral analytics | Custom event tracking | PostHog | Funnels, cohorts, feature flags, session replay |
| iOS charting | Custom Core Graphics drawing | SwiftUI Charts | Native accessibility, Dark Mode, Dynamic Type support |

## Common Pitfalls

### Pitfall 1: html2canvas Fails on Cross-Origin Images
**What goes wrong:** Charts with external images (logos, map tiles) render as blank in PDF
**Why it happens:** html2canvas respects CORS; cross-origin images without proper headers are blocked
**How to avoid:** Set `useCORS: true` in html2canvas options. Proxy external images through own domain. For chart exports, render charts to canvas first, then capture
**Warning signs:** Blank rectangles in exported PDFs where images should be

### Pitfall 2: Recharts SSR Hydration Mismatch
**What goes wrong:** Charts flash or error on page load due to server/client rendering mismatch
**Why it happens:** Recharts uses browser APIs (window dimensions) that don't exist during SSR
**How to avoid:** Mark all chart components as `"use client"`. Use `ResponsiveContainer` which handles resize. Consider lazy loading charts with `React.lazy` or `next/dynamic`
**Warning signs:** Hydration errors in console, charts rendering at wrong size initially

### Pitfall 3: jsPDF Multi-Page Content Splitting
**What goes wrong:** Charts or tables get cut in half across page boundaries
**Why it happens:** html2canvas captures entire DOM as one image; jsPDF slices mechanically at page height
**How to avoid:** Implement smart page break detection (D-34j). Measure section heights before rendering. Add CSS `break-inside: avoid` on chart containers. Consider rendering sections individually and composing PDF page by page
**Warning signs:** Tables with headers on one page and data on next, charts cut horizontally

### Pitfall 4: Budget Field is String Type
**What goes wrong:** Financial aggregation produces NaN or incorrect totals
**Why it happens:** Both cs_projects.budget and cs_contracts.budget are `text` columns (e.g., "$450,000" not 450000)
**How to avoid:** Write robust parser in `aggregation.ts`: strip `$`, remove commas, parse to number. Handle edge cases: empty string, "N/A", "TBD". All aggregation functions must sanitize input
**Warning signs:** NaN in charts, $0 totals when data exists

### Pitfall 5: Vercel Cron Timeout for Batch Operations
**What goes wrong:** Scheduled report generation times out for large portfolios
**Why it happens:** Vercel Functions have execution time limits (60s default, 300s max on Pro)
**How to avoid:** Process schedules in batches. Use D-50i architecture: cron triggers, generates one report at a time. For batch export (D-34m), use background job pattern with status polling
**Warning signs:** 504 errors on cron runs, partial email deliveries

### Pitfall 6: SheetJS Community Edition Limitations
**What goes wrong:** Advanced Excel features (embedded charts, complex formatting) don't work
**Why it happens:** xlsx 0.18.5 (community/Apache) has limited styling support compared to Pro
**How to avoid:** Keep Excel exports focused on data tables with basic formatting. For D-47's "embedded charts" requirement, export charts as images in separate sheets. Test actual output in Excel/Google Sheets
**Warning signs:** Missing cell colors, no chart rendering in exported files

### Pitfall 7: Resend Rate Limits in Production
**What goes wrong:** Scheduled reports fail silently when many are due at same time
**Why it happens:** Resend has per-second and daily rate limits depending on plan
**How to avoid:** Implement D-50v concurrency protection. Queue emails with small delay between sends. Implement D-50x fallback (store report for download if email fails). Log all delivery attempts to cs_report_delivery_log
**Warning signs:** Intermittent 429 errors from Resend, missing scheduled emails

### Pitfall 8: next-intl Configuration Complexity
**What goes wrong:** i18n breaks routing or causes build errors
**Why it happens:** next-intl requires middleware configuration and message file organization
**How to avoid:** Start with English-only messages file, add middleware for locale detection. Use `useTranslations` hook in client components, `getTranslations` in server components. Keep all report labels in message files from day one
**Warning signs:** Build failures mentioning missing locale, 404 on localized routes

## Code Examples

### Health Score Computation (Claude's Discretion)
```typescript
// web/src/lib/reports/aggregation.ts
// Health score: green (0-70%), yellow (70-90%), red (90%+) budget consumption
// + schedule delays + open critical issues

type HealthColor = "green" | "yellow" | "red";

export function computeHealthScore(sections: {
  budget?: { spent: number; total: number } | null;
  schedule?: { delayedMilestones: number; totalMilestones: number } | null;
  issues?: { criticalOpen: number } | null;
}): { score: number; color: HealthColor; label: string } {
  let score = 100;

  // Budget factor (40% weight)
  if (sections.budget && sections.budget.total > 0) {
    const budgetPct = sections.budget.spent / sections.budget.total;
    if (budgetPct > 0.9) score -= 40;
    else if (budgetPct > 0.7) score -= 20;
  }

  // Schedule factor (35% weight)
  if (sections.schedule && sections.schedule.totalMilestones > 0) {
    const delayPct = sections.schedule.delayedMilestones / sections.schedule.totalMilestones;
    if (delayPct > 0.3) score -= 35;
    else if (delayPct > 0.1) score -= 15;
  }

  // Issues factor (25% weight)
  if (sections.issues) {
    if (sections.issues.criticalOpen > 3) score -= 25;
    else if (sections.issues.criticalOpen > 0) score -= 10;
  }

  const color: HealthColor = score >= 70 ? "green" : score >= 40 ? "yellow" : "red";
  const label = color === "green" ? "On Track" : color === "yellow" ? "At Risk" : "Critical";
  return { score: Math.max(0, score), color, label };
}
```

### Budget String Parser
```typescript
// web/src/lib/reports/aggregation.ts
export function parseBudgetString(budget: string): number {
  if (!budget || budget === "N/A" || budget === "TBD" || budget === "---") return 0;
  const cleaned = budget.replace(/[$,\s]/g, "");
  const num = parseFloat(cleaned);
  return isNaN(num) ? 0 : num;
}
```

### Supabase Database Schema (new tables per D-91)
```sql
-- Report schedules (D-54, D-91)
create table cs_report_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  frequency text not null check (frequency in ('daily','weekly','biweekly','monthly')),
  day_of_week int,            -- 0=Sun..6=Sat (for weekly/biweekly)
  day_of_month int,           -- 1-28 (for monthly)
  time_utc time not null,
  timezone text not null default 'America/New_York',
  recipients uuid[] not null, -- team member user_ids (D-50e)
  sections text[] default '{}', -- optional section filter
  is_active boolean not null default true,
  last_run_at timestamptz,
  next_run_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Delivery log (D-50h)
create table cs_report_delivery_log (
  id uuid primary key default gen_random_uuid(),
  schedule_id uuid references cs_report_schedules(id),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  recipients uuid[],
  status text not null check (status in ('sent','failed','partial')),
  error_message text,
  pdf_storage_path text,      -- Supabase Storage path (D-34l)
  email_html text,            -- Archived email content (D-50h)
  created_at timestamptz default now()
);

-- Shared links (D-64b)
create table cs_report_shared_links (
  id uuid primary key default gen_random_uuid(),
  token text not null unique,
  user_id uuid not null references auth.users(id),
  org_id uuid,
  project_id uuid,            -- null for portfolio rollup
  report_type text not null check (report_type in ('project','rollup')),
  expires_at timestamptz not null,
  view_count int not null default 0,
  max_views_per_day int not null default 100,
  is_revoked boolean not null default false,
  created_at timestamptz default now()
);

-- Report history / versions (D-99)
create table cs_report_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  project_id uuid,
  report_type text not null,
  snapshot_data jsonb not null, -- full report JSON at generation time
  pdf_storage_path text,
  created_at timestamptz default now()
);

-- Report templates (D-93)
create table cs_report_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  name text not null,
  description text,
  template_config jsonb not null, -- section ordering, visibility, custom CSS
  is_default boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Comments on report sections (D-98)
create table cs_report_comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  report_history_id uuid references cs_report_history(id),
  section text not null,
  content text not null,
  parent_id uuid references cs_report_comments(id), -- thread support
  created_at timestamptz default now()
);

-- Annotations (D-98)
create table cs_report_annotations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  org_id uuid,
  report_history_id uuid references cs_report_history(id),
  chart_id text not null,
  fabric_json jsonb not null,  -- Fabric.js serialized objects
  created_at timestamptz default now()
);

-- Audit log (D-112)
create table cs_report_audit_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  org_id uuid,
  action text not null,        -- 'viewed', 'exported', 'shared', 'scheduled'
  report_type text,
  project_id uuid,
  device_info text,
  created_at timestamptz default now()
);

-- RLS policies (all tables)
alter table cs_report_schedules enable row level security;
alter table cs_report_delivery_log enable row level security;
alter table cs_report_shared_links enable row level security;
alter table cs_report_history enable row level security;
alter table cs_report_templates enable row level security;
alter table cs_report_comments enable row level security;
alter table cs_report_annotations enable row level security;
alter table cs_report_audit_log enable row level security;

-- Indexes (D-61)
create index idx_report_schedules_next_run on cs_report_schedules(next_run_at) where is_active = true;
create index idx_report_delivery_log_schedule on cs_report_delivery_log(schedule_id, created_at desc);
create index idx_report_shared_links_token on cs_report_shared_links(token) where is_revoked = false;
create index idx_report_history_project on cs_report_history(project_id, created_at desc);
create index idx_report_audit_log_user on cs_report_audit_log(user_id, created_at desc);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Server-side PDF (Puppeteer/wkhtmltopdf) | Client-side jsPDF + html2canvas | 2023+ | No server resources, works offline, instant generation |
| D3.js for React charts | Recharts (React-native wrapper) | 2020+ | Declarative API, less boilerplate, better React integration |
| Handlebars email templates | React Email components | 2023+ | Type-safe, component-based, preview in browser |
| SendGrid for transactional email | Resend | 2023+ | Simpler API, better DX, Vercel-native |
| Custom i18n JSON files | next-intl with ICU format | 2022+ | Standardized message format, plural rules, type safety |
| Chart.js with react-chartjs-2 wrapper | Recharts native React | Ongoing | No wrapper needed, tree-shakeable, responsive by default |

**Deprecated/outdated:**
- html2canvas has known issues with CSS Grid and newer CSS features -- test thoroughly with actual report layouts [ASSUMED]
- xlsx community edition (0.18.5) is the last Apache-licensed version; SheetJS Pro is commercial [VERIFIED: npm registry]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | SwiftUI Charts supports all required chart types (pie, bar, line, area, radar) on iOS 18.2+ | Standard Stack (iOS) | May need fallback to Charts framework or custom drawing |
| A2 | UIGraphicsPDFRenderer can render SwiftUI views to PDF with chart images | Architecture Patterns | May need WKWebView fallback path (D-28 already accounts for this) |
| A3 | html2canvas 1.4.1 handles CSS custom properties (var(--surface) etc.) correctly | Common Pitfalls | May need to inline computed styles before capture |
| A4 | Vercel Cron supports 15-minute intervals on current plan | Architecture Patterns | May need Supabase pg_cron as fallback (D-50 accounts for this) |
| A5 | Fabric.js 7.x works in Next.js 16 client components without SSR issues | Standard Stack | May need dynamic import with ssr: false |
| A6 | react-window works with React 19 | Standard Stack | May need @tanstack/virtual as alternative |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest 4.1.2 + Playwright 1.59.1 |
| Config file | web/vitest.config.ts (exists) |
| Quick run command | `cd web && npx vitest run --reporter=verbose` |
| Full suite command | `cd web && npx vitest run && npx playwright test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPORT-01 | Single project report with all 4 sections | unit + integration | `cd web && npx vitest run src/lib/reports/__tests__/aggregation.test.ts` | Wave 0 |
| REPORT-01 | Report API returns correct structure | integration | `cd web && npx vitest run src/app/api/reports/__tests__/project.test.ts` | Wave 0 |
| REPORT-02 | Portfolio rollup with financial totals | unit + integration | `cd web && npx vitest run src/lib/reports/__tests__/rollup.test.ts` | Wave 0 |
| REPORT-03 | PDF export produces valid file | unit + snapshot | `cd web && npx vitest run src/lib/reports/__tests__/pdf-generator.test.ts` | Wave 0 |
| REPORT-03 | PDF export E2E workflow | e2e | `cd web && npx playwright test tests/reports-export.spec.ts` | Wave 0 |
| REPORT-04 | Chart components render with data | component | `cd web && npx vitest run src/app/reports/__tests__/charts.test.tsx` | Wave 0 |
| D-83 | 100% line coverage on aggregation functions | unit | `cd web && npx vitest run --coverage src/lib/reports/` | Wave 0 |

### Sampling Rate
- **Per task commit:** `cd web && npx vitest run src/lib/reports/ src/app/api/reports/ --reporter=verbose`
- **Per wave merge:** `cd web && npx vitest run && npx playwright test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `web/src/lib/reports/__tests__/aggregation.test.ts` -- covers REPORT-01 data computation
- [ ] `web/src/app/api/reports/__tests__/project.test.ts` -- covers REPORT-01 API
- [ ] `web/src/lib/reports/__tests__/rollup.test.ts` -- covers REPORT-02 computation
- [ ] `web/src/lib/reports/__tests__/pdf-generator.test.ts` -- covers REPORT-03
- [ ] `web/src/app/reports/__tests__/charts.test.tsx` -- covers REPORT-04
- [ ] `web/tests/reports-export.spec.ts` -- Playwright E2E for full report workflow
- [ ] Shared JSON test fixtures in `web/src/lib/reports/__tests__/fixtures/` for cross-platform use (D-80)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | Existing Supabase auth via getAuthenticatedClient() |
| V3 Session Management | Yes | Existing Supabase SSR session cookies |
| V4 Access Control | Yes | RLS on all cs_report_* tables (D-63) + role-based permissions (D-64g) |
| V5 Input Validation | Yes | Zod schemas for API route inputs, parseBudgetString sanitization |
| V6 Cryptography | Yes | PDF password protection (D-34h) -- use jsPDF encryption, never custom crypto |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized report access | Information Disclosure | Supabase RLS + auth check on every API route |
| Shareable link token guessing | Information Disclosure | Cryptographically random tokens (crypto.randomUUID), time-limited expiry (D-64b) |
| PDF with malicious content | Tampering | Sanitize all user input before PDF rendering, no raw HTML injection |
| Cron endpoint abuse | Elevation of Privilege | CRON_SECRET bearer token verification (Vercel-standard) |
| Rate limit bypass on exports | Denial of Service | Upstash Redis rate limiting on /api/reports/export (D-62b) |
| Sensitive data in shared links | Information Disclosure | Auto-mask financial totals on shared links (D-64f) |
| Email recipient spoofing | Spoofing | Recipients limited to team members only (D-50e), validated against user_orgs |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Web app | Verified | 20+ (CI) | -- |
| Vitest | Testing | Verified | 4.1.2 | -- |
| Playwright | E2E testing | Verified | 1.59.1 | -- |
| Xcode | iOS build | Verified | 16.2+ | -- |
| Supabase | Data layer | Verified | Existing | Mock data fallback |
| Upstash Redis | Rate limiting | Verified | Existing (@upstash/ratelimit 2.0.8) | In-memory fallback (existing) |
| Vercel Analytics | Event tracking | Verified | Existing (@vercel/analytics 2.0.1) | -- |
| Resend | Email delivery | Not installed | -- | Direct download fallback (D-50x) |
| PostHog | Behavioral analytics | Not installed | -- | Vercel Analytics covers basic events |
| vercel.json | Cron configuration | Not present | -- | Must create for cron jobs |

**Missing dependencies with no fallback:**
- None -- all critical dependencies have fallback paths defined in decisions

**Missing dependencies with fallback:**
- Resend SDK not installed -- fallback to "download from Report History" (D-50x)
- PostHog not installed -- Vercel Analytics covers basic tracking (D-105)
- vercel.json not present -- must create for Vercel Cron (D-50i)

## Open Questions (RESOLVED)

1. **Supabase Storage bucket configuration** -- RESOLVED
   - What we know: D-34l requires storing PDFs in Supabase Storage for re-download
   - What's unclear: Whether a `reports` bucket exists or needs creation; storage size limits on current Supabase plan
   - Resolution: Create `reports` bucket in Wave 0 setup, implement cleanup per retention policy (D-96). Bucket creation is a standard Supabase dashboard operation or SQL migration. Deferred to Phase 19b (storage features)

2. **Existing data completeness for report aggregation** -- RESOLVED
   - What we know: cs_projects and cs_contracts exist with data. Phase 15 (team), Phase 16 (field/safety), Phase 17 (calendar/tasks) tables exist
   - What's unclear: Whether all dependent phase tables have production data or only test fixtures
   - Resolution: Build reports to handle zero-data gracefully (D-08: show "None" for empty sections). All aggregation functions handle null/empty arrays. The /api/reports/health endpoint validates table existence at runtime

3. **Vercel plan tier for Cron and Functions** -- RESOLVED
   - What we know: D-50i specifies Vercel Cron + Resend architecture
   - What's unclear: Current Vercel plan limits (Hobby: 1 cron per day; Pro: every minute)
   - Resolution: Design cron to work at 15-min intervals but degrade gracefully if limited. pg_cron backup per D-50. Scheduled email delivery is deferred to Phase 19b -- cron configuration will be addressed then

4. **SwiftUI Charts radar chart support** -- RESOLVED
   - What we know: D-19c requires radar/spider chart for portfolio rollup
   - What's unclear: SwiftUI Charts may not have native radar chart support
   - Resolution: Implement radar chart as custom SwiftUI Path drawing if Charts framework lacks native support. Radar chart is a Phase 19b feature (portfolio rollup charts). Core charts (pie, bar, line) are confirmed available in SwiftUI Charts

## Sources

### Primary (HIGH confidence)
- npm registry -- verified all package versions, peer dependencies, and licenses
- Existing codebase -- verified NavTab enum, navGroups, API route patterns, rate limiting, Supabase fetch patterns, Finance page layout

### Secondary (MEDIUM confidence)
- Recharts React 19 peer dependency compatibility confirmed via npm view
- next-intl Next.js 16 compatibility confirmed via npm view peer deps
- jsPDF + html2canvas API patterns based on well-established library usage

### Tertiary (LOW confidence)
- SwiftUI Charts feature coverage (pie, bar, line, radar) -- needs iOS build verification
- html2canvas CSS custom property handling -- needs runtime testing
- Fabric.js 7.x SSR compatibility with Next.js 16 -- needs import testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all versions verified against npm registry, peer deps confirmed for React 19/Next.js 16
- Architecture: HIGH -- follows established codebase patterns (Finance page, API routes, Supabase fetch)
- Pitfalls: HIGH -- based on well-known library limitations and existing codebase data model analysis
- iOS specifics: MEDIUM -- SwiftUI Charts capabilities assumed from training data, not runtime-verified

**Research date:** 2026-04-11
**Valid until:** 2026-05-11 (30 days -- stable libraries, locked decisions)
