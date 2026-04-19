"use client";
// D-77: Company logo (left) + project name (center) + section anchor nav + "Last updated [date]"
// D-2: Responsive -- on mobile (< 640px), hide section anchors
// D-16: aria-label on nav, role="navigation"
// D-01..D-07, D-23, D-24, D-26 (Phase 27): Map anchor (last on home) + Overview anchor (first on /map) gated by showMapLink

import Link from "next/link";
import { usePathname } from "next/navigation";

type PortalHeaderProps = {
  companyName: string;
  logoUrl?: string;
  projectName: string;
  sectionAnchors: { id: string; label: string }[];
  lastUpdated: string;
  // Phase 27 D-19 -- required, single source of truth for desktop + mobile.
  // Server-computed in portal page.tsx and threaded through PortalShell.
  showMapLink: boolean;
};

// Shared anchor style used by section anchors AND the Map/Overview links
// so visual parity (D-02, D-24) is preserved in one place.
const ANCHOR_STYLE = {
  fontSize: 13,
  fontWeight: 500,
  color: "var(--portal-primary, #2563EB)",
  textDecoration: "none",
  padding: "6px 12px",
  borderRadius: 6,
  whiteSpace: "nowrap" as const,
  transition: "background 200ms ease-in-out",
};

export default function PortalHeader({
  companyName,
  logoUrl,
  projectName,
  sectionAnchors,
  lastUpdated,
  showMapLink,
}: PortalHeaderProps) {
  // Static CSS for responsive behavior (no user input, safe to inline)
  const responsiveCSS = `@media (max-width: 639px) { .portal-section-nav { display: none !important; } }`;

  // Route awareness (D-06 LOCKED): client-side pathname read drives which of
  // {Map, Overview} renders. On /map we show Overview (return to portal home);
  // on portal home we show Map (navigate to /map).
  const pathname = usePathname() ?? "";
  const isOnMap = pathname.endsWith("/map");

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

      {/* Section anchor navigation -- hidden on mobile via CSS above.
          D-07: render when showMapLink is true even if sectionAnchors is empty. */}
      {(sectionAnchors.length > 0 || showMapLink) && (
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
          {/* Overview anchor -- FIRST when on /map (D-05, D-26) */}
          {showMapLink && isOnMap && (
            <Link
              key="overview-return"
              href=".."
              prefetch={true}
              style={ANCHOR_STYLE}
            >Overview</Link>
          )}

          {/* Existing in-page section anchors -- unchanged */}
          {sectionAnchors.map((anchor) => (
            <a
              key={anchor.id}
              href={`#section-${anchor.id}`}
              style={ANCHOR_STYLE}
            >
              {anchor.label}
            </a>
          ))}

          {/* Map anchor -- LAST when on portal home (D-03, D-04, D-23, D-24) */}
          {showMapLink && !isOnMap && (
            <Link
              key="map-link"
              href="./map"
              prefetch={true}
              style={ANCHOR_STYLE}
            >Map</Link>
          )}
        </nav>
      )}
    </header>
  );
}
