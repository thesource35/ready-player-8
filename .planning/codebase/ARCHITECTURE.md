# Architecture

**Analysis Date:** 2026-04-04

## Pattern Overview

**Overall:** Multi-platform, feature-rich construction management system with distributed architecture across iOS/macOS/visionOS SwiftUI app and Next.js web platform. Both platforms sync with shared Supabase backend and integrate Anthropic Claude AI.

**Key Characteristics:**
- Layered architecture: UI → Services → Data Sync → Backend (Supabase)
- Offline-first with local persistence (UserDefaults/AppStorage), remote sync when configured
- AI-driven: Claude API integration with MCP tools for construction-specific assistance
- Mobile-first on iOS with secondary web support; visionOS/macOS as additional targets
- Mock data fallback for all features when backend not configured
- Feature gates with subscription tier access control

## Layers

**Presentation Layer (Views & UI):**
- Purpose: Render UI, handle user interactions, coordinate navigation across 32+ tabs
- Location: `ready player 8/ContentView.swift` (35K lines, monolithic), individual view files (`ProjectsView.swift`, `ContractsView.swift`, etc.)
- Web: `web/src/app/**/*.tsx` (route-based pages and layouts)
- Contains: SwiftUI Views, React Components, Theme system, animations, forms
- Depends on: Service layer (Supabase, Analytics, Navigation)
- Used by: App entry points (`ready_player_8App.swift`, `web/src/app/layout.tsx`)

**Service Layer:**
- Purpose: Encapsulate business logic, data operations, external service integration
- Location: 
  - iOS/macOS: `SupabaseService.swift`, `AppInfrastructure.swift`, `ConstructionOSNetwork.swift`, `AppError.swift`, `NetworkClient.swift`
  - Web: `web/src/lib/**/*.ts` (utilities, hooks, integrations)
- Contains: Supabase client initialization, analytics tracking, crash reporting, data validation
- Depends on: Data persistence, external APIs (Supabase, Anthropic)
- Used by: All view/page components

**Data Sync Layer:**
- Purpose: Manage local caching, Supabase sync, offline handling
- Location: `SupabaseCRUDWiring.swift` (DataSyncManager singleton), `web/src/lib/supabase/fetch.ts`
- Contains: Generic sync helpers, cache invalidation, network error handling, table mappings
- Pattern: Load local (UserDefaults) → Try remote (Supabase) → Fall back to mock data
- Depends on: Supabase client, local storage APIs
- Used by: Service layer and views

**Backend (Supabase):**
- Purpose: Single source of truth for persistent data when user configures backend
- Location: Remote PostgreSQL database via Supabase REST/Real-time APIs
- Tables: `cs_projects`, `cs_contracts`, `cs_market_data`, `cs_ai_messages`, `cs_wealth_*`, `cs_ops_*`, `cs_field_*`, etc.
- Auth: Configured via `ConstructOS.Integrations.Backend.BaseURL` and `ConstructOS.Integrations.Backend.ApiKey` (UserDefaults)
- Used by: DataSyncManager for fetching and persisting

**AI Layer:**
- Purpose: Provide Claude-powered assistance with MCP tools and construction-specific knowledge
- iOS/macOS: `AngelicAIView.swift` (in-app chat interface), Anthropic API key from UserDefaults
- Web: `web/src/app/api/chat/route.ts` (server-side streaming endpoint)
- Model: `claude-haiku-4-5-20251001`
- Features: Rate limiting, fallback responses, live project/contract data injection into system prompt

**Infrastructure Layer:**
- Purpose: System-level concerns (analytics, crash reporting, feature gates, preferences)
- Location: `AppInfrastructure.swift`, `AppEnvironment.swift`, `PersistenceController.swift`
- Classes: `AnalyticsEngine`, `CrashReporter`, `LinkHealthService` (shared singletons)
- Used by: App entry point and services

## Data Flow

**User Interaction → Data Persistence:**

1. User performs action (create project, send chat message, etc.)
2. View calls service method (e.g., `saveProject(newProject)`)
3. Service validates and transforms data if needed
4. DataSyncManager saves to local (UserDefaults/AppStorage)
5. If Supabase configured: DataSyncManager attempts remote write via REST API
6. On error: logs to CrashReporter, shows user-friendly toast, data remains in local storage for offline

**Remote Read Flow:**

1. View loads → calls `await loadProjects()`
2. DataSyncManager starts with local cache (UserDefaults)
3. If Supabase configured: async fetch live data from `cs_projects` table
4. Remote data replaces local if non-empty
5. If network fails: uses cached local data
6. If no data exists: shows empty state or mock data

**State Management:**
- iOS/macOS: `@State`, `@AppStorage`, `@StateObject` with manual sync to Supabase
- Web: React hooks (`useState`, custom `useFetch`), Server Components for data loading
- Global singletons: `SupabaseService.shared`, `AnalyticsEngine.shared`, `CrashReporter.shared`, `DataSyncManager.shared`
- Wealth Suite uses dedicated AppStorage keys: `ConstructOS.Wealth.*`

**AI Chat Flow (Web):**

