---
phase: 29-live-video-traffic-feed-sat-drone
plan: 04
subsystem: backend
tags: [supabase, pg_net, pg_cron, edge-function, deno, postgres-trigger, retention]

# Dependency graph
requires:
  - phase: 29-01
    provides: cs_live_suggestions table + RLS + indexes + generated_at column (retention pivot)
  - phase: 29-02
    provides: cs_video_assets.source_type='drone' widening (trigger key predicate)
  - phase: 29-03
    provides: generate-live-suggestions Edge Function with ?project_id=X scoped mode (trigger target)
  - phase: 22
    provides: notify_ffmpeg_worker() template (pg_net trigger shape), Phase 22 retention cron slots (03:00/03:05/03:30 UTC — this plan staggers 03:45), Vault secrets project_url + service_role_key, prune-expired-videos Edge Function pattern (auth gate, structured log)
provides:
  - trg_notify_live_suggestions AFTER UPDATE trigger on cs_video_assets (T-29-TRIGGER-LOOP-mitigated; fires ONLY on drone + transition-to-ready)
  - notify_live_suggestions_worker() security-definer PL/pgSQL function (Vault-indirected Bearer auth; silent no-op when Vault unset)
  - prune-expired-suggestions Supabase Edge Function (row-only 7-day retention; idempotent; service-role Bearer gate)
  - pg_cron migration scheduling phase29-prune-expired-suggestions at 03:45 UTC (no collision with Phase 22 slots)
  - DEFERRED deploy: `supabase functions deploy prune-expired-suggestions` + `supabase db push` (human action)
