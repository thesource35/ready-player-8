# ConstructionOS — Production Hardening

## What This Is

A comprehensive fix-up of the existing ConstructionOS multi-platform app (iOS/macOS/visionOS SwiftUI + Next.js web). The app is feature-complete but has accumulated technical debt: silent error handling, insecure credential storage, volatile state that resets on launch, no authentication, and zero test coverage. This project makes the codebase production-ready.

## Core Value

Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## Requirements

### Validated

- ✓ Projects CRUD with Supabase sync — existing
- ✓ Contracts/bid pipeline management — existing
- ✓ Market intelligence dashboard — existing
- ✓ Angelic AI chat (Claude API) — existing
- ✓ Wealth Suite (5 tabs: MoneyLens, Psychology, PowerThinking, Leverage, Opportunity) — existing
- ✓ Rental search and equipment management — existing
- ✓ Operations views (commercial, core) — existing
- ✓ Integration Hub for backend configuration — existing
- ✓ Web platform with 30+ route pages — existing
- ✓ Theme system and premium UI — existing
- ✓ CarPlay support — existing

### Active

- [ ] Move all API keys and credentials from UserDefaults to Keychain (iOS) and env vars (web)
- [ ] Enable Supabase Row-Level Security on all tables
- [ ] Implement Supabase Auth with session tokens (iOS + web)
- [ ] Replace all empty catch blocks with proper error logging and user-facing alerts
- [ ] Replace silent `try?` calls with `do-catch` blocks that surface failures
- [ ] Persist all @State arrays using AppStorage/JSON pattern (projects, contracts, messages, wealth data)
- [ ] Replace in-memory rate limiter with distributed solution (Upstash Redis)
- [ ] Fix chat API fallback to distinguish "API unavailable" vs "temporary error"
- [ ] Add email validation on lead capture endpoint
- [ ] Add CSRF protection on form endpoints
- [ ] Add pagination to Supabase queries (web)
- [ ] Reduce chat system prompt payload size
- [ ] Fix ProjectsView/ContractsView stale data when filtering
- [ ] Fix AngelicAI session isolation (server-side validation)
- [ ] Add error boundaries and loading states to web pages
- [ ] Write unit tests for core services (SupabaseService, chat route, auth flows)
- [ ] Write integration tests for Supabase CRUD operations
- [ ] Write E2E tests for chat flow (web)

### Out of Scope

- Breaking apart monolithic files (ContentView, RentalSearchView) — separate refactoring initiative
- Offline queue / local-first architecture — future project
- Real-time collaboration / conflict resolution — future project
- Webhook integrations to external systems — future project
- Load/performance testing — defer until after hardening
- Mobile app redesign or new features — this is a fix-up only

## Context

- iOS app is a brownfield SwiftUI project targeting iOS 26.2+, macOS 15.6+, visionOS
- Web app is Next.js 16.2.2 with React 19, TypeScript, Tailwind CSS
- Both platforms share a Supabase backend (PostgreSQL + REST API)
- AI features use Anthropic Claude API (claude-haiku-4-5-20251001)
- The app has been through several feature-building sprints but no hardening pass
- ContentView.swift is 12,500+ lines (monolithic) — we're fixing bugs inside it, not restructuring
- CONCERNS.md documents 299 lines of specific issues with file paths and line numbers
- Codebase map available in `.planning/codebase/` (7 documents)

## Constraints

- **File structure**: Don't break apart monolithic files — fix bugs in place
- **Both platforms**: Fixes must cover both iOS Swift app and Next.js web app
- **Backward compatible**: Don't break existing features while fixing issues
- **Tests required**: Add tests for critical paths as we fix them
- **Supabase**: Use existing Supabase backend — don't migrate to different database

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Fix bugs in place, don't refactor file structure | Avoid scope creep — monolith breakup is separate project | — Pending |
| Implement Supabase Auth (not custom auth) | Already using Supabase, minimize new dependencies | — Pending |
| Use Upstash Redis for rate limiting | Distributed, works across serverless instances | — Pending |
| Add tests alongside fixes | Catch regressions as we change error handling and state management | — Pending |
| Keychain for iOS credentials | Platform-standard secure storage, pattern already exists in codebase | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-04 after initialization*
