# Codebase Structure

**Analysis Date:** 2026-04-04

## Directory Layout

```
ready player 8/
├── ready player 8/                    # iOS/macOS/visionOS SwiftUI app (~60 Swift files)
│   ├── ContentView.swift              # Main navigation hub (35K lines, monolithic)
│   ├── ready_player_8App.swift        # App entry point + CarPlay
│   ├── ThemeAndModels.swift           # Design system + model definitions
│   ├── SupabaseService.swift          # Supabase client + DTOs
│   ├── AppInfrastructure.swift        # Analytics, crash reporting, feature gates
│   ├── SupabaseCRUDWiring.swift       # Data sync orchestration
│   ├── ProjectsView.swift             # Project CRUD + Supabase sync
│   ├── ContractsView.swift            # Bid pipeline management
│   ├── MarketView.swift               # Market intelligence dashboard
│   ├── AngelicAIView.swift            # AI chat with Anthropic API
│   ├── OperationsCore.swift           # RFIs, submittals, change orders
│   ├── OperationsField.swift          # Daily logs, timecards, permits
│   ├── OperationsCommercial.swift     # Commercial operations panels
│   ├── ConstructionOSNetwork.swift    # Social network data models
│   ├── WealthShared.swift             # Wealth suite shared data
│   ├── MoneyLensView.swift            # Money Lens dashboard
│   ├── PsychologyDecoderView.swift    # Psychology quiz + tracking
│   ├── PowerThinkingView.swift        # Decision journal
│   ├── LeverageSystemView.swift       # Leverage scoring
│   ├── OpportunityFilterView.swift    # Opportunity evaluation
│   ├── FieldOpsView.swift             # Field operations dashboard
│   ├── FinanceHubView.swift           # AIA pay apps, lien waivers
│   ├── SecurityAccessView.swift       # Face ID, Touch ID, 2FA
│   ├── ComplianceView.swift           # OSHA, safety compliance
│   ├── SatelliteRoofEstimatorView.swift  # AI roof estimator
│   ├── RentalSearchView.swift         # Equipment rental marketplace
│   ├── TaxAccountantView.swift        # Tax deduction tracker
│   ├── PunchListProView.swift         # Punch list management
│   ├── ScheduleTools.swift            # Gantt chart, scheduling
│   ├── MapsView.swift                 # Maps with satellite/weather overlays
│   ├── ElectricalFiberView.swift      # Electrical + fiber trades
│   ├── ConstructionTech2026View.swift # Tech trends (digital twins, robotics)
│   ├── SocialNetworkView.swift        # Social feed (legacy)
│   ├── SocialFeedNetwork.swift        # Social feed (current)
│   ├── GlobalContractorDirectoryView.swift  # Contractor search
│   ├── AnalyticsDashboardView.swift   # Analytics + reporting
│   ├── IntegrationHubView.swift       # Backend, auth, payment integration
│   ├── SettingsProfileView.swift      # User settings, profile management
│   ├── ClientPortalView.swift         # Owner/client dashboard
│   ├── FinancialInfrastructure.swift  # Pay, Capital, Insurance models
│   ├── CryptoPayments.swift           # Crypto payment support
│   ├── PlatformFeatures.swift         # Feature flags + metadata
│   ├── UserProfileNetwork.swift       # User profile + verification
│   ├── UIHelpers.swift                # Common UI components
│   ├── SharedComponents.swift         # Reusable sub-components
│   ├── AppError.swift                 # Error types + handling
│   ├── AppEnvironment.swift           # Environment variables
│   ├── Constants.swift                # Global constants (roles, trades, etc.)
│   ├── NetworkClient.swift            # Custom HTTP client
│   ├── ToastManager.swift             # Toast notifications
│   ├── PersistenceController.swift    # CoreData setup
│   ├── LinkHealthService.swift        # Link validation
│   ├── MCPServer.swift                # MCP server integration
│   ├── LayoutChrome.swift             # Navigation chrome
│   ├── AppStorageJSON.swift           # JSON UserDefaults helpers
│   ├── ViewUtilities.swift            # View extensions
│   ├── PricingView.swift              # Pricing page
│   ├── SmartBuildHubView.swift        # Smart construction
│   ├── VerificationSystem.swift       # 3-tier verification
│   ├── Assets.xcassets/               # Images, colors, fonts
│   └── Info.plist                     # Bundle configuration

├── web/                               # Next.js web app
│   ├── src/
│   │   ├── app/                       # App Router pages
│   │   │   ├── layout.tsx             # Root layout (nav, footer, auth check)
│   │   │   ├── page.tsx               # Home page with features overview
│   │   │   ├── login/
│   │   │   │   ├── page.tsx           # Login form
│   │   │   │   └── layout.tsx         # Login layout
│   │   │   ├── projects/
│   │   │   │   ├── page.tsx           # Projects list + CRUD
│   │   │   │   ├── layout.tsx         # Projects layout
│   │   │   │   └── error.tsx          # Error boundary
│   │   │   ├── contracts/
│   │   │   │   ├── page.tsx           # Contracts dashboard
│   │   │   │   ├── layout.tsx         # Contracts layout
│   │   │   │   └── error.tsx          # Error boundary
│   │   │   ├── ai/
│   │   │   │   ├── page.tsx           # AI assistant
│   │   │   │   ├── layout.tsx         # AI layout
│   │   │   │   └── error.tsx          # Error boundary
│   │   │   ├── api/
│   │   │   │   ├── chat/route.ts      # Anthropic API streaming endpoint
│   │   │   │   ├── projects/route.ts  # Projects CRUD endpoint
│   │   │   │   ├── contracts/route.ts # Contracts CRUD endpoint
│   │   │   │   ├── export/route.ts    # Data export endpoint
│   │   │   │   ├── jobs/route.ts      # Job listings endpoint
│   │   │   │   ├── leads/route.ts     # Lead capture endpoint
│   │   │   │   ├── feed/route.ts      # Social feed endpoint
│   │   │   │   ├── ops/route.ts       # Operations data endpoint
│   │   │   │   ├── punch/route.ts     # Punch list endpoint
│   │   │   │   ├── tasks/route.ts     # Tasks endpoint
│   │   │   │   ├── link-health/route.ts # Link validation endpoint
│   │   │   │   ├── auth/
│   │   │   │   │   ├── callback/route.ts # Supabase auth callback
│   │   │   │   │   └── signout/route.ts  # Sign out endpoint
│   │   │   │   ├── billing/
│   │   │   │   │   ├── checkout/route.ts # Paddle checkout
│   │   │   │   │   └── webhook/route.ts  # Paddle webhook
│   │   │   │   └── webhooks/
│   │   │   │       └── paddle/route.ts    # Subscription webhooks
│   │   │   ├── [32+ route pages]/      # Market, Maps, Rentals, Finance, Compliance, Field, etc.
│   │   │   ├── components/
│   │   │   │   ├── AngelicAssistant.tsx      # Floating AI chat widget
│   │   │   │   ├── AngelicFlowStrip.tsx      # AI prompt suggestions
│   │   │   │   ├── AngelicPromptToggle.tsx   # AI toggle
│   │   │   │   ├── FeatureAccessLink.tsx     # Subscription-gated link
│   │   │   │   ├── PremiumFeatureGate.tsx    # Feature paywall
│   │   │   │   ├── SubscriberActionButton.tsx # Tier-specific buttons
│   │   │   │   ├── NavAuthLinks.tsx          # Auth nav items
│   │   │   │   ├── MobileNav.tsx             # Mobile navigation
│   │   │   │   └── ExternalLink.tsx          # External link wrapper
│   │   │   ├── globals.css             # Tailwind + custom styles
│   │   │   ├── loading.tsx             # Global loading UI
│   │   │   ├── error.tsx               # Global error boundary
│   │   │   └── not-found.tsx           # 404 page
│   │   ├── lib/
│   │   │   ├── supabase/
│   │   │   │   ├── client.ts           # Browser Supabase client
│   │   │   │   ├── server.ts           # Server Supabase client (SSR)
│   │   │   │   ├── env.ts              # Environment variable getters
│   │   │   │   ├── types.ts            # TypeScript interfaces for DB
│   │   │   │   └── fetch.ts            # Generic fetch wrapper
│   │   │   ├── hooks/
│   │   │   │   └── useFetch.ts         # Custom fetch hook
│   │   │   ├── subscription/
│   │   │   │   ├── featureAccess.ts    # Feature availability checker
│   │   │   │   ├── featurePreviews.ts  # Preview access config
│   │   │   │   └── useSubscriptionTier.ts # Hook to get user tier
│   │   │   ├── billing/
│   │   │   │   ├── plans.ts            # Pricing tier definitions
│   │   │   │   └── square.ts           # Paddle integration
│   │   │   ├── links/
│   │   │   │   ├── externalLinks.ts    # External URL mappings
│   │   │   │   └── linkHealth.ts       # Link validation
│   │   │   ├── angelic/
│   │   │   │   └── preferences.ts      # AI preferences/settings
│   │   │   ├── nav.ts                  # Navigation structure
│   │   │   ├── mock-data.ts            # Fallback mock data
│   │   │   ├── seo.ts                  # SEO utilities
│   │   │   ├── rate-limit.ts           # Rate limiter for API
│   │   │   └── jobs.ts                 # Job listings utilities
│   │   └── proxy.ts                    # Request proxy config
│   ├── next.config.ts                  # Next.js configuration
│   ├── tailwind.config.ts              # Tailwind CSS config
│   ├── tsconfig.json                   # TypeScript config
│   ├── package.json                    # Dependencies (Next.js 15, React 19, Supabase, etc.)
│   └── public/                         # Static assets (logo, manifest)

├── ready player 8.xcodeproj/          # Xcode project settings
├── ready player 8Tests/               # Unit tests (minimal coverage)
├── ready player 8UITests/             # UI tests (minimal coverage)
├── docs/                              # Documentation (Metadata, design specs, etc.)
├── .planning/codebase/                # GSD planning documents (ARCHITECTURE.md, STRUCTURE.md, etc.)
├── .github/workflows/                 # CI/CD (link health checks, etc.)
├── .swiftlint.yml                     # SwiftLint configuration
└── .gitignore                         # Excluded files
```

