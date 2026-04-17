/**
 * @vitest-environment jsdom
 */
// Phase 22-07 — LiveStreamView + VideoClipPlayer structural tests.
// These don't assert playback (mux-player requires browser media APIs); they verify the component
// surface: loading/error/offline branches for Live, and the 4-status switch for the VOD player.
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, cleanup, act } from "@testing-library/react";
import React from "react";

// Mock mux-player-react — jsdom has no media pipeline and we only care about prop plumbing.
vi.mock("@mux/mux-player-react", () => ({
  default: (props: Record<string, unknown>) => (
    <div
      data-testid="mock-mux-player"
      data-stream-type={props["streamType"] as string}
      data-muted={props["muted"] ? "true" : "false"}
      data-playback-id={props["playbackId"] as string}
      data-src={props["src"] as string}
      data-accent={props["accentColor"] as string}
    />
  ),
}));

// Mock fetch for the usePlaybackToken hook used inside LiveStreamView.
function installFetchMock(response: unknown, ok = true) {
  const fn = vi.fn().mockImplementation(async () => ({
    ok,
    status: ok ? 200 : 500,
    json: async () => response,
  }));
  vi.stubGlobal("fetch", fn);
  return fn;
}

beforeEach(() => {
  vi.useFakeTimers();
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
});

async function flush() {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(0);
  });
}

import { LiveStreamView } from "../LiveStreamView";
import { VideoClipPlayer } from "../VideoClipPlayer";
import type { VideoSource, VideoAsset } from "@/lib/video/types";

const source: VideoSource = {
  id: "src_1",
  org_id: "org_1",
  project_id: "proj_1",
  kind: "fixed_camera",
  name: "Lobby Cam",
  location_label: null,
  mux_live_input_id: "li_1",
  mux_playback_id: "pb_1",
  audio_enabled: false,
  status: "active",
  last_active_at: null,
  created_at: "2026-04-16T00:00:00Z",
  created_by: "usr_1",
};

const readyAsset: VideoAsset = {
  id: "ast_1",
  source_id: "src_1",
  org_id: "org_1",
  project_id: "proj_1",
  source_type: "upload",
  kind: "vod",
  storage_path: "org_1/proj_1/ast_1/",
  mux_playback_id: null,
  mux_asset_id: null,
  status: "ready",
  started_at: "2026-04-16T00:00:00Z",
  ended_at: null,
  duration_s: 60,
  retention_expires_at: null,
  name: "Walkthrough",
  portal_visible: false,
  last_error: null,
  created_at: "2026-04-16T00:00:00Z",
  created_by: "usr_1",
};

describe("LiveStreamView", () => {
  it("shows 'Connecting to stream…' loading copy while the token mints", () => {
    installFetchMock({ token: "jwt_1", ttl: 300, playback_id: "pb_1" });
    render(<LiveStreamView source={source} />);
    expect(screen.getByText(/Connecting to stream/i)).toBeTruthy();
  });

  it("renders a ll-live muted MuxPlayer once the token mint succeeds", async () => {
    installFetchMock({ token: "jwt_1", ttl: 300, playback_id: "pb_1" });
    render(<LiveStreamView source={source} />);
    await flush();
    const player = screen.getByTestId("mock-mux-player");
    expect(player.getAttribute("data-stream-type")).toBe("ll-live");
    expect(player.getAttribute("data-muted")).toBe("true");
    expect(player.getAttribute("data-playback-id")).toBe("pb_1");
    expect(player.getAttribute("data-accent")).toBe("var(--accent)");
  });

  it("renders the UI-SPEC error copy with a Retry button when the mint fails", async () => {
    installFetchMock({ error: "boom", code: "video.playback_token_mint_failed", retryable: false }, false);
    render(<LiveStreamView source={source} />);
    await flush();
    expect(screen.getByText(/Couldn't start playback/i)).toBeTruthy();
    expect(screen.getByRole("button", { name: /Retry/i })).toBeTruthy();
  });

  it("shows an offline status instead of the player when source.status === 'offline'", () => {
    installFetchMock({ token: "jwt_1", ttl: 300, playback_id: "pb_1" });
    const { getByTestId } = render(<LiveStreamView source={{ ...source, status: "offline" }} />);
    // Offline state swaps the player for a status panel; no MuxPlayer mounted.
    expect(getByTestId("live-offline")).toBeTruthy();
    expect(screen.queryByTestId("mock-mux-player")).toBeNull();
  });
});

describe("VideoClipPlayer", () => {
  it("renders an on-demand muted MuxPlayer pointed at the VOD playback-url route for ready assets", () => {
    render(<VideoClipPlayer asset={readyAsset} />);
    const player = screen.getByTestId("mock-mux-player");
    expect(player.getAttribute("data-stream-type")).toBe("on-demand");
    expect(player.getAttribute("data-muted")).toBe("true");
    expect(player.getAttribute("data-src")).toBe("/api/video/vod/playback-url?asset_id=ast_1");
  });

  it("routes to /api/portal/video/playback-url and includes portal_token when portalToken prop is set", () => {
    render(<VideoClipPlayer asset={readyAsset} portalToken="ptok_abc" />);
    const player = screen.getByTestId("mock-mux-player");
    const src = player.getAttribute("data-src") || "";
    expect(src.startsWith("/api/portal/video/playback-url?")).toBe(true);
    expect(src).toContain("asset_id=ast_1");
    expect(src).toContain("portal_token=ptok_abc");
  });

  it("renders an Uploading placeholder when asset.status === 'uploading'", () => {
    render(<VideoClipPlayer asset={{ ...readyAsset, status: "uploading" }} />);
    expect(screen.getByText(/Uploading/i)).toBeTruthy();
    expect(screen.queryByTestId("mock-mux-player")).toBeNull();
  });

  it("renders a Transcoding placeholder when asset.status === 'transcoding'", () => {
    render(<VideoClipPlayer asset={{ ...readyAsset, status: "transcoding" }} />);
    expect(screen.getByText(/Transcoding/i)).toBeTruthy();
    expect(screen.queryByTestId("mock-mux-player")).toBeNull();
  });

  it("renders a failure state with the UI-SPEC retry copy when asset.status === 'failed'", () => {
    render(<VideoClipPlayer asset={{ ...readyAsset, status: "failed", last_error: "codec error" }} />);
    expect(screen.getByText(/Transcode failed/i)).toBeTruthy();
    expect(screen.queryByTestId("mock-mux-player")).toBeNull();
  });
});
