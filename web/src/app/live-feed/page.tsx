// Phase 29 LIVE-03 — /live-feed server component.
// Mirrors web/src/app/maps/page.tsx pattern: auth check, fetch projects via RLS, hand off to client component.

import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase/server";
import { getPageMetadata } from "@/lib/seo";
import { LiveFeedClient } from "./LiveFeedClient";

export const metadata: Metadata = getPageMetadata("live-feed");
export const dynamic = "force-dynamic";

export type LiveFeedProject = { id: string; name: string; client: string | null };

export default async function LiveFeedPage() {
  const supabase = await createServerSupabase();
  // Supabase not configured (local dev without env) — render empty-state shell rather than crash.
  if (!supabase) {
    return <LiveFeedClient projects={[]} />;
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // RLS scopes projects to the user's orgs. No service-role client.
  const { data: projects, error } = await supabase
    .from("cs_projects")
    .select("id, name, client")
    .order("name", { ascending: true });

  if (error) {
    // Surface the failure — no silent fallback to mock data here.
    console.error("[live-feed] cs_projects fetch failed:", error.message);
  }

  return <LiveFeedClient projects={(projects ?? []) as LiveFeedProject[]} />;
}
