// Portal CRUD query helpers (D-97 through D-112)
// Management operations use getAuthenticatedClient() (RLS-enforced)
// Public portal viewing uses service-role client (bypasses RLS)

import { createClient } from "@supabase/supabase-js";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import type { PortalConfig, PortalTemplate, PortalSectionsConfig, PortalAuditAction } from "./types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// Service-role client for public portal access (bypasses RLS)
// ---------------------------------------------------------------------------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// Audit logging helper (D-114)
// ---------------------------------------------------------------------------

async function logPortalAudit(
  supabase: SupabaseAny,
  action: PortalAuditAction,
  metadata: Record<string, unknown>,
  options?: { userId?: string; portalConfigId?: string; linkId?: string }
): Promise<void> {
  try {
    await supabase.from("cs_portal_audit_log").insert({
      user_id: options?.userId ?? null,
      action,
      portal_config_id: options?.portalConfigId ?? null,
      link_id: options?.linkId ?? null,
      metadata,
    });
  } catch (err) {
    console.error("[logPortalAudit] Failed to write audit log:", err);
  }
}

// ---------------------------------------------------------------------------
// createPortalLink — inserts shared link + portal config (D-97)
// ---------------------------------------------------------------------------

export async function createPortalLink(params: {
  projectId: string;
  slug: string;
  companySlug: string;
  template: PortalTemplate;
  sectionsConfig: PortalSectionsConfig;
  expiryDays: number | null;
  clientEmail?: string;
  userId: string;
  orgId?: string;
}): Promise<{ link: Record<string, unknown>; config: PortalConfig }> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    throw new Error("Authentication required");
  }

  const token = crypto.randomUUID();

  const expiresAt = params.expiryDays
    ? new Date(Date.now() + params.expiryDays * 24 * 60 * 60 * 1000).toISOString()
    : null;

  // Step 1: Insert into cs_report_shared_links with link_type='portal'
  const { data: link, error: linkErr } = await supabase
    .from("cs_report_shared_links")
    .insert({
      token,
      user_id: params.userId,
      project_id: params.projectId,
      report_type: "project",
      link_type: "portal",
      expires_at: expiresAt,
      view_count: 0,
      max_views_per_day: 100,
      is_revoked: false,
    })
    .select()
    .single();

  if (linkErr || !link) {
    console.error("[createPortalLink] cs_report_shared_links insert error:", linkErr);
    throw new Error("Failed to create portal shared link");
  }

  // Step 2: Insert into cs_portal_config
  const { data: config, error: configErr } = await supabase
    .from("cs_portal_config")
    .insert({
      link_id: link.id,
      project_id: params.projectId,
      user_id: params.userId,
      org_id: params.orgId ?? null,
      slug: params.slug,
      company_slug: params.companySlug,
      template: params.template,
      sections_config: params.sectionsConfig,
      client_email: params.clientEmail ?? null,
    })
    .select()
    .single();

  if (configErr || !config) {
    console.error("[createPortalLink] cs_portal_config insert error:", configErr);
    // Clean up the shared link if config insert fails
    await supabase.from("cs_report_shared_links").delete().eq("id", link.id);
    throw new Error("Failed to create portal configuration");
  }

  // Audit log
  await logPortalAudit(supabase, "link_created", {
    token,
    slug: params.slug,
    company_slug: params.companySlug,
    template: params.template,
    expiry_days: params.expiryDays,
  }, { userId: params.userId, portalConfigId: config.id, linkId: link.id });

  return { link: link as Record<string, unknown>, config: config as PortalConfig };
}

// ---------------------------------------------------------------------------
// getPortalBySlug — public portal lookup by branded URL (D-24)
// ---------------------------------------------------------------------------

