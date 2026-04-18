import { describe, it, expect } from "vitest";
import {
  validateDocumentUpload,
  ALLOWED_MIME,
  MAX_BYTES,
  isEntityType,
  ENTITY_TYPES,
  ENTITY_TABLE_MAP,
} from "./validation";

describe("validateDocumentUpload", () => {
  it("accepts a 1-byte allowed file", () => {
    expect(validateDocumentUpload({ size: 1, mimeType: "application/pdf" })).toEqual({
      ok: true,
    });
  });

  it("accepts a file at exactly MAX_BYTES", () => {
    expect(
      validateDocumentUpload({ size: MAX_BYTES, mimeType: "image/png" })
    ).toEqual({ ok: true });
  });

  it("rejects empty file with 400", () => {
    const r = validateDocumentUpload({ size: 0, mimeType: "application/pdf" });
    expect(r).toEqual({ ok: false, status: 400, error: "Empty file" });
  });

  it("rejects oversized file with 413", () => {
    const r = validateDocumentUpload({
      size: MAX_BYTES + 1,
      mimeType: "application/pdf",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.status).toBe(413);
      expect(r.error).toBe("File exceeds 50 MB");
    }
  });

  it("rejects disallowed MIME with 415", () => {
    const r = validateDocumentUpload({
      size: 100,
      mimeType: "application/x-msdownload",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.status).toBe(415);
      expect(r.error).toMatch(/Unsupported type/);
    }
  });

  it("accepts heic", () => {
    expect(
      validateDocumentUpload({ size: 100, mimeType: "image/heic" })
    ).toEqual({ ok: true });
  });
});

describe("ALLOWED_MIME", () => {
  it("contains exactly the documented types", () => {
    expect(Array.from(ALLOWED_MIME).sort()).toEqual(
      [
        "application/pdf",
        "image/heic",
        "image/jpeg",
        "image/png",
        "image/webp",
      ].sort()
    );
  });
});

describe("MAX_BYTES", () => {
  it("is 52428800", () => {
    expect(MAX_BYTES).toBe(52428800);
  });
});

describe("isEntityType", () => {
  it("accepts valid entity types", () => {
    for (const t of ENTITY_TYPES) {
      expect(isEntityType(t)).toBe(true);
    }
  });
  it("rejects invalid", () => {
    expect(isEntityType("nope")).toBe(false);
    expect(isEntityType(42)).toBe(false);
    expect(isEntityType(undefined)).toBe(false);
  });
});

describe("ENTITY_TYPES drift guard (D-11)", () => {
  it("contains exactly 7 values in canonical order", () => {
    expect(ENTITY_TYPES.length).toBe(7);
    expect([...ENTITY_TYPES]).toEqual([
      "project",
      "rfi",
      "submittal",
      "change_order",
      "daily_log",
      "safety_incident",
      "punch_item",
    ]);
  });
  it("accepts all 3 Phase 16 enum extensions", () => {
    expect(isEntityType("daily_log")).toBe(true);
    expect(isEntityType("safety_incident")).toBe(true);
    expect(isEntityType("punch_item")).toBe(true);
  });
});

describe("ENTITY_TABLE_MAP (pre-flight target tables)", () => {
  it("maps every entity type to a concrete cs_ table", () => {
    for (const t of ENTITY_TYPES) {
      const table = ENTITY_TABLE_MAP[t];
      expect(table).toMatch(/^cs_[a-z_]+$/);
    }
  });
  it("covers every entity type (no gaps)", () => {
    const keys = Object.keys(ENTITY_TABLE_MAP).sort();
    expect(keys).toEqual([...ENTITY_TYPES].sort());
  });
  it("specifically maps new Phase 16/26 types", () => {
    expect(ENTITY_TABLE_MAP.daily_log).toBe("cs_daily_logs");
    expect(ENTITY_TABLE_MAP.safety_incident).toBe("cs_safety_incidents");
    expect(ENTITY_TABLE_MAP.punch_item).toBe("cs_punch_items");
    expect(ENTITY_TABLE_MAP.rfi).toBe("cs_rfis");
    expect(ENTITY_TABLE_MAP.submittal).toBe("cs_submittals");
    expect(ENTITY_TABLE_MAP.change_order).toBe("cs_change_orders");
    expect(ENTITY_TABLE_MAP.project).toBe("cs_projects");
  });
});
