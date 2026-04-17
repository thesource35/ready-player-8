// Phase 14 — /projects/[id]/activity timeline (Server Component)
// Chronological flat list of cs_activity_events for one project.

import { fetchProjectActivity } from "@/lib/notifications";
import type { ActivityEvent } from "@/lib/supabase/types";

export const metadata = {
  title: "Project Activity — ConstructionOS",
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

const ENTITY_LABELS: Record<string, string> = {
  cs_projects: "Project",
  cs_contracts: "Contract",
  cs_rfis: "RFI",
  cs_change_orders: "Change order",
  cs_daily_logs: "Daily log",
  cs_attachments: "Document",
  cs_safety_incidents: "Safety incident",
  cs_submittals: "Submittal",
  cs_punch_list: "Punch item",
  cs_documents: "Document",
  cs_document_attachments: "Document",
};

const DETAIL_LABELS: Record<string, string> = {
  document_uploaded: "Document uploaded",
  document_attached: "Document attached",
  document_detached: "Document detached",
  version_added: "New version added",
};

export default async function ProjectActivityPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const events = await fetchProjectActivity(id, 200);

  return (
    <div style={{ maxWidth: 720, margin: "0 auto", padding: "32px 20px" }}>
      <div style={{ marginBottom: 24 }}>
        <a
          href={`/projects/${id}`}
          style={{ fontSize: 11, color: "#9EBDC2", textDecoration: "none" }}
        >
          ← Back to project
        </a>
        <h1
          style={{
            fontSize: 28,
            fontWeight: 900,
            letterSpacing: 2,
            color: "#F0F8F8",
            marginTop: 8,
          }}
        >
          ACTIVITY
        </h1>
        <p style={{ fontSize: 12, color: "#9EBDC2", marginTop: 4 }}>
          {events.length} event{events.length === 1 ? "" : "s"}
        </p>
      </div>

      {events.length === 0 ? (
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
          <p style={{ fontSize: 13 }}>No activity yet on this project.</p>
        </div>
      ) : (
        <ul
          style={{
            listStyle: "none",
            padding: 0,
            margin: 0,
            display: "flex",
            flexDirection: "column",
            gap: 0,
          }}
        >
          {events.map((e: ActivityEvent, idx) => {
            const label = ENTITY_LABELS[e.entity_type] ?? e.entity_type;
            const detail = (e.payload as Record<string, unknown>)?.detail as string | undefined;
            const filename = (e.payload as Record<string, unknown>)?.filename as string | undefined;
            const historical = (e.payload as Record<string, unknown>)?.historical === true;
            const isDocEvent = e.category === "document";

            let displayText = `${label} ${e.action}`;
            if (detail && DETAIL_LABELS[detail]) {
              displayText = DETAIL_LABELS[detail];
              if (filename) displayText += `: ${filename}`;
            }

            return (
              <li
                key={e.id}
                style={{
                  display: "flex",
                  gap: 14,
                  padding: "14px 4px",
                  borderBottom:
                    idx === events.length - 1
                      ? "none"
                      : "1px solid rgba(51,84,94,0.15)",
                }}
              >
                <div
                  style={{
                    width: 8,
                    height: 8,
                    borderRadius: 4,
                    background: "#F29E3D",
                    marginTop: 6,
                    flexShrink: 0,
                  }}
                />
                <div style={{ flex: 1 }}>
                  <div
                    style={{
                      display: "flex",
                      gap: 10,
                      alignItems: "baseline",
                      marginBottom: 2,
                    }}
                  >
                    {isDocEvent && (
                      <span
                        style={{
                          background: "rgba(242,158,61,0.15)",
                          color: "#F29E3D",
                          padding: "2px 6px",
                          borderRadius: 4,
                          fontSize: 10,
                          fontWeight: 800,
                          marginRight: 6,
                        }}
                      >
                        DOC
                      </span>
                    )}
                    <span style={{ fontSize: 13, fontWeight: 700, color: "#F0F8F8" }}>
                      {displayText}
                    </span>
                    <span
                      style={{
                        fontSize: 9,
                        fontWeight: 800,
                        letterSpacing: 1,
                        textTransform: "uppercase",
                        color: "#F29E3D",
                      }}
                    >
                      {e.category.replace(/_/g, " ")}
                    </span>
                  </div>
                  <div style={{ fontSize: 11, color: "#9EBDC2" }}>
                    {timeAgo(e.created_at)}
                    {historical && (
                      <span
                        style={{
                          fontSize: 9,
                          color: "rgba(158,189,194,0.4)",
                          fontStyle: "italic",
                          marginLeft: 6,
                        }}
                      >
                        (historical)
                      </span>
                    )}
                  </div>
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
