# Phase 19: Reporting & Dashboards - Context

**Gathered:** 2026-04-11 (updated)
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can view aggregated metrics across their projects and export shareable reports. Covers single-project summary reports, cross-project financial rollup dashboards, PDF/CSV/Excel/JSON/PowerPoint export, chart visualizations, scheduled email report delivery, shareable report links, AI-powered insights, report templates, collaboration features, and comprehensive analytics. Both iOS and web platforms with full feature parity.

</domain>

<decisions>
## Implementation Decisions

### Report Content & Sections
- **D-01:** Executive summary format — one-page overview with key metrics, status badges, and top items per section
- **D-02:** All four data sections included: Budget & Financials, Schedule & Milestones, Issues & Risks, Team & Activity
- **D-03:** Dedicated Reports tab in nav (both iOS and web)
- **D-04:** Reports generated on-the-fly from current data — no persistence/storage needed for on-demand views
- **D-05:** Stat cards + lists layout — KPI cards at top, sections as compact lists below
- **D-06:** Project lifetime date range — all-time data, no date picker (consistent across all time-series charts)
- **D-07:** Color-coded health score (green/yellow/red) based on budget %, schedule %, and open critical issues — hardcoded defaults plus per-project customizable thresholds
- **D-08:** Always show all sections — empty sections display "None" message to confirm data was checked; missing feature data shows zero counts
- **D-09:** iOS layout is mobile-optimized — same data, single-column stacked cards (iPhone), split view on iPad (NavigationSplitView: project list left, report right)
- **D-10:** Report header shows project name, client name, date generated, and health status — customizable company branding (logo + colors)
- **D-11:** Clickable items in Issues & Risks section — link to detail pages (web) / tappable (iOS)
- **D-12:** Simple progress bars for schedule visualization (% complete per milestone), not Gantt
- **D-13:** Budget shows summary totals + % — contract value, total billed, % complete, change order net, retainage (5-6 key numbers, no line items)
- **D-14:** Team section shows counts + 3-5 most recent activity feed entries
- **D-15:** Include document and photo counts per section (from Phase 13 and Phase 16 data)
- **D-16:** Safety incidents: count + severity breakdown (minor/moderate/serious) + days since last incident + full incident list when items exist
- **D-16b:** Per-section data freshness timestamps + report-level generation timestamp
- **D-16c:** Feature coverage indicator per project in rollup — shows 'data completeness' badge (e.g., 'Project X: 4/6 features active')
- **D-16d:** AI-generated Key Insights section at top of each report — auto-generated analysis of report data. Included in web view, PDF export, and scheduled email
- **D-16e:** AI recommendations inline per section + consolidated AI Action Items summary section — actionable buttons to create tasks or notifications from insights

