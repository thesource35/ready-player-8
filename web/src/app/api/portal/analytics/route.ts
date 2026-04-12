import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { getPortalAnalytics } from "@/lib/portal/analyticsQueries";

// ---------------------------------------------------------------------------
// GET: Fetch portal analytics (D-21, D-43)
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
  const daysParam = searchParams.get("days");

  if (!portalConfigId) {
    return NextResponse.json({ error: "portal_config_id query parameter is required" }, { status: 400 });
  }

  // Validate UUID format (prevent injection)
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(portalConfigId)) {
    return NextResponse.json({ error: "Invalid portal_config_id format" }, { status: 400 });
  }

  // Verify the user owns this portal config
  const { data: config } = await supabase
    .from("cs_portal_config")
    .select("id")
    .eq("id", portalConfigId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (!config) {
    return NextResponse.json({ error: "Portal config not found" }, { status: 404 });
  }

  const days = daysParam ? parseInt(daysParam, 10) : 30;
  if (isNaN(days) || days < 1 || days > 365) {
    return NextResponse.json({ error: "days must be between 1 and 365" }, { status: 400 });
  }

  const analytics = await getPortalAnalytics(portalConfigId, days);

  return NextResponse.json(
    { analytics },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
