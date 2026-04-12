// Report type definitions for Phase 19 — Reporting & Dashboards
// Aligned with SupabaseService.swift DTOs and Supabase table schemas.
// All types are pure data shapes with no runtime dependencies.

// ---------- Health ----------

export type HealthColor = "green" | "gold" | "red";
export type HealthLabel = "On Track" | "At Risk" | "Critical";

export type HealthScore = {
  score: number;
  color: HealthColor;
  label: HealthLabel;
};

// ---------- Report Sections ----------

/** D-13: Budget shows summary totals — contract value, total billed, % complete, change order net, retainage */
export type BudgetSection = {
  contractValue: number;
  totalBilled: number;
  percentComplete: number;
  changeOrderNet: number;
  retainage: number;
  spent: number;
  remaining: number;
};

/** D-12: Simple progress bars per milestone */
export type ScheduleMilestone = {
  name: string;
  percentComplete: number;
  status: string;
};

export type ScheduleSection = {
  milestones: ScheduleMilestone[];
  delayedCount: number;
  totalCount: number;
};

/** D-11: Clickable items in Issues & Risks */
export type RfiItem = {
  id: string;
  subject: string;
  status: string;
  created_at: string;
};

export type ChangeOrderItem = {
  id: string;
  description: string;
  amount: number;
  status: string;
};

export type IssuesSection = {
  rfis: RfiItem[];
  changeOrders: ChangeOrderItem[];
  criticalOpen: number;
  totalOpen: number;
};

/** D-14: Team counts + recent activity */
export type ActivityEntry = {
  user: string;
  action: string;
  timestamp: string;
};

export type TeamSection = {
  memberCount: number;
  recentActivity: ActivityEntry[];
  roleBreakdown: Record<string, number>;
};

/** D-16: Safety incidents with severity breakdown */
export type SafetyIncident = {
  id: string;
  description: string;
  severity: string;
  date: string;
};

export type SafetyMonthlyData = {
  month: string;
  count: number;
};

export type SafetySection = {
  totalIncidents: number;
  severityBreakdown: { minor: number; moderate: number; serious: number };
  daysSinceLastIncident: number;
  monthlyData: SafetyMonthlyData[];
  incidents: SafetyIncident[];
};

/** D-16d, D-16e: AI-generated insights */
export type AIRecommendation = {
  section: string;
  text: string;
  actionable: boolean;
};

export type AIInsightsSection = {
  summary: string;
  recommendations: AIRecommendation[];
};

/** D-16b, D-56f: Per-section wrapper with freshness and error tracking */
export type SectionError = {
  code: string;
  message: string;
  retryable: boolean;
};

export type ReportSection = {
  data: unknown;
  freshness: string;
  error?: SectionError;
};

// ---------- Project Report ----------

/** D-01, D-02, D-08, D-15: Single-project summary report */
export type ProjectReport = {
  project_id: string;
  project_name: string;
  client_name: string;
  generated_at: string;
  health: HealthScore;
  budget: BudgetSection | null;
  schedule: ScheduleSection | null;
  issues: IssuesSection | null;
  team: TeamSection | null;
  safety: SafetySection | null;
  ai_insights: AIInsightsSection | null;
  documents: { count: number };
  photos: { count: number };
  errors: Array<{ section: string; error: string }>;
};

// ---------- Portfolio Rollup ----------

/** D-16c, D-37, D-41: Per-project summary in rollup */
export type ProjectSummary = {
  id: string;
  name: string;
  status: string;
  health: HealthScore;
  contractValue: number;
  billed: number;
  percentComplete: number;
  scheduleHealth: string;
  openIssues: number;
  safetyIncidents: number;
  featureCoverage: { active: number; total: number };
};

/** D-35 through D-46b: Cross-project portfolio rollup */
export type PortfolioRollup = {
  generated_at: string;
  health: HealthScore;
  projects: ProjectSummary[];
  totals: {
    contractValue: number;
    totalBilled: number;
    changeOrderNet: number;
  };
  monthlySpend: Array<{ month: string; amount: number }>;
};

// ---------- Scheduling & Delivery ----------

/** D-49, D-50b: Report schedule configuration */
export type ReportSchedule = {
  id: string;
  frequency: "daily" | "weekly" | "biweekly" | "monthly";
  day_of_week?: number;
  day_of_month?: number;
  time_utc: string;
  timezone: string;
  recipients: string[];
  sections: string[];
  is_active: boolean;
  last_run_at: string | null;
  next_run_at: string | null;
};

/** D-64b: Shareable report link */
export type SharedLink = {
  id: string;
  token: string;
  project_id: string | null;
  report_type: "project" | "rollup";
  expires_at: string;
  view_count: number;
  is_revoked: boolean;
};

/** D-50h: Delivery audit log */
export type DeliveryLog = {
  id: string;
  schedule_id: string;
  recipients: string[];
  status: "sent" | "failed" | "partial";
  error_message?: string;
  pdf_storage_path?: string;
  created_at: string;
};

// ---------- Templates ----------

/** D-93, D-94: Report template configuration */
export type ReportTemplate = {
  id: string;
  name: string;
  description: string;
  template_config: {
    sections: string[];
    ordering: string[];
    visibility: Record<string, boolean>;
    customCSS?: string;
  };
};

// ---------- Comparison ----------

/** D-46b: Period-over-period comparison */
export type ComparePeriod = {
  current: PortfolioRollup;
  previous: PortfolioRollup;
  deltas: Record<string, number>;
};