### Chart Approach
- **D-17:** Web charting: Recharts library — React-native, declarative components, good Next.js compatibility
- **D-18:** iOS charting: SwiftUI Charts — Apple's native framework, zero dependencies, iOS 16+ (min is 18.2+). Full parity with web chart types
- **D-19:** Chart types matched to data — budget: pie chart (spent vs remaining), schedule: bar chart (milestones % complete), safety: line chart (incidents over time monthly)
- **D-19b:** Additional charts: activity/notification trends (line chart from Phase 14), team utilization (stacked bar: members per role/trade + horizontal bar: workload per member + heatmap: member x week), documents/photos (area chart cumulative + bar chart monthly + stat card counters), tasks (burndown chart + created-vs-completed bar chart)
- **D-19c:** Portfolio rollup charts: grouped bar for financial comparison + radar/spider chart for multi-dimensional health + monthly spend trend (aggregate line + per-project lines + stacked area toggle)
- **D-20:** Full chart interactivity — hover tooltips with exact values, click-to-filter associated data lists, zoom/pan/brush selection on time series, click-to-drill on all charts
- **D-21:** Charts always use light theme (white background) — consistent with PDF output. Print-friendly CSS @media print rules for web page printing
- **D-22:** Charts appear in both Reports tab and as small mini chart widgets on individual project detail pages (same chart type but smaller, tap/click navigates to full Reports view)
- **D-23:** Inline labels (color dot + label) — no separate legend block
- **D-24:** Budget pie: two segments (spent vs remaining) showing % complete at a glance
- **D-25:** Safety line chart: monthly data points
- **D-26:** Schedule bar chart: top 5-8 milestones for readability
- **D-26b:** Charts support subtle entrance animation by default (bars grow, lines draw, pie slices expand), with option to disable in settings. Smooth transitions on data updates
- **D-26c:** Individual chart export as PNG + SVG — small download icon per chart
- **D-26d:** Charts support high contrast mode (detect OS settings, add patterns like hatching/dots for colorblind users) + full keyboard navigation + screen reader with ARIA labels and hidden data table equivalents
- **D-26e:** Responsive chart sizing using ResponsiveContainer (Recharts) with breakpoint-aware minimum sizes
- **D-26f:** Tabbed sections as primary view (Financial, Schedule, Safety, Team, Activity) + option to see single scrollable page + configurable dashboard (single saved layout per user, drag-and-drop rearrange, toggle charts on/off)
- **D-26g:** Toggle between 'Charts + Data' and 'Charts Only' view modes + full-screen chart mode on click
- **D-26h:** Independent loading per chart with prioritized rendering order (budget/schedule first, then safety, then activity/team)
- **D-26i:** Empty chart states: placeholder illustrations with contextual messaging per chart domain (e.g., safety incident illustration with "No safety incidents recorded")
- **D-26j:** Built-in conditional formatting on report tables: health-based coloring auto-applied + user-defined custom conditional formatting rules

### PDF Export Strategy
- **D-27:** Web PDF: client-side jsPDF + html2canvas — no server resources needed, works offline
- **D-28:** iOS PDF: UIGraphicsPDFRenderer as primary (native, offline) with WKWebView capture as fallback option
- **D-29:** Export triggered by "Export PDF" button on report view — opens preview in new tab with download button
- **D-30:** PDF includes charts rendered as static images — self-contained document
- **D-31:** PDF file named: "{ProjectName}-Report-{YYYY-MM-DD}.pdf"
- **D-32:** PDF has header (project/company name) + footer (page number + generated date + optional confidentiality notice) on each page
- **D-33:** PDF uses light/print theme — white background, dark text, colored accents
- **D-34:** PDF export available for both single-project reports and cross-project rollup
- **D-34b:** Auto-detect paper size by user's region — US/Canada: Letter, international: A4
- **D-34c:** Auto-detect orientation — portrait for single-project reports (text-heavy), landscape for portfolio rollup (table/chart-heavy)
- **D-34d:** Auto-generated table of contents with clickable links on page 1 of PDF
- **D-34e:** Customizable company branding on PDFs — upload logo, set brand colors. Applies to header/footer
- **D-34f:** Confidentiality footer (toggleable: "Confidential — [Company Name]") + DRAFT watermark on preview/test PDFs
- **D-34g:** Optional executive summary text area at export time — user types notes that appear as 'Executive Summary' section at start of PDF
- **D-34h:** Password protection — checkbox at export time with password field. One-time per export
- **D-34i:** QR code on first page linking to the live web report version
- **D-34j:** Smart page breaks (never break mid-chart/mid-table) + section-per-page preference when content allows
- **D-34k:** Tagged PDFs for accessibility (PDF/UA compliance — structural tags, headings, tables, alt text on charts)
- **D-34l:** Stored in Supabase Storage for re-download from Report History
- **D-34m:** Batch export — 'Export All Reports' button generates per-project PDFs + rollup PDF, bundled as ZIP. Background job processing for large portfolios with notification when ready
- **D-34n:** Scheduled reports: pre-render PDF template client-side at schedule creation time; cron job injects fresh data into template

