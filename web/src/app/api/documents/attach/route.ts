import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import {
  isEntityType,
  ENTITY_TABLE_MAP,
  type DocumentEntityType,
} from "@/lib/documents/validation";

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

  let body: { document_id?: string; entity_type?: string; entity_id?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (!body.document_id || !body.entity_id || !isEntityType(body.entity_type)) {
    return NextResponse.json(
      { error: "document_id, entity_type, entity_id required" },
      { status: 400 }
    );
  }

  // Phase 26 D-06: pre-flight entity existence check. Replaces the silent RLS
  // 403 with an actionable 404. The table name comes from a hard-coded map
  // (ENTITY_TABLE_MAP in validation.ts) — never string-interpolated from user
  // input — so there is no SQL-injection exposure (T-26-SQLI mitigation).
  const entityType = body.entity_type as DocumentEntityType;
  const targetTable = ENTITY_TABLE_MAP[entityType];
  const { data: existing, error: preErr } = await supabase
    .from(targetTable)
    .select("id")
    .eq("id", body.entity_id)
    .maybeSingle();
  if (preErr) {
    console.error(
      `[documents/attach] pre-flight ${targetTable} lookup failed:`,
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

  const { error } = await supabase.from("cs_document_attachments").insert({
    document_id: body.document_id,
    entity_type: body.entity_type,
    entity_id: body.entity_id,
  });
  if (error) {
    const status =
      (error as { code?: string }).code === "23505" ? 409 : 500;
    console.error("[documents/attach] insert failed:", error.message);
    return NextResponse.json({ error: error.message }, { status });
  }
  return NextResponse.json({ ok: true });
}
