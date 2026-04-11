# Phase 19: Reporting & Dashboards - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-11 (updated)
**Phase:** 19-reporting-dashboards
**Mode:** Update session — expanded from 66 to 119 decisions across 48 areas
**Areas discussed:** Email/Scheduled Reports, Chart Details, Data Aggregation, PDF Generation, AI Insights, Report Permissions & Sharing, Mobile (iOS) Experience, Performance & Scale, Testing Strategy, Accessibility, Localization/i18n, Error States & Edge Cases, Onboarding/Discovery, Notification Integration, Data Export Formats, Report Versioning, Analytics & Usage Tracking, Real-time Updates, Printing Optimization, Collaboration, AI-Powered Recommendations, Report Scheduling Calendar, Integration with External Tools, Report Search, Offline-first Architecture, White-labeling, Keyboard Shortcuts, Report Theming, Bulk Operations, Database Schema, Security & Compliance, Migration Strategy, CarPlay / External Displays, Backup & Disaster Recovery, Notification Preferences, Report Comparison Tools, Report Permissions Matrix, Data Import, Report Bookmarks/Favorites, Report Permissions Inheritance, Data Validation Rules, Report Migration from Competitors, Report Annotations/Markup, Conditional Formatting, Report Subscriptions, Report Logging & Audit Trail, Report Automation Rules, Report Embedding

---

## Email/Scheduled Reports

| Option | Description | Selected |
|--------|-------------|----------|
| In-app settings panel | Dedicated section in Reports tab | |
| Per-report quick toggle | Inline modal on each report | |
| Settings page only | Centralized in Settings | |
| **All three combined** | All approaches integrated | ✓ |

**User's choice:** All three — dedicated section + per-report toggle + Settings entry
**Additional decisions:** Team members only for recipients, full custom frequency, branded HTML email with inline summary + PDF + web link, notify on delivery AND failure, pause/resume + auto-pause on inactive, manual 'Send now', delivery log in Supabase with full content archive, Vercel Cron + Resend primary, user's local timezone, both iOS and web, optional section picker, no unsubscribe, send without PDF on failure, test email to self, one report per schedule, branded noreply, auto-generated subject, unlimited schedules, show next run time, card rows with swipe (iOS), portfolio rollups only for scheduling

---

## Chart Details

**New charts added:** Activity/notification trends, team utilization (3 chart types), documents/photos (3 visualizations), task burndown + throughput, portfolio grouped bar + radar + spend trend variants
**Interactivity:** Full — hover, click-to-filter, zoom/pan/brush, click-to-drill
**Theme:** Always light (charts)
**Layout:** Tabbed sections + single scrollable + configurable dashboard (single saved layout)
**Animation:** Subtle entrance, toggleable in settings
**Export:** Individual PNG + SVG per chart
**Empty states:** Placeholder illustrations with contextual messaging
**iOS parity:** Full — same chart types via SwiftUI Charts
**Print:** CSS @media print stylesheet
**Responsive:** ResponsiveContainer + breakpoint-aware minimums
**View modes:** Charts + Data / Charts Only toggle + full-screen chart mode
**Loading:** Independent per chart with priority order
**All-time data range:** Maintained (D-06)

---

## Data Aggregation

**Query strategy:** Database views + fallback raw queries. Standard views for light, materialized for heavy
**Missing data:** Show sections with zero counts
**Response format:** Hybrid — pre-computed aggregates + raw chart data points
**Health thresholds:** Hardcoded defaults + per-project customizable
**Portfolio query:** All projects with 200-project server-side cap
**Caching:** Fresh for on-demand, snapshot for scheduled
**Schema guard:** Pre-flight schema check at startup
**iOS data:** API primary, full-parity local fallback when offline
**Filters:** Expanded beyond D-39 — status + date range, project type, client, budget range
**Filter persistence:** URL params + user-saved defaults
**Period comparison:** Supported via compare_period API param
**Debug info:** X-Report-Debug header + _meta JSON field
**Data validation:** Silent correction (clamp to valid ranges)
**Health endpoint:** /api/reports/health for both platforms

---

## PDF Generation

**Web library:** jsPDF + html2canvas (client-side, replaces Puppeteer)
**iOS:** UIGraphicsPDFRenderer primary + WKWebView fallback
**Orientation:** Auto-detect (portrait for project, landscape for rollup)
**TOC:** Auto-generated with clickable links
**Branding:** Customizable company logo + colors
**Watermarks:** Confidentiality footer + DRAFT on previews
**Notes:** Executive summary text field at export time
**Password:** Prompt at export time
**Preview:** Opens in new tab with download button
**QR code:** On first page linking to web report
**Accessibility:** Tagged PDFs (PDF/UA compliance)
**Storage:** Supabase Storage for re-download
**Batch:** ZIP bundle, background job processing
**Scheduled:** Pre-render template client-side, cron injects fresh data
**Paper size:** Auto-detect by region

---

## All Other Areas (Key Decisions)

- **AI Insights:** Auto-generated + inline recommendations + actionable buttons. In web, PDF, and email
- **Permissions:** Shareable links (30-day, revocable, live data, auto-masking). Three-tier role matrix
- **iOS:** Widgets, full offline, haptics, Siri, Watch, Dynamic Island, Spotlight, split view iPad, CarPlay + AirPlay
- **Performance:** Progressive load (<1s / <3s), virtual scrolling, multi-layer caching, multi-layer monitoring
- **Testing:** Unit + integration + E2E + snapshots + visual regression. 100% aggregation coverage. CI artifacts
- **i18n:** Full multi-language, user-selected currency, locale-aware formatting
- **Collaboration:** Section comments + visual annotation/drawing tools
- **Automation:** Built-in triggers + custom rule builder
- **Embedding:** Chart widgets + full report embed
- **White-labeling:** Two tiers (basic for all, enterprise custom domain)
- **Versioning:** Full history with visual diff
- **Benchmarks:** Multi-source (published + AI + user-base)
- **Schema:** cs_report_* prefix, org_id on all tables

---

## Claude's Discretion

Skeleton loading design, Recharts/SwiftUI Charts configuration, health score default thresholds, database index specifics, email template HTML/CSS, WidgetKit/Siri/Spotlight/Watch/Dynamic Island implementation, Fabric.js config, PostHog schema, Service Worker strategy, report drafts/cloning/tags features, and all remaining implementation details.

## Deferred Ideas

- Webhooks for external systems (JSON API + Zapier covers basics)
- visionOS spatial 3D charts
- Full competitor tool API integrations (v3.0)
- OAuth login providers (v2.1+)
