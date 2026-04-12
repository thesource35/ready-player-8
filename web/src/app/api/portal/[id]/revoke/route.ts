import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// ---------------------------------------------------------------------------
// POST: Revoke a portal link (D-116 — soft revoke)
// ---------------------------------------------------------------------------

export async function POST(
  req: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

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

  // Fetch portal config to get link_id (verify ownership)
  const { data: config, error: configErr } = await supabase
    .from("cs_portal_config")
    .select("id, link_id")
    .eq("id", id)
    .eq("user_id", user.id)
    .eq("is_deleted", false)
    .maybeSingle();

  if (configErr) {
    console.error("[portal/revoke] Config lookup error:", configErr);
    return NextResponse.json({ error: "Failed to look up portal config" }, { status: 500 });
  }

  if (!config) {
    return NextResponse.json({ error: "Portal config not found" }, { status: 404 });
  }

  const linkId = (config as { link_id: string }).link_id;

  // Soft revoke the shared link (D-116)
  const { error: revokeErr } = await supabase
    .from("cs_report_shared_links")
    .update({ is_revoked: true })
    .eq("id", linkId)
    .eq("user_id", user.id);

  if (revokeErr) {
    console.error("[portal/revoke] Revoke error:", revokeErr);
    return NextResponse.json({ error: "Failed to revoke portal link" }, { status: 500 });
  }

  // Audit log (D-114)
  await supabase.from("cs_portal_audit_log").insert({
    user_id: user.id,
    action: "link_revoked",
    portal_config_id: id,
    link_id: linkId,
    metadata: { revoked_at: new Date().toISOString() },
  });

  return NextResponse.json(
    { revoked: true },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
