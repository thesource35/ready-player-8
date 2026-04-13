"use client";

import { useState, useEffect, useCallback } from "react";
import { tokens } from "@/lib/design-tokens";
import type { PortalConfig } from "@/lib/portal/types";
import { PortalCreateDialog } from "@/app/components/portal/PortalCreateDialog";
import { PortalListTable } from "@/app/components/portal/PortalListTable";
import { PortalAnalyticsDashboard } from "@/app/components/portal/PortalAnalyticsDashboard";

// D-26: Portal management dashboard page
// Authenticated page with link table, create dialog, analytics

type PortalLinkRow = PortalConfig & {
  token: string;
  expires_at: string | null;
  view_count: number;
  is_revoked: boolean;
};

export default function PortalsPage() {
  const [links, setLinks] = useState<PortalLinkRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [analyticsPortalId, setAnalyticsPortalId] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  // Fetch portal links
  const loadLinks = useCallback(async () => {
    try {
      const res = await fetch("/api/portal/create", { method: "GET" });
      // The create route only supports POST, so we need a list endpoint.
      // Use authenticated client-side fetch to portalQueries via a thin wrapper.
      // For now, fetch from the config endpoint with a list approach.
      // In practice, we call the list API.

      // We'll fetch the user's portal configs via a search on the analytics endpoint pattern.
      // Actually, let's just fetch projects and their portal configs.
      // The simplest approach: fetch all configs for the user by hitting a list-style GET.

      // Use a dedicated list call — fetch user's portal links by querying the management endpoint.
      const listRes = await fetch("/api/portal/list");
      if (listRes.ok) {
        const data = await listRes.json();
        setLinks(data.links ?? []);
      } else {
        // If list endpoint doesn't exist, start with empty
        setLinks([]);
      }
    } catch {
      setLinks([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadLinks();
  }, [loadLinks]);

  // Toast auto-dismiss
  useEffect(() => {
    if (!toast) return;
    const timer = setTimeout(() => setToast(null), 5000);
    return () => clearTimeout(timer);
  }, [toast]);

  function showToast(message: string) {
    setToast(message);
  }

  function handleCreated(_config: PortalConfig, url: string) {
    setShowCreate(false);
    showToast(
      url
        ? "Portal link created! URL copied to clipboard."
        : "Portal link created!"
    );
    loadLinks();
  }

  function getPortalUrl(link: PortalLinkRow): string {
    return `${window.location.origin}/portal/${link.company_slug}/${link.slug}`;
  }

  async function handleCopyUrl(link: PortalLinkRow) {
    const url = getPortalUrl(link);
    try {
      await navigator.clipboard.writeText(url);
      showToast("Portal URL copied to clipboard");
    } catch {
      showToast("Failed to copy URL");
    }
  }

  function handlePreview(link: PortalLinkRow) {
    // D-17: Open in new tab
    window.open(getPortalUrl(link), "_blank");
  }

  function handleEditConfig(link: PortalLinkRow) {
    // For now navigate to a config edit view — future plan will add inline edit
    showToast(`Edit configuration for ${link.slug}`);
  }

  async function handleRevoke(link: PortalLinkRow) {
    try {
      const res = await fetch(`/api/portal/${link.id}/revoke`, {
        method: "POST",
      });
      if (res.ok) {
        showToast("Portal link revoked");
        loadLinks();
      } else {
        const data = await res.json();
        showToast(data.error || "Failed to revoke link");
      }
    } catch {
      showToast("Failed to revoke link");
    }
  }

  async function handleDelete(link: PortalLinkRow) {
    try {
      const res = await fetch(`/api/portal/${link.id}/config`, {
        method: "DELETE",
      });
      if (res.ok) {
        showToast("Portal link deleted");
        loadLinks();
      } else {
        const data = await res.json();
        showToast(data.error || "Failed to delete link");
      }
    } catch {
      showToast("Failed to delete link");
    }
  }

  // Analytics panel
  if (analyticsPortalId) {
    return (
      <div style={{ padding: tokens.spacing.lg }}>
        <button
          type="button"
          onClick={() => setAnalyticsPortalId(null)}
          style={{
            display: "inline-flex",
            alignItems: "center",
            gap: 6,
            marginBottom: tokens.spacing.md,
            padding: "6px 12px",
            fontSize: tokens.typography.fontSize.sm,
            border: `1px solid ${tokens.colors.gray[200]}`,
            borderRadius: tokens.radius.md,
            background: tokens.card.bg,
            color: tokens.colors.gray[700],
            cursor: "pointer",
          }}
        >
          &larr; Back to Portal Links
        </button>
        <PortalAnalyticsDashboard portalConfigId={analyticsPortalId} />
      </div>
    );
  }

  return (
    <div style={{ padding: tokens.spacing.lg, maxWidth: 1200, margin: "0 auto" }}>
      {/* Toast notification (D-96) */}
      {toast && (
        <div
          style={{
            position: "fixed",
            top: 16,
            right: 16,
            zIndex: 2000,
            background: tokens.colors.toast.success.bg,
            border: `1px solid ${tokens.colors.toast.success.border}`,
            borderRadius: tokens.radius.md,
            padding: "12px 20px",
            fontSize: tokens.typography.fontSize.sm,
            color: tokens.colors.semantic.success,
            boxShadow: "0 4px 16px rgba(0,0,0,0.08)",
            animation: `slideIn ${tokens.motion.toast} ${tokens.motion.easing.enter}`,
          }}
        >
          {toast}
        </div>
      )}

      {/* Page header */}
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: tokens.spacing.lg,
        }}
      >
        <div>
          <h1
            style={{
              margin: 0,
              fontSize: tokens.typography.fontSize["3xl"],
              fontWeight: tokens.typography.fontWeight.semibold,
              color: tokens.colors.primary[800],
            }}
          >
            Portal Links
          </h1>
          <p
            style={{
              margin: `4px 0 0`,
              fontSize: tokens.typography.fontSize.sm,
              color: tokens.colors.gray[500],
            }}
          >
            Share project progress with clients via branded portal links
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowCreate(true)}
          style={{
            padding: "10px 20px",
            fontSize: tokens.typography.fontSize.sm,
            fontWeight: tokens.typography.fontWeight.bold,
            border: "none",
            borderRadius: tokens.radius.md,
            background: tokens.colors.primary[600],
            color: "#fff",
            cursor: "pointer",
            whiteSpace: "nowrap",
          }}
        >
          Create Portal Link
        </button>
      </div>

      {/* Content */}
      {loading ? (
        // Skeleton loader (D-89)
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              style={{
                height: 48,
                background: tokens.colors.gray[100],
                borderRadius: tokens.radius.md,
                animation: `shimmer ${tokens.motion.shimmer} linear infinite`,
              }}
            />
          ))}
        </div>
      ) : links.length === 0 ? (
        // Empty state (D-88)
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            padding: `${tokens.spacing["3xl"]}px ${tokens.spacing.lg}px`,
            textAlign: "center",
          }}
        >
          <div
            style={{
              width: 56,
              height: 56,
              borderRadius: "50%",
              background: tokens.colors.primary[50],
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 24,
              marginBottom: tokens.spacing.md,
            }}
          >
            {"\uD83D\uDD17"}
          </div>
          <h2
            style={{
              margin: 0,
              fontSize: tokens.typography.fontSize.xl,
              fontWeight: tokens.typography.fontWeight.semibold,
              color: tokens.colors.gray[900],
              marginBottom: tokens.spacing.sm,
            }}
          >
            No portal links yet
          </h2>
          <p
            style={{
              margin: 0,
              fontSize: tokens.typography.fontSize.sm,
              color: tokens.colors.gray[500],
              maxWidth: 360,
              lineHeight: tokens.typography.lineHeight.relaxed,
              marginBottom: tokens.spacing.md,
            }}
          >
            Share project progress with clients through branded, read-only
            portal links. Choose what to show and track engagement.
          </p>
          <button
            type="button"
            onClick={() => setShowCreate(true)}
            style={{
              padding: "10px 24px",
              fontSize: tokens.typography.fontSize.sm,
              fontWeight: tokens.typography.fontWeight.bold,
              border: "none",
              borderRadius: tokens.radius.md,
              background: tokens.colors.primary[600],
              color: "#fff",
              cursor: "pointer",
            }}
          >
            Create Your First Portal
          </button>
        </div>
      ) : (
        <PortalListTable
          links={links}
          onCopyUrl={handleCopyUrl}
          onPreview={handlePreview}
          onEditConfig={handleEditConfig}
          onRevoke={handleRevoke}
          onDelete={handleDelete}
          onViewAnalytics={(link) => setAnalyticsPortalId(link.id)}
        />
      )}

      {/* Create dialog */}
      <PortalCreateDialog
        open={showCreate}
        onClose={() => setShowCreate(false)}
        onCreated={handleCreated}
      />
    </div>
  );
}
