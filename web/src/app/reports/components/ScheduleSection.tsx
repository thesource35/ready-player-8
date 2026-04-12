"use client";

import { ScheduleBarChart } from "./ScheduleBarChart";
import type { ScheduleSection as ScheduleSectionType } from "@/lib/reports/types";

type ScheduleSectionProps = {
  data: ScheduleSectionType | null;
  freshness?: string;
};

const healthColor = (pct: number): string =>
  pct >= 80 ? "var(--green)" : pct >= 50 ? "var(--gold)" : "var(--red)";

/** D-12: progress bars for milestones (% complete) */
export function ScheduleSection({ data, freshness }: ScheduleSectionProps) {
  return (
    <div>
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 8,
          marginTop: 24,
        }}
      >
        <div
          style={{
            fontSize: 12,
            fontWeight: 800,
            letterSpacing: 2,
            color: "var(--cyan)",
            textTransform: "uppercase",
          }}
        >
          Schedule &amp; Milestones
        </div>
        {freshness && (
          <div style={{ fontSize: 8, color: "var(--muted)" }}>
            Last updated {new Date(freshness).toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* D-08: if no tasks, show "None recorded" */}
      {!data || data.milestones.length === 0 ? (
        <div
          style={{
            background: "var(--surface)",
            borderRadius: 10,
            padding: 20,
            textAlign: "center",
            color: "var(--muted)",
            fontSize: 12,
          }}
        >
          None recorded
        </div>
      ) : (
        <>
          {/* Summary */}
          <div
            style={{
              display: "flex",
              gap: 16,
              marginBottom: 12,
              fontSize: 12,
            }}
          >
            <span>
              <strong>{data.totalCount}</strong>{" "}
              <span style={{ color: "var(--muted)" }}>milestones</span>
            </span>
            {data.delayedCount > 0 && (
              <span style={{ color: "var(--red)" }}>
                <strong>{data.delayedCount}</strong> delayed
              </span>
            )}
          </div>

          {/* UI-SPEC Progress Bar: milestone progress bars */}
          {data.milestones.slice(0, 8).map((m) => (
            <div
              key={m.name}
              style={{
                background: "var(--surface)",
                borderRadius: 10,
                padding: 12,
                marginBottom: 8,
              }}
            >
              <div
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  marginBottom: 6,
                  fontSize: 12,
                }}
              >
                <span style={{ fontWeight: 800 }}>{m.name}</span>
                <span style={{ color: healthColor(m.percentComplete), fontWeight: 800 }}>
                  {m.percentComplete}%
                </span>
              </div>
              {/* UI-SPEC: track rgba(51,84,94,0.3), fill health color, borderRadius 4, height 8 */}
              <div
                style={{
                  background: "rgba(51,84,94,0.3)",
                  borderRadius: 4,
                  height: 8,
                }}
              >
                <div
                  style={{
                    background: healthColor(m.percentComplete),
                    borderRadius: 4,
                    height: 8,
                    width: `${Math.min(100, Math.max(0, m.percentComplete))}%`,
                    transition: "width 0.3s ease",
                  }}
                />
              </div>
            </div>
          ))}

          {/* D-26: Schedule bar chart for top milestones */}
          <ScheduleBarChart milestones={data.milestones} />
        </>
      )}
    </div>
  );
}
