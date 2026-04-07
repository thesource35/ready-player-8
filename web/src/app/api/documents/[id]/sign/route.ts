import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function GET(
  _req: Request,
  ctx: { params: Promise<{ id: string }> }
) {
  const { id } = await ctx.params;
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

  const { data: doc, error } = await supabase
    .from("cs_documents")
    .select("storage_path, mime_type, filename")
    .eq("id", id)
    .single();
  if (error || !doc)
    return NextResponse.json({ error: "Not found" }, { status: 404 });

  const { data: signed, error: signErr } = await supabase.storage
    .from("documents")
    .createSignedUrl(doc.storage_path, 3600);
  if (signErr || !signed) {
    console.error(
      "[documents/sign] createSignedUrl failed for",
      id,
      signErr?.message
    );
    return NextResponse.json(
      { error: signErr?.message ?? "sign failed" },
      { status: 500 }
    );
  }

  return NextResponse.json({
    url: signed.signedUrl,
    mime_type: doc.mime_type,
    filename: doc.filename,
    expires_at: new Date(Date.now() + 3600_000).toISOString(),
  });
}
