"use client";

import { StatCard } from "./StatCard";
import type { TeamSection as TeamSectionType } from "@/lib/reports/types";

type TeamSectionProps = {
  data: TeamSectionType | null;
  freshness?: string;
  documentCount?: number;
  photoCount?: number;
};

/** D-14: member counts + 3-5 most recent activity feed entries, D-15: doc/photo counts */
export function TeamSection({ data, freshness, documentCount, photoCount }: TeamSectionProps) {
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
            color: "var(--purple)",
            textTransform: "uppercase",
          }}
        >
          Team &amp; Activity
        </div>
        {freshness && (
          <div style={{ fontSize: 8, color: "var(--muted)" }}>
            Last updated {new Date(freshness).toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* D-08: if no team data, show "None recorded" */}
      {!data || data.memberCount === 0 ? (
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
          {/* Team stat cards */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
              gap: 8,
              marginBottom: 16,
            }}
          >
            <StatCard
              value={String(data.memberCount)}
              label="Team Members"
              color="var(--purple)"
            />
            {/* D-15: document and photo counts */}
            <StatCard
              value={String(documentCount ?? 0)}
              label="Documents"
              color="var(--cyan)"
            />
            <StatCard
              value={String(photoCount ?? 0)}
              label="Photos"
              color="var(--green)"
            />
          </div>

          {/* Role breakdown */}
          {Object.keys(data.roleBreakdown).length > 0 && (
            <div style={{ marginBottom: 16 }}>
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
                Role Breakdown
              </div>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {Object.entries(data.roleBreakdown).map(([role, count]) => (
                  <div
                    key={role}
                    style={{
                      background: "var(--surface)",
                      borderRadius: 8,
                      padding: "6px 12px",
                      fontSize: 10,
                    }}
                  >
                    <span style={{ fontWeight: 800, color: "var(--purple)" }}>{count}</span>{" "}
                    <span style={{ color: "var(--muted)" }}>{role}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* D-14: 3-5 most recent activity feed entries */}
          {data.recentActivity.length > 0 && (
            <div>
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
                Recent Activity
              </div>
              {data.recentActivity.slice(0, 5).map((entry, i) => (
                <div
                  key={`activity-${i}`}
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
                    <span style={{ fontSize: 12, fontWeight: 800 }}>{entry.user}</span>
                    <span style={{ fontSize: 12, color: "var(--muted)", marginLeft: 8 }}>
                      {entry.action}
                    </span>
                  </div>
                  <div style={{ fontSize: 10, color: "var(--muted)" }}>
                    {new Date(entry.timestamp).toLocaleDateString()}
                  </div>
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
