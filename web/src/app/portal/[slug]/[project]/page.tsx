import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import { getBrandingForPortal, getCompanyBranding } from "@/lib/portal/brandingQueries";
import { recordPortalView } from "@/lib/portal/analyticsQueries";
import {
  computeBudgetSection,
  computeScheduleSection,
  computeHealthScore,
  clampBudgetPercent,
} from "@/lib/reports/aggregation";
import { SECTION_ORDER } from "@/lib/portal/types";
import type { PortalConfig } from "@/lib/portal/types";
import type { Metadata } from "next";
import { headers } from "next/headers";
import PortalShell from "@/app/components/portal/PortalShell";
import ExpiredPage from "@/app/components/portal/ExpiredPage";

// D-24: URL pattern /portal/{company_slug}/{project_slug}
// D-123: Disabled sections never queried from database
// T-20-15: Budget data gated by shouldShowAmounts()
// T-20-16: Only enabled sections are queried
// T-20-17: 200ms delay on 404 to prevent enumeration

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// Service-role client for public portal access
// ---------------------------------------------------------------------------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// D-30, D-38: Budget masking logic
// ---------------------------------------------------------------------------

function shouldShowAmounts(config: PortalConfig): boolean {
  return (
    config.sections_config.budget.enabled === true &&
    config.show_exact_amounts === true
  );
}

function maskCurrency(value: number): string {
  if (value === 0) return "$0";
  if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M+`;
  if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K+`;
  return "$***";
}

// ---------------------------------------------------------------------------
// D-23: Dynamic metadata for branded OG tags
// ---------------------------------------------------------------------------

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string; project: string }>;
}): Promise<Metadata> {
  const { slug, project } = await params;
  const supabase = getServiceClient();
  if (!supabase) {
    return { title: "Portal | ConstructionOS", robots: "noindex, nofollow" };
  }

  const { data: config } = await supabase
    .from("cs_portal_config")
    .select("project_id, org_id, company_slug")
    .eq("company_slug", slug)
    .eq("slug", project)
    .eq("is_deleted", false)
    .maybeSingle();

  if (!config) {
    return { title: "Portal | ConstructionOS", robots: "noindex, nofollow" };
  }

  // Fetch project name
  const { data: proj } = await supabase
    .from("cs_projects")
    .select("name")
    .eq("id", config.project_id)
    .maybeSingle();

  // Fetch company branding for logo
  const branding = config.org_id
    ? await getCompanyBranding(config.org_id)
    : null;

  const projectName = (proj?.name as string) ?? "Project";
  const companyName = branding?.company_name ?? slug;
  const logoUrl = branding?.logo_light_path ?? undefined;

  return {
    title: `${projectName} - ${companyName}`,
    description: `View project progress for ${projectName}`,
    robots: "noindex, nofollow",
    openGraph: {
      title: `${projectName} - ${companyName}`,
      description: `View project progress for ${projectName}`,
      ...(logoUrl ? { images: [{ url: logoUrl }] } : {}),
    },
  };
}

// ---------------------------------------------------------------------------
// Per-section timeout wrapper (10s per section)
// ---------------------------------------------------------------------------

