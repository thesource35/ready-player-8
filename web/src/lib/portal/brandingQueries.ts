// Company branding CRUD query helpers (D-73, D-74, D-59)
// Management operations use getAuthenticatedClient() (RLS-enforced)
// Public portal viewing uses service-role client (bypasses RLS)

import { createClient } from "@supabase/supabase-js";
import { getAuthenticatedClient } from "@/lib/supabase/fetch";
import { getSupabaseUrl, getSupabaseServerKey } from "@/lib/supabase/env";
import type { CompanyBranding, PortalThemeConfig, PortalAuditAction } from "./types";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type SupabaseAny = any;

// ---------------------------------------------------------------------------
// Service-role client for public portal access (bypasses RLS)
// ---------------------------------------------------------------------------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------------------------------------------------------------------------
// Audit logging helper (D-114)
// ---------------------------------------------------------------------------

async function logBrandingAudit(
  supabase: SupabaseAny,
  action: PortalAuditAction,
  metadata: Record<string, unknown>,
  options?: { userId?: string }
): Promise<void> {
  try {
    await supabase.from("cs_portal_audit_log").insert({
      user_id: options?.userId ?? null,
      action,
      metadata,
    });
  } catch (err) {
    console.error("[logBrandingAudit] Failed to write audit log:", err);
  }
}

// Default theme config when no branding exists
const DEFAULT_THEME: PortalThemeConfig = {
  primary: "#1E40AF",
  secondary: "#3B82F6",
  background: "#FFFFFF",
  text: "#1F2937",
  cardBg: "#F9FAFB",
  fontFamily: "Inter",
  borderRadius: 8,
  customCSS: null,
};

// ---------------------------------------------------------------------------
// getCompanyBranding — fetch branding for an org (D-73)
// ---------------------------------------------------------------------------

export async function getCompanyBranding(orgId: string): Promise<CompanyBranding | null> {
  // Use service-role client so this works for public portal rendering too
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[getCompanyBranding] Service client not available");
    return null;
  }

  try {
    const { data, error } = await supabase
      .from("cs_company_branding")
      .select("*")
      .eq("org_id", orgId)
      .maybeSingle();

    if (error) {
      console.error("[getCompanyBranding] fetch error:", error);
      return null;
    }

    return data as CompanyBranding | null;
  } catch (err) {
    console.error("[getCompanyBranding] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// upsertCompanyBranding — create or update branding (D-74)
// ---------------------------------------------------------------------------

export async function upsertCompanyBranding(
  orgId: string,
  userId: string,
  branding: Partial<Omit<CompanyBranding, "id" | "org_id" | "user_id" | "created_at" | "updated_at">>
): Promise<CompanyBranding | null> {
  const { supabase, user } = await getAuthenticatedClient();
  if (!supabase || !user) {
    console.error("[upsertCompanyBranding] Authentication required");
    return null;
  }

  try {
    const { data, error } = await supabase
      .from("cs_company_branding")
      .upsert(
        {
          org_id: orgId,
          user_id: userId,
          ...branding,
        },
        { onConflict: "org_id" }
      )
      .select()
      .single();

    if (error) {
      console.error("[upsertCompanyBranding] upsert error:", error);
      return null;
    }

    // Audit log
    await logBrandingAudit(supabase, "branding_updated", {
      org_id: orgId,
      updated_fields: Object.keys(branding),
    }, { userId });

    return data as CompanyBranding;
  } catch (err) {
    console.error("[upsertCompanyBranding] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// getPortalBrandingOverride — check portal config for theme override (D-59)
// ---------------------------------------------------------------------------

export async function getPortalBrandingOverride(
  configId: string
): Promise<Partial<PortalThemeConfig> | null> {
  const supabase = getServiceClient();
  if (!supabase) {
    console.error("[getPortalBrandingOverride] Service client not available");
    return null;
  }

  try {
    const { data, error } = await supabase
      .from("cs_portal_config")
      .select("sections_config")
      .eq("id", configId)
      .maybeSingle();

    if (error || !data) {
      if (error) console.error("[getPortalBrandingOverride] fetch error:", error);
      return null;
    }

    // Theme override stored in sections_config.theme_override
    const sectionsConfig = data.sections_config as Record<string, unknown> | null;
    if (!sectionsConfig || !sectionsConfig.theme_override) return null;

    return sectionsConfig.theme_override as Partial<PortalThemeConfig>;
  } catch (err) {
    console.error("[getPortalBrandingOverride] exception:", err);
    return null;
  }
}

// ---------------------------------------------------------------------------
// getBrandingForPortal — resolve final branding: company + override (D-59)
// ---------------------------------------------------------------------------

export async function getBrandingForPortal(
  orgId: string,
  configId: string
): Promise<{ branding: CompanyBranding | null; theme: PortalThemeConfig }> {
  try {
    // Fetch company branding (base)
    const companyBranding = await getCompanyBranding(orgId);

    // Fetch per-portal override
    const portalOverride = await getPortalBrandingOverride(configId);

    // Base theme: company branding theme_config or defaults
    const baseTheme: PortalThemeConfig = companyBranding?.theme_config
      ? { ...DEFAULT_THEME, ...companyBranding.theme_config }
      : { ...DEFAULT_THEME };

    // Merge portal-specific override on top (D-59: per-project overrides)
    const finalTheme: PortalThemeConfig = portalOverride
      ? { ...baseTheme, ...portalOverride }
      : baseTheme;

    return {
      branding: companyBranding,
      theme: finalTheme,
    };
  } catch (err) {
    console.error("[getBrandingForPortal] exception:", err);
    return {
      branding: null,
      theme: { ...DEFAULT_THEME },
    };
  }
}
