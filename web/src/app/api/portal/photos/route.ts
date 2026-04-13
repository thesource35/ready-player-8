// GET /api/portal/photos — public photo data endpoint for portal lazy loading
// D-55: Paginated photo loading with date filtering
// D-109: Rate limited (100 views/day per link)

import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { PORTAL_RATE_LIMITS } from "@/lib/portal/types";
import type { PortalPhoto } from "@/lib/portal/photoHelpers";

// In-memory rate limit map (single-instance deployment)
const viewCounts = new Map<string, { count: number; resetAt: number }>();

function checkRateLimit(linkId: string): boolean {
  const now = Date.now();
  const entry = viewCounts.get(linkId);
  if (!entry || entry.resetAt < now) {
    viewCounts.set(linkId, { count: 1, resetAt: now + 86400000 });
    return true;
  }
  if (entry.count >= PORTAL_RATE_LIMITS.viewsPerDayPerLink) return false;
  entry.count++;
  return true;
}

// Prune stale entries when map exceeds 10,000
function pruneRateLimits() {
  if (viewCounts.size <= 10000) return;
  const now = Date.now();
  for (const [key, val] of viewCounts) {
    if (val.resetAt < now) viewCounts.delete(key);
  }
}

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

export async function GET(req: Request): Promise<Response> {
  const { searchParams } = new URL(req.url);
  const token = searchParams.get("token");
  const offset = Math.max(0, parseInt(searchParams.get("offset") ?? "0", 10) || 0);
  const limit = Math.min(50, Math.max(1, parseInt(searchParams.get("limit") ?? "20", 10) || 20));
  const dateStart = searchParams.get("date_start");
  const dateEnd = searchParams.get("date_end");

  if (!token) {
    return NextResponse.json({ error: "Missing token" }, { status: 400 });
  }

  const supabase = getServiceClient();
  if (!supabase) {
    return NextResponse.json({ error: "Service not configured" }, { status: 500 });
  }

  try {
    // Validate token: check cs_report_shared_links + cs_portal_config
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("id, project_id, expires_at, is_revoked")
      .eq("token", token)
      .eq("link_type", "portal")
      .maybeSingle();

    if (linkErr || !link) {
      // D-122: 200ms delay on 404 responses to prevent enumeration
      await new Promise((r) => setTimeout(r, 200));
      return NextResponse.json({ error: "Invalid token" }, { status: 404 });
    }

    // Check expiry and revocation
    if (link.is_revoked) {
      return NextResponse.json({ error: "Link revoked" }, { status: 403 });
    }
    if (link.expires_at && new Date(link.expires_at) < new Date()) {
      return NextResponse.json({ error: "Link expired" }, { status: 410 });
    }

    // Rate limit check (D-109)
    pruneRateLimits();
    if (!checkRateLimit(link.id as string)) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Try again tomorrow." },
        { status: 429 },
      );
    }

    // Check portal config for photos section enabled
    const { data: config } = await supabase
      .from("cs_portal_config")
      .select("sections_config")
      .eq("link_id", link.id)
      .eq("is_deleted", false)
      .maybeSingle();

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const sections = config?.sections_config as any;
    if (!sections?.photos?.enabled) {
      return NextResponse.json({ error: "Photos section not enabled" }, { status: 403 });
    }

    const projectId = link.project_id as string;

    // Resolve document IDs attached to this project
    const { data: attachments } = await supabase
      .from("cs_document_attachments")
      .select("document_id")
      .eq("entity_type", "project")
      .eq("entity_id", projectId);

    const docIds = (attachments ?? []).map((a) => a.document_id as string);
    if (docIds.length === 0) {
      return NextResponse.json({ photos: [], total: 0, hasMore: false });
    }

    // Build photo query
    let photoQuery = supabase
      .from("cs_documents")
      .select("id, filename, storage_path, captured_at, gps_lat, gps_lng, created_at, metadata", { count: "exact" })
      .like("mime_type", "image/%")
      .eq("is_current", true)
      .in("id", docIds)
      .order("captured_at", { ascending: false, nullsFirst: false });

    // Apply date range from portal config
    const configDateRange = sections.photos.date_range;
    const effectiveStart = dateStart || configDateRange?.start;
    const effectiveEnd = dateEnd || configDateRange?.end;

    if (effectiveStart) {
      photoQuery = photoQuery.gte("captured_at", effectiveStart);
    }
    if (effectiveEnd) {
      photoQuery = photoQuery.lte("captured_at", effectiveEnd + "T23:59:59Z");
    }

    // Get total count first, then paginated results
    const { count: total } = await photoQuery;

    // Apply pagination
    photoQuery = photoQuery.range(offset, offset + limit - 1);

    const { data: photos, error: photoErr } = await photoQuery;

    if (photoErr) {
      console.error("[portal/photos] query error:", photoErr.message);
      return NextResponse.json({ error: "Failed to fetch photos" }, { status: 500 });
    }

    const photoRows = photos ?? [];

    // Generate short-lived signed URLs (1 hour) for thumbnails
    if (photoRows.length > 0) {
      const paths = photoRows.map((p) => p.storage_path as string);
      const { data: signed } = await supabase.storage
        .from("documents")
        .createSignedUrls(paths, 3600); // 1 hour

      const signedMap = new Map<string, string>();
      (signed ?? []).forEach((entry, idx) => {
        if (entry.signedUrl) {
          signedMap.set(photoRows[idx].id as string, entry.signedUrl);
        }
      });

      const portalPhotos: PortalPhoto[] = photoRows.map((row) => {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const meta = (row.metadata ?? {}) as any;
        return {
          id: row.id as string,
          url: "",
          signedUrl: signedMap.get(row.id as string) ?? "",
          caption: meta.caption ?? null,
          date_taken: (row.captured_at as string) ?? (row.created_at as string),
          location: {
            lat: row.gps_lat as number | undefined,
            lng: row.gps_lng as number | undefined,
            label: meta.location_label ?? undefined,
          },
          uploader_name: meta.uploader_name ?? "Team member",
          has_annotation: !!meta.has_annotation,
          width: meta.width ?? 0,
          height: meta.height ?? 0,
        };
      });

      const totalCount = total ?? portalPhotos.length;

      return NextResponse.json({
        photos: portalPhotos,
        total: totalCount,
        hasMore: offset + limit < totalCount,
      });
    }

    return NextResponse.json({ photos: [], total: total ?? 0, hasMore: false });
  } catch (err) {
    console.error("[portal/photos] unexpected error:", err);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
