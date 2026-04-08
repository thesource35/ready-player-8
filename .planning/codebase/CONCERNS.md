# Codebase Concerns

**Analysis Date:** 2026-04-04

## Tech Debt

**iOS/macOS App - Monolithic Files:**
- Issue: Several files exceed 100+ KB (RentalSearchView.swift 135KB, OperationsCommercial.swift 81KB, IntegrationHubView.swift 75KB, OperationsCore.swift 67KB). These massive files are difficult to navigate, test, and maintain.
- Files: `ready player 8/RentalSearchView.swift`, `ready player 8/OperationsCommercial.swift`, `ready player 8/IntegrationHubView.swift`, `ready player 8/OperationsCore.swift`
- Impact: Slow IDE performance, increased merge conflicts, reduced code clarity, difficult to extract reusable components.
- Fix approach: Break into smaller focused modules (e.g., RentalSearchView → RentalSearch + RentalFilter + RentalResults; OperationsCommercial → separate views for RFI, change orders, submittals).

**@State Arrays Reset on Launch:**
- Issue: Multiple views use `@State private var` with mutable arrays that are initialized empty on view creation. These arrays lose their data on each app relaunch because they're not persisted.
- Files: `ready player 8/ProjectsView.swift` (line 6), `ready player 8/MarketView.swift` (lines 7-8), `ready player 8/ContractsView.swift` (line 6), `ready player 8/AngelicAIView.swift` (line 34), `ready player 8/MoneyLensView.swift` (lines 13-14), `ready player 8/OpportunityFilterView.swift` (line 21), `ready player 8/PsychologyDecoderView.swift` (lines 21-22), `ready player 8/LeverageSystemView.swift` (lines 18-20)
- Impact: User data appears lost, poor user experience, must reload Supabase data every launch even if offline.
- Fix approach: Use `@AppStorage` with `AppStorageJSON` pattern (already demonstrated in codebase) for arrays that should persist locally. Only fetch from Supabase on demand.

**Silenced Errors with try?:**
- Issue: Excessive use of `try?` without fallback handling silently swallows encoding/decoding errors.
- Files: `ready player 8/AngelicAIView.swift`, `ready player 8/AppStorageJSON.swift`, `ready player 8/ConstructionOSNetwork.swift`, `ready player 8/LeverageSystemView.swift` (multiple JSONDecoder/JSONEncoder calls with try?)
- Impact: Data loss goes undetected, hard to debug persistence failures, users don't know why their data didn't save.
- Fix approach: Replace `try?` with `do-catch` blocks that log errors via `CrashReporter.shared.log()` or UIAlert. Ensure users see "Data save failed" messages.

**Catch Blocks with No Error Handling:**
- Issue: At least 39 catch blocks exist with minimal or empty error handling. Example: `catch { }` patterns ignore the error entirely.
- Files: `ready player 8/OperationsCommercial.swift`, `ready player 8/SecurityAccessView.swift`, `ready player 8/MCPServer.swift`, `ready player 8/AngelicAIView.swift`
- Impact: Silent failures, no logging, users unaware of system problems.
- Fix approach: All catch blocks must log to `CrashReporter.shared.log()` and display user-facing error alerts when operations fail.

**API Keys Stored Insecurely:**
- Issue: Anthropic API key and other secrets are stored in UserDefaults/AppStorage instead of Keychain.
- Files: `ready player 8/AngelicAIView.swift` (API key handling), `ready player 8/FinancialInfrastructure.swift` (Paddle, Coinbase keys)
- Impact: API keys exposed in app backup/iTuneset data, vulnerable to compromised devices.
- Fix approach: Use `KeychainHelper.save()` for all API keys (pattern already exists in codebase). Never store in UserDefaults.

**Unencrypted Credential Storage:**
- Issue: Supabase credentials (BaseURL, ApiKey) are stored in plain text in UserDefaults via Integration Hub.
- Files: `ready player 8/IntegrationHubView.swift`, `ready player 8/SupabaseService.swift` (retrieves from UserDefaults with keys `ConstructOS.Integrations.Backend.BaseURL`, `ConstructOS.Integrations.Backend.ApiKey`)
- Impact: Credentials exposed if device backup is compromised, no encryption layer.
- Fix approach: Store Supabase credentials in Keychain, not UserDefaults. Implement credential validation and rotation.

