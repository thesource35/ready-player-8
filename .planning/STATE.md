---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Feature Expansion
status: verifying
stopped_at: Completed 20-08-PLAN.md
last_updated: "2026-04-13T14:05:56.147Z"
last_activity: 2026-04-13
progress:
  total_phases: 9
  completed_phases: 7
  total_plans: 62
  completed_plans: 55
  percent: 89
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-06)

**Core value:** Every user action must either succeed visibly or fail with a clear, actionable message -- no silent data loss, no undetected errors, no security gaps.
**Current focus:** Phase 20 — client-portal-sharing

## Current Position

Phase: 20 (client-portal-sharing) — EXECUTING
Plan: 10 of 10
Status: Phase complete — ready for verification
Last activity: 2026-04-13

## Accumulated Context

### Decisions

See PROJECT.md Key Decisions table for full history.

v2.0 roadmap decisions:

- Document Management placed first (Phase 13) as foundational — many later features attach files
- Notifications placed early (Phase 14) so later features can emit notifications
- Reporting placed late (Phase 19) to aggregate data from preceding feature areas
- Client Portal last (Phase 20) — requires content from documents, field photos, and reports
- [Phase 17]: Mirror cs_projects RLS expression on cs_project_tasks/cs_task_dependencies; duration_days as generated stored column; updateOwnedRow scoped by org_id (T-17-02)
- [Phase 17-calendar-scheduling]: updateOwnedRow falls back to id-only update when user_orgs lookup fails/empty — prevents silent 404 until a proper user_orgs migration lands
- [Phase 18]: 9 test stubs (exceeds 8 minimum) to cover validation edge cases for RFI and CO tools
- [Phase 18]: Input validation on generate_rfi (subject) and draft_change_order (description) for empty-string rejection
- [Phase 18]: Named MCP-only DTOs with MCP prefix to avoid collision with SupabaseService DTOs
- [Phase 18]: Human verified AI-03 (draft_change_order) end-to-end on web; all 4 AI requirements confirmed working
- [Phase 19]: Health score uses weighted composite: budget 40%, schedule 35%, issues 25%
- [Phase 19]: parseBudgetString strips non-numeric chars, returns 0 for unparseable (T-19-01)
- [Phase 19]: Pure aggregation functions: no side effects, no Supabase calls, accept raw data arrays
- [Phase 19]: Recharts Tooltip formatter uses any type for Recharts 3.x ValueType/NameType intersection compatibility
- [Phase 19-reporting-dashboards]: Immutable audit log: no UPDATE/DELETE RLS policies on cs_report_audit_log (T-19-06)
- [Phase 19-reporting-dashboards]: Budget text parsed via regex in SQL views since cs_projects stores budget as text
- [Phase 19]: Promise.allSettled with 10s per-section timeout for parallel section fetching (D-56)
- [Phase 19]: Query param sanitization strips non-alphanumeric chars to prevent injection (T-19-11)
- [Phase 19]: Reports link placed in FIELD nav group alongside Finance and Analytics per D-66
- [Phase 19]: Project report uses tabbed sections (Financial, Schedule, Safety, Team, Activity) per D-26f with Charts+Data/Charts Only toggle
- [Phase 19]: react-window v2 API uses rowComponent/rowCount/rowHeight (not FixedSizeList from v1)
- [Phase 19]: PDF generation fully client-side via jsPDF + html2canvas (no server round-trip) per D-60
- [Phase 19]: Text sanitization strips HTML tags + 2000 char limit for PDF XSS prevention (T-19-16)
- [Phase 19]: Service-role Supabase client for cron handler (bypasses RLS for system-level schedule processing)
- [Phase 19]: Three-tier role resolution (report -> project -> org) with manager fallback for unconfigured orgs (D-64g, D-119)
- [Phase 19]: Financial data masked to ranges on shared views, not redacted completely (D-64f, T-19-23)
- [Phase 19]: Export-specific rate limit (10 req/min) separate from general API rate limit (D-62b)
- [Phase 19]: Reports tab in field nav group; SupabaseService extended with public makeReportRequest; demo data embedded inline for offline-first
- [Phase 19]: UIGraphicsPDFRenderer for iOS PDF; Locale.current.region for paper size; ImageRenderer at 2x for chart embedding; AppIntents for Siri shortcuts
- [Phase 19]: FabricCanvasInner separated for clean dynamic import; comment HTML stripped + 2000 char limit; Fabric.js JSON validated for objects array + 500KB limit; version diff uses inverted-metric awareness for color coding
- [Phase 19-reporting-dashboards]: i18n uses next-intl getRequestConfig English-only; report themes via CSS custom properties on container; bulk ops limited to 50 items (T-19-34)
- [Phase 19-reporting-dashboards]: Health notifications only emit on color transitions, not score changes within same band (D-100)
- [Phase 19-reporting-dashboards]: Automation rules restricted to predefined action whitelist (T-19-37)
- [Phase 19-reporting-dashboards]: Embed route uses X-Frame-Options: ALLOWALL for iframe support (D-104)
- [Phase 19-reporting-dashboards]: Metrics endpoint bounded to 100 entries per endpoint in-memory (T-19-38)
- [Phase 19]: Feature tour uses localStorage; template JSON validated 50KB + CSS sanitized (T-19-40); CSV sanitizes formula injection (T-19-39)
- [Phase 19-reporting-dashboards]: SWR-compatible config object instead of SWR library dependency; feature flags default 100% rollout; SW scoped to /reports only
- [Phase 19]: Existing ShowReportIntent/PortfolioHealthIntent reused; AppShortcut phrases static (no String param interpolation); high contrast dual-detection via colorSchemeContrast + differentiateWithoutColor
- [Phase 19]: E2E test in web/e2e/ (matching playwright.config.ts); Resend class-based mock; webhook metadata-only per T-19-46
- [Phase 20-client-portal-sharing]: Design tokens as flat single-file export (web/src/lib/design-tokens.ts) as source of truth for portal and app styling
- [Phase 20-client-portal-sharing]: 56 test stubs across 8 files covering PORTAL-01 through PORTAL-04 plus CSS sanitization, image processing, rate limiting security
- [Phase 20]: Service-role client for public portal viewing bypasses RLS after token/slug validation
- [Phase 20]: INSERT-only RLS on cs_portal_audit_log for immutable audit trail (D-114)
- [Phase 20]: Soft-delete via is_deleted/is_revoked flags instead of hard delete (D-116)
- [Phase 20]: Portal API routes follow reports/share/route.ts pattern for auth, rate limiting, error handling
- [Phase 20]: CSS sanitizer uses 9 forbidden regex patterns + 30 allowed property whitelist (T-20-10)
- [Phase 20]: SVG validation rejects 5 attack vectors: script, event handlers, javascript:, external URLs, data: URIs (T-20-11)
- [Phase 20]: Portal SSR page uses service-role Supabase client for data access (same pattern as shared reports)
- [Phase 20]: Budget masking checks both section enabled AND show_exact_amounts flag (D-30, D-38)
- [Phase 20]: CSS custom properties applied via inline style on PortalShell wrapper div for branding
- [Phase 20]: PhotoTimeline integrates existing PhotoCard/PhotoLightbox/DateFilter from plan 20-04; sequential ZIP processing bounds memory (T-20-20)
- [Phase 20-client-portal-sharing]: PortalPhoto type in photoHelpers.ts with signedUrl, location, has_annotation; photos grouped by YYYY-MM-DD newest-first; JSZip for bulk ZIP; portal PDF client-side via jsPDF + html2canvas
- [Phase 20]: All portal management components use 'use client' with inline styles from design tokens; portal list API at /api/portal/list wraps existing portalQueries
- [Phase 20]: portalEmail uses .tsx extension for JSX email templates; contrast validator uses WCAG 2.1 sRGB gamma; email sends are non-blocking
- [Phase 20]: portalEmail uses .tsx extension for JSX email template support; Resend client lazily initialized; email sends non-blocking
- [Phase 20]: Portal DTOs use camelCase Swift properties with JSONEncoder snake_case conversion; createPortalLink two-step insert with server ID fetch; Color hex extension for branding serialization
- [Phase 20]: Portal DTOs use camelCase Swift properties with JSONEncoder snake_case conversion; createPortalLink sequential insert pattern; Color hex extension for branding serialization

### Pending Todos

None.

### Blockers/Concerns

- Plan 17-02 risk: user_orgs table existence unverified — updateOwnedRow silent-match-zero if table missing/mis-named

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260406-rcz | Fix all 8 partial requirements and 36 TS errors from v1.0 milestone audit | 2026-04-07 | 1fe77a6 | [260406-rcz-fix-all-8-partial-requirements-and-36-ts](./quick/260406-rcz-fix-all-8-partial-requirements-and-36-ts/) |

## Session Continuity

Last session: 2026-04-13T14:05:56.140Z
Stopped at: Completed 20-08-PLAN.md
Resume file: None
