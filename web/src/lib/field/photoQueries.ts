// 999.5 follow-up: server-only marker (uses createServerSupabase).
import "server-only";

// Phase 16 FIELD-02: Server-side photo query helpers.
//
// Queries cs_documents filtered to image MIME types and resolves storage
// paths to signed URLs via a SINGLE batched createSignedUrls() call
// (RESEARCH §7). RLS on cs_documents enforces visibility.

import { createServerSupabase } from "@/lib/supabase/server";

export type FieldPhoto = {
  id: string;
  filename: string;
  mime_type: string;
  storage_path: string;
  captured_at: string | null;
  gps_lat: number | null;
  gps_lng: number | null;
  gps_source: "fresh" | "stale_last_known" | "manual_pin" | null;
  created_at: string;
};

export type ListFieldPhotosResult = {
  ok: true;
  photos: FieldPhoto[];
  signedUrls: Map<string, string>;
} | {
  ok: false;
  status: number;
  error: string;
  photos: FieldPhoto[];
  signedUrls: Map<string, string>;
};

const DEFAULT_LIMIT = 48;
const SIGNED_URL_TTL_SECONDS = 60 * 10; // 10 min
const DOCUMENTS_BUCKET = "documents";

export async function listFieldPhotos(params: {
  projectId?: string;
  limit?: number;
  before?: string;
} = {}): Promise<ListFieldPhotosResult> {
  const limit = Math.min(Math.max(params.limit ?? DEFAULT_LIMIT, 1), 200);

  const supabase = await createServerSupabase();
  if (!supabase) {
    return {
      ok: false,
      status: 500,
      error: "Supabase not configured",
      photos: [],
      signedUrls: new Map(),
    };
  }

  // RLS on cs_documents filters rows to those the caller may see.
  // Project filtering flows through cs_document_attachments because
  // cs_documents has no project_id column (Phase 13 schema).
  let query = supabase
    .from("cs_documents")
    .select(
      "id, filename, mime_type, storage_path, captured_at, gps_lat, gps_lng, gps_source, created_at"
    )
    .like("mime_type", "image/%")
    .eq("is_current", true)
    .order("captured_at", { ascending: false, nullsFirst: false })
    .limit(limit);

  if (params.before) {
    query = query.lt("captured_at", params.before);
  }

  if (params.projectId) {
    // Sub-select document_ids attached to this project via junction table.
    const { data: attached, error: attachedErr } = await supabase
      .from("cs_document_attachments")
      .select("document_id")
      .eq("entity_type", "project")
      .eq("entity_id", params.projectId);

    if (attachedErr) {
      console.error(
        "[field/photoQueries] attachment filter failed:",
        attachedErr.message
      );
      return {
        ok: false,
        status: 500,
        error: attachedErr.message,
        photos: [],
        signedUrls: new Map(),
      };
    }
    const ids = (attached ?? []).map((r) => r.document_id as string);
    if (ids.length === 0) {
      return { ok: true, photos: [], signedUrls: new Map() };
    }
    query = query.in("id", ids);
  }

  const { data, error } = await query;
  if (error) {
    console.error("[field/photoQueries] list failed:", error.message);
    return {
      ok: false,
      status: 500,
      error: error.message,
      photos: [],
      signedUrls: new Map(),
    };
  }

  const photos = (data ?? []) as FieldPhoto[];
  const signedUrls = new Map<string, string>();

  if (photos.length === 0) {
    return { ok: true, photos, signedUrls };
  }

  // SINGLE batched call — avoids N+1. createSignedUrls returns an array
  // aligned with the input paths order. (RESEARCH §7.)
  const paths = photos.map((p) => p.storage_path);
  const { data: signed, error: signedErr } = await supabase.storage
    .from(DOCUMENTS_BUCKET)
    .createSignedUrls(paths, SIGNED_URL_TTL_SECONDS);

  if (signedErr) {
    console.error(
      "[field/photoQueries] createSignedUrls failed:",
      signedErr.message
    );
    // Return photos without URLs rather than hard-failing the page.
    return { ok: true, photos, signedUrls };
  }

  (signed ?? []).forEach((entry, idx) => {
    if (entry.signedUrl) {
      signedUrls.set(photos[idx].id, entry.signedUrl);
    }
  });

  return { ok: true, photos, signedUrls };
}
