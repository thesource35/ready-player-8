// GET /api/portal/map -- public portal map data endpoint (D-13)
// Returns project-scoped map data filtered by portal overlay config.
// Uses service-role client (bypasses RLS) after token validation.
// D-109: Rate limited per link (100 views/day)
// T-21-16: Only returns data for the specific project associated with the portal link
// T-21-17: 200ms delay on 404 to prevent slug enumeration

import { NextResponse } from "next/server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { PORTAL_RATE_LIMITS, DEFAULT_MAP_OVERLAYS } from "@/lib/portal/types";
import type { PortalMapOverlays } from "@/lib/maps/types";

// In-memory rate limit map (single-instance deployment)
// Key pattern: map view count per portal link.
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

// Prune stale entries when map exceeds 10,000 to bound memory
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

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

type PortalMapResponse = {
  data: {
    overlays: PortalMapOverlays;
    site: {
      project_id: string;
      name: string;
      lat: number | null;
      lng: number | null;
    };
    equipment: Array<{
      id: string;
      name: string;
      type: string;
      status: string;
      lat: number;
      lng: number;
      recorded_at: string;
    }>;
    photos: Array<{
      id: string;
      filename: string;
      lat: number;
      lng: number;
      created_at: string;
    }>;
  } | null;
  message?: string;
};

export async function GET(req: Request): Promise<Response> {
  const { searchParams } = new URL(req.url);
  const token = searchParams.get("token");

  if (!token) {
    return NextResponse.json(
      { error: "Missing token" } satisfies Record<string, string>,
      { status: 400 },
    );
  }

  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[portal/map] Service client not configured");
    return NextResponse.json(
      { error: "Service not configured" },
      { status: 500 },
    );
  }

  try {
    // Step 1: Validate token via cs_report_shared_links
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("id, project_id, expires_at, is_revoked")
      .eq("token", token)
      .eq("link_type", "portal")
      .maybeSingle();

    if (linkErr || !link) {
      // T-21-17: 200ms delay to prevent token enumeration
      await new Promise((r) => setTimeout(r, 200));
      return NextResponse.json({ error: "Invalid token" }, { status: 404 });
    }

    if (link.is_revoked) {
      return NextResponse.json({ error: "Link revoked" }, { status: 403 });
    }
    if (link.expires_at && new Date(link.expires_at) < new Date()) {
      return NextResponse.json({ error: "Link expired" }, { status: 410 });
    }

    // Step 2: Rate limit per link (D-109)
    pruneRateLimits();
    if (!checkRateLimit(link.id as string)) {
      return NextResponse.json(
        { error: "Rate limit exceeded. Try again tomorrow." },
        { status: 429 },
      );
    }

    // Step 3: Load portal config for overlays
    const { data: config, error: configErr } = await supabase
      .from("cs_portal_config")
      .select("project_id, sections_config")
      .eq("link_id", link.id)
      .eq("is_deleted", false)
      .maybeSingle();

    if (configErr || !config) {
      if (configErr)
        console.error("[portal/map] config lookup error:", configErr);
      return NextResponse.json(
        { error: "Portal config not found" },
        { status: 404 },
      );
    }

    // Extract overlays with backward-compatible default
    const sections = (config.sections_config ?? {}) as SupabaseAny;
    const overlays: PortalMapOverlays = {
      show_map: Boolean(
        sections.map_overlays?.show_map ?? DEFAULT_MAP_OVERLAYS.show_map,
      ),
      satellite: Boolean(
        sections.map_overlays?.satellite ?? DEFAULT_MAP_OVERLAYS.satellite,
      ),
      traffic: Boolean(
        sections.map_overlays?.traffic ?? DEFAULT_MAP_OVERLAYS.traffic,
      ),
      equipment: Boolean(
        sections.map_overlays?.equipment ?? DEFAULT_MAP_OVERLAYS.equipment,
      ),
      photos: Boolean(
        sections.map_overlays?.photos ?? DEFAULT_MAP_OVERLAYS.photos,
      ),
    };

    // If map disabled, return null data with message
    if (!overlays.show_map) {
      return NextResponse.json({
        data: null,
        message: "Map not enabled for this portal",
      } satisfies PortalMapResponse);
    }

    const projectId = config.project_id as string;

    // Step 4: Fetch project site (map center) -- always needed when map is shown
    const { data: project, error: projectErr } = await supabase
      .from("cs_projects")
      .select("id, name, lat, lng")
      .eq("id", projectId)
      .maybeSingle();

    if (projectErr) {
      console.error("[portal/map] project lookup error:", projectErr);
    }

    const site = {
      project_id: projectId,
      name: (project?.name as string) ?? "Project",
      lat: (project?.lat as number | null) ?? null,
      lng: (project?.lng as number | null) ?? null,
    };

    // Step 5: Conditionally fetch equipment positions (T-21-16: scoped to project)
    let equipment: PortalMapResponse["data"] extends infer D
      ? D extends { equipment: infer E }
        ? E
        : never
      : never = [];
    if (overlays.equipment) {
      const { data: equipRows, error: equipErr } = await supabase
        .from("cs_equipment_latest_positions")
        .select(
          "id, name, type, status, latest_lat, latest_lng, latest_recorded_at, assigned_project",
        )
        .eq("assigned_project", projectId);

      if (equipErr) {
        console.error("[portal/map] equipment lookup error:", equipErr);
      } else if (Array.isArray(equipRows)) {
        equipment = equipRows
          .filter(
            (r: SupabaseAny) =>
              r.latest_lat != null && r.latest_lng != null,
          )
          .map((r: SupabaseAny) => ({
            id: r.id as string,
            name: (r.name as string) ?? "Equipment",
            type: (r.type as string) ?? "equipment",
            status: (r.status as string) ?? "active",
            lat: r.latest_lat as number,
            lng: r.latest_lng as number,
            recorded_at: (r.latest_recorded_at as string) ?? "",
          }));
      }
    }

    // Step 6: Conditionally fetch GPS photos (T-21-16: scoped to project)
    let photos: PortalMapResponse["data"] extends infer D
      ? D extends { photos: infer P }
        ? P
        : never
      : never = [];
    if (overlays.photos) {
      const { data: photoRows, error: photoErr } = await supabase
        .from("cs_documents")
        .select("id, filename, gps_lat, gps_lng, created_at, entity_id, entity_type")
        .eq("entity_type", "project")
        .eq("entity_id", projectId)
        .not("gps_lat", "is", null)
        .not("gps_lng", "is", null);

      if (photoErr) {
        console.error("[portal/map] photos lookup error:", photoErr);
      } else if (Array.isArray(photoRows)) {
        photos = photoRows.map((r: SupabaseAny) => ({
          id: r.id as string,
          filename: (r.filename as string) ?? "photo",
          lat: r.gps_lat as number,
          lng: r.gps_lng as number,
          created_at: (r.created_at as string) ?? "",
        }));
      }
    }

    const response: PortalMapResponse = {
      data: {
        overlays,
        site,
        equipment,
        photos,
      },
    };

    return NextResponse.json(response);
  } catch (err) {
    console.error("[portal/map] unexpected error:", err);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}
