// Phase 29 LIVE-12 — client hook for drone assets split by 24h window.
//
// Reads cs_video_assets via the authenticated Supabase browser client (RLS
// filters by the user's org). T-29-RLS-CLIENT — no service-role key ever
// reaches the browser.
//
// Polls every 30 s (T-29-09-02 — conservative cadence; a single Realtime
// channel would be a follow-up). Cleans up on unmount.

"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

export type DroneAsset = {
  id: string;
  org_id: string;
  project_id: string;
  source_type: "drone";
  status: string;
  name: string | null;
  created_at: string;
  duration_s: number | null;
};

// Exported pure function so scrubber-window.test.ts can assert the 24h math
// without touching the hook's network path.
export function partitionByCutoff(
  clips: DroneAsset[],
  nowMs: number,
): { within24h: DroneAsset[]; olderThan24h: DroneAsset[] } {
  const cutoff = nowMs - 24 * 60 * 60 * 1000;
  const within: DroneAsset[] = [];
  const older: DroneAsset[] = [];
  for (const c of clips) {
    const t = new Date(c.created_at).getTime();
    if (Number.isFinite(t) && t >= cutoff) within.push(c);
    else older.push(c);
  }
  within.sort((a, b) => b.created_at.localeCompare(a.created_at));
  older.sort((a, b) => b.created_at.localeCompare(a.created_at));
  return { within24h: within, olderThan24h: older };
}

const POLL_INTERVAL_MS = 30_000; // 30s polling — conservative, doesn't hammer DB

export type UseDroneAssetsResult = {
  within24h: DroneAsset[];
  olderThan24h: DroneAsset[];
  loading: boolean;
  error: string | null;
};

export function useDroneAssets(projectId: string): UseDroneAssetsResult {
  const [clips, setClips] = useState<DroneAsset[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!projectId) {
      setClips([]);
      setLoading(false);
      return;
    }
    const supabase = createClient();
    if (!supabase) {
      // Supabase not configured (local dev without env) — surface state without
      // crashing; matches LiveFeedPage server-component fallback.
      setClips([]);
      setLoading(false);
      setError(null);
      return;
    }
    let active = true;

    async function fetchOnce() {
      if (!supabase) return;
      const { data, error: qErr } = await supabase
        .from("cs_video_assets")
        .select(
          "id, org_id, project_id, source_type, status, name, created_at, duration_s",
        )
        .eq("project_id", projectId)
        .eq("source_type", "drone")
        .eq("status", "ready")
        .order("created_at", { ascending: false })
        .limit(200);
      if (!active) return;
      if (qErr) {
        setError(qErr.message);
        setLoading(false);
        return;
      }
      setError(null);
      setClips((data ?? []) as DroneAsset[]);
      setLoading(false);
    }

    void fetchOnce();
    const id = window.setInterval(fetchOnce, POLL_INTERVAL_MS);
    return () => {
      active = false;
      window.clearInterval(id);
    };
  }, [projectId]);

  const now = Date.now();
  const { within24h, olderThan24h } = partitionByCutoff(clips, now);
  return { within24h, olderThan24h, loading, error };
}
