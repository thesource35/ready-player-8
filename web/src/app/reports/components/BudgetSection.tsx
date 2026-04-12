"use client";

import { StatCard } from "./StatCard";
import { BudgetPieChart } from "./BudgetPieChart";
import type { BudgetSection as BudgetSectionType } from "@/lib/reports/types";

type BudgetSectionProps = {
  data: BudgetSectionType | null;
  freshness?: string;
  mini?: boolean;
};

const fmt = (n: number): string => {
  if (n >= 1_000_000) return `$${(n / 1_000_000).toFixed(1)}M`;
  if (n >= 1_000) return `$${Math.round(n / 1000)}K`;
  return `$${n.toLocaleString()}`;
};

/** D-13: contract value, total billed, % complete, change order net, retainage */
export function BudgetSection({ data, freshness, mini }: BudgetSectionProps) {
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
            color: "var(--accent)",
            textTransform: "uppercase",
          }}
        >
          Budget &amp; Financials
        </div>
        {freshness && (
          <div style={{ fontSize: 8, color: "var(--muted)" }}>
            Last updated {new Date(freshness).toLocaleTimeString()}
          </div>
        )}
      </div>

      {/* D-08: if no budget data, show "None recorded" */}
      {!data ? (
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
          {/* StatCard grid per UI-SPEC */}
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "repeat(auto-fit, minmax(140px, 1fr))",
              gap: 8,
              marginBottom: 16,
            }}
          >
            <StatCard value={fmt(data.contractValue)} label="Contract Value" color="var(--accent)" />
            <StatCard value={fmt(data.totalBilled)} label="Total Billed" color="var(--cyan)" />
            <StatCard value={`${data.percentComplete}%`} label="Complete" color="var(--green)" />
            <StatCard
              value={`${data.changeOrderNet >= 0 ? "+" : ""}${fmt(data.changeOrderNet)}`}
              label="Change Orders"
              color={data.changeOrderNet >= 0 ? "var(--gold)" : "var(--red)"}
            />
            <StatCard value={fmt(data.retainage)} label="Retainage" color="var(--gold)" />
          </div>

          {/* D-24: Budget pie chart (spent vs remaining donut) */}
          <BudgetPieChart spent={data.spent} remaining={data.remaining} mini={mini} />
        </>
      )}
    </div>
  );
}
