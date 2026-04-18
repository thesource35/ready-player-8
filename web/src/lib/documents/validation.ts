export const ALLOWED_MIME = new Set([
  "application/pdf",
  "image/png",
  "image/jpeg",
  "image/heic",
  "image/webp",
]);
export const MAX_BYTES = 50 * 1024 * 1024; // 52428800

export type ValidationResult =
  | { ok: true }
  | { ok: false; status: number; error: string };

export function validateDocumentUpload(input: {
  size: number;
  mimeType: string;
}): ValidationResult {
  if (input.size === 0) return { ok: false, status: 400, error: "Empty file" };
  if (input.size > MAX_BYTES)
    return { ok: false, status: 413, error: "File exceeds 50 MB" };
  if (!ALLOWED_MIME.has(input.mimeType)) {
    return {
      ok: false,
      status: 415,
      error: `Unsupported type ${input.mimeType}`,
    };
  }
  return { ok: true };
}

// Canonical entity types for document attachments. Raw values MUST match
// the Postgres `cs_document_entity_type` enum (see migration 20260408004
// which added daily_log / safety_incident / punch_item for Phase 16).
// Source of truth: DB enum. This array mirrors that enum for client-side
// validation. Drift is caught by validation.test.ts drift guard (D-11).
export const ENTITY_TYPES = [
  "project",
  "rfi",
  "submittal",
  "change_order",
  "daily_log",
  "safety_incident",
  "punch_item",
] as const;
export type DocumentEntityType = (typeof ENTITY_TYPES)[number];

export function isEntityType(v: unknown): v is DocumentEntityType {
  return (
    typeof v === "string" && (ENTITY_TYPES as readonly string[]).includes(v)
  );
}

// Hard-coded map of entity_type -> backing table name. NEVER computed from
// user input — prevents SQL-injection-shaped misuse of the pre-flight
// existence check (T-26-SQLI mitigation).
export const ENTITY_TABLE_MAP: Record<DocumentEntityType, string> = {
  project: "cs_projects",
  rfi: "cs_rfis",
  submittal: "cs_submittals",
  change_order: "cs_change_orders",
  daily_log: "cs_daily_logs",
  safety_incident: "cs_safety_incidents",
  punch_item: "cs_punch_items",
};
