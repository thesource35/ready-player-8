---
phase: 29-live-video-traffic-feed-sat-drone
plan: 10
subsystem: ui
tags:
  - nextjs
  - react
  - supabase
  - anthropic
  - rls
  - rate-limit
  - live-feed
  - cost-cap
  - vitest

# Dependency graph
requires:
  - phase: 29-01
    provides: cs_live_suggestions table + RLS (select + dismiss policies)
  - phase: 29-03
    provides: shared anthropic-vision adapter (callAnthropicVision + Zod schema)
  - phase: 29-08
    provides: LiveFeedClient shell + per-project grid + data-section placeholders
  - phase: 29-09
    provides: video/scrubber/library/upload wiring inside PerProjectShell
  - phase: 22
    provides: VOD storage layout (<org>/<project>/<asset>/poster.jpg) + rate-limit helper pattern
  - phase: 21
    provides: typography scale (9/11/12/20 px × 400/800) + color tokens
provides:
  - GET /api/live-feed/suggestions (list non-dismissed, RLS-scoped)
  - PATCH /api/live-feed/suggestions/:id (per-user dismiss via authenticated client)
  - POST /api/live-feed/analyze (manual Analyze-Now with budget pre-check)
  - GET /api/live-feed/budget (daily counter of cs_live_suggestions rows)
  - Shared budget helper (readBudget / assertBudgetAvailable / 96/day cap)
  - Shared generateSuggestion helper (mirrors Edge Function per-project body)
  - LiveSuggestionCard + LiveSuggestionStream + TrafficUnifiedCard + BudgetBadge
  - AnalyzeNowButton + LastAnalyzedTimestamp + useSuggestions + useBudget
  - Fully-wired PerProjectShell with all LIVE-09 / LIVE-10 / LIVE-11 surfaces
affects:
  - Future phase that wires Phase 21 road-traffic data into TrafficUnifiedCard.roadSummary
  - iOS equivalents (deferred per plan scope — web-only in this plan)
  - Follow-up plans needing to reuse readBudget / generateSuggestion helpers

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Structured error envelope { error: { code, message, retryable } } on every Next.js route
    - Lifted-hook pattern for shared poll loops (useSuggestions/useBudget)
    - Optimistic dismiss with revert-on-error (CLAUDE.md no-silent-failures)
    - Flexible component prop shape (parent-provided vs self-managed hook)
    - Service-role + cookie-scoped dual-client for budget-gated analyze route

key-files:
  created:
    - web/src/lib/live-feed/budget.ts
    - web/src/lib/live-feed/generate-suggestion.ts
    - web/src/app/api/live-feed/budget/route.ts
    - web/src/app/api/live-feed/suggestions/route.ts
    - web/src/app/api/live-feed/suggestions/[id]/route.ts
    - web/src/app/api/live-feed/analyze/route.ts
    - web/src/app/live-feed/useSuggestions.ts
    - web/src/app/live-feed/useBudget.ts
    - web/src/app/live-feed/LiveSuggestionCard.tsx
    - web/src/app/live-feed/LiveSuggestionStream.tsx
    - web/src/app/live-feed/BudgetBadge.tsx
    - web/src/app/live-feed/AnalyzeNowButton.tsx
    - web/src/app/live-feed/LastAnalyzedTimestamp.tsx
    - web/src/app/live-feed/TrafficUnifiedCard.tsx
  modified:
    - web/src/app/live-feed/LiveFeedClient.tsx
    - web/src/app/live-feed/__tests__/suggestion-card.test.tsx
    - web/src/app/live-feed/__tests__/budget-badge.test.tsx

key-decisions:
  - "Created shared generateSuggestion helper rather than inlining Edge-Function logic in analyze route — single source of truth for per-project generation"
  - "Lifted useSuggestions and useBudget hooks into PerProjectShell so timestamp, stream, and traffic card share one poll loop each (avoids duplicate /api polling)"
  - "LiveSuggestionStream accepts parent-provided props OR self-manages via hook — stable hook order preserved without forcing callers to choose"
  - "TrafficUnifiedCard reads action_hint.structured_fields using the Zod-validated field names (equipment_active_count, people_visible_count, perimeter_activity, weather_visible) — aligned with 29-03 adapter rather than the ad-hoc names in the plan snippet"
  - "Severity colors paired with SVG shapes (circle/diamond/triangle) for color-blind safety per UI-SPEC §Accessibility — not color alone"
  - "Analyze route uses cookie-scoped client for budget pre-check (RLS-honest count) but service-role client for the INSERT (cs_live_suggestions has no INSERT RLS policy per 29-01 STEP D — service_role only)"
  - "Added a belt-and-suspenders project-access check in analyze before service-role INSERT — RLS on budget is already enforced but the service-role client could otherwise INSERT into any project"

