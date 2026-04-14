"use client";

import { useState } from "react";

// D-40: Collapsible sections via expand/collapse toggle, start expanded
// D-41: Summary by default, expandable with "See details" / "Show less"
// D-37: Item count in header
// D-39: Per-section "last updated" timestamp
// D-45: Optional section notes

type SectionWrapperProps = {
  id: string;
  title: string;
  itemCount?: number;
  lastUpdated?: string;
  sectionNote?: string;
  children: React.ReactNode;
};

export default function SectionWrapper({
  id,
  title,
  itemCount,
  lastUpdated,
  sectionNote,
  children,
}: SectionWrapperProps) {
  const [expanded, setExpanded] = useState(true);

  return (
    <section
      id={`section-${id}`}
      style={{
        marginBottom: 24,
        background: "var(--portal-card-bg, #FFFFFF)",
        borderRadius: "var(--portal-radius, 8px)",
        border: "1px solid #E2E5E9",
        overflow: "hidden",
      }}
    >
      {/* Section header with toggle */}
      <button
        onClick={() => setExpanded((prev) => !prev)}
        aria-expanded={expanded}
        aria-controls={`section-content-${id}`}
        style={{
          width: "100%",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "16px 20px",
          background: "transparent",
          border: "none",
          cursor: "pointer",
          textAlign: "left",
          minHeight: 44,
          color: "inherit",
          fontFamily: "inherit",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <h2
            style={{
              fontSize: 16,
              fontWeight: 600,
              margin: 0,
              color: "var(--portal-text, #1F2937)",
            }}
          >
            {title}
            {itemCount != null && (
              <span
                style={{
                  fontSize: 13,
                  fontWeight: 400,
                  color: "#9CA3AF",
                  marginLeft: 8,
                }}
              >
                ({itemCount})
              </span>
            )}
          </h2>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {lastUpdated && (
            <span style={{ fontSize: 11, color: "#9CA3AF" }}>
              Updated {lastUpdated}
            </span>
          )}
          <span
            style={{
              fontSize: 12,
              fontWeight: 500,
              color: "var(--portal-primary, #2563EB)",
            }}
          >
            {expanded ? "Show less" : "See details"}
          </span>
          <svg
            width="16"
            height="16"
            viewBox="0 0 16 16"
            fill="none"
            style={{
              transform: expanded ? "rotate(180deg)" : "rotate(0deg)",
              transition: "transform 250ms ease-in-out",
            }}
          >
            <path
              d="M4 6l4 4 4-4"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </div>
      </button>

      {/* Section content with expand/collapse animation */}
      <div
        id={`section-content-${id}`}
        role="region"
        aria-labelledby={`section-${id}`}
        style={{
          maxHeight: expanded ? 2000 : 0,
          opacity: expanded ? 1 : 0,
          overflow: "hidden",
          transition:
            "max-height 250ms ease-in-out, opacity 250ms ease-in-out",
        }}
      >
        <div style={{ padding: "0 20px 20px" }}>
          {/* D-45: Optional section note */}
          {sectionNote && (
            <p
              style={{
                fontSize: 13,
                color: "#6B7280",
                marginBottom: 16,
                padding: "8px 12px",
                background: "#F8F9FB",
                borderRadius: 6,
                borderLeft: "3px solid var(--portal-primary, #2563EB)",
              }}
            >
              {sectionNote}
            </p>
          )}
          {children}
        </div>
      </div>
    </section>
  );
}
