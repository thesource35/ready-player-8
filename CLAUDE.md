<!-- GSD:project-start source:PROJECT.md -->
## Project

**ConstructionOS — Production Hardening**

A comprehensive fix-up of the existing ConstructionOS multi-platform app (iOS/macOS/visionOS SwiftUI + Next.js web). The app is feature-complete but has accumulated technical debt: silent error handling, insecure credential storage, volatile state that resets on launch, no authentication, and zero test coverage. This project makes the codebase production-ready.

**Core Value:** Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

### Constraints

- **File structure**: Don't break apart monolithic files — fix bugs in place
- **Both platforms**: Fixes must cover both iOS Swift app and Next.js web app
- **Backward compatible**: Don't break existing features while fixing issues
- **Tests required**: Add tests for critical paths as we fix them
- **Supabase**: Use existing Supabase backend — don't migrate to different database
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Swift - iOS 18.2+, macOS 15.6+, visionOS support (SwiftUI framework)
- TypeScript - 5.x - Web app and API routes (Next.js)
- JavaScript - Node.js runtime for build and scripts
- SQL - Supabase database queries and schema
- YAML - CI/CD workflows and configuration
## Runtime
- **iOS/macOS/visionOS:** Native Swift runtime (XCode 16.2)
- **Web:** Node.js 20 (specified in GitHub Actions)
- **API:** Node.js runtime (Vercel Functions on Vercel platform)
- **iOS:** None (native framework dependencies via SPM, no CocoaPods)
- **Web:** npm - Lockfile: `web/package-lock.json` present
## Frameworks
- Next.js 16.2.2 - Full-stack React framework with App Router
- React 19.2.4 - UI library
- React DOM 19.2.4 - DOM renderer
- SwiftUI - Native declarative UI framework
- Combine - Reactive programming framework
- CoreData - Local persistence (template-only, unused by app data)
- vitest 3.2.4 - Web unit testing (Node environment)
- XCTest - iOS unit tests (via GitHub Actions)
- TypeScript 5.x - Type checking
- Tailwind CSS 4 - Web utility-first CSS (via @tailwindcss/postcss)
- ESLint 9 - Web linting (with Next.js config)
- @next/swc-darwin-arm64 16.2.2 - Next.js compiler (ARM macOS)
## Key Dependencies
- @supabase/ssr 0.10.0 - Server-side Supabase auth/session management (web)
- @supabase/supabase-js 2.101.1 - Supabase JavaScript client
- @ai-sdk/anthropic 3.0.64 - Anthropic SDK (Claude API client)
- ai 6.0.142 - Vercel AI SDK for LLM streaming and chat
- mapbox-gl 3.20.0 - Interactive maps library (web maps page)
- @vercel/analytics 2.0.1 - Analytics tracking for Vercel deployments
- next - Next.js framework with built-in image/font optimization
- tailwindcss 4 - CSS utility framework
- @tailwindcss/postcss 4 - PostCSS integration for Tailwind
- zod - Schema validation (used in various routes)
## Configuration Files
- `web/next.config.ts` - Next.js configuration with CSP headers, image optimization
- `web/tsconfig.json` - TypeScript compiler with path aliases (@/* → ./src/*)
- `web/eslint.config.mjs` - ESLint with Next.js Web Vitals and TypeScript rules
- `web/vitest.config.ts` - Vitest runner with @ alias resolution
- `web/package.json` - Dependencies, scripts (dev, build, test, lint, verify)
- `ready player 8.xcodeproj/project.pbxproj` - Xcode project (object v77, PBXFileSystemSynchronizedRootGroup)
- `ready player 8/Info.plist` - App permissions and launch configuration
- `.swiftlint.yml` - SwiftLint rules (disabled: line_length, force_cast, complexity)
- `.github/workflows/ci.yml` - CI/CD pipeline (macOS 15 for iOS, Ubuntu for web)
- `.github/workflows/link-health.yml` - Link health checking workflow
## Environment & Configuration
- Supabase credentials stored in `UserDefaults` and `Keychain`
- Anthropic API key stored in `AppStorage`
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- CSP: Allows scripts from mapbox.com, anthropic.com, vercel-scripts.com
## Build Targets
- App bundle: `ready player 8.app`
- Tests: `ready player 8Tests.xctest`
- UI Tests: `ready player 8UITests.xctest`
- Deployment: testFlight (via Xcode), App Store
- Build command: `next build --webpack`
- Output: Static + API routes (standalone for Docker via `output: 'standalone'` config option)
- Deployment: Vercel (primary), self-hosted Node.js server compatible
- Start command: `next start` (production server)
## Platform Requirements
- Xcode 16.2+ (for iOS/macOS build)
- Node.js 20+ (for web development)
- npm (for package management)
- Swift 5.9+ (implicit with Xcode 16.2)
- **iOS:** iOS 18.2+
- **macOS:** macOS 15.6+
- **visionOS:** Supported (via CarPlay integration in `ready_player_8App.swift`)
- **Web:** Node.js 20+ or Vercel Functions runtime
- **Database:** Supabase (PostgreSQL-based)
## Build Scripts
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Overview
- **Swift/SwiftUI**: iOS/macOS/visionOS app (ConstructionOS native)
- **TypeScript/React + Next.js**: Web platform
## Swift Conventions
### File Organization & MARK Comments
### Naming Patterns
- Use suffix `View` for all SwiftUI views: `ProjectsView`, `AuthGateView`, `MoneyLensView`, `AngelicAIView`
- Extracted sub-views are typically private var-computed properties within parent (e.g., `projectsHeader`, `statsRow`) or separate Views with descriptive names
- PascalCase for all model names: `SupabaseProject`, `WealthOpportunity`, `DecisionJournalEntry`, `PsychologySession`
- Enum cases: camelCase: `case login, signup, twoFactor, forgotPassword`
- Computed properties: camelCase with semantic meaning: `avgScore`, `wealthSignal`, `signalColor`
- camelCase for all function and property names
- Private properties: prefix with `private let`, `@State private var`
- Derived properties: computed vars using `var` with getter
- Plurals for collections: `projects`, `mockProjects`, `displayProjects`
- Hierarchical dot notation: `ConstructOS.Wealth.PsychologyScore`, `ConstructOS.AngelicAI.SessionID`, `ConstructOS.Integrations.Backend.BaseURL`
- Pattern: `{appName}.{feature}.{property}`
- Apply to all persistent state in UserDefaults
### Code Style & Structure
- Prefer computed properties for sub-views over inline closures
- Use `var body: some View` at top, then private sub-views below
- LazyVStack/VStack with consistent spacing (usually 12–16)
- `@State private var` for local UI state
- `@AppStorage` for persisted simple values (strings, ints, booleans)
- `@StateObject` for complex observable objects
- `@ObservedObject` when passing in shared instances (e.g., `@ObservedObject var profileStore = UserProfileStore.shared`)
- `@EnvironmentObject` for app-wide services (e.g., `SupabaseService`)
- Use `@escaping` for async callbacks
- Prefer `Task { await func() }` over GCD for async work
- Use `.task { await loadData() }` modifier on views for onAppear-like behavior
- Use `Theme` struct colors globally: `Theme.bg`, `Theme.surface`, `Theme.accent`, `Theme.gold`, `Theme.text`, `Theme.muted`
- Apply `.premiumGlow(cornerRadius: 16, color: Theme.accent)` for elevated cards (View extension in Theme)
- Fonts: `.system(size:, weight:)` with explicit weights (.heavy, .semibold, .medium)
- Letter spacing: `.tracking(2)` or `.tracking(4)` for titles
- Use `AppError` enum from `AppError.swift` with cases: `.network()`, `.supabaseNotConfigured`, `.supabaseHTTP()`, `.decoding()`, `.authFailed()`, `.validationFailed()`, `.permissionDenied()`, `.unknown()`
- All errors conform to `LocalizedError & Identifiable`
- Check `error.isRetryable` before auto-retry logic
- Use `error.severity` to determine alert style (`.info`, `.warning`, `.error`)
- Use `InputValidator` static methods: `.email()`, `.required()`, `.numeric()`, `.password()`, `.minLength()`
- Each validator returns `{ isValid: Bool, message: String }`
### Import Order
### Comments
- Explain `why`, not `what`: "Filter to active projects only" not "if status != Delayed"
- Document non-obvious logic: rate limiting, retry strategies, complex calculations
- Mark sections with `// MARK: -` for navigation
- Not commonly used in this codebase; prefer clear code
- Comments above complex computed properties: `// Average score excluding failed projects`
## TypeScript / Next.js Conventions
### File Organization
### Naming Patterns
- kebab-case for routes: `web/src/app/projects/page.tsx`, `web/src/app/api/chat/route.ts`
- camelCase for utilities and libraries: `web/src/lib/useFetch.ts`, `web/src/lib/seo.ts`
- PascalCase for React components (rarely extracted from pages): `AngelicFlowStrip.tsx`
- camelCase for all function and variable names
- `async` functions: `fetchTable()`, `getAuthenticatedClient()`, `insertRow()`
- Hook functions: prefix `use`: `useFetch()`, `useSubscriptionTier()`
- Constant arrays/objects: SCREAMING_SNAKE_CASE if config, camelCase if data: `RATE_LIMIT`, `WINDOW_MS`, `pageMetadata`, `navGroups`
- PascalCase: `type Project = { ... }`, `type RentalLead = { ... }`
- Suffixes: `_ledger`, `_messages`, `_ai_messages` for table names (snake_case in DB)
- Use `type` not `interface` for consistency
### Code Style
- Strict mode enabled (`"strict": true` in tsconfig)
- Target ES2017, ESNext modules
- No implicit any; all return types annotated
- Use path aliases: `@/lib`, `@/app/components`
- Organized in groups:
- Server functions: `async function fetchTable<T>(...)`
- Route handlers: `export async function POST(req: Request) { ... }`
- Client hooks: `useEffect(() => { fetch(...) })` with cleanup
- Always check `res.ok` before parsing JSON: `if (!res.ok) throw new Error(...)`
- Try-catch in async functions: wrap JSON parsing, API calls
- Return `NextResponse.json({ error: "message" }, { status: 400 })`
- Log to console: `console.error("[context] message:", err)`
- Fallback to safe defaults on error (empty arrays, null data)
- Inline in route handlers: check `typeof`, `.trim()`, required fields before DB insert
- Return 400 with descriptive error message if validation fails
- Implement per-IP in-memory map for single-instance deployments
- Key pattern: `rateLimit.get(ip)`, check count and resetAt
- Prune stale entries when map exceeds 10,000 entries
### Component Patterns
- Fetch data directly in component
- Use `async` component if needed
- No hooks, no event handlers
- Add `"use client"` directive at top of file
- Use `useState`, `useEffect`, `useFetch` hook
- `useState` for form inputs and local UI state
- Import from `@/lib/seo`: `const metadata = getPageMetadata("projects")`
- Export `metadata` const in `page.tsx` (server component)
- Type: `Metadata` from `next`
### Styling
- Inline `style={}` objects (no external CSS files in most pages)
- Custom properties: `var(--surface)`, `var(--accent)`, `var(--muted)`, `var(--green)`, `var(--purple)`, `var(--cyan)`, `var(--gold)`, `var(--red)`
- Design tokens: `padding: 20`, `borderRadius: 14`, `fontSize: 12`, `fontWeight: 800`
- Not heavily used (mostly inline styles)
- When used, prefer semantic utilities
### Comments
- Rate limiting logic, buffer management, memory cleanup
- Non-obvious state transitions
- TODO/FIXME for known gaps
## Cross-Platform Patterns
### Model Consistency
- `SupabaseProject`, `SupabaseContract`, `SupabaseWealthOpportunity` in `SupabaseService.swift`
- Wealth models in `WealthShared.swift`
- `type Project`, `type Contract`, `type RentalLead` in `web/src/lib/supabase/types.ts`
### AppStorage & UserDefaults Keys
### Error Recovery
- Log errors with context: file, function, what operation failed
- Provide user-friendly messages (no stack traces)
- Distinguish retryable from non-retryable errors
- Offer fallback UI: demo data (mobile), error boundary (web)
## Linting & Formatting
- Tool: ESLint 9 (flat config)
- Config: `web/eslint.config.mjs`
- Rules: Next.js core web vitals + TypeScript
- Run: `npm run lint` (no --fix used automatically)
- No linter enforced (SwiftUI formatting conventions followed by convention)
- Code structure enforced via Xcode build phases
## Summary
| Aspect | Swift | TypeScript |
|--------|-------|-----------|
| **File Org** | MARK comments, views + models | app/ routes, lib/ utilities |
| **Naming** | PascalCase types, camelCase props | kebab-case routes, camelCase utils |
| **State** | @State, @AppStorage, @ObservedObject | useState, hooks |
| **Async** | Task, async/await | async/await, useEffect |
| **Errors** | AppError enum | NextResponse.json with status |
| **Styling** | Theme struct colors | CSS custom properties |
| **Comments** | MARK sections, explain why | Rate limit, state logic |
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Layered architecture: UI → Services → Data Sync → Backend (Supabase)
- Offline-first with local persistence (UserDefaults/AppStorage), remote sync when configured
- AI-driven: Claude API integration with MCP tools for construction-specific assistance
- Mobile-first on iOS with secondary web support; visionOS/macOS as additional targets
- Mock data fallback for all features when backend not configured
- Feature gates with subscription tier access control
## Layers
- Purpose: Render UI, handle user interactions, coordinate navigation across 32+ tabs
- Location: `ready player 8/ContentView.swift` (35K lines, monolithic), individual view files (`ProjectsView.swift`, `ContractsView.swift`, etc.)
- Web: `web/src/app/**/*.tsx` (route-based pages and layouts)
- Contains: SwiftUI Views, React Components, Theme system, animations, forms
- Depends on: Service layer (Supabase, Analytics, Navigation)
- Used by: App entry points (`ready_player_8App.swift`, `web/src/app/layout.tsx`)
- Purpose: Encapsulate business logic, data operations, external service integration
- Location: 
- Contains: Supabase client initialization, analytics tracking, crash reporting, data validation
- Depends on: Data persistence, external APIs (Supabase, Anthropic)
- Used by: All view/page components
- Purpose: Manage local caching, Supabase sync, offline handling
- Location: `SupabaseCRUDWiring.swift` (DataSyncManager singleton), `web/src/lib/supabase/fetch.ts`
- Contains: Generic sync helpers, cache invalidation, network error handling, table mappings
- Pattern: Load local (UserDefaults) → Try remote (Supabase) → Fall back to mock data
- Depends on: Supabase client, local storage APIs
- Used by: Service layer and views
- Purpose: Single source of truth for persistent data when user configures backend
- Location: Remote PostgreSQL database via Supabase REST/Real-time APIs
- Tables: `cs_projects`, `cs_contracts`, `cs_market_data`, `cs_ai_messages`, `cs_wealth_*`, `cs_ops_*`, `cs_field_*`, etc.
- Auth: Configured via `ConstructOS.Integrations.Backend.BaseURL` and `ConstructOS.Integrations.Backend.ApiKey` (UserDefaults)
- Used by: DataSyncManager for fetching and persisting
- Purpose: Provide Claude-powered assistance with MCP tools and construction-specific knowledge
- iOS/macOS: `AngelicAIView.swift` (in-app chat interface), Anthropic API key from UserDefaults
- Web: `web/src/app/api/chat/route.ts` (server-side streaming endpoint)
- Model: `claude-haiku-4-5-20251001`
- Features: Rate limiting, fallback responses, live project/contract data injection into system prompt
- Purpose: System-level concerns (analytics, crash reporting, feature gates, preferences)
- Location: `AppInfrastructure.swift`, `AppEnvironment.swift`, `PersistenceController.swift`
- Classes: `AnalyticsEngine`, `CrashReporter`, `LinkHealthService` (shared singletons)
- Used by: App entry point and services
## Data Flow
- iOS/macOS: `@State`, `@AppStorage`, `@StateObject` with manual sync to Supabase
- Web: React hooks (`useState`, custom `useFetch`), Server Components for data loading
- Global singletons: `SupabaseService.shared`, `AnalyticsEngine.shared`, `CrashReporter.shared`, `DataSyncManager.shared`
- Wealth Suite uses dedicated AppStorage keys: `ConstructOS.Wealth.*`
## Key Abstractions
- Purpose: Centralized Supabase HTTP client with credential management
- Location: `ready player 8/SupabaseService.swift`
- Pattern: Reads URL/API key from UserDefaults, provides fetch/insert/update/delete methods
- Provides: `isConfigured` flag, automatic JSON serialization, error handling
- Used by: All data-dependent views, DataSyncManager
- Purpose: Generic sync orchestration for all data tables
- Pattern: Maintains local cache + attempts remote sync, tracks sync status per table
- Methods: `syncTable<T>()` (load local, try remote), `saveAndSync<T>()` (persist locally, queue remote)
- Used by: All views that load/save data (Projects, Contracts, Wealth suite, Ops panels, etc.)
- Purpose: Centralized color, typography, and design system
- Location: `ready player 8/ThemeAndModels.swift`
- Colors: Dark teal background (`bg`), amber accent (`accent`), cyan/gold/green/red/purple system colors
- Extensions: `View.premiumGlow()`, View adaptive color helpers
- Used by: All SwiftUI components for consistent styling
- Purpose: Encapsulate AI conversation state and history persistence
- Pattern: Store in Supabase `cs_ai_messages` table, maintain session ID in UserDefaults
- Fallback: If API unavailable, return hardcoded responses with navigation hints
- Used by: `AngelicAIView.swift` (iOS) and `/api/chat/route.ts` (Web)
- Purpose: Social network data model for construction professionals
- Fields: authorName, authorRole, authorTrade, postType, content, tags, timeAgo
- Types: WorkUpdate, ProjectWin, JobPosting, BidRequest, Shoutout
- Trades: General, Concrete, Steel, Electrical, Plumbing, HVAC, Framing, Roofing, Crane, Finishing
- Purpose: Standardized layout for 12-panel Operations suite
- Pattern: Each panel has title, description, mock data, sync to Supabase table
- Tables: change_orders, safety_incidents, rfis, submittals, punch_list, daily_logs, etc.
- Flow: Load from UserDefaults → Display with filtering/sorting → Save changes → Sync to Supabase
## Entry Points
- Location: `ready_player_8App.swift`
- Flow: App entry → Initialize singletons (SupabaseService, AnalyticsEngine, CrashReporter) → ContentView
- Responsibilities: CarPlay scene setup (if iOS+CarPlay), environment object injection, window group setup
- Location: `web/src/app/layout.tsx` (root), `web/src/app/page.tsx` (home)
- Flow: RootLayout sets up nav, footer, AngelicAssistant, Analytics → Page routes
- Responsibilities: Global metadata, security headers (CSP, HSTS, X-Frame-Options), theme wrapper
- iOS/macOS: `AuthGateView` (in ContentView) with login/signup/2FA steps
- Web: Supabase SSR client setup in `web/src/lib/supabase/server.ts`, callback at `web/src/app/auth/callback/route.ts`
## Error Handling
- Network errors: Log to CrashReporter, show toast message, keep user on current screen
- Missing data: Display empty state with "create new" CTA, or show mock data
- API failures: Fallback to hardcoded responses (e.g., chat API down → use getFallbackResponse)
- Validation: Input validation at form submission, display inline error messages
- Rate limiting: HTTP 429 with "wait a minute" message, prevents request even before API call
- Location: `web/src/app/error.tsx` (route-level), `web/src/app/*/error.tsx` (per-route)
- Pattern: Catch unhandled exceptions, show error UI with retry button
## Cross-Cutting Concerns
- iOS/macOS: `CrashReporter.shared.reportError()`, `AnalyticsEngine.shared.track()`
- Web: `console.error()`, Vercel Analytics, future Sentry integration
- All logged errors include context (function name, table name, operation type)
- iOS: Form validation in view (inline checks), Codable decoding validates JSON shape
- Web: Form validation in components, Zod schemas in `web/src/lib/**`
- Backend: Supabase RLS policies (if enabled) prevent unauthorized access
- iOS: AuthGateView with 2FA, credentials stored in Keychain (referenced but not always active)
- Web: Supabase SSR auth, session cookies, protected routes check subscription tier
- Feature Access: Web uses `FeatureAccessLink` component to gate features by subscription
- iOS/macOS: All data cached in UserDefaults/AppStorage, DataSyncManager syncs when online
- Web: None (assumes continuous connectivity)
- Mock data: Both platforms show mock data if no real data exists locally or remotely
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
