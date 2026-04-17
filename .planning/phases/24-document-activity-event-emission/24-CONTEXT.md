# Phase 24: Document → Activity Event Emission - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Every document mutation emits a row into `cs_activity_events` so the activity feed populates for document ops. Closes INT-02 and FLOW-01. Covers both `cs_documents` (upload, version) and `cs_document_attachments` (attach, detach) tables. No new UI pages — only trigger functions, a migration, a backfill script, and minor activity feed rendering updates.

</domain>

<decisions>
## Implementation Decisions

### Emission mechanism
- **D-01:** Trigger on both `cs_document_attachments` AND `cs_documents`. Attachments emit for attach/detach events; documents emit for upload/version events. The `cs_documents` trigger JOINs through `cs_document_attachments` to resolve `project_id` — if no attachment exists yet, skip emission silently.
- **D-02:** iOS gets event emission for free — SupabaseService inserts into these tables directly, so the Postgres trigger fires automatically. Zero iOS code changes needed.

### Trigger function
- **D-03:** Create a NEW trigger function `emit_document_activity_event()` separate from the existing `emit_activity_event()`. The document function handles the JOIN logic to resolve project_id through cs_document_attachments. Keeps existing 5-table trigger untouched — no risk to cs_projects, cs_contracts, etc.

### Event granularity
- **D-04:** Hybrid action model — `action` column uses standard TG_OP values (INSERT/UPDATE/DELETE) for schema consistency. The `payload` JSON includes a `detail` key with semantic meaning: `'document_uploaded'`, `'document_attached'`, `'document_detached'`, `'version_added'`.
- **D-05:** New `'document'` category (not `'generic'`). Enables future notification preference filtering — users can opt in/out of document notifications independently.

### Backfill strategy
- **D-06:** Backfill existing documents with a `'historical': true` flag in the payload. Use `cs_documents.created_at` as the event timestamp so the activity feed shows complete history. The UI can distinguish real-time events from backfilled ones via the historical flag.

### Activity feed display
- **D-07:** Document events in the web activity feed show a document icon (📄) and semantic label from `payload.detail` (e.g., "Document uploaded: site-plan.pdf"). Uses the hybrid action+detail from D-04. Historical events may optionally show a subtle "historical" badge.

### Claude's Discretion
- Exact SQL JOIN strategy in the trigger function (subquery vs LEFT JOIN)
- Backfill script error handling and batch size
- Historical badge styling in the activity feed (subtle or omitted)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Activity event infrastructure
- `supabase/migrations/20260407_phase14_notifications.sql` — Defines `emit_activity_event()` trigger function, `cs_activity_events` table schema (project_id, entity_type, entity_id, action, category, actor_id, payload), and trigger attachment to 5 tables
- `supabase/migrations/20260407001_phase14_notifications_rls.sql` — RLS policies for cs_activity_events

### Document schema
- `supabase/migrations/20260406_documents.sql` — `cs_documents` table (id, org_id, version_chain_id, version_number, is_current, filename, mime_type, size_bytes, storage_path, uploaded_by, created_at) and `cs_document_attachments` junction table (document_id, entity_type, entity_id)
- `supabase/migrations/20260406001_documents_rls.sql` — RLS policies for document tables

### Activity feed consumer
- `web/src/lib/notifications.ts` §fetchProjectActivity — Reads cs_activity_events for a project, returns ActivityEvent[]
- `web/src/app/projects/[id]/activity/page.tsx` — Web activity feed page that renders events

### Document API routes
- `web/src/app/api/documents/upload/route.ts` — Upload endpoint
- `web/src/app/api/documents/attach/route.ts` — Attach endpoint
- `web/src/app/api/documents/[id]/versions/route.ts` — Version endpoint

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `emit_activity_event()` function: Template for the new document-specific trigger. Same INSERT pattern into `cs_activity_events` with project_id, entity_type, entity_id, action, category, actor_id, payload.
- `fetchProjectActivity()` in `web/src/lib/notifications.ts`: Already reads all cs_activity_events for a project — no query changes needed, just rendering.

### Established Patterns
- Trigger-based emission: All activity events come from Postgres triggers, not application code. The new document triggers follow the same pattern.
- Category-based routing: `category` field drives NOTIF-05 push decisions. New `'document'` category extends this system.
- `v_action` from `TG_OP`: Existing trigger maps INSERT→INSERT, UPDATE→UPDATE, DELETE→DELETE.

### Integration Points
- `cs_document_attachments.entity_id` → resolves to a project (entity_type = 'project') or to an entity within a project (rfi, submittal, change_order). The JOIN must handle both cases.
- `web/src/app/projects/[id]/activity/page.tsx` — Rendering logic needs to handle the new `detail` payload key for document-specific display.
- iOS DocumentSyncManager — No changes needed (triggers fire automatically on Supabase INSERT).

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches within the decisions above.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 24-document-activity-event-emission*
*Context gathered: 2026-04-17*
