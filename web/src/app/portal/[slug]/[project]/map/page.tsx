// D-13: Public portal map page with LOCKED overlays.
// Server component -- fetches portal config, determines whether map is enabled,
// and delegates rendering to PortalMapClient (which fetches via /api/portal/map).
// NO toggle controls shown to the client viewer.
//
// Phase 27 additions:
//   D-05, D-14, D-26 -- Render PortalHeader with showMapLink=true so Overview return anchor appears
//   D-12 -- Cache: dynamic="force-dynamic" + revalidate=60 (matches portal home)
//   D-18 -- Do NOT render the mobile bottom-nav component (phones get vertical map space)
//   D-20, D-21 -- Inherit portal branding via getBrandingForPortal + apply 5 CSS vars
//   D-22 -- Keep existing notFound() for expired/revoked (do NOT swap to a branded expired-page component)
//   D-27, D-28 -- Fire-and-forget recordPortalView with the map section-viewed marker
//   D-29 -- Reuse checkDailyViewLimit shared 100/day budget with portal home

import { notFound } from "next/navigation";
import { headers } from "next/headers";
import type { Metadata } from "next";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { DEFAULT_MAP_OVERLAYS } from "@/lib/portal/types";
import type { PortalSectionsConfig } from "@/lib/portal/types";
import type { PortalMapOverlays } from "@/lib/maps/types";
import { getBrandingForPortal } from "@/lib/portal/brandingQueries";
import { recordPortalView } from "@/lib/portal/analyticsQueries";
import PortalHeader from "@/app/components/portal/PortalHeader";
import PortalMapClient from "./PortalMapClient";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// D-29 (Phase 27): Shared 100/day budget with portal home.
// Verbatim copy of checkDailyViewLimit from web/src/app/portal/[slug]/[project]/page.tsx (lines 226-240).
// Both helpers query cs_portal_analytics for the same link_id -> same row count -> same budget.
async function checkDailyViewLimit(
  supabase: SupabaseAny,
  linkId: string,
): Promise<boolean> {
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);
  const { count } = await supabase
    .from("cs_portal_analytics")
    .select("id", { count: "exact", head: true })
    .eq("link_id", linkId)
    .gte("created_at", todayStart.toISOString());
  return ((count as number) ?? 0) < 100;
}

// Verbatim copy of hashIP from web/src/app/portal/[slug]/[project]/page.tsx (lines 246-255).
function hashIP(ip: string): string {
  let hash = 0;
  for (let i = 0; i < ip.length; i++) {
    const char = ip.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
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
    .select("id, link_id, project_id, org_id, sections_config")
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
    .select("id, token, expires_at, is_revoked")
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

  // D-29: Reuse 100/day shared budget with portal home
  const allowed = await checkDailyViewLimit(supabase, link.id as string);
  if (!allowed) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "100vh",
          padding: 32,
          fontFamily: "system-ui, sans-serif",
          background: "#F8F9FB",
          color: "#374151",
        }}
      >
        <div style={{ fontSize: 48, fontWeight: 800, color: "#F59E0B", marginBottom: 16 }}>
          429
        </div>
        <h1 style={{ fontSize: 20, fontWeight: 700, marginBottom: 8 }}>
          Too many requests
        </h1>
        <p style={{ fontSize: 14, color: "#6B7280", textAlign: "center" }}>
          This portal has reached its daily view limit. Please try again tomorrow.
        </p>
      </div>
    );
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

  // D-20, D-21: Branding inheritance -- same helper as portal home
  const { branding, theme } = await getBrandingForPortal(
    (config.org_id as string) ?? "",
    config.id as string,
  );

  // Fetch project name for PortalHeader title
  const { data: projectRow } = await supabase
    .from("cs_projects")
    .select("name")
    .eq("id", config.project_id)
    .maybeSingle();
  const projectName = (projectRow?.name as string) ?? "Project";

  // D-27, D-28: Fire-and-forget analytics with the map section-viewed marker
  const headersList = await headers();
  const ip = headersList.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "";
  const userAgent = headersList.get("user-agent") ?? "";
  recordPortalView({
    portalConfigId: config.id as string,
    linkId: link.id as string,
    sectionViewed: "map",
    ipHash: ip ? hashIP(ip) : undefined,
    userAgent: userAgent.slice(0, 256),
  }).catch((err: unknown) => {
    console.error("[PortalMapPage] analytics recording failed:", err);
  });

  const companyName = branding?.company_name ?? "";
  const logoUrl = branding?.logo_light_path ?? undefined;
  const lastUpdated = new Date().toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  return (
    <div
      style={{
        // D-20: Apply portal branding as CSS custom properties (mirrors PortalShell.tsx lines 100-106)
        ["--portal-primary" as string]: theme.primary,
        ["--portal-secondary" as string]: theme.secondary ?? theme.primary,
        ["--portal-bg" as string]: theme.background,
        ["--portal-text" as string]: theme.text,
        ["--portal-card-bg" as string]: theme.cardBg,
        ["--portal-font-family" as string]: `${theme.fontFamily}, system-ui, -apple-system, sans-serif`,
        ["--portal-radius" as string]: `${theme.borderRadius}px`,
        background: theme.background,
        color: theme.text,
        fontFamily: `${theme.fontFamily}, system-ui, -apple-system, sans-serif`,
        minHeight: "100vh",
      }}
    >
      {/* D-05, D-14, D-26: PortalHeader with showMapLink=true -> Overview anchor renders FIRST.
          sectionAnchors=[] because /map has no in-page section anchors.
          D-18: mobile bottom-nav intentionally omitted on /map. */}
      <PortalHeader
        companyName={companyName}
        logoUrl={logoUrl}
        projectName={projectName}
        sectionAnchors={[]}
        lastUpdated={lastUpdated}
        showMapLink={true}
      />

      <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
        {/* Intro card -- uses branded CSS vars (D-20) */}
        <div
          style={{
            background: "var(--portal-card-bg, #F5F7F8)",
            borderRadius: "var(--portal-radius, 14px)",
            padding: 20,
            marginBottom: 16,
            border: "1px solid #E2E5E9",
          }}
        >
          <div
            style={{
              fontSize: 12,
              fontWeight: 900,
              letterSpacing: 2,
              color: "var(--portal-primary, #2563EB)",
            }}
          >
            PROJECT MAP
          </div>
          <p
            style={{
              fontSize: 11,
              fontWeight: 600,
              color: "#6B7280",
              margin: "4px 0 0",
            }}
          >
            Site location and visible layers configured by your project team.
          </p>
        </div>

        {/* D-13: Preserve existing 'Map not available' placeholder when show_map false */}
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
              borderRadius: "var(--portal-radius, 14px)",
              background: "var(--portal-card-bg, #F5F7F8)",
              border: "1px solid #E2E5E9",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#6B7280",
              fontSize: 13,
              fontWeight: 600,
            }}
          >
            Map not available for this portal
          </div>
        )}
      </div>
    </div>
  );
}

// D-12 (Phase 27): Same edge cache as portal home -- no explicit revalidatePath needed for show_map flips
export const dynamic = "force-dynamic";
export const revalidate = 60;
