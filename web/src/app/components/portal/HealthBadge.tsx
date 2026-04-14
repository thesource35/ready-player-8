// D-29: Health score badge always visible at top of portal
// D-94: Colored dot (8px circle) + text status indicator

type HealthBadgeProps = {
  score: number;
};

function getHealthState(score: number): {
  label: string;
  color: string;
  dotColor: string;
} {
  if (score > 75) {
    return { label: "Healthy", color: "#16A34A", dotColor: "#16A34A" };
  }
  if (score >= 50) {
    return { label: "At Risk", color: "#F59E0B", dotColor: "#F59E0B" };
  }
  return { label: "Critical", color: "#DC2626", dotColor: "#DC2626" };
}

export default function HealthBadge({ score }: HealthBadgeProps) {
  const { label, color, dotColor } = getHealthState(score);

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 8,
        marginBottom: 24,
        padding: "12px 16px",
        background: "var(--portal-card-bg, #FFFFFF)",
        borderRadius: "var(--portal-radius, 8px)",
        border: `1px solid ${color}30`,
      }}
    >
      {/* 8px colored dot (D-94) */}
      <div
        style={{
          width: 8,
          height: 8,
          borderRadius: "50%",
          background: dotColor,
          flexShrink: 0,
        }}
      />
      <span
        style={{
          fontSize: 14,
          fontWeight: 600,
          color,
        }}
      >
        {label}
      </span>
      <span
        style={{
          fontSize: 13,
          color: "#9CA3AF",
          marginLeft: 4,
        }}
      >
        Health Score: {score}
      </span>
    </div>
  );
}
