---
phase: 30-notifications-list-mark-read-ios-push-remediation
plan: 08
subsystem: testing
tags: [notifications, deno, apns, push, edge-function, regression, defense-in-depth, d-21, d-22, notif-05]

# Dependency graph
requires:
  - phase: 14-notifications-activity-feed
    provides: notifications-fanout Edge Function (index.ts + apns.ts + existing 6 Deno tests + existing 4 apns tests), APNsRegistrationTests.swift (14-05)
  - phase: 28-retroactive-verification-sweep
    provides: NOTIF-05 Unsatisfied verdict that scoped this remediation into Phase 30
  - phase: 30-01-notifications-list-mark-read-ios-push-remediation
    provides: Phase 30 test harness precedent (vi.hoisted for mock refs; compile-only verification where relevant)

provides:
  - D-21 a regression lock on PUSH_CATEGORIES allowlist (push-categories.test.ts — 9 tests)
  - D-21 b regression lock on cs_device_tokens query shape + error tolerance + zero-recipient short-circuit (device-token-lookup.test.ts — 3 tests)
  - D-21 c regression lock on APNs payload shape — aps.alert/badge/sound/thread-id + top-level event_id/project_id/category (apns-payload-shape.test.ts — 3 tests)
  - D-21 d regression lock on BadDeviceToken/Unregistered/410 stale-token pruning + redaction invariant (bad-device-token.test.ts — 3 tests)
  - D-22 audit evidence: APNsRegistrationTests.swift unchanged since Phase 14-05 (SHA-1 + last-commit timestamp recorded)
  - Full notifications-fanout Deno suite GREEN at 28/0 (6 existing + 4 existing apns + 18 new) — exceeds ≥21 acceptance floor by 7

affects:
  - Phase 30-09 real-device UAT — CI-bound regression floor means real-device test is a confirmation step, not a debugging session
  - Any future PR that adds a 4th push category — `PUSH_CATEGORIES.size === 3` + strict-exclusion list fails CI unless the tests are intentionally updated alongside the production change
  - Any future PR that logs raw device_token in an error path — redaction invariant in bad-device-token.test.ts fails CI
  - Any future refactor of the cs_device_tokens query shape — device-token-lookup.test.ts fails CI unless the `in('user_id', recipients) + eq('platform', 'ios')` contract is preserved

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Deno test co-location with Edge Function source; one file per D-21 axis keeps test-failure blast radius small"
    - "Inline PostgREST stub pattern (makeSupabaseStub / makeTrackedSupabaseStub) mirrors index.test.ts helpers — Deno does not hoist across files, so each test file re-declares its stub"
    - "Redaction invariant test pattern: capture console.warn/error via reassignment, assert `logs.every(!includes(token))` across all failure modes"
    - "Strict-allowlist regression pattern: assert both `set.size === N` AND explicit inclusion + exclusion — catches both additions and typos"
    - "D-22 audit-only task pattern: shasum + git log + git diff evidence recorded in SUMMARY, zero code touched"

key-files:
  created:
    - supabase/functions/notifications-fanout/push-categories.test.ts
    - supabase/functions/notifications-fanout/device-token-lookup.test.ts
    - supabase/functions/notifications-fanout/apns-payload-shape.test.ts
    - supabase/functions/notifications-fanout/bad-device-token.test.ts
    - .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-08-SUMMARY.md
  modified: []

key-decisions:
  - "Four separate test files (one per D-21 axis) instead of appending to index.test.ts — matches plan intent (\"keeps test-failure blast radius small\") and makes CI logs self-describing when a specific axis regresses"
  - "Inline stub helpers in each file rather than extracting shared fixtures — Deno does not hoist across files without explicit exports, and index.test.ts helpers are not exported; duplicating ~30 lines per file is cheaper than the export surface churn on index.test.ts"
  - "Redaction invariant uses console.warn/error reassignment + restore-in-finally — works across Deno runtime without Sinon/vi.spyOn machinery"
  - "D-22 audit ships as pure evidence (shasum + git log + git diff output) — zero code change to APNsRegistrationTests.swift; the no-diff assertion is the audit deliverable"
  - "Zero production code touched: index.ts and apns.ts carry zero uncommitted changes. Plan is defense-in-depth regression only, per plan's `success_criteria: Zero production code changes`"

patterns-established:
  - "PUSH_CATEGORIES.size === 3 + explicit exclusion list as the NOTIF-05 allowlist contract — any future addition to the set must intentionally update both the production Set and the test simultaneously"
  - "Per-axis D-21 test file naming (push-categories / device-token-lookup / apns-payload-shape / bad-device-token) — `grep -l D-21 supabase/functions/notifications-fanout/*.test.ts` enumerates the four axes in one command"
  - "Redaction invariant as a first-class test case (not a lint rule) — catches information-disclosure regressions at CI rather than code review"

