"use client";

// Phase 30 — Inbox project-filter dropdown (D-06, D-09, D-10, D-11).
// Navigates /inbox?project_id= via next/navigation; persists choice to localStorage.
// On mount: rehydrates from localStorage (D-10) and silently recovers from a stale
// persisted/URL id (D-11) by wiping the key + replacing the URL with /inbox.

import { useEffect, useState, useCallback, useRef } from "react";
import type { CSSProperties } from "react";
import { useRouter } from "next/navigation";
import { LAST_FILTER_STORAGE_KEY, type ProjectMembershipUnread } from "@/lib/notifications";

type Props = {
  memberships: ProjectMembershipUnread[];
  currentProjectId: string | null;
};

// D-09 sort: unread descending, tiebreak by latest_created_at descending.
function sortMemberships(a: ProjectMembershipUnread, b: ProjectMembershipUnread): number {
  if (a.unread_count !== b.unread_count) return b.unread_count - a.unread_count;
  const ta = a.latest_created_at ?? "";
  const tb = b.latest_created_at ?? "";
  return tb.localeCompare(ta);
}

export default function InboxProjectPicker({ memberships, currentProjectId }: Props) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement | null>(null);

  // D-10 rehydrate + D-11 stale recovery on mount.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const persisted = window.localStorage.getItem(LAST_FILTER_STORAGE_KEY);
    const valid = new Set(memberships.map((m) => m.project_id));
    if (currentProjectId && !valid.has(currentProjectId)) {
      // URL has a stale id → wipe + redirect to /inbox (D-11).
      window.localStorage.removeItem(LAST_FILTER_STORAGE_KEY);
      router.replace("/inbox");
      return;
    }
    if (!currentProjectId && persisted && valid.has(persisted)) {
      router.replace(`/inbox?project_id=${encodeURIComponent(persisted)}`);
    } else if (persisted && !valid.has(persisted)) {
      window.localStorage.removeItem(LAST_FILTER_STORAGE_KEY);
    }
  }, [currentProjectId, memberships, router]);

  // Close dropdown when clicking outside.
  useEffect(() => {
    const onDown = (e: MouseEvent) => {
      if (!rootRef.current) return;
      if (!rootRef.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", onDown);
    return () => document.removeEventListener("mousedown", onDown);
  }, []);

  const onPick = useCallback(
    (projectId: string | null) => {
      if (typeof window !== "undefined") {
        if (projectId) window.localStorage.setItem(LAST_FILTER_STORAGE_KEY, projectId);
        else window.localStorage.removeItem(LAST_FILTER_STORAGE_KEY);
      }
      setOpen(false);
      router.push(projectId ? `/inbox?project_id=${encodeURIComponent(projectId)}` : "/inbox");
    },
    [router]
  );

  const sorted = [...memberships].sort(sortMemberships);
  const currentName = currentProjectId
    ? memberships.find((m) => m.project_id === currentProjectId)?.project_name ?? "Unknown project"
    : "All Projects";

  return (
    <div ref={rootRef} style={{ position: "relative", display: "inline-block" }}>
      <button
        type="button"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label="Filter notifications by project"
        onClick={() => setOpen((v) => !v)}
        style={{
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: 1,
          padding: "6px 12px",
          borderRadius: 8,
          background: "rgba(22,40,50,0.6)",
          color: "#F29E3D",
          border: "1px solid rgba(242,158,61,0.3)",
          cursor: "pointer",
          display: "inline-flex",
          alignItems: "center",
          gap: 6,
        }}
      >
        <span>{currentName.toUpperCase()}</span>
        <span style={{ fontSize: 9 }}>{open ? "▴" : "▾"}</span>
      </button>
      {open && (
        <ul
          role="listbox"
          style={{
            position: "absolute",
            top: "calc(100% + 4px)",
            right: 0,
            minWidth: 240,
            listStyle: "none",
            padding: 4,
            margin: 0,
            background: "#162832",
            border: "1px solid rgba(51,84,94,0.5)",
            borderRadius: 10,
            zIndex: 10,
            boxShadow: "0 8px 24px rgba(0,0,0,0.4)",
          }}
        >
          <li>
            <button
              type="button"
              onClick={() => onPick(null)}
              style={rowStyle(currentProjectId === null)}
            >
              <span>All Projects</span>
              {currentProjectId === null && <span aria-hidden>✓</span>}
            </button>
          </li>
          <li aria-hidden style={{ height: 1, background: "rgba(51,84,94,0.4)", margin: "4px 0" }} />
          {sorted.map((m) => (
            <li key={m.project_id}>
              <button
                type="button"
                onClick={() => onPick(m.project_id)}
                style={rowStyle(currentProjectId === m.project_id)}
              >
                <span
                  style={{
                    flex: 1,
                    textAlign: "left",
                    minWidth: 0,
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {m.project_name}
                </span>
                {m.unread_count > 0 && (
                  <span
                    style={{
                      fontSize: 9,
                      fontWeight: 900,
                      padding: "2px 6px",
                      borderRadius: 999,
                      background: "rgba(242,158,61,0.25)",
                      color: "#F29E3D",
                    }}
                  >
                    {m.unread_count}
                  </span>
                )}
                {currentProjectId === m.project_id && <span aria-hidden>✓</span>}
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function rowStyle(active: boolean): CSSProperties {
  return {
    width: "100%",
    padding: "8px 10px",
    fontSize: 12,
    fontWeight: 600,
    color: active ? "#F29E3D" : "#F0F8F8",
    background: active ? "rgba(242,158,61,0.08)" : "transparent",
    border: "none",
    borderRadius: 6,
    cursor: "pointer",
    display: "flex",
    alignItems: "center",
    gap: 8,
    textAlign: "left",
  };
}
