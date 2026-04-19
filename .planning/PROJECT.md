# ConstructionOS — Production Hardening

## What This Is

A production-hardened multi-platform construction management app (iOS/macOS/visionOS SwiftUI + Next.js web). Shipped v1.0 hardening milestone: secure credential storage, real authentication with MFA, row-level security on all 23 Supabase tables, crash-safe iOS code, comprehensive error handling, web security hardening, accessibility, SEO, and test coverage across both platforms.

## Core Value

Every user action must either succeed visibly or fail with a clear, actionable message — no silent data loss, no undetected errors, no security gaps.

## Current State

**Shipped:** v2.0 Portal & AI Expansion (2026-04-14) — reduced scope after audit (see `milestones/v2.0-MILESTONE-AUDIT.md`)
**Previous milestones:** v1.0 Production Hardening (2026-04-06)
**Tech stack:** SwiftUI (iOS 18.2+), Next.js 16.2.2, React 19, Supabase, Anthropic Claude API, Mapbox GL JS, MapKit
**Current focus:** v2.1 Gap Closure — INT-01 + INT-07 closed (Phases 26, 27); verification backfill for Phases 13–19 shipped (Phase 28, status=partial — 22 UAT items deferred to follow-up session; NOTIF-01/03/05 cluster scheduled for Phase 30 remediation)

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
- ✓ Enhanced AI with Claude tool calling (RFI/CO drafts, live Supabase data) — v2.0
- ✓ Client Portal with branding, photo timeline, PDF export, soft-delete audit log — v2.0
- ✓ Live Satellite & Traffic Maps (Mapbox/MapKit unified, equipment tracking, GPS photos) — v2.0
- ✓ Document RLS reconciliation — 5 stub entity tables + rebuilt RLS for all 7 entity types + trigger whitelist extension + API preflight validation + UI picker filter — v2.1 (Phase 26)
- ✓ Portal → Map navigation link (INT-07) — server-gated `showMapLink`, PortalHeader Map/Overview anchors, MobilePortalNav 6th MapPin icon, branded /map page with analytics + shared rate limit + 60s revalidate — v2.1 (Phase 27)

### Active (v2.1)

- [ ] Notifications & Activity Feed — code written, verification pending (Phases 24, 25, 28)
- [ ] Document Management — RLS reconciled 2026-04-19 (Phase 26); activity emission + verification pending (Phases 24, 28)
- [ ] Team & Crew Management — iOS wired 2026-04-14, cert notifications pending (Phase 25)
- [ ] Reporting & Dashboards — code written (18 plans), verification pending (Phase 28)
- [ ] Field Tools (photos, punch lists, daily logs) — code written, verification pending (Phase 28)
- [ ] Calendar & Scheduling — code written, AgendaListView wired 2026-04-14, verification pending (Phase 28)
- [ ] Live Site Video (Phase 22) — never planned

### Out of Scope

- Breaking apart monolithic files (ContentView, RentalSearchView) — separate refactoring initiative
- Offline queue / local-first architecture — future project
- Real-time collaboration / conflict resolution — future project
- Load/performance testing — defer until after feature expansion
- OAuth login (Google, Apple) — deferred to v2.1+

## Current Milestone: v2.1 Gap Closure & Feature Completion

**Goal:** Close v2.0 carryover: add missing VERIFICATION.md for phases 13–19, resolve 4 integration blockers (INT-01, INT-02, INT-06, INT-07), and plan Phase 22 (Live Site Video).

**Target work:**
- Phase 23: iOS Navigation & Assignment Wiring (code closed by quick task 260414-n4w; phase formalizes verification)
- Phase 24: Document → Activity Event Emission (INT-02)
- Phase 25: Certification Expiry Notifications (INT-06)
- Phase 26: Documents RLS Table Reconciliation (INT-01)
- Phase 27: Portal → Map Navigation Link (INT-07)
- Phase 28: Retroactive Verification Sweep (Phases 13–19)
- Phase 22: Live Site Video — requires planning

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
| AI tool calls return structured drafts, no direct DB insert (Phase 18) | User always approves before persistence — safety rail for hallucinated content | ✓ Good — `_action: "review_before_saving"` pattern adopted across RFI and CO tools |
| Service-role Supabase client for public portal SSR (Phase 20) | Anonymous viewers can't authenticate but still need gated data access after token/slug validation | ✓ Good — same pattern as shared reports, RLS bypass is scoped |
| INSERT-only RLS on portal audit log (Phase 20) | Immutable audit trail required for compliance | ✓ Good — no UPDATE/DELETE policies defined |
| Soft-delete via flags for portal links (Phase 20) | Preserve audit history and allow undo | ✓ Good — hard deletes avoided in this domain |
| Append-only cs_equipment_locations with no UPDATE/DELETE RLS (Phase 21) | Tamper-proof location history for equipment tracking | ✓ Good — DISTINCT ON view gives efficient latest-position query |
| Design tokens as single-file export (Phase 20) | Source of truth for portal and app styling | ✓ Good — `web/src/lib/design-tokens.ts` used across portal and management UI |
| Ship reduced v2.0 scope (3 phases) after audit failure | Honest milestone — avoid shipping with 27 unverified requirements | ⚠ Revisit — verify whether v2.0 users perceive portal/AI/maps as a coherent shipment without the feature phases they visually depend on |
| Return HTTP 404 + `validationFailed` on missing entity instead of RLS 403 (Phase 26) | 403 silently mapped to "permission denied" toasts hiding the real cause (empty table) — defense-in-depth preflight produces actionable error naming the missing entity | ✓ Good — web `/api/documents/attach` + iOS `DocumentSyncManager.preflightEntityExists` surface `"<entity_type> not found"` before any DB write or storage upload |
| Hide entity_types with empty backing tables from picker UIs (Phase 26) | Stub tables exist for RLS parity but have no feature UI yet; showing them in pickers would create orphan-attach dead-ends | ✓ Good — `nonEmptyEntityTypes()` helper on web + iOS queries HEAD counts via `withTaskGroup`, prop unions widened to full 7-value `DocumentEntityType` |
| Bump Phase 26 migration timestamps after Phase 25 collision (Phase 26) | Supabase CLI identifies migrations by prefix; two phases picking `20260418001` caused silent-skip. Rename preserves SQL bodies via `git mv` | ✓ Good — Phase 26 migrations renumbered to `20260418002/003/004`, applied cleanly on remote |

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
*Last updated: 2026-04-19 after Phase 28 (Retroactive Verification Sweep) — 6 backfilled VERIFICATION.md files shipped; status=partial pending UAT walkthrough; Phase 30 NOTIF remediation queued*
