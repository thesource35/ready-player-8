"use client";

import Link from "next/link";
import { daysBetween } from "@/lib/calendar/dates";
import type { TimelineResponse } from "./page";

const DAY_WIDTH = 6; // px per day in rollup
const LANE_HEIGHT = 56;
const LABEL_WIDTH = 160;

export default function RollupTimeline({ data }: { data: TimelineResponse }) {
  const { window: win, projects, tasks, milestones, crewAssignments } = data;
  const totalDays = Math.max(1, daysBetween(win.from, win.to) + 1);
  const trackWidth = totalDays * DAY_WIDTH;

  // Aggregate crew_count per project per week bucket.
  const weekBuckets = Math.max(1, Math.ceil(totalDays / 7));
  const crewByProject = new Map<string, number[]>();
  for (const p of projects) crewByProject.set(p.id, new Array(weekBuckets).fill(0));
  for (const c of crewAssignments) {
    const lane = crewByProject.get(c.project_id);
    if (!lane) continue;
    let offset: number;
    try {
      offset = daysBetween(win.from, c.date);
    } catch {
      continue;
    }
    if (offset < 0 || offset >= totalDays) continue;
    const bucket = Math.floor(offset / 7);
    lane[bucket] += c.crew_count ?? 1;
  }

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 12,
        padding: 16,
        overflowX: "auto",
      }}
    >
      <div style={{ display: "flex", marginBottom: 8 }}>
        <div
          style={{
            width: LABEL_WIDTH,
            flexShrink: 0,
            fontSize: 9,
            fontWeight: 800,
            color: "var(--muted)",
          }}
        >
          PROJECT
        </div>
        <div style={{ position: "relative", width: trackWidth }}>
          <div
            style={{
              fontSize: 8,
              fontWeight: 800,
              color: "var(--muted)",
              display: "flex",
              justifyContent: "space-between",
            }}
          >
            <span>{win.from}</span>
            <span>{win.to}</span>
          </div>
        </div>
      </div>

      {projects.length === 0 && (
        <div style={{ fontSize: 12, color: "var(--muted)", padding: 12 }}>
          No projects in this window.
        </div>
      )}

      {projects.map((project) => {
        const projectTasks = tasks.filter((t) => t.project_id === project.id);
        const projectMilestones = milestones.filter((m) => m.project_id === project.id);
        const crewBins = crewByProject.get(project.id) ?? [];
        return (
          <div
            key={project.id}
            style={{
              display: "flex",
              alignItems: "center",
              marginBottom: 6,
              borderBottom: "1px solid rgba(255,255,255,0.04)",
              paddingBottom: 6,
            }}
          >
            <div style={{ width: LABEL_WIDTH, flexShrink: 0, paddingRight: 8 }}>
              <Link
                href={`/schedule?project=${encodeURIComponent(project.id)}&view=gantt`}
                style={{
                  fontSize: 11,
                  fontWeight: 800,
                  color: "var(--text)",
                  textDecoration: "none",
                }}
              >
                {project.name}
              </Link>
              <div style={{ fontSize: 8, color: "var(--muted)" }}>
                {projectTasks.length} tasks · {projectMilestones.length} milestones
              </div>
            </div>
            <div
              style={{
                position: "relative",
                width: trackWidth,
                height: LANE_HEIGHT,
                background: "var(--panel)",
                borderRadius: 4,
              }}
            >
              {/* Task bars */}
              {projectTasks.map((task) => {
                let left: number;
                let width: number;
                try {
                  left = daysBetween(win.from, task.start_date) * DAY_WIDTH;
                  width = (daysBetween(task.start_date, task.end_date) + 1) * DAY_WIDTH;
                } catch {
                  return null;
                }
                if (left + width < 0 || left > trackWidth) return null;
                return (
                  <div
                    key={task.id}
                    title={`${task.name} (${task.start_date} → ${task.end_date})`}
                    style={{
                      position: "absolute",
                      left,
                      width: Math.max(2, width),
                      top: 8,
                      height: 12,
                      borderRadius: 2,
                      background: task.is_critical ? "var(--red)" : "var(--accent)",
                      opacity: 0.7,
                    }}
                  />
                );
              })}
              {/* Milestone diamonds */}
              {projectMilestones.map((m) => {
                let left: number;
                try {
                  left = daysBetween(win.from, m.date) * DAY_WIDTH;
                } catch {
                  return null;
                }
                if (left < 0 || left > trackWidth) return null;
                const color =
                  m.type === "bid_due"
                    ? "var(--gold)"
                    : m.type === "inspection"
                      ? "var(--cyan)"
                      : "var(--green)";
                return (
                  <div
                    key={`${m.source_id}-${m.type}`}
                    title={`${m.label} · ${m.date}`}
                    style={{
                      position: "absolute",
                      left: left - 5,
                      top: 24,
                      width: 10,
                      height: 10,
                      background: color,
                      transform: "rotate(45deg)",
                    }}
                  />
                );
              })}
              {/* Crew badges per week */}
              {crewBins.map((count, i) => {
                if (count === 0) return null;
                return (
                  <div
                    key={i}
                    style={{
                      position: "absolute",
                      left: i * 7 * DAY_WIDTH,
                      top: 40,
                      fontSize: 7,
                      fontWeight: 800,
                      color: "var(--muted)",
                      padding: "1px 3px",
                      background: "rgba(0,0,0,0.3)",
                      borderRadius: 2,
                    }}
                  >
                    {count}c
                  </div>
                );
              })}
            </div>
          </div>
        );
      })}

      <div
        style={{
          marginTop: 12,
          display: "flex",
          gap: 12,
          fontSize: 8,
          color: "var(--muted)",
          fontWeight: 800,
        }}
      >
        <span>
          <span
            style={{
              display: "inline-block",
              width: 10,
              height: 6,
              background: "var(--accent)",
              marginRight: 4,
            }}
          />
          TASK
        </span>
        <span>
          <span
            style={{
              display: "inline-block",
              width: 10,
              height: 6,
              background: "var(--red)",
              marginRight: 4,
            }}
          />
          CRITICAL
        </span>
        <span>
          <span
            style={{
              display: "inline-block",
              width: 8,
              height: 8,
              background: "var(--green)",
              transform: "rotate(45deg)",
              marginRight: 4,
            }}
          />
          START/END
        </span>
        <span>
          <span
            style={{
              display: "inline-block",
              width: 8,
              height: 8,
              background: "var(--gold)",
              transform: "rotate(45deg)",
              marginRight: 4,
            }}
          />
          BID DUE
        </span>
        <span>
          <span
            style={{
              display: "inline-block",
              width: 8,
              height: 8,
              background: "var(--cyan)",
              transform: "rotate(45deg)",
              marginRight: 4,
            }}
          />
          INSPECTION
        </span>
      </div>
    </div>
  );
}
