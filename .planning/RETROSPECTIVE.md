# ConstructionOS — Retrospective

## Milestone: v1.0 — Production Hardening

**Shipped:** 2026-04-07
**Phases:** 12 | **Plans:** 36 | **Commits:** 177

### What Was Built

- Keychain credential storage with automatic UserDefaults migration
- Supabase Auth with email/password, MFA/TOTP, session management on both platforms
- Row-level security on all 23 Supabase tables with 3-phase migration
- Eliminated all force unwraps and fatalError calls from iOS codebase
- Comprehensive error handling (CrashReporter, AppStorageJSON, error boundaries)
- Web security hardening (CSRF, Zod validation, Paddle HMAC webhooks)
- Distributed rate limiting via Upstash Redis with middleware integration
- Pagination on all 6 data API routes with Load More UI
- Dynamic content (real user profiles, canonical prices, geolocation maps)
- Accessibility (182+ VoiceOver labels, aria-labels, form labels)
- SEO (metadata, sitemap, robots.txt, OpenGraph image)
- Test coverage: 18 iOS unit tests, 60 web tests (vitest + playwright)

### What Worked

- **Sequential security chain** (Keychain -> Auth -> RLS) — clean dependency ordering meant each phase built on the last without rework
- **Phase-per-concern** — separating iOS and web work into distinct phases avoided cross-platform merge conflicts
- **Verification reports** — VERIFICATION.md files caught real integration gaps (types.ts missing user_id, double rate limiting) that would have shipped as bugs
- **Milestone audit** — the 3-source cross-reference (VERIFICATION + SUMMARY + codebase) caught 8 partial requirements that all phase-level verifications missed

### What Was Inefficient

- **Worktree merges with untracked files** — many files were untracked on main, causing add/add conflicts during worktree merges. Stashing untracked files first resolved it but added manual steps
- **4 phases without VERIFICATION.md** — phases 1, 10, 11, 12 were never formally verified, requiring the audit to catch gaps retroactively
- **npm install not persisting across worktrees** — node_modules are local to each worktree, so `npm install` in a worktree didn't help the main tree. Had to re-run after merge
- **ignoreBuildErrors masking real errors** — 36 TS errors accumulated silently because `next.config.ts` had `ignoreBuildErrors: true`

### Patterns Established

- `AppStorageJSON` helper for persisting Swift arrays to UserDefaults with 1MB guard
- `verifyCsrfOrigin` utility shared across all mutating API routes
- `fetchTablePaginated` with `{ data, hasMore, total }` response shape
- `getAuthenticatedClient` pattern for auth + Supabase client in one call
- `updateOwnedRow` / `deleteOwnedRow` with mandatory user_id filter
- Error boundary convention: `error.tsx` in every route directory

### Key Lessons

- **Run `tsc --noEmit` as a gate, not just `next build`** — ignoreBuildErrors hides real issues
- **Verify cross-phase type contracts** — when one phase adds DB columns, another phase must update TypeScript types
- **Install dependencies before archiving** — package.json entries without `npm install` are invisible failures
- **Audit before completing** — the milestone audit caught integration gaps that individual phase verifications missed because they don't test cross-phase wiring

## Milestone: v2.0 — Portal & AI Expansion

**Shipped:** 2026-04-14
**Phases:** 3 (18, 20, 21) of originally scoped 10 | **Plans:** 20 | **Scope reduced after audit**

### What Was Built

- Enhanced AI with Claude tool calling: live Supabase project/contract data injection, RFI and change-order draft generation with human-review-before-save pattern
- iOS MCP tool server async upgrade: `MCPServer.swift` uses `try await supabase.fetch` for live data
- Client portal system: shareable read-only project URLs, per-section visibility, custom branding (logo + theme), photo timeline with lightbox/ZIP/PDF export
- Portal security: CSS sanitizer with 9 forbidden patterns + 30-property allowlist, SVG attack vector rejection, INSERT-only audit log RLS, soft-delete flags
- Portal management: web dashboard, templates, branded email, webhook delivery with ID-only payloads, IP blocking
- Live satellite & traffic maps: Mapbox (web) + MapKit (iOS) unified across all map features
- Equipment tracking: append-only `cs_equipment_locations` with DISTINCT ON latest-position view, typed marker shapes per equipment type
- iOS equipment check-in flow: GPS capture via CLLocationManager wrapper, MKDirections road routes with straight-line fallback
- Portal map integration: token-based API pattern, admin-locked overlay configuration via JSONB

