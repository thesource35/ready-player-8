"use client";

import { useState } from "react";
import { BudgetSection } from "./BudgetSection";
import { ScheduleSection } from "./ScheduleSection";
import { SafetySection } from "./SafetySection";
import { TeamSection } from "./TeamSection";
import { AIInsightsSection } from "./AIInsightsSection";
import { ReportHeader } from "./ReportHeader";
import type {
  BudgetSection as BudgetSectionType,
  ScheduleSection as ScheduleSectionType,
  SafetySection as SafetySectionType,
  TeamSection as TeamSectionType,
  AIInsightsSection as AIInsightsSectionType,
} from "@/lib/reports/types";

// ---------- Demo Data (D-66c) ----------

const DEMO_PROJECT = {
  name: "Riverside Mixed-Use Development",
  client: "Metro Development Corp",
  generatedAt: new Date().toISOString(),
  health: { score: 78, color: "gold" as const, label: "At Risk" as const },
};

const DEMO_BUDGET: BudgetSectionType = {
  contractValue: 2_400_000,
  totalBilled: 1_800_000,
  percentComplete: 75,
  changeOrderNet: 85_000,
  retainage: 90_000,
  spent: 1_710_000,
  remaining: 690_000,
};

const DEMO_SCHEDULE: ScheduleSectionType = {
  milestones: [
    { name: "Site Preparation", percentComplete: 100, status: "Complete" },
    { name: "Foundation", percentComplete: 100, status: "Complete" },
    { name: "Structural Steel", percentComplete: 95, status: "Active" },
    { name: "MEP Rough-In", percentComplete: 70, status: "Active" },
    { name: "Exterior Envelope", percentComplete: 45, status: "Active" },
    { name: "Interior Framing", percentComplete: 20, status: "Delayed" },
    { name: "Finish Work", percentComplete: 0, status: "Pending" },
    { name: "Final Inspections", percentComplete: 0, status: "Pending" },
  ],
  delayedCount: 1,
  totalCount: 8,
};

const DEMO_SAFETY: SafetySectionType = {
  totalIncidents: 4,
  severityBreakdown: { minor: 3, moderate: 1, serious: 0 },
  daysSinceLastIncident: 14,
  monthlyData: [
    { month: "Jan", count: 1 },
    { month: "Feb", count: 0 },
    { month: "Mar", count: 2 },
    { month: "Apr", count: 1 },
    { month: "May", count: 0 },
    { month: "Jun", count: 0 },
  ],
  incidents: [
    {
      id: "demo-s1",
      description: "Slip on wet surface — first aid only",
      severity: "minor",
      date: "2026-03-28",
    },
    {
      id: "demo-s2",
      description: "Tool dropped from height — near miss",
      severity: "minor",
      date: "2026-03-15",
    },
    {
      id: "demo-s3",
      description: "Scaffolding bracket failure — worker bruise",
      severity: "moderate",
      date: "2026-03-10",
    },
    {
      id: "demo-s4",
      description: "Material stored improperly — corrected",
      severity: "minor",
      date: "2026-01-22",
    },
  ],
};

const DEMO_TEAM: TeamSectionType = {
  memberCount: 12,
  recentActivity: [
    {
      user: "J. Martinez",
      action: "Updated schedule milestone: MEP Rough-In to 70%",
      timestamp: "2026-04-10T14:30:00Z",
    },
    {
      user: "S. Chen",
      action: "Added safety incident report",
      timestamp: "2026-04-09T09:15:00Z",
    },
    {
      user: "K. Patel",
      action: "Approved change order #CO-103",
      timestamp: "2026-04-08T16:45:00Z",
    },
    {
      user: "R. Thompson",
      action: "Uploaded daily log with 4 photos",
      timestamp: "2026-04-07T17:00:00Z",
    },
    {
      user: "M. Davis",
      action: "Created RFI for structural beam spec",
      timestamp: "2026-04-06T11:20:00Z",
    },
  ],
  roleBreakdown: {
    "Project Manager": 1,
    Superintendent: 2,
    Foreman: 3,
    "Safety Officer": 1,
    Laborer: 5,
  },
};

