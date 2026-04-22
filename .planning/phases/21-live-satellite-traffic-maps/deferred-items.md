# Phase 21 Deferred Items

Out-of-scope findings from Phase 21 executions — not introduced by Phase 21 but surfaced during its verification runs.

## Pre-existing TypeScript errors (Phase 29 domain)

**File:** `web/src/lib/live-feed/generate-suggestion.ts:154`
**Error:** `TS2741: Property 'imageUrl' is missing in type 'ProjectContext' but required in type 'VisionPromptInput'.`
**Origin commit:** `d04799c` (Phase 29 — "fix(ai): drop duplicate imageUrl from promptInput")
**Surfaced during:** Plan 21-08 tsc pass, 2026-04-22
**Scope boundary:** Phase 29 live-feed subsystem, not touched by any Phase 21 plan. Pre-existing at HEAD before Plan 21-08 started. Blocking `npx tsc --noEmit` clean-green across `web/` but does not affect `web/src/app/maps/**` which is what Phase 21 owns.
**Recommended owner:** Phase 30 or a follow-up Phase 29 remediation quick task.
