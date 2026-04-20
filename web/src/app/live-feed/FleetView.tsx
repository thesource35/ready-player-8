// Phase 29 LIVE-03 / D-07 — responsive Fleet tile grid.
// UI-SPEC §Responsive line 462-465 — auto-fill minmax(320px, 1fr) gives:
//   ≥ 1280 px: 3–4 columns · 1024–1279: 3 columns · 768–1023: 2 columns · < 768: 1 column.

"use client";

import type { LiveFeedProject } from "./page";
import { FleetTile } from "./FleetTile";

export function FleetView({ projects }: { projects: LiveFeedProject[] }) {
  if (projects.length === 0) {
    return (
      <div style={{ padding: 48, textAlign: "center" }}>
        <h1 style={{ fontSize: 20, fontWeight: 800, color: "var(--text)" }}>No Active Projects</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>
          Join or create a project to see it here.
        </p>
      </div>
    );
  }
  return (
    <div
      data-testid="fleet-grid"
      style={{
        display: "grid",
        gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))",
        gap: 24,
      }}
    >
      {projects.map((p) => (
        <FleetTile key={p.id} project={p} />
      ))}
    </div>
  );
}