### Cross-Project Rollup
- **D-35:** All financial metrics: total contract value, total billed vs remaining, change order impact, per-project comparison
- **D-36:** Layout: summary KPI cards + sortable project table + charts — comprehensive portfolio dashboard
- **D-37:** Non-financial metrics included: schedule health per project, open issues rollup, team utilization, safety across portfolio
- **D-38:** Horizontal timeline bars showing all projects' start/end dates (Gantt-style portfolio view)
- **D-39:** Sortable columns + expanded filters: status (Active/Delayed/Completed) + date range, project type, client, budget range. Filters persist via URL params (shareable, bookmarkable) with user-saved defaults as fallback
- **D-40:** Click project row to navigate to its individual report (drill-down)
- **D-41:** Portfolio-level aggregate health score + per-project health badges
- **D-42:** Show all projects with status badges — active by default, toggle for completed
- **D-43:** Monthly spend trend line chart showing portfolio financial trends over time (aggregate + per-project lines + stacked area toggle)
- **D-44:** iOS: segmented control in Reports tab ("Project Report" / "Portfolio Rollup") + separate nav item
- **D-45:** On-load + manual refresh (pull-to-refresh iOS, refresh button web) + auto-refresh polling every 5 min + Supabase Realtime subscriptions for live updates + portfolio auto-refresh as executive monitoring view
- **D-46:** Virtual scrolling at 25+ projects in the portfolio table (react-window or similar). Server-side cap at 200 projects with notice
- **D-46b:** Period comparison support — API accepts optional compare_period param. Returns current + previous period with delta (% change)

### Export & Delivery
- **D-47:** PDF + CSV + Excel (.xlsx with SheetJS, formatted columns, multiple sheets, embedded charts) + JSON API export + PowerPoint (.pptx with pptxgenjs, each section as a slide with chart images)
- **D-48:** CSV: two options — 'Summary CSV' (flat table per project, key metrics as columns) and 'Detailed CSV' (multi-section with all data)
- **D-49:** Email/scheduled reports included — portfolio rollups only get scheduled delivery. Custom frequency: user picks frequency (daily/weekly/biweekly/monthly), day, and time. No presets
- **D-50:** Email delivery via Resend API. Primary infrastructure: Vercel Cron + Resend. Supabase pg_cron as backup trigger

### Email/Schedule Management
- **D-50b:** Three-point schedule management: dedicated section in Reports tab + per-report 'Schedule this' quick toggle + entry in app Settings
- **D-50c:** Email content: branded HTML email with ConstructionOS header/logo/colors, inline metrics summary (health score, budget %, key numbers), PDF attachment, and link to live web report
- **D-50d:** Notifications on delivery AND failure — ties into Phase 14 notification system. Full event notifications: delivery, failure, health changes, shared link accessed, batch export complete
- **D-50e:** Recipients: team members only (from Phase 15 crew data). No external email addresses
- **D-50f:** Schedule features: pause/resume toggle + create/delete + auto-pause on inactive projects (Completed/On Hold status)
- **D-50g:** Manual 'Send now' button on each schedule entry + schedule only delivery
- **D-50h:** Delivery log: cs_report_delivery_log Supabase table with timestamp, schedule_id, recipients, status, error message. Full content archive: stored PDF link + HTML email content
- **D-50i:** Primary architecture: Vercel Cron runs on schedule, queries due schedules from DB, generates PDFs, calls Resend
- **D-50j:** User's local timezone for schedule execution
- **D-50k:** Schedule management available on both iOS and web — full feature parity
- **D-50l:** All report sections included by default, with optional section picker for customization
- **D-50m:** No unsubscribe link — recipients are team members managed by the sender
- **D-50n:** On PDF generation failure during scheduled run: send email without PDF, note the failure. Notification emitted
- **D-50o:** 'Send test to self' button for previewing scheduled report emails before activating
- **D-50p:** One report (portfolio rollup) per schedule entry. Create multiple schedules for different configurations
- **D-50q:** Branded noreply from address (reports@constructionos.com or configured domain)
- **D-50r:** Auto-generated email subject line (e.g., 'ConstructionOS Portfolio Report — Week of Apr 14, 2026')
- **D-50s:** Unlimited schedules per user account. No rate limits on email delivery
- **D-50t:** Schedule UI shows next run time alongside frequency and last delivery status
- **D-50u:** iOS schedule management: card rows with swipe actions for quick operations (list view + card-based)
- **D-50v:** Concurrency protection: Supabase row lock prevents overlapping cron runs
- **D-50w:** Request deduplication: client SWR + server-side fingerprinting (belt and suspenders)
- **D-50x:** Resend API down: fallback to direct download — store report, notify user: 'Your scheduled report is ready — download from Report History'

