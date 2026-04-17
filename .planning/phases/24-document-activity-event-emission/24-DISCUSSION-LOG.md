# Phase 24: Document → Activity Event Emission - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 24-document-activity-event-emission
**Areas discussed:** Emission mechanism, Event granularity, iOS emission parity, Migration approach, Backfill strategy, Activity feed display

---

## Emission Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Trigger with JOIN | Attach trigger to cs_document_attachments (not cs_documents). Orphan docs won't emit until attached. | ✓ |
| App-level INSERT in API routes | Each web API route manually inserts into cs_activity_events. Breaks trigger pattern. | |
| Add project_id to cs_documents | Denormalize: add project_id column. Requires migration + backfill. | |

**User's choice:** Trigger with JOIN
**Notes:** Keeps established Phase 14 trigger pattern. Orphan docs correctly excluded.

### Follow-up: Trigger on cs_documents too?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, trigger on both tables | cs_document_attachments for attach/detach, cs_documents for upload/version. JOIN to resolve project_id. | ✓ |
| Only cs_document_attachments | Simpler but new versions won't appear in feed. | |

**User's choice:** Yes, trigger on both tables

---

## Event Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Semantic actions | Use descriptive actions: 'document_uploaded', 'document_attached', etc. | |
| Match existing (INSERT/UPDATE/DELETE) | Same coarse actions as other tables. Consistent but less informative. | |
| Hybrid | TG_OP as action + 'detail' key in payload JSON with semantic meaning. | ✓ |

**User's choice:** Hybrid
**Notes:** Schema consistency via TG_OP + semantic richness via payload.detail.

### Follow-up: Category value?

| Option | Description | Selected |
|--------|-------------|----------|
| New 'document' category | Enables separate notification filtering for document events. | ✓ |
| Use 'generic' | Simpler but no filtering granularity. | |

**User's choice:** New 'document' category

---

## iOS Emission Parity

| Option | Description | Selected |
|--------|-------------|----------|
| Trigger handles it | iOS inserts into same tables — triggers fire automatically. Zero code changes. | ✓ |
| Add iOS toast on emission | Show confirmation toast. Adds UI complexity. | |

**User's choice:** Trigger handles it
**Notes:** Trigger-based approach means both platforms get emission automatically.

---

## Migration Approach

| Option | Description | Selected |
|--------|-------------|----------|
| New function for docs | Create emit_document_activity_event() separate from existing function. No risk to existing 5 tables. | ✓ |
| Extend existing function | Add conditional branch for document tables. Riskier. | |

**User's choice:** New function for docs

---

## Backfill Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Forward-only | Only new operations emit. Simpler but incomplete history. | |
| Backfill with original timestamps | Use created_at as event timestamp. Complete but no way to distinguish. | |
| Backfill with 'historical' flag | Backfill + historical: true in payload. UI can distinguish. | ✓ |

**User's choice:** Backfill with 'historical' flag
**Notes:** Most accurate representation — complete history with clear distinction between real-time and backfilled events.

---

## Activity Feed Display

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + semantic label | Document icon (📄) + label from payload.detail. | ✓ |
| Same as other events | Generic rendering. Consistent but less informative. | |
| You decide | Claude picks during implementation. | |

**User's choice:** Icon + semantic label

---

## Claude's Discretion

- SQL JOIN strategy in trigger function
- Backfill script error handling and batch size
- Historical badge styling

## Deferred Ideas

None — discussion stayed within phase scope.
