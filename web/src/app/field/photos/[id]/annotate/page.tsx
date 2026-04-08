// Phase 16 FIELD-03: Annotate page (Server Component).
// Async params per Next 15+ convention.

import type { Metadata } from "next";
import { createServerSupabase } from "@/lib/supabase/server";
import { loadAnnotation } from "./actions";
import { Editor } from "./Editor";
import { parseLayerJson } from "@/lib/field/annotations/schema";

export const metadata: Metadata = {
  title: "Annotate Photo · ConstructionOS",
};

type Params = Promise<{ id: string }>;

export default async function AnnotatePhotoPage({ params }: { params: Params }) {
  const { id } = await params;

  const supabase = await createServerSupabase();
  if (!supabase) {
    return <div style={{ padding: 20 }}>Supabase not configured.</div>;
  }

  const { data: doc, error } = await supabase
    .from("cs_documents")
    .select("id, filename, storage_path, mime_type")
    .eq("id", id)
    .maybeSingle();

  if (error || !doc) {
    return (
      <div style={{ padding: 20 }}>
        <h1>Photo not found</h1>
        <p style={{ color: "var(--muted)" }}>{error?.message ?? "No document with that id."}</p>
      </div>
    );
  }

  const { data: signed } = await supabase.storage
    .from("documents")
    .createSignedUrl((doc as { storage_path: string }).storage_path, 600);

  const existing = await loadAnnotation(id);
  const initialLayer =
    existing.ok && existing.layerJson
      ? (() => {
          const p = parseLayerJson(existing.layerJson);
          return p.ok ? p.value : { schema_version: 1 as const, shapes: [] };
        })()
      : { schema_version: 1 as const, shapes: [] };

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <h1 style={{ marginBottom: 12 }}>Annotate: {(doc as { filename: string }).filename}</h1>
      <Editor
        documentId={id}
        photoUrl={signed?.signedUrl ?? ""}
        initialLayer={initialLayer}
      />
    </div>
  );
}