1. User submits message → `web/src/app/api/chat/route.ts`
2. Rate limiter checks IP-based quota (20 requests/60 seconds)
3. Fetch live projects/contracts from Supabase to inject into system prompt
4. Call Anthropic API with streaming enabled
5. Parse `content_block_delta` events and stream back to client as `text/plain`
6. On API failure: return fallback response with hardcoded navigation links

## Key Abstractions

**SupabaseService:**
- Purpose: Centralized Supabase HTTP client with credential management
- Location: `ready player 8/SupabaseService.swift`
- Pattern: Reads URL/API key from UserDefaults, provides fetch/insert/update/delete methods
- Provides: `isConfigured` flag, automatic JSON serialization, error handling
- Used by: All data-dependent views, DataSyncManager

**DataSyncManager:**
- Purpose: Generic sync orchestration for all data tables
- Pattern: Maintains local cache + attempts remote sync, tracks sync status per table
- Methods: `syncTable<T>()` (load local, try remote), `saveAndSync<T>()` (persist locally, queue remote)
- Used by: All views that load/save data (Projects, Contracts, Wealth suite, Ops panels, etc.)

**Theme:**
- Purpose: Centralized color, typography, and design system
- Location: `ready player 8/ThemeAndModels.swift`
- Colors: Dark teal background (`bg`), amber accent (`accent`), cyan/gold/green/red/purple system colors
- Extensions: `View.premiumGlow()`, View adaptive color helpers
- Used by: All SwiftUI components for consistent styling

**AIMessage / AngelicAI:**
- Purpose: Encapsulate AI conversation state and history persistence
- Pattern: Store in Supabase `cs_ai_messages` table, maintain session ID in UserDefaults
- Fallback: If API unavailable, return hardcoded responses with navigation hints
- Used by: `AngelicAIView.swift` (iOS) and `/api/chat/route.ts` (Web)

**ConstructionOSNetworkPost:**
- Purpose: Social network data model for construction professionals
- Fields: authorName, authorRole, authorTrade, postType, content, tags, timeAgo
- Types: WorkUpdate, ProjectWin, JobPosting, BidRequest, Shoutout
- Trades: General, Concrete, Steel, Electrical, Plumbing, HVAC, Framing, Roofing, Crane, Finishing

**OpsPanel Abstractions:**
- Purpose: Standardized layout for 12-panel Operations suite
- Pattern: Each panel has title, description, mock data, sync to Supabase table
- Tables: change_orders, safety_incidents, rfis, submittals, punch_list, daily_logs, etc.
- Flow: Load from UserDefaults → Display with filtering/sorting → Save changes → Sync to Supabase

## Entry Points

**iOS/macOS/visionOS:**
- Location: `ready_player_8App.swift`
- Flow: App entry → Initialize singletons (SupabaseService, AnalyticsEngine, CrashReporter) → ContentView
- Responsibilities: CarPlay scene setup (if iOS+CarPlay), environment object injection, window group setup

**Web:**
- Location: `web/src/app/layout.tsx` (root), `web/src/app/page.tsx` (home)
- Flow: RootLayout sets up nav, footer, AngelicAssistant, Analytics → Page routes
- Responsibilities: Global metadata, security headers (CSP, HSTS, X-Frame-Options), theme wrapper

**Authentication:**
- iOS/macOS: `AuthGateView` (in ContentView) with login/signup/2FA steps
- Web: Supabase SSR client setup in `web/src/lib/supabase/server.ts`, callback at `web/src/app/auth/callback/route.ts`

## Error Handling

**Strategy:** Multi-layered with user-friendly fallbacks and offline support

**Patterns:**
- Network errors: Log to CrashReporter, show toast message, keep user on current screen
- Missing data: Display empty state with "create new" CTA, or show mock data
- API failures: Fallback to hardcoded responses (e.g., chat API down → use getFallbackResponse)
- Validation: Input validation at form submission, display inline error messages
- Rate limiting: HTTP 429 with "wait a minute" message, prevents request even before API call

**Error Boundaries (Web):**
- Location: `web/src/app/error.tsx` (route-level), `web/src/app/*/error.tsx` (per-route)
- Pattern: Catch unhandled exceptions, show error UI with retry button

## Cross-Cutting Concerns

**Logging:** 
- iOS/macOS: `CrashReporter.shared.reportError()`, `AnalyticsEngine.shared.track()`
- Web: `console.error()`, Vercel Analytics, future Sentry integration
- All logged errors include context (function name, table name, operation type)

**Validation:**
- iOS: Form validation in view (inline checks), Codable decoding validates JSON shape
- Web: Form validation in components, Zod schemas in `web/src/lib/**`
- Backend: Supabase RLS policies (if enabled) prevent unauthorized access

**Authentication:**
- iOS: AuthGateView with 2FA, credentials stored in Keychain (referenced but not always active)
- Web: Supabase SSR auth, session cookies, protected routes check subscription tier
- Feature Access: Web uses `FeatureAccessLink` component to gate features by subscription

**Offline Support:**
- iOS/macOS: All data cached in UserDefaults/AppStorage, DataSyncManager syncs when online
- Web: None (assumes continuous connectivity)
- Mock data: Both platforms show mock data if no real data exists locally or remotely

---

*Architecture analysis: 2026-04-04*