### API Design
- **D-51:** One API route per report type: /api/reports/project/[id] and /api/reports/rollup
- **D-52:** Separate PDF export endpoint: /api/reports/export/[type]
- **D-53:** Single API call returns full report (all sections at once). Hybrid response: pre-computed aggregates for summary stats + raw data points for chart time-series
- **D-54:** Dedicated /api/reports/schedule endpoint for email schedule CRUD
- **D-55:** iOS fetches from web API (same endpoints) as primary — local aggregation fallback when offline (full parity with web API logic in Swift)
- **D-56:** Partial report with notice when a section fails — never block entire report for one section failure. 10s timeout per section with retry button on failed sections
- **D-56b:** /api/reports/health endpoint — verifies all required tables, views, Resend config, schema version. Used by both iOS and web
- **D-56c:** Debug info: X-Report-Debug response header + _meta field in JSON response with timing per section and view/query source
- **D-56d:** Pre-flight schema check at startup — validates table existence before querying. Reports missing schema gracefully
- **D-56e:** Data validation: silent correction — clamp values to valid ranges (budget capped at 100%, floor counts at 0) without flagging anomalies
- **D-56f:** Structured error responses: HTTP status code + { error: { code: 'REPORT_SECTION_TIMEOUT', message: '...', section: 'budget', retryable: true } }
- **D-56g:** Database views: standard views for light aggregations, materialized views for heavy ones with periodic refresh. Stale materialized views fall back to raw queries
- **D-56h:** Report API webhook events for Zapier/Make integration on report generation

### Performance & Caching
- **D-57:** Compute on demand for on-demand reports. Cache for scheduled reports (snapshot at generation time)
- **D-58:** Skeleton loading screens matching stat cards + section layout
- **D-59:** Multi-layer caching: client SWR (5 min TTL) + server in-memory (1 min TTL for DB views) + Vercel Edge Cache with tags per project. Invalidate on data write
- **D-60:** PDF generation is client-side (jsPDF) — near-instant for single reports. Batch exports run as background jobs
- **D-61:** Targeted database indexes on frequently aggregated columns (project_id + status, project_id + created_at)
- **D-62:** Progressive loading: summary KPI cards <1s, full charts and sections <3s
- **D-62b:** Global rate limit via Upstash Redis + report-specific tighter limits on expensive operations (PDF generation at 10 req/min, batch export limited)
- **D-62c:** Performance monitoring: Vercel Analytics for API times + custom /api/reports/metrics endpoint with p50/p95 response times per section

### Access Control & Sharing
- **D-63:** RLS-enforced — users only see reports for projects they have access to. All authenticated users get all report features (no role-based feature restrictions on report type)
- **D-64:** PDF documents: optional password protection (prompt at export time)
- **D-64b:** Shareable links with time-limited token (30 day expiry). Full report, read-only. Live data (always current). View count tracking. Manual revoke + auto expire
- **D-64c:** Shared link pages show user's custom company branding
- **D-64d:** Shareable link generation and management available on both iOS and web
- **D-64e:** Rate limit on shared link access: max 100 views per link per day
- **D-64f:** Automatic sensitive field masking on shared links — system auto-masks financial totals and personal names, shows only percentages and aggregates
- **D-64g:** Role-based permissions matrix with tiered defaults: Admin (full), Manager (view + export + share), Viewer (view only). Customizable per org. Three-tier inheritance: org defaults → project overrides → report-level overrides

### Navigation & Placement
- **D-65:** iOS: Reports tab in Intel group (alongside Market, Analytics), icon: chart.bar.doc.horizontal
- **D-66:** Web: Reports in main sidebar nav, route at /reports, grouped with Analytics and Finance
- **D-66b:** Feature discovery: Reports tab in nav + first-time tooltip tour (dismissable, re-accessible from help menu) + contextual links on related pages ('View full report →' on project detail)
- **D-66c:** Demo report with sample construction data for new users with no projects
- **D-66d:** In-app help section + external documentation link ('Learn more')

