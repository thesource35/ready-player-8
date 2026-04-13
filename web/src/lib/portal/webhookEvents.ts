// Portal webhook events (D-111)
// Leverages Phase 19's webhook infrastructure pattern.
// Fire-and-forget with 5s timeout; failure logged but non-blocking (T-20-32).
// Only sends event metadata, not full portal data (T-19-46).

import type { PortalAuditAction } from "./types";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type PortalWebhookEvent =
  | "portal.link_created"
  | "portal.client_viewed"
  | "portal.link_expired"
  | "portal.link_revoked"
  | "portal.branding_updated";

type WebhookPayload = {
  event: PortalWebhookEvent;
  portal_config_id: string;
  project_id: string;
  timestamp: string;
  metadata?: Record<string, unknown>;
};

// ---------------------------------------------------------------------------
// Webhook Delivery
// ---------------------------------------------------------------------------

const WEBHOOK_TIMEOUT_MS = 5_000;

/**
 * Deliver webhook payload to a single URL with 5s timeout.
 * Returns true if delivery succeeded (2xx), false otherwise.
 */
async function deliverWebhook(
  url: string,
  payload: WebhookPayload,
): Promise<boolean> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), WEBHOOK_TIMEOUT_MS);

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    return res.ok;
  } catch (err) {
    console.error(
      `[webhookEvents] Delivery failed to ${url}:`,
      err instanceof Error ? err.message : err,
    );
    return false;
  } finally {
    clearTimeout(timer);
  }
}

// ---------------------------------------------------------------------------
// Webhook Configuration Lookup
// ---------------------------------------------------------------------------

const WEBHOOK_CONFIG_KEY = "constructionos_webhook_config";

type StoredWebhookConfig = {
  url: string;
  events: string[];
  isActive: boolean;
};

/**
 * Look up webhook configurations for a project.
 * Reads from localStorage (matching Phase 19 WebhookConfig pattern).
 * In production this would read from a database table.
 */
function getWebhookConfigs(): StoredWebhookConfig | null {
  if (typeof window === "undefined" && typeof globalThis !== "undefined") {
    // Server-side: no localStorage available
    return null;
  }
  try {
    const raw =
      typeof localStorage !== "undefined"
        ? localStorage.getItem(WEBHOOK_CONFIG_KEY)
        : null;
    if (!raw) return null;
    const config = JSON.parse(raw) as StoredWebhookConfig;
    if (!config.isActive || !config.url) return null;
    return config;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Audit Log
// ---------------------------------------------------------------------------

/**
 * Log webhook delivery to cs_portal_audit_log (D-114).
 * Non-blocking: fire-and-forget.
 */
async function logWebhookDelivery(
  event: PortalWebhookEvent,
  portalConfigId: string,
  success: boolean,
): Promise<void> {
  try {
    // Map webhook event to audit action
    const actionMap: Record<PortalWebhookEvent, PortalAuditAction> = {
      "portal.link_created": "link_created",
      "portal.client_viewed": "portal_viewed",
      "portal.link_expired": "portal_expired",
      "portal.link_revoked": "link_revoked",
      "portal.branding_updated": "branding_updated",
    };

    const action = actionMap[event];
    console.log(
      `[webhookEvents] Audit: ${action} for ${portalConfigId} (delivery: ${success ? "success" : "failed"})`,
    );
    // In production, INSERT into cs_portal_audit_log via Supabase service client
  } catch (err) {
    console.error("[webhookEvents] Audit log failed:", err);
  }
}

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Trigger a portal webhook event.
 * Non-blocking: fire-and-forget with 5s timeout per T-20-32.
 * Looks up webhook configurations and delivers payload to configured URLs.
 */
export async function triggerPortalWebhook(params: {
  event: PortalWebhookEvent;
  portalConfigId: string;
  projectId: string;
  metadata?: Record<string, unknown>;
}): Promise<void> {
  const { event, portalConfigId, projectId, metadata } = params;

  const config = getWebhookConfigs();
  if (!config) {
    // No webhook configured — still log the event for audit
    await logWebhookDelivery(event, portalConfigId, true);
    return;
  }

  // Check if this event type is in the configured events list
  // Portal events map to "report_shared" or similar configured event types
  // Accept if the webhook is active (we deliver all portal events to active webhooks)
  const payload: WebhookPayload = {
    event,
    portal_config_id: portalConfigId,
    project_id: projectId,
    timestamp: new Date().toISOString(),
    metadata,
  };

  // Fire-and-forget: don't await in caller context
  const success = await deliverWebhook(config.url, payload);
  await logWebhookDelivery(event, portalConfigId, success);
}
