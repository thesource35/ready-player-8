import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-114: Immutable audit log — read-only endpoint
// Returns audit events for a portal config (INSERT-only RLS on cs_portal_audit_log)

// ---------------------------------------------------------------------------
// GET: Fetch audit log for a portal config (D-114)
// ---------------------------------------------------------------------------

export async function GET(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/portal");
  if (!rl.success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Try again later." },
      { status: 429, headers: getRateLimitHeaders(rl) }
    );
  }

  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    return NextResponse.json(
      { error: "Authentication required" },
      { status: 401 }
    );
  }

  // Parse query parameters
  const url = new URL(req.url);
  const daysParam = url.searchParams.get("days");
  const limitParam = url.searchParams.get("limit");

  const days = daysParam ? Math.min(Math.max(parseInt(daysParam, 10) || 30, 1), 365) : 30;
  const limit = limitParam ? Math.min(Math.max(parseInt(limitParam, 10) || 100, 1), 1000) : 100;

  // Verify requesting user owns the portal config
  const { data: config, error: configErr } = await supabase
    .from("cs_portal_config")
    .select("id, user_id, link_id")
    .eq("id", id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (configErr) {
    console.error("[audit] config lookup error:", configErr);
    return NextResponse.json(
      { error: "Failed to verify portal ownership" },
      { status: 500 }
    );
  }

  if (!config) {
    return NextResponse.json(
      { error: "Portal not found or access denied" },
      { status: 404 }
    );
  }

  // Calculate date threshold
  const sinceDate = new Date(
    Date.now() - days * 24 * 60 * 60 * 1000
  ).toISOString();

  // Fetch audit events for this portal config or its associated link
  const { data: events, error: auditErr } = await supabase
    .from("cs_portal_audit_log")
    .select("id, action, metadata, created_at, user_id, portal_config_id, link_id")
    .or(`portal_config_id.eq.${id},link_id.eq.${config.link_id}`)
    .gte("created_at", sinceDate)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (auditErr) {
    console.error("[audit] fetch error:", auditErr);
    return NextResponse.json(
      { error: "Failed to fetch audit log" },
      { status: 500 }
    );
  }

  return NextResponse.json({
    portal_config_id: id,
    days,
    count: events?.length ?? 0,
    events: events ?? [],
  });
}
