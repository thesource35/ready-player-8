# External Integrations

**Analysis Date:** 2025-04-04

## APIs & External Services

**AI/Chat:**
- Anthropic Claude API (claude-haiku-4-5-20251001)
  - SDK/Client: `@ai-sdk/anthropic`, `ai` (Vercel AI SDK wrapper)
  - Auth: `ANTHROPIC_API_KEY` (env var)
  - Endpoint: `https://api.anthropic.com/v1/messages`
  - Used by: Chat route `/api/chat`, AngelicAIView (iOS), Web AI assistant
  - Rate limiting: In-place per-request throttling (20 req/min per IP on web)

**Maps & Location:**
- Mapbox GL
  - SDK/Client: `mapbox-gl` v3.20.0
  - Auth: API token (client-side in web)
  - Used by: `/web/src/app/maps/page.tsx` (interactive maps)
  - Features: Satellite view, custom styling, geofencing

**Equipment Rental Integrations (iOS):**
- URL schemes registered (LSApplicationQueriesSchemes in Info.plist):
  - `unitedrentals://` - United Rentals app deep linking
  - `dozr://` - DOZR equipment rental platform
  - `sunbeltrentals://` - Sunbelt Rentals app deep linking
  - Used by: RentalSearchView for quote flows

## Data Storage

**Databases:**
- **Supabase (PostgreSQL):**
  - Connection: `NEXT_PUBLIC_SUPABASE_URL` (env var)
  - Client: `@supabase/supabase-js`, `@supabase/ssr`
  - Auth method: API key + JWT tokens (managed by Supabase auth)

**Tables (with schema details in `SupabaseService.swift`):**
- `cs_projects` - Construction project data (name, budget, progress, status, score)
- `cs_contracts` - Bid/contract pipeline (title, client, stage, budget, score)
- `cs_market_data` - Market intelligence (city, vacancy, trends)
- `cs_ai_messages` - Conversation history (session_id, role, content)
- `cs_wealth_opportunities` - Opportunity tracking
- `cs_decision_journal` - Decision log with context and outcomes
- `cs_psychology_sessions` - Psychology quiz results and scoring
- `cs_leverage_snapshots` - Leverage system state snapshots
- `cs_wealth_tracking` - Financial tracking data
- `cs_daily_logs` - Field operations logs
- `cs_timecards` - Crew time tracking
- `cs_ops_alerts` - Operational alerts
- `cs_rfis` - Request for Information documents
- `cs_change_orders` - Change order tracking
- `cs_punch_pro` - Punch list items
- `cs_feed_posts` - Social feed posts
- `cs_transactions` - Financial transactions
- `cs_tax_expenses` - Tax deduction tracking
- `cs_rental_leads` - Rental opportunity leads
- `cs_user_profiles` - User account and subscription tier (free/field/pm/owner)

**File Storage:**
- Supabase Storage (via Supabase client, configuration required)
- Local filesystem only (when Supabase not configured)

**Caching:**
- None centralized
- In-memory via Supabase client cache
- Browser cache (Next.js default for static assets)

## Authentication & Identity

**Auth Provider:**
- Supabase Auth (built-in PostgreSQL auth backend)
  - Implementation: OAuth + email/password
  - Endpoints: `{SUPABASE_URL}/auth/v1/signup`, `/auth/v1/token`, `/auth/v1/refresh`
  - Auth flow:
    - iOS: Manual email/password via SupabaseService API calls (stores JWT in Keychain)
    - Web: Supabase SSR adapter with cookies (routes: `/auth/callback`, `/auth/signout`)
  - Session: JWT tokens refreshed via refresh_token
  - Storage: Keychain (iOS), Secure cookies (Web)

**Server-Side Sessions:**
- Web: Supabase JWT in secure HTTP-only cookies (via @supabase/ssr)
- iOS: Access token + refresh token in Keychain

**Related Files:**
- `web/src/app/auth/callback/route.ts` - OAuth callback handler
- `web/src/app/auth/signout/route.ts` - Sign out handler
- `web/src/lib/supabase/server.ts` - Server-side Supabase client
- `web/src/lib/supabase/client.ts` - Browser-side Supabase client
- `ready player 8/SupabaseService.swift` - iOS Supabase integration

## Verification & Identity Verification

**3-Tier Verification System:**
- Identity Verified
- Licensed Professional
- Verified Company
- Accessed via `/verify` route
- Data stored in Supabase tables (managed via VerificationSystem.swift)

## Monitoring & Observability

