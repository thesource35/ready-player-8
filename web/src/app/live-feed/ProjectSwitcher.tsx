// Phase 29 LIVE-04 — web project switcher dropdown.
// Persists selection to localStorage ConstructOS.LiveFeed.LastSelectedProjectId.

"use client";

import { useEffect, useRef, useState } from "react";
import type { LiveFeedProject } from "./page";
import { LIVE_FEED_KEYS, writeString } from "./livefeed-storage";

export function ProjectSwitcher({
  projects,
  selectedProjectId,
  onSelect,
}: {
  projects: LiveFeedProject[];
  selectedProjectId: string;
  onSelect: (id: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [filter, setFilter] = useState("");
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onClick(e: MouseEvent) {
      if (!ref.current?.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  const current = projects.find((p) => p.id === selectedProjectId);
  // Case-insensitive prefix match on project name (LIVE-04 switcher filter spec).
  const filtered = filter
    ? projects.filter((p) => p.name.toLowerCase().startsWith(filter.toLowerCase()))
    : projects;

  function handleSelect(id: string) {
    onSelect(id);
    writeString(LIVE_FEED_KEYS.lastSelectedProjectId, id);
    setOpen(false);
    setFilter("");
  }

  return (
    <div ref={ref} style={{ position: "relative" }}>
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-label={`Project switcher, ${current?.name ?? "Switch project…"}`}
        style={{
          fontSize: 12,
          padding: "6px 12px",
          borderRadius: 10,
          background: "var(--surface)",
          color: "var(--text)",
          border: "1px solid " + (open ? "var(--accent)" : "var(--surface)"),
          cursor: "pointer",
        }}
      >
        {current?.name ?? "Switch project…"} ▾
      </button>
      {open && (
        <div
          role="listbox"
          style={{
            position: "absolute",
            top: "100%",
            left: 0,
            marginTop: 4,
            minWidth: 240,
            maxHeight: 320,
            overflowY: "auto",
            background: "var(--surface)",
            borderRadius: 10,
            border: "1px solid var(--accent)",
            zIndex: 50,
            padding: 8,
            display: "flex",
            flexDirection: "column",
            gap: 4,
          }}
        >
          <input
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            placeholder="Switch project…"
            aria-label="Filter projects"
            style={{
              fontSize: 12,
              padding: "6px 8px",
              borderRadius: 6,
              background: "var(--bg)",
              color: "var(--text)",
              border: "1px solid var(--surface)",
            }}
          />
          {filtered.map((p) => (
            <button
              key={p.id}
              type="button"
              role="option"
              aria-selected={p.id === selectedProjectId}
              onClick={() => handleSelect(p.id)}
              style={{
                textAlign: "left",
                fontSize: 12,
                padding: "6px 8px",
                background:
                  p.id === selectedProjectId ? "rgba(242,158,61,0.12)" : "transparent",
                color: "var(--text)",
                border: "none",
                cursor: "pointer",
                borderRadius: 6,
              }}
            >
              {p.name}
            </button>
          ))}
          {filtered.length === 0 && (
            <span style={{ fontSize: 12, color: "var(--muted)", padding: "6px 8px" }}>
              No matches.
            </span>
          )}
        </div>
      )}
    </div>
  );
}
