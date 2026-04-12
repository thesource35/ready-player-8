---
phase: 19-reporting-dashboards
plan: 14
subsystem: api
tags: [notifications, automation-rules, embed, metrics, posthog, iframe, threshold-alerts]

# Dependency graph
requires:
  - phase: 19-04
    provides: Report API routes (project, rollup, health endpoints)
provides:
  - Notification emission for report events (health changes, deliveries, shared links, batch export)
  - Metric threshold alerts with per-project configurable thresholds
  - If-then automation rule engine with 5 built-in templates
  - Embeddable report iframe route with share token auth
  - Performance metrics endpoint (p50/p95/avg) per API section
  - PostHog integration helper and Vercel Analytics event constants
affects: [19-15, 19-16, 19-17, 19-18]

# Tech tracking
tech-stack:
  added: []
  patterns: [notification-emission-on-events, threshold-alert-checking, if-then-rule-engine, iframe-embed-with-token-auth, in-memory-timing-buffer]

key-files:
  created:
    - web/src/lib/reports/notifications-integration.ts
    - web/src/lib/reports/automation-rules.ts
    - web/src/app/api/reports/embed/route.ts
    - web/src/app/api/reports/metrics/route.ts
    - web/src/app/reports/components/NotificationPreferences.tsx
    - web/src/app/reports/components/AutomationRuleBuilder.tsx
    - web/src/app/reports/components/EmbedCodeGenerator.tsx
  modified: []

key-decisions:
  - "Health notifications only emit on color transitions (green/gold/red), not score changes within same color band (D-100)"
  - "Automation rules restricted to predefined action whitelist (T-19-37: no arbitrary code execution)"
  - "Embed route overrides X-Frame-Options with ALLOWALL and frame-ancestors * for iframe support (D-104)"
  - "Metrics endpoint bounded to 100 entries per endpoint in-memory (T-19-38: DoS prevention)"

patterns-established:
  - "Notification emission: check color transition -> build message -> insert into cs_notifications table"
  - "Rule evaluation: iterate active rules -> evaluate condition against metrics -> return triggered actions"
  - "Embed auth: validate share token -> check expiry -> increment view count -> serve HTML"

requirements-completed: [REPORT-01]

# Metrics
duration: 15min
completed: 2026-04-12
---

# Phase 19 Plan 14: Notifications, Automation, Embed & Metrics Summary

**Report notification integration with health change alerts, if-then automation rule engine with 5 templates, embeddable iframe route with share token auth, and p50/p95 performance metrics endpoint**

## Performance

- **Duration:** 15 min
- **Started:** 2026-04-12T09:08:31Z
- **Completed:** 2026-04-12T09:23:09Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Built notification integration that emits on health color transitions, delivery status, shared link access, and batch export events (D-100, D-50d)
- Built metric threshold alert system with configurable per-project thresholds and unexpected change detection (D-102)
- Built automation rule engine with 5 built-in templates, custom if-then rule builder, and predefined action whitelist (D-103, T-19-37)
- Built embed route serving iframe-friendly HTML with X-Frame-Options: ALLOWALL, share token validation, and expiry checking (D-104)
- Built performance metrics endpoint returning p50/p95/avg timing data with admin-only access and bounded in-memory buffer (D-62c, T-19-38)
- Built three UI components: NotificationPreferences (per-type/per-project toggles + digest mode), AutomationRuleBuilder (visual condition/action pickers), EmbedCodeGenerator (target/size selection + copy + preview)

## Task Commits

Each task was committed atomically:

1. **Task 1: Notification integration + automation rules** - `6c6df59` (feat)
2. **Task 2: Embed codes + metrics endpoint + analytics** - `1fe6774` (feat)

## Files Created/Modified
- `web/src/lib/reports/notifications-integration.ts` - Health change, delivery, shared link, batch export notification emitters + threshold checking + change detection
- `web/src/lib/reports/automation-rules.ts` - If-then rule engine with 5 built-in templates, evaluateRules function, predefined action types
- `web/src/app/reports/components/NotificationPreferences.tsx` - Per-type toggles, per-project granularity, daily digest mode
- `web/src/app/reports/components/AutomationRuleBuilder.tsx` - Visual condition picker (metric + operator + threshold) + action picker + template buttons
- `web/src/app/api/reports/embed/route.ts` - Iframe-embeddable report with share token auth, view count tracking, X-Frame-Options override
- `web/src/app/api/reports/metrics/route.ts` - p50/p95/avg response times, admin-only, bounded timing buffer, PostHog helper
- `web/src/app/reports/components/EmbedCodeGenerator.tsx` - Iframe code generator with target/size options, copy button, live preview

## Decisions Made
- Health notifications only emit on color transitions (green/gold/red), not score changes within same color band -- reduces notification noise while capturing meaningful state changes
- Automation rules restricted to predefined action whitelist (send_report, send_notification, pause_schedule, create_task) -- prevents arbitrary code execution per T-19-37
- Embed route uses ALLOWALL for X-Frame-Options and frame-ancestors * for CSP -- necessary for third-party embedding per D-104
- In-memory timing buffer bounded to 100 entries per endpoint -- prevents unbounded memory growth per T-19-38

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. PostHog integration is a stub that logs to console in development; production requires POSTHOG_API_KEY environment variable.

## Next Phase Readiness
- Notification integration ready for wiring to health score computation in report generation
- Automation rules ready for UI integration in report settings
- Embed route ready for external embedding
- Metrics endpoint ready for admin dashboard
- All components importable from reports/components/

## Self-Check: PASSED

- All 7 created files verified on disk
- Commit 6c6df59 verified in git log
- Commit 1fe6774 verified in git log

---
*Phase: 19-reporting-dashboards*
*Completed: 2026-04-12*
