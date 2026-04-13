import { NextResponse } from "next/server";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { rateLimit, getRateLimitHeaders } from "@/lib/rate-limit";
import { listPortalLinks } from "@/lib/portal/portalQueries";

// ---------------------------------------------------------------------------
// GET: List user's portal links (D-26)
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
  const projectId = searchParams.get("project_id") ?? undefined;

  const links = await listPortalLinks(user.id, projectId);

  return NextResponse.json(
    { links },
    { status: 200, headers: getRateLimitHeaders(rl) }
  );
}
