// IP blocking utility for portal viewing (D-119, T-20-29)
// Stores blocked IPs in cs_portal_config.metadata JSONB field
// as { blocked_ips: string[] } to avoid a separate table.

import { createClient } from "@supabase/supabase-js";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

type PortalMetadata = {
  blocked_ips?: string[];
  [key: string]: unknown;
};

// ---------------------------------------------------------------------------
// Service-role client for public portal access checks
// ---------------------------------------------------------------------------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// Audit logging helper
// ---------------------------------------------------------------------------

async function logIPAudit(
  supabase: SupabaseAny,
  action: "ip_blocked",
  metadata: Record<string, unknown>,
  options: { userId: string; portalConfigId: string }
): Promise<void> {
  try {
    await supabase.from("cs_portal_audit_log").insert({
      user_id: options.userId,
      action,
      portal_config_id: options.portalConfigId,
      link_id: null,
      metadata,
    });
  } catch (err) {
    console.error("[ipBlocker] Failed to write audit log:", err);
  }
}

// ---------------------------------------------------------------------------
// isIPBlocked — check if IP is in blocked list (public/service-role)
// ---------------------------------------------------------------------------

export async function isIPBlocked(
  portalConfigId: string,
  ip: string
): Promise<boolean> {
  const supabase = getServiceClient();
  if (!supabase) return false;

  try {
    const { data, error } = await supabase
      .from("cs_portal_config")
      .select("metadata")
      .eq("id", portalConfigId)
      .maybeSingle();

    if (error || !data) return false;

    const metadata = (data.metadata ?? {}) as PortalMetadata;
    const blocked_ips = metadata.blocked_ips ?? [];
    return blocked_ips.includes(ip);
  } catch (err) {
    console.error("[isIPBlocked] exception:", err);
    return false;
  }
}

// ---------------------------------------------------------------------------
// blockIP — add IP to blocked list (authenticated)
// ---------------------------------------------------------------------------

export async function blockIP(
  portalConfigId: string,
  ip: string,
  userId: string
): Promise<void> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    throw new Error("Authentication required");
  }

  // Verify ownership
  const { data: config, error: fetchErr } = await supabase
    .from("cs_portal_config")
    .select("id, metadata")
    .eq("id", portalConfigId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (fetchErr || !config) {
    throw new Error("Portal not found or access denied");
  }

  const metadata = (config.metadata ?? {}) as PortalMetadata;
  const blocked_ips = metadata.blocked_ips ?? [];

  // Avoid duplicates
  if (blocked_ips.includes(ip)) return;

  const updatedMetadata: PortalMetadata = {
    ...metadata,
    blocked_ips: [...blocked_ips, ip],
  };

  const { error: updateErr } = await supabase
    .from("cs_portal_config")
    .update({ metadata: updatedMetadata })
    .eq("id", portalConfigId)
    .eq("user_id", user.id);

  if (updateErr) {
    console.error("[blockIP] update error:", updateErr);
    throw new Error("Failed to block IP");
  }

  // Audit log
  await logIPAudit(supabase, "ip_blocked", {
    ip,
    action_type: "block",
  }, { userId, portalConfigId });
}

// ---------------------------------------------------------------------------
// unblockIP — remove IP from blocked list (authenticated)
// ---------------------------------------------------------------------------

export async function unblockIP(
  portalConfigId: string,
  ip: string,
  userId: string
): Promise<void> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    throw new Error("Authentication required");
  }

  // Verify ownership
  const { data: config, error: fetchErr } = await supabase
    .from("cs_portal_config")
    .select("id, metadata")
    .eq("id", portalConfigId)
    .eq("user_id", user.id)
    .maybeSingle();

  if (fetchErr || !config) {
    throw new Error("Portal not found or access denied");
  }

  const metadata = (config.metadata ?? {}) as PortalMetadata;
  const blocked_ips = metadata.blocked_ips ?? [];

  const updatedMetadata: PortalMetadata = {
    ...metadata,
    blocked_ips: blocked_ips.filter((blocked) => blocked !== ip),
  };

  const { error: updateErr } = await supabase
    .from("cs_portal_config")
    .update({ metadata: updatedMetadata })
    .eq("id", portalConfigId)
    .eq("user_id", user.id);

  if (updateErr) {
    console.error("[unblockIP] update error:", updateErr);
    throw new Error("Failed to unblock IP");
  }

  // Audit log
  await logIPAudit(supabase, "ip_blocked", {
    ip,
    action_type: "unblock",
  }, { userId, portalConfigId });
}

// ---------------------------------------------------------------------------
// getBlockedIPs — list blocked IPs for management UI (authenticated)
// ---------------------------------------------------------------------------

export async function getBlockedIPs(
  portalConfigId: string
): Promise<string[]> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) return [];

  try {
    const { data, error } = await supabase
      .from("cs_portal_config")
      .select("metadata")
      .eq("id", portalConfigId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (error || !data) return [];

    const metadata = (data.metadata ?? {}) as PortalMetadata;
    return metadata.blocked_ips ?? [];
  } catch (err) {
    console.error("[getBlockedIPs] exception:", err);
    return [];
  }
}
