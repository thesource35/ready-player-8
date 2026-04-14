import type {
  CompanyBranding,
  PortalConfig,
  PortalThemeConfig,
  PortalSectionKey,
} from "@/lib/portal/types";
import type { HealthScore } from "@/lib/reports/types";
import PortalHeader from "./PortalHeader";
import PortalFooter from "./PortalFooter";
import HealthBadge from "./HealthBadge";
import BudgetSection from "./BudgetSection";
import ScheduleSection from "./ScheduleSection";
import ChangeOrdersSection from "./ChangeOrdersSection";
import DocumentsSection from "./DocumentsSection";
import CookieConsent from "./CookieConsent";

// Server component wrapper that applies branding via CSS custom properties
// D-32: Sections render in fixed SECTION_ORDER
// D-44: Auto-hide empty sections
// D-70: Welcome message at top if set
// Note: custom_css is pre-sanitized at save time via cssSanitizer.ts (T-20-10)

type PortalShellProps = {
  branding: CompanyBranding | null;
  theme: PortalThemeConfig;
  portalConfig: PortalConfig;
  sections: Record<string, unknown>;
  healthScore: HealthScore;
  projectName: string;
  sectionOrder: PortalSectionKey[];
  showAmounts: boolean;
};

const SECTION_LABELS: Record<PortalSectionKey, string> = {
  schedule: "Schedule",
  budget: "Budget",
  photos: "Photos",
  change_orders: "Change Orders",
  documents: "Documents",
};