## Directory Purposes

**ready player 8/ (iOS/macOS/visionOS):**
- Purpose: SwiftUI application for construction professionals
- Contains: Views, services, models, UI components
- Key patterns: SwiftUI @State/@AppStorage for local state, Supabase for sync, mock data fallback
- Auto-included: Uses PBXFileSystemSynchronizedRootGroup; new .swift files auto-included in Xcode

**web/src/app/ (Next.js Pages):**
- Purpose: Web UI and API routes
- Route files: page.tsx (display), layout.tsx (wrapper), error.tsx (boundaries), route.ts (API handlers)
- API routes: Each resource (projects, contracts, feed) has own route handler
- Pattern: Next.js App Router, Server Components by default, "use client" for interactive components

**web/src/lib/ (Shared Utilities):**
- Purpose: Reusable functions, hooks, integrations
- Supabase: Client + server initialization, type definitions, fetch wrappers
- Subscription: Feature access logic, tier checks
- Billing: Paddle integration, pricing definitions
- Mock data: Fallback data when backend unavailable

## Key File Locations

**Entry Points:**
- iOS/macOS: `ready player 8/ready_player_8App.swift` (App struct with @main)
- Web: `web/src/app/layout.tsx` (root), `web/src/app/page.tsx` (home)

**Configuration:**
- iOS: `ready player 8/Info.plist` (bundle config, privacy strings)
- Web: `web/next.config.ts` (CSP headers, image formats), `web/tsconfig.json` (paths), `tailwind.config.ts` (colors)