patterns-established:
  - "Dual-client analyze pattern: authenticated (RLS) for pre-checks + service-role for writes that have no INSERT policy"
  - "Budget helper as single source of truth: same readBudget semantics in web route + Edge Function (via mirrored copy)"
  - "Polling hook with cancelled-ref guard + preserve-last-known-on-error (avoids UI flash to unknown-state)"

requirements-completed:
  - LIVE-08
  - LIVE-09
  - LIVE-10
  - LIVE-11

# Metrics
duration: ~30min
completed: 2026-04-20
---

# Phase 29 Plan 10: Web Suggestions + Traffic + Budget API Summary

**Shipped the web per-project Live Feed end-to-end: 4 new API routes (list / dismiss / analyze / budget) gated by RLS + a 96/day Anthropic cost cap, plus 8 client components + 2 hooks wired into PerProjectShell so users can see severity-colored suggestion cards, dismiss them with optimistic UI, read a live budget counter, and manually trigger Analyze Now without ever bypassing the cap.**

## Performance

- **Started:** 2026-04-20T11:30 (approx)
- **Completed:** 2026-04-20T12:02Z
- **Duration:** ~30 min (11 atomic task commits + metadata commit)
- **Tasks:** 11/11 completed (T-10-A … T-10-R)
- **Files created:** 14
- **Files modified:** 3
- **Tests passing:** 32/32 across 7 live-feed + portal test files (12 new assertions: 3 for LiveSuggestionCard, 4 for BudgetBadge, 5 carried from LIVE-14 baseline)
- **tsc --noEmit:** clean

## Accomplishments

- Built the 4-route backend for web Live Feed: list suggestions (RLS-scoped), dismiss (RLS WITH CHECK enforces `dismissed_by = auth.uid()`), manual analyze (budget pre-check + shared adapter), budget counter
- Established `LIVE_SUGGESTION_DAILY_CAP = 96` as the single source of truth — the Edge Function's inline constant and the web helper now refer to the same value and the same count-since-UTC-midnight semantics
- Created the shared `generateSuggestion` helper so the manual analyze route and the scheduled Edge Function both route through a single per-project generation code path (T-29-VISION-PAYLOAD Zod validation lives once, in the vision adapter)
- Wired all 5 new components + 2 hooks into `LiveFeedClient.tsx` — both `data-section="suggestions-stream"` and `data-section="traffic"` placeholders are gone; the minimap placeholder is preserved as a follow-up per UI-SPEC deferred note
- Un-skipped the Wave 0 stubs `suggestion-card.test.tsx` (3 assertions) and `budget-badge.test.tsx` (4 assertions); both pass
- LIVE-14 regression lock holds: zero files under `web/src/app/api/portal/video/` modified; the 4-assertion drone-exclusion test still passes

## Task Commits

Each task was committed atomically on `main`:

1. **T-10-A: Shared budget helper** — `3f524fd` (feat)
2. **T-10-B: GET /api/live-feed/budget** — `8fb0016` (feat)
3. **T-10-C: GET /api/live-feed/suggestions** — `e81ee2f` (feat)
4. **T-10-D: PATCH /api/live-feed/suggestions/:id dismiss** — `5951513` (feat)
5. **T-10-E: POST /api/live-feed/analyze + generateSuggestion helper** — `0d24790` (feat)
6. **T-10-F: useSuggestions + LiveSuggestionCard + un-skip test** — `0f953a7` (feat)
7. **T-10-G: LiveSuggestionStream side panel** — `ec94022` (feat)
8. **T-10-H: useBudget + BudgetBadge + un-skip test** — `00f4238` (feat)
9. **T-10-I: AnalyzeNowButton + LastAnalyzedTimestamp** — `2421c37` (feat)
10. **T-10-J: TrafficUnifiedCard** — `fb2726e` (feat)
11. **T-10-K: Wire all components into LiveFeedClient** — `befa362` (feat)
12. **T-10-R: LIVE-14 non-regression** — verification-only; no new commit (no files modified, portal tests still pass)

