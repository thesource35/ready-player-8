---
phase: 09-web-performance-dynamic-content
plan: 05
subsystem: web-api-pagination
tags: [pagination, load-more, api, performance]
dependency_graph:
  requires: [09-02]
  provides: [paginated-api-responses, load-more-ui]
  affects: [projects, contracts, punch, feed, tasks, ops]
tech_stack:
  added: []
  patterns: [fetchTablePaginated, load-more-append, paginated-response-shape]
key_files:
  created: []
  modified:
    - web/src/app/api/projects/route.ts
    - web/src/app/api/contracts/route.ts
    - web/src/app/api/punch/route.ts
    - web/src/app/api/feed/route.ts
    - web/src/app/api/tasks/route.ts
    - web/src/app/api/ops/route.ts
    - web/src/app/projects/page.tsx
    - web/src/app/contracts/page.tsx
    - web/src/app/punch/page.tsx
    - web/src/app/feed/page.tsx
    - web/src/app/tasks/page.tsx
    - web/src/app/ops/page.tsx
decisions:
  - Multi-table routes (tasks, ops) paginate the primary table only (todos, alerts)
  - Feed page Load More button placed inside Feed tab only (not Jobs/Market/DMs/Companies tabs)
metrics:
  duration: ~53 minutes
  completed: 2026-04-06
---

# Phase 09 Plan 05: Wire Pagination to API Routes and Client Pages Summary

Wired fetchTablePaginated into all 6 API GET routes with page query param, and added "Load More" append-style buttons to all 6 client pages.

## What Was Done

### Task 1: Add pagination to all 6 API GET route handlers (0caf32e)

Updated all 6 API route GET handlers to use `fetchTablePaginated` instead of `fetchTable`:

- **projects, contracts, punch, feed**: Direct replacement -- single-table routes now accept `?page=N` and return `{ data, hasMore, total }` shape
- **tasks**: Multi-table route -- paginated `cs_todos` via fetchTablePaginated, kept `cs_schedule_events` and `cs_reminders` as full fetches, added `hasMore` and `total` to the response envelope
- **ops**: Multi-table route -- paginated `cs_ops_alerts` via fetchTablePaginated, kept `cs_rfis` and `cs_change_orders` as full fetches, added `hasMore` and `total` to the response envelope

Page parameter parsed with `Math.max(0, ...)` to prevent negative offsets (T-09-13 mitigation). Page size fixed at 25 server-side, not client-controllable. Mock data fallback preserved for page 0 when Supabase returns empty.

POST, DELETE, and PATCH handlers in all routes were left completely unchanged.

### Task 2: Add "Load More" buttons to all 6 client pages (69bb164)

Added pagination state (`page`, `hasMore`, `loadingMore`) and `loadMore` function to all 6 client pages:

- **projects, contracts, punch, feed**: Updated initial `useEffect` fetch to handle new `{ data, hasMore, total }` response shape with backward compatibility for plain arrays. Added `loadMore` async function that fetches next page and appends results.
- **tasks**: Load More within Tasks tab (activeTab === 0), paginating todos list
- **ops**: Load More after Priority Alerts section, paginating alerts list
- **feed**: Load More within Feed tab (activeTab === 0), paginating posts list

Each page extracted a `map*` helper function (mapProject, mapContract, mapPunchItem, mapPost, mapTodo, mapAlert) to deduplicate mapping logic between initial load and loadMore.

Load More button styled consistently: amber accent background, dark text, 8px border radius, disabled state with 0.6 opacity and "Loading..." text.

## Deviations from Plan

None -- plan executed exactly as written.

## Decisions Made

1. **Multi-table routes paginate primary table only**: Tasks route paginates `cs_todos` while events and reminders load fully. Ops route paginates `cs_ops_alerts` while RFIs and change orders load fully. This is practical since these secondary tables have fewer rows and are displayed in separate sections.
2. **Feed Load More scoped to Feed tab**: The feed page has 5 tabs (Feed, Jobs, Market, DMs, Companies). Load More only appears in the Feed tab since only feed posts come from the paginated API.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 0caf32e | feat(09-05): add pagination to all 6 API GET route handlers |
| 2 | 69bb164 | feat(09-05): add Load More buttons to all 6 client pages |

## Verification

- All 6 API routes contain `fetchTablePaginated` import and usage
- All 6 API routes parse `page` query param and return `{ data, hasMore, total }` shape
- All 6 client pages contain "Load More" button text
- All 6 client pages have `hasMore`, `loadMore`, `loadingMore` state/handlers
- TypeScript check confirms no new errors introduced (all errors are pre-existing)
- Mock data fallback still works on page 0

## Self-Check: PASSED

All 12 modified files confirmed present on disk. Both commit hashes (0caf32e, 69bb164) confirmed in git log.
