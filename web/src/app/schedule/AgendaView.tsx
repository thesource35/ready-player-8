"use client";

import { parseDateOnly } from "@/lib/calendar/dates";
import type { TimelineResponse } from "./page";

type AgendaItem = {
  date: string;
  kind: "task" | "milestone" | "event";
  label: string;
  projectId: string;
  detail?: string;
};

export default function AgendaView({ data }: { data: TimelineResponse }) {
  const { projects, tasks, milestones, events } = data;
  const projectName = new Map(projects.map((p) => [p.id, p.name]));

  const items: AgendaItem[] = [];
  for (const t of tasks) {
    items.push({
      date: t.start_date,
      kind: "task",
      label: t.name,
      projectId: t.project_id,
      detail: `${t.start_date} → ${t.end_date}${t.trade ? ` · ${t.trade}` : ""}`,
    });
  }
  for (const m of milestones) {
    items.push({
      date: m.date,
      kind: "milestone",
      label: m.label,
      projectId: m.project_id,
      detail: m.type,
    });
  }
  for (const e of events) {
    items.push({
      date: e.date,
      kind: "event",
      label: e.title,
      projectId: e.project_id,
      detail: e.event_type,
    });
  }

  // Group by date (lexical sort works on ISO strings).
  const byDate = new Map<string, AgendaItem[]>();
  for (const it of items) {
    if (!byDate.has(it.date)) byDate.set(it.date, []);
    byDate.get(it.date)!.push(it);
  }
  const sortedDates = Array.from(byDate.keys()).sort();

  if (sortedDates.length === 0) {
    return (
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 12,
          padding: 16,
          fontSize: 12,
          color: "var(--muted)",
        }}
      >
        Nothing scheduled in this window.
      </div>
    );
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      {sortedDates.map((date) => {
        // DST-safe parse for display label.
        const d = parseDateOnly(date);
        const label = d.toLocaleDateString(undefined, {
          weekday: "short",
          month: "short",
          day: "numeric",
          year: "numeric",
        });
        const dayItems = byDate.get(date)!;
        return (
          <div
            key={date}
            style={{
              background: "var(--surface)",
              borderRadius: 10,
              padding: 12,
              borderLeft: "3px solid var(--accent)",
            }}
          >
            <div
              style={{
                fontSize: 11,
                fontWeight: 900,
                letterSpacing: 1,
                color: "var(--accent)",
                marginBottom: 8,
              }}
            >
              {label.toUpperCase()}
            </div>
            {dayItems.map((it, i) => (
              <div
                key={`${it.kind}-${i}-${it.label}`}
                style={{
                  display: "flex",
                  gap: 8,
                  padding: "6px 0",
                  borderTop: i === 0 ? "none" : "1px solid rgba(255,255,255,0.04)",
                  fontSize: 11,
                }}
              >
                <span
                  style={{
                    display: "inline-block",
                    minWidth: 60,
                    fontSize: 8,
                    fontWeight: 800,
                    color:
                      it.kind === "task"
                        ? "var(--accent)"
                        : it.kind === "milestone"
                          ? "var(--gold)"
                          : "var(--cyan)",
                  }}
                >
                  {it.kind.toUpperCase()}
                </span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 700, color: "var(--text)" }}>{it.label}</div>
                  <div style={{ fontSize: 9, color: "var(--muted)" }}>
                    {projectName.get(it.projectId) ?? it.projectId}
                    {it.detail ? ` · ${it.detail}` : ""}
                  </div>
                </div>
              </div>
            ))}
          </div>
        );
      })}
    </div>
  );
}
