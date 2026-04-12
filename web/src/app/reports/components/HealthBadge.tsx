"use client";

type HealthBadgeProps = {
  score: number;
  color: "green" | "gold" | "red";
  label: string;
};

const COLOR_MAP: Record<string, string> = {
  green: "var(--green)",
  gold: "var(--gold)",
  red: "var(--red)",
};

/** UI-SPEC Health Score Badge: dot + label inline */
export function HealthBadge({ score, color, label }: HealthBadgeProps) {
  const cssColor = COLOR_MAP[color] || "var(--muted)";

  return (
    <span
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 4,
        padding: "4px 8px",
        borderRadius: 6,
      }}
      aria-label={`Health score: ${score}% - ${label}`}
    >
      <span
        style={{
          width: 8,
          height: 8,
          borderRadius: "50%",
          background: cssColor,
          flexShrink: 0,
        }}
      />
      <span
        style={{
          fontSize: 8,
          fontWeight: 800,
          color: cssColor,
        }}
      >
        {label}
      </span>
    </span>
  );
}
