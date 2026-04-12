"use client";

/**
 * UI-SPEC Skeleton Loading + D-58: shimmer animation with progressive loading.
 * D-62: KPI cards first, then charts (progressive loading order).
 * D-26h: each chart area loads independently.
 */

const shimmerKeyframes = `
@keyframes shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
`;

const shimmerStyle: React.CSSProperties = {
  background: "linear-gradient(90deg, var(--surface) 25%, var(--panel) 50%, var(--surface) 75%)",
  backgroundSize: "200% 100%",
  animation: "shimmer 1.5s infinite",
  borderRadius: 10,
};

export function SkeletonReport() {
  return (
    <>
      {/* Inject keyframes */}
      <style>{shimmerKeyframes}</style>

      {/* KPI skeleton: 4 cards at height 72px — loads first per D-62 */}
      <div
        data-testid="skeleton-kpi"
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
          gap: 8,
          marginBottom: 16,
        }}
      >
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={`kpi-${i}`} style={{ ...shimmerStyle, height: 72 }} />
        ))}
      </div>

      {/* Chart skeleton: single block at 240px — loads second per D-62 */}
      <div
        data-testid="skeleton-chart"
        style={{
          ...shimmerStyle,
          height: 240,
          borderRadius: 14,
          marginBottom: 16,
        }}
      />

      {/* List skeleton: 4 rows at 48px — loads third */}
      <div data-testid="skeleton-list" style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {Array.from({ length: 4 }).map((_, i) => (
          <div key={`list-${i}`} style={{ ...shimmerStyle, height: 48 }} />
        ))}
      </div>
    </>
  );
}
