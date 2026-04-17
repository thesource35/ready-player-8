---
phase: 24-document-activity-event-emission
plan: 01
subsystem: database
tags: [postgres, triggers, plpgsql, activity-events, documents]

requires:
  - phase: 14-notifications-activity-feed
    provides: "cs_activity_events table, emit_activity_event() trigger pattern"
  - phase: 13-document-management
    provides: "cs_documents, cs_document_attachments tables, create_document_version() RPC"
provides:
  - "emit_document_activity_event() trigger function for document mutations"
  - "Triggers on cs_documents and cs_document_attachments emitting to cs_activity_events"
  - "Backfill of existing documents with historical:true flag"
  - "Version copy GUC guard in create_document_version() RPC"
  - "Payload contract tests for all four document event types"
affects: [24-02, 25-notifications, 28-verification-sweep]

tech-stack:
  added: []
  patterns:
    - "Separate trigger function per domain (emit_document_activity_event vs emit_activity_event)"
    - "GUC-based guard pattern (app.version_copy) for suppressing duplicate trigger events during RPC"
    - "Entity type whitelist for dynamic SQL defense-in-depth"

key-files:
  created:
    - supabase/migrations/20260417001_phase24_document_activity_triggers.sql
    - web/src/__tests__/documents/activity-emission.test.ts
  modified: []

key-decisions:
  - "Separate trigger function per D-03 — no modifications to existing emit_activity_event()"
  - "app.version_copy GUC guard suppresses duplicate attachment events during create_document_version() RPC"
  - "Backfill includes only is_current=true documents with NOT EXISTS idempotency guard"

patterns-established:
  - "GUC guard pattern: SET LOCAL app.{name} = 'on' to suppress triggers during RPC operations"
  - "Entity type whitelist before dynamic SQL format() calls"

requirements-completed: [DOC-02, NOTIF-02]

duration: 5min
completed: 2026-04-17
---

# Phase 24 Plan 01: Document Activity Event Emission Summary

**Postgres trigger function emit_document_activity_event() wired to cs_documents and cs_document_attachments with project_id resolution through junction table, version_copy GUC guard, and historical backfill**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-17T19:07:52Z
- **Completed:** 2026-04-17T19:13:11Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Created emit_document_activity_event() trigger function handling both cs_documents and cs_document_attachments with branch logic per table
- Implemented project_id resolution through cs_document_attachments junction table with entity_type whitelist for dynamic SQL safety (T-24-01)
- Added version_copy GUC guard to suppress duplicate attachment events during create_document_version() RPC
- Backfilled existing documents into cs_activity_events with historical:true flag and original timestamps
- 6 vitest tests validating payload contract for all four event types (document_uploaded, document_attached, document_detached, version_added)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create emit_document_activity_event() trigger function and attach to both tables** - `0dc03e9` (feat)
2. **Task 2: Backfill existing documents and create emission tests** - `88cf752` (test)

## Files Created/Modified
- `supabase/migrations/20260417001_phase24_document_activity_triggers.sql` - Trigger function, RPC update, trigger attachments, backfill DO block
- `web/src/__tests__/documents/activity-emission.test.ts` - 6 payload contract tests for document activity events

## Decisions Made
- Separate trigger function (D-03): emit_document_activity_event() is completely independent from emit_activity_event()
- Version copy guard: SET LOCAL app.version_copy = 'on' in create_document_version() RPC prevents duplicate document_attached events when copying attachments to new versions
- Backfill scope: Only is_current=true documents backfilled (one event per version chain), with NOT EXISTS guard for idempotent re-runs
- Non-project entity resolution: Backfill uses NULL project_id for non-project attachments (avoids complex dynamic SQL in batch context); live triggers resolve fully

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Migration ready for `supabase db push`
- Plan 02 (activity feed rendering) can now add ENTITY_LABELS entries for cs_documents/cs_document_attachments and DETAIL_LABELS rendering
- INT-02 closure depends on this migration being applied to the remote database

---
*Phase: 24-document-activity-event-emission*
*Completed: 2026-04-17*
