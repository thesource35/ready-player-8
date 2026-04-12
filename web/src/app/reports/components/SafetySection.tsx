"use client";

import { StatCard } from "./StatCard";
import { SafetyLineChart } from "./SafetyLineChart";
import type { SafetySection as SafetySectionType } from "@/lib/reports/types";

type SafetySectionProps = {
  data: SafetySectionType | null;
  freshness?: string;
};

const severityColor = (severity: string): string => {
  if (severity === "serious") return "var(--red)";
  if (severity === "moderate") return "var(--gold)";
  return "var(--green)";
};

/** D-16: count + severity breakdown (minor/moderate/serious) + days since last incident */
export function SafetySection({ data, freshness }: SafetySectionProps) {
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
            color: "var(--red)",
            textTransform: "uppercase",
          }}
        >
          Safety
        </div>
        {freshness && (
          <div style={{ fontSize: 8, color: "var(--muted)" }}>
            Last updated {new Date(freshness).toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* D-08: if no incidents, show positive "None recorded" message */}
      {!data || data.totalIncidents === 0 ? (
        <div
          style={{
            background: "var(--surface)",
            borderRadius: 10,
            padding: 20,
            textAlign: "center",
            color: "var(--green)",
            fontSize: 12,
          }}
        >
          None recorded — no safety incidents on file
        </div>
      ) : (
        <>
          {/* Severity breakdown stat cards */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
              gap: 8,
              marginBottom: 16,
            }}
          >
            <StatCard
              value={String(data.totalIncidents)}
              label="Total Incidents"
              color="var(--red)"
            />
            <StatCard
              value={String(data.severityBreakdown.minor)}
              label="Minor"
              color="var(--green)"
            />
            <StatCard
              value={String(data.severityBreakdown.moderate)}
              label="Moderate"
              color="var(--gold)"
            />
            <StatCard
              value={String(data.severityBreakdown.serious)}
              label="Serious"
              color="var(--red)"
            />
            <StatCard
              value={data.daysSinceLastIncident >= 0 ? String(data.daysSinceLastIncident) : "N/A"}
              label="Days Since Last"
              color={data.daysSinceLastIncident > 30 ? "var(--green)" : "var(--gold)"}
            />
          </div>

          {/* D-25: Safety line chart for monthly trend */}
          {data.monthlyData.length > 0 && (
            <SafetyLineChart monthlyData={data.monthlyData} />
          )}

          {/* D-16: full incident list when items exist */}
          {data.incidents.length > 0 && (
            <div style={{ marginTop: 12 }}>
              <div
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  color: "var(--muted)",
                  letterSpacing: 1,
                  textTransform: "uppercase",
                  marginBottom: 8,
                }}
              >
                Incident Log
              </div>
              {data.incidents.map((incident) => (
                <div
                  key={incident.id}
                  style={{
                    background: "var(--surface)",
                    borderRadius: 10,
                    padding: 12,
                    marginBottom: 8,
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                  }}
                >
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 800 }}>
                      {incident.description}
                    </div>
                    <div style={{ fontSize: 10, color: "var(--muted)" }}>
                      {new Date(incident.date).toLocaleDateString()}
                    </div>
                  </div>
                  <span
                    style={{
                      fontSize: 8,
                      fontWeight: 800,
                      color: severityColor(incident.severity),
                      background: `${severityColor(incident.severity)}15`,
                      padding: "3px 8px",
                      borderRadius: 4,
                      textTransform: "uppercase",
                    }}
                  >
                    {incident.severity}
                  </span>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