## Known Bugs

**ChatAPI Fallback is Hardcoded Mock Data:**
- Issue: `/web/src/app/api/chat/route.ts` returns hardcoded fallback responses instead of actual error messaging when Anthropic API key is missing or request fails.
- Files: `web/src/app/api/chat/route.ts` (lines 38-158, `getFallbackResponse()`)
- Trigger: ANTHROPIC_API_KEY env var not set, or Anthropic API returns 5xx error.
- Workaround: Users see generic "I'm Angelic" responses instead of understanding that live data fetch failed.
- Fix approach: Distinguish between "API unavailable" (return fallback) vs "temporary error" (retry or queue for later). Include explicit messaging to user.

**Rate Limiter is In-Memory Only:**
- Issue: `/web/src/app/api/chat/route.ts` uses a `Map<string, { count, resetAt }>` for rate limiting. This only works within a single function instance and resets when the instance recycles.
- Files: `web/src/app/api/chat/route.ts` (lines 9-29)
- Impact: Rate limit can be bypassed if requests hit different serverless instances. Not suitable for production multi-instance deployments.
- Fix approach: Replace with Vercel KV or Upstash Redis (comment in code already suggests this). Or implement per-IP header validation at the Edge level.

**ProjectsView and ContractsView Reset Supabase Data:**
- Issue: When filtering or searching, the live Supabase data in `@State` is not re-fetched if the view is recreated. Filters operate on stale data.
- Files: `ready player 8/ProjectsView.swift` (lines 6-30, displayProjects computed property doesn't validate Supabase sync), `ready player 8/ContractsView.swift`
- Impact: User sees filtered results from old data, confusion when filtering doesn't work.
- Fix approach: Refetch Supabase data when filter changes, or use Supabase-side filtering with REST queries.

**AngelicAI Session ID Never Persists Sessions:**
- Issue: `AngelicAIView.swift` uses `@AppStorage("ConstructOS.AngelicAI.SessionID")` to store a UUID, but messages are fetched from Supabase table `cs_ai_messages` with no strong session isolation or user authentication.
- Files: `ready player 8/AngelicAIView.swift` (line 32, sessionID logic)
- Impact: Messages may leak between users if deployed multi-user, or sessions can be accessed by anyone with the session ID.
- Fix approach: Implement server-side session validation, ensure Supabase RLS policies enforce per-user access.

## Security Considerations

**No User Authentication:**
- Risk: The iOS app has an `AuthGateView` (ContentView.swift) with auth fields, but no real server-side session validation. Users can skip to the app without credentials.
- Files: `ready player 8/ContentView.swift` (AuthGateView, lines ~1-100), `ready player 8/SupabaseService.swift` (no token validation)
- Current mitigation: Demo access allowed in DEBUG builds; no production auth flow implemented yet.
- Recommendations: Implement Supabase Auth with session tokens, enforce RLS policies on all tables, validate tokens on each request.

**Supabase Tables Have No RLS (Row-Level Security):**
- Risk: Any authenticated user can read/write all rows in `cs_projects`, `cs_contracts`, `cs_wealth_opportunities`, etc. if RLS is not enabled.
- Files: `ready player 8/SupabaseService.swift` (table comments reference schema but no RLS setup), web app calls `fetchTable()` in `web/src/lib/supabase/fetch.ts`
- Current mitigation: None documented.
- Recommendations: Enable RLS on all tables, implement user_id policy checks, test access controls before production.

**API Keys Hardcoded in Fallback Routes:**
- Risk: If Anthropic API key is missing from env, web chat falls back to mock data. No validation that API calls are actually being made.
- Files: `web/src/app/api/chat/route.ts` (line 168, no validation that apiKey is non-empty before proceeding to real API)
- Current mitigation: Fallback data prevents visible failure but masks the underlying issue.
- Recommendations: Explicitly check for required env vars at build time or startup. Log missing secrets to monitoring.

**Client-Side Supabase Keys Exposed:**
- Risk: Next.js app uses public Supabase keys in `web/src/lib/supabase/client.ts`. While Supabase is designed for this, all API calls are visible in the browser network tab.
- Files: `web/src/lib/supabase/client.ts` (lines 1-11)
- Current mitigation: RLS policies (if enabled) enforce authorization.
- Recommendations: Review all Supabase RLS policies, use Row-Level Security exclusively, never rely on client-side secret keys.

**Email Validation Missing:**
- Risk: `/web/src/app/api/leads/route.ts` accepts email without validation beyond `typeof body.email === "string"`.
- Files: `web/src/app/api/leads/route.ts` (line 14, email not validated with regex/format check)
- Impact: Invalid emails stored in database, undeliverable lead follow-ups.
- Recommendations: Add email format validation using regex or a library like `isEmail`.

**No CSRF Protection on Forms:**
- Risk: Form endpoints like `/api/leads` accept POST with no CSRF token or verification.
- Files: `web/src/app/api/leads/route.ts`
- Current mitigation: None documented.
- Recommendations: Add CSRF token validation or use Vercel middleware to enforce same-origin policy.

## Performance Bottlenecks

**Parallel Requests Not Batched:**
- Issue: Routes like `/web/src/app/api/chat/route.ts` use `Promise.all([fetchTable(...), fetchTable(...)])` but don't paginate. Fetching 10 projects + 10 contracts on every chat request is wasteful.
- Files: `web/src/app/api/chat/route.ts` (lines 175-181)
- Cause: System prompt is rebuilt on every chat message with fresh data, causing N+1 queries.
- Improvement path: Cache project/contract list for 5 minutes, fetch only on explicit "refresh" action or use `use cache` directive (Next.js 15+).

**Supabase Queries Have No Pagination:**
- Issue: `fetchTable()` calls don't implement cursor-based pagination or limit results properly.
- Files: `web/src/lib/supabase/fetch.ts` (if it exists), referenced by routes
- Impact: Large tables (1000+ rows) load entire dataset into memory.
- Improvement path: Implement pagination with limit/offset, implement cursor-based pagination for large result sets.

**Large JSON Serialization in Chat:**
- Issue: System prompt in chat route includes full project/contract data serialized as strings (lines 183-189 of route.ts). With 50+ fields per record, this becomes 50+ KB per request.
- Files: `web/src/app/api/chat/route.ts` (lines 183-189)
- Impact: Larger request payloads, slower API calls to Anthropic.
- Improvement path: Send only summary data (name, status, score) to Anthropic, not full record details.

**ViewBuilder Recomputation in Large Lists:**
- Issue: SwiftUI views like `ProjectsView` and `RentalSearchView` compute `displayProjects` and filter arrays on every render pass. With 1000+ items, this causes lag.
- Files: `ready player 8/ProjectsView.swift` (lines 17-30, computed property filters on every body read), `ready player 8/RentalSearchView.swift`
- Impact: UI stutters when scrolling or typing in search.
- Improvement path: Use `@Query` or lazy filtering, memoize computed properties with `@State`, consider moving to SwiftData or Core Data for indexing.

## Fragile Areas

**IntegrationHub - Credential Configuration:**
- Files: `ready player 8/IntegrationHubView.swift` (1647 lines, all credential/backend config logic)
- Why fragile: Single file handles all integration setup (Supabase, Firebase, Outlook, QuickBooks, Microsoft365). Any change to credential storage affects all integrations.
- Safe modification: Extract credential saving logic into a `CredentialStore` protocol with Keychain implementation. Test credential round-trip before using.
- Test coverage: No unit tests for credential save/load; manual testing only.

**SupabaseService - Shared Instance Without Thread Safety:**
- Files: `ready player 8/SupabaseService.swift` (837 lines)
- Why fragile: `SupabaseService.shared` is a global singleton. Multiple views may call `fetchTable()` simultaneously without coordination. No mutex/lock for shared state.
- Safe modification: All Supabase calls must be wrapped in `@MainActor` or use `DispatchQueue.main.async`. Document that all network calls are main-thread only.
- Test coverage: No concurrency tests.

**ProjectsView CRUD Operations:**
- Files: `ready player 8/ProjectsView.swift` (657 lines, CRUD logic in view)
- Why fragile: Add/edit/delete operations are embedded in the view. Changing field names or types requires changes in multiple places (model, view, Supabase table schema).
- Safe modification: Extract CRUD to a `ProjectsViewModel` or `ProjectsRepository`. Update model first, then propagate changes.
- Test coverage: No unit tests for CRUD; no validation tests for required fields.

**ContentView.swift - Auth Gate:**
- Files: `ready player 8/ContentView.swift` (line ~1-100, AuthGateView)
- Why fragile: Authentication logic is embedded in a view. Signup, login, 2FA, company select, forgot password are all in one struct. Changing flow requires careful refactoring.
- Safe modification: Extract to `AuthViewModel` with clear state machine (login → 2FA → companySelect). Test state transitions independently.
- Test coverage: No unit tests for auth flows.

**AngelicAI Message Streaming:**
- Files: `ready player 8/AngelicAIView.swift` (640 lines, chat logic in view)
- Why fragile: Message parsing and streaming is done in the view's async functions. If API response format changes, entire view breaks.
- Safe modification: Extract message parsing to a `ChatParser` or `ChatService`. Mock responses in tests before changing.
- Test coverage: No unit tests for message parsing or streaming error handling.

**RentalSearchView - 2496 Lines:**
- Files: `ready player 8/RentalSearchView.swift` (2496 lines, monolithic)
- Why fragile: Extreme size makes it difficult to change without breaking multiple features. Search, filter, sorting, booking, quoting all interdependent.
- Safe modification: Break into components: RentalSearchHeader, RentalCatalog, RentalFilter, RentalCart, RentalCheckout. Use a coordinator/router.
- Test coverage: No unit tests; manual testing only.

## Scaling Limits

**In-Memory Rate Limiter:**
- Current capacity: ~10,000 unique IPs tracked before cleanup triggers.
- Limit: Drops oldest entries when map size > 10,000; resets after WINDOW_MS (60s). With high concurrency (1000 requests/min), entries may collide or reset prematurely.
- Scaling path: Switch to Vercel KV or Redis for distributed rate limiting that works across function instances.

**Supabase Queries Without Caching:**
- Current capacity: Supabase free tier allows ~100 concurrent connections.
- Limit: If 50+ users hit ProjectsView simultaneously, each fetching project list, connection pool exhausts.
- Scaling path: Implement HTTP caching (ETag, max-age) for project/contract lists; use Vercel Edge Config for cached data.

**CoreData Not Used for Local Sync:**
- Current capacity: All data stored in UserDefaults (limited to ~5MB per app).
- Limit: With wealth data, psychology sessions, leverage snapshots all serialized as JSON, AppStorage may exceed limits.
- Scaling path: Migrate to SwiftData or CoreData, implement sync queue to reconcile local + Supabase changes.

**No Offline Support:**
- Current capacity: Zero offline data; all views depend on network.
- Limit: Any network hiccup shows errors; no queued operations.
- Scaling path: Implement local-first architecture with sync queue; queue operations when offline, sync when online.

## Dependencies at Risk

**Anthropic API Dependency in Chat:**
- Risk: Chat route falls back to hardcoded mocks if API key missing or request fails. This masks production issues.
- Impact: Users think chat is "working" but seeing mock data instead of live analysis.
- Migration plan: Implement explicit "Data source" indicator in UI. Show "Using mock data" or "Live data from your projects" clearly. Set up monitoring alerts for API failures.

**Supabase as Single Source of Truth:**
- Risk: If Supabase is down, entire app is read-only. No offline queue or conflict resolution.
- Impact: Users can't create projects, contracts, or wealth records during outage.
- Migration plan: Implement local-first with sync queue. Test offline scenarios before production.

**MapBox Integration:**
- Risk: Maps page (`/web/src/app/maps/page.tsx`) likely depends on MapBox API. No error handling shown.
- Impact: If MapBox token is invalid or quota exceeded, maps page breaks silently.
- Migration plan: Add error boundary, display "Maps unavailable" message, provide fallback (list view).

**Next.js 16.2.2 Rapid Release Cycle:**
- Risk: Version 16.2.2 is cutting-edge; documentation may lag, breaking changes in 16.3+ could require fast refactoring.
- Impact: Dependency updates may break builds unexpectedly.
- Migration plan: Pin to stable release, test beta versions in CI before upgrading, maintain changelog of version-specific patterns.

**React 19.2.4 (Bleeding Edge):**
- Risk: React 19.x is very new; third-party libraries may not support it yet. TypeScript definitions may be incomplete.
- Impact: Type errors, compatibility issues with UI libraries.
- Migration plan: Verify all dependencies support React 19.x before upgrading production.

## Missing Critical Features

**Persistence for Local State:**
- Problem: UI state (selected items, filters, drafts) is lost on app relaunch because it's `@State` with no save.
- Blocks: Users can't resume work, must re-filter/re-select every session.
- Priority: High — affects core workflows.

**Error Recovery and Retry Logic:**
- Problem: Network errors are caught but not retried. Transient failures (timeout, 429) cause permanent loss of user action.
- Blocks: Unreliable data submission, users unaware if their action saved.
- Priority: High.

**Server-Side User Authentication:**
- Problem: iOS app has auth UI but no real auth backend. Web and iOS don't share session.
- Blocks: Multi-user deployments unsafe, data leakage risk.
- Priority: Critical — required for production.

**Offline Queue for Operations:**
- Problem: All operations require live network. Offline users see errors immediately.
- Blocks: Field teams can't work offline (no projects visible, can't log time).
- Priority: High — construction field teams often offline.