### iOS-Specific Features
- **D-67:** WidgetKit Home Screen widgets showing health score, budget status, key KPIs (small/medium/large sizes)
- **D-68:** Full offline with sync — cache all report data locally, generate reports offline from cached data, queue exports for when network returns
- **D-69:** Subtle haptic feedback on chart interactions (light tap on data point selection, tab switches)
- **D-70:** Siri Shortcuts: 'Show project report' and 'Portfolio health' — deep links to Reports tab
- **D-71:** Pinch-to-zoom on charts, landscape rotation support for wider chart viewing
- **D-72:** Apple Watch complications — portfolio health score and project count on Watch face
- **D-73:** Dynamic Island / Live Activity for batch PDF export progress
- **D-74:** Spotlight Search indexing — project reports searchable from home screen (CoreSpotlight)
- **D-75:** VoiceOver: semantic announcements with both raw values and interpretation (e.g., "Budget: 92% spent — at risk")
- **D-76:** CarPlay health summary (color-coded health badge + project count) + AirPlay/external display presentation mode for meetings (chart-only view optimized for large screens)

### Testing Strategy
- **D-77:** Unit tests (Vitest) with fixtures + integration tests against test DB for report data accuracy
- **D-78:** PDF testing: snapshot tests + manual visual review + visual regression (Percy/Chromatic) + content verification (pdf-parse)
- **D-79:** Chart testing: component tests (Vitest + React Testing Library) + Playwright visual screenshots
- **D-80:** Shared JSON test fixtures for cross-platform consistency (Swift XCTests + TypeScript Vitest read same fixtures). Trust API for cross-platform number parity
- **D-81:** E2E Playwright test: full report workflow (navigate → load → verify charts → export PDF → verify download)
- **D-82:** Email testing: mock Resend in unit tests + Resend sandbox in integration tests
- **D-83:** 100% line coverage for aggregation/computation functions. Other code at 70%+
- **D-84:** CI generates sample project report + portfolio rollup PDF from fixture data, archived as build artifacts
- **D-85:** iOS: swift-snapshot-testing for visual regression + XCUITest for functional interaction

### Localization & Accessibility
- **D-86:** Full i18n from day one — next-intl (web) + String Catalogs (iOS). All report labels and section titles translatable. Multi-language support for every country
- **D-87:** User-selected currency for financial formatting. Locale-aware date/number formatting as default, ISO format available as option
- **D-88:** Full keyboard + screen reader accessibility: ARIA labels, keyboard-navigable data points, hidden data table alternatives for charts
- **D-89:** Tagged PDFs for accessibility (PDF/UA compliance)
- **D-90:** High contrast mode — detect OS settings, adjust chart colors and patterns

### Database Schema
- **D-91:** cs_report_* table prefix: cs_report_schedules, cs_report_delivery_log, cs_report_history, cs_report_shared_links, cs_report_templates, cs_report_annotations, cs_report_comments, cs_report_audit_log
- **D-92:** org_id column on all new tables for multi-tenant support
- **D-93:** Report templates: built-in templates as static JSON files in repo + user-created templates in Supabase (cs_report_templates)
- **D-94:** Custom template builder: section ordering + visibility (basic), full visual editor (advanced), JSON/code-based templates (power user). Tiered customization

### Migration & Rollout
- **D-95:** Feature flag gradual rollout (10% → 50% → 100%) + beta opt-in toggle in Settings + eventual full launch
- **D-96:** User-configurable data retention period (6mo, 1yr, 2yr, unlimited) for stored reports and delivery logs
- **D-97:** Full data export for backup — ZIP with all stored PDFs, schedules, templates, delivery logs + automated Supabase backups

### Collaboration
- **D-98:** Comments on report sections (thread-based, cs_report_comments table) + visual annotation/drawing tools on charts (circles, arrows, highlights via Fabric.js or similar). Annotations exportable in PDF
- **D-99:** Report version history with full diff — every generation creates a version. Visual diff highlights metric changes (up/down), new issues, resolved items

### Notifications & Subscriptions
- **D-100:** Health score change notifications with default alerts on all color transitions + user-customizable overrides
- **D-101:** Notification preferences: per-type toggles + per-project granularity + daily digest mode option
- **D-102:** Metric threshold alerts: custom thresholds per project per metric ('Alert when budget > 85%') + change detection for unexpected movements (>X% change)