affects: [29-05, 29-06, 29-07, 29-08, 29-09, 29-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "pg_net trigger guard: `new.source_type = 'drone' AND new.status = 'ready' AND (old.status IS DISTINCT FROM 'ready')` — fires exactly once per transition-to-ready. Prevents re-fire on unrelated UPDATEs (metadata edits, portal_visible flips). Canonical mitigation for T-29-TRIGGER-LOOP."
    - "Vault indirection for both trigger functions AND cron jobs: `(select decrypted_secret from vault.decrypted_secrets where name = 'project_url')`. Reuses secrets established by Phase 14/22 — no new credentials introduced."
    - "Row-only retention (vs. Phase 22 storage+row retention): cs_live_suggestions has zero storage artefacts — prune is a single `delete ... where generated_at < cutoff`. Idempotent by construction."
    - "Cron stagger discipline: Phase 22 owns 03:00/03:05/03:30 UTC; Phase 29-03 owns */15; Phase 29-04 adds 03:45 UTC with 15-min gap above Phase 22's highest slot."

key-files:
  created:
    - supabase/migrations/20260420003_phase29_live_suggestions_trigger.sql
    - supabase/functions/prune-expired-suggestions/index.ts
    - supabase/functions/prune-expired-suggestions/deno.json
    - supabase/migrations/20260420004_phase29_prune_suggestions_cron.sql
  modified: []

key-decisions:
  - "Trigger fires AFTER UPDATE (not AFTER INSERT). Drone clips enter cs_video_assets with status='uploading'; the ffmpeg worker transitions status uploading→transcoding→ready. Only the terminal transition should fire Anthropic — so UPDATE with old/new status comparison, not INSERT."
  - "Trigger invocation path: `/functions/v1/generate-live-suggestions?project_id=<new.project_id>` in query-string, body={trigger:'per_upload', asset_id:new.id}. Matches the scoped-mode contract 29-03 built into the Edge Function (when ?project_id is present, Edge Function scopes to one project)."
  - "Trigger body carries asset_id for logging/debugging; Edge Function's scoped-mode logic does NOT require asset_id (it refetches the latest drone asset for the project). Keeping asset_id on the wire costs nothing and enables future debugging."
  - "Fail-silent when Vault unset — v_url/v_key NULL check mirrors Phase 22's notify_ffmpeg_worker() guard so local dev DBs without Vault secrets don't error on every status update."
  - "prune function does NOT use INTERVAL in SQL — cutoff computed in JS (`Date.now() - 7 * 24 * 60 * 60 * 1000`) then serialized to ISO string for `.lt('generated_at', cutoff)`. Matches prune-expired-videos idiom and avoids PostgREST's interval parsing edge cases."
  - "prune function returns `.select('id')` on DELETE so `deleted` count in the log report reflects actual rows removed (PostgREST requires the `Prefer: return=representation` equivalent; supabase-js `.select()` after `.delete()` handles this)."

patterns-established:
  - "Phase 29 retention convention: row-only Edge Functions use a single DELETE with cutoff in ms, no storage sweep step; reserves the heavier Phase-22-shape storage-sweep pattern for assets that actually have storage."
  - "Phase 29 trigger convention: transition-guard AFTER UPDATE (never AFTER INSERT when the interesting event is a status transition); Vault indirection for URL + key; silent-skip when Vault unset; constant-time fire-and-forget (perform net.http_post) so trigger never blocks the triggering UPDATE."

requirements-completed: []  # LIVE-07 and LIVE-13 are BLOCKED on Task 4 deploy/push. Mark complete in a follow-up run once `supabase functions deploy` + `supabase db push` both succeed and pg_trigger/cron.job verification passes.

# Metrics
duration: 13min
completed: 2026-04-20
---

# Phase 29-04: Per-upload Trigger + 7-day Retention Summary

**pg_net AFTER-UPDATE trigger on cs_video_assets that fires generate-live-suggestions only on drone + transition-to-ready (T-29-TRIGGER-LOOP guarded), plus a row-only prune-expired-suggestions Edge Function scheduled at 03:45 UTC for D-21 7-day retention.**

## Performance

- **Duration:** ~13 min (author + verify + commit; excludes deploy)
- **Started:** 2026-04-20T02:01:19Z
- **Completed (code):** 2026-04-20T02:14:35Z
- **Tasks completed:** 3 of 4 (Task 4 DEFERRED — see below)
- **Files created:** 4

## Accomplishments

- pg_net trigger `trg_notify_live_suggestions` + function `notify_live_suggestions_worker()` authored with the novel T-29-TRIGGER-LOOP guard (`new.source_type='drone' AND new.status='ready' AND old.status IS DISTINCT FROM 'ready'`) — fires exactly once per drone transition-to-ready, never on unrelated UPDATEs.
- `prune-expired-suggestions` Supabase Edge Function authored — idempotent 7-day row-only retention, service-role Bearer gate, structured `[prune-suggestions]` log for cron.job_run_details.
- pg_cron migration authored scheduling the prune function at `45 3 * * *` (03:45 UTC) — 15-minute stagger above Phase 22's highest slot (03:30) with Vault-indirected Bearer auth.
- All three migrations/functions committed atomically; working tree for 29-04 files is clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create pg_net trigger migration for per-upload Live Suggestions** — `4791dc6` (feat)
2. **Task 2: Create prune-expired-suggestions Edge Function + deno.json** — `2e89426` (feat)
3. **Task 3: Create pg_cron migration scheduling prune-expired-suggestions at 03:45 UTC** — `b87598c` (feat)
4. **Task 4: Deploy Edge Function + apply migrations** — **DEFERRED** (human action; see below)

## Files Created

- `supabase/migrations/20260420003_phase29_live_suggestions_trigger.sql` — `notify_live_suggestions_worker()` security-definer function + `trg_notify_live_suggestions` AFTER UPDATE trigger on cs_video_assets. Guard predicates drone+ready+transition. Vault-indirected URL+key; silent no-op when Vault unset.
- `supabase/functions/prune-expired-suggestions/index.ts` — Deno Edge Function. 7-day cutoff computed in JS (ms), `supabase.from('cs_live_suggestions').delete().lt('generated_at', cutoff).select('id')`. Structured JSON report with `{deleted, errors}`.
- `supabase/functions/prune-expired-suggestions/deno.json` — import map pinning `@supabase/supabase-js@2.101.1` from esm.sh (matches Phase 29-03 and Phase 22 Deno functions).
- `supabase/migrations/20260420004_phase29_prune_suggestions_cron.sql` — idempotent unschedule-then-schedule of `phase29-prune-expired-suggestions` at `45 3 * * *`. Invokes Edge Function via `net.http_post` with Vault-indirected Bearer auth.

## Decisions Made

- **AFTER UPDATE, not AFTER INSERT.** Drone clips are inserted with `status='uploading'`; the event of interest is the terminal transition to `'ready'` after the Fly.io ffmpeg worker finishes. An INSERT trigger would miss it entirely (row is inserted before transcode). Phase 22's `notify_ffmpeg_worker` uses AFTER INSERT because it fires on upload start (opposite end of the pipeline).
- **`IS DISTINCT FROM` instead of `<>`.** If `old.status` is NULL, `old.status <> 'ready'` evaluates to NULL (not TRUE), which would short-circuit the trigger. `IS DISTINCT FROM` correctly treats NULL as "not equal to 'ready'". Defensive even though UPDATE-trigger `old` is always a full row.
- **Query-string `?project_id=X`, not body.** The 29-03 Edge Function's scoped-mode read path uses `new URL(req.url).searchParams.get('project_id')`. Keeping the scope parameter in the URL means the cron path (no project_id) and the trigger path (with project_id) differ in the URL only, not in body shape — simpler to reason about.
- **Fail-silent on Vault miss.** A `raise exception` on unset Vault secrets would block every drone status transition in local dev and could cascade in prod if Vault rotation momentarily clears a secret. Silent skip matches Phase 22 `notify_ffmpeg_worker`.

## Deviations from Plan

**None — plan executed exactly as written.** All three code tasks' acceptance criteria passed on first verification. No auto-fixes required.

## Issues Encountered

None.

## DEFERRED Tasks

### Task 4 [BLOCKING]: Deploy prune-expired-suggestions + apply 2 new migrations

**Status:** Deferred per deferral protocol — this is a `checkpoint:human-action` task requiring operator credentials and the Supabase CLI with a linked project.

**What the user must run (in this order):**

```bash
# 1. Deploy the retention Edge Function
supabase functions deploy prune-expired-suggestions
# Expected: "Deployed Function prune-expired-suggestions" with version printed

# 2. Apply both new migrations
supabase db push
# Expected output lines include:
#   Applying migration 20260420003_phase29_live_suggestions_trigger.sql... ok
#   Applying migration 20260420004_phase29_prune_suggestions_cron.sql... ok
```

**Verification commands (run after deploy + push):**

```bash
# 3. Verify trigger is installed (expect 1 row; tgrelid = cs_video_assets)
supabase db remote query "select tgname, tgrelid::regclass from pg_trigger where tgname = 'trg_notify_live_suggestions';"

# 4. Verify cron job present (expect schedule = '45 3 * * *')
supabase db remote query "select jobname, schedule from cron.job where jobname = 'phase29-prune-expired-suggestions';"

# 5. Smoke-test prune function directly
SRK=<service_role_key>
curl -X POST https://<PROJECT_REF>.supabase.co/functions/v1/prune-expired-suggestions \
  -H "Authorization: Bearer $SRK"
# Expected: 200 OK with body '{"deleted":0,"errors":[]}' (no rows older than 7d yet in Wave 2)
```

**Optional end-to-end trigger test** (recommended once 29-09 ships the drone upload UI, or via direct API call using 29-02's source_type='drone' widening):

```bash
# Upload a drone clip through the web path, wait for transcode to 'ready', then:
supabase db remote query "select * from cron.job_run_details \
  where jobid in (select jobid from cron.job where jobname='phase29-generate-live-suggestions') \
  order by start_time desc limit 3;"
# Look for an invocation OUTSIDE the */15 cadence, triggered by the pg_net trigger.
```

**Resume signal:** Type "deployed" (per plan's resume-signal) once:
- `supabase functions deploy prune-expired-suggestions` succeeded.
- `supabase db push` applied both 20260420003 and 20260420004 migrations.
- pg_trigger shows `trg_notify_live_suggestions` on `cs_video_assets`.
- cron.job shows `phase29-prune-expired-suggestions` at schedule `45 3 * * *`.
- Manual curl to prune returns 200 with JSON report.

On success, the verifier should mark LIVE-07 and LIVE-13 complete in REQUIREMENTS.md. Until then, both requirements remain INCOMPLETE.

## User Setup Required

**Edge Function secrets (reused from Phase 22 / 29-01; no new secrets introduced):**
- `SUPABASE_URL` — reused
- `SUPABASE_SERVICE_ROLE_KEY` — reused

No new secrets. No new dashboard configuration. No new Vault entries.

## Known Stubs

None — all code paths fully wired. Trigger body executes `net.http_post`; Edge Function executes `supabase.delete()`; cron job invokes `net.http_post`.

## Threat Flags

None — no new trust boundaries introduced beyond those documented in the plan's threat model (all three T-29-04-* threats mitigated in code as specified).

## Next Phase Readiness

- **Wave 3 (UI) unblocked on code:** 29-05 through 29-09 can consume `cs_live_suggestions` knowing two insert paths (cron */15 and per-upload trigger) exist. The actual insert stream requires Task 4 deploy.
- **29-10 (web suggestions + traffic + budget API) unblocked on code** for the same reason.
- **Blockers on downstream runtime verification:** Task 4 deploy. Until `supabase db push` lands, no trigger/cron runs in production, so UI waves can still develop against the */15 cron (already live per 29-03) but cannot exercise the per-upload path end-to-end.

## Self-Check

Verified after summary creation.

- FOUND: supabase/migrations/20260420003_phase29_live_suggestions_trigger.sql
- FOUND: supabase/functions/prune-expired-suggestions/index.ts
- FOUND: supabase/functions/prune-expired-suggestions/deno.json
- FOUND: supabase/migrations/20260420004_phase29_prune_suggestions_cron.sql
- FOUND commit 4791dc6 (Task 1)
- FOUND commit 2e89426 (Task 2)
- FOUND commit b87598c (Task 3)

## Self-Check: PASSED

---
*Phase: 29-live-video-traffic-feed-sat-drone*
*Plan: 04*
*Completed (code): 2026-04-20 — deploy DEFERRED*
