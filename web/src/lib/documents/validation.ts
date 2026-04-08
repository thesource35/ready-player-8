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

export const ENTITY_TYPES = [
  "project",
  "rfi",
  "submittal",
  "change_order",
] as const;
export type DocumentEntityType = (typeof ENTITY_TYPES)[number];

export function isEntityType(v: unknown): v is DocumentEntityType {
  return (
    typeof v === "string" && (ENTITY_TYPES as readonly string[]).includes(v)
  );
}
