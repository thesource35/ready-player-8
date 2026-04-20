// Phase 29 D-07 — single Fleet tile: 16:9 poster area + 120 px suggestion row.
// Real poster + latest suggestion wired in a 29-10 consumption pass.

"use client";

import type { LiveFeedProject } from "./page";

export function FleetTile({ project }: { project: LiveFeedProject }) {
  return (
    <article
      data-testid="fleet-tile"
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        overflow: "hidden",
        boxShadow: "0 0 18px rgba(242,158,61,0.18)",
      }}
    >
      <div
        style={{
          aspectRatio: "16 / 9",
          background: "var(--bg)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <span
          style={{
            fontSize: 11,
            fontWeight: 800,
            letterSpacing: 2,
            color: "var(--text)",
          }}
        >
          {project.name}
        </span>
      </div>
      <div style={{ height: 120, padding: 12, color: "var(--muted)", fontSize: 12 }}>
        No suggestions yet
      </div>
    </article>
  );
}
