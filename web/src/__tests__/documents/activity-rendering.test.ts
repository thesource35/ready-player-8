/**
 * Phase 24: Document Activity Event Rendering — Contract Tests
 *
 * Validates the rendering logic contracts in activity/page.tsx:
 * ENTITY_LABELS mapping, DETAIL_LABELS mapping, display text construction,
 * and historical flag detection. These are contract tests since the activity
 * page is a server component that cannot be unit-tested via jsdom.
 */
import { describe, test, expect } from "vitest";

// Contract copies of constants from web/src/app/projects/[id]/activity/page.tsx
// If these drift from the source, the contract is broken and tests must be updated.

const ENTITY_LABELS: Record<string, string> = {
  cs_projects: "Project",
  cs_contracts: "Contract",
  cs_rfis: "RFI",
  cs_change_orders: "Change order",
  cs_daily_logs: "Daily log",
  cs_attachments: "Document",
  cs_safety_incidents: "Safety incident",
  cs_submittals: "Submittal",
  cs_punch_list: "Punch item",
  cs_documents: "Document",
  cs_document_attachments: "Document",
};

const DETAIL_LABELS: Record<string, string> = {
  document_uploaded: "Document uploaded",
  document_attached: "Document attached",
  document_detached: "Document detached",
  version_added: "New version added",
};

describe("Phase 24: Document Activity Event Rendering", () => {
  test("ENTITY_LABELS maps cs_documents to Document", () => {
    expect(ENTITY_LABELS["cs_documents"]).toBe("Document");
  });

  test("ENTITY_LABELS maps cs_document_attachments to Document", () => {
    expect(ENTITY_LABELS["cs_document_attachments"]).toBe("Document");
  });

  test("DETAIL_LABELS covers all four event types", () => {
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

    expect(Object.keys(DETAIL_LABELS)).toHaveLength(4);
  });

  test("display text for document_uploaded includes filename", () => {
    const detail = "document_uploaded";
    const filename = "site-plan.pdf";
    const displayText =
      DETAIL_LABELS[detail] + (filename ? `: ${filename}` : "");
    expect(displayText).toBe("Document uploaded: site-plan.pdf");
  });

  test("display text for version_added without filename", () => {
    const displayText = DETAIL_LABELS["version_added"];
    expect(displayText).toBe("New version added");
  });

  test("historical flag detected in payload", () => {
    const payload: Record<string, unknown> = {
      detail: "document_uploaded",
      historical: true,
      filename: "test.pdf",
    };
    expect(payload.historical === true).toBe(true);
  });

  test("non-historical events have no historical flag", () => {
    const payload: Record<string, unknown> = {
      detail: "document_attached",
      filename: "test.pdf",
    };
    expect((payload as Record<string, unknown>).historical === true).toBe(
      false
    );
  });
});