**Error Tracking:**
- Custom in-app error capture via `CrashReporter` (iOS)
  - Stored in `UserDefaults` under `ConstructOS.Crashes`
  - Logs persisted locally (no external crash reporting service)
- Web: Standard console errors (no external service detected)

**Analytics:**
- **iOS:** Custom `AnalyticsEngine` with event tracking
  - Events stored in `UserDefaults` (key: `ConstructOS.Analytics.Events`)
  - Tracks: Screen views, actions, errors
  - Max 500 events in memory
  - No external analytics service (local-only)
- **Web:** Vercel Analytics
  - Package: `@vercel/analytics` v2.0.1
  - Integrated in `web/src/app/layout.tsx` (Analytics component)
  - Collects: Page views, Core Web Vitals, performance metrics

**Logging:**
- Console logging (native Swift in iOS, browser console in web)
- No centralized logging service (Sentry, LogRocket, etc.)

## CI/CD & Deployment

**Hosting:**
- **Web:** Vercel (primary platform, Next.js optimized)
  - Deployment: Git-connected (GitHub Actions pushes to Vercel)
  - Runtime: Node.js 20
- **iOS:** TestFlight / App Store (manual via Xcode)
- **Alternative:** Self-hosted Node.js compatible deployment

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - **iOS Build:**
    - Runs on: macOS 15
    - Xcode 16.2
    - Builds for iPhone 16 Simulator
    - Runs unit and UI tests
  - **Web Build:**
    - Runs on: Ubuntu latest
    - Node.js 20
    - Steps: lint, typecheck, build
  - **Link Health:**
    - Automated link checking (ripgrep-based)
    - Runs on: Ubuntu latest

**Pre-commit/Pre-push:**
- `npm run verify` (lint + typecheck + build)
- SwiftLint (iOS, via `.swiftlint.yml`)

## Environment Configuration

**Required env vars (Web):**
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase project URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` or `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` - Anon key
- `ANTHROPIC_API_KEY` - Optional (enables live AI, fallback mode works without)

**Billing/Payment:**
- `SQUARE_*_PAYMENT_LINK` env vars (Square payment links)
  - Tiers: field, pm, owner
  - Intervals: monthly, annual
  - Configuration: `web/src/lib/billing/square.ts`

**Secrets location:**
- Web: Vercel environment variables (secure)
- iOS: Keychain (secure), UserDefaults (credentials set via UI)
- Never committed to git (.env* files ignored)

## Webhooks & Callbacks

**Incoming:**
- **Billing Webhook:**
  - Route: `/api/billing/webhook`
  - Source: Square (payment confirmation)
  - Handles: Payment success, subscription updates
- **Supabase Auth Callback:**
  - Route: `/auth/callback`
  - Source: Supabase OAuth provider
  - Handles: OAuth login completion

**Outgoing:**
- None detected
- Platform designed as consumer of external services, not producer

## API Rate Limiting

**Web Chat Route (`/api/chat`):**
- Implementation: In-memory Map per Fluid Compute instance
- Limit: 20 requests per 60 seconds per IP
- Fallback: Returns mock response if rate limit exceeded
- Note: For stricter enforcement, recommends Vercel KV or Upstash Redis

**Supabase:**
- Default rate limits (Supabase tier-dependent)
- No custom limits enforced in app layer

**Anthropic Claude:**
- Default API rate limits per subscription tier
- Handled by Anthropic's backend

## Route Access Control

**Subscription Tier Gating:**
File: `web/src/proxy.ts` (Next.js middleware)

- **Free Tier Routes:**
  - `/checkout`, `/verify`, `/profile`, `/jobs`, `/feed`, `/settings`
  - Accessible to all logged-in users

- **Field Tier ($X/month):**
  - `/compliance`, `/rentals`, `/field`

- **PM Tier ($X/month):**
  - `/projects`, `/contracts`, `/market`, `/maps`, `/ops`, `/ai`, `/analytics`, `/clients`, `/schedule`, `/training`, `/scanner`, `/electrical`, `/tax`, `/punch`, `/roofing`, `/smart-build`, `/contractors`, `/tech`, `/wealth`, `/tasks`, `/trust`, `/cos-network`, `/security`

- **Owner Tier ($X/month):**
  - `/finance`, `/hub`, `/empire`

**Preview Pages:**
- Non-paying users redirected to `/preview/*` for feature demos
- Public routes: `/`, `/login`, `/pricing`, `/terms`, `/privacy`, `/support`, `/not-found`

---

*Integration audit: 2025-04-04*
