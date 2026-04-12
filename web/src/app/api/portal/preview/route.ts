import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// ---------------------------------------------------------------------------
// GET: Generate a temporary preview URL for a portal (D-17)
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
  const portalConfigId = searchParams.get("portal_config_id");

  if (!portalConfigId) {
    return NextResponse.json({ error: "portal_config_id query parameter is required" }, { status: 400 });
  }

  // Validate UUID format
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(portalConfigId)) {
    return NextResponse.json({ error: "Invalid portal_config_id format" }, { status: 400 });
  }

  // Verify the user owns this portal config
  const { data: config } = await supabase
    .from("cs_portal_config")
    .select("id, company_slug, slug")
    .eq("id", portalConfigId)
    .eq("user_id", user.id)
    .eq("is_deleted", false)
    .maybeSingle();

  if (!config) {
    return NextResponse.json({ error: "Portal config not found" }, { status: 404 });
  }

  // Generate a temporary preview token with 1-hour expiry
  const previewToken = crypto.randomUUID();

  // Insert a temporary shared link for preview
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hour

  const { error: insertErr } = await supabase
    .from("cs_report_shared_links")
    .insert({
      token: previewToken,
      user_id: user.id,
      project_id: null,
      report_type: "project",
      link_type: "portal",
      expires_at: expiresAt,
      view_count: 0,
      max_views_per_day: 100,
      is_revoked: false,
    });

  if (insertErr) {
    console.error("[portal/preview] Preview token insert error:", insertErr);
    return NextResponse.json({ error: "Failed to generate preview token" }, { status: 500 });
  }

  const baseUrl = req.headers.get("x-forwarded-proto")
    ? `${req.headers.get("x-forwarded-proto")}://${req.headers.get("host")}`
    : `https://${req.headers.get("host") ?? "localhost:3000"}`;

  return NextResponse.json(
    {
      preview_url: `${baseUrl}/portal/preview/${previewToken}`,
      expires_at: expiresAt,
    },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