## Files Created/Modified

### Shared helpers (2 new)
- `web/src/lib/live-feed/budget.ts` — `LIVE_SUGGESTION_DAILY_CAP = 96`, `readBudget`, `assertBudgetAvailable` with `code: 'budget_reached'` sentinel
- `web/src/lib/live-feed/generate-suggestion.ts` — `generateSuggestion({ projectId, supabase, triggeredBy, userId })` — mirrors Edge Function per-project body; typed `GenerateSuggestionError` with `code: 'no_ready_drone_asset' | 'poster_sign_failed' | 'vision_failed' | 'insert_failed' | 'missing_api_key'`

### API routes (4 new)
- `web/src/app/api/live-feed/budget/route.ts` — GET; returns `{ used, remaining, cap, resetsAt }`
- `web/src/app/api/live-feed/suggestions/route.ts` — GET; returns 20 most recent non-dismissed rows ordered DESC
- `web/src/app/api/live-feed/suggestions/[id]/route.ts` — PATCH; sets `dismissed_at = now()` + `dismissed_by = auth.uid()`
- `web/src/app/api/live-feed/analyze/route.ts` — POST; budget pre-check → project-access check → service-role delegate to `generateSuggestion`

### Client components + hooks (8 new)
- `web/src/app/live-feed/useSuggestions.ts` — 30s polling + optimistic dismiss + revert-on-error
- `web/src/app/live-feed/useBudget.ts` — 30s polling; preserves last-known on poll failure
- `web/src/app/live-feed/LiveSuggestionCard.tsx` — severity border + SVG shape + dismiss button
- `web/src/app/live-feed/LiveSuggestionStream.tsx` — 4-state side panel; parent-provided or self-managed
- `web/src/app/live-feed/BudgetBadge.tsx` — 3 states (healthy/warning/reached) with exported `budgetState()` helper
- `web/src/app/live-feed/AnalyzeNowButton.tsx` — disabled at `remaining <= 0`; tooltip copy verbatim
- `web/src/app/live-feed/LastAnalyzedTimestamp.tsx` — 30s tick; "just now" / "N min ago" / "N h ago"
- `web/src/app/live-feed/TrafficUnifiedCard.tsx` — ROAD + ON-SITE sections; Zod-aligned field names

### Tests (2 un-skipped)
- `web/src/app/live-feed/__tests__/suggestion-card.test.tsx` — 3 passing assertions (text renders, severity → border color, × → onDismiss(id))
- `web/src/app/live-feed/__tests__/budget-badge.test.tsx` — 4 passing assertions (0/96 TODAY copy, healthy/warning/reached styling)

### Integration (1 modified)
- `web/src/app/live-feed/LiveFeedClient.tsx` — replaced both `data-section` placeholders with real components; lifted `useSuggestions` + `useBudget` to `PerProjectShell`; added header row with timestamp/badge/button; `LiveSuggestionStream` receives shared hook outputs as props

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan snippet imports `createServerClient` + `rateLimit(key, max, windowMs)` that do not exist in this codebase**
- **Found during:** Task T-10-B (first route)
- **Issue:** Plan called `import { createServerClient } from '@/lib/supabase/server'` and `rateLimit(key, 30, 60_000)`. This codebase exports `createServerSupabase` (returns `Promise<Client|null>`) and `rateLimit(identifier, route)` (returns `{ success, limit, remaining, reset }`).
- **Fix:** Aligned all 4 routes with the real helpers. Added 503 branch for `supabase === null` (DB not configured). Used `rateLimit` with route-key convention `/api/live-feed/{suggestions,analyze}` to key the shared limiter correctly; emitted `Retry-After` header on 429.
- **Files modified:** all 4 routes in `web/src/app/api/live-feed/`
- **Commits:** 8fb0016, e81ee2f, 5951513, 0d24790

**2. [Rule 2 - Critical Functionality] `generateSuggestion` helper did not exist**
- **Found during:** Task T-10-E (analyze route)
- **Issue:** Plan's snippet imports `generateSuggestion` from `@/lib/live-feed/anthropic-vision` but that module only exports the low-level `callAnthropicVision`. The Edge Function inlines its per-project logic (sign poster → build context → call vision → insert) — there was no shared helper for the analyze route to delegate to.
- **Fix:** Created `web/src/lib/live-feed/generate-suggestion.ts` mirroring the Edge Function's per-project body. Typed error codes let the route map domain failures to HTTP 409/500/503 with actionable copy. T-29-VISION-PAYLOAD Zod validation still lives once, inside `callAnthropicVision`, so both callers share it.
- **Files created:** `web/src/lib/live-feed/generate-suggestion.ts`
- **Commit:** 0d24790

