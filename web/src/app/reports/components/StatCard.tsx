"use client";

type StatCardProps = {
  value: string;
  label: string;
  color?: string;
};

/** UI-SPEC KPI Stat Card: centered value + micro label */
export function StatCard({ value, label, color }: StatCardProps) {
  return (
    <div
      style={{
        textAlign: "center",
        padding: 16,
        background: "rgba(242,158,61,0.06)",
        borderRadius: 10,
      }}
    >
      <div
        style={{
          fontSize: 24,
          fontWeight: 800,
          color: color || "var(--text)",
        }}
      >
        {value}
      </div>
      <div
        style={{
          fontSize: 8,
          fontWeight: 800,
          color: "var(--muted)",
          textTransform: "uppercase",
        }}
      >
        {label}
      </div>
    </div>
  );
}