requirements-completed:
  - NOTIF-05

metrics:
  duration_minutes: ~45
  completed_date: 2026-04-23
  commits:
    - "80074de"
    - "ea380af"
    - "33d3854"
    - "eefaa43"
---

# Phase 30 Plan 08: D-21 push Edge Function Deno-test coverage + D-22 APNsRegistrationTests unchanged audit Summary

**18 new Deno regression tests across 4 files lock the notifications-fanout push path to the NOTIF-05 contract (category allowlist, device-token query shape, APNs payload shape, stale-token prune + redaction) — full suite 28/0 GREEN, production code untouched, APNsRegistrationTests.swift confirmed byte-identical since Phase 14-05.**

## Performance

- **Duration:** ~45 min (test authoring + Deno iteration + audit)
- **Completed:** 2026-04-23
- **Tasks:** 5 (4 TDD test-file tasks + 1 audit)
- **Files created:** 4 Deno test files + this SUMMARY
- **Files modified:** 0 production files

## Accomplishments

- **D-21 a** (push-categories.test.ts): 9 tests — PUSH_CATEGORIES set equality (`size === 3`), 3 allowed categories each produce exactly 1 APNs call, 5 denied categories (including `bid_deadlin` typo regression) each produce 0 APNs calls
- **D-21 b** (device-token-lookup.test.ts): 3 tests — `in('user_id', recipients) + eq('platform', 'ios')` query shape asserted via tracked stub call log, token-lookup error surfaces `tokenError: true` with HTTP 200 (no webhook retry), zero-recipient path short-circuits before cs_device_tokens is queried
- **D-21 c** (apns-payload-shape.test.ts): 3 tests — `aps.alert.title/body` non-empty, `aps.badge === 1`, `aps.sound === 'default'`, `aps['thread-id'] === event.project_id`, top-level `event_id/project_id/category` mirror source, non-cert events omit `aps.category`
- **D-21 d** (bad-device-token.test.ts): 3 tests — 410 Unregistered prunes stale token, 400 BadDeviceToken prunes stale token, 500 InternalServerError leaves token intact; redaction invariant `logs.every(!includes(token))` enforced across all three failure modes
- **D-22 audit:** APNsRegistrationTests.swift SHA-1 `93581122217f703a4a8e05da33c9a5e4202edf4f`, last commit `9805e17` (Phase 13–15 merge, pre-Phase-30), uncommitted diff 0 bytes — confirmed unchanged since Phase 14-05
- **Full Deno suite:** `deno test --allow-env --no-check supabase/functions/notifications-fanout/` → **28 passed, 0 failed (311ms)** — exceeds ≥21 plan acceptance floor by 7 tests

## Task Commits

