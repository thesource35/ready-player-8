# Roadmap: ConstructionOS Production Hardening

## Overview

This roadmap transforms ConstructionOS from feature-complete-but-fragile to production-ready across both iOS and web platforms. The critical path is the security chain (Secrets -> Auth -> RLS), which must execute sequentially. Once secrets are locked down, crash safety, error handling, state persistence, web hardening, and polish workstreams can execute in parallel. Tests come last, after all the code they cover is stabilized. 126 requirements across 12 phases.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Secrets & Infrastructure Cleanup** - Rotate exposed keys, fix gitignore, remove repo debris, fix deployment target
- [ ] **Phase 2: Authentication** - Real auth flows on both platforms (replace fake SSO, fake 2FA, fake forgot-password)
- [ ] **Phase 3: Row-Level Security** - Per-user data isolation on all Supabase tables with ownership checks and migration files
- [ ] **Phase 4: iOS Crash Safety** - Eliminate every force unwrap and fatalError that can crash the app
- [ ] **Phase 5: iOS Error Handling & State Persistence** - Replace silent failures with visible errors, persist all volatile @State arrays
- [ ] **Phase 6: Web Security & Validation** - Webhook verification, CSRF, form validation, and data persistence fixes
- [ ] **Phase 7: Web Error Handling & Consistency** - Structured error JSON, standardize auth/rate-limit/SDK patterns across routes
- [ ] **Phase 8: Web UX & Loading States** - Error boundaries, loading indicators, SSR safety, feature gating
- [ ] **Phase 9: Web Performance & Dynamic Content** - Rate limiting, pagination, payment fixes, dynamic content, image config
- [ ] **Phase 10: Accessibility & SEO** - Screen reader labels, metadata, robots/sitemap, PWA icon
- [ ] **Phase 11: iOS Tests** - Unit tests for Keychain, auth, persistence, and Supabase service plus CI test execution
- [ ] **Phase 12: Web Tests** - Unit tests for API routes, E2E tests for critical user flows

## Phase Details

### Phase 1: Secrets & Infrastructure Cleanup
**Goal**: No secret is exposed in git history or stored insecurely, repo hygiene issues are resolved, and iOS builds target a real OS version
**Depends on**: Nothing (first phase)
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06, SEC-07, SEC-08, SEC-09, SEC-10, SEC-11, SEC-12, INFRA-01
**Success Criteria** (what must be TRUE):
  1. User can configure Supabase/Anthropic/Paddle/Coinbase credentials and they persist in iOS Keychain, not UserDefaults
  2. Existing users who had credentials in UserDefaults have them silently migrated to Keychain on first launch (old entries deleted)
  3. Web app logs clear error at startup if required env vars are missing (does not silently run without them)
  4. CSP headers remove unsafe-eval and tighten wildcard domains; Mapbox popup HTML is escaped; Square webhook rejects unsigned requests
  5. Supabase secret key is rotated, .gitignore covers .env*/DS_Store/xcuserdata/DerivedData, orphaned folders removed, @next/swc-darwin-arm64 removed, iOS deployment target is valid
**Plans:** 3 plans
Plans:
- [x] 01-01-PLAN.md — iOS Keychain credential migration (Anthropic, Supabase, UserDefaults migration)
- [x] 01-02-PLAN.md — Web security hardening (env validation, Square webhook, CSP, Mapbox XSS)
- [x] 01-03-PLAN.md — Repo hygiene and infrastructure (key rotation, gitignore, deps cleanup, deployment target)

