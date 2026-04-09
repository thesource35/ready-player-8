"use client";

/**
 * GanttChart — Phase 17 CAL-04.
 *
 * D-08: single-bar move (conflict warning badge, no cascade)
 * D-09: day-snap via Math.round(deltaPx / dayWidth)
 * D-10: atomic PATCH /api/calendar/tasks/[id] with new start+end
 * D-11: server writes updated_by / updated_at on every PATCH
 *
 * DST safety: ALL date math goes through parseDateOnly/addDays/daysBetween
 * from @/lib/calendar/dates — never `new Date("YYYY-MM-DD")`.
 */

import { useMemo, useRef, useState, useCallback } from "react";
import { addDays, daysBetween } from "@/lib/calendar/dates";

export type GanttTask = {
  id: string;
  project_id: string;
  name: string;
  start_date: string;
  end_date: string;
  trade?: string | null;
  percent_complete: number;
  is_critical: boolean;
};

export type GanttDep = {
  id: string;
  predecessor_task_id: string;
  successor_task_id: string;
  dep_type: "FS" | "SS" | "FF" | "SF";
  lag_days: number;
};

export type GanttMilestone = {
  project_id: string;
  type: "start" | "end" | "bid_due" | "inspection";
  date: string;
  label: string;
  source_id: string;
};

const DAY_WIDTH = 20;
const ROW_HEIGHT = 28;
const LABEL_WIDTH = 180;
const HEADER_HEIGHT = 24;

type DragState = {
  taskId: string;
  pointerId: number;
  startX: number;
  originalStart: string;
  originalEnd: string;
};

async function patchTaskDates(
  id: string,
  start_date: string,
  end_date: string
): Promise<boolean> {
  try {
    const res = await fetch(`/api/calendar/tasks/${encodeURIComponent(id)}`, {
      method: "PATCH",
      credentials: "include",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": "1",
      },
      body: JSON.stringify({ start_date, end_date }),
    });
    return res.ok;
  } catch (err) {
    console.error("[gantt] PATCH failed:", err);
    return false;
  }
}

function toast(message: string, type: "error" | "info" = "error") {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent("toast", { detail: { type, message } }));
}

