---
phase: 29-live-video-traffic-feed-sat-drone
plan: 03
subsystem: backend
tags: [supabase-edge-function, anthropic, claude-vision, zod, pg_cron, deno, typescript]

# Dependency graph
requires:
  - phase: 29-01
    provides: cs_live_suggestions table + RLS + indexes (model check locks accepted values)
  - phase: 29-02
    provides: VideoUploadClient source_type widening + portal drone-exclusion regression test
  - phase: 22
    provides: poster.jpg at {org}/{project}/{asset}/poster.jpg after VOD transcode; Vault project_url/service_role_key; Edge Function deploy pattern; prune-expired-videos canonical shape
provides:
  - Shared Anthropic vision adapter (web/src/lib/live-feed/anthropic-vision.ts) with Zod schema validation
  - Deno-side mirror (supabase/functions/_shared/anthropic-vision.ts) for Edge Function parity
  - generate-live-suggestions Supabase Edge Function (LIVE-06 backend, unscheduled/undeployed)
  - pg_cron migration scheduling the Edge Function every 15 min (awaiting db push)
affects: [29-04, 29-05, 29-06, 29-07, 29-08, 29-09, 29-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared web ↔ Deno adapter: maintain lock-step copies of anthropic-vision.ts — web imports Zod from npm 'zod' (v4 transitive), Deno imports from https://esm.sh/zod@3.23.8. Any schema or prompt change MUST land in both files in the same commit."
    - "Zod safeParse before DB insert closes T-29-VISION-PAYLOAD: malformed Anthropic responses throw in callAnthropicVision and are counted in report.malformed_skipped; never persisted."
    - "Budget-reached sentinel pattern: when project hits 96/day cap, insert ONE row with model='budget_reached_marker' per UTC day (sentinel pre-check before insert keeps it idempotent)."
    - "Signed poster URL TTL = 60s — Anthropic fetches the image within seconds; short TTL minimizes exposure."
    - "Edge Function ?project_id=X scoped mode enables 29-04 per-upload pg_net trigger to target one project without duplicating logic."

key-files:
  created:
    - web/src/lib/live-feed/anthropic-vision.ts
    - web/src/lib/live-feed/__tests__/anthropic-vision.test.ts (replaced Wave 0 stub)
    - supabase/functions/_shared/anthropic-vision.ts
    - supabase/functions/generate-live-suggestions/index.ts
    - supabase/functions/generate-live-suggestions/deno.json
    - supabase/migrations/20260420002_phase29_generate_live_suggestions_cron.sql
  modified: []

key-decisions:
  - "Zod v4 is used on the web side (node_modules transitive 4.3.6) but is API-compatible with the v3.23.8 pin the Deno mirror uses — the schema surface we rely on (z.object, z.enum, z.string().min().max(), z.number().int(), z.default, .safeParse) is identical between versions. Verified with a live Node REPL test before writing the adapter."
  - "Edge Function does NOT hardcode Anthropic key — reads Deno.env.get('ANTHROPIC_API_KEY'). The secret was set in 29-01 Task 2. No key literals appear in source."
  - "Edge Function does NOT use @anthropic-ai/sdk — single-shot raw HTTP POST via fetch is smaller Deno bundle and matches RESEARCH Alternative (raw SDK simpler than Vercel AI SDK for one-shot vision)."
  - "Signed URL path (org/project/asset/poster.jpg) is logged but signed URL itself is NOT — honors T-29-03-02 (information disclosure mitigation)."
  - "Default model hardcoded to claude-haiku-4-5-20251001 in Edge Function; model upgrade override (ConstructOS.LiveFeed.SuggestionModel) is client-side only for 29-10 Analyze Now — mitigates T-29-03-04 (scheduled-job silent upgrade)."

patterns-established:
  - "Deno Edge Function canonical import shape for Phase 29: @supabase/supabase-js@2.101.1 from esm.sh; zod@3.23.8 from esm.sh; shared modules via ../_shared/*.ts relative import."
  - "pg_cron schedule naming: phaseNN-{function-slug} — matches Phase 22 convention (phase22-prune-expired-videos etc.)."
  - "Edge Function scoping protocol: accept optional ?project_id=X query param; when absent, iterate all candidates with drone asset ready in the last 24h."

requirements-completed: []  # LIVE-06 and LIVE-08 remain INCOMPLETE until Task 4 deploy/push succeeds. Mark complete in 29-03's resumption run after deploy.

# Metrics
duration: 7min
completed: 2026-04-20
---

# Phase 29 Plan 03: Anthropic Vision Suggestion Generator Summary

**Shared Zod-validated Anthropic vision adapter (web + Deno mirror) + generate-live-suggestions Supabase Edge Function with 96/day budget cap, 60s signed poster URLs, and every-15-min pg_cron schedule — code-complete, deploy deferred.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-04-20T01:29:00Z
- **Completed:** 2026-04-20T01:36:18Z
- **Tasks completed:** 3 of 4 (Task 4 DEFERRED — user action required)
- **Files created:** 6

## Accomplishments

- Shared Anthropic vision adapter with Zod `LiveSuggestionResponseSchema` that matches the cs_live_suggestions check constraints exactly (1..2000 chars + 3-value severity enum).
- 8 passing vitest assertions cover prompt build, well-formed parse, 3 validation failures (empty / overlong / invalid severity), 200-response happy path, 5xx retry-then-throw, and no-JSON rejection.
- Edge Function implements the full LIVE-06 contract: service_role auth gate, 96/day budget pre-check, budget_reached_marker sentinel insert when capped, poster read via 60s signed URL, Anthropic call with `../_shared/anthropic-vision.ts` validator, and structured `[live-suggestions]` audit log.
- pg_cron migration mirrors Phase 22's idempotent unschedule-then-schedule pattern; uses existing Vault secrets (`project_url`, `service_role_key`) — no new secrets in the SQL.
- All 3 autonomous tasks committed atomically with conventional-commit messages prefixed `feat(29-03):`.

## Task Commits

1. **Task 1: Shared anthropic-vision adapter + 8 passing tests** — `0016ce1` (feat)
2. **Task 2: generate-live-suggestions Edge Function + Deno mirror** — `e07b56e` (feat)
3. **Task 3: pg_cron migration (every 15 min)** — `e78948c` (feat)
4. **Task 4: Deploy Edge Function + apply migration** — **DEFERRED — awaiting user action** (see User Action Required below)

## Files Created/Modified

- `web/src/lib/live-feed/anthropic-vision.ts` — shared vision adapter exporting `buildVisionPrompt`, `callAnthropicVision`, `LiveSuggestionResponseSchema`, `ActionHintSchema`, `DEFAULT_VISION_MODEL`, `SITE_ANALYST_SYSTEM_PROMPT`.
- `web/src/lib/live-feed/__tests__/anthropic-vision.test.ts` — replaced Wave 0 skip stub with 8 assertions; all pass under `npx vitest run`.
- `supabase/functions/_shared/anthropic-vision.ts` — Deno-compatible byte-equivalent mirror (only the Zod import differs: `https://esm.sh/zod@3.23.8`).
- `supabase/functions/generate-live-suggestions/index.ts` — 200-line Deno.serve Edge Function mirroring `prune-expired-videos` shape + new budget/vision logic.
- `supabase/functions/generate-live-suggestions/deno.json` — import map for `@supabase/supabase-js` and `zod` via esm.sh.
- `supabase/migrations/20260420002_phase29_generate_live_suggestions_cron.sql` — idempotent `*/15 * * * *` pg_cron schedule invoking the Edge Function via Vault-sourced Bearer auth.

## Decisions Made

- **Zod v4 on web side is API-compatible with v3.23.8 on Deno side.** Verified via Node REPL that `z.object`, `z.enum`, `z.string().min().max()`, `z.number().int().min().max()`, `.default({})`, and `.safeParse` behave identically between 3.x and 4.x for the schema surface this plan uses. No adapter changes needed across versions.
- **Budget_reached_marker sentinel is one-per-project-per-day**, enforced by a pre-insert count check inside the budget-skipped branch. Avoids spamming the table when a runaway cron tick finds the cap exceeded 96 times in a day.
- **Signed-URL path is logged, signed URL body is not** (T-29-03-02 mitigation). Structured log: `[live-suggestions] no_poster {"project_id": ..., "path": "org/project/asset/poster.jpg"}`.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None — all code paths are wired. Stub detection scan: the Edge Function's `buildProjectContext` intentionally leaves `recentDeliveries`, `weather`, and `roadTraffic` unset in v1. This is documented in the plan (D-16 / UI-SPEC notes these as optional) and is not a stub — the adapter handles `undefined` inputs by emitting "unknown" defaults in the prompt.

## User Action Required — Task 4 (BLOCKING)

**Status:** DEFERRED until user runs the deploy commands below. This is the designed workflow: code-writing is autonomous, deploy-time blocking steps (`supabase functions deploy`, `supabase db push`) require user's Supabase auth and must be run by the operator.

### Prerequisites to re-verify

```bash
# 1. Anthropic key secret must still be present (set in 29-01 Task 2)
supabase secrets list | grep ANTHROPIC_API_KEY

# 2. Vault secrets must still be present (set in Phase 14/22)
supabase db remote query "select name from vault.decrypted_secrets where name in ('project_url','service_role_key') order by name;"
# Expect 2 rows
```

### Deploy commands

```bash
# Deploy the Edge Function (bundles supabase/functions/_shared/ automatically)
supabase functions deploy generate-live-suggestions

# Apply the pg_cron migration
supabase db push

# Verify cron job is installed
supabase db remote query "select jobname, schedule from cron.job where jobname = 'phase29-generate-live-suggestions';"
# Expect: 1 row with schedule '*/15 * * * *'

# Smoke-test Edge Function (expect 200 + JSON report)
SRK=$(supabase db remote query "select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key';" --output=json | jq -r '.[0].decrypted_secret')
curl -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/generate-live-suggestions" \
  -H "Authorization: Bearer $SRK"
# Expect: 200 with {"generated":0,"budget_skipped":0,...} if no drone assets exist (not a failure)

# Wait up to 15 min then verify first scheduled tick
supabase db remote query "select start_time, status from cron.job_run_details where jobid = (select jobid from cron.job where jobname = 'phase29-generate-live-suggestions') order by start_time desc limit 1;"
# Expect: status='succeeded'
```

### After deploy

When the cron job is visible and the first scheduled tick succeeds, mark requirements LIVE-06 and LIVE-08 complete in REQUIREMENTS.md (they are currently tracked as pending for this plan). The shared adapter is already in main and is importable by 29-10 without any further action.

## Next Plan Readiness

- **29-04 (per-upload trigger)** can proceed once Task 4 deploys — the `?project_id=X` scoped mode is already implemented.
- **29-05 through 29-09 (UI work)** can read the `cs_live_suggestions` table against the deployed Edge Function (or against stub data until deploy completes).
- **29-10 (web Analyze Now route)** can import `callAnthropicVision` from `@/lib/live-feed/anthropic-vision` immediately — no backend dependency for that import.

## Self-Check: PASSED

Verified:
- `web/src/lib/live-feed/anthropic-vision.ts` — FOUND
- `web/src/lib/live-feed/__tests__/anthropic-vision.test.ts` — FOUND
- `supabase/functions/_shared/anthropic-vision.ts` — FOUND
- `supabase/functions/generate-live-suggestions/index.ts` — FOUND
- `supabase/functions/generate-live-suggestions/deno.json` — FOUND
- `supabase/migrations/20260420002_phase29_generate_live_suggestions_cron.sql` — FOUND
- Commit `0016ce1` (Task 1) — FOUND in git log
- Commit `e07b56e` (Task 2) — FOUND in git log
- Commit `e78948c` (Task 3) — FOUND in git log
- Vitest: 8 passed / 0 failed / 0 skipped

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Plan: 03 — generate-live-suggestions Edge Function + shared Anthropic vision adapter*
*Completed (code): 2026-04-20 — Deploy deferred to user*
