# ConstructionOS — Production Hardening

## What This Is

A production-hardened multi-platform construction management app (iOS/macOS/visionOS SwiftUI + Next.js web). Shipped v1.0 hardening milestone: secure credential storage, real authentication with MFA, row-level security on all 23 Supabase tables, crash-safe iOS code, comprehensive error handling, web security hardening, accessibility, SEO, and test coverage across both platforms.

## Core Value

Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## Current State

**Shipped:** v1.0 Production Hardening (2026-04-06)
**Codebase:** ~31,684 LOC Swift + ~25,105 LOC TypeScript = ~56,789 total
**Tech stack:** SwiftUI (iOS 18.2+), Next.js 16.2.2, React 19, Supabase, Anthropic Claude API
**Tests:** 18 iOS unit tests (XCTest), 42 web unit tests (Vitest), 2 Playwright E2E specs

## Requirements

### Validated

- ✓ Projects CRUD with Supabase sync — existing
- ✓ Contracts/bid pipeline management — existing
- ✓ Market intelligence dashboard — existing
- ✓ Angelic AI chat (Claude API) — existing
- ✓ Wealth Suite (5 tabs) — existing
- ✓ Rental search and equipment management — existing
- ✓ Operations views (commercial, core) — existing
- ✓ Integration Hub for backend configuration — existing
- ✓ Web platform with 30+ route pages — existing
- ✓ Theme system and premium UI — existing
- ✓ CarPlay support — existing
- ✓ iOS Keychain credential storage with UserDefaults migration — v1.0
- ✓ Supabase Auth with email/password, MFA, session management — v1.0
- ✓ Row-level security on all 23 Supabase tables — v1.0
- ✓ iOS crash safety (all force unwraps eliminated) — v1.0
- ✓ iOS error handling with CrashReporter logging — v1.0
- ✓ iOS state persistence via AppStorageJSON — v1.0
- ✓ Web Zod validation, CSRF, Paddle webhook HMAC — v1.0
- ✓ Web error boundaries on all 42 routes — v1.0
- ✓ Web loading/empty states on data pages — v1.0
- ✓ Distributed rate limiting (Upstash Redis) — v1.0
- ✓ Pagination on all data routes — v1.0
- ✓ Dynamic content (no hardcoded users/prices/dates) — v1.0
- ✓ Web accessibility (aria-labels, form labels, status text) — v1.0
- ✓ iOS accessibility (182+ VoiceOver labels) — v1.0
- ✓ SEO metadata, sitemap, robots.txt, OG image — v1.0
- ✓ iOS unit tests (SupabaseService, Keychain, auth, AppStorageJSON) — v1.0
- ✓ Web unit tests (chat, leads, middleware, Paddle, checkout) — v1.0
- ✓ Playwright E2E tests (auth/project, chat flows) — v1.0

### Active

- [ ] Notifications & Activity Feed
- [ ] Document Management
- [ ] Team & Crew Management
- [ ] Reporting & Dashboards
- [ ] Enhanced AI (Angelic AI v2)
- [ ] Field Tools (photos, punch lists, daily logs)
- [ ] Client Portal / Sharing
- [ ] Calendar & Scheduling

### Out of Scope

- Breaking apart monolithic files (ContentView, RentalSearchView) — separate refactoring initiative
- Offline queue / local-first architecture — future project
- Real-time collaboration / conflict resolution — future project
- Load/performance testing — defer until after feature expansion
- OAuth login (Google, Apple) — deferred to v2.1+

## Current Milestone: v2.0 Feature Expansion

**Goal:** Add 8 major feature areas that transform ConstructionOS from a hardened shell into a full-featured construction management platform.

**Target features:**
- Notifications & Activity Feed
- Document Management
- Team & Crew Management
- Reporting & Dashboards
- Enhanced AI (Angelic AI v2)
- Field Tools (photos, punch lists, daily logs)
- Client Portal / Sharing
- Calendar & Scheduling

## Constraints

- **File structure**: Don't break apart monolithic files — fix bugs in place
- **Both platforms**: Fixes must cover both iOS Swift app and Next.js web app
- **Backward compatible**: Don't break existing features while fixing issues
- **Tests required**: Add tests for critical paths as we fix them
- **Supabase**: Use existing Supabase backend — don't migrate to different database

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fix bugs in place, don't refactor file structure | Avoid scope creep — monolith breakup is separate project | ✓ Good — kept scope focused |
| Implement Supabase Auth (not custom auth) | Already using Supabase, minimize new dependencies | ✓ Good — MFA, session management, middleware all work |
| Use Upstash Redis for rate limiting | Distributed, works across serverless instances | ✓ Good — dual-mode with in-memory fallback |
| Add tests alongside fixes | Catch regressions as we change error handling and state management | ✓ Good — 60+ tests across platforms |
| Keychain for iOS credentials | Platform-standard secure storage, pattern already exists in codebase | ✓ Good — automatic migration from UserDefaults |
| Sequential security chain (Keychain → Auth → RLS) | RLS without user_id backfill makes data invisible | ✓ Good — clean dependency ordering |
| AI SDK migration (raw fetch → streamText) | SDK already in package.json, provides streaming + error handling | ✓ Good — maxOutputTokens fixed, streaming works |
| 3-phase RLS migration (columns → backfill → policies) | Safe rollout with backfill before enabling enforcement | ✓ Good — all 23 tables secured |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-06 after v2.0 milestone start*
