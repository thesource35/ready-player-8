import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import {
  validateDocumentUpload,
  isEntityType,
  ALLOWED_MIME,
  ENTITY_TABLE_MAP,
  type DocumentEntityType,
} from "@/lib/documents/validation";

// Reference ALLOWED_MIME so static analysis sees the import even though
// validateDocumentUpload encapsulates the check.
void ALLOWED_MIME;

export async function POST(req: Request) {
  const supabase = await createServerSupabase();
  if (!supabase)
    return NextResponse.json(
      { error: "Supabase not configured" },
      { status: 500 }
    );

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return NextResponse.json(
      { error: "Invalid multipart body" },
      { status: 400 }
    );
  }

  const file = form.get("file");
  const entityType = String(form.get("entity_type") ?? "");
  const entityId = String(form.get("entity_id") ?? "");

  if (!(file instanceof File))
    return NextResponse.json({ error: "file required" }, { status: 400 });
  if (!isEntityType(entityType))
    return NextResponse.json(
      { error: "invalid entity_type" },
      { status: 400 }
    );
  if (!entityId)
    return NextResponse.json(
      { error: "entity_id required" },
      { status: 400 }
    );

  const v = validateDocumentUpload({ size: file.size, mimeType: file.type });
  if (!v.ok) return NextResponse.json({ error: v.error }, { status: v.status });

  // Phase 26 D-06: pre-flight entity existence check BEFORE storage upload
  // to avoid orphan objects. Hard-coded ENTITY_TABLE_MAP is the only source
  // of the table name (T-26-SQLI).
  const targetTable = ENTITY_TABLE_MAP[entityType as DocumentEntityType];
  const { data: existing, error: preErr } = await supabase
    .from(targetTable)
    .select("id")
    .eq("id", entityId)
    .maybeSingle();
  if (preErr) {
    console.error(
      `[documents/upload] pre-flight ${targetTable} lookup failed:`,
      preErr.message
    );
    return NextResponse.json({ error: preErr.message }, { status: 500 });
  }
  if (!existing) {
    return NextResponse.json(
      { error: `${entityType} not found` },
      { status: 404 }
    );
  }

  const documentId = crypto.randomUUID();
  const ext = (file.name.split(".").pop() ?? "bin")
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "");
  const orgId =
    (user.app_metadata as { org_id?: string } | undefined)?.org_id ?? user.id;
  const path = `${orgId}/${entityType}/${entityId}/${documentId}.${ext}`;

  const { error: upErr } = await supabase.storage
    .from("documents")
    .upload(path, file, { contentType: file.type, upsert: false });
  if (upErr) {
    console.error("[documents/upload] storage upload failed:", upErr.message);
    return NextResponse.json({ error: upErr.message }, { status: 500 });
  }

  const { error: insErr } = await supabase.from("cs_documents").insert({
    id: documentId,
    org_id: orgId,
    version_chain_id: documentId,
    version_number: 1,
    is_current: true,
    filename: file.name,
    mime_type: file.type,
    size_bytes: file.size,
    storage_path: path,
    uploaded_by: user.id,
  });
  if (insErr) {
    // Roll back the storage upload to avoid orphaned objects.
    await supabase.storage.from("documents").remove([path]);
    console.error("[documents/upload] insert failed:", insErr.message);
    return NextResponse.json({ error: insErr.message }, { status: 500 });
  }

  // Auto-attach to the entity. Failure here is non-fatal for the upload.
  const { error: attachErr } = await supabase
    .from("cs_document_attachments")
    .insert({
      document_id: documentId,
      entity_type: entityType,
      entity_id: entityId,
    });
  if (attachErr) {
    console.error(
      "[documents/upload] auto-attach failed:",
      attachErr.message
    );
  }

  return NextResponse.json({
    document_id: documentId,
    version_chain_id: documentId,
    path,
  });
}
