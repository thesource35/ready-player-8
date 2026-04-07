import { describe, it, expect } from "vitest";
import {
  validateDocumentUpload,
  ALLOWED_MIME,
  MAX_BYTES,
  isEntityType,
  ENTITY_TYPES,
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
