"use client";

import type { AIInsightsSection as AIInsightsSectionType } from "@/lib/reports/types";

type AIInsightsSectionProps = {
  data: AIInsightsSectionType | null;
};

/** D-16d: "Key Insights" heading with AI-generated analysis
 *  D-16e: recommendations inline per section + action items summary */
export function AIInsightsSection({ data }: AIInsightsSectionProps) {
  return (
    <div>
      <div
        style={{
          fontSize: 12,
          fontWeight: 800,
          letterSpacing: 2,
          color: "var(--accent)",
          textTransform: "uppercase",
          marginBottom: 8,
          marginTop: 24,
        }}
      >
        Key Insights
      </div>

      {/* UI-SPEC: If no AI data, show prompt message */}
      {!data || (!data.summary && data.recommendations.length === 0) ? (
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
          Add more project data to unlock AI-powered insights.
        </div>
      ) : (
        <>
          {/* AI summary */}
          {data.summary && (
            <div
              style={{
                background: "var(--surface)",
                borderRadius: 10,
                padding: 16,
                marginBottom: 12,
                fontSize: 12,
                lineHeight: 1.5,
                color: "var(--text)",
              }}
            >
              {data.summary}
            </div>
          )}

          {/* D-16e: Recommendations */}
          {data.recommendations.length > 0 && (
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
                Recommendations
              </div>
              {data.recommendations.map((rec, i) => (
                <div
                  key={`rec-${i}`}
                  style={{
                    background: "var(--surface)",
                    borderRadius: 10,
                    padding: 12,
                    marginBottom: 8,
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                    gap: 12,
                  }}
                >
                  <div>
                    <div style={{ fontSize: 12, lineHeight: 1.5 }}>{rec.text}</div>
                    <div style={{ fontSize: 8, color: "var(--muted)", marginTop: 4 }}>
                      {rec.section}
                    </div>
                  </div>
                  {rec.actionable && (
                    <span
                      style={{
                        fontSize: 8,
                        fontWeight: 800,
                        color: "var(--accent)",
                        background: "rgba(242,158,61,0.1)",
                        padding: "3px 8px",
                        borderRadius: 4,
                        textTransform: "uppercase",
                        whiteSpace: "nowrap",
                        flexShrink: 0,
                      }}
                    >
                      Action Item
                    </span>
                  )}
                </div>
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