async function withTimeout<T>(
  promise: Promise<T>,
  ms: number = 10_000
): Promise<T | null> {
  try {
    const result = await Promise.race([
      promise,
      new Promise<null>((resolve) => setTimeout(() => resolve(null), ms)),
    ]);
    return result;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Section data fetchers
// ---------------------------------------------------------------------------

async function fetchScheduleData(supabase: SupabaseAny, projectId: string) {
  const { data: tasks } = await supabase
    .from("cs_project_tasks")
    .select("*")
    .eq("project_id", projectId)
    .order("start_date", { ascending: true });
  return computeScheduleSection(Array.isArray(tasks) ? tasks : []);
}

async function fetchBudgetData(
  supabase: SupabaseAny,
  projectId: string,
  showExact: boolean
) {
  const [{ data: proj }, { data: contracts }] = await Promise.all([
    supabase
      .from("cs_projects")
      .select("budget")
      .eq("id", projectId)
      .maybeSingle(),
    supabase.from("cs_contracts").select("*").eq("project_id", projectId),
  ]);

  const budget = computeBudgetSection(
    { budget: (proj?.budget as string) ?? "0" },
    Array.isArray(contracts) ? contracts : []
  );

  if (!showExact) {
    // Mask dollar amounts -- return percentages and status only
    return {
      ...budget,
      contractValue: 0,
      totalBilled: 0,
      changeOrderNet: 0,
      remaining: 0,
      retainage: 0,
      masked: true,
      maskedContractValue: maskCurrency(budget.contractValue),
      maskedTotalBilled: maskCurrency(budget.totalBilled),
      maskedChangeOrderNet: maskCurrency(budget.changeOrderNet),
      maskedRemaining: maskCurrency(budget.remaining),
      maskedRetainage: maskCurrency(budget.retainage),
    };
  }

  return { ...budget, masked: false };
}

async function fetchChangeOrders(supabase: SupabaseAny, projectId: string) {
  const { data } = await supabase
    .from("cs_change_orders")
    .select("*")
    .eq("project_id", projectId)
    .order("created_at", { ascending: false });
  return Array.isArray(data) ? data : [];
}

async function fetchDocuments(
  supabase: SupabaseAny,
  projectId: string,
  allowedIds?: string[]
) {
  let query = supabase
    .from("cs_documents")
    .select("*")
    .eq("project_id", projectId)
    .order("created_at", { ascending: false });

  if (allowedIds && allowedIds.length > 0) {
    query = query.in("id", allowedIds);
  }

  const { data } = await query;
  return Array.isArray(data) ? data : [];
}

async function fetchPhotos(supabase: SupabaseAny, projectId: string) {
  const { data } = await supabase
    .from("cs_field_photos")
    .select("*")
    .eq("project_id", projectId)
    .order("created_at", { ascending: false })
    .limit(20); // D-55: First 20 photos, lazy load more
  return Array.isArray(data) ? data : [];
}

// ---------------------------------------------------------------------------
// Rate limit check (D-109: 100 views/day per link)
// ---------------------------------------------------------------------------

async function checkDailyViewLimit(
  supabase: SupabaseAny,
  linkId: string
): Promise<boolean> {
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);

  const { count } = await supabase
    .from("cs_portal_analytics")
    .select("id", { count: "exact", head: true })
    .eq("link_id", linkId)
    .gte("created_at", todayStart.toISOString());

  return ((count as number) ?? 0) < 100;
}

// ---------------------------------------------------------------------------
// IP hash for analytics (D-114)
// ---------------------------------------------------------------------------

function hashIP(ip: string): string {
  // Simple hash for anonymization -- not crypto-grade, sufficient for analytics
  let hash = 0;
  for (let i = 0; i < ip.length; i++) {
    const char = ip.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash |= 0;
  }
  return Math.abs(hash).toString(36);
}

// ---------------------------------------------------------------------------
// Main page component
// ---------------------------------------------------------------------------

export default async function PortalPage({
  params,
}: {
  params: Promise<{ slug: string; project: string }>;
}) {
  const { slug, project } = await params;

  const supabase = getServiceClient();
  if (!supabase) {
    return <GenericNotFound />;
  }

  // Step 1: Look up portal config by company_slug + project_slug
  const { data: config, error: configErr } = await supabase
    .from("cs_portal_config")
    .select("*")
    .eq("company_slug", slug)
    .eq("slug", project)
    .eq("is_deleted", false)
    .maybeSingle();

  // D-122 / T-20-17: 200ms delay on 404 to prevent token enumeration
  if (configErr || !config) {
    await new Promise((resolve) => setTimeout(resolve, 200));
    return <GenericNotFound />;
  }

  const portalConfig = config as PortalConfig;

  // Step 2: Get associated shared link for expiry/revocation check
  const { data: link } = await supabase
    .from("cs_report_shared_links")
    .select("id, token, expires_at, is_revoked, view_count")
    .eq("id", portalConfig.link_id)
    .maybeSingle();

  if (!link) {
    await new Promise((resolve) => setTimeout(resolve, 200));
    return <GenericNotFound />;
  }

  // Check revoked
  if (link.is_revoked) {
    const branding = portalConfig.org_id
      ? await getCompanyBranding(portalConfig.org_id)
      : null;
    return (
      <ExpiredPage
        companyName={branding?.company_name}
        logoUrl={branding?.logo_light_path ?? undefined}
        isExpired={false}
      />
    );
  }

  // Check expired (D-15, D-69)
  if (link.expires_at && new Date(link.expires_at as string) < new Date()) {
    const branding = portalConfig.org_id
      ? await getCompanyBranding(portalConfig.org_id)
      : null;
    return (
      <ExpiredPage
        companyName={branding?.company_name}
        logoUrl={branding?.logo_light_path ?? undefined}
        isExpired={true}
      />
    );
  }

  // Step 3: Rate limit check (D-109)
  const allowed = await checkDailyViewLimit(supabase, link.id as string);
  if (!allowed) {
    return <RateLimitPage />;
  }

  // Step 4: Fetch enabled sections only (D-123 / T-20-16)
  const sectionsConfig = portalConfig.sections_config;
  const showAmounts = shouldShowAmounts(portalConfig);

  const sectionFetches: Promise<{ key: string; data: unknown }>[] = [];

  if (sectionsConfig.schedule.enabled) {
    sectionFetches.push(
      withTimeout(fetchScheduleData(supabase, portalConfig.project_id)).then(
        (data) => ({ key: "schedule", data })
      )
    );
  }

  if (sectionsConfig.budget.enabled) {
    sectionFetches.push(
      withTimeout(
        fetchBudgetData(supabase, portalConfig.project_id, showAmounts)
      ).then((data) => ({ key: "budget", data }))
    );
  }

  if (sectionsConfig.photos.enabled) {
    sectionFetches.push(
      withTimeout(fetchPhotos(supabase, portalConfig.project_id)).then(
        (data) => ({ key: "photos", data })
      )
    );
  }

  if (sectionsConfig.change_orders.enabled) {
    sectionFetches.push(
      withTimeout(fetchChangeOrders(supabase, portalConfig.project_id)).then(
        (data) => ({ key: "change_orders", data })
      )
    );
  }

  if (sectionsConfig.documents.enabled) {
    const allowedDocIds =
      sectionsConfig.documents.allowed_document_ids ?? undefined;
    sectionFetches.push(
      withTimeout(
        fetchDocuments(supabase, portalConfig.project_id, allowedDocIds)
      ).then((data) => ({ key: "documents", data }))
    );
  }

  // Promise.allSettled for parallel fetching with per-section failure isolation
  const sectionResults = await Promise.allSettled(sectionFetches);
  const sections: Record<string, unknown> = {};

  for (const result of sectionResults) {
    if (result.status === "fulfilled" && result.value.data != null) {
      sections[result.value.key] = result.value.data;
    }
  }

  // Step 5: Fetch project info for display
  const { data: projectData } = await supabase
    .from("cs_projects")
    .select("name, status, budget")
    .eq("id", portalConfig.project_id)
    .maybeSingle();

  const projectName = (projectData?.name as string) ?? "Project";

  // Step 6: Compute health score
  const budgetData = sections.budget as Record<string, unknown> | undefined;
  const scheduleData = sections.schedule as Record<string, unknown> | undefined;

  const budgetSpentPct =
    budgetData && (budgetData.contractValue as number) > 0
      ? ((budgetData.totalBilled as number) /
          (budgetData.contractValue as number)) *
        100
      : 0;
  const delayedPct =
    scheduleData && (scheduleData.totalCount as number) > 0
      ? ((scheduleData.delayedCount as number) /
          (scheduleData.totalCount as number)) *
        100
      : 0;

  const healthScore = computeHealthScore({
    budgetSpentPercent: clampBudgetPercent(budgetSpentPct),
    delayedMilestonePercent: delayedPct,
    criticalOpenIssues: 0,
  });

  // Step 7: Fetch company branding (D-59)
  const { branding, theme } = await getBrandingForPortal(
    portalConfig.org_id ?? "",
    portalConfig.id
  );

  // Step 8: Record analytics (D-102, D-114)
  const headersList = await headers();
  const ip = headersList.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "";
  const userAgent = headersList.get("user-agent") ?? "";

  // Fire-and-forget analytics insert
  recordPortalView({
    portalConfigId: portalConfig.id,
    linkId: link.id as string,
    ipHash: ip ? hashIP(ip) : undefined,
    userAgent: userAgent.slice(0, 256),
  }).catch((err: unknown) => {
    console.error("[PortalPage] analytics recording failed:", err);
  });

  // Step 9: Cache headers set via route segment config at bottom of file
  // D-20: public, s-maxage=60, stale-while-revalidate=300

  return (
    <PortalShell
      branding={branding}
      theme={theme}
      portalConfig={portalConfig}
      sections={sections}
      healthScore={healthScore}
      projectName={projectName}
      sectionOrder={SECTION_ORDER}
      showAmounts={showAmounts}
    />
  );
}

// ---------------------------------------------------------------------------
// Static sub-components for error states
// ---------------------------------------------------------------------------

function GenericNotFound() {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "100vh",
        padding: 32,
        fontFamily: "system-ui, sans-serif",
        background: "#F8F9FB",
        color: "#374151",
      }}
    >
      <div
        style={{
          fontSize: 64,
          fontWeight: 800,
          color: "#D1D5DB",
          marginBottom: 16,
        }}
      >
        404
      </div>
      <h1 style={{ fontSize: 20, fontWeight: 700, marginBottom: 8 }}>
        Page not found
      </h1>
      <p style={{ fontSize: 14, color: "#6B7280", textAlign: "center" }}>
        This link is invalid or has been removed.
      </p>
    </div>
  );
}

function RateLimitPage() {
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "100vh",
        padding: 32,
        fontFamily: "system-ui, sans-serif",
        background: "#F8F9FB",
        color: "#374151",
      }}
    >
      <div
        style={{
          fontSize: 48,
          fontWeight: 800,
          color: "#F59E0B",
          marginBottom: 16,
        }}
      >
        429
      </div>
      <h1 style={{ fontSize: 20, fontWeight: 700, marginBottom: 8 }}>
        Too many requests
      </h1>
      <p style={{ fontSize: 14, color: "#6B7280", textAlign: "center" }}>
        This portal has reached its daily view limit. Please try again tomorrow.
      </p>
    </div>
  );
}

// D-20: Cache-Control: public, s-maxage=60, stale-while-revalidate=300
// force-dynamic ensures SSR on each request; revalidate controls CDN edge cache
export const dynamic = "force-dynamic";
export const revalidate = 60;