All four test files landed as atomic commits (salvaged from a worktree merge; the prior executor's SUMMARY was lost when the worktree was removed since `.planning/` is gitignored):

1. **Task 1: D-21 a push-categories (strict allowlist)** — `80074de` (test) — 9 tests
2. **Task 2: D-21 b device-token-lookup (query shape + error tolerance)** — `ea380af` (test) — 3 tests
3. **Task 3: D-21 c apns-payload-shape (aps.* + top-level invariants)** — `33d3854` (test) — 3 tests
4. **Task 4: D-21 d bad-device-token (stale prune + redaction invariant)** — `eefaa43` (test) — 3 tests
5. **Task 5: D-22 audit + full Deno suite run** — audit only, no commit (per plan: "This task produces NO code changes")

**Plan metadata:** _(this SUMMARY + STATE.md/ROADMAP.md update — final commit)_

_Note: TDD tasks for this plan are test-only (defense-in-depth); no feat/refactor step because production code already meets the asserted contracts._

## Files Created/Modified

### Created (4 Deno test files + 1 summary)

- `supabase/functions/notifications-fanout/push-categories.test.ts` — D-21 a strict allowlist coverage (9 tests). Inlines makeSupabaseStub + makeSendApnsStub from index.test.ts pattern. Asserts `PUSH_CATEGORIES.size === 3` + explicit inclusion (bid_deadline/safety_alert/assigned_task) + explicit exclusion (generic/document/cert_renewal/unknown_new_category/bid_deadlin-typo).
- `supabase/functions/notifications-fanout/device-token-lookup.test.ts` — D-21 b query-shape assertion (3 tests). Tracked stub records every `from(table).op(col, val)` invocation; tests assert the `cs_device_tokens` query invokes `in('user_id', recipients)` + `eq('platform', 'ios')`, that a lookup error returns `{status: 200, tokenError: true}` (no retry), and that zero recipients (actor-only) short-circuits before the cs_device_tokens query.
- `supabase/functions/notifications-fanout/apns-payload-shape.test.ts` — D-21 c aps.* + top-level invariants (3 tests). Captures sendApns(token, payload) calls and asserts `aps.alert.title/body` non-empty, `aps.badge === 1`, `aps.sound === 'default'`, `aps['thread-id']` equals project_id, top-level `event_id/project_id/category` mirror source, non-cert events omit `aps.category`.
- `supabase/functions/notifications-fanout/bad-device-token.test.ts` — D-21 d stale prune + redaction invariant (3 tests). Captures console.warn/error across three sendApns rejection modes (410 Unregistered, 400 BadDeviceToken, 500 InternalServerError). Asserts token pruned on 410/400, token retained on 500, and the raw device_token string never appears in captured logs across all three cases.
- `.planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-08-SUMMARY.md` — this file.

### Modified (0 production files)

Zero changes to production code:

| Production surface | Status | Evidence |
|--------------------|--------|----------|
| `supabase/functions/notifications-fanout/index.ts` | Untouched | `git diff` returns 0 lines |
| `supabase/functions/notifications-fanout/apns.ts` | Untouched | `git diff` returns 0 lines |
| `supabase/functions/notifications-fanout/index.test.ts` | Untouched | `git diff` returns 0 lines (Task 5 optional comment-only edit skipped — the 4 new files' naming is self-describing) |
| `supabase/functions/notifications-fanout/apns.test.ts` | Untouched | `git diff` returns 0 lines |
| `ready player 8Tests/APNsRegistrationTests.swift` | Untouched (D-22 audit) | `git diff` returns 0 lines; shasum `93581122217f703a4a8e05da33c9a5e4202edf4f`; last commit `9805e17` (Phase 13–15 merge, pre-Phase-30) |

## D-22 Audit Evidence

Per Plan Task 5 and D-22 acceptance criteria:

| Metric | Value |
|--------|-------|
| SHA-1 of APNsRegistrationTests.swift | `93581122217f703a4a8e05da33c9a5e4202edf4f` |
| Last commit touching the file | `9805e17` ("Phases 13–15: Documents, Notifications, Team & Crew Management (#2)") |
| Date of last commit (Phase 14-05 shipment) | Pre-Phase-30 (predates 30-CONTEXT.md authoring) |
| `git diff -- "ready player 8Tests/APNsRegistrationTests.swift"` | Empty (0 lines) |
| Audit verdict | **UNCHANGED since Phase 14-05 per D-22** |

## Deno Suite Final Run

```
deno test --allow-env --no-check supabase/functions/notifications-fanout/
```

Per-file breakdown:

| File | Tests | Category |
|------|-------|----------|
| `apns-payload-shape.test.ts` | 3 | **New** (D-21 c) |
| `apns.test.ts` | 4 | Existing (Phase 14-02) |
| `bad-device-token.test.ts` | 3 | **New** (D-21 d) |
| `device-token-lookup.test.ts` | 3 | **New** (D-21 b) |
| `index.test.ts` | 6 | Existing (Phase 14-02) |
| `push-categories.test.ts` | 9 | **New** (D-21 a) |
| **Total** | **28 passed / 0 failed (311ms)** | **18 new + 10 existing** |

Acceptance floor was **≥21 tests total** (6 existing index.test.ts + ≥15 across Tasks 1-4). Actual: **28 total, 18 new** — clears floor by 7.

## Decisions Made

1. **Four separate test files (one per D-21 axis) instead of appending to index.test.ts.** Matches plan intent ("keeps test-failure blast radius small"); when a regression lands, CI logs point at the axis name directly (`bad-device-token.test.ts FAILED` vs. `index.test.ts FAILED: 17 subtests, one failed`).
2. **Inline stub helpers per file.** Deno does not hoist across files without explicit exports; index.test.ts's makeSupabaseStub/makeSendApnsStub are not exported. Duplicating ~30 lines of stub-builder per file is cheaper than exporting the helpers from index.test.ts (which would touch a production-adjacent test file and bloat its public surface).
3. **Redaction invariant via console reassignment.** `console.warn = (...) => logs.push(...)` with `try/finally` restore works in Deno without Sinon/vi.spyOn machinery. Captures substring-negative assertion (`logs.every(l => !l.includes(token))`) which is the simplest expression of the information-disclosure property.
4. **D-22 audit is evidence-only.** No code change to APNsRegistrationTests.swift; the audit deliverable is the shasum + last-commit + `git diff = empty` triple, recorded in this SUMMARY.
5. **Zero production code touched.** Plan explicitly calls this out in `<success_criteria>`: "Zero production code changes: plan is defense-in-depth only." Honored exactly — `git diff index.ts apns.ts index.test.ts apns.test.ts` returns 0 lines.

## Deviations from Plan

**None — plan executed exactly as written.** All four test files shipped in the exact form specified in the plan's `<action>` blocks; all acceptance criteria met or exceeded; zero auto-fixes needed because the test suite asserts properties of already-correct production code.

Task 5's optional cosmetic comment in `index.test.ts` was declined (the plan marked it as a "LIMIT the edit to a single comment addition" nice-to-have, not a hard requirement) — the four new file names are self-describing enough that a cross-reference header in index.test.ts adds noise without value.

## Issues Encountered

**Worktree recovery (meta-only, not a plan issue).** The prior executor ran in a short-lived git worktree that was removed after the merge, taking the executor's in-progress SUMMARY.md draft with it (`.planning/` is gitignored and therefore not included in the worktree→main merge). The four code commits (80074de/ea380af/33d3854/eefaa43) had already landed on main via the worktree merge, so recovery was limited to re-authoring this SUMMARY + re-running the D-22 audit to confirm still-current state. APNsRegistrationTests.swift hash matches pre-execution audit; no drift.

No issues during plan execution itself.

## User Setup Required

None — this plan is CI-bound test authoring. No external services, environment variables, or dashboard configuration required. The tests run under `deno test --allow-env --no-check` using only `SUPABASE_SERVICE_ROLE_KEY=test-service-role-key` set inside each test file.

The downstream real-device UAT (Phase 30-09) is where external setup (APNs sandbox provisioning, real iPhone, Xcode-signed build) is required. That remains scoped to 30-09 per plan.

## Threat Flags

None — no new trust boundaries, endpoints, file-access paths, or schema changes introduced. Plan adds only Deno test files co-located with existing Edge Function source. The `<threat_model>` entries (T-30-08-01 Information Disclosure, T-30-08-02 Tampering via new push category) are MITIGATED by Tasks 4 and 1 respectively as planned.

## Self-Check: PASSED

**Created files verified:**
- `supabase/functions/notifications-fanout/push-categories.test.ts` — FOUND (commit 80074de)
- `supabase/functions/notifications-fanout/device-token-lookup.test.ts` — FOUND (commit ea380af)
- `supabase/functions/notifications-fanout/apns-payload-shape.test.ts` — FOUND (commit 33d3854)
- `supabase/functions/notifications-fanout/bad-device-token.test.ts` — FOUND (commit eefaa43)

**Commits verified on main:**
- `80074de` — FOUND (`test(30-08): add D-21 a push-categories Deno test`)
- `ea380af` — FOUND (`test(30-08): add D-21 b device-token-lookup Deno test`)
- `33d3854` — FOUND (`test(30-08): add D-21 c apns-payload-shape Deno test`)
- `eefaa43` — FOUND (`test(30-08): add D-21 d bad-device-token Deno test`)

**Deno suite re-run at SUMMARY authoring time:** 28 passed / 0 failed (311ms)

**D-22 audit re-run at SUMMARY authoring time:**
- `shasum "ready player 8Tests/APNsRegistrationTests.swift"` → `93581122217f703a4a8e05da33c9a5e4202edf4f` (matches pre-execution)
- `git log --oneline -- "ready player 8Tests/APNsRegistrationTests.swift" | head -1` → `9805e17 Phases 13–15: Documents, Notifications, Team & Crew Management (#2)`
- `git diff -- "ready player 8Tests/APNsRegistrationTests.swift" | wc -l` → `0`

## Next Phase Readiness

**Plan 30-09 is unblocked.** With the CI-bound regression floor in place, 30-09's real-device UAT is a confirmation step, not a debugging session:

- Any future Edge Function regression fails within 60s of `deno test` before the PR can merge (per plan `<success_criteria>`)
- If 30-09 real-device testing reveals a push delivery issue, the bug is provably in provisioning/APNs-auth/deploy (outside these tests' scope), not in the fanout logic

**Remaining Phase 30 plans:** 30-03 (web project-picker), 30-04 (filter-scoped mark-all + bell-badge parity), 30-05 (iOS Realtime subscription), 30-06 (analytics), 30-09 (real-device UAT + 30-DEPLOY-STEPS.md). Phase 30 progress after this plan: **4/9 complete**.

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Plan: 08*
*Completed: 2026-04-23*