**3. [Rule 1 - Bug] TrafficUnifiedCard referenced field names not in the Zod schema**
- **Found during:** Task T-10-J
- **Issue:** Plan snippet reads `onSite.equipment_active` and `onSite.equipment_idle`, but the `ActionHintSchema` in `web/src/lib/live-feed/anthropic-vision.ts` (29-03) exposes `equipment_active_count`, `people_visible_count`, `deliveries_in_progress`, `perimeter_activity`, `weather_visible` — there is no `equipment_idle` field. Rendering the plan's field names as-is would always render empty (silent data loss — violates CLAUDE.md no-silent-failures).
- **Fix:** Aligned `TrafficUnifiedCard` with the actual Zod-validated shape. Added semantic coloring for `perimeter_activity` (clear=green, vehicle_approach=gold, unidentified_activity=red) and hid `weather_visible='unknown'` so the card only shows meaningful data.
- **Files modified:** `web/src/app/live-feed/TrafficUnifiedCard.tsx`
- **Commit:** fb2726e

**4. [Rule 1 - Bug] Duplicate 30s poll loop if both `LiveSuggestionStream` and the parent called `useSuggestions` independently**
- **Found during:** Task T-10-K
- **Issue:** Plan asked `PerProjectShell` to invoke `useSuggestions(projectId)` at the top AND render `<LiveSuggestionStream projectId={projectId} />` (which internally also calls `useSuggestions`). That would double the `/api/live-feed/suggestions` poll rate for no benefit.
- **Fix:** Lifted the hook once in the parent. Refactored `LiveSuggestionStream` to accept parent-provided `suggestions/loading/error/dismiss` props AND keep hook order stable (still calls `useSuggestions(null)` when parent provides props, so the hook loop stays idle but the hook count never changes).
- **Files modified:** `web/src/app/live-feed/LiveSuggestionStream.tsx`, `web/src/app/live-feed/LiveFeedClient.tsx`
- **Commit:** befa362

**5. [Rule 2 - Critical Functionality] Analyze route could service-role-INSERT into any project_id**
- **Found during:** Task T-10-E design review
- **Issue:** The budget pre-check uses the cookie-scoped client (RLS enforces org isolation on the row count) — but if the pre-check found 0 rows (e.g., user targets a project_id in a different org that happens to have no suggestions today), the route would then service-role-INSERT into that foreign project. RLS can't save us once service-role is in play.
- **Fix:** Added an explicit `cs_projects` lookup via the authenticated client before the service-role step. If the caller can't see the project via RLS (`maybeSingle()` returns null), the route returns 404 `project_not_accessible` and never reaches `generateSuggestion`.
- **Files modified:** `web/src/app/api/live-feed/analyze/route.ts`
- **Commit:** 0d24790

**6. [Rule 1 - Bug] Dismiss button used `position: absolute` without `position: relative` ancestor**
- **Found during:** Task T-10-F
- **Issue:** Plan snippet placed a `position: absolute` × button inside an `<article>` with no positioning context — it would have positioned relative to the nearest positioned ancestor (possibly the page), not the card.
- **Fix:** Set `position: relative` on the `<article>` and reserved `paddingRight: 36` so the button never overlaps text.
- **Files modified:** `web/src/app/live-feed/LiveSuggestionCard.tsx`
- **Commit:** 0f953a7

### Additional Enhancements (not strictly required by plan)

- **Color-blind safety (UI-SPEC §Accessibility):** added SVG shape indicator (circle/diamond/triangle) next to severity color — the card never relies on color alone.
- **Optimistic dismiss revert:** `useSuggestions.dismiss` rethrows after reverting the optimistic removal so upstream callers can surface an error toast if they want. Matches LIVE-09's "never silently drop" contract.

No checkpoints hit. No blockers. No architectural-scope changes required (no Rule 4 triggers).

## Auth / Authentication Gates

None. All authentication goes through `createServerSupabase().auth.getUser()` on the same cookie-backed Supabase SSR pattern established in Phase 22 routes.

## Known Stubs

