# Deferred Items — Phase 13

Pre-existing issues discovered during plan execution that are out of scope for the current task.

## 13-02 (Web API routes)

### Pre-existing TypeScript errors (unrelated to documents)

`npx tsc --noEmit` reports ~17 errors in files NOT touched by this plan:

- `src/app/api/jobs/route.ts` — missing `@/lib/jobs` module + spread-types error
- `src/app/components/AngelicPromptToggle.tsx` — missing `@/lib/angelic/preferences`
- `src/app/contracts/page.tsx`, `src/app/feed/page.tsx`, `src/app/ops/page.tsx`, `src/app/projects/page.tsx`, `src/app/punch/page.tsx`, `src/app/trust/page.tsx` — missing `@/app/components/PremiumFeatureGate`
- `src/app/feed/page.tsx`, `src/app/page.tsx` — missing `FeatureAccessLink` / `AngelicFlowStrip`
- `src/app/jobs/page.tsx` — missing `@/lib/jobs`, `@/lib/subscription/useSubscriptionTier`, implicit-any params
- `src/app/projects/page.tsx` — missing `SubscriberActionButton`

These appear to be missing files from a prior incomplete checkpoint. Files inside `web/src/app/api/documents/**` and `web/src/lib/documents/**` are tsc-clean.

### Missing infrastructure

- `web/package.json` had no `test` script and no installed `node_modules` when this plan started; vitest is `^4.1.2` (CLAUDE.md mentions 3.2.4, outdated). Added `"test": "vitest"` script as part of Task 1 commit.
