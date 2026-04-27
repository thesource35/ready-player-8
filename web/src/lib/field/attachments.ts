// 999.5 follow-up: server-only marker (uses createServerSupabase).
import "server-only";

// Phase 16 FIELD-02: DB helpers for cs_document_attachments with field entity types.
//
// Ground-truth schema notes (see supabase/migrations/20260406_documents.sql and
// 20260408004_phase16_extend_entity_type_enum.sql):
//   - cs_document_attachments has NO attachment_id. Composite PK:
//       (document_id, entity_type, entity_id).
//   - entity_type is enum cs_document_entity_type with values:
//       project | rfi | submittal | change_order | daily_log |
//       safety_incident | punch_item
//   - RLS on insert returns PostgrestError.code === '42501' on denial.
//
// This module is the single source of truth for web-side attach/detach/list.
// It returns a discriminated-union result shape so both Server Actions and
// Route Handlers can consume it cleanly (Server Actions cannot return
// NextResponse directly).

import { createServerSupabase } from "@/lib/supabase/server";

export const FIELD_ENTITY_TYPES = [
  "project",
  "rfi",
  "submittal",
  "change_order",
  "daily_log",
  "safety_incident",
  "punch_item",
] as const;

export type FieldEntityType = (typeof FIELD_ENTITY_TYPES)[number];

export function isFieldEntityType(v: unknown): v is FieldEntityType {
  return (
    typeof v === "string" &&
    (FIELD_ENTITY_TYPES as readonly string[]).includes(v)
  );
}

// Hand-rolled UUID v1–v5 check (zod is not a dependency in web/).
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isUuid(v: unknown): v is string {
  return typeof v === "string" && UUID_RE.test(v);
}

export type AttachmentResult =
  | { ok: true; data?: unknown }
  | { ok: false; status: number; error: string };

function mapPostgrestError(code: string | undefined): number {
  if (code === "42501") return 403; // RLS denial
  if (code === "23505") return 409; // unique violation (already attached)
  if (code === "23503") return 400; // FK violation (bad ids)
  return 500;
}

export async function attachPhoto(
  documentId: unknown,
  entityType: unknown,
  entityId: unknown
): Promise<AttachmentResult> {
  if (!isUuid(documentId)) {
    return { ok: false, status: 400, error: "Invalid document_id" };
  }
  if (!isFieldEntityType(entityType)) {
    return { ok: false, status: 400, error: "Invalid entity_type" };
  }
  if (!isUuid(entityId)) {
    return { ok: false, status: 400, error: "Invalid entity_id" };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, status: 500, error: "Supabase not configured" };
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, status: 401, error: "Unauthorized" };
  }

  const { error } = await supabase.from("cs_document_attachments").insert({
    document_id: documentId,
    entity_type: entityType,
    entity_id: entityId,
  });

  if (error) {
    const status = mapPostgrestError((error as { code?: string }).code);
    console.error("[field/attachments] insert failed:", error.message);
    return { ok: false, status, error: error.message };
  }

  return { ok: true };
}

// cs_document_attachments has no surrogate attachment_id — deletion is by
// composite key. Plan signature has been corrected here.
export async function detachPhoto(
  documentId: unknown,
  entityType: unknown,
  entityId: unknown
): Promise<AttachmentResult> {
  if (!isUuid(documentId)) {
    return { ok: false, status: 400, error: "Invalid document_id" };
  }
  if (!isFieldEntityType(entityType)) {
    return { ok: false, status: 400, error: "Invalid entity_type" };
  }
  if (!isUuid(entityId)) {
    return { ok: false, status: 400, error: "Invalid entity_id" };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, status: 500, error: "Supabase not configured" };
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { ok: false, status: 401, error: "Unauthorized" };
  }

  const { error } = await supabase
    .from("cs_document_attachments")
    .delete()
    .eq("document_id", documentId)
    .eq("entity_type", entityType)
    .eq("entity_id", entityId);

  if (error) {
    const status = mapPostgrestError((error as { code?: string }).code);
    console.error("[field/attachments] delete failed:", error.message);
    return { ok: false, status, error: error.message };
  }

  return { ok: true };
}

export async function listAttachmentsForEntity(
  entityType: unknown,
  entityId: unknown
): Promise<AttachmentResult> {
  if (!isFieldEntityType(entityType)) {
    return { ok: false, status: 400, error: "Invalid entity_type" };
  }
  if (!isUuid(entityId)) {
    return { ok: false, status: 400, error: "Invalid entity_id" };
  }

  const supabase = await createServerSupabase();
  if (!supabase) {
    return { ok: false, status: 500, error: "Supabase not configured" };
  }

  const { data, error } = await supabase
    .from("cs_document_attachments")
    .select("document_id, entity_type, entity_id, created_at")
    .eq("entity_type", entityType)
    .eq("entity_id", entityId);

  if (error) {
    const status = mapPostgrestError((error as { code?: string }).code);
    console.error("[field/attachments] list failed:", error.message);
    return { ok: false, status, error: error.message };
  }

  return { ok: true, data: data ?? [] };
}