### Phase 2: Authentication
**Goal**: Users must sign in to access their data on both iOS and web, with real auth flows replacing all fake/stub implementations
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07, AUTH-08, AUTH-09, AUTH-10, AUTH-11
**Success Criteria** (what must be TRUE):
  1. User can create an account and log in with email/password on both iOS and web
  2. iOS user stays logged in across app restarts (auth token in Keychain, auto-refreshed before expiry)
  3. Web user stays logged in across browser sessions (cookie-based via @supabase/ssr, middleware-validated)
  4. Developer can bypass auth in DEBUG builds using existing demo mode
  5. 2FA TOTP validates against server (not just regex); backup code flow works; SSO buttons hidden (deferred to v2); forgot-password makes real API call
  6. Leads endpoint is rate-limited or CAPTCHA-protected (no longer open to spam)
**Plans:** 3 plans
Plans:
- [ ] 02-01-PLAN.md — iOS auth hardening (real forgot-password, hide SSO, session auto-refresh, token validation)
- [ ] 02-02-PLAN.md — Web auth middleware and leads rate limiting (middleware.ts, session validation, rate limit)
- [ ] 02-03-PLAN.md — 2FA server verification on both platforms (Supabase MFA, backup codes, real TOTP)

### Phase 3: Row-Level Security
**Goal**: Every Supabase table enforces per-user data isolation -- users can only read/write their own rows, with versioned migration files
**Depends on**: Phase 2
**Requirements**: RLS-01, RLS-02, RLS-03, RLS-04, RLS-05, RLS-06, RLS-07, INFRA-06
**Success Criteria** (what must be TRUE):
  1. All Supabase tables have a user_id column and RLS policies that restrict access to the authenticated user
  2. Existing data is preserved (backfilled with admin user_id before RLS is enabled)
  3. iOS app sends auth token with every Supabase request and receives only that user's data
  4. Web app sends auth token with every Supabase request; PATCH/DELETE routes verify ownership before modifying rows
  5. Jobs API uses anon key for public GET (not service role key that bypasses RLS)
  6. Supabase migration files exist with version history (not just a single schema.sql)
**Plans:** 2 plans
Plans:
- [ ] 03-01-PLAN.md — Supabase migration files (user_id columns, backfill, RLS policies)
- [ ] 03-02-PLAN.md — Web API ownership checks and Jobs API fix

### Phase 4: iOS Crash Safety
**Goal**: No force unwrap or fatalError can crash the app at runtime -- all replaced with safe unwrapping and graceful fallbacks
**Depends on**: Phase 1
**Requirements**: CRASH-01, CRASH-02, CRASH-03, CRASH-04, CRASH-05
**Success Criteria** (what must be TRUE):
  1. SupabaseService force unwraps (lines 199, 221, 464, 702) replaced with guard-let that returns a descriptive error
  2. ContentView footer URL force unwraps replaced with guard-let (graceful no-op if URL invalid)
  3. PersistenceController fatalError replaced with fallback that logs error and continues with in-memory store
  4. OperationsField/OperationsCore and SecurityAccessView force unwraps guarded safely
**Plans**: TBD

### Phase 5: iOS Error Handling & State Persistence
**Goal**: Every iOS operation that can fail either recovers gracefully or shows a clear error message, and all user-created data survives app restarts
**Depends on**: Phase 1
**Requirements**: ERR-01, ERR-02, ERR-03, ERR-04, ERR-05, ERR-06, STATE-01, STATE-02, STATE-03, STATE-04, STATE-05, STATE-06, STATE-07, STATE-08, STATE-09, STATE-10, STATE-11, DATA-01, DATA-02, DATA-03, DATA-04
**Success Criteria** (what must be TRUE):
  1. No empty catch blocks remain -- all failures logged via CrashReporter.shared with appropriate user alert
  2. All silent try? calls replaced with do-catch; error categorization (expected/recoverable vs unexpected vs non-critical) applied
  3. Chat interface clearly indicates live vs mock/fallback data; print() leaks removed; deprecated autocapitalization API replaced
  4. User creates a project, force-quits the app, relaunches, and sees the project still there (all 11 view-level @State arrays persist including SocialNetwork and ScheduleTools)
  5. App warns or truncates gracefully if any AppStorage JSON key approaches 1MB
  6. Filtering projects/contracts triggers fresh Supabase fetch; AI messages are session-isolated per user
  7. SupabaseService validates tokens actually arrived on signUp/signIn and falls back gracefully when no credentials exist
