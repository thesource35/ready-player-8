---
phase: quick
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - web/src/lib/supabase/types.ts
  - web/src/lib/mock-data.ts
  - web/src/app/api/chat/route.ts
  - web/src/app/api/chat/route.test.ts
  - web/next.config.ts
  - web/src/app/api/billing/checkout/route.ts
  - web/src/app/api/contracts/route.ts
  - web/src/app/api/feed/route.ts
  - web/src/app/api/projects/route.ts
  - web/src/app/api/tasks/route.ts
  - web/src/app/api/punch/route.ts
  - web/src/app/api/ops/route.ts
  - web/src/app/api/leads/route.ts
  - web/src/app/api/leads/route.test.ts
  - web/src/app/api/link-health/route.ts
  - web/src/app/layout.tsx
autonomous: true
requirements: [RLS-05, WERR-05, CONSIST-04, CONSIST-01, WEB-02, AUTH-06, PERF-01, WTEST-04]
must_haves:
  truths:
    - "npx tsc --noEmit returns 0 errors"
    - "All API routes use middleware rate limiting, not legacy checkRateLimit"
    - "Billing checkout route has CSRF and auth checks"
    - "Nav shows auth-aware sign-in/sign-out links via NavAuthLinks component"
  artifacts:
    - path: "web/src/lib/supabase/types.ts"
      provides: "user_id on RLS types, OpsAlert/Rfi/ChangeOrder exports"
      contains: "user_id"
    - path: "web/next.config.ts"
      provides: "Clean Next.js 16 config without invalid eslint property"
    - path: "web/src/app/layout.tsx"
      provides: "NavAuthLinks wired into nav bar"
      contains: "NavAuthLinks"
  key_links:
    - from: "web/src/app/api/ops/route.ts"
      to: "web/src/lib/supabase/types.ts"
      via: "import { OpsAlert, Rfi, ChangeOrder }"
      pattern: "OpsAlert.*Rfi.*ChangeOrder"
---

<objective>
Fix all 37 TypeScript errors and 8 partial requirements from the v1.0 milestone audit so `npx tsc --noEmit` passes clean and `ignoreBuildErrors` can remain as a safety net rather than a crutch.

Purpose: The audit found type mismatches, missing type exports, legacy rate-limit calls that conflict with middleware, a missing CSRF check on billing, and the nav not using the auth-aware NavAuthLinks component. These are all small, surgical fixes.

Output: Zero TS errors, all 8 partial requirements promoted to full compliance.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@web/src/lib/supabase/types.ts
@web/src/lib/mock-data.ts
@web/src/app/api/chat/route.ts
@web/next.config.ts
@web/src/app/api/billing/checkout/route.ts
@web/src/app/layout.tsx
@web/src/app/components/NavAuthLinks.tsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix all TypeScript type errors and config</name>
  <files>web/src/lib/supabase/types.ts, web/src/lib/mock-data.ts, web/src/app/api/chat/route.ts, web/next.config.ts</files>
  <action>
1. **web/src/lib/supabase/types.ts** — Add `user_id?: string` field to: `Project`, `Contract`, `FeedPost`, `PunchItem` types (fixes RLS-05, resolves 4 TS errors in routes that set user_id on insert). Also add and export these three new types at the end of the file (fixes WERR-05, resolves 3 TS errors in ops/route.ts):

```typescript
export interface OpsAlert {
  id: string;
  title: string;
  message: string;
  severity: string;
  acknowledged: boolean;
  created_at: string;
  user_id?: string;
}

export interface Rfi {
  id: string;
  number: string;
  subject: string;
  status: string;
  priority: string;
  assigned_to: string;
  due_date: string;
  created_at: string;
  user_id?: string;
}

export interface ChangeOrder {
  id: string;
  number: string;
  description: string;
  amount: number;
  status: string;
  requested_by: string;
  created_at: string;
  user_id?: string;
}
```