### Automation
- **D-103:** Built-in automation trigger templates (health-triggered auto-sends) + custom if-then rule builder for power users

### Embedding
- **D-104:** Individual chart embed codes (iframe) for external sites (Notion, dashboards) + full report embed. Auth via share token

### Analytics
- **D-105:** Vercel Analytics for basic events (report_viewed, report_exported, schedule_created) + PostHog for detailed behavioral analytics (funnels, cohorts, feature usage)

### Search
- **D-106:** Filter + sort on report list (project, date, health status) + full-text search across report content

### White-labeling
- **D-107:** Two tiers: basic white-labeling (logo + colors) for all users. Full white-labeling (custom domain, email domain) as enterprise feature

### Keyboard Shortcuts
- **D-108:** Standard shortcuts (Cmd+P print, Cmd+E export, Cmd+S share, Cmd+R refresh) + vim-like power user shortcuts (opt-in). Keyboard shortcut help panel (Cmd+?)

### Report Theming
- **D-109:** Built-in themes (Professional, Construction, Corporate, Minimal, Executive) + custom CSS themes for enterprise + branded theme from white-labeling settings

### Bulk Operations
- **D-110:** Bulk delete history, bulk revoke shared links, bulk schedule management (pause/resume/update/delete), bulk re-export (regenerate multiple PDFs)

### Bookmarks & Favorites
- **D-111:** Pin favorite reports to top of list + custom personal dashboard built from bookmarked charts (drag-and-drop arrangement)

### Audit Trail
- **D-112:** Full access log (user, timestamp, report type, project, device/browser in cs_report_audit_log) + summarized dashboard showing access patterns and popular reports

### Offline (Web)
- **D-113:** Full PWA offline — Service Worker caches report assets and data. Installable as PWA. Full offline report viewing and generation

### External Integrations
- **D-114:** QuickBooks-compatible financial export + open JSON API endpoints for external tools + webhook events to Zapier/Make + full competitor tool integration deferred to v3.0
- **D-115:** Generic CSV/Excel import wizard with column mapping now. Procore-specific mapping later. Full competitor migration deferred to v3.0

### Industry Benchmarks
- **D-116:** Multi-source benchmarking: static published data (AGC, ENR) as baseline + AI-estimated adjustments for context + user-base aggregates when available

### Comparison Tools
- **D-117:** Project vs project side-by-side comparison + time period comparison (using version history snapshots) + industry benchmarking

### Scheduling Calendar
- **D-118:** Report schedule events integrated into Phase 17 calendar + standalone mini-calendar in Reports tab + sortable list view of upcoming deliveries

### Report Permissions Inheritance
- **D-119:** Three-tier inheritance: org defaults → project overrides → report-level overrides

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — REPORT-01 through REPORT-04 acceptance criteria

### Existing financial patterns
- `web/src/app/finance/page.tsx` — Finance page with inline styles, stat cards, mock financial data — layout pattern to follow
- `web/src/app/schedule/GanttChart.tsx` — Existing Gantt chart component (custom CSS, not a charting library)
- `web/src/app/schedule/RollupTimeline.tsx` — Existing timeline rollup component — pattern for portfolio timeline view

### Data models
- `ready player 8/SupabaseService.swift` — All Supabase DTOs and table schemas (cs_projects, cs_contracts, budget fields)
- `web/src/lib/supabase/fetch.ts` — Web Supabase fetch utilities

### Prior phase context
- `.planning/phases/13-document-management-foundation/13-CONTEXT.md` — Document data available for report inclusion
- `.planning/phases/14-notifications-activity-feed/14-CONTEXT.md` — Activity feed data for team section + notification integration
- `.planning/phases/15-team-crew-management/15-CONTEXT.md` — Team/crew data for utilization metrics + recipient management
- `.planning/phases/16-field-tools/16-CONTEXT.md` — Field photos and safety incident data
- `.planning/phases/17-calendar-scheduling/17-CONTEXT.md` — Schedule/task/milestone data + calendar integration for report schedules

### Theme and styling
- `ready player 8/ContentView.swift` — Theme struct (colors: bg, surface, accent, gold, cyan, green, red, purple, text, muted)