**Core Logic:**
- Data syncing: `ready player 8/SupabaseCRUDWiring.swift` (DataSyncManager), `web/src/lib/supabase/fetch.ts`
- AI: `ready player 8/AngelicAIView.swift` (iOS chat), `web/src/app/api/chat/route.ts` (web endpoint)
- Navigation: `ready player 8/ContentView.swift` (iOS tabs), `web/src/lib/nav.ts` (web routes)
- Theme: `ready player 8/ThemeAndModels.swift` (colors, typography)

**Testing:**
- Unit tests: `ready player 8Tests/` (minimal; mainly Swift files with @testable imports)
- UI tests: `ready player 8UITests/` (minimal; launch tests)
- Web tests: `web/src/__tests__/` (api.test.ts)

## Naming Conventions

**Files:**
- SwiftUI Views: `[FeatureName]View.swift` (e.g., `ProjectsView.swift`, `AngelicAIView.swift`)
- Services: `[ServiceName].swift` (e.g., `SupabaseService.swift`, `AppInfrastructure.swift`)
- Helpers/Utilities: `[Domain][Helper].swift` (e.g., `AppStorageJSON.swift`, `UIHelpers.swift`)
- Web pages: `[feature]/page.tsx` (e.g., `projects/page.tsx`, `ai/page.tsx`)
- Web API: `api/[resource]/route.ts` (e.g., `api/chat/route.ts`, `api/projects/route.ts`)
- Web components: `[ComponentName].tsx` (e.g., `AngelicAssistant.tsx`, `FeatureAccessLink.tsx`)

