import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { createPortalLink } from "@/lib/portal/portalQueries";
import { generateSlug, generateCompanySlug } from "@/lib/portal/slugGenerator";
import { TEMPLATE_DEFAULTS } from "@/lib/portal/types";
import type { PortalTemplate } from "@/lib/portal/types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// D-109: 50 management requests/hour per user
// D-24: Branded slug URLs — /portal/{companySlug}/{slug}

// ---------------------------------------------------------------------------
// POST: Create a portal link (D-97, D-24)
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

  let body: {
    project_id?: string;
    slug?: string;
    company_slug?: string;
    template?: PortalTemplate;
    expiry_days?: number | null;
    client_email?: string;
    map_overlays?: {
      show_map?: boolean;
      satellite?: boolean;
      traffic?: boolean;
      equipment?: boolean;
      photos?: boolean;
    };
  };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (!body.project_id || typeof body.project_id !== "string") {
    return NextResponse.json({ error: "project_id is required" }, { status: 400 });
  }

  // Validate template if provided
  const template: PortalTemplate = body.template ?? "executive_summary";
  if (!TEMPLATE_DEFAULTS[template]) {
    return NextResponse.json(
      { error: "Invalid template. Must be 'executive_summary', 'full_progress', or 'photo_update'." },
      { status: 400 }
    );
  }

  // Auto-generate slug from project name if not provided
  let slug = body.slug ? generateSlug(body.slug) : "";
  if (!slug) {
    // Fetch project name for slug generation
    const { data: project } = await supabase
      .from("cs_projects")
      .select("name")
      .eq("id", body.project_id)
      .maybeSingle();

    const projectName = (project as { name?: string } | null)?.name;
    slug = projectName ? generateSlug(projectName) : `project-${body.project_id.slice(0, 8)}`;
  }

  // Auto-generate company slug from branding if not provided
  let companySlug = body.company_slug ? generateCompanySlug(body.company_slug) : "";
  if (!companySlug) {
    // Try to fetch company name from branding
    try {
      const { data: orgRow } = await supabase
        .from("user_orgs")
        .select("org_id")
        .eq("user_id", user.id)
        .maybeSingle();

      if (orgRow) {
        const orgId = (orgRow as { org_id: string }).org_id;
        const { data: branding } = await supabase
          .from("cs_company_branding")
          .select("company_name")
          .eq("org_id", orgId)
          .maybeSingle();

        const companyName = (branding as { company_name?: string } | null)?.company_name;
        companySlug = companyName ? generateCompanySlug(companyName) : "";
      }
    } catch {
      // Gracefully degrade if org/branding tables don't exist
    }

    if (!companySlug) {
      companySlug = `org-${user.id.slice(0, 8)}`;
    }
  }

  // Check slug uniqueness (T-20-14: UNIQUE(company_slug, slug) constraint)
  const { data: existing } = await supabase
    .from("cs_portal_config")
    .select("id")
    .eq("company_slug", companySlug)
    .eq("slug", slug)
    .eq("is_deleted", false)
    .maybeSingle();

  if (existing) {
    // Suggest alternative by appending -2, -3, etc.
    let altSlug = slug;
    let counter = 2;
    while (counter <= 20) {
      altSlug = `${slug}-${counter}`.slice(0, 50);
      const { data: altExisting } = await supabase
        .from("cs_portal_config")
        .select("id")
        .eq("company_slug", companySlug)
        .eq("slug", altSlug)
        .eq("is_deleted", false)
        .maybeSingle();

      if (!altExisting) break;
      counter++;
    }
    slug = altSlug;
  }

  // Resolve org_id for the user
  let orgId: string | undefined;
  try {
    const { data: orgRow } = await supabase
      .from("user_orgs")
      .select("org_id")
      .eq("user_id", user.id)
      .maybeSingle();
    if (orgRow) {
      orgId = (orgRow as { org_id: string }).org_id;
    }
  } catch {
    // user_orgs may not exist
  }

  // Get default sections config from template
  const sectionsConfig = { ...TEMPLATE_DEFAULTS[template] };

  // D-13: Merge client-supplied map overlay config, coercing to booleans for safety
  if (body.map_overlays && typeof body.map_overlays === "object") {
    const templateMap = sectionsConfig.map_overlays;
    sectionsConfig.map_overlays = {
      show_map: Boolean(body.map_overlays.show_map ?? templateMap?.show_map ?? true),
      satellite: Boolean(body.map_overlays.satellite ?? templateMap?.satellite ?? true),
      traffic: Boolean(body.map_overlays.traffic ?? templateMap?.traffic ?? false),
      equipment: Boolean(body.map_overlays.equipment ?? templateMap?.equipment ?? false),
      photos: Boolean(body.map_overlays.photos ?? templateMap?.photos ?? true),
    };
  }

  try {
    const { link, config } = await createPortalLink({
      projectId: body.project_id,
      slug,
      companySlug,
      template,
      sectionsConfig,
      expiryDays: body.expiry_days ?? 30,
      clientEmail: body.client_email,
      userId: user.id,
      orgId,
    });

    const baseUrl = req.headers.get("x-forwarded-proto")
      ? `${req.headers.get("x-forwarded-proto")}://${req.headers.get("host")}`
      : `https://${req.headers.get("host") ?? "localhost:3000"}`;

    return NextResponse.json(
      {
        link: {
          token: (link as SupabaseAny).token,
          url: `${baseUrl}/portal/${companySlug}/${slug}`,
        },
        config,
      },
      { status: 201, headers: getRateLimitHeaders(rl) }
    );
  } catch (err) {
    console.error("[portal/create] Error:", err);
    return NextResponse.json(
      { error: err instanceof Error ? err.message : "Failed to create portal link" },
      { status: 500 }
    );
  }
}
