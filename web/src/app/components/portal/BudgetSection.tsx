import SectionWrapper from "./SectionWrapper";

// D-30: Budget masked by default (percentages and status bars, no dollar amounts)
// D-38: Dollar amounts only if showExactAmounts is true

type BudgetSectionProps = {
  budget: Record<string, unknown>;
  showExactAmounts: boolean;
  sectionNote?: string;
};

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: "USD",
    maximumFractionDigits: 0,
  }).format(value);
}

function getStatusColor(percent: number): string {
  if (percent <= 80) return "#16A34A"; // Green: on/under budget
  if (percent <= 95) return "#F59E0B"; // Amber: approaching
  return "#DC2626"; // Red: over budget
}

export default function BudgetSection({
  budget,
  showExactAmounts,
  sectionNote,
}: BudgetSectionProps) {
  const percentComplete = (budget.percentComplete as number) ?? 0;
  const masked = budget.masked as boolean;

  return (
    <SectionWrapper
      id="budget"
      title="Budget"
      sectionNote={sectionNote}
    >
      {/* Progress bar */}
      <div style={{ marginBottom: 20 }}>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginBottom: 6,
            fontSize: 13,
          }}
        >
          <span style={{ color: "#374151", fontWeight: 500 }}>
            Budget Utilized
          </span>
          <span
            style={{
              fontWeight: 600,
              color: getStatusColor(percentComplete),
            }}
          >
            {percentComplete.toFixed(1)}%
          </span>
        </div>
        <div
          style={{
            height: 8,
            background: "#E2E5E9",
            borderRadius: 4,
            overflow: "hidden",
          }}
        >
          <div
            style={{
              height: "100%",
              width: `${Math.min(percentComplete, 100)}%`,
              background: getStatusColor(percentComplete),
              borderRadius: 4,
              transition: "width 300ms ease-in-out",
            }}
          />
        </div>
      </div>

      {/* Budget metrics grid */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(140px, 1fr))",
          gap: 12,
        }}
      >
        <MetricCard
          label="Contract Value"
          value={
            showExactAmounts && !masked
              ? formatCurrency(budget.contractValue as number)
              : (budget.maskedContractValue as string) ?? "---"
          }
        />
        <MetricCard
          label="Total Billed"
          value={
            showExactAmounts && !masked
              ? formatCurrency(budget.totalBilled as number)
              : (budget.maskedTotalBilled as string) ?? "---"
          }
        />
        <MetricCard
          label="Change Orders"
          value={
            showExactAmounts && !masked
              ? formatCurrency(budget.changeOrderNet as number)
              : (budget.maskedChangeOrderNet as string) ?? "---"
          }
        />
        <MetricCard
          label="Remaining"
          value={
            showExactAmounts && !masked
              ? formatCurrency(budget.remaining as number)
              : (budget.maskedRemaining as string) ?? "---"
          }
        />
        <MetricCard label="% Complete" value={`${percentComplete.toFixed(1)}%`} />
        <MetricCard
          label="Retainage"
          value={
            showExactAmounts && !masked
              ? formatCurrency(budget.retainage as number)
              : (budget.maskedRetainage as string) ?? "---"
          }
        />
      </div>

      {/* Masking notice */}
      {masked && (
        <p
          style={{
            fontSize: 11,
            color: "#9CA3AF",
            marginTop: 12,
            textAlign: "center",
          }}
        >
          Financial details are shown as ranges for privacy.
        </p>
      )}
    </SectionWrapper>
  );
}

function MetricCard({ label, value }: { label: string; value: string }) {
  return (
    <div
      style={{
        padding: 12,
        background: "#F8F9FB",
        borderRadius: 8,
        textAlign: "center",
      }}
    >
      <div
        style={{
          fontSize: 16,
          fontWeight: 700,
          color: "var(--portal-text, #1F2937)",
          marginBottom: 4,
        }}
      >
        {value}
      </div>
      <div
        style={{
          fontSize: 11,
          color: "#9CA3AF",
          textTransform: "uppercase",
          letterSpacing: 0.5,
        }}
      >
        {label}
      </div>
    </div>
  );
}