export default function PortalShell({
  branding,
  theme,
  portalConfig,
  sections,
  healthScore,
  projectName,
  sectionOrder,
  showAmounts,
}: PortalShellProps) {
  // Build section anchors for sections that have data
  const activeSections = sectionOrder.filter((key) => {
    const data = sections[key];
    if (data == null) return false;
    if (Array.isArray(data) && data.length === 0) return false;
    return true;
  });

  const sectionAnchors = activeSections.map((key) => ({
    id: key,
    label: SECTION_LABELS[key] ?? key,
  }));

  const companyName = branding?.company_name ?? "";
  const logoUrl = branding?.logo_light_path ?? undefined;
  const lastUpdated = new Date().toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  // Custom CSS is pre-sanitized at save time via cssSanitizer.ts (T-20-10)
  // The sanitizer strips dangerous properties (expressions, javascript: URLs)
  // and only allows safe visual properties from a 30+ property whitelist
  const customCSS = branding?.custom_css ?? theme.customCSS ?? null;

  return (
    <div
      style={{
        // Apply branding as CSS custom properties
        ["--portal-primary" as string]: theme.primary,
        ["--portal-secondary" as string]: theme.secondary ?? theme.primary,
        ["--portal-bg" as string]: theme.background,
        ["--portal-text" as string]: theme.text,
        ["--portal-card-bg" as string]: theme.cardBg,
        ["--portal-font-family" as string]: `${theme.fontFamily}, system-ui, -apple-system, sans-serif`,
        ["--portal-radius" as string]: `${theme.borderRadius}px`,
        background: theme.background,
        color: theme.text,
        fontFamily: `${theme.fontFamily}, system-ui, -apple-system, sans-serif`,
        minHeight: "100vh",
      }}
    >
      {/* Render pre-sanitized custom CSS (T-20-10: sanitized on save) */}
      {customCSS && (
        <style
          dangerouslySetInnerHTML={{ __html: customCSS }}
        />
      )}

      {/* D-62: Hero banner if cover_image_path exists */}
      {branding?.cover_image_path && (
        <div
          style={{
            width: "100%",
            height: 200,
            backgroundImage: `url(${branding.cover_image_path})`,
            backgroundSize: "cover",
            backgroundPosition: "center",
          }}
        />
      )}

      <PortalHeader
        companyName={companyName}
        logoUrl={logoUrl}
        projectName={projectName}
        sectionAnchors={sectionAnchors}
        lastUpdated={lastUpdated}
      />

      <main
        style={{
          maxWidth: 960,
          margin: "0 auto",
          padding: "24px 16px",
        }}
      >
        {/* D-70: Welcome message */}
        {portalConfig.welcome_message && (
          <div
            style={{
              padding: 16,
              marginBottom: 24,
              background: theme.cardBg,
              borderRadius: theme.borderRadius,
              border: `1px solid ${theme.primary}20`,
              fontSize: 14,
              lineHeight: 1.5,
            }}
          >
            {portalConfig.welcome_message}
          </div>
        )}

        {/* D-29: Health badge always visible */}
        <HealthBadge score={healthScore.score} />

        {/* D-32: Sections in fixed order, D-44: auto-hide empty */}
        {sectionOrder.map((key) => {
          const data = sections[key];
          if (data == null) return null;
          if (Array.isArray(data) && data.length === 0) return null;

          const sectionNote = portalConfig.section_notes?.[key] ?? undefined;

          switch (key) {
            case "schedule":
              return (
                <ScheduleSection
                  key={key}
                  schedule={data as Record<string, unknown>}
                  sectionNote={sectionNote}
                />
              );
            case "budget":
              return (
                <BudgetSection
                  key={key}
                  budget={data as Record<string, unknown>}
                  showExactAmounts={showAmounts}
                  sectionNote={sectionNote}
                />
              );
            case "photos":
              return (
                <div
                  key={key}
                  id="section-photos"
                  style={{
                    marginBottom: 24,
                    padding: 20,
                    background: "var(--portal-card-bg, #FFFFFF)",
                    borderRadius: "var(--portal-radius, 8px)",
                    border: "1px solid #E2E5E9",
                  }}
                >
                  <h2
                    style={{
                      fontSize: 16,
                      fontWeight: 600,
                      marginBottom: 16,
                    }}
                  >
                    Photos ({(data as unknown[]).length})
                  </h2>
                  {sectionNote && (
                    <p
                      style={{
                        fontSize: 13,
                        color: "#6B7280",
                        marginBottom: 12,
                      }}
                    >
                      {sectionNote}
                    </p>
                  )}
                  <div
                    style={{
                      display: "grid",
                      gridTemplateColumns:
                        "repeat(auto-fill, minmax(200px, 1fr))",
                      gap: 12,
                    }}
                  >
                    {(data as Record<string, unknown>[])
                      .slice(0, 20)
                      .map((photo, i) => (
                        <div
                          key={(photo.id as string) ?? i}
                          style={{
                            borderRadius: 8,
                            overflow: "hidden",
                            border: "1px solid #E2E5E9",
                          }}
                        >
                          <div
                            style={{
                              width: "100%",
                              paddingBottom: "75%",
                              background: "#F1F3F5",
                              position: "relative",
                            }}
                          >
                            {Boolean(photo.file_path) && (
                              <img
                                src={photo.file_path as string}
                                alt={
                                  (photo.caption as string) ?? "Project photo"
                                }
                                style={{
                                  position: "absolute",
                                  top: 0,
                                  left: 0,
                                  width: "100%",
                                  height: "100%",
                                  objectFit: "cover",
                                }}
                                loading="lazy"
                              />
                            )}
                          </div>
                          {Boolean(photo.caption) && (
                            <div
                              style={{
                                padding: 8,
                                fontSize: 12,
                                color: "#374151",
                              }}
                            >
                              {photo.caption as string}
                            </div>
                          )}
                        </div>
                      ))}
                  </div>
                </div>
              );
            case "change_orders":
              return (
                <ChangeOrdersSection
                  key={key}
                  changeOrders={data as Record<string, unknown>[]}
                  showAmounts={showAmounts}
                  sectionNote={sectionNote}
                />
              );
            case "documents":
              return (
                <DocumentsSection
                  key={key}
                  documents={data as Record<string, unknown>[]}
                  sectionNote={sectionNote}
                />
              );
            default:
              return null;
          }
        })}
      </main>

      <PortalFooter
        contactInfo={branding?.contact_info ?? undefined}
        poweredByEnabled={portalConfig.powered_by_enabled}
        reportAbuseUrl={`mailto:abuse@constructionos.com?subject=Report portal: ${portalConfig.slug}`}
      />

      <CookieConsent />
    </div>
  );
}
