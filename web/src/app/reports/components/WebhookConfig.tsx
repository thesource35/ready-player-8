"use client";

/**
 * WebhookConfig: Configure webhook URL and events for report API integration.
 * Per D-56h: Report API webhook events for Zapier/Make integration.
 * Per D-114: JSON API endpoints listed for external tool integration.
 * Per T-19-46: Only send event metadata (not full report data) to webhooks.
 * Per T-19-47: Timeout webhook calls at 5s; retry once; log failures.
 */

import { useState, useCallback } from "react";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type WebhookEvent =
  | "report_generated"
  | "report_exported"
  | "report_shared"
  | "schedule_delivered";

type WebhookConfig = {
  url: string;
  events: WebhookEvent[];
  isActive: boolean;
};

type WebhookConfigProps = {
  config?: WebhookConfig;
  onSave?: (config: WebhookConfig) => void;
};

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const WEBHOOK_EVENTS: { id: WebhookEvent; label: string; description: string }[] = [
  {
    id: "report_generated",
    label: "Report Generated",
    description: "Fires when a new project or portfolio report is generated",
  },
  {
    id: "report_exported",
    label: "Report Exported",
    description: "Fires when a report is exported as PDF, CSV, Excel, or PowerPoint",
  },
  {
    id: "report_shared",
    label: "Report Shared",
    description: "Fires when a report sharing link is created or sent",
  },
  {
    id: "schedule_delivered",
    label: "Schedule Delivered",
    description: "Fires when a scheduled report email is delivered",
  },
];

const STORAGE_KEY = "constructionos.reports.webhookConfig";

// T-19-47: Webhook call timeout
const WEBHOOK_TIMEOUT_MS = 5000;

// ---------------------------------------------------------------------------
// Webhook Delivery (T-19-46, T-19-47)
// ---------------------------------------------------------------------------

/**
 * Send webhook event with metadata only (T-19-46).
 * Times out at 5s, retries once on failure (T-19-47).
 */
export async function sendWebhookEvent(
  url: string,
  event: WebhookEvent,
  metadata: Record<string, string | number>
): Promise<{ success: boolean; error?: string }> {
  // T-19-46: Only send event type + metadata, not full report data
  const payload = {
    event,
    timestamp: new Date().toISOString(),
    metadata,
  };

  for (let attempt = 0; attempt < 2; attempt++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), WEBHOOK_TIMEOUT_MS);

      const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timeout);

      if (response.ok) {
        return { success: true };
      }

      // Non-OK response -- retry once
      if (attempt === 0) {
        console.warn(`[webhook] Attempt 1 failed (${response.status}), retrying...`);
        continue;
      }

      return { success: false, error: `HTTP ${response.status}` };
    } catch (err) {
      if (attempt === 0) {
        console.warn("[webhook] Attempt 1 failed, retrying...", err);
        continue;
      }

      const message = err instanceof Error ? err.message : "Unknown error";
      console.error("[webhook] Delivery failed after 2 attempts:", message);
      return { success: false, error: message };
    }
  }

  return { success: false, error: "Max retries exceeded" };
}

// ---------------------------------------------------------------------------
// Storage Helpers
// ---------------------------------------------------------------------------

function loadConfig(): WebhookConfig {
  if (typeof window === "undefined") {
    return { url: "", events: [], isActive: false };
  }
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored
      ? JSON.parse(stored)
      : { url: "", events: [], isActive: false };
  } catch {
    return { url: "", events: [], isActive: false };
  }
}

