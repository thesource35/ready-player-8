---
phase: 01-secrets-infrastructure-cleanup
plan: 02
subsystem: web-security
tags: [csp, env-validation, webhook-auth, xss-prevention]
dependency_graph:
  requires: []
  provides: [env-validation, webhook-signature-guard, csp-headers, xss-safe-popups]
  affects: [web/next.config.ts, web/src/lib/supabase/env.ts, web/src/app/api/billing/webhook/route.ts, web/src/app/maps/page.tsx]
tech_stack:
  added: []
  patterns: [env-var-validation-at-startup, csp-security-headers, html-escape-defense-in-depth]
key_files:
  created:
    - web/src/lib/supabase/env.ts
  modified:
    - web/src/app/api/billing/webhook/route.ts
    - web/next.config.ts
    - web/src/app/maps/page.tsx
decisions:
  - "CSP headers added fresh to next.config.ts (they did not previously exist)"
  - "unsafe-eval excluded from CSP script-src from the start"
  - "Mapbox CSP uses three specific subdomains: api, events, tiles"
  - "validateRequiredEnvVars() runs at module scope on first import of env.ts"
metrics:
  duration: 7m
  completed: 2026-04-05T04:12:56Z
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 3
requirements:
  - SEC-04
  - SEC-05
  - SEC-06
  - SEC-07
  - SEC-12
---

# Phase 01 Plan 02: Web Security Hardening Summary

Env var validation with error-level logging at startup, webhook signature enforcement with no bypass, CSP headers without unsafe-eval using specific Mapbox subdomains, and XSS-safe Mapbox popup escaping.

## What Was Done

### Task 1: Env Var Validation and Webhook Signature Guard (d5d56fe)

**web/src/lib/supabase/env.ts (created):**
- Created env.ts module with `getSupabaseUrl()`, `getSupabasePublishableKey()`, `getSupabaseServerKey()`, `isSupabaseConfigured()` accessor functions
- `warnOnce()` uses `console.error` in ALL environments (not development-only)
- `validateRequiredEnvVars()` checks required vars (SUPABASE_URL, ANON_KEY) and optional vars (ANTHROPIC_API_KEY, SERVICE_ROLE_KEY, SQUARE_WEBHOOK_SIGNATURE_KEY) at module load time
- Logs clear summary: "MISSING REQUIRED env vars: X, Y -- app will run in demo mode"

**web/src/app/api/billing/webhook/route.ts:**
- Removed `|| ""` empty-string defaults from `SQUARE_WEBHOOK_SIGNATURE_KEY` and `SQUARE_WEBHOOK_URL`
- Added early guard at top of POST handler: returns 503 when signature key not configured
- Removed conditional `if (SQUARE_WEBHOOK_SIGNATURE_KEY)` wrapper -- signature verification now runs unconditionally
- No path exists to accept unsigned requests

### Task 2: CSP Headers and Mapbox Popup Escaping (e390e86)

**web/next.config.ts:**
- Added `async headers()` config with Content-Security-Policy, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy
- CSP script-src: `'self' 'unsafe-inline'` (no unsafe-eval) + mapbox + vercel-scripts
- CSP connect-src: specific Mapbox subdomains (api, events, tiles) instead of wildcard
- CSP img-src: specific Mapbox subdomains (api, tiles) instead of wildcard

**web/src/app/maps/page.tsx:**
- Added `escapeHtml()` utility function (replaces &, <, >, ", ')
- All 7 interpolated values in Mapbox popup `setHTML()` wrapped with `escapeHtml()`
- Defense-in-depth: data is currently hardcoded but escaping protects against future data source changes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] env.ts did not exist**
- **Found during:** Task 1
- **Issue:** Plan referenced existing env.ts with `warnOnce` function, but the file did not exist on disk. The webhook route.ts already had an import from `@/lib/supabase/env`.
- **Fix:** Created env.ts from scratch with all specified functions plus the existing import contract (getSupabaseUrl, getSupabaseServerKey).
- **Files created:** web/src/lib/supabase/env.ts

**2. [Rule 3 - Blocking] CSP headers did not exist in next.config.ts**
- **Found during:** Task 2
- **Issue:** Plan described removing unsafe-eval from existing CSP, but next.config.ts had no headers() config at all.
- **Fix:** Added complete headers() config with CSP (without unsafe-eval from the start) plus other security headers.
- **Files modified:** web/next.config.ts

## Threat Mitigations Applied

| Threat ID | Status | Implementation |
|-----------|--------|----------------|
| T-01-04 | Mitigated | Webhook returns 503 when SQUARE_WEBHOOK_SIGNATURE_KEY missing; HMAC always verified |
| T-01-05 | Mitigated | CSP script-src has no unsafe-eval; only self + unsafe-inline + specific origins |
| T-01-06 | Mitigated | All 7 popup interpolations wrapped with escapeHtml() |
| T-01-07 | Mitigated | console.error in all environments; validateRequiredEnvVars() at module load |

## Known Stubs

None -- all implementations are fully functional.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | d5d56fe | feat(01-02): validate env vars at startup and reject unsigned webhooks |
| 2 | e390e86 | feat(01-02): harden CSP headers and escape Mapbox popup HTML |

## Self-Check: PASSED

- All 4 files exist on disk
- Both commit hashes (d5d56fe, e390e86) found in git log
