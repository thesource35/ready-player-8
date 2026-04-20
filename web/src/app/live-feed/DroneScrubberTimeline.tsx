// Phase 29 LIVE-12 — web 24h scrubber timeline.
//
// Renders ONLY clips within the 24h window (partitioned upstream by useDroneAssets).
// Tapping a segment updates selection AND records a LastScrubTimestamp so the
// D-20 auto-advance 30s guard in LiveFeedClient can suppress auto-switching
// while the user is actively scrubbing.

"use client";

import type { CSSProperties } from "react";
import type { DroneAsset } from "./useDroneAssets";
import { perProjectScrubKey } from "./livefeed-storage";

type Props = {
  projectId: string;
  clips: DroneAsset[];
  selectedAssetId: string | null;
  onSelect: (id: string) => void;
  onUploadTap: () => void;
};

function shortTime(iso: string): string {
  try {
    const d = new Date(iso);
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  } catch {
    return iso.slice(-5);
  }
}

const rowStyle: CSSProperties = {
  display: "flex",
  gap: 4,
  padding: 8,
  height: 56,
  overflowX: "auto",
  background: "var(--surface)",
  borderRadius: 10,
};

const emptyStyle: CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 12,
  padding: 12,
  height: 56,
  background: "var(--surface)",
  borderRadius: 10,
};

export function DroneScrubberTimeline({
  projectId,
  clips,
  selectedAssetId,
  onSelect,
  onUploadTap,
}: Props) {
  if (clips.length === 0) {
    return (
      <div role="region" aria-label="Drone scrubber (empty)" style={emptyStyle}>
        <span style={{ fontSize: 12, color: "var(--muted)" }}>
          No drone clips in the last 24 h.
        </span>
        <button
          type="button"
          onClick={onUploadTap}
          style={{
            fontSize: 9,
            fontWeight: 800,
            letterSpacing: 2,
            padding: "6px 12px",
            borderRadius: 8,
            background: "var(--accent)",
            color: "black",
            border: "none",
            cursor: "pointer",
          }}
        >
          Upload Drone Clip
        </button>
      </div>
    );
  }

  function handleSelect(id: string) {
    onSelect(id);
    // Record user-scrub so D-20 guard in LiveFeedClient suppresses auto-advance
    // for the next 30 s while the user reviews the clip they chose.
    try {
      window.localStorage.setItem(
        perProjectScrubKey(projectId),
        new Date().toISOString(),
      );
    } catch {
      // localStorage may be unavailable (private mode, quota) — non-fatal.
    }
  }

  return (
    <div
      role="region"
      aria-label="Drone scrubber (last 24 hours)"
      style={rowStyle}
    >
      {clips.map((c) => {
        const active = c.id === selectedAssetId;
        return (
          <button
            key={c.id}
            type="button"
            onClick={() => handleSelect(c.id)}
            aria-label={`Drone clip, ${new Date(c.created_at).toLocaleTimeString()}, ${
              c.duration_s ?? "?"
            } seconds. Tap to play.`}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 2,
              padding: 4,
              background: "transparent",
              border: "none",
              cursor: "pointer",
            }}
          >
            <span
              style={{
                width: 36,
                height: 28,
                borderRadius: 2,
                background: active ? "var(--cyan)" : "rgba(158,189,194,0.4)",
              }}
            />
            <span
              style={{
                fontSize: 9,
                fontWeight: 800,
                letterSpacing: 1,
                color: active ? "var(--cyan)" : "var(--muted)",
              }}
            >
              {shortTime(c.created_at)}
            </span>
          </button>
        );
      })}
    </div>
  );
}