**Plans**: TBD

### Phase 6: Web Security & Validation
**Goal**: Web endpoints reject malformed input, verify webhook signatures, protect against CSRF, and persist data correctly
**Depends on**: Nothing (independent)
**Requirements**: WEB-01, WEB-02, WEB-03, WEB-04, WEB-05, VAL-01, VAL-02, VAL-03, VAL-04, VAL-05, VAL-06, VAL-07, VAL-08
**Success Criteria** (what must be TRUE):
  1. Submitting an invalid email to /api/leads returns a validation error (not a silent accept)
  2. POST requests from a different origin are rejected (CSRF protection active)
  3. Paddle webhook requests with invalid signatures are rejected; valid ones update subscription status in Supabase
  4. Login, profile, jobs, and rental forms validate email/phone format with proper regex before submission
  5. Text inputs enforce maxLength limits; rental form does not show success when API fails; addProject persists to database; add form shows validation feedback
**Plans**: TBD
**UI hint**: yes

### Phase 7: Web Error Handling & Consistency
**Goal**: All API routes return structured error JSON with correct status codes, and web codebase uses consistent patterns for auth, rate limiting, and SDK usage
**Depends on**: Nothing (independent)
**Requirements**: WERR-01, WERR-02, WERR-03, WERR-04, WERR-05, WERR-06, WERR-07, WERR-08, WERR-09, CONSIST-01, CONSIST-02, CONSIST-04
**Success Criteria** (what must be TRUE):
  1. All API routes return structured JSON errors (never raw exception text); chat route distinguishes "API unavailable" vs "temporary error"
  2. Missing env vars detected and logged at startup (WERR-03)
  3. All 8 API routes missing try/catch around req.json() are wrapped; Jobs API validates response body shape
  4. Export API returns 503 when Supabase not configured (not fake data with 200); POST routes return 201; DELETE routes return proper error status on failure
  5. Single rate limiting implementation across all routes; all protected routes use same getAuthenticatedClient() pattern; chat route uses AI SDK instead of raw fetch
**Plans**: TBD

### Phase 8: Web UX & Loading States
**Goal**: Every web page handles errors visibly with error boundaries, shows loading/empty states, and gates premium features consistently
**Depends on**: Nothing (independent)
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05, INFRA-07, CONSIST-03
**Success Criteria** (what must be TRUE):
  1. All 22 unprotected pages have error.tsx boundaries that show a user-friendly error message
  2. Maps page shows "Maps unavailable" when Mapbox token missing; Jobs page shows "No results" empty state
  3. AI page shows loading indicator during initial load; punch/ops/tasks pages show loading indicators during fetch
  4. AngelicPromptToggle checks typeof window before localStorage access (no SSR crash)
  5. Punch and trust pages are wrapped with PremiumFeatureGate
**Plans**: TBD
**UI hint**: yes

### Phase 9: Web Performance & Dynamic Content
**Goal**: Web app handles load with distributed rate limiting and pagination, dynamic content reflects real data, and payment flows work correctly
**Depends on**: Nothing (independent)
**Requirements**: PERF-01, PERF-02, PERF-03, PERF-04, PERF-05, PERF-06, PERF-07, DYN-01, DYN-02, DYN-03, DYN-04, DYN-05, DYN-06, DYN-07, PAY-01, PAY-02, DATA-05, INFRA-05
**Success Criteria** (what must be TRUE):
  1. Rate limiting works across serverless instances (Upstash Redis); rate limit headers applied to responses; middleware uses session token claims instead of querying Supabase
  2. Supabase queries paginated with "load more" control; export API streams or caps at safe size; chat system prompt sends summary only
  3. Maps page creates popups lazily on marker click; Next.js image remotePatterns configured for Supabase/Mapbox
  4. Settings page shows actual user; checkout shows trial info; prices consistent; footer year dynamic; marketing numbers real or removed; app version reads from Bundle
  5. Square checkout passes selected payment method and billing interval correctly
  6. Supabase tables have updated_at triggers