2. **web/src/lib/mock-data.ts** — The `Project` type has `score: string` but mock data uses numeric values (88, 92, etc.). Fix by changing `score` in the `Project` interface (in types.ts) from `string` to `number`. This is correct because Contract already has `score: number` and scores are numeric. This resolves 5 TS errors in mock-data.ts.

3. **web/src/app/api/chat/route.ts** — On line 82, rename `maxTokens: 1024` to `maxOutputTokens: 1024` (fixes CONSIST-04, resolves 1 TS error — the AI SDK renamed this property).

4. **web/next.config.ts** — Remove the entire `eslint: { ignoreDuringBuilds: true }` block (lines 32-34). This property does not exist in `NextConfig` for Next.js 16. Resolves 1 TS error.

5. **npm install** — Run `cd web && npm install` to install @upstash/ratelimit, @upstash/redis, and @playwright/test from package.json into node_modules. These are already in package.json but not installed. Resolves 23 TS errors (2 from rate-limit.ts, 21 from e2e/*.spec.ts and playwright.config.ts).

6. **git add web/src/lib/nav.ts** — Track this untracked file so CI tests can import it.
  </action>
  <verify>
    <automated>cd web && npm install && npx tsc --noEmit 2>&1 | head -5</automated>
  </verify>
  <done>npx tsc --noEmit exits with 0 errors. All 37 TS errors resolved.</done>
</task>

<task type="auto">
  <name>Task 2: Remove legacy rate limiting and add billing security</name>
  <files>web/src/app/api/contracts/route.ts, web/src/app/api/feed/route.ts, web/src/app/api/projects/route.ts, web/src/app/api/tasks/route.ts, web/src/app/api/punch/route.ts, web/src/app/api/ops/route.ts, web/src/app/api/leads/route.ts, web/src/app/api/chat/route.ts, web/src/app/api/link-health/route.ts, web/src/app/api/chat/route.test.ts, web/src/app/api/leads/route.test.ts, web/src/app/api/billing/checkout/route.ts</files>
  <action>
**CONSIST-01: Remove legacy checkRateLimit from all routes** (middleware now handles rate limiting):

For each of these 9 route files, remove the `checkRateLimit` import and the if-block that calls it:
- `web/src/app/api/contracts/route.ts` — remove import (line 5) and rate limit check (lines 12-13ish)
- `web/src/app/api/feed/route.ts` — remove import (line 5) and rate limit check
- `web/src/app/api/projects/route.ts` — remove import (line 5) and rate limit check
- `web/src/app/api/tasks/route.ts` — remove import (line 3) and rate limit check
- `web/src/app/api/punch/route.ts` — remove import (line 5) and rate limit check
- `web/src/app/api/ops/route.ts` — remove import (line 4) and rate limit check
- `web/src/app/api/link-health/route.ts` — remove import (line 4) and rate limit check
- `web/src/app/api/chat/route.ts` — remove `checkRateLimit, getLegacyRateLimitHeaders` from import (line 4), remove the rate limit if-block (lines 10-15), remove the `const ip` line if only used for rate limiting (check if ip is used elsewhere first — it is NOT used elsewhere after removing rate limit)
- `web/src/app/api/leads/route.ts` — remove `checkRateLimit, getLegacyRateLimitHeaders` from import (line 3), remove rate limit if-block

Also remove the `const ip = ...` line from each route where it was only used for rate limiting. If `ip` is not referenced anywhere else in the function after removing the rate-limit block, delete the ip assignment too.

**Update test files** to remove rate-limit mocking:
- `web/src/app/api/chat/route.test.ts` — remove the `checkRateLimit` mock from vi.mock("@/lib/rate-limit"...), remove `vi.mocked(checkRateLimit)` calls, remove the "returns 429 on rate limit" test case (or update it to test middleware behavior)
- `web/src/app/api/leads/route.test.ts` — same: remove checkRateLimit mock, vi.mocked calls, and 429 test case

**WEB-02: Add CSRF and auth to billing checkout route:**

In `web/src/app/api/billing/checkout/route.ts`:
- Add import: `import { verifyCsrfOrigin } from "@/lib/csrf";`
- Add import: `import { createServerSupabase } from "@/lib/supabase/server";`
- In the POST handler, before the JSON parse, add CSRF check:
  ```typescript
  if (!verifyCsrfOrigin(request)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }
  ```
- After CSRF check, add auth check:
  ```typescript
  const supabase = await createServerSupabase();
  if (!supabase) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }
  ```
  </action>
  <verify>
    <automated>cd web && npx tsc --noEmit && grep -rn "checkRateLimit" src/app/api/ --include="*.ts" | grep -v ".test.ts" | grep -v "node_modules" | wc -l | xargs test 0 -eq && echo "PASS: no legacy rate limit in routes"</automated>
  </verify>
  <done>Zero routes import checkRateLimit. Billing checkout has CSRF + auth guards. Test files updated to not mock removed functionality.</done>
</task>

<task type="auto">
  <name>Task 3: Wire NavAuthLinks into layout and track nav.ts</name>
  <files>web/src/app/layout.tsx</files>
  <action>
**AUTH-06: Replace static sign-in links with NavAuthLinks component:**

In `web/src/app/layout.tsx`:
1. Add import at top: `import NavAuthLinks from "./components/NavAuthLinks";`
2. Replace the static sign-in div (lines 91-94):
   ```tsx
   <div className="hidden lg:flex items-center gap-3 shrink-0">
     <a href="/login" className="text-sm font-bold text-[#F29E3D]">Sign In</a>
     <a href="/login" className="px-4 py-2 rounded-lg text-sm font-bold text-black" style={{ background: 'linear-gradient(90deg, #F29E3D, #FCC757)' }}>Get Started</a>
   </div>
   ```
   With:
   ```tsx
   <div className="hidden lg:flex items-center gap-3 shrink-0">
     <NavAuthLinks />
   </div>
   ```

This uses the existing NavAuthLinks component which captures the current URL for redirect-after-login, uses Next.js Link components, and is wrapped in Suspense.

**Track nav.ts:**
Run `git add web/src/lib/nav.ts` to ensure CI can find this file.
  </action>
  <verify>
    <automated>cd web && grep -q "NavAuthLinks" src/app/layout.tsx && echo "PASS: NavAuthLinks wired" && git ls-files --error-unmatch src/lib/nav.ts 2>/dev/null && echo "PASS: nav.ts tracked"</automated>
  </verify>
  <done>Layout imports and renders NavAuthLinks. nav.ts is git-tracked. Sign-in links now capture redirect URL.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client -> billing API | Untrusted input for payment checkout |
| client -> all mutation APIs | POST/PUT/DELETE from browser |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-quick-01 | Spoofing | billing/checkout POST | mitigate | Add verifyCsrfOrigin + auth.getUser() check before processing |
| T-quick-02 | Elevation of Privilege | billing/checkout | mitigate | Require authenticated user session before generating payment link |
| T-quick-03 | Denial of Service | all API routes | accept | Legacy per-route rate limiting removed; middleware-level rate limiting (Upstash) remains active |
</threat_model>

<verification>
```bash
# Full verification after all tasks
cd web && npm install && npx tsc --noEmit
cd web && npm test
cd web && grep -rn "checkRateLimit" src/app/api/ --include="*.ts" | grep -v ".test.ts" | wc -l  # expect 0
cd web && grep "NavAuthLinks" src/app/layout.tsx  # expect import + usage
git ls-files web/src/lib/nav.ts  # expect tracked
```
</verification>

<success_criteria>
- `npx tsc --noEmit` exits with 0 errors (all 37 TS errors resolved)
- No API route files (excluding tests) import `checkRateLimit`
- `billing/checkout/route.ts` includes `verifyCsrfOrigin` and auth check
- `layout.tsx` renders `NavAuthLinks` component
- `web/src/lib/nav.ts` is git-tracked
- `npm test` passes (test files updated for removed rate-limit mocks)
</success_criteria>

<output>
After completion, create `.planning/quick/260406-rcz-fix-all-8-partial-requirements-and-36-ts/260406-rcz-SUMMARY.md`
</output>
