import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { processUploadedImage } from "@/lib/portal/imageProcessor";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// Valid upload type fields
const VALID_UPLOAD_TYPES = ["logo_light", "logo_dark", "favicon", "cover_image"] as const;
type UploadType = (typeof VALID_UPLOAD_TYPES)[number];

// Map upload type to image processor type
function getImageType(uploadType: UploadType): "logo" | "cover" | "favicon" {
  switch (uploadType) {
    case "logo_light":
    case "logo_dark":
      return "logo";
    case "cover_image":
      return "cover";
    case "favicon":
      return "favicon";
  }
}

// Map upload type to branding column
function getBrandingColumn(uploadType: UploadType): string {
  switch (uploadType) {
    case "logo_light":
      return "logo_light_path";
    case "logo_dark":
      return "logo_dark_path";
    case "cover_image":
      return "cover_image_path";
    case "favicon":
      return "favicon_path";
  }
}

// ---------------------------------------------------------------------------
// POST: Upload branding image (D-75, D-61, D-62, D-124)
// ---------------------------------------------------------------------------

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/portal");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json({ error: "Authentication required" }, { status: 401 });
  }

  // Parse FormData
  let formData: FormData;
  try {
    formData = await req.formData();
  } catch {
    return NextResponse.json({ error: "Invalid form data" }, { status: 400 });
  }

  const file = formData.get("file");
  const typeField = formData.get("type");

  if (!file || !(file instanceof File)) {
    return NextResponse.json({ error: "No file provided" }, { status: 400 });
  }

  if (!typeField || typeof typeField !== "string") {
    return NextResponse.json({ error: "type field is required (logo_light, logo_dark, favicon, cover_image)" }, { status: 400 });
  }

  const uploadType = typeField as UploadType;
  if (!VALID_UPLOAD_TYPES.includes(uploadType)) {
    return NextResponse.json(
      { error: `Invalid type. Must be one of: ${VALID_UPLOAD_TYPES.join(", ")}` },
      { status: 400 }
    );
  }

  // Read file buffer
  const arrayBuffer = await file.arrayBuffer();
  const buffer = Buffer.from(arrayBuffer);

  // Validate and process image
  const imageType = getImageType(uploadType);
  let processedBuffer: Buffer;
  try {
    processedBuffer = await processUploadedImage(buffer, file.name, imageType);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Image processing failed";
    return NextResponse.json({ error: message }, { status: 400 });
  }

  // Resolve org_id
  let orgId: string | undefined;
  try {
    const { data: orgRow } = await supabase
      .from("user_orgs")
      .select("org_id")
      .eq("user_id", user.id)
      .maybeSingle();
    orgId = (orgRow as { org_id?: string } | null)?.org_id;
  } catch {
    // user_orgs may not exist
  }

  if (!orgId) {
    return NextResponse.json({ error: "No organization found for user" }, { status: 400 });
  }

  // Upload to Supabase Storage 'branding' bucket (D-100)
  // Path: {org_id}/{type}/{filename}
  const sanitizedFilename = file.name.replace(/[^a-zA-Z0-9._-]/g, "_");
  const storagePath = `${orgId}/${uploadType}/${sanitizedFilename}`;

  // Use service-role client for storage operations
  const url = getSupabaseUrl();
  const serviceKey = getSupabaseServerKey();
  if (!url || !serviceKey) {
    return NextResponse.json({ error: "Storage not configured" }, { status: 500 });
  }
  const serviceClient = createClient(url, serviceKey);

  const { error: uploadErr } = await serviceClient.storage
    .from("branding")
    .upload(storagePath, processedBuffer, {
      contentType: file.type,
      upsert: true, // Overwrite existing file
    });

  if (uploadErr) {
    console.error("[portal/branding/upload] Storage upload error:", uploadErr);
    return NextResponse.json({ error: "Failed to upload file to storage" }, { status: 500 });
  }

  // Get public URL
  const { data: publicUrlData } = serviceClient.storage
    .from("branding")
    .getPublicUrl(storagePath);

  // Update cs_company_branding with new path
  const brandingColumn = getBrandingColumn(uploadType);
  const { error: updateErr } = await supabase
    .from("cs_company_branding")
    .update({ [brandingColumn]: storagePath } as SupabaseAny)
    .eq("org_id", orgId);

  if (updateErr) {
    console.error("[portal/branding/upload] Branding update error:", updateErr);
    // File uploaded but branding not updated — not critical, can be retried
  }

  // Audit log (D-114)
  await supabase.from("cs_portal_audit_log").insert({
    user_id: user.id,
    action: "branding_updated",
    metadata: {
      upload_type: uploadType,
      path: storagePath,
      filename: sanitizedFilename,
      size_bytes: processedBuffer.length,
    },
  });

  return NextResponse.json(
    {
      path: storagePath,
      url: publicUrlData.publicUrl,
    },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