**Directories:**
- Feature-specific: lowercase with hyphens (e.g., `ready player 8/`, `web/src/app/`)
- Shared utilities: `lib/` with subdirectories by domain (supabase, hooks, billing, etc.)
- Routes: Flat structure with domain name (projects, contracts, ai, feed)

## Where to Add New Code

**New Feature (iOS/macOS):**
- Primary code: Create `[FeatureName]View.swift` in `ready player 8/`
- Data model: Add Codable struct to `ThemeAndModels.swift` or in same file as view
- If using Supabase: Add table mapping to `SupabaseCRUDWiring.swift` tableMap
- Navigation: Add to `NavTab` enum and navItems in `ContentView.swift`
- Tests: Create `ready player 8Tests/[FeatureName]Tests.swift`

**New Feature (Web):**
- Page: Create `web/src/app/[feature]/page.tsx`
- Layout (if shared): Create `web/src/app/[feature]/layout.tsx`
- API route: Create `web/src/app/api/[resource]/route.ts`
- Types: Add interface to `web/src/lib/supabase/types.ts`
- Tests: Create `web/src/__tests__/[feature].test.ts`

**Utility/Helper:**
- iOS: Add to `UIHelpers.swift`, `SharedComponents.swift`, or create new `[Domain]Helper.swift`
- Web: Add to `web/src/lib/[domain]/[helper].ts`

**Component (Web):**
- Location: `web/src/app/components/[ComponentName].tsx`
- Pattern: Export as default or named, use "use client" if interactive
- Style: Use Tailwind classes or inline styles with CSS variables

**New Data Table:**
- Supabase: Add SQL in `SupabaseCRUDWiring.swift` SQL comments or in database directly
- iOS model: Add Codable struct to `ThemeAndModels.swift` or feature file
- Web type: Add to `web/src/lib/supabase/types.ts` and ALLOWED_TABLES array
- Sync: Add entry to `DataSyncManager.tableMap` in iOS and corresponding API route in web

## Special Directories

**Assets.xcassets:**
- Purpose: Images, app icons, colors, fonts for iOS/macOS/visionOS
- Generated: No (manually added)
- Committed: Yes

**.next:**
- Purpose: Next.js build cache and compiled routes
- Generated: Yes (created by `next build`)
- Committed: No (in .gitignore)

**node_modules:**
- Purpose: npm dependencies
- Generated: Yes (by `npm install`)
- Committed: No (in .gitignore)

**docs:**
- Purpose: Product documentation, metadata, design specs
- Files: AppStore-Metadata.md, architecture docs, API specs
- Committed: Yes

**.planning/codebase:**
- Purpose: GSD codebase analysis documents (this file, ARCHITECTURE.md, CONVENTIONS.md, etc.)
- Generated: Yes (by /gsd-map-codebase)
- Committed: Yes

---

*Structure analysis: 2026-04-04*
