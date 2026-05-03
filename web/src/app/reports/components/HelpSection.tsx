"use client";

import { useState } from "react";
import { restartTour } from "./FeatureDiscovery";

// ---------- FAQ Items ----------

type FAQItem = {
  question: string;
  answer: string;
};

const FAQ_ITEMS: FAQItem[] = [
  {
    question: "How is the health score calculated?",
    answer:
      "Health scores combine budget performance (40%), schedule adherence (35%), and open issues (25%) into a weighted composite. Green = 80-100, Gold = 50-79, Red = 0-49.",
  },
  {
    question: "How often are reports updated?",
    answer:
      "Reports pull live data from your Supabase backend each time you view them. Scheduled reports generate snapshots at the configured frequency.",
  },
  {
    question: "Can I customize which sections appear in a report?",
    answer:
      "Yes. Use the Template Manager to toggle sections on/off, reorder them, or create custom templates for different audiences (executives, field teams, clients).",
  },
  {
    question: "How do I share a report with someone outside my team?",
    answer:
      "Click the Share button on any report to generate a time-limited link. You can set an expiration date and revoke access at any time.",
  },
  {
    question: "What export formats are available?",
    answer:
      "Reports can be exported as PDF, CSV, Excel (.xlsx), or PowerPoint (.pptx). PDF includes charts and formatting; CSV/Excel exports raw data tables.",
  },
  {
    question: "How do scheduled reports work?",
    answer:
      "Set up a schedule (daily, weekly, biweekly, monthly) and choose recipients. Reports are generated as PDF and delivered via email at the configured time.",
  },
];

// ---------- Keyboard Shortcuts (D-108) ----------

type ShortcutGroup = {
  group: string;
  shortcuts: { keys: string; description: string }[];
};

const KEYBOARD_SHORTCUTS: ShortcutGroup[] = [
  {
    group: "Navigation",
    shortcuts: [
      { keys: "?", description: "Toggle help panel" },
      { keys: "Esc", description: "Close modal / cancel" },
      { keys: "1-5", description: "Switch report tabs" },
    ],
  },
  {
    group: "Reports",
    shortcuts: [
      { keys: "Ctrl+P", description: "Export as PDF" },
      { keys: "Ctrl+E", description: "Export as CSV" },
      { keys: "Ctrl+S", description: "Share report" },
    ],
  },
];

// ---------- Component ----------

type HelpSectionProps = {
  isOpen: boolean;
  onClose: () => void;
};

