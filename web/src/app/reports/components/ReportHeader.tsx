"use client";

import { HealthBadge } from "./HealthBadge";
import type { HealthScore } from "@/lib/reports/types";

type ReportHeaderProps = {
  projectName: string;
  clientName: string;
  generatedAt: string;
  health: HealthScore;
};

/** D-10: project name, client name, date generated, health status badge */
export function ReportHeader({
  projectName,
  clientName,
  generatedAt,
  health,
}: ReportHeaderProps) {
  // D-16b: "Generated {Month DD, YYYY at HH:MM}"
  const dateStr = (() => {
    try {
      const d = new Date(generatedAt);
      return `Generated ${d.toLocaleDateString("en-US", {
        month: "long",
        day: "numeric",
        year: "numeric",
      })} at ${d.toLocaleTimeString("en-US", {
        hour: "2-digit",
        minute: "2-digit",
      })}`;
    } catch {
      return `Generated ${generatedAt}`;
    }
  })();

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        padding: 20,
        marginBottom: 16,
        border: "1px solid rgba(105,210,148,0.08)",
      }}
    >
      <div
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "flex-start",
          flexWrap: "wrap",
          gap: 12,
        }}
      >
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 800, margin: 0 }}>{projectName}</h2>
          {clientName && (
            <div style={{ fontSize: 12, color: "var(--muted)", marginTop: 4 }}>
              {clientName}
            </div>
          )}
          <div style={{ fontSize: 10, color: "var(--muted)", marginTop: 4 }}>
            {dateStr}
          </div>
        </div>
        <HealthBadge score={health.score} color={health.color} label={health.label} />
      </div>
      {/* D-10: customizable company branding placeholder for future white-labeling */}
      <div
        style={{
          fontSize: 8,
          color: "var(--muted)",
          marginTop: 12,
          opacity: 0.5,
        }}
        aria-hidden="true"
      >
        {/* Logo placeholder — future white-labeling per D-107 */}
      </div>
    </div>
  );
}
