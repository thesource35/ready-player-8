"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const tabs = [
  { label: "PROJECT REPORT", href: "/reports" },
  { label: "PORTFOLIO ROLLUP", href: "/reports/rollup" },
  { label: "SCHEDULES", href: "/reports/schedules" },
];

export default function ReportsLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();

  /** Active if exact match or if pathname starts with the tab href (for nested routes) */
  function isActive(href: string): boolean {
    if (href === "/reports") {
      // Exact match or project sub-routes, but NOT /reports/rollup or /reports/schedules
      return pathname === "/reports" || pathname.startsWith("/reports/project");
    }
    return pathname.startsWith(href);
  }

  return (
    <div style={{ maxWidth: 1200, margin: "0 auto", padding: 20 }}>
      {/* UI-SPEC Report Page Shell: page header */}
      <div
        style={{
          background: "var(--surface)",
          borderRadius: 14,
          padding: 20,
          marginBottom: 16,
          border: "1px solid rgba(105,210,148,0.08)",
        }}
      >
        <div
          style={{
            fontSize: 12,
            fontWeight: 800,
            letterSpacing: 3,
            color: "var(--green)",
            textTransform: "uppercase",
          }}
        >
          REPORTS
        </div>
        <h1 style={{ fontSize: 24, fontWeight: 800, margin: "4px 0" }}>
          Reporting Dashboard
        </h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>
          Project reports, portfolio rollup, and scheduled deliveries
        </p>
      </div>

      {/* UI-SPEC Tab Bar: 3 tabs per D-50b */}
      <div
        style={{
          display: "flex",
          gap: 0,
          borderRadius: 8,
          overflow: "hidden",
          marginBottom: 16,
        }}
      >
        {tabs.map((tab) => {
          const active = isActive(tab.href);
          return (
            <Link
              key={tab.href}
              href={tab.href}
              style={{
                flex: 1,
                textAlign: "center",
                padding: "8px 0",
                fontSize: 8,
                fontWeight: 800,
                letterSpacing: 1,
                textTransform: "uppercase",
                textDecoration: "none",
                background: active ? "var(--accent)" : "var(--surface)",
                color: active ? "var(--bg)" : "var(--muted)",
                cursor: "pointer",
              }}
            >
              {tab.label}
            </Link>
          );
        })}
      </div>

      {children}
    </div>
  );
}
