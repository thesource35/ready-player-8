/**
 * @vitest-environment jsdom
 */
// Phase 22-07 — usePlaybackToken hook tests.
// Covers: fetch on mount, portal routing (D-19), auto-refresh 30s before TTL (D-14), error handling,
// cleanup on unmount. Uses vi.useFakeTimers to assert scheduling of the refresh timeout.
import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { renderHook, act } from "@testing-library/react";

import { usePlaybackToken } from "../usePlaybackToken";

type FetchArgs = { url: string; body: unknown };

function mockFetch(response: unknown, ok = true, status = 200) {
  const calls: FetchArgs[] = [];
  const fn = vi.fn().mockImplementation(async (url: string, init?: RequestInit) => {
    calls.push({ url, body: init?.body ? JSON.parse(String(init.body)) : null });
    return {
      ok,
      status,
      json: async () => response,
    } as unknown as Response;
  });
  return { fn, calls };
}

// Flush the current fetch's microtask chain (fetch resolve → res.json() resolve → setState).
// With fake timers, advancing timers by 0 inside act() is the clean way to drain the queue.
async function flush() {
  await act(async () => {
    await vi.advanceTimersByTimeAsync(0);
  });
}

describe("usePlaybackToken", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });
  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it("POSTs to /api/video/mux/playback-token when no portalToken is passed", async () => {
    const { fn, calls } = mockFetch({ token: "jwt.abc", ttl: 300, playback_id: "pb_123" });
    vi.stubGlobal("fetch", fn);

    const { result } = renderHook(() => usePlaybackToken({ sourceId: "src-1" }));
    await flush();

    expect(result.current.token).toBe("jwt.abc");
    expect(result.current.playbackId).toBe("pb_123");
    expect(result.current.ttl).toBe(300);
    expect(result.current.loading).toBe(false);
    expect(calls.length).toBe(1);
    expect(calls[0].url).toBe("/api/video/mux/playback-token");
    expect(calls[0].body).toEqual({ source_id: "src-1" });
  });

  it("routes to /api/portal/video/playback-token and includes portal_token in body when portalToken is passed", async () => {
    const { fn, calls } = mockFetch({ token: "jwt.portal", ttl: 300, playback_id: "pb_portal" });
    vi.stubGlobal("fetch", fn);

    const { result } = renderHook(() => usePlaybackToken({ sourceId: "src-1", portalToken: "ptok_abc" }));
    await flush();

    expect(result.current.token).toBe("jwt.portal");
    expect(calls[0].url).toBe("/api/portal/video/playback-token");
    expect(calls[0].body).toEqual({ source_id: "src-1", portal_token: "ptok_abc" });
  });

  it("schedules auto-refresh 30s before ttl expiry (ttl=300 -> refresh at 270s)", async () => {
    const { fn } = mockFetch({ token: "jwt.first", ttl: 300, playback_id: "pb_1" });
    vi.stubGlobal("fetch", fn);

    renderHook(() => usePlaybackToken({ sourceId: "src-1" }));
    await flush();
    expect(fn).toHaveBeenCalledTimes(1);

    // Advance 269 seconds → still 1 call
    await act(async () => {
      await vi.advanceTimersByTimeAsync(269_000);
    });
    expect(fn).toHaveBeenCalledTimes(1);

    // Advance past the refresh boundary (ttl - 30 = 270s) → refresh fires
    await act(async () => {
      await vi.advanceTimersByTimeAsync(2_000);
    });
    expect(fn).toHaveBeenCalledTimes(2);
  });

  it("exposes error state when the server returns a non-OK response", async () => {
    const { fn } = mockFetch(
      { error: "Rate limited", code: "video.rate_limited", retryable: true },
      false,
      429,
    );
    vi.stubGlobal("fetch", fn);

    const { result } = renderHook(() => usePlaybackToken({ sourceId: "src-1" }));
    await flush();

    expect(result.current.loading).toBe(false);
    expect(result.current.token).toBeNull();
    expect(result.current.error).toBe("Rate limited");
  });

  it("cancels pending refresh on unmount (no stale setState after teardown)", async () => {
    const { fn } = mockFetch({ token: "jwt.first", ttl: 300, playback_id: "pb_1" });
    vi.stubGlobal("fetch", fn);

    const { result, unmount } = renderHook(() => usePlaybackToken({ sourceId: "src-1" }));
    await flush();
    expect(result.current.token).toBe("jwt.first");

    // Unmount before the refresh fires.
    unmount();

    // Advance well past the scheduled refresh — no new fetch should be issued.
    await act(async () => {
      await vi.advanceTimersByTimeAsync(600_000);
    });
    expect(fn).toHaveBeenCalledTimes(1);
  });
});