export default function GanttChart({
  projectId: _projectId,
  projectName,
  tasks,
  dependencies,
  milestones,
  rangeStart,
  rangeEnd,
}: {
  projectId: string;
  projectName?: string;
  tasks: GanttTask[];
  dependencies: GanttDep[];
  milestones: GanttMilestone[];
  rangeStart: string;
  rangeEnd: string;
}) {
  const totalDays = Math.max(1, daysBetween(rangeStart, rangeEnd) + 1);
  const gridWidth = totalDays * DAY_WIDTH;

  // Optimistic overrides keyed by task id — { start_date, end_date }.
  const [overrides, setOverrides] = useState<
    Record<string, { start_date: string; end_date: string }>
  >({});
  const [drag, setDrag] = useState<DragState | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);

  const display = useCallback(
    (t: GanttTask): GanttTask => {
      const o = overrides[t.id];
      return o ? { ...t, start_date: o.start_date, end_date: o.end_date } : t;
    },
    [overrides]
  );

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>, task: GanttTask) => {
    (e.currentTarget as HTMLDivElement).setPointerCapture(e.pointerId);
    const d = display(task);
    setDrag({
      taskId: task.id,
      pointerId: e.pointerId,
      startX: e.clientX,
      originalStart: d.start_date,
      originalEnd: d.end_date,
    });
  };

  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!drag) return;
    const dayDelta = Math.round((e.clientX - drag.startX) / DAY_WIDTH);
    if (dayDelta === 0) {
      setOverrides((prev) => {
        if (!(drag.taskId in prev)) return prev;
        const next = { ...prev };
        delete next[drag.taskId];
        return next;
      });
      return;
    }
    setOverrides((prev) => ({
      ...prev,
      [drag.taskId]: {
        start_date: addDays(drag.originalStart, dayDelta),
        end_date: addDays(drag.originalEnd, dayDelta),
      },
    }));
  };

  const onPointerUp = async (e: React.PointerEvent<HTMLDivElement>) => {
    if (!drag) return;
    const currentDrag = drag;
    const dayDelta = Math.round((e.clientX - currentDrag.startX) / DAY_WIDTH);
    setDrag(null);
    if (dayDelta === 0) return;

    const newStart = addDays(currentDrag.originalStart, dayDelta);
    const newEnd = addDays(currentDrag.originalEnd, dayDelta);

    const ok = await patchTaskDates(currentDrag.taskId, newStart, newEnd);
    if (!ok) {
      // Roll back optimistic state.
      setOverrides((prev) => {
        const next = { ...prev };
        delete next[currentDrag.taskId];
        return next;
      });
      toast("Reschedule failed", "error");
    }
  };

  // Conflict detection: successor.start < predecessor.end → warn (does not block).
  const conflictingTaskIds = useMemo(() => {
    const byId = new Map<string, GanttTask>();
    for (const t of tasks) byId.set(t.id, display(t));
    const bad = new Set<string>();
    for (const d of dependencies) {
      const pred = byId.get(d.predecessor_task_id);
      const succ = byId.get(d.successor_task_id);
      if (!pred || !succ) continue;
      if (succ.start_date < pred.end_date) bad.add(succ.id);
    }
    return bad;
  }, [tasks, dependencies, display]);

  // Position helpers.
  const taskLeft = (t: GanttTask) => {
    try {
      return daysBetween(rangeStart, t.start_date) * DAY_WIDTH;
    } catch {
      return 0;
    }
  };
  const taskWidth = (t: GanttTask) => {
    try {
      return (daysBetween(t.start_date, t.end_date) + 1) * DAY_WIDTH;
    } catch {
      return DAY_WIDTH;
    }
  };

  // SVG arrow paths for dependencies.
  const arrows = useMemo(() => {
    const idx = new Map<string, number>();
    tasks.forEach((t, i) => idx.set(t.id, i));
    const paths: { id: string; d: string }[] = [];
    for (const dep of dependencies) {
      const pi = idx.get(dep.predecessor_task_id);
      const si = idx.get(dep.successor_task_id);
      if (pi == null || si == null) continue;
      const pred = display(tasks[pi]);
      const succ = display(tasks[si]);
      const px = taskLeft(pred) + taskWidth(pred);
      const py = pi * ROW_HEIGHT + ROW_HEIGHT / 2;
      const sx = taskLeft(succ);
      const sy = si * ROW_HEIGHT + ROW_HEIGHT / 2;
      const midX = Math.max(px + 6, sx - 6);
      paths.push({
        id: dep.id,
        d: `M ${px} ${py} L ${midX} ${py} L ${midX} ${sy} L ${sx} ${sy}`,
      });
    }
    return paths;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tasks, dependencies, overrides, rangeStart]);

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 12,
        padding: 16,
        overflowX: "auto",
      }}
    >
      {projectName && (
        <h2
          style={{
            fontSize: 12,
            fontWeight: 900,
            letterSpacing: 1,
            color: "var(--accent)",
            marginBottom: 12,
          }}
        >
          {projectName.toUpperCase()} · GANTT
        </h2>
      )}
      <div style={{ display: "flex" }}>
        {/* Label column */}
        <div style={{ width: LABEL_WIDTH, flexShrink: 0, paddingTop: HEADER_HEIGHT }}>
          {tasks.map((t) => {
            const d = display(t);
            const conflict = conflictingTaskIds.has(t.id);
            return (
              <div
                key={t.id}
                style={{
                  height: ROW_HEIGHT,
                  display: "flex",
                  alignItems: "center",
                  fontSize: 10,
                  fontWeight: 700,
                  color: "var(--text)",
                  borderBottom: "1px solid rgba(255,255,255,0.04)",
                  paddingRight: 8,
                }}
              >
                {conflict && (
                  <span
                    title="Dependency conflict"
                    style={{ color: "var(--gold)", marginRight: 4 }}
                  >
                    ⚠
                  </span>
                )}
                <span style={{ flex: 1, overflow: "hidden", textOverflow: "ellipsis" }}>
                  {d.name}
                </span>
              </div>
            );
          })}
        </div>

        {/* Grid area */}
        <div
          ref={containerRef}
          data-testid="gantt-grid"
          style={{
            position: "relative",
            width: gridWidth,
            minHeight: tasks.length * ROW_HEIGHT + HEADER_HEIGHT,
          }}
        >
          {/* Header day ticks every 7 days */}
          <div
            style={{
              position: "relative",
              height: HEADER_HEIGHT,
              borderBottom: "1px solid rgba(255,255,255,0.08)",
            }}
          >
            {Array.from({ length: Math.ceil(totalDays / 7) }, (_, i) => (
              <div
                key={i}
                style={{
                  position: "absolute",
                  left: i * 7 * DAY_WIDTH,
                  top: 4,
                  fontSize: 8,
                  color: "var(--muted)",
                  fontWeight: 800,
                }}
              >
                {addDays(rangeStart, i * 7)}
              </div>
            ))}
          </div>

          {/* Row grid lines */}
          {tasks.map((t, i) => (
            <div
              key={`row-${t.id}`}
              style={{
                position: "absolute",
                left: 0,
                top: HEADER_HEIGHT + i * ROW_HEIGHT,
                width: gridWidth,
                height: ROW_HEIGHT,
                borderBottom: "1px solid rgba(255,255,255,0.04)",
              }}
            />
          ))}

          {/* Task bars */}
          {tasks.map((t, i) => {
            const d = display(t);
            const left = taskLeft(d);
            const w = Math.max(DAY_WIDTH, taskWidth(d));
            return (
              <div
                key={t.id}
                data-testid={`task-bar-${t.id}`}
                data-task-id={t.id}
                data-start={d.start_date}
                data-end={d.end_date}
                onPointerDown={(e) => onPointerDown(e, t)}
                onPointerMove={onPointerMove}
                onPointerUp={onPointerUp}
                onPointerCancel={onPointerUp}
                style={{
                  position: "absolute",
                  left,
                  top: HEADER_HEIGHT + i * ROW_HEIGHT + 4,
                  width: w,
                  height: ROW_HEIGHT - 8,
                  borderRadius: 4,
                  background: t.is_critical ? "var(--red)" : "var(--accent)",
                  opacity: drag?.taskId === t.id ? 0.6 : 0.85,
                  cursor: "grab",
                  touchAction: "none",
                  display: "flex",
                  alignItems: "center",
                  paddingLeft: 6,
                  fontSize: 9,
                  fontWeight: 800,
                  color: "#000",
                  userSelect: "none",
                }}
              >
                {/* Progress fill */}
                <div
                  style={{
                    position: "absolute",
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: `${Math.max(0, Math.min(100, d.percent_complete))}%`,
                    background: "rgba(0,0,0,0.25)",
                    borderRadius: 4,
                  }}
                />
                <span style={{ position: "relative" }}>{d.percent_complete}%</span>
              </div>
            );
          })}

          {/* Milestone markers */}
          {milestones.map((m, i) => {
            let left = 0;
            try {
              left = daysBetween(rangeStart, m.date) * DAY_WIDTH;
            } catch {
              return null;
            }
            const color =
              m.type === "bid_due"
                ? "var(--gold)"
                : m.type === "inspection"
                  ? "var(--cyan)"
                  : "var(--green)";
            return (
              <div
                key={`${m.source_id}-${m.type}-${i}`}
                title={`${m.label} · ${m.date}`}
                style={{
                  position: "absolute",
                  left: left - 6,
                  top: HEADER_HEIGHT - 4,
                  width: 12,
                  height: 12,
                  background: color,
                  transform: "rotate(45deg)",
                }}
              />
            );
          })}

          {/* Dependency arrows SVG overlay */}
          <svg
            style={{
              position: "absolute",
              left: 0,
              top: HEADER_HEIGHT,
              width: gridWidth,
              height: tasks.length * ROW_HEIGHT,
              pointerEvents: "none",
            }}
          >
            {arrows.map((a) => (
              <path
                key={a.id}
                d={a.d}
                fill="none"
                stroke="var(--muted)"
                strokeWidth="1.5"
                markerEnd="url(#gantt-arrow)"
              />
            ))}
            <defs>
              <marker
                id="gantt-arrow"
                viewBox="0 0 10 10"
                refX="9"
                refY="5"
                markerWidth="5"
                markerHeight="5"
                orient="auto-start-reverse"
              >
                <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--muted)" />
              </marker>
            </defs>
          </svg>
        </div>
      </div>
    </div>
  );
}