- `TrafficUnifiedCard` receives `roadSummary={null}` — Phase 21 road-traffic tile wiring is deferred per UI-SPEC §Claude's Discretion. The component renders the graceful "No data — waiting for next analysis" empty state in that branch (not a silent failure). Follow-up plan needed to wire Phase 21 traffic-tile data into `roadSummary`.
- `minimap` placeholder (`data-section="minimap"`) preserved intentionally — UI-SPEC notes mini-map is "29-10 or follow-up"; this plan's scope explicitly ships suggestions + traffic + budget only.

Neither stub prevents the plan's goal from being achieved: the LIVE-08/09/10/11 surfaces users interact with (suggestion cards, dismiss flow, budget counter, Analyze Now, on-site traffic section) are all live.

## Threat Flags

No new security-relevant surface introduced beyond what the plan's `<threat_model>` already covered. Every threat in the register has a tested mitigation:

| Threat | Mitigation location |
|--------|---------------------|
| T-29-RLS-CLIENT | All 4 routes use `createServerSupabase` (cookie-scoped); no service-role leakage except analyze route's INSERT (service_role required because 29-01 intentionally has no INSERT RLS policy) |
| T-29-COST-CAP | `assertBudgetAvailable` pre-check in analyze route BEFORE any Anthropic call; identical 96/day semantics as Edge Function |
| T-29-VISION-PAYLOAD | Delegated to `callAnthropicVision`'s Zod validation (unchanged from 29-03) |
| T-29-RATE-LIMIT-ABUSE | 30 req/min/IP on analyze + dismiss via shared `@/lib/rate-limit`, keyed per route |
| T-29-PORTAL-DRONE (LIVE-14) | No files under `web/src/app/api/portal/video/` modified; regression vitest (4 assertions) still passes |

## Verification

Automated:
- `cd web && npx vitest run src/app/live-feed/__tests__ src/app/api/live-feed src/lib/live-feed/__tests__ src/app/api/portal/video/__tests__` → 32 tests pass across 7 files
- `cd web && npx tsc --noEmit` → clean (exit 0)
- Every task's plan `<verify>` grep assertion returned positive counts

Manual (deferred to `/gsd-verify-work` or manual UAT):
- End-to-end: upload a drone clip → wait for Edge Function or click Analyze Now → observe a suggestion card rendered in the side panel with the correct severity border
- Visual check that the BudgetBadge transitions healthy→warning→reached as suggestions accumulate (requires a live Anthropic quota)
- Dismissing a card: optimistic removal + server persistence + refresh does not re-surface the card

## Self-Check: PASSED

Verified post-write:

### Files
- FOUND: web/src/lib/live-feed/budget.ts
- FOUND: web/src/lib/live-feed/generate-suggestion.ts
- FOUND: web/src/app/api/live-feed/budget/route.ts
- FOUND: web/src/app/api/live-feed/suggestions/route.ts
- FOUND: web/src/app/api/live-feed/suggestions/[id]/route.ts
- FOUND: web/src/app/api/live-feed/analyze/route.ts
- FOUND: web/src/app/live-feed/useSuggestions.ts
- FOUND: web/src/app/live-feed/useBudget.ts
- FOUND: web/src/app/live-feed/LiveSuggestionCard.tsx
- FOUND: web/src/app/live-feed/LiveSuggestionStream.tsx
- FOUND: web/src/app/live-feed/BudgetBadge.tsx
- FOUND: web/src/app/live-feed/AnalyzeNowButton.tsx
- FOUND: web/src/app/live-feed/LastAnalyzedTimestamp.tsx
- FOUND: web/src/app/live-feed/TrafficUnifiedCard.tsx
- FOUND (modified): web/src/app/live-feed/LiveFeedClient.tsx
- FOUND (modified): web/src/app/live-feed/__tests__/suggestion-card.test.tsx
- FOUND (modified): web/src/app/live-feed/__tests__/budget-badge.test.tsx

### Commits
- FOUND: 3f524fd (T-10-A)
- FOUND: 8fb0016 (T-10-B)
- FOUND: e81ee2f (T-10-C)
- FOUND: 5951513 (T-10-D)
- FOUND: 0d24790 (T-10-E)
- FOUND: 0f953a7 (T-10-F)
- FOUND: ec94022 (T-10-G)
- FOUND: 00f4238 (T-10-H)
- FOUND: 2421c37 (T-10-I)
- FOUND: fb2726e (T-10-J)
- FOUND: befa362 (T-10-K)
