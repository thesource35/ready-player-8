// D-13: Public portal map page with LOCKED overlays.
// Server component -- fetches portal config, determines whether map is enabled,
// and delegates rendering to PortalMapClient (which fetches via /api/portal/map).
// NO toggle controls shown to the client viewer.

import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { DEFAULT_MAP_OVERLAYS } from "@/lib/portal/types";
import type { PortalSectionsConfig } from "@/lib/portal/types";
import type { PortalMapOverlays } from "@/lib/maps/types";
import PortalMapClient from "./PortalMapClient";

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string; project: string }>;
}): Promise<Metadata> {
  const { slug, project } = await params;
  return {
    title: `Project Map | ${slug}/${project}`,
    description: "Project site map",
    robots: "noindex, nofollow",
  };
}

export default async function PortalMapPage({
  params,
}: {
  params: Promise<{ slug: string; project: string }>;
}) {
  const { slug, project } = await params;
  const supabase = getServiceClient();
  if (!supabase) {
    return notFound();
  }

  // Look up portal config by company_slug + slug
  const { data: config, error: configErr } = await supabase
    .from("cs_portal_config")
    .select("link_id, project_id, sections_config")
    .eq("company_slug", slug)
    .eq("slug", project)
    .eq("is_deleted", false)
    .maybeSingle();

  if (configErr || !config) {
    return notFound();
  }

  // Verify shared link: active, non-expired, non-revoked
  const { data: link, error: linkErr } = await supabase
    .from("cs_report_shared_links")
    .select("token, expires_at, is_revoked")
    .eq("id", config.link_id)
    .maybeSingle();

  if (linkErr || !link) {
    return notFound();
  }
  if (link.is_revoked) {
    return notFound();
  }
  if (link.expires_at && new Date(link.expires_at as string) < new Date()) {
    return notFound();
  }

  // Read overlay config with backward-compatible defaults (D-13)
  const sections = (config.sections_config ?? {}) as PortalSectionsConfig;
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

  const mapboxToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN ?? null;

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div
        style={{
          background: "var(--surface, #F5F7F8)",
          borderRadius: 14,
          padding: 20,
          marginBottom: 16,
          border: "1px solid rgba(74,196,204,0.08)",
        }}
      >
        <div
          style={{
            fontSize: 12,
            fontWeight: 900,
            letterSpacing: 2,
            color: "var(--cyan, #4AC4CC)",
          }}
        >
          PROJECT MAP
        </div>
        <p
          style={{
            fontSize: 11,
            fontWeight: 600,
            color: "var(--muted, #6B7C80)",
            margin: "4px 0 0",
          }}
        >
          Site location and visible layers configured by your project team.
        </p>
      </div>

      {overlays.show_map ? (
        <PortalMapClient
          token={link.token as string}
          mapboxToken={mapboxToken}
        />
      ) : (
        <div
          style={{
            width: "100%",
            height: 220,
            borderRadius: 14,
            background: "var(--surface, #F5F7F8)",
            border: "1px solid rgba(51,84,94,0.12)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "var(--muted, #6B7C80)",
            fontSize: 13,
            fontWeight: 600,
          }}
        >
          Map not available for this portal
        </div>
      )}
    </div>
  );
}
