# Technology Stack

**Analysis Date:** 2025-04-04

## Languages

**Primary:**
- Swift - iOS 18.2+, macOS 15.6+, visionOS support (SwiftUI framework)
- TypeScript - 5.x - Web app and API routes (Next.js)
- JavaScript - Node.js runtime for build and scripts

**Secondary:**
- SQL - Supabase database queries and schema
- YAML - CI/CD workflows and configuration

## Runtime

**Environment:**
- **iOS/macOS/visionOS:** Native Swift runtime (XCode 16.2)
- **Web:** Node.js 20 (specified in GitHub Actions)
- **API:** Node.js runtime (Vercel Functions on Vercel platform)

**Package Managers:**
- **iOS:** None (native framework dependencies via SPM, no CocoaPods)
- **Web:** npm - Lockfile: `web/package-lock.json` present

## Frameworks

**Core Web:**
- Next.js 16.2.2 - Full-stack React framework with App Router
- React 19.2.4 - UI library
- React DOM 19.2.4 - DOM renderer

**Core iOS/macOS:**
- SwiftUI - Native declarative UI framework
- Combine - Reactive programming framework
- CoreData - Local persistence (template-only, unused by app data)

**Testing:**
- vitest 3.2.4 - Web unit testing (Node environment)
- XCTest - iOS unit tests (via GitHub Actions)

**Build/Dev:**
- TypeScript 5.x - Type checking
- Tailwind CSS 4 - Web utility-first CSS (via @tailwindcss/postcss)
- ESLint 9 - Web linting (with Next.js config)
- @next/swc-darwin-arm64 16.2.2 - Next.js compiler (ARM macOS)

## Key Dependencies

**Critical:**
- @supabase/ssr 0.10.0 - Server-side Supabase auth/session management (web)
- @supabase/supabase-js 2.101.1 - Supabase JavaScript client
- @ai-sdk/anthropic 3.0.64 - Anthropic SDK (Claude API client)
- ai 6.0.142 - Vercel AI SDK for LLM streaming and chat
- mapbox-gl 3.20.0 - Interactive maps library (web maps page)

**Infrastructure:**
- @vercel/analytics 2.0.1 - Analytics tracking for Vercel deployments
- next - Next.js framework with built-in image/font optimization

**Styling & UI:**
- tailwindcss 4 - CSS utility framework
- @tailwindcss/postcss 4 - PostCSS integration for Tailwind

**Utilities:**
- zod - Schema validation (used in various routes)

## Configuration Files

**Web:**
- `web/next.config.ts` - Next.js configuration with CSP headers, image optimization
- `web/tsconfig.json` - TypeScript compiler with path aliases (@/* → ./src/*)
- `web/eslint.config.mjs` - ESLint with Next.js Web Vitals and TypeScript rules
- `web/vitest.config.ts` - Vitest runner with @ alias resolution
- `web/package.json` - Dependencies, scripts (dev, build, test, lint, verify)

**iOS:**
- `ready player 8.xcodeproj/project.pbxproj` - Xcode project (object v77, PBXFileSystemSynchronizedRootGroup)
- `ready player 8/Info.plist` - App permissions and launch configuration
- `.swiftlint.yml` - SwiftLint rules (disabled: line_length, force_cast, complexity)

**Project:**
- `.github/workflows/ci.yml` - CI/CD pipeline (macOS 15 for iOS, Ubuntu for web)
- `.github/workflows/link-health.yml` - Link health checking workflow

## Environment & Configuration

**Web Environment Variables:**
```
NEXT_PUBLIC_SUPABASE_URL        # Supabase project URL
NEXT_PUBLIC_SUPABASE_ANON_KEY   # Supabase anonymous key
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY  # Supabase publishable key (alternate)
ANTHROPIC_API_KEY               # Claude API key (fallback route if unavailable)
SQUARE_*_PAYMENT_LINK           # Square payment links for billing tiers
```

**iOS Configuration:**
- Supabase credentials stored in `UserDefaults` and `Keychain`
  - `ConstructOS.Integrations.Backend.BaseURL`
  - `ConstructOS.Integrations.Backend.ApiKey`
- Anthropic API key stored in `AppStorage`
  - `ConstructOS.AngelicAI.APIKey`
  - `ConstructOS.AngelicAI.SessionID`

**Security Headers (Next.js):**
- X-Frame-Options: DENY
- X-Content-Type-Options: nosniff
- Referrer-Policy: strict-origin-when-cross-origin
- CSP: Allows scripts from mapbox.com, anthropic.com, vercel-scripts.com

## Build Targets

**iOS/macOS:**
- App bundle: `ready player 8.app`
- Tests: `ready player 8Tests.xctest`
- UI Tests: `ready player 8UITests.xctest`
- Deployment: testFlight (via Xcode), App Store

**Web:**
- Build command: `next build --webpack`
- Output: Static + API routes (standalone for Docker via `output: 'standalone'` config option)
- Deployment: Vercel (primary), self-hosted Node.js server compatible
- Start command: `next start` (production server)

## Platform Requirements

**Development:**
- Xcode 16.2+ (for iOS/macOS build)
- Node.js 20+ (for web development)
- npm (for package management)
- Swift 5.9+ (implicit with Xcode 16.2)

**Production:**
- **iOS:** iOS 18.2+
- **macOS:** macOS 15.6+
- **visionOS:** Supported (via CarPlay integration in `ready_player_8App.swift`)
- **Web:** Node.js 20+ or Vercel Functions runtime
- **Database:** Supabase (PostgreSQL-based)

## Build Scripts

**Web:**
```bash
npm run dev          # Start development server (next dev)
npm run build        # Build for production with webpack
npm start            # Start production server
npm run lint         # Run ESLint
npm run typecheck    # Run TypeScript type checker
npm run test         # Run vitest unit tests
npm run verify       # lint + typecheck + build (pre-commit)
npm run smoke        # Smoke tests (custom)
npm run linkcheck    # Check link health (ripgrep-based)
```

**iOS:**
```bash
xcodebuild build -project "ready player 8.xcodeproj" -scheme "ready player 8" ...
xcodebuild test -project "ready player 8.xcodeproj" -scheme "ready player 8" ...
```

---

*Stack analysis: 2025-04-04*