export function HelpSection({ isOpen, onClose }: HelpSectionProps) {
  const [expandedFAQ, setExpandedFAQ] = useState<number | null>(null);
  const [showShortcuts, setShowShortcuts] = useState(false);

  if (!isOpen) return null;

  return (
    <div
      style={{
        position: "fixed",
        top: 0,
        right: 0,
        width: 380,
        height: "100vh",
        background: "var(--surface)",
        borderLeft: "1px solid var(--border)",
        zIndex: 1000,
        overflowY: "auto",
        boxShadow: "-4px 0 16px rgba(0,0,0,0.3)",
      }}
      role="dialog"
      aria-label="Help panel"
    >
      {/* Header */}
      <div
        style={{
          padding: "16px 20px",
          borderBottom: "1px solid var(--border)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <div style={{ fontSize: 14, fontWeight: 800, color: "var(--text)" }}>
          Help &amp; Resources
        </div>
        <button
          onClick={onClose}
          aria-label="Close help panel"
          style={{
            background: "none",
            border: "none",
            color: "var(--muted)",
            fontSize: 18,
            cursor: "pointer",
            padding: "2px 6px",
          }}
        >
          ×
        </button>
      </div>

      {/* Quick actions */}
      <div style={{ padding: "12px 20px", borderBottom: "1px solid var(--border)" }}>
        <div
          style={{
            fontSize: 10,
            fontWeight: 700,
            color: "var(--muted)",
            textTransform: "uppercase",
            letterSpacing: 1,
            marginBottom: 8,
          }}
        >
          Quick Actions
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {/* D-66b: Restart tour */}
          <button
            onClick={() => {
              restartTour();
            }}
            style={{
              background: "var(--panel)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              padding: "8px 12px",
              fontSize: 12,
              color: "var(--text)",
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            Restart Feature Tour
          </button>

          {/* D-108: Keyboard shortcuts */}
          <button
            onClick={() => setShowShortcuts((prev) => !prev)}
            style={{
              background: "var(--panel)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              padding: "8px 12px",
              fontSize: 12,
              color: "var(--text)",
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            {showShortcuts ? "Hide" : "Show"} Keyboard Shortcuts
          </button>

          {/* D-66d: External documentation link */}
          <a
            href="https://docs.constructionos.app/reports"
            target="_blank"
            rel="noopener noreferrer"
            style={{
              background: "var(--panel)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              padding: "8px 12px",
              fontSize: 12,
              color: "var(--accent)",
              textDecoration: "none",
              display: "block",
            }}
          >
            Learn more — Documentation ↗
          </a>
        </div>
      </div>

      {/* Keyboard shortcuts panel */}
      {showShortcuts && (
        <div style={{ padding: "12px 20px", borderBottom: "1px solid var(--border)" }}>
          <div
            style={{
              fontSize: 10,
              fontWeight: 700,
              color: "var(--muted)",
              textTransform: "uppercase",
              letterSpacing: 1,
              marginBottom: 8,
            }}
          >
            Keyboard Shortcuts
          </div>
          {KEYBOARD_SHORTCUTS.map((group) => (
            <div key={group.group} style={{ marginBottom: 12 }}>
              <div
                style={{
                  fontSize: 11,
                  fontWeight: 700,
                  color: "var(--text)",
                  marginBottom: 4,
                }}
              >
                {group.group}
              </div>
              {group.shortcuts.map((sc) => (
                <div
                  key={sc.keys}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    padding: "3px 0",
                  }}
                >
                  <span style={{ fontSize: 11, color: "var(--muted)" }}>
                    {sc.description}
                  </span>
                  <kbd
                    style={{
                      background: "var(--panel)",
                      border: "1px solid var(--border)",
                      borderRadius: 4,
                      padding: "1px 6px",
                      fontSize: 10,
                      fontFamily: "monospace",
                      color: "var(--text)",
                    }}
                  >
                    {sc.keys}
                  </kbd>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}

      {/* FAQ items */}
      <div style={{ padding: "12px 20px" }}>
        <div
          style={{
            fontSize: 10,
            fontWeight: 700,
            color: "var(--muted)",
            textTransform: "uppercase",
            letterSpacing: 1,
            marginBottom: 8,
          }}
        >
          Frequently Asked Questions
        </div>
        {FAQ_ITEMS.map((item, i) => (
          <div
            key={i}
            style={{
              borderBottom: "1px solid var(--border)",
              paddingBottom: 8,
              marginBottom: 8,
            }}
          >
            <button
              onClick={() => setExpandedFAQ(expandedFAQ === i ? null : i)}
              aria-expanded={expandedFAQ === i}
              style={{
                background: "none",
                border: "none",
                width: "100%",
                textAlign: "left",
                padding: "6px 0",
                cursor: "pointer",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <span
                style={{
                  fontSize: 12,
                  fontWeight: 600,
                  color: "var(--text)",
                  flex: 1,
                }}
              >
                {item.question}
              </span>
              <span
                style={{
                  fontSize: 14,
                  color: "var(--muted)",
                  marginLeft: 8,
                  transition: "transform 0.15s",
                  transform:
                    expandedFAQ === i ? "rotate(180deg)" : "rotate(0deg)",
                }}
              >
                ▾
              </span>
            </button>
            {expandedFAQ === i && (
              <div
                style={{
                  fontSize: 11,
                  color: "var(--muted)",
                  lineHeight: 1.5,
                  padding: "4px 0 2px 0",
                }}
              >
                {item.answer}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

/**
 * Help icon button for the report header.
 */
export function HelpButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      aria-label="Open help panel"
      title="Help"
      style={{
        background: "var(--panel)",
        border: "1px solid var(--border)",
        borderRadius: 6,
        width: 32,
        height: 32,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        fontSize: 14,
        color: "var(--muted)",
        cursor: "pointer",
      }}
    >
      ?
    </button>
  );
}