**Plans**: TBD
**UI hint**: yes

### Phase 10: Accessibility & SEO
**Goal**: Web app is navigable by screen readers and discoverable by search engines; iOS buttons have accessibility labels; PWA is installable
**Depends on**: Nothing (independent)
**Requirements**: A11Y-01, A11Y-02, A11Y-03, A11Y-04, SEO-01, SEO-02, SEO-03, SEO-04, SEO-05, INFRA-04
**Success Criteria** (what must be TRUE):
  1. Screen reader can identify every icon-only button by its aria-label (web) and every action button by its accessibilityLabel (iOS, 182+ buttons across 37 files)
  2. All form inputs have associated label elements; status indicators convey meaning via text, not color alone
  3. All 16 pages missing metadata exports now have them; key pages have OpenGraph tags with OG image for social sharing
  4. robots.txt and sitemap.xml are generated and accessible; PWA manifest has 192x192 icon for "Add to Home Screen"
**Plans**: TBD
**UI hint**: yes

### Phase 11: iOS Tests
**Goal**: Critical iOS code paths have automated tests that catch regressions, and CI actually runs them
**Depends on**: Phase 1, Phase 4, Phase 5
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. SupabaseService CRUD operations have unit tests covering success and error cases
  2. Keychain storage has unit tests for save, read, delete, and UserDefaults migration
  3. Auth flow state transitions (login, logout, token refresh) have unit tests
  4. AppStorageJSON persistence has unit tests covering encode, decode, and size limit behavior
  5. CI pipeline runs `npm run test` (vitest) and `npm audit` in addition to lint/typecheck/build
**Plans**: TBD

### Phase 12: Web Tests
**Goal**: Critical web code paths have automated tests that catch regressions in API routes, auth middleware, and end-to-end flows
**Depends on**: Phase 6, Phase 7, Phase 8, Phase 9
**Requirements**: WTEST-01, WTEST-02, WTEST-03, WTEST-04, WTEST-05, WTEST-06, WTEST-07
**Success Criteria** (what must be TRUE):
  1. Chat API route has unit tests for valid request, missing API key, and rate limiting scenarios
  2. Leads API route has unit tests for valid email, invalid email, and missing fields
  3. Auth middleware has unit tests for valid session, expired session, and no session
  4. E2E test confirms a user can sign up, log in, create a project, and see it listed
  5. E2E test confirms a user can send a chat message and receive an AI response
  6. Paddle webhook and checkout flow have unit tests for signature verification and payment method passthrough
**Plans**: TBD

## Progress

**Execution Order:**
Phases 1 -> 2 -> 3 are sequential (critical security chain).
Phases 4, 5, 6, 7, 8, 9, 10 can execute in parallel after Phase 1.
Phases 11, 12 execute last (after the code they test is stable).

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Secrets & Infrastructure Cleanup | 3/3 | Complete | 2026-04-05 |
| 2. Authentication | 0/3 | Planned | - |
| 3. Row-Level Security | 0/2 | Planned | - |
| 4. iOS Crash Safety | 0/TBD | Not started | - |
| 5. iOS Error Handling & State Persistence | 0/TBD | Not started | - |
| 6. Web Security & Validation | 0/TBD | Not started | - |
| 7. Web Error Handling & Consistency | 0/TBD | Not started | - |
| 8. Web UX & Loading States | 0/TBD | Not started | - |
| 9. Web Performance & Dynamic Content | 0/TBD | Not started | - |
| 10. Accessibility & SEO | 0/TBD | Not started | - |
| 11. iOS Tests | 0/TBD | Not started | - |
| 12. Web Tests | 0/TBD | Not started | - |
