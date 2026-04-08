// Phase 14 — /inbox notification list (Server Component)
// Filter by project via ?project_id= query string. Mark-all-read POSTs to the
// API route which respects that filter (D-12).

import { fetchNotifications } from "@/lib/notifications";
import type { Notification } from "@/lib/supabase/types";

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
  const notifications = await fetchNotifications({ projectId, limit: 100 });
  const unreadCount = notifications.filter((n: Notification) => !n.read_at).length;

  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "32px 20px" }}>
      <div style={{ display: "flex", alignItems: "baseline", justifyContent: "space-between", marginBottom: 24 }}>
        <div>
          <h1 style={{ fontSize: 28, fontWeight: 900, letterSpacing: 2, color: "#F0F8F8", marginBottom: 4 }}>
            INBOX
          </h1>
          <p style={{ fontSize: 12, color: "#9EBDC2" }}>
            {projectId ? `Filtered to one project · ` : ""}
            {unreadCount} unread of {notifications.length}
          </p>
        </div>
        <form action={`/api/notifications/mark-all-read${projectId ? `?project_id=${projectId}` : ""}`} method="POST">
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
          <p style={{ fontSize: 13 }}>No notifications yet.</p>
          <p style={{ fontSize: 11, marginTop: 6 }}>
            Project activity, safety alerts, and bid deadlines will appear here.
          </p>
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
                    <form action={`/api/notifications/${n.id}`} method="POST">
                      {/* Next.js forms don't natively send PATCH; use _method override via API route extension */}
                      <input type="hidden" name="_method" value="PATCH" />
                      <button
                        type="submit"
                        formAction={`/api/notifications/${n.id}?_method=PATCH`}
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
