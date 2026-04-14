import SectionWrapper from "./SectionWrapper";

// D-38: Show scope + status always. Dollar amounts only if showAmounts is true
// Status badge: approved (green), pending (amber), rejected (red)

type ChangeOrdersSectionProps = {
  changeOrders: Record<string, unknown>[];
  showAmounts: boolean;
  sectionNote?: string;
};

function getStatusStyle(status: string): { bg: string; color: string } {
  const s = (status ?? "").toLowerCase();
  if (s === "approved") return { bg: "#F0FDF4", color: "#16A34A" };
  if (s === "rejected" || s === "denied") return { bg: "#FEF2F2", color: "#DC2626" };
  return { bg: "#FFFBEB", color: "#F59E0B" }; // pending / other
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value);
}

export default function ChangeOrdersSection({
  changeOrders,
  showAmounts,
  sectionNote,
}: ChangeOrdersSectionProps) {
  return (
    <SectionWrapper
      id="change_orders"
      title="Change Orders"
      itemCount={changeOrders.length}
      sectionNote={sectionNote}
    >
      <div>
        {changeOrders.map((co, i) => {
          const status = (co.status as string) ?? "Pending";
          const statusStyle = getStatusStyle(status);

          return (
            <div
              key={(co.id as string) ?? i}
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "12px 0",
                borderBottom:
                  i < changeOrders.length - 1 ? "1px solid #F1F3F5" : "none",
                gap: 12,
              }}
            >
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontSize: 14,
                    fontWeight: 500,
                    color: "var(--portal-text, #374151)",
                    marginBottom: 4,
                  }}
                >
                  {(co.title as string) ??
                    (co.description as string) ??
                    `CO-${i + 1}`}
                </div>
                {Boolean(co.scope) && (
                  <div style={{ fontSize: 12, color: "#6B7280" }}>
                    {co.scope as string}
                  </div>
                )}
              </div>

              {/* Amount (only if showAmounts) */}
              {showAmounts && co.amount != null && (
                <span
                  style={{
                    fontSize: 13,
                    fontWeight: 600,
                    color: "#374151",
                    whiteSpace: "nowrap",
                  }}
                >
                  {formatCurrency(co.amount as number)}
                </span>
              )}

              {/* Status badge */}
              <span
                style={{
                  fontSize: 11,
                  fontWeight: 600,
                  padding: "4px 10px",
                  borderRadius: 12,
                  background: statusStyle.bg,
                  color: statusStyle.color,
                  whiteSpace: "nowrap",
                  textTransform: "capitalize",
                }}
              >
                {status}
              </span>
            </div>
          );
        })}

        {changeOrders.length === 0 && (
          <p
            style={{
              fontSize: 13,
              color: "#9CA3AF",
              textAlign: "center",
              padding: 16,
            }}
          >
            No change orders.
          </p>
        )}
      </div>
    </SectionWrapper>
  );
}
