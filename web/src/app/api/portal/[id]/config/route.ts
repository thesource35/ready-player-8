import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { updatePortalConfig } from "@/lib/portal/portalQueries";
import type { PortalConfig } from "@/lib/portal/types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// GET: Fetch portal config by id (D-97)
// ---------------------------------------------------------------------------

export async function GET(
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

  const { data: config, error } = await supabase
    .from("cs_portal_config")
    .select("*")
    .eq("id", id)
    .eq("user_id", user.id)
    .eq("is_deleted", false)
    .maybeSingle();

  if (error) {
    console.error("[portal/config/GET] Fetch error:", error);
    return NextResponse.json({ error: "Failed to fetch portal config" }, { status: 500 });
  }

  if (!config) {
    return NextResponse.json({ error: "Portal config not found" }, { status: 404 });
  }

  return NextResponse.json(
    { config: config as PortalConfig },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

// ---------------------------------------------------------------------------
// PUT: Update portal config (D-97)
// ---------------------------------------------------------------------------

export async function PUT(
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

  let body: Partial<PortalConfig>;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  // Verify ownership before update
  const { data: existing } = await supabase
    .from("cs_portal_config")
    .select("id")
    .eq("id", id)
    .eq("user_id", user.id)
    .eq("is_deleted", false)
    .maybeSingle();

  if (!existing) {
    return NextResponse.json({ error: "Portal config not found" }, { status: 404 });
  }

  // Strip immutable fields from update payload
  const {
    id: _id,
    link_id: _linkId,
    user_id: _userId,
    created_at: _createdAt,
    updated_at: _updatedAt,
    ...updates
  } = body as SupabaseAny;

  const updated = await updatePortalConfig(id, updates);
  if (!updated) {
    return NextResponse.json({ error: "Failed to update portal config" }, { status: 500 });
  }

  return NextResponse.json(
    { config: updated },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
