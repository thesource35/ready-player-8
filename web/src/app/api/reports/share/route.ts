import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";

// D-64b: Shareable link CRUD — create, list, revoke
// D-64g: Role-based permissions (admin/manager can share, viewer cannot)
// D-110: Bulk revoke support
// D-119: Three-tier permission inheritance (org -> project -> report)

// ---------------------------------------------------------------------------
// Permission roles (D-64g)
// ---------------------------------------------------------------------------

type ReportRole = "admin" | "manager" | "viewer";

const ROLE_PERMISSIONS: Record<ReportRole, Set<string>> = {
  admin: new Set(["view", "export", "share", "schedule"]),
  manager: new Set(["view", "export", "share"]),
  viewer: new Set(["view"]),
};

/**
 * Resolve a user's effective report role. Checks three tiers (D-119):
 *   1. Report-level overrides (cs_report_permissions)
 *   2. Project-level role (cs_team_assignments)
 *   3. Org-level default (user_orgs)
 * Falls back to "manager" if no role data is available (allows sharing
 * for users who haven't configured org/team yet).
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

async function resolveReportRole(
  supabase: SupabaseAny,
  userId: string,
  _projectId: string | null
): Promise<ReportRole> {
  // Tier 1: report-level permission override
  // (cs_report_permissions table may not exist yet — gracefully degrade)
  try {
    const { data: perm } = await supabase
      .from("cs_report_permissions")
      .select("role")
      .eq("user_id", userId)
      .maybeSingle();
    const permRole = (perm as { role?: string } | null)?.role;
    if (permRole && ["admin", "manager", "viewer"].includes(permRole)) {
      return permRole as ReportRole;
    }
  } catch {
    // Table doesn't exist yet — continue to next tier
  }

  // Tier 2: project-level role from team assignments
  if (_projectId) {
    try {
      const { data: assignment } = await supabase
        .from("cs_team_assignments")
        .select("role")
        .eq("user_id", userId)
        .eq("project_id", _projectId)
        .maybeSingle();
      const assignRole = (assignment as { role?: string } | null)?.role;
      if (assignRole) {
        const r = assignRole.toLowerCase();
        if (r.includes("admin")) return "admin";
        if (r.includes("manager") || r.includes("pm") || r.includes("superintendent")) return "manager";
        return "viewer";
      }
    } catch {
      // Table may not exist — continue
    }
  }

  // Tier 3: org-level default
  try {
    const { data: orgRow } = await supabase
      .from("user_orgs")
      .select("role")
      .eq("user_id", userId)
      .maybeSingle();
    const orgRole = (orgRow as { role?: string } | null)?.role;
    if (orgRole) {
      const r = orgRole.toLowerCase();
      if (r.includes("admin") || r.includes("owner")) return "admin";
      if (r.includes("manager")) return "manager";
      return "viewer";
    }
  } catch {
    // Table may not exist
  }

  // Default: allow sharing (manager) until permission tables are configured
  return "manager";
}

// ---------------------------------------------------------------------------
// POST: Create a shareable link (D-64b)
// ---------------------------------------------------------------------------

export async function POST(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
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

  let body: { project_id?: string; report_type?: string };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const reportType = body.report_type ?? "project";
  if (!["project", "rollup"].includes(reportType)) {
    return NextResponse.json({ error: "Invalid report_type. Must be 'project' or 'rollup'." }, { status: 400 });
  }

  const projectId = body.project_id ?? null;
  if (reportType === "project" && !projectId) {
    return NextResponse.json({ error: "project_id is required for project reports" }, { status: 400 });
  }

  // D-64g: check role-based permissions before allowing share creation
  const role = await resolveReportRole(supabase, user.id, projectId);
  if (!ROLE_PERMISSIONS[role].has("share")) {
    return NextResponse.json(
      { error: "Insufficient permissions. Viewers cannot create shared links." },
      { status: 403 }
    );
  }

  // D-64b: generate cryptographically random token (T-19-24: 122 bits entropy)
  const token = crypto.randomUUID();

  // D-64b: 30-day expiry
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

  const { data: link, error: insertErr } = await supabase
    .from("cs_report_shared_links")
    .insert({
      token,
      user_id: user.id,
      project_id: projectId,
      report_type: reportType,
      expires_at: expiresAt,
      view_count: 0,
      max_views_per_day: 100, // D-64e
      is_revoked: false,
    })
    .select()
    .single();

  if (insertErr || !link) {
    console.error("[share/POST] Insert error:", insertErr);
    return NextResponse.json({ error: "Failed to create shared link" }, { status: 500 });
  }

  // D-112: Log to audit log (T-19-26: repudiation mitigation)
  await supabase.from("cs_report_audit_log").insert({
    user_id: user.id,
    action: "shared",
    report_type: reportType,
    project_id: projectId,
    metadata: { token, link_id: link.id },
  });

  const baseUrl = req.headers.get("x-forwarded-proto")
    ? `${req.headers.get("x-forwarded-proto")}://${req.headers.get("host")}`
    : `https://${req.headers.get("host") ?? "localhost:3000"}`;

  return NextResponse.json(
    {
      id: link.id,
      token,
      url: `${baseUrl}/reports/shared/${token}`,
      expires_at: expiresAt,
      report_type: reportType,
      project_id: projectId,
    },
    { status: 201, headers: getRateLimitHeaders(rl) }
  );
}

// ---------------------------------------------------------------------------
// GET: List user's shared links with view counts
// ---------------------------------------------------------------------------

export async function GET(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
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

  const { data: links, error } = await supabase
    .from("cs_report_shared_links")
    .select("*")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  if (error) {
    console.error("[share/GET] Fetch error:", error);
    return NextResponse.json({ error: "Failed to fetch shared links" }, { status: 500 });
  }

  return NextResponse.json(
    { links: links ?? [] },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}

// ---------------------------------------------------------------------------
// DELETE: Revoke link(s) — single ID or array of IDs (D-64b, D-110)
// ---------------------------------------------------------------------------

export async function DELETE(req: Request) {
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "anonymous";
  const rl = await rateLimit(ip, "/api/reports");
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

  let body: { id?: string; ids?: string[] };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  // D-110: bulk revoke support — accept single id or array of ids
  const linkIds: string[] = body.ids ?? (body.id ? [body.id] : []);
  if (linkIds.length === 0) {
    return NextResponse.json({ error: "Provide 'id' or 'ids' to revoke" }, { status: 400 });
  }

  // Set is_revoked = true (soft delete) only for links owned by this user
  const { data: revoked, error: revokeErr } = await supabase
    .from("cs_report_shared_links")
    .update({ is_revoked: true })
    .eq("user_id", user.id)
    .in("id", linkIds)
    .select("id");

  if (revokeErr) {
    console.error("[share/DELETE] Revoke error:", revokeErr);
    return NextResponse.json({ error: "Failed to revoke link(s)" }, { status: 500 });
  }

  // D-112: audit log
  await supabase.from("cs_report_audit_log").insert({
    user_id: user.id,
    action: "shared",
    metadata: { action: "revoke", link_ids: linkIds, revoked_count: revoked?.length ?? 0 },
  });

  return NextResponse.json(
    { revoked: revoked?.length ?? 0, ids: revoked?.map((r: { id: string }) => r.id) ?? [] },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