### Libraries to add
- `recharts` — Web charting library (React-native, declarative)
- `jspdf` + `html2canvas` — Client-side PDF generation
- `resend` — Email delivery for scheduled reports
- `xlsx` (SheetJS) — Excel export
- `pptxgenjs` — PowerPoint export
- `next-intl` — Web internationalization
- `fabric` — Canvas annotation/drawing tools
- `posthog-js` / `posthog-node` — Behavioral analytics

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Finance page pattern** (`web/src/app/finance/page.tsx`): Inline styles with CSS custom properties, stat card layout, status color mapping — template for report layout
- **GanttChart** (`web/src/app/schedule/GanttChart.tsx`): Custom chart rendering — reference but will use Recharts instead
- **RollupTimeline** (`web/src/app/schedule/RollupTimeline.tsx`): Portfolio timeline view — similar to what the rollup needs
- **Theme struct** (ContentView.swift): All colors and premiumGlow modifier available for iOS report styling
- **useFetch hook**: Existing data fetching pattern for web client components
- **NavTab enum** (ContentView.swift): 13 tabs grouped into core/intel/wealth — Reports tab adds to intel group
- **Upstash Redis rate limiting**: Existing distributed rate limiting infrastructure — extend for report-specific limits
- **Vercel Analytics** (@vercel/analytics): Existing analytics — extend with report events
- **NotificationsStore** (NotificationsStore.swift): Phase 14 notification infrastructure — integrate report notifications
- **Phase 17 calendar**: Calendar infrastructure for report schedule integration

### Established Patterns
- Web pages use inline `style={}` objects with CSS custom properties (var(--surface), var(--accent), etc.)
- iOS views use `@State`/`@AppStorage` for local state, `SupabaseService.shared` for data
- API routes follow `/api/{resource}/route.ts` pattern with auth checks
- Data sync follows: load local → try remote → fall back to mock data
- Existing rate limiting via Upstash Redis on API routes
- Existing RLS policies on all 23 tables

### Integration Points
- **NavTab enum**: Add new `.reports` case to existing navigation
- **Web sidebar nav**: Add Reports link in nav groups (web/src/app/layout.tsx)
- **Supabase RLS**: Report API queries inherit existing v1.0 RLS policies. New tables need RLS policies
- **Notification system** (Phase 14): Emit notifications for report delivery, failure, health changes, shared link access, batch complete
- **Calendar system** (Phase 17): Report schedules appear as calendar events
- **Package.json**: Add recharts, jspdf, html2canvas, resend, xlsx, pptxgenjs, next-intl, fabric, posthog-js dependencies
- **Vercel Cron**: Add cron job for scheduled report delivery
- **Supabase Storage**: reports/ bucket for stored PDFs and email archives
- **CSP headers**: Update for iframe embedding support (X-Frame-Options changes for embed feature)

</code_context>

<specifics>
## Specific Ideas

- Reports should feel like the existing Finance page — stat cards at top, clean lists below, same inline style pattern
- Health score uses the app's color system: green = on track, amber/gold = at risk, red = delayed/critical
- PDF reports styled for construction industry — project name header, page numbers, professional but not overly formal. Customizable company branding
- Portfolio rollup should give an executive the complete picture at a glance — one screen tells them which projects need attention
- Safety reporting is comprehensive: severity breakdown + days-since-last + full incident list when relevant
- AI insights should provide actionable construction-specific recommendations (budget trending, safety patterns, schedule risks)
- Scheduled emails should have professional branded HTML with inline metrics + PDF attachment + web link
- Chart interactions should feel premium — smooth animations, responsive, with full keyboard and screen reader support
- Report templates should support tiered customization from simple section toggling to full visual editing
- External embedding enables construction firms to display project dashboards in their own client portals

</specifics>

<deferred>
## Deferred Ideas

- **Webhooks for external systems** — deferred, JSON API + Zapier webhooks covers basic integration
- **visionOS spatial 3D charts** — deferred to future iteration
- **Full competitor tool integrations (Procore, Buildertrend APIs)** — deferred to v3.0
- **OAuth login providers** — deferred to v2.1+

</deferred>

---

*Phase: 19-reporting-dashboards*
*Context gathered: 2026-04-11 (updated)*