### What Worked

- **Reducing scope at audit rather than shipping broken** — caught that 6/9 phases lacked VERIFICATION.md; better to ship 3 verified than 10 unverified
- **Human-review-before-save on AI drafts** — `_action: "review_before_saving"` pattern prevents hallucinated DB inserts; validated end-to-end for AI-03
- **Append-only + DISTINCT ON view** — Phase 21 equipment tracking gets efficient latest-position queries while preserving tamper-proof history
- **Service-role client for public SSR after token validation** — reused from shared reports, safe RLS bypass scoped to validated tokens
- **Design tokens as single-file export** — Phase 20's `design-tokens.ts` became source of truth reused across portal and management UI

### What Was Inefficient

- **18-plan phase (19 Reporting)** — planning density too high; no phase-level verification possible when each plan is small and SUMMARY-only
- **Phases 13–17 shipped without VERIFICATION.md** — pattern broke between milestones; need to reinstate "no SUMMARY without VERIFICATION" gate
- **Phase 22 added to roadmap without a plan** — roadmap drift; phases should be marked TBD rather than counted toward milestone progress
- **REQUIREMENTS.md drift on MAP-01..04** — Phase 21 added requirement IDs in plan frontmatters but never updated the traceability table; caught only by audit
- **Quick-task 260414-n4w hours before milestone close** — INT-03/04/05 had been known for days; surfacing earlier would have avoided the rush

### Patterns Established

- AI tool drafts return structured payloads with `_action: "review_before_saving"` — no direct DB insert from LLM tool calls
- `formatDraftIfPresent()` pattern for iOS chat: JSON detection → gold-themed type-badge card rendering
- Portal audit log: INSERT-only RLS, no UPDATE/DELETE policies, immutable by design
- Portal token-based API: `/api/portal/*?token=X` pattern; slug lookup only in server page component
- `DEFAULT_MAP_OVERLAYS` applied at read time for JSONB backward compatibility with pre-feature rows
- Design tokens as flat single-file export consumed via inline styles

### Key Lessons

- **Milestone audit must happen BEFORE marking phases complete**, not after — six phases sat in "Complete" status for a week with no verification
- **Verification-or-nothing gate belongs in phase workflow**: without VERIFICATION.md, the phase should not be marked done
- **"Complete" in ROADMAP.md currently means "last plan merged"; it should mean "phase goal verified"** — semantic drift caused the v2.0 scope surprise
- **Quick-tasks as audit-response are valuable but late** — 260414-n4w closed 3 blockers but the audit ran 8 hours before milestone close; shift left
- **Don't add phases to a roadmap without at least a goal** — Phase 22 appeared mid-milestone without any plan, inflating completion percentage

### Cost Observations

- Sessions: multi-session execution across phases 18, 20, 21
- Notable: Phase 19 (Reporting, 18 plans) consumed more budget than 18 + 20 + 21 combined but was cut from shipped scope — over-specification risk

## Cross-Milestone Trends

| Metric | v1.0 | v2.0 |
|--------|------|------|
| Phases (planned / shipped) | 12 / 12 | 10 / 3 |
| Plans | 36 | 20 (63 planned) |
| Timeline | 14 days | 3 days (18, 20, 21 only) |
| Requirements (in-scope / shipped) | 131 / 131 | 39 / 12 |
| Satisfaction | 131/131 (100%) | 12/39 (31%) |
| TS Errors at Audit | 36 -> 0 | 17 pre-existing (deferred) |
| Verified phases | 12/12 | 3/9 |
| Milestone scope survived audit | yes | no (reduced) |
