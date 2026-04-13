"use client";

import { useState } from "react";
import { tokens } from "@/lib/design-tokens";
import type { PortalConfig } from "@/lib/portal/types";

// D-26: Sortable table of all portal links
// D-94: Status dots (green=active, gray=expired, red=revoked)
// D-95: Alternating row colors

type PortalLinkRow = PortalConfig & {
  token: string;
  expires_at: string | null;
  view_count: number;
  is_revoked: boolean;
};

type SortKey = "created_at" | "view_count" | "project_id";

type PortalListTableProps = {
  links: PortalLinkRow[];
  onCopyUrl: (link: PortalLinkRow) => void;
  onPreview: (link: PortalLinkRow) => void;
  onEditConfig: (link: PortalLinkRow) => void;
  onRevoke: (link: PortalLinkRow) => void;
  onDelete: (link: PortalLinkRow) => void;
  onViewAnalytics: (link: PortalLinkRow) => void;
};

function getLinkStatus(link: PortalLinkRow): { label: string; color: string } {
  if (link.is_revoked) return { label: "Revoked", color: tokens.colors.semantic.error };
  if (link.expires_at && new Date(link.expires_at) < new Date()) {
    return { label: "Expired", color: tokens.colors.gray[400] };
  }
  return { label: "Active", color: tokens.colors.semantic.success };
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

export function PortalListTable({
  links,
  onCopyUrl,
  onPreview,
  onEditConfig,
  onRevoke,
  onDelete,
  onViewAnalytics,
}: PortalListTableProps) {
  const [sortBy, setSortBy] = useState<SortKey>("created_at");
  const [sortAsc, setSortAsc] = useState(false);
  const [confirmAction, setConfirmAction] = useState<{
    type: "revoke" | "delete";
    link: PortalLinkRow;
  } | null>(null);

  const sorted = [...links].sort((a, b) => {
    let cmp = 0;
    if (sortBy === "created_at") {
      cmp = new Date(a.created_at).getTime() - new Date(b.created_at).getTime();
    } else if (sortBy === "view_count") {
      cmp = a.view_count - b.view_count;
    } else if (sortBy === "project_id") {
      cmp = a.project_id.localeCompare(b.project_id);
    }
    return sortAsc ? cmp : -cmp;
  });

  function toggleSort(key: SortKey) {
    if (sortBy === key) {
      setSortAsc((prev) => !prev);
    } else {
      setSortBy(key);
      setSortAsc(false);
    }
  }

  function renderSortIndicator(key: SortKey) {
    if (sortBy !== key) return null;
    return <span style={{ marginLeft: 4 }}>{sortAsc ? "\u25B2" : "\u25BC"}</span>;
  }

  const thStyle: React.CSSProperties = {
    padding: "10px 12px",
    fontSize: tokens.typography.fontSize.xs,
    fontWeight: tokens.typography.fontWeight.semibold,
    color: tokens.colors.gray[500],
    textAlign: "left",
    borderBottom: `1px solid ${tokens.colors.gray[200]}`,
    cursor: "pointer",
    userSelect: "none",
    whiteSpace: "nowrap",
  };

  const tdStyle: React.CSSProperties = {
    padding: "10px 12px",
    fontSize: tokens.typography.fontSize.sm,
    color: tokens.colors.gray[700],
    borderBottom: `1px solid ${tokens.colors.gray[100]}`,
    whiteSpace: "nowrap",
  };

  const actionBtnStyle: React.CSSProperties = {
    padding: "4px 8px",
    fontSize: 11,
    fontWeight: tokens.typography.fontWeight.medium,
    border: `1px solid ${tokens.colors.gray[200]}`,
    borderRadius: tokens.radius.sm,
    background: tokens.card.bg,
    color: tokens.colors.gray[700],
    cursor: "pointer",
  };

  return (
    <>
      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              <th style={thStyle} onClick={() => toggleSort("project_id")}>
                Project{renderSortIndicator("project_id")}
              </th>
              <th style={{ ...thStyle, cursor: "default" }}>Slug URL</th>
              <th style={{ ...thStyle, cursor: "default" }}>Template</th>
              <th style={{ ...thStyle, cursor: "default" }}>Status</th>
              <th style={thStyle} onClick={() => toggleSort("view_count")}>
                Views{renderSortIndicator("view_count")}
              </th>
              <th style={thStyle} onClick={() => toggleSort("created_at")}>
                Created{renderSortIndicator("created_at")}
              </th>
              <th style={{ ...thStyle, cursor: "default", textAlign: "right" }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((link, idx) => {
              const status = getLinkStatus(link);
              const rowBg = idx % 2 === 0 ? tokens.card.bg : tokens.colors.gray[50];
              const templateLabel = link.template
                .replace(/_/g, " ")
                .replace(/\b\w/g, (c) => c.toUpperCase());

              return (
                <tr key={link.id} style={{ background: rowBg }}>
                  <td style={tdStyle}>
                    <span style={{ fontWeight: tokens.typography.fontWeight.medium }}>
                      {link.project_id.slice(0, 8)}...
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <code
                      style={{
                        fontSize: 11,
                        color: tokens.colors.primary[600],
                        background: tokens.colors.primary[50],
                        padding: "2px 6px",
                        borderRadius: tokens.radius.sm,
                      }}
                    >
                      /{link.company_slug}/{link.slug}
                    </code>
                  </td>
                  <td style={tdStyle}>{templateLabel}</td>
                  <td style={tdStyle}>
                    <span style={{ display: "inline-flex", alignItems: "center", gap: 6 }}>
                      <span
                        style={{
                          width: 8,
                          height: 8,
                          borderRadius: "50%",
                          background: status.color,
                          display: "inline-block",
                          flexShrink: 0,
                        }}
                      />
                      {status.label}
                    </span>
                  </td>
                  <td style={tdStyle}>{link.view_count}</td>
                  <td style={tdStyle}>{formatDate(link.created_at)}</td>
                  <td style={{ ...tdStyle, textAlign: "right" }}>
                    <div style={{ display: "flex", gap: 4, justifyContent: "flex-end", flexWrap: "wrap" }}>
                      <button
                        type="button"
                        style={actionBtnStyle}
                        onClick={() => onCopyUrl(link)}
                        title="Copy URL"
                      >
                        Copy
                      </button>
                      <button
                        type="button"
                        style={actionBtnStyle}
                        onClick={() => onPreview(link)}
                        title="Preview in new tab"
                      >
                        Preview
                      </button>
                      <button
                        type="button"
                        style={actionBtnStyle}
                        onClick={() => onViewAnalytics(link)}
                        title="View analytics"
                      >
                        Analytics
                      </button>
                      <button
                        type="button"
                        style={actionBtnStyle}
                        onClick={() => onEditConfig(link)}
                        title="Edit configuration"
                      >
                        Edit
                      </button>
                      {!link.is_revoked && (
                        <button
                          type="button"
                          style={{
                            ...actionBtnStyle,
                            color: tokens.colors.semantic.warning,
                            borderColor: tokens.colors.semantic.warning,
                          }}
                          onClick={() => setConfirmAction({ type: "revoke", link })}
                          title="Revoke link"
                        >
                          Revoke
                        </button>
                      )}
                      <button
                        type="button"
                        style={{
                          ...actionBtnStyle,
                          color: tokens.colors.semantic.error,
                          borderColor: tokens.colors.semantic.error,
                        }}
                        onClick={() => setConfirmAction({ type: "delete", link })}
                        title="Delete link"
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Confirmation dialog for destructive actions */}
      {confirmAction && (
        <div
          style={{
            position: "fixed",
            inset: 0,
            background: "rgba(0,0,0,0.5)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1000,
          }}
          onClick={() => setConfirmAction(null)}
        >
          <div
            style={{
              background: tokens.card.bg,
              borderRadius: tokens.radius.lg,
              padding: tokens.spacing.lg,
              maxWidth: 400,
              width: "90%",
              boxShadow: "0 8px 32px rgba(0,0,0,0.12)",
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <h3
              style={{
                margin: 0,
                fontSize: tokens.typography.fontSize.lg,
                fontWeight: tokens.typography.fontWeight.semibold,
                color: tokens.colors.semantic.error,
                marginBottom: tokens.spacing.sm,
              }}
            >
              {confirmAction.type === "revoke" ? "Revoke Link" : "Delete Link"}
            </h3>
            <p
              style={{
                fontSize: tokens.typography.fontSize.sm,
                color: tokens.colors.gray[600],
                lineHeight: tokens.typography.lineHeight.relaxed,
                margin: `0 0 ${tokens.spacing.md}px 0`,
              }}
            >
              {confirmAction.type === "revoke"
                ? "This will immediately disable access for anyone with this portal link. The link data will be preserved but viewers will see an expired page."
                : "This will permanently remove this portal link and all associated configuration. Analytics data will be preserved."}
            </p>
            <div style={{ display: "flex", gap: tokens.spacing.sm, justifyContent: "flex-end" }}>
              <button
                type="button"
                style={{
                  padding: "8px 16px",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.medium,
                  border: `1px solid ${tokens.colors.gray[200]}`,
                  borderRadius: tokens.radius.md,
                  background: tokens.card.bg,
                  color: tokens.colors.gray[700],
                  cursor: "pointer",
                }}
                onClick={() => setConfirmAction(null)}
              >
                Cancel
              </button>
              <button
                type="button"
                style={{
                  padding: "8px 16px",
                  fontSize: tokens.typography.fontSize.sm,
                  fontWeight: tokens.typography.fontWeight.bold,
                  border: "none",
                  borderRadius: tokens.radius.md,
                  background: tokens.colors.semantic.error,
                  color: "#fff",
                  cursor: "pointer",
                }}
                onClick={() => {
                  if (confirmAction.type === "revoke") {
                    onRevoke(confirmAction.link);
                  } else {
                    onDelete(confirmAction.link);
                  }
                  setConfirmAction(null);
                }}
              >
                {confirmAction.type === "revoke" ? "Revoke Link" : "Delete Link"}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
