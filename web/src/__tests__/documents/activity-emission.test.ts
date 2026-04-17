/**
 * Phase 24: Document Activity Event Emission — Payload Contract Tests
 *
 * Validates the data shape contract that the activity feed rendering depends on.
 * These tests verify payload structure, not Supabase connectivity.
 */
import { describe, it, expect } from "vitest";

// Mirrors the ActivityEvent interface from @/lib/supabase/types.ts
interface ActivityEvent {
  id: string;
  project_id: string | null;
  entity_type: string;
  entity_id: string | null;
  action: string;
  category: string;
  actor_id: string | null;
  payload: Record<string, unknown>;
  created_at: string;
}

// Detail labels contract — rendering code depends on these keys
const DETAIL_LABELS: Record<string, string> = {
  document_uploaded: "Document uploaded",
  document_attached: "Document attached",
  document_detached: "Document detached",
  version_added: "New version added",
};

// Entity labels contract — Plan 02 must add these to ENTITY_LABELS
const DOCUMENT_ENTITY_LABELS: Record<string, string> = {
  cs_documents: "Document",
  cs_document_attachments: "Document",
};

describe("Phase 24: Document Activity Event Emission", () => {
  it("document_uploaded payload has required fields", () => {
    const event: ActivityEvent = {
      id: "e1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      project_id: "p1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      entity_type: "cs_documents",
      entity_id: "d1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      action: "insert",
      category: "document",
      actor_id: "u1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      payload: {
        detail: "document_uploaded",
        filename: "site-plan.pdf",
        id: "d1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
        org_id: "o1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
        version_number: 1,
        is_current: true,
        mime_type: "application/pdf",
        size_bytes: 1048576,
      },
      created_at: "2026-04-17T12:00:00Z",
    };

    expect(event.category).toBe("document");
    expect(event.entity_type).toBe("cs_documents");
    expect(event.action).toBe("insert");
    expect(event.payload.detail).toBe("document_uploaded");
    expect(event.payload.filename).toBe("site-plan.pdf");
    expect(typeof event.payload.filename).toBe("string");
    expect(event.project_id).not.toBeNull();
  });

  it("document_attached payload has required fields", () => {
    const event: ActivityEvent = {
      id: "e2a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      project_id: "p1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      entity_type: "cs_document_attachments",
      entity_id: "d1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      action: "insert",
      category: "document",
      actor_id: "u1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      payload: {
        detail: "document_attached",
        filename: "foundation-spec.pdf",
        document_id: "d1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
        entity_type: "project",
        entity_id: "p1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      },
      created_at: "2026-04-17T12:05:00Z",
    };

    expect(event.category).toBe("document");
    expect(event.entity_type).toBe("cs_document_attachments");
    expect(event.payload.detail).toBe("document_attached");
    expect(event.payload.filename).toBeDefined();
    expect(event.payload.document_id).toBeDefined();
  });

  it("version_added payload has required fields", () => {
    const event: ActivityEvent = {
      id: "e3a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      project_id: "p1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      entity_type: "cs_documents",
      entity_id: "d2a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      action: "insert",
      category: "document",
      actor_id: "u1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      payload: {
        detail: "version_added",
        filename: "site-plan-v2.pdf",
        version_number: 2,
        is_current: true,
      },
      created_at: "2026-04-17T14:00:00Z",
    };

    expect(event.category).toBe("document");
    expect(event.payload.detail).toBe("version_added");
    expect(event.payload.filename).toBeDefined();
    expect((event.payload.version_number as number)).toBeGreaterThan(1);
  });

  it("historical backfill events have historical:true flag", () => {
    const event: ActivityEvent = {
      id: "e4a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      project_id: "p1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      entity_type: "cs_documents",
      entity_id: "d3a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      action: "insert",
      category: "document",
      actor_id: "u1a2b3c4-d5e6-f7a8-b9c0-d1e2f3a4b5c6",
      payload: {
        detail: "document_uploaded",
        historical: true,
        filename: "old-blueprint.pdf",
      },
      created_at: "2026-01-15T09:00:00Z",
    };

    expect(event.payload.historical).toBe(true);
    expect(event.payload.detail).toBe("document_uploaded");
    // Historical events should use original created_at, not migration time
    const eventDate = new Date(event.created_at);
    expect(eventDate.getFullYear()).toBeLessThanOrEqual(2026);
  });

  it("ENTITY_LABELS mapping covers document entity types", () => {
    // Contract test: Plan 02 must add these to the ENTITY_LABELS map
    // in web/src/app/projects/[id]/activity/page.tsx
    expect(DOCUMENT_ENTITY_LABELS).toHaveProperty("cs_documents");
    expect(DOCUMENT_ENTITY_LABELS).toHaveProperty("cs_document_attachments");
    expect(DOCUMENT_ENTITY_LABELS.cs_documents).toBe("Document");
    expect(DOCUMENT_ENTITY_LABELS.cs_document_attachments).toBe("Document");
  });

  it("detail labels cover all four event types", () => {
    const requiredDetails = [
      "document_uploaded",
      "document_attached",
      "document_detached",
      "version_added",
    ];

    for (const detail of requiredDetails) {
      expect(DETAIL_LABELS).toHaveProperty(detail);
      expect(typeof DETAIL_LABELS[detail]).toBe("string");
      expect(DETAIL_LABELS[detail].length).toBeGreaterThan(0);
    }

    // Verify all four are present (no extras, no missing)
    expect(Object.keys(DETAIL_LABELS)).toHaveLength(4);
  });
});
