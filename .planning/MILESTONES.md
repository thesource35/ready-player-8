# Milestones

## v2.0 Portal & AI Expansion (Shipped: 2026-04-14)

**Phases completed:** 3 phases (18, 20, 21), 20 plans

**Scope note:** Original v2.0 scope was Phases 13–22 ("Feature Expansion"). After the 2026-04-14 milestone audit found 6/9 phases unverified and 4 critical integration blockers, scope was reduced to the three phases with complete goal-backward verification. Remaining phases (13–17, 19, 22) reassigned to v2.1 along with gap-closure phases 23–28.

**Key accomplishments:**

- Enhanced AI (Angelic AI v2): Claude tool calling with live Supabase project/contract data; RFI and change-order draft generation with human review-before-save pattern; iOS + web parity via `MCPServer.swift` and `web/src/app/api/chat/tools.ts`
- Client Portal: Shareable read-only project URLs with per-section visibility, custom branding (logo + theme), photo timeline with lightbox/ZIP/PDF export, CSS sanitizer + SVG attack mitigation, INSERT-only immutable audit log
- Portal Management: Web dashboard with template picker, soft-delete revocation, IP blocking, audit log API, webhook delivery with ID-only payloads, branded email templates
- Live Satellite & Traffic Maps: Unified map system across iOS (MapKit) and web (Mapbox); satellite/hybrid/standard layer toggle; real-time traffic overlays; construction equipment tracking with append-only location history and DISTINCT ON latest-position view; GPS-tagged photo markers
- iOS Equipment Check-In: GPS-capture check-in flow with `CheckInLocationManager` (CLLocationManagerDelegate wrapper); delivery routes via MKDirections with straight-line fallback
- Portal Map Integration: Token-based `/api/portal/map` pattern matching Phase 20 auth convention; admin-locked overlay configuration via `PortalSectionsConfig.map_overlays` JSONB

**Known Gaps (carried to v2.1):**

- 15 human UAT items remain across phases 20, 21 (visual/end-to-end checks requiring browser or device)
- 27 feature requirements (DOC, NOTIF, TEAM, FIELD, CAL, REPORT) reassigned to v2.1 gap-closure phases 23–28
- Integration blockers INT-01, INT-02, INT-06, INT-07 carried forward
- Integration blockers INT-03, INT-04, INT-05 closed by quick task 260414-n4w

**Timeline:** 2026-04-11 → 2026-04-14 (3 days for phases 18, 20, 21 execution)

**Archive:** `milestones/v2.0-ROADMAP.md` · `milestones/v2.0-REQUIREMENTS.md` · `milestones/v2.0-MILESTONE-AUDIT.md`

---

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
