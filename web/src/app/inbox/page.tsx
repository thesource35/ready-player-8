// Phase 14 — /inbox notification list (Server Component)
// Filter by project via ?project_id= query string. Mark-all-read uses a Server
// Action which respects that filter (D-12).
// Phase 30 (D-01/D-02) — per-row READ and MARK ALL READ now invoke React 19
// Server Actions from ./actions; the legacy POST + HTTP-method-override kludge is gone.
// Phase 30-03 (D-06/D-10/D-12) — header now hosts the InboxProjectPicker dropdown
// and the sub-count + empty-state copy branch on the active project filter.

import { fetchNotifications, fetchProjectMembershipsWithUnread } from "@/lib/notifications/server";
import type { Notification } from "@/lib/supabase/types";
import { markReadAction, markAllReadAction } from "./actions";
import InboxProjectPicker from "./InboxProjectPicker";

export const metadata = {
  title: "Inbox — ConstructionOS",
  description: "All your project notifications in one place.",
};

function timeAgo(iso: string): string {
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return "";
  const seconds = Math.max(0, Math.floor((Date.now() - then) / 1000));
  if (seconds < 60) return `${seconds}s ago`;
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

const CATEGORY_COLOR: Record<string, string> = {
  bid_deadline: "#F29E3D",
  safety_alert: "#FF5060",
  assigned_task: "#5BC0FF",
  generic: "#9EBDC2",
};

export default async function InboxPage({
  searchParams,
}: {
  searchParams: Promise<{ project_id?: string }>;
}) {
  const params = await searchParams;
  const projectId = params.project_id ?? null;
  const [notifications, memberships] = await Promise.all([
    fetchNotifications({ projectId, limit: 100 }),
    fetchProjectMembershipsWithUnread(),
  ]);
  const unreadCount = notifications.filter((n: Notification) => !n.read_at).length;
  const currentProjectName = projectId
    ? memberships.find((m) => m.project_id === projectId)?.project_name ?? null
    : null;

  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "32px 20px" }}>
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 24, gap: 12 }}>
        <div style={{ minWidth: 0 }}>
          <h1 style={{ fontSize: 28, fontWeight: 900, letterSpacing: 2, color: "#F0F8F8", marginBottom: 4 }}>
            INBOX
          </h1>
          <p style={{ fontSize: 12, color: "#9EBDC2" }}>
            {projectId && currentProjectName ? `Filtered to ${currentProjectName} · ` : ""}
            {unreadCount} unread of {notifications.length}
          </p>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <InboxProjectPicker
            memberships={memberships}
            currentProjectId={projectId}
            unreadCountAtSelect={unreadCount}
          />
          <form action={markAllReadAction}>
            {projectId && <input type="hidden" name="project_id" value={projectId} />}
            <button
              type="submit"
              disabled={unreadCount === 0}
              style={{
                fontSize: 11,
                fontWeight: 700,
                letterSpacing: 1,
                padding: "8px 14px",
                borderRadius: 8,
                background: unreadCount ? "#162832" : "transparent",
                color: unreadCount ? "#F29E3D" : "rgba(158,189,194,0.4)",
                border: "1px solid rgba(242,158,61,0.3)",
                cursor: unreadCount ? "pointer" : "default",
              }}
            >
              MARK ALL READ
            </button>
          </form>
        </div>
      </div>

      {notifications.length === 0 ? (
        <div
          style={{
            padding: 40,
            textAlign: "center",
            color: "rgba(158,189,194,0.6)",
            background: "rgba(22,40,50,0.4)",
            borderRadius: 14,
            border: "1px dashed rgba(51,84,94,0.3)",
          }}
        >
          <p style={{ fontSize: 13 }}>
            {projectId && currentProjectName
              ? `No notifications for ${currentProjectName}`
              : "No notifications yet."}
          </p>
          {projectId ? (
            <p style={{ fontSize: 11, marginTop: 6 }}>
              <a href="/inbox" style={{ color: "#F29E3D", textDecoration: "underline" }}>
                Show all projects
              </a>
            </p>
          ) : (
            <p style={{ fontSize: 11, marginTop: 6 }}>
              Project activity, safety alerts, and bid deadlines will appear here.
            </p>
          )}
        </div>
      ) : (
        <ul style={{ listStyle: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: 8 }}>
          {notifications.map((n: Notification) => {
            const isUnread = !n.read_at && !n.dismissed_at;
            const accent = CATEGORY_COLOR[n.category] ?? "#9EBDC2";
            return (
              <li
                key={n.id}
                style={{
                  display: "flex",
                  gap: 12,
                  padding: 14,
                  background: isUnread ? "rgba(22,40,50,0.8)" : "rgba(22,40,50,0.3)",
                  borderRadius: 12,
                  borderLeft: `3px solid ${isUnread ? accent : "rgba(51,84,94,0.4)"}`,
                  opacity: n.dismissed_at ? 0.5 : 1,
                }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 4 }}>
                    <span
                      style={{
                        fontSize: 9,
                        fontWeight: 800,
                        letterSpacing: 1,
                        textTransform: "uppercase",
                        color: accent,
                      }}
                    >
                      {n.category.replace(/_/g, " ")}
                    </span>
                    <span style={{ fontSize: 10, color: "rgba(158,189,194,0.5)" }}>{timeAgo(n.created_at)}</span>
                  </div>
                  <h3 style={{ fontSize: 13, fontWeight: 700, color: "#F0F8F8", marginBottom: 2 }}>{n.title}</h3>
                  {n.body && <p style={{ fontSize: 12, color: "#9EBDC2" }}>{n.body}</p>}
                </div>
                <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
                  {isUnread && (
                    <form action={markReadAction}>
                      <input type="hidden" name="id" value={n.id} />
                      <button
                        type="submit"
                        style={{
                          fontSize: 9,
                          padding: "4px 8px",
                          background: "transparent",
                          color: "#9EBDC2",
                          border: "1px solid rgba(158,189,194,0.3)",
                          borderRadius: 6,
                          cursor: "pointer",
                        }}
                      >
                        READ
                      </button>
                    </form>
                  )}
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
