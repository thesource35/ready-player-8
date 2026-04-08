import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";
import { validateDocumentUpload } from "@/lib/documents/validation";

async function resolveChainId(
  supabase: NonNullable<Awaited<ReturnType<typeof createServerSupabase>>>,
  id: string
): Promise<string | null> {
  const { data, error } = await supabase
    .from("cs_documents")
    .select("version_chain_id")
    .eq("id", id)
    .single();
  if (error || !data) return null;
  return (data as { version_chain_id: string }).version_chain_id;
}

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

  const chainId = await resolveChainId(supabase, id);
  if (!chainId)
    return NextResponse.json({ error: "Not found" }, { status: 404 });

  const { data, error } = await supabase
    .from("cs_documents")
    .select("*")
    .eq("version_chain_id", chainId)
    .order("version_number", { ascending: false });
  if (error) {
    console.error("[documents/versions] list failed:", error.message);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ versions: data ?? [] });
}

export async function POST(
  req: Request,
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

  const chainId = await resolveChainId(supabase, id);
  if (!chainId)
    return NextResponse.json({ error: "Not found" }, { status: 404 });

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
  if (!(file instanceof File))
    return NextResponse.json({ error: "file required" }, { status: 400 });

  const v = validateDocumentUpload({ size: file.size, mimeType: file.type });
  if (!v.ok) return NextResponse.json({ error: v.error }, { status: v.status });

  const orgId =
    (user.app_metadata as { org_id?: string } | undefined)?.org_id ?? user.id;
  const ext = (file.name.split(".").pop() ?? "bin")
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "");
  const versionDocId = crypto.randomUUID();
  const path = `${orgId}/versions/${chainId}/${versionDocId}.${ext}`;

  const { error: upErr } = await supabase.storage
    .from("documents")
    .upload(path, file, { contentType: file.type, upsert: false });
  if (upErr) {
    console.error("[documents/versions] storage upload failed:", upErr.message);
    return NextResponse.json({ error: upErr.message }, { status: 500 });
  }

  const { data: newId, error: rpcErr } = await supabase.rpc(
    "create_document_version",
    {
      p_chain_id: chainId,
      p_filename: file.name,
      p_mime_type: file.type,
      p_size_bytes: file.size,
      p_storage_path: path,
      p_org_id: orgId,
    }
  );
  if (rpcErr) {
    await supabase.storage.from("documents").remove([path]);
    console.error("[documents/versions] rpc failed:", rpcErr.message);
    return NextResponse.json({ error: rpcErr.message }, { status: 500 });
  }

  return NextResponse.json({
    document_id: newId,
    version_chain_id: chainId,
    path,
  });
}
