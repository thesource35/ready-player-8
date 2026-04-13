// GET /api/portal/photos/download — photo download with EXIF stripping
// D-53: Individual photo download + bulk ZIP download
// D-118: Strip sensitive EXIF (GPS, device info) before delivery
// T-20-19: All downloads routed through stripSensitiveExif

import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { stripSensitiveExif } from "@/lib/portal/imageProcessor";
import JSZip from "jszip";

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// In-memory rate limit for downloads (shared with view count)
const downloadCounts = new Map<string, { count: number; resetAt: number }>();

function checkDownloadLimit(linkId: string): boolean {
  const now = Date.now();
  const entry = downloadCounts.get(linkId);
  if (!entry || entry.resetAt < now) {
    downloadCounts.set(linkId, { count: 1, resetAt: now + 86400000 });
    return true;
  }
  if (entry.count >= 100) return false; // D-109: 100/day per link
  entry.count++;
  return true;
}

export async function GET(req: Request): Promise<Response> {
  const { searchParams } = new URL(req.url);
  const token = searchParams.get("token");
  const photoId = searchParams.get("photo_id");
  const bulkAll = searchParams.get("all") === "true";

  if (!token) {
    return NextResponse.json({ error: "Missing token" }, { status: 400 });
  }

  if (!photoId && !bulkAll) {
    return NextResponse.json(
      { error: "Provide photo_id or all=true" },
      { status: 400 },
    );
  }

  const supabase = getServiceClient();
  if (!supabase) {
    return NextResponse.json({ error: "Service not configured" }, { status: 500 });
  }

  try {
    // Validate token
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("id, project_id, expires_at, is_revoked")
      .eq("token", token)
      .eq("link_type", "portal")
      .maybeSingle();

    if (linkErr || !link) {
      await new Promise((r) => setTimeout(r, 200));
      return NextResponse.json({ error: "Invalid token" }, { status: 404 });
    }

    if (link.is_revoked) {
      return NextResponse.json({ error: "Link revoked" }, { status: 403 });
    }
    if (link.expires_at && new Date(link.expires_at) < new Date()) {
      return NextResponse.json({ error: "Link expired" }, { status: 410 });
    }

    // Rate limit
    if (!checkDownloadLimit(link.id as string)) {
      return NextResponse.json(
        { error: "Download limit exceeded. Try again tomorrow." },
        { status: 429 },
      );
    }

    // Check photos section enabled
    const { data: config } = await supabase
      .from("cs_portal_config")
      .select("sections_config, watermark_enabled, company_slug")
      .eq("link_id", link.id)
      .eq("is_deleted", false)
      .maybeSingle();

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sections = config?.sections_config as any;
    if (!sections?.photos?.enabled) {
      return NextResponse.json({ error: "Photos section not enabled" }, { status: 403 });
    }

    const projectId = link.project_id as string;

    // Get document IDs for project
    const { data: attachments } = await supabase
      .from("cs_document_attachments")
      .select("document_id")
      .eq("entity_type", "project")
      .eq("entity_id", projectId);

    const docIds = (attachments ?? []).map((a) => a.document_id as string);
    if (docIds.length === 0) {
      return NextResponse.json({ error: "No photos available" }, { status: 404 });
    }

    // ---------- Single photo download ----------
    if (photoId && !bulkAll) {
      // Verify photo belongs to project
      if (!docIds.includes(photoId)) {
        return NextResponse.json({ error: "Photo not found" }, { status: 404 });
      }

      const { data: doc } = await supabase
        .from("cs_documents")
        .select("filename, storage_path, mime_type")
        .eq("id", photoId)
        .like("mime_type", "image/%")
        .eq("is_current", true)
        .maybeSingle();

      if (!doc) {
        return NextResponse.json({ error: "Photo not found" }, { status: 404 });
      }

      // Download from Supabase Storage
      const { data: fileData, error: dlErr } = await supabase.storage
        .from("documents")
        .download(doc.storage_path as string);

      if (dlErr || !fileData) {
        console.error("[portal/photos/download] storage error:", dlErr);
        return NextResponse.json({ error: "Download failed" }, { status: 500 });
      }

      // D-118: Strip sensitive EXIF (GPS, device info) via stripSensitiveExif
      const rawBuffer = Buffer.from(await fileData.arrayBuffer());
      const stripped = await stripSensitiveExif(rawBuffer);

      const filename = (doc.filename as string) || "photo.jpg";
      const contentType = (doc.mime_type as string) || "image/jpeg";

      return new Response(new Uint8Array(stripped), {
        headers: {
          "Content-Type": contentType,
          "Content-Disposition": `attachment; filename="${filename}"`,
          "Cache-Control": "private, no-store",
        },
      });
    }

    // ---------- D-53: Bulk ZIP download ----------
    if (bulkAll) {
      // Fetch all project photos
      const { data: photos } = await supabase
        .from("cs_documents")
        .select("id, filename, storage_path, mime_type")
        .like("mime_type", "image/%")
        .eq("is_current", true)
        .in("id", docIds)
        .order("captured_at", { ascending: false, nullsFirst: false });

      if (!photos || photos.length === 0) {
        return NextResponse.json({ error: "No photos to download" }, { status: 404 });
      }

      // T-20-20: Process photos sequentially to bound memory usage
      const zip = new JSZip();
      const usedNames = new Set<string>();

      for (const photo of photos) {
        try {
          const { data: fileData } = await supabase.storage
            .from("documents")
            .download(photo.storage_path as string);

          if (!fileData) continue;

          // Strip EXIF from each photo (D-118)
          const rawBuffer = Buffer.from(await fileData.arrayBuffer());
          const stripped = await stripSensitiveExif(rawBuffer);

          // Deduplicate filenames
          let name = (photo.filename as string) || `photo-${photo.id}.jpg`;
          if (usedNames.has(name)) {
            const ext = name.lastIndexOf(".");
            const base = ext > 0 ? name.slice(0, ext) : name;
            const suffix = ext > 0 ? name.slice(ext) : ".jpg";
            name = `${base}-${photo.id.slice(0, 8)}${suffix}`;
          }
          usedNames.add(name);

          zip.file(name, stripped);
        } catch (err) {
          console.error(`[portal/photos/download] Failed to process photo ${photo.id}:`, err);
          // Skip failed photos, continue with others
        }
      }

      const zipBlob = await zip.generateAsync({
        type: "nodebuffer",
        compression: "DEFLATE",
        compressionOptions: { level: 6 },
      });

      return new Response(new Uint8Array(zipBlob), {
        headers: {
          "Content-Type": "application/zip",
          "Content-Disposition": 'attachment; filename="project-photos.zip"',
          "Cache-Control": "private, no-store",
        },
      });
    }

    return NextResponse.json({ error: "Invalid request" }, { status: 400 });
  } catch (err) {
    console.error("[portal/photos/download] unexpected error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
