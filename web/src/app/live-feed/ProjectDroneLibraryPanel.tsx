// Phase 29 D-09 — collapsible library panel for drone clips >24h old.
//
// Input is already the olderThan24h bucket from useDroneAssets, which itself
// filters on cs_video_assets.source_type='drone' AND status='ready' with an
// implicit upper bound of Phase 22's 30d VOD retention (rows >30d are pruned
// by Phase 22's prune-expired-videos Edge Function — no UI filter needed).

"use client";

import { useState } from "react";
import type { DroneAsset } from "./useDroneAssets";

type Props = {
  clips: DroneAsset[];
  onSelect: (id: string) => void;
};

export function ProjectDroneLibraryPanel({ clips, onSelect }: Props) {
  const [open, setOpen] = useState(false);
  return (
    <section
      aria-label="Project drone library"
      style={{ background: "var(--surface)", borderRadius: 14 }}
    >
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        style={{
          width: "100%",
          textAlign: "left",
          padding: 12,
          fontSize: 11,
          fontWeight: 800,
          letterSpacing: 2,
          color: "var(--muted)",
          background: "transparent",
          border: "none",
          cursor: "pointer",
        }}
      >
        DRONE LIBRARY ({clips.length}) {open ? "▾" : "▸"}
      </button>
      {open &&
        (clips.length === 0 ? (
          <div style={{ padding: 16 }}>
            <strong
              style={{
                display: "block",
                fontSize: 14,
                fontWeight: 800,
                color: "var(--text)",
                marginBottom: 4,
              }}
            >
              No Older Clips
            </strong>
            <p style={{ fontSize: 12, color: "var(--muted)", margin: 0 }}>
              Clips older than 24 hours appear here for up to 30 days.
            </p>
          </div>
        ) : (
          <ul style={{ listStyle: "none", margin: 0, padding: 0 }}>
            {clips.map((c) => (
              <li key={c.id}>
                <button
                  type="button"
                  onClick={() => onSelect(c.id)}
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    width: "100%",
                    textAlign: "left",
                    padding: 12,
                    background: "transparent",
                    border: "none",
                    cursor: "pointer",
                    color: "var(--text)",
                    fontSize: 12,
                  }}
                >
                  <span>
                    {c.created_at.slice(0, 10)} · {c.name ?? "drone clip"}
                  </span>
                  <span style={{ color: "var(--accent)" }}>▶</span>
                </button>
              </li>
            ))}
          </ul>
        ))}
    </section>
  );
}