function saveConfig(config: WebhookConfig): void {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
  } catch {
    console.error("[WebhookConfig] Failed to save to localStorage");
  }
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export default function WebhookConfigPanel({ config: initialConfig, onSave }: WebhookConfigProps) {
  const [config, setConfig] = useState<WebhookConfig>(() => initialConfig ?? loadConfig());
  const [testStatus, setTestStatus] = useState<"idle" | "sending" | "success" | "error">("idle");
  const [testError, setTestError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const handleUrlChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    setConfig((prev) => ({ ...prev, url: e.target.value }));
    setSaved(false);
  }, []);

  const handleToggleEvent = useCallback((eventId: WebhookEvent) => {
    setConfig((prev) => ({
      ...prev,
      events: prev.events.includes(eventId)
        ? prev.events.filter((e) => e !== eventId)
        : [...prev.events, eventId],
    }));
    setSaved(false);
  }, []);

  const handleToggleActive = useCallback(() => {
    setConfig((prev) => ({ ...prev, isActive: !prev.isActive }));
    setSaved(false);
  }, []);

  const handleSave = useCallback(() => {
    saveConfig(config);
    onSave?.(config);
    setSaved(true);
    setTimeout(() => setSaved(false), 3000);
  }, [config, onSave]);

  const handleTestWebhook = useCallback(async () => {
    if (!config.url.trim()) {
      setTestError("Enter a webhook URL first");
      setTestStatus("error");
      return;
    }

    setTestStatus("sending");
    setTestError(null);

    const result = await sendWebhookEvent(config.url, "report_generated", {
      test: 1,
      source: "constructionos",
      message: "Test webhook from ConstructionOS Reports",
    });

    if (result.success) {
      setTestStatus("success");
      setTimeout(() => setTestStatus("idle"), 3000);
    } else {
      setTestStatus("error");
      setTestError(result.error ?? "Unknown error");
    }
  }, [config.url]);

  const inputStyle: React.CSSProperties = {
    width: "100%",
    background: "var(--surface, #111d33)",
    border: "1px solid var(--border, #1e3a5f)",
    borderRadius: 8,
    color: "var(--text, #e2e8f0)",
    padding: "10px 14px",
    fontSize: 14,
  };

  const buttonStyle: React.CSSProperties = {
    border: "none",
    borderRadius: 8,
    padding: "8px 18px",
    fontSize: 13,
    fontWeight: 600,
    cursor: "pointer",
  };

  return (
    <div
      style={{
        padding: 20,
        background: "var(--surface, #111d33)",
        borderRadius: 14,
        border: "1px solid var(--border, #1e3a5f)",
      }}
    >
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <h3 style={{ color: "var(--text, #e2e8f0)", margin: 0, fontSize: 16, fontWeight: 700 }}>
          Webhook Configuration
        </h3>
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
            color: "var(--muted, #94a3b8)",
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          <input
            type="checkbox"
            checked={config.isActive}
            onChange={handleToggleActive}
            aria-label="Enable webhook"
          />
          Active
        </label>
      </div>

      {/* Webhook URL */}
      <div style={{ marginBottom: 16 }}>
        <label
          htmlFor="webhook-url"
          style={{ display: "block", color: "var(--muted, #94a3b8)", fontSize: 12, marginBottom: 6 }}
        >
          Webhook URL
        </label>
        <input
          id="webhook-url"
          type="url"
          value={config.url}
          onChange={handleUrlChange}
          placeholder="https://hooks.zapier.com/hooks/catch/..."
          style={inputStyle}
          aria-label="Webhook URL"
        />
      </div>

      {/* Event Checkboxes */}
      <div style={{ marginBottom: 16 }}>
        <label
          style={{ display: "block", color: "var(--muted, #94a3b8)", fontSize: 12, marginBottom: 8 }}
        >
          Events to Send
        </label>
        {WEBHOOK_EVENTS.map((event) => (
          <label
            key={event.id}
            style={{
              display: "flex",
              alignItems: "flex-start",
              gap: 8,
              padding: "6px 0",
              cursor: "pointer",
              color: "var(--text, #e2e8f0)",
              fontSize: 13,
            }}
          >
            <input
              type="checkbox"
              checked={config.events.includes(event.id)}
              onChange={() => handleToggleEvent(event.id)}
              style={{ marginTop: 2 }}
              aria-label={`Enable ${event.label} event`}
            />
            <div>
              <div style={{ fontWeight: 600 }}>{event.label}</div>
              <div style={{ color: "var(--muted, #94a3b8)", fontSize: 12 }}>
                {event.description}
              </div>
            </div>
          </label>
        ))}
      </div>

      {/* D-114: JSON API endpoints reference */}
      <div
        style={{
          marginBottom: 16,
          padding: 12,
          background: "rgba(0, 212, 255, 0.05)",
          borderRadius: 8,
          border: "1px solid rgba(0, 212, 255, 0.1)",
        }}
      >
        <p style={{ color: "var(--cyan, #00d4ff)", fontSize: 12, fontWeight: 600, margin: "0 0 6px" }}>
          JSON API Endpoints
        </p>
        <div style={{ color: "var(--muted, #94a3b8)", fontSize: 11, fontFamily: "monospace" }}>
          <div>GET /api/reports/project/[id] - Single project report</div>
          <div>GET /api/reports/rollup - Portfolio rollup</div>
          <div>POST /api/reports/schedule - Create/update schedule</div>
          <div>GET /api/reports/shared/[token] - Shared report view</div>
        </div>
      </div>

      {/* Action buttons */}
      <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
        <button
          onClick={handleSave}
          style={{
            ...buttonStyle,
            background: "var(--accent, #f5a623)",
            color: "#000",
          }}
        >
          {saved ? "Saved" : "Save"}
        </button>

        <button
          onClick={handleTestWebhook}
          disabled={testStatus === "sending"}
          style={{
            ...buttonStyle,
            background: "transparent",
            border: "1px solid var(--border, #1e3a5f)",
            color: "var(--text, #e2e8f0)",
            opacity: testStatus === "sending" ? 0.6 : 1,
          }}
        >
          {testStatus === "sending"
            ? "Sending..."
            : testStatus === "success"
              ? "Test Sent"
              : "Test Webhook"}
        </button>

        {testStatus === "error" && testError && (
          <span style={{ color: "var(--red, #ef4444)", fontSize: 12 }}>
            {testError}
          </span>
        )}
      </div>
    </div>
  );
}
