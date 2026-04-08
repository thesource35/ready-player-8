"use server";

// Phase 16 FIELD-03: Server Action for saving photo annotations.
//
// Isolated from web/src/app/field/actions.ts to avoid merge conflicts
// with the concurrent 16-05 (daily logs) executor.
//
// Returns a discriminated-union plain object — Server Actions cannot
// return NextResponse.

import { parseLayerJson } from "@/lib/field/annotations/schema";
import { createServerSupabase } from "@/lib/supabase/server";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export type SaveAnnotationResult =
  | { ok: true }
  | { ok: false; status: number; error: string };

function mapPostgrestError(code: string | undefined): number {
  if (code === "42501") return 403; // RLS denial (T-16-RLS)
  if (code === "23503") return 400; // FK violation
  return 500;
}

export async function saveAnnotation(
  documentId: unknown,
  layerJson: unknown
): Promise<SaveAnnotationResult> {
  if (typeof documentId !== "string" || !UUID_RE.test(documentId)) {
    return { ok: false, status: 400, error: "Invalid document_id" };
  }

  const parsed = parseLayerJson(layerJson);
  if (!parsed.ok) {
    return { ok: false, status: 400, error: parsed.error };
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

  // Resolve org_id from the parent document — the RLS policy on
  // cs_photo_annotations checks EXISTS against cs_documents, but the
  // table's org_id column is NOT NULL so we must provide one.
  const { data: doc, error: docErr } = await supabase
    .from("cs_documents")
    .select("org_id")
    .eq("id", documentId)
    .maybeSingle();

  if (docErr || !doc) {
    const status = docErr
      ? mapPostgrestError((docErr as { code?: string }).code)
      : 404;
    return {
      ok: false,
      status,
      error: docErr?.message ?? "Document not found",
    };
  }

  const { error } = await supabase
    .from("cs_photo_annotations")
    .upsert(
      {
        document_id: documentId,
        org_id: (doc as { org_id: string }).org_id,
        layer_json: parsed.value,
        schema_version: 1,
        created_by: user.id,
        updated_by: user.id,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "document_id" }
    );

  if (error) {
    const status = mapPostgrestError((error as { code?: string }).code);
    console.error("[field/annotate] upsert failed:", error.message);
    return { ok: false, status, error: error.message };
  }

  return { ok: true };
}

export async function loadAnnotation(
  documentId: string
): Promise<{ ok: true; layerJson: unknown | null } | { ok: false; error: string }> {
  if (!UUID_RE.test(documentId)) {
    return { ok: false, error: "Invalid document_id" };
  }
  const supabase = await createServerSupabase();
  if (!supabase) return { ok: false, error: "Supabase not configured" };

  const { data, error } = await supabase
    .from("cs_photo_annotations")
    .select("layer_json")
    .eq("document_id", documentId)
    .maybeSingle();

  if (error) return { ok: false, error: error.message };
  return { ok: true, layerJson: data?.layer_json ?? null };
}
