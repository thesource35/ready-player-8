"use server";

// Phase 16 FIELD-02: Server Actions wrapping field attachment lib helpers.
//
// NOTE: Server Actions MUST return plain serializable objects — NextResponse
// is Route-Handler-only. We return the same discriminated-union
// AttachmentResult shape the lib exposes so callers can branch on .ok.

import {
  attachPhoto as libAttachPhoto,
  detachPhoto as libDetachPhoto,
  listAttachmentsForEntity as libListAttachmentsForEntity,
  type AttachmentResult,
} from "@/lib/field/attachments";

export async function attachPhoto(
  documentId: string,
  entityType: string,
  entityId: string
): Promise<AttachmentResult> {
  return libAttachPhoto(documentId, entityType, entityId);
}

export async function detachPhoto(
  documentId: string,
  entityType: string,
  entityId: string
): Promise<AttachmentResult> {
  return libDetachPhoto(documentId, entityType, entityId);
}

export async function listAttachmentsForEntity(
  entityType: string,
  entityId: string
): Promise<AttachmentResult> {
  return libListAttachmentsForEntity(entityType, entityId);
}
