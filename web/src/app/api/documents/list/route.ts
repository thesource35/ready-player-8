import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { isEntityType } from "@/lib/documents/validation";

export async function GET(req: Request) {
  const supabase = await createServerSupabase();
  if (!supabase)
    return NextResponse.json(
      { error: "Supabase not configured" },
      { status: 500 },
    );
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(req.url);
  const entityType = url.searchParams.get("entity_type");
  const entityId = url.searchParams.get("entity_id");
  if (!isEntityType(entityType) || !entityId) {
    return NextResponse.json(
      { error: "entity_type and entity_id required" },
      { status: 400 },
    );
  }

  const { data, error } = await supabase
    .from("cs_documents")
    .select("*, cs_document_attachments!inner(entity_type, entity_id)")
    .eq("cs_document_attachments.entity_type", entityType)
    .eq("cs_document_attachments.entity_id", entityId)
    .eq("is_current", true)
    .order("created_at", { ascending: false });
  if (error)
    return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ documents: data ?? [] });
}
