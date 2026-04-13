"use client";

import { useState, useEffect, useCallback } from "react";
import { tokens } from "@/lib/design-tokens";
import { SECTION_ORDER } from "@/lib/portal/types";
import type { PortalConfig, CompanyBranding, PortalSectionKey } from "@/lib/portal/types";

// D-17: Live preview (iframe for existing portals, inline for creation)
// D-27: Updates in real-time as config changes

type LivePreviewPanelProps = {
  portalConfigId?: string;
  previewConfig?: Partial<PortalConfig>;
  branding?: CompanyBranding;
};

const SECTION_LABELS: Record<PortalSectionKey, string> = {
  schedule: "Schedule & Milestones",
  budget: "Budget & Financials",
  photos: "Progress Photos",
  change_orders: "Change Orders",
  documents: "Documents",
};

export function LivePreviewPanel({
  portalConfigId,
  previewConfig,
  branding,
}: LivePreviewPanelProps) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [iframeLoading, setIframeLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch preview URL for existing portals
  const fetchPreviewUrl = useCallback(async () => {
    if (!portalConfigId) return;
    setIframeLoading(true);
    setError(null);

    try {
      const res = await fetch(
        `/api/portal/preview?portal_config_id=${portalConfigId}`
      );
      if (!res.ok) throw new Error("Failed to generate preview");
      const data = await res.json();
      setPreviewUrl(data.preview_url ?? null);
    } catch {
      setError("Preview unavailable");
    } finally {
      setIframeLoading(false);
    }
  }, [portalConfigId]);

  useEffect(() => {
    if (portalConfigId) {
      fetchPreviewUrl();
    }
  }, [portalConfigId, fetchPreviewUrl]);

  // Iframe preview for existing portal configs
  if (portalConfigId) {
    if (iframeLoading) {
      return (
        <div
          style={{
            height: 400,
            background: tokens.colors.gray[50],
            borderRadius: tokens.radius.md,
            display: "flex",
            flexDirection: "column",
            gap: tokens.spacing.sm,
            padding: tokens.spacing.md,
          }}
        >
          {/* Skeleton loader matching portal layout */}
          <div
            style={{
              height: 40,
              background: tokens.colors.gray[200],
              borderRadius: tokens.radius.sm,
              animation: `shimmer ${tokens.motion.shimmer} linear infinite`,
            }}
          />
          <div
            style={{
              height: 24,
              width: "60%",
              background: tokens.colors.gray[200],
              borderRadius: tokens.radius.sm,
              animation: `shimmer ${tokens.motion.shimmer} linear infinite`,
            }}
          />
          <div
            style={{
              flex: 1,
              background: tokens.colors.gray[100],
              borderRadius: tokens.radius.sm,
              animation: `shimmer ${tokens.motion.shimmer} linear infinite`,
            }}
          />
        </div>
      );
    }

    if (error) {
      return (
        <div
          style={{
            height: 400,
            background: tokens.colors.gray[50],
            borderRadius: tokens.radius.md,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: tokens.spacing.sm,
          }}
        >
          <div style={{ fontSize: 24, color: tokens.colors.gray[400] }}>
            {"\u26A0"}
          </div>
          <div
            style={{
              fontSize: tokens.typography.fontSize.sm,
              color: tokens.colors.gray[500],
            }}
          >
            Preview unavailable
          </div>
          <button
            type="button"
            onClick={fetchPreviewUrl}
            style={{
              padding: "6px 16px",
              fontSize: tokens.typography.fontSize.xs,
              fontWeight: tokens.typography.fontWeight.medium,
              border: `1px solid ${tokens.colors.gray[200]}`,
              borderRadius: tokens.radius.md,
              background: tokens.card.bg,
              color: tokens.colors.gray[700],
              cursor: "pointer",
            }}
          >
            Retry
          </button>
        </div>
      );
    }

    if (previewUrl) {
      return (
        <div style={{ display: "flex", flexDirection: "column", gap: tokens.spacing.sm }}>
          <div style={{ display: "flex", gap: tokens.spacing.sm }}>
            <button
              type="button"
              onClick={fetchPreviewUrl}
              style={{
                padding: "4px 12px",
                fontSize: tokens.typography.fontSize.xs,
                border: `1px solid ${tokens.colors.gray[200]}`,
                borderRadius: tokens.radius.sm,
                background: tokens.card.bg,
                color: tokens.colors.gray[700],
                cursor: "pointer",
              }}
            >
              Refresh
            </button>
            <a
              href={previewUrl}
              target="_blank"
              rel="noopener noreferrer"
              style={{
                padding: "4px 12px",
                fontSize: tokens.typography.fontSize.xs,
                border: `1px solid ${tokens.colors.gray[200]}`,
                borderRadius: tokens.radius.sm,
                background: tokens.card.bg,
                color: tokens.colors.primary[600],
                textDecoration: "none",
                display: "inline-flex",
                alignItems: "center",
                gap: 4,
              }}
            >
              Open in new tab {"\u2197"}
            </a>
          </div>
          <iframe
            src={previewUrl}
            title="Portal preview"
            style={{
              width: "100%",
              height: 500,
              border: `1px solid ${tokens.colors.gray[200]}`,
              borderRadius: tokens.radius.md,
              background: tokens.card.bg,
            }}
            onLoad={() => setIframeLoading(false)}
          />
        </div>
      );
    }
  }

  // Inline mini-preview for creation mode (no portalConfigId)
  const sections = previewConfig?.sections_config;
  const enabledSections = sections
    ? SECTION_ORDER.filter((key) => sections[key]?.enabled)
    : [];

  const companyName = branding?.company_name ?? "Your Company";
  const templateLabel = (previewConfig?.template ?? "executive_summary")
    .replace(/_/g, " ")
    .replace(/\b\w/g, (c) => c.toUpperCase());

  return (
    <div
      style={{
        border: `1px solid ${tokens.colors.gray[200]}`,
        borderRadius: tokens.radius.md,
        overflow: "hidden",
        background: tokens.colors.gray[50],
        fontSize: tokens.typography.fontSize.xs,
      }}
    >
      {/* Mini header */}
      <div
        style={{
          padding: `${tokens.spacing.sm}px ${tokens.spacing.md}px`,
          background: tokens.colors.primary[600],
          color: "#fff",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <span style={{ fontWeight: tokens.typography.fontWeight.semibold }}>
          {companyName}
        </span>
        <span style={{ opacity: 0.7, fontSize: 10 }}>{templateLabel}</span>
      </div>

      {/* Project name + health badge */}
      <div
        style={{
          padding: `${tokens.spacing.sm}px ${tokens.spacing.md}px`,
          borderBottom: `1px solid ${tokens.colors.gray[200]}`,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          background: tokens.card.bg,
        }}
      >
        <span
          style={{
            fontWeight: tokens.typography.fontWeight.medium,
            color: tokens.colors.gray[900],
          }}
        >
          Project Name
        </span>
        <span
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 4,
            fontSize: 10,
            color: tokens.colors.semantic.success,
            fontWeight: tokens.typography.fontWeight.semibold,
          }}
        >
          <span
            style={{
              width: 6,
              height: 6,
              borderRadius: "50%",
              background: tokens.colors.semantic.success,
            }}
          />
          On Track
        </span>
      </div>

      {/* Section blocks */}
      <div
        style={{
          padding: tokens.spacing.sm,
          display: "flex",
          flexDirection: "column",
          gap: 6,
        }}
      >
        {enabledSections.length === 0 ? (
          <div
            style={{
              padding: tokens.spacing.md,
              textAlign: "center",
              color: tokens.colors.gray[400],
            }}
          >
            No sections enabled
          </div>
        ) : (
          enabledSections.map((key) => (
            <div
              key={key}
              style={{
                padding: "8px 10px",
                background: tokens.card.bg,
                border: `1px solid ${tokens.colors.gray[200]}`,
                borderRadius: tokens.radius.sm,
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              <div
                style={{
                  width: 4,
                  height: 20,
                  borderRadius: 2,
                  background: tokens.colors.primary[400],
                  flexShrink: 0,
                }}
              />
              <span
                style={{
                  color: tokens.colors.gray[700],
                  fontWeight: tokens.typography.fontWeight.medium,
                }}
              >
                {SECTION_LABELS[key]}
              </span>
            </div>
          ))
        )}

        {/* Hidden sections shown muted */}
        {sections &&
          SECTION_ORDER.filter((key) => !sections[key]?.enabled).map((key) => (
            <div
              key={key}
              style={{
                padding: "8px 10px",
                background: tokens.colors.gray[50],
                border: `1px dashed ${tokens.colors.gray[200]}`,
                borderRadius: tokens.radius.sm,
                color: tokens.colors.gray[300],
                fontSize: 11,
              }}
            >
              {SECTION_LABELS[key]} (hidden)
            </div>
          ))}
      </div>

      {/* Mini footer */}
      <div
        style={{
          padding: `6px ${tokens.spacing.md}px`,
          borderTop: `1px solid ${tokens.colors.gray[200]}`,
          background: tokens.colors.gray[50],
          fontSize: 10,
          color: tokens.colors.gray[400],
          textAlign: "center",
        }}
      >
        Portal Preview
      </div>
    </div>
  );
}