**Real-Time Collaboration:**
- Problem: No live sync if two users edit same project. Last write wins; changes overwrite without warning.
- Blocks: Team coordination breaks if multiple people work same record.
- Priority: Medium — depends on user scale.

**Webhook Integrations from Supabase:**
- Problem: No way to notify external systems (Slack, Outlook, QuickBooks) of changes in ConstructionOS.
- Blocks: Integrations feel one-way; can't push data to partners.
- Priority: Medium — integration roadmap item.

## Test Coverage Gaps

**No Unit Tests for Core Services:**
- What's not tested: SupabaseService.swift, ProjectsViewModel (if it existed), AuthGateView, ChatService (web).
- Files: `ready player 8/SupabaseService.swift`, `web/src/app/api/chat/route.ts`, `ready player 8/AngelicAIView.swift`
- Risk: Refactoring breaks services without detection, regressions ship to production.
- Priority: Critical — these are foundation code.

**No Integration Tests for Supabase Sync:**
- What's not tested: Can projects be created, read, updated, deleted via Supabase? Do changes appear in UI?
- Files: Any view that uses `supabase.insert()`, `supabase.update()`, `supabase.delete()`
- Risk: CRUD operations fail silently, users think data was saved when it wasn't.
- Priority: High — CRUD is core feature.

