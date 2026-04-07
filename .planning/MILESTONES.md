# Milestones

## v1.0 Production Hardening (Shipped: 2026-04-07)

**Phases completed:** 12 phases, 36 plans, 48 tasks

**Key accomplishments:**

- 1. [Rule 2 - Security] Added UserDefaults cleanup in saveBackendConfig
- web/src/lib/supabase/env.ts (created):
- Comprehensive .gitignore, removed platform-specific SWC dep, fixed iOS deployment target from invalid 26.2 to 18.2
- 3-phase Supabase migration (columns + backfill + policies) enabling row-level security on all 23 tables with per-user data isolation
- Replaced 4 force unwraps in SupabaseService and 2 fatalError calls in PersistenceController with guard-let throws and in-memory Core Data fallback
- Replaced all 11 force unwrap operators across 5 view-layer Swift files with safe unwrapping patterns (guard-let, optional chaining, nil-coalescing, map)
- 1. [Rule 3 - Blocking] applyHeaders made throwing required caller updates
- Zod input validation on /api/leads, CSRF origin protection on 8 mutating routes, Paddle HMAC-SHA256 webhook verification with subscription tier upsert
- Commit:
- 23 per-route error.tsx boundaries added to all uncovered web routes, achieving 100% error boundary coverage (41 routes + 1 root = 42 total)
- Upstash Redis dual-mode rate limiter with per-route config in middleware and JWT decode fast-path for session validation
- 1. [Rule 3 - Blocking] Created billing/plans.ts in worktree
- 25 page metadata layouts, dynamic sitemap/robots.txt, OpenGraph image, and 192x192 PWA icon for search discovery and social sharing
- A11Y-01: Icon-only button aria-labels
- Commit:
- 18 unit tests covering SupabaseService CRUD error paths, Keychain migration, auth state transitions, and AppStorageJSON persistence edge cases
- Commit:
- 24 Vitest unit tests covering Chat API (7), Leads API (7), and auth middleware (10) with full mock isolation for rate limiting, CSRF, Supabase, and AI SDK
- 1. [Rule 1 - Bug] Adapted payment method test values to match actual codebase
- Playwright E2E specs for auth/project-create and AI chat flows with full API mocking via page.route()

---

## v1.0 Production Hardening (Shipped: 2026-04-06)

**Phases completed:** 12 phases, 36 plans, 48 tasks

**Key accomplishments:**

- 1. [Rule 2 - Security] Added UserDefaults cleanup in saveBackendConfig
- web/src/lib/supabase/env.ts (created):
- Comprehensive .gitignore, removed platform-specific SWC dep, fixed iOS deployment target from invalid 26.2 to 18.2
- 3-phase Supabase migration (columns + backfill + policies) enabling row-level security on all 23 tables with per-user data isolation
- Replaced 4 force unwraps in SupabaseService and 2 fatalError calls in PersistenceController with guard-let throws and in-memory Core Data fallback
- Replaced all 11 force unwrap operators across 5 view-layer Swift files with safe unwrapping patterns (guard-let, optional chaining, nil-coalescing, map)
- 1. [Rule 3 - Blocking] applyHeaders made throwing required caller updates
- Zod input validation on /api/leads, CSRF origin protection on 8 mutating routes, Paddle HMAC-SHA256 webhook verification with subscription tier upsert
- Commit:
- 23 per-route error.tsx boundaries added to all uncovered web routes, achieving 100% error boundary coverage (41 routes + 1 root = 42 total)
- Upstash Redis dual-mode rate limiter with per-route config in middleware and JWT decode fast-path for session validation
- 1. [Rule 3 - Blocking] Created billing/plans.ts in worktree
- 25 page metadata layouts, dynamic sitemap/robots.txt, OpenGraph image, and 192x192 PWA icon for search discovery and social sharing
- A11Y-01: Icon-only button aria-labels
- Commit:
- 18 unit tests covering SupabaseService CRUD error paths, Keychain migration, auth state transitions, and AppStorageJSON persistence edge cases
- Commit:
- 24 Vitest unit tests covering Chat API (7), Leads API (7), and auth middleware (10) with full mock isolation for rate limiting, CSRF, Supabase, and AI SDK
- 1. [Rule 1 - Bug] Adapted payment method test values to match actual codebase
- Playwright E2E specs for auth/project-create and AI chat flows with full API mocking via page.route()

---
