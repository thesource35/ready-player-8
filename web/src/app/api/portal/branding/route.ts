import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { getCompanyBranding, upsertCompanyBranding } from "@/lib/portal/brandingQueries";
import { sanitizePortalCSS } from "@/lib/portal/cssSanitizer";
import type { CompanyBranding } from "@/lib/portal/types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// GET: Fetch company branding (D-73)
// ---------------------------------------------------------------------------

export async function GET(req: Request) {
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

  const { searchParams } = new URL(req.url);
  const orgId = searchParams.get("org_id");

  if (!orgId) {
    // Try to resolve org_id from user
    try {
      const { data: orgRow } = await supabase
        .from("user_orgs")
        .select("org_id")
        .eq("user_id", user.id)
        .maybeSingle();

      if (orgRow) {
        const resolvedOrgId = (orgRow as { org_id: string }).org_id;
        const branding = await getCompanyBranding(resolvedOrgId);
        return NextResponse.json(
          { branding },
          { status: 200, headers: getRateLimitHeaders(rl) }
        );
      }
    } catch {
      // user_orgs may not exist
    }
    return NextResponse.json(
      { branding: null },
      { status: 200, headers: getRateLimitHeaders(rl) }
    );
  }

  const branding = await getCompanyBranding(orgId);
  return NextResponse.json(
    { branding },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

// ---------------------------------------------------------------------------
// PUT: Update company branding (D-74)
// ---------------------------------------------------------------------------

export async function PUT(req: Request) {
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

  let body: Partial<CompanyBranding> & { org_id?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  // Resolve org_id
  let orgId = body.org_id;
  if (!orgId) {
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
  }

  if (!orgId) {
    return NextResponse.json({ error: "org_id is required. Either provide it or ensure user_orgs is configured." }, { status: 400 });
  }

  // Sanitize custom CSS if provided (D-117, T-20-10)
  const updates: Record<string, SupabaseAny> = { ...body };
  delete updates.org_id;
  delete updates.id;
  delete updates.user_id;
  delete updates.created_at;
  delete updates.updated_at;

  if (updates.custom_css && typeof updates.custom_css === "string") {
    const { sanitized, warnings } = sanitizePortalCSS(updates.custom_css);
    updates.custom_css = sanitized;
    if (warnings.length > 0) {
      console.warn("[portal/branding] CSS sanitization warnings:", warnings);
    }
  }

  // Also sanitize custom CSS within theme_config
  if (updates.theme_config?.customCSS && typeof updates.theme_config.customCSS === "string") {
    const { sanitized, warnings } = sanitizePortalCSS(updates.theme_config.customCSS);
    updates.theme_config = { ...updates.theme_config, customCSS: sanitized };
    if (warnings.length > 0) {
      console.warn("[portal/branding] Theme CSS sanitization warnings:", warnings);
    }
  }

  const result = await upsertCompanyBranding(orgId, user.id, updates);
  if (!result) {
    return NextResponse.json({ error: "Failed to update branding" }, { status: 500 });
  }

  return NextResponse.json(
    { branding: result },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