**No E2E Tests for Chat Flow:**
- What's not tested: User sends message → API fetches projects → Anthropic responds → message appears in UI.
- Files: `web/src/app/ai/page.tsx`, `web/src/app/api/chat/route.ts`
- Risk: Chat feature breaks due to API changes or parse errors.
- Priority: High — heavily used feature.

**No Offline/Network Error Tests:**
- What's not tested: App behavior when Supabase is down, network timeout, 5xx responses.
- Files: All views that fetch data
- Risk: Crashes or silent failures during network issues.
- Priority: High — reliability blocker.

**No Security Tests:**
- What's not tested: Can unauthenticated users access Supabase tables? Can users see other users' data?
- Files: `ready player 8/SupabaseService.swift`, Supabase RLS policies
- Risk: Data leakage, unauthorized access.
- Priority: Critical — security vulnerability.

**No Load Tests:**
- What's not tested: How fast does chat route respond with 100+ concurrent users? Does rate limiter hold?
- Files: `web/src/app/api/chat/route.ts`
- Risk: Production outage under load.
- Priority: Medium — depends on scale.

**No UI Tests for Complex Views:**
- What's not tested: RentalSearchView filtering, ProjectsView sorting, OperationsCommercial workflows.
- Files: `ready player 8/RentalSearchView.swift`, `ready player 8/ProjectsView.swift`, `ready player 8/OperationsCommercial.swift`
- Risk: UI regressions go undetected.
- Priority: Medium.

---

*Concerns audit: 2026-04-04*
