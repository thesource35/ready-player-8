"use client";

// Phase 14 — Header bell with live unread badge.
// Subscribes to Realtime cs_notifications filtered by user_id; refetches the
// count on every change. Falls back to a static badge from /api/notifications
// when Realtime is unavailable. Badge caps at 99+.

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@supabase/supabase-js";

function formatBadge(n: number): string {
  if (n <= 0) return "";
  if (n > 99) return "99+";
  return String(n);
}

export default function HeaderBell() {
  const [unread, setUnread] = useState(0);
  const [userId, setUserId] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    try {
      const res = await fetch("/api/notifications?limit=1", { cache: "no-store" });
      if (!res.ok) return;
      const data = (await res.json()) as { unread?: number };
      setUnread(data.unread ?? 0);
    } catch {
      // network errors are non-fatal — badge just stays at last known value
    }
  }, []);

  // Initial load + identify the user for Realtime subscription
  useEffect(() => {
    let cancelled = false;

    const init = async () => {
      await refresh();
      const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
      const key =
        process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
      if (!url || !key) return;
      const client = createClient(url, key);
      const { data } = await client.auth.getUser();
      if (cancelled || !data.user) return;
      setUserId(data.user.id);
    };

    init();

    return () => {
      cancelled = true;
    };
  }, [refresh]);

  // Realtime subscription (re-runs when userId resolves)
  useEffect(() => {
    if (!userId) return;
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key =
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !key) return;

    const client = createClient(url, key);
    const channel = client
      .channel(`cs_notifications:${userId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "cs_notifications",
          filter: `user_id=eq.${userId}`,
        },
        () => refresh()
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
      client.removeChannel(channel);
    };
  }, [userId, refresh]);

  const badge = formatBadge(unread);

  return (
    <a
      href="/inbox"
      aria-label={unread > 0 ? `Inbox (${badge} unread)` : "Inbox"}
      className="relative inline-flex items-center justify-center w-9 h-9 rounded-lg hover:bg-[#162832]"
      style={{ color: "#9EBDC2" }}
    >
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" />
        <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" />
      </svg>
      {badge && (
        <span
          className="absolute -top-1 -right-1 min-w-[16px] h-[16px] px-1 rounded-full text-[9px] font-black flex items-center justify-center"
          style={{ background: "#F29E3D", color: "#0a1418" }}
        >
          {badge}
        </span>
      )}
    </a>
  );
}
