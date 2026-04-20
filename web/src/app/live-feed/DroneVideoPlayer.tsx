// Phase 29 LIVE-02 — drone playback reuses Phase 22's web VideoClipPlayer VERBATIM.
//
// The VideoClipPlayer lives under web/src/app/projects/[id]/cameras/VideoClipPlayer.tsx
// and takes a full VideoAsset (not just an id). We hydrate a minimal VideoAsset from
// the DroneAsset so the Phase 22 player receives the exact shape it expects. This
// satisfies LIVE-02 parity: ZERO changes to the player.

"use client";

import type { VideoAsset } from "@/lib/video/types";
import { VideoClipPlayer } from "@/app/projects/[id]/cameras/VideoClipPlayer";
import type { DroneAsset } from "./useDroneAssets";

// Map a DroneAsset (thin hook projection) to the full VideoAsset shape the
// Phase 22 player expects. All fields not present on DroneAsset default to
// values consistent with a ready VOD asset — the player reads `status`,
// `last_error`, and `id`; everything else is pass-through for type safety.
function toVideoAsset(a: DroneAsset): VideoAsset {
  return {
    id: a.id,
    source_id: "", // not surfaced by the query; player doesn't read it for ready assets
    org_id: a.org_id,
    project_id: a.project_id,
    source_type: a.source_type, // 'drone' — player is agnostic (LIVE-02)
    kind: "vod",
    storage_path: null,
    mux_playback_id: null,
    mux_asset_id: null,
    status: a.status as VideoAsset["status"],
    started_at: a.created_at,
    ended_at: null,
    duration_s: a.duration_s,
    retention_expires_at: null,
    name: a.name,
    portal_visible: false,
    last_error: null,
    created_at: a.created_at,
    created_by: "",
  };
}

export function DroneVideoPlayer({ asset }: { asset: DroneAsset | null }) {
  if (!asset) {
    return (
      <div
        role="region"
        aria-label="Drone video player (empty)"
        style={{
          aspectRatio: "16 / 9",
          background: "var(--surface)",
          borderRadius: 14,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          color: "var(--muted)",
          fontSize: 12,
          gap: 8,
          padding: 24,
          textAlign: "center",
        }}
      >
        <strong style={{ fontSize: 20, fontWeight: 800, color: "var(--text)" }}>
          No Drone Clips Yet
        </strong>
        <span>Upload a drone clip to start analyzing site activity.</span>
      </div>
    );
  }
  return <VideoClipPlayer asset={toVideoAsset(asset)} />;
}
