// Portal analytics insert/read functions (D-21, D-43, D-102)
// Public portal view inserts use service-role client (no auth for viewers)
// Analytics reads use authenticated client (owner only)

import { createClient } from "@supabase/supabase-js";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import type { PortalAnalyticsEvent } from "./types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// Service-role client for public analytics inserts (bypasses RLS)
// ---------------------------------------------------------------------------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// recordPortalView — insert analytics event + increment view_count (D-102)
// ---------------------------------------------------------------------------

export async function recordPortalView(params: {
  portalConfigId: string;
  linkId: string;
  sectionViewed?: string;
  timeSpentMs?: number;
  scrollDepthPct?: number;
  ipHash?: string;
  userAgent?: string;
}): Promise<boolean> {
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[recordPortalView] Service client not available");
    return false;
  }

  try {
    // Insert analytics event
    const { error: insertErr } = await supabase
      .from("cs_portal_analytics")
      .insert({
        portal_config_id: params.portalConfigId,
        link_id: params.linkId,
        section_viewed: params.sectionViewed ?? null,
        time_spent_ms: params.timeSpentMs ?? null,
        scroll_depth_pct: params.scrollDepthPct ?? null,
        ip_hash: params.ipHash ?? null,
        user_agent: params.userAgent ?? null,
      });

    if (insertErr) {
      console.error("[recordPortalView] analytics insert error:", insertErr);
      return false;
    }

    // Increment view_count on cs_report_shared_links
    // Use raw RPC or manual increment since Supabase JS doesn't have atomic increment
    const { data: link } = await supabase
      .from("cs_report_shared_links")
      .select("view_count")
      .eq("id", params.linkId)
      .maybeSingle();

    if (link) {
      const currentCount = (link.view_count as number) ?? 0;
      await supabase
        .from("cs_report_shared_links")
        .update({ view_count: currentCount + 1 })
        .eq("id", params.linkId);
    }

    // Audit log for portal view
    await supabase.from("cs_portal_audit_log").insert({
      user_id: null, // anonymous viewer
      action: "portal_viewed",
      portal_config_id: params.portalConfigId,
      link_id: params.linkId,
      metadata: {
        section_viewed: params.sectionViewed,
        ip_hash: params.ipHash,
      },
    });

    return true;
  } catch (err) {
    console.error("[recordPortalView] exception:", err);
    return false;
  }
}

// ---------------------------------------------------------------------------
// getPortalAnalytics — aggregated analytics for portal owner (D-21, D-43)
// ---------------------------------------------------------------------------

export async function getPortalAnalytics(
  configId: string,
  days?: number
): Promise<{
  totalViews: number;
  perSectionViews: Record<string, number>;
  avgTimeSpentMs: number;
  avgScrollDepthPct: number;
  recentEvents: PortalAnalyticsEvent[];
}> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[getPortalAnalytics] Authentication required");
    return { totalViews: 0, perSectionViews: {}, avgTimeSpentMs: 0, avgScrollDepthPct: 0, recentEvents: [] };
  }

  try {
    let query = supabase
      .from("cs_portal_analytics")
      .select("*")
      .eq("portal_config_id", configId)
      .order("created_at", { ascending: false });

    // Optional date filter
    if (days) {
      const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString();
      query = query.gte("created_at", since);
    }

    const { data: events, error } = await query;

    if (error || !events) {
      if (error) console.error("[getPortalAnalytics] fetch error:", error);
      return { totalViews: 0, perSectionViews: {}, avgTimeSpentMs: 0, avgScrollDepthPct: 0, recentEvents: [] };
    }

    // Aggregate
    const totalViews = events.length;
    const perSectionViews: Record<string, number> = {};
    let totalTimeMs = 0;
    let timeCount = 0;
    let totalScroll = 0;
    let scrollCount = 0;

    for (const event of events) {
      const ev = event as SupabaseAny;
      if (ev.section_viewed) {
        perSectionViews[ev.section_viewed] = (perSectionViews[ev.section_viewed] ?? 0) + 1;
      }
      if (ev.time_spent_ms != null) {
        totalTimeMs += ev.time_spent_ms as number;
        timeCount++;
      }
      if (ev.scroll_depth_pct != null) {
        totalScroll += ev.scroll_depth_pct as number;
        scrollCount++;
      }
    }

    return {
      totalViews,
      perSectionViews,
      avgTimeSpentMs: timeCount > 0 ? Math.round(totalTimeMs / timeCount) : 0,
      avgScrollDepthPct: scrollCount > 0 ? Math.round(totalScroll / scrollCount) : 0,
      recentEvents: (events.slice(0, 50) as PortalAnalyticsEvent[]),
    };
  } catch (err) {
    console.error("[getPortalAnalytics] exception:", err);
    return { totalViews: 0, perSectionViews: {}, avgTimeSpentMs: 0, avgScrollDepthPct: 0, recentEvents: [] };
  }
}

// ---------------------------------------------------------------------------
// getPortalViewCount — quick view count for a link (D-21)
// ---------------------------------------------------------------------------

export async function getPortalViewCount(
  linkId: string
): Promise<{ totalViews: number; lastViewedAt: string | null }> {
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[getPortalViewCount] Service client not available");
    return { totalViews: 0, lastViewedAt: null };
  }

  try {
    // Get view_count from shared links
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("view_count")
      .eq("id", linkId)
      .maybeSingle();

    if (linkErr) {
      console.error("[getPortalViewCount] link fetch error:", linkErr);
      return { totalViews: 0, lastViewedAt: null };
    }

    // Get last viewed timestamp from analytics
    const { data: lastEvent, error: eventErr } = await supabase
      .from("cs_portal_analytics")
      .select("created_at")
      .eq("link_id", linkId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (eventErr) {
      console.error("[getPortalViewCount] analytics fetch error:", eventErr);
    }

    return {
      totalViews: (link?.view_count as number) ?? 0,
      lastViewedAt: (lastEvent?.created_at as string) ?? null,
    };
  } catch (err) {
    console.error("[getPortalViewCount] exception:", err);
    return { totalViews: 0, lastViewedAt: null };
  }
}
