"use client";

import { useEffect, useState, useCallback } from "react";

// ---------- Types ----------

type ShortcutAction = {
  key: string;
  meta: boolean;
  shift?: boolean;
  label: string;
  description: string;
  group: "actions" | "navigation";
};

type KeyboardShortcutsProps = {
  onPrint?: () => void;
  onExport?: () => void;
  onShare?: () => void;
  onRefresh?: () => void;
  /** Enable vim-like navigation shortcuts (D-108 opt-in) */
  vimMode?: boolean;
  onNavigateUp?: () => void;
  onNavigateDown?: () => void;
  onGoToRollup?: () => void;
};

// ---------- Shortcut Definitions ----------

const SHORTCUTS: ShortcutAction[] = [
  { key: "p", meta: true, label: "Cmd+P", description: "Print report", group: "actions" },
  { key: "e", meta: true, label: "Cmd+E", description: "Export report", group: "actions" },
  { key: "s", meta: true, label: "Cmd+S", description: "Share report", group: "actions" },
  { key: "r", meta: true, label: "Cmd+R", description: "Refresh data", group: "actions" },
  { key: "?", meta: true, label: "Cmd+?", description: "Show shortcuts", group: "actions" },
];

const VIM_SHORTCUTS: ShortcutAction[] = [
  { key: "j", meta: false, label: "j", description: "Navigate down", group: "navigation" },
  { key: "k", meta: false, label: "k", description: "Navigate up", group: "navigation" },
  { key: "r", meta: false, label: "g r", description: "Go to rollup", group: "navigation" },
];

// ---------- Component ----------

export function KeyboardShortcuts({
  onPrint,
  onExport,
  onShare,
  onRefresh,
  vimMode = false,
  onNavigateUp,
  onNavigateDown,
  onGoToRollup,
}: KeyboardShortcutsProps) {
  const [showHelp, setShowHelp] = useState(false);
  const [gPressed, setGPressed] = useState(false);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      // Ignore when typing in inputs
      const tag = (e.target as HTMLElement)?.tagName;
      if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;

      const isMeta = e.metaKey || e.ctrlKey;

      // Cmd+P: Print
      if (isMeta && e.key === "p") {
        e.preventDefault();
        if (onPrint) {
          onPrint();
        } else {
          window.print();
        }
        return;
      }

      // Cmd+E: Export
      if (isMeta && e.key === "e") {
        e.preventDefault();
        onExport?.();
        return;
      }

      // Cmd+S: Share
      if (isMeta && e.key === "s") {
        e.preventDefault();
        onShare?.();
        return;
      }

      // Cmd+R: Refresh
      if (isMeta && e.key === "r") {
        e.preventDefault();
        onRefresh?.();
        return;
      }

      // Cmd+? (Cmd+Shift+/): Help panel
      if (isMeta && e.key === "?") {
        e.preventDefault();
        setShowHelp((prev) => !prev);
        return;
      }

      // Escape: close help
      if (e.key === "Escape") {
        setShowHelp(false);
        setGPressed(false);
        return;
      }

      // Vim-like shortcuts (D-108 opt-in)
      if (vimMode && !isMeta) {
        if (e.key === "j") {
          onNavigateDown?.();
          return;
        }
        if (e.key === "k") {
          onNavigateUp?.();
          return;
        }
        // g+r sequence
        if (e.key === "g") {
          setGPressed(true);
          setTimeout(() => setGPressed(false), 1000);
          return;
        }
        if (gPressed && e.key === "r") {
          setGPressed(false);
          onGoToRollup?.();
          return;
        }
      }
    },
    [onPrint, onExport, onShare, onRefresh, vimMode, onNavigateUp, onNavigateDown, onGoToRollup, gPressed]
  );

  // Register/unregister event listener
  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  const allShortcuts = vimMode ? [...SHORTCUTS, ...VIM_SHORTCUTS] : SHORTCUTS;
  const actionShortcuts = allShortcuts.filter((s) => s.group === "actions");
  const navShortcuts = allShortcuts.filter((s) => s.group === "navigation");

  if (!showHelp) return null;

  return (
    <div
      role="dialog"
      aria-label="Keyboard Shortcuts"
      aria-modal="true"
      style={{
        position: "fixed",
        inset: 0,
        zIndex: 9999,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        background: "rgba(0,0,0,0.5)",
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) setShowHelp(false);
      }}
    >
      <div
        style={{
          background: "var(--surface, #1A2332)",
          border: "1px solid var(--border, #2A3544)",
          borderRadius: 12,
          padding: 24,
          minWidth: 320,
          maxWidth: 420,
          boxShadow: "0 16px 48px rgba(0,0,0,0.4)",
        }}
      >
        {/* Header */}
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: 16,
          }}
        >
          <h2
            style={{
              fontSize: 14,
              fontWeight: 800,
              color: "var(--text, #E8ECF0)",
              margin: 0,
            }}
          >
            Keyboard Shortcuts
          </h2>
          <button
            onClick={() => setShowHelp(false)}
            aria-label="Close keyboard shortcuts"
            style={{
              background: "none",
              border: "none",
              color: "var(--muted, #6B7B8D)",
              fontSize: 16,
              cursor: "pointer",
              padding: 4,
            }}
          >
            Esc
          </button>
        </div>

        {/* Actions group */}
        <div style={{ marginBottom: 16 }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 800,
              color: "var(--accent, #F29E3D)",
              textTransform: "uppercase",
              letterSpacing: 1,
              marginBottom: 8,
            }}
          >
            Actions
          </div>
          {actionShortcuts.map((s) => (
            <div
              key={s.label}
              style={{
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                padding: "6px 0",
              }}
            >
              <span
                style={{
                  fontSize: 12,
                  color: "var(--text, #E8ECF0)",
                }}
              >
                {s.description}
              </span>
              <kbd
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  color: "var(--accent, #F29E3D)",
                  background: "rgba(242,158,61,0.1)",
                  padding: "2px 8px",
                  borderRadius: 4,
                  border: "1px solid rgba(242,158,61,0.2)",
                  fontFamily: "monospace",
                }}
              >
                {s.label}
              </kbd>
            </div>
          ))}
        </div>

        {/* Navigation group (vim mode) */}
        {navShortcuts.length > 0 && (
          <div>
            <div
              style={{
                fontSize: 10,
                fontWeight: 800,
                color: "var(--cyan, #4AC4CC)",
                textTransform: "uppercase",
                letterSpacing: 1,
                marginBottom: 8,
              }}
            >
              Navigation (Vim Mode)
            </div>
            {navShortcuts.map((s) => (
              <div
                key={s.label}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                  padding: "6px 0",
                }}
              >
                <span
                  style={{
                    fontSize: 12,
                    color: "var(--text, #E8ECF0)",
                  }}
                >
                  {s.description}
                </span>
                <kbd
                  style={{
                    fontSize: 10,
                    fontWeight: 800,
                    color: "var(--cyan, #4AC4CC)",
                    background: "rgba(74,196,204,0.1)",
                    padding: "2px 8px",
                    borderRadius: 4,
                    border: "1px solid rgba(74,196,204,0.2)",
                    fontFamily: "monospace",
                  }}
                >
                  {s.label}
                </kbd>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
