// D-77: Company logo (left) + project name (center) + section anchor nav + "Last updated [date]"
// D-2: Responsive -- on mobile (< 640px), hide section anchors
// D-16: aria-label on nav, role="navigation"

type PortalHeaderProps = {
  companyName: string;
  logoUrl?: string;
  projectName: string;
  sectionAnchors: { id: string; label: string }[];
  lastUpdated: string;
};

export default function PortalHeader({
  companyName,
  logoUrl,
  projectName,
  sectionAnchors,
  lastUpdated,
}: PortalHeaderProps) {
  // Static CSS for responsive behavior (no user input, safe to inline)
  const responsiveCSS = `@media (max-width: 639px) { .portal-section-nav { display: none !important; } }`;

  return (
    <header
      style={{
        padding: "16px 24px",
        borderBottom: "1px solid #E2E5E9",
        background: "var(--portal-card-bg, #FFFFFF)",
      }}
    >
      {/* Static responsive CSS -- hardcoded string, no user input */}
      <style dangerouslySetInnerHTML={{ __html: responsiveCSS }} />

      <div
        style={{
          maxWidth: 960,
          margin: "0 auto",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          flexWrap: "wrap",
          gap: 12,
        }}
      >
        {/* Company logo or name */}
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {logoUrl ? (
            <img
              src={logoUrl}
              alt={`${companyName} logo`}
              style={{ maxHeight: 40, width: "auto", objectFit: "contain" }}
            />
          ) : (
            companyName && (
              <span
                style={{
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--portal-primary, #1E3A5F)",
                }}
              >
                {companyName}
              </span>
            )
          )}
        </div>

        {/* Project name (center) */}
        <h1
          style={{
            fontSize: 18,
            fontWeight: 600,
            margin: 0,
            color: "var(--portal-text, #1F2937)",
            textAlign: "center",
            flex: "1 1 auto",
          }}
        >
          {projectName}
        </h1>

        {/* Last updated */}
        <div
          style={{
            fontSize: 12,
            color: "#9CA3AF",
            whiteSpace: "nowrap",
          }}
        >
          Last updated {lastUpdated}
        </div>
      </div>

      {/* Section anchor navigation -- hidden on mobile via CSS above */}
      {sectionAnchors.length > 0 && (
        <nav
          role="navigation"
          aria-label="Portal section navigation"
          style={{
            maxWidth: 960,
            margin: "12px auto 0",
            display: "flex",
            gap: 8,
            overflowX: "auto",
            paddingBottom: 4,
          }}
          className="portal-section-nav"
        >
          {sectionAnchors.map((anchor) => (
            <a
              key={anchor.id}
              href={`#section-${anchor.id}`}
              style={{
                fontSize: 13,
                fontWeight: 500,
                color: "var(--portal-primary, #2563EB)",
                textDecoration: "none",
                padding: "6px 12px",
                borderRadius: 6,
                whiteSpace: "nowrap",
                transition: "background 200ms ease-in-out",
              }}
            >
              {anchor.label}
            </a>
          ))}
        </nav>
      )}
    </header>
  );
}
