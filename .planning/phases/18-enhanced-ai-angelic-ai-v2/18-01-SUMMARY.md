---
phase: 18-enhanced-ai-angelic-ai-v2
plan: 01
subsystem: api
tags: [ai-sdk, tool-calling, supabase, zod, streamText, vitest]

requires:
  - phase: 18-enhanced-ai-angelic-ai-v2
    provides: Failing test stubs for AI tools (plan 18-00)
provides:
  - Construction tool definitions for AI SDK (createConstructionTools)
  - Multi-step tool calling in web chat route with stopWhen: stepCountIs(5)
  - Live Supabase data fetching via AI tools (projects, contracts, RFIs, change orders, punch list, daily logs)
  - Document generation tools (RFI draft, change order draft) with DRAFT-only output
  - Bid analysis tool cross-referencing contract and market data
affects: [18-02-ios-tool-calling, 18-03-ios-mcp-tools]

tech-stack:
  added: []
  patterns: [AI SDK tool() with inputSchema (Zod), stepCountIs for multi-step limit, DRAFT-only document generation]

key-files:
  created:
    - web/src/app/api/chat/tools.ts
  modified:
    - web/src/app/api/chat/route.ts
    - web/src/app/api/chat/route.test.ts
    - web/src/app/api/chat/__tests__/tools.test.ts

key-decisions:
  - "Input validation on generate_rfi (subject) and draft_change_order (description) to return errors on empty strings"
  - "runTool test helper to satisfy AI SDK v6 two-argument execute type signature"

patterns-established:
  - "AI tool pattern: tool({ description, inputSchema: z.object(...), execute }) with null-supabase guard"
  - "DRAFT-only document generation: tools return JSON with _action: review_before_saving, never insert into DB"
  - "Multi-step tool calling: stopWhen: stepCountIs(5) limits tool loop rounds"

requirements-completed: [AI-01, AI-02, AI-03, AI-04]

duration: 8min
completed: 2026-04-11
---

# Phase 18 Plan 01: Web AI Tools Summary

**10 AI SDK tool definitions (data query, RFI draft, CO draft, bid analysis) with multi-step tool calling in web chat route**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-11T06:45:08Z
- **Completed:** 2026-04-11T06:53:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Created tools.ts with 10 tool definitions covering AI-01 (7 data query tools), AI-02 (RFI draft), AI-03 (CO draft), AI-04 (bid analysis)
- Updated chat route to use tool calling with stopWhen: stepCountIs(5) for multi-step AI rounds
- All 15 tests pass (9 tool tests + 6 route tests), TypeScript clean, build succeeds

## Task Commits

Each task was committed atomically:

1. **Task 1: Create construction tools module with Supabase-backed tool definitions** - `679a8eb` (feat)
2. **Task 2: Update chat route.ts to use tools with multi-step calling** - `0df1e5b` (feat)

## Files Created/Modified
- `web/src/app/api/chat/tools.ts` - 10 AI SDK tool definitions with Zod inputSchema, null-supabase guards, and try/catch error handling
- `web/src/app/api/chat/route.ts` - Integrated tool calling with stepCountIs(5), updated system prompt, removed static data summary counts
- `web/src/app/api/chat/route.test.ts` - Added tool and stepCountIs to ai mock exports
- `web/src/app/api/chat/__tests__/tools.test.ts` - Added runTool helper for AI SDK v6 type compatibility

## Decisions Made
- Added input validation (empty string checks) on generate_rfi subject and draft_change_order description fields for correctness
- Created runTool test helper to satisfy AI SDK v6 two-argument execute() type signature without changing test logic

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed route.test.ts mock missing tool and stepCountIs exports**
- **Found during:** Task 2 (route update)
- **Issue:** Existing route.test.ts mocked `ai` module without `tool` or `stepCountIs` exports, causing 2 test failures
- **Fix:** Added `tool: vi.fn().mockImplementation((def) => def)` and `stepCountIs: vi.fn()` to the ai mock
- **Files modified:** web/src/app/api/chat/route.test.ts
- **Verification:** All 6 route tests pass
- **Committed in:** 0df1e5b (Task 2 commit)

**2. [Rule 3 - Blocking] Fixed tools.test.ts TypeScript errors from AI SDK v6 execute signature**
- **Found during:** Task 2 (verification)
- **Issue:** AI SDK v6 tool().execute requires 2 arguments at type level; tests only passed 1, causing tsc --noEmit failures
- **Fix:** Added runTool helper that passes stub options as second argument, replaced all direct .execute() calls
- **Files modified:** web/src/app/api/chat/__tests__/tools.test.ts
- **Verification:** npx tsc --noEmit passes with zero errors
- **Committed in:** 0df1e5b (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary for test and type-check compliance. No scope creep.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Web AI tool calling complete and verified
- Ready for Plan 18-02 (iOS tool calling) and Plan 18-03 (iOS MCP tools)
- No blockers

## Self-Check: PASSED

- [x] web/src/app/api/chat/tools.ts exists
- [x] web/src/app/api/chat/route.ts exists
- [x] Commit 679a8eb exists in git log
- [x] Commit 0df1e5b exists in git log

---
*Phase: 18-enhanced-ai-angelic-ai-v2*
*Completed: 2026-04-11*
