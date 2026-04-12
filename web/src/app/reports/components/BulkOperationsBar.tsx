"use client";

import { useState, useCallback } from "react";

// ---------- Types ----------

type BulkAction = "delete" | "export" | "revoke" | "pause" | "resume";

type BulkOperationsBarProps = {
  /** IDs of selected items */
  selectedIds: string[];
  /** Callback to clear all selections */
  onClearSelection: () => void;
  /** Available actions for the current context */
  availableActions?: BulkAction[];
  /** Handlers for each action */
  onDelete?: (ids: string[]) => void | Promise<void>;
  onExport?: (ids: string[]) => void | Promise<void>;
  onRevoke?: (ids: string[]) => void | Promise<void>;
  onPause?: (ids: string[]) => void | Promise<void>;
  onResume?: (ids: string[]) => void | Promise<void>;
};

// ---------- Constants ----------

/** Maximum items per bulk operation (T-19-34: limit to 50 items) */
const MAX_BULK_ITEMS = 50;

const ACTION_CONFIG: Record<
  BulkAction,
  { label: string; color: string; destructive: boolean; icon: string }
> = {
  delete: { label: "Delete Selected", color: "var(--red, #D94D48)", destructive: true, icon: "x" },
  export: { label: "Export Selected", color: "var(--accent, #F29E3D)", destructive: false, icon: "^" },
  revoke: { label: "Revoke Selected Links", color: "var(--red, #D94D48)", destructive: true, icon: "!" },
  pause: { label: "Pause Schedules", color: "var(--gold, #FCC757)", destructive: false, icon: "||" },
  resume: { label: "Resume Schedules", color: "var(--green, #69D294)", destructive: false, icon: ">" },
};

// ---------- Component ----------

export function BulkOperationsBar({
  selectedIds,
  onClearSelection,
  availableActions = ["delete", "export"],
  onDelete,
  onExport,
  onRevoke,
  onPause,
  onResume,
}: BulkOperationsBarProps) {
  const [confirmAction, setConfirmAction] = useState<BulkAction | null>(null);
  const [processing, setProcessing] = useState(false);

  const count = selectedIds.length;

  const handleAction = useCallback(
    async (action: BulkAction) => {
      // T-19-34: limit bulk operations to 50 items
      const ids = selectedIds.slice(0, MAX_BULK_ITEMS);

      // Destructive actions require confirmation
      const config = ACTION_CONFIG[action];
      if (config.destructive && confirmAction !== action) {
        setConfirmAction(action);
        return;
      }

      setProcessing(true);
      setConfirmAction(null);

      try {
        switch (action) {
          case "delete":
            await onDelete?.(ids);
            break;
          case "export":
            await onExport?.(ids);
            break;
          case "revoke":
            await onRevoke?.(ids);
            break;
          case "pause":
            await onPause?.(ids);
            break;
          case "resume":
            await onResume?.(ids);
            break;
        }
      } finally {
        setProcessing(false);
      }
    },
    [selectedIds, confirmAction, onDelete, onExport, onRevoke, onPause, onResume]
  );

  // Don't render when nothing is selected
  if (count === 0) return null;

  return (
    <>
      {/* Confirmation dialog overlay */}
      {confirmAction && (
        <div
          role="dialog"
          aria-label="Confirm bulk action"
          aria-modal="true"
          style={{
            position: "fixed",
            inset: 0,
            zIndex: 10000,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "rgba(0,0,0,0.5)",
          }}
          onClick={(e) => {
            if (e.target === e.currentTarget) setConfirmAction(null);
          }}
        >
          <div
            style={{
              background: "var(--surface, #1A2332)",
              border: "1px solid var(--border, #2A3544)",
              borderRadius: 12,
              padding: 24,
              maxWidth: 400,
              boxShadow: "0 16px 48px rgba(0,0,0,0.4)",
            }}
          >
            <h3
              style={{
                fontSize: 14,
                fontWeight: 800,
                color: "var(--text, #E8ECF0)",
                margin: "0 0 12px 0",
              }}
            >
              Confirm {ACTION_CONFIG[confirmAction].label}
            </h3>
            <p
              style={{
                fontSize: 12,
                color: "var(--muted, #6B7B8D)",
                margin: "0 0 16px 0",
              }}
            >
              {confirmAction === "delete"
                ? `Are you sure you want to delete ${count} ${count === 1 ? "item" : "items"}? This cannot be undone.`
                : `Are you sure you want to revoke ${count} ${count === 1 ? "link" : "links"}?`}
              {count > MAX_BULK_ITEMS && (
                <span style={{ display: "block", marginTop: 8, color: "var(--gold, #FCC757)" }}>
                  Note: Only the first {MAX_BULK_ITEMS} items will be processed.
                </span>
              )}
            </p>
            <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
              <button
                onClick={() => setConfirmAction(null)}
                style={{
                  padding: "8px 16px",
                  fontSize: 11,
                  fontWeight: 600,
                  background: "var(--panel, #0F1C24)",
                  color: "var(--text, #E8ECF0)",
                  border: "1px solid var(--border, #2A3544)",
                  borderRadius: 6,
                  cursor: "pointer",
                }}
              >
                Cancel
              </button>
              <button
                onClick={() => handleAction(confirmAction)}
                style={{
                  padding: "8px 16px",
                  fontSize: 11,
                  fontWeight: 800,
                  background: ACTION_CONFIG[confirmAction].color,
                  color: "#FFFFFF",
                  border: "none",
                  borderRadius: 6,
                  cursor: "pointer",
                }}
              >
                {ACTION_CONFIG[confirmAction].label}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Fixed bottom bar (D-110) */}
      <div
        role="toolbar"
        aria-label="Bulk operations"
        style={{
          position: "fixed",
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 9998,
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "10px 20px",
          background: "var(--surface, #1A2332)",
          borderTop: "1px solid var(--border, #2A3544)",
          boxShadow: "0 -4px 16px rgba(0,0,0,0.3)",
        }}
      >
        {/* Left: selection count */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
          }}
        >
          <span
            style={{
              fontSize: 12,
              fontWeight: 800,
              color: "var(--accent, #F29E3D)",
            }}
          >
            {count} {count === 1 ? "item" : "items"} selected
          </span>
          <button
            onClick={onClearSelection}
            aria-label="Clear selection"
            style={{
              fontSize: 10,
              fontWeight: 600,
              color: "var(--muted, #6B7B8D)",
              background: "none",
              border: "none",
              cursor: "pointer",
              textDecoration: "underline",
            }}
          >
            Clear
          </button>
        </div>

        {/* Right: action buttons */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 8,
          }}
        >
          {availableActions.map((action) => {
            const config = ACTION_CONFIG[action];
            return (
              <button
                key={action}
                onClick={() => handleAction(action)}
                disabled={processing}
                aria-label={config.label}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 6,
                  padding: "6px 14px",
                  fontSize: 11,
                  fontWeight: 700,
                  color: config.destructive ? "#FFFFFF" : config.color,
                  background: config.destructive ? config.color : "transparent",
                  border: config.destructive ? "none" : `1px solid ${config.color}`,
                  borderRadius: 6,
                  cursor: processing ? "not-allowed" : "pointer",
                  opacity: processing ? 0.6 : 1,
                }}
              >
                <span style={{ fontSize: 12, fontWeight: 800 }}>{config.icon}</span>
                {config.label}
              </button>
            );
          })}
        </div>
      </div>
    </>
  );
}