export async function getPortalBySlug(
  companySlug: string,
  slug: string
): Promise<(PortalConfig & { token: string; expires_at: string | null; view_count: number }) | null> {
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[getPortalBySlug] Service client not available");
    return null;
  }

  try {
    const { data: config, error: configErr } = await supabase
      .from("cs_portal_config")
      .select("*")
      .eq("company_slug", companySlug)
      .eq("slug", slug)
      .eq("is_deleted", false)
      .maybeSingle();

    if (configErr || !config) {
      if (configErr) console.error("[getPortalBySlug] config lookup error:", configErr);
      return null;
    }

    // Fetch the associated shared link to check expiry/revocation
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("token, expires_at, is_revoked, view_count")
      .eq("id", config.link_id)
      .maybeSingle();

    if (linkErr || !link) {
      if (linkErr) console.error("[getPortalBySlug] link lookup error:", linkErr);
      return null;
    }

    // Check: not revoked, not expired
    if (link.is_revoked) return null;
    if (link.expires_at && new Date(link.expires_at) < new Date()) return null;

    return {
      ...(config as PortalConfig),
      token: link.token as string,
      expires_at: link.expires_at as string | null,
      view_count: (link.view_count as number) ?? 0,
    };
  } catch (err) {
    console.error("[getPortalBySlug] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// getPortalByToken — public portal lookup by token (D-06)
// ---------------------------------------------------------------------------

export async function getPortalByToken(
  token: string
): Promise<(PortalConfig & { token: string; expires_at: string | null; view_count: number }) | null> {
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[getPortalByToken] Service client not available");
    return null;
  }

  try {
    // Find the shared link by token
    const { data: link, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("id, token, expires_at, is_revoked, view_count")
      .eq("token", token)
      .eq("link_type", "portal")
      .maybeSingle();

    if (linkErr || !link) {
      if (linkErr) console.error("[getPortalByToken] link lookup error:", linkErr);
      return null;
    }

    // Check: not revoked, not expired
    if (link.is_revoked) return null;
    if (link.expires_at && new Date(link.expires_at) < new Date()) return null;

    // Find the portal config
    const { data: config, error: configErr } = await supabase
      .from("cs_portal_config")
      .select("*")
      .eq("link_id", link.id)
      .eq("is_deleted", false)
      .maybeSingle();

    if (configErr || !config) {
      if (configErr) console.error("[getPortalByToken] config lookup error:", configErr);
      return null;
    }

    return {
      ...(config as PortalConfig),
      token: link.token as string,
      expires_at: link.expires_at as string | null,
      view_count: (link.view_count as number) ?? 0,
    };
  } catch (err) {
    console.error("[getPortalByToken] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// updatePortalConfig — authenticated update (D-97)
// ---------------------------------------------------------------------------

export async function updatePortalConfig(
  configId: string,
  updates: Partial<Omit<PortalConfig, "id" | "link_id" | "user_id" | "created_at" | "updated_at">>
): Promise<PortalConfig | null> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[updatePortalConfig] Authentication required");
    return null;
  }

  try {
    const { data, error } = await supabase
      .from("cs_portal_config")
      .update(updates)
      .eq("id", configId)
      .eq("user_id", user.id) // RLS + application-level guard
      .select()
      .single();

    if (error) {
      console.error("[updatePortalConfig] update error:", error);
      return null;
    }

    // Audit log
    await logPortalAudit(supabase, "config_updated", {
      config_id: configId,
      updated_fields: Object.keys(updates),
    }, { userId: user.id, portalConfigId: configId });

    return data as PortalConfig;
  } catch (err) {
    console.error("[updatePortalConfig] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// revokePortalLink — soft revoke on shared link (D-116)
// ---------------------------------------------------------------------------

export async function revokePortalLink(linkId: string): Promise<boolean> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[revokePortalLink] Authentication required");
    return false;
  }

  try {
    const { error } = await supabase
      .from("cs_report_shared_links")
      .update({ is_revoked: true })
      .eq("id", linkId)
      .eq("user_id", user.id);

    if (error) {
      console.error("[revokePortalLink] revoke error:", error);
      return false;
    }

    // Audit log
    await logPortalAudit(supabase, "link_revoked", {
      link_id: linkId,
    }, { userId: user.id, linkId });

    return true;
  } catch (err) {
    console.error("[revokePortalLink] exception:", err);
    return false;
  }
}

// ---------------------------------------------------------------------------
// deletePortalLink — soft delete on portal config (D-116)
// ---------------------------------------------------------------------------

export async function deletePortalLink(configId: string): Promise<boolean> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[deletePortalLink] Authentication required");
    return false;
  }

  try {
    const { error } = await supabase
      .from("cs_portal_config")
      .update({ is_deleted: true })
      .eq("id", configId)
      .eq("user_id", user.id);

    if (error) {
      console.error("[deletePortalLink] delete error:", error);
      return false;
    }

    // Audit log
    await logPortalAudit(supabase, "link_deleted", {
      config_id: configId,
    }, { userId: user.id, portalConfigId: configId });

    return true;
  } catch (err) {
    console.error("[deletePortalLink] exception:", err);
    return false;
  }
}

// ---------------------------------------------------------------------------
// listPortalLinks — list user's portal configs (D-26)
// ---------------------------------------------------------------------------

export async function listPortalLinks(
  userId: string,
  projectId?: string
): Promise<(PortalConfig & { token: string; expires_at: string | null; view_count: number; is_revoked: boolean })[]> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[listPortalLinks] Authentication required");
    return [];
  }

  try {
    let query = supabase
      .from("cs_portal_config")
      .select("*")
      .eq("user_id", userId)
      .eq("is_deleted", false)
      .order("created_at", { ascending: false });

    if (projectId) {
      query = query.eq("project_id", projectId);
    }

    const { data: configs, error: configErr } = await query;

    if (configErr || !configs || configs.length === 0) {
      if (configErr) console.error("[listPortalLinks] config fetch error:", configErr);
      return [];
    }

    // Fetch associated shared links for token, expiry, view_count
    const linkIds = configs.map((c: SupabaseAny) => c.link_id as string);
    const { data: links, error: linkErr } = await supabase
      .from("cs_report_shared_links")
      .select("id, token, expires_at, view_count, is_revoked")
      .in("id", linkIds);

    if (linkErr) {
      console.error("[listPortalLinks] link fetch error:", linkErr);
      return [];
    }

    const linkMap = new Map<string, { token: string; expires_at: string | null; view_count: number; is_revoked: boolean }>();
    for (const link of (links ?? [])) {
      linkMap.set(link.id as string, {
        token: link.token as string,
        expires_at: link.expires_at as string | null,
        view_count: (link.view_count as number) ?? 0,
        is_revoked: (link.is_revoked as boolean) ?? false,
      });
    }

    return configs.map((config: SupabaseAny) => {
      const linkData = linkMap.get(config.link_id as string);
      return {
        ...(config as PortalConfig),
        token: linkData?.token ?? "",
        expires_at: linkData?.expires_at ?? null,
        view_count: linkData?.view_count ?? 0,
        is_revoked: linkData?.is_revoked ?? false,
      };
    });
  } catch (err) {
    console.error("[listPortalLinks] exception:", err);
    return [];
  }
}