const DEMO_AI_INSIGHTS: AIInsightsSectionType = {
  summary:
    "Riverside project is 75% complete with one delayed milestone. Interior framing is behind schedule — consider reallocating crew from completed foundation tasks.",
  recommendations: [
    {
      section: "schedule",
      text: "Interior framing is 2 weeks behind. Shift 2 workers from site prep to accelerate.",
      actionable: true,
    },
    {
      section: "budget",
      text: "Change order volume is within normal range at 3.5% of contract value.",
      actionable: false,
    },
    {
      section: "safety",
      text: "14 days since last incident. Consider recognizing safety milestone with crew.",
      actionable: true,
    },
  ],
};

// ---------- Tabs ----------

const TABS = ["Financial", "Schedule", "Safety", "Team", "AI Insights"] as const;
type Tab = (typeof TABS)[number];

// ---------- Component ----------

type DemoReportProps = {
  onClose?: () => void;
};

export function DemoReport({ onClose }: DemoReportProps) {
  const [activeTab, setActiveTab] = useState<Tab>("Financial");

  return (
    <div>
      {/* D-66c: demo banner */}
      <div
        style={{
          background: "rgba(242,158,61,0.1)",
          border: "1px solid rgba(242,158,61,0.3)",
          borderRadius: 8,
          padding: "10px 16px",
          marginBottom: 16,
          fontSize: 12,
          color: "var(--accent)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
        }}
      >
        <span>
          This is a demo report with sample data. Create a project to see your
          own data.
        </span>
        {onClose && (
          <button
            onClick={onClose}
            style={{
              background: "var(--accent)",
              color: "#000",
              border: "none",
              borderRadius: 6,
              padding: "4px 12px",
              fontSize: 11,
              fontWeight: 700,
              cursor: "pointer",
            }}
          >
            Close Demo
          </button>
        )}
      </div>

      {/* Report header */}
      <ReportHeader
        projectName={DEMO_PROJECT.name}
        clientName={DEMO_PROJECT.client}
        generatedAt={DEMO_PROJECT.generatedAt}
        health={DEMO_PROJECT.health}
      />

      {/* Tab navigation */}
      <div
        style={{
          display: "flex",
          gap: 0,
          borderBottom: "1px solid var(--border)",
          marginBottom: 16,
          marginTop: 16,
        }}
      >
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={{
              padding: "8px 16px",
              fontSize: 11,
              fontWeight: activeTab === tab ? 800 : 500,
              color: activeTab === tab ? "var(--accent)" : "var(--muted)",
              background: "none",
              border: "none",
              borderBottom:
                activeTab === tab ? "2px solid var(--accent)" : "2px solid transparent",
              cursor: "pointer",
              transition: "all 0.15s",
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      {/* Tab content */}
      {activeTab === "Financial" && <BudgetSection data={DEMO_BUDGET} />}
      {activeTab === "Schedule" && <ScheduleSection data={DEMO_SCHEDULE} />}
      {activeTab === "Safety" && <SafetySection data={DEMO_SAFETY} />}
      {activeTab === "Team" && <TeamSection data={DEMO_TEAM} />}
      {activeTab === "AI Insights" && <AIInsightsSection data={DEMO_AI_INSIGHTS} />}
    </div>
  );
}

/**
 * CTA button to open the demo report from the empty state.
 */
export function DemoReportCTA({ onClick }: { onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      style={{
        background: "var(--accent)",
        color: "#000",
        border: "none",
        borderRadius: 8,
        padding: "10px 20px",
        fontSize: 13,
        fontWeight: 700,
        cursor: "pointer",
        marginTop: 12,
      }}
    >
      View Demo Report
    </button>
  );
}
