// D-78: Contact info (if provided) + optional "Powered by ConstructionOS" (D-19) + legal links
// D-121: "Report this page" link for abuse reporting

type PortalFooterProps = {
  contactInfo?: {
    email?: string;
    phone?: string;
    website?: string;
    address?: string;
  };
  poweredByEnabled: boolean;
  reportAbuseUrl: string;
};

export default function PortalFooter({
  contactInfo,
  poweredByEnabled,
  reportAbuseUrl,
}: PortalFooterProps) {
  const hasContact =
    contactInfo &&
    (contactInfo.email ||
      contactInfo.phone ||
      contactInfo.website ||
      contactInfo.address);

  return (
    <footer
      style={{
        borderTop: "1px solid #E2E5E9",
        padding: "32px 24px",
        background: "#FFFFFF",
        marginTop: 48,
      }}
    >
      <div
        style={{
          maxWidth: 960,
          margin: "0 auto",
        }}
      >
        {/* Contact info */}
        {hasContact && (
          <div
            style={{
              marginBottom: 24,
              display: "flex",
              flexWrap: "wrap",
              gap: 24,
              fontSize: 13,
              color: "#6B7280",
            }}
          >
            {contactInfo.email && (
              <a
                href={`mailto:${contactInfo.email}`}
                style={{ color: "var(--portal-primary, #2563EB)", textDecoration: "none" }}
              >
                {contactInfo.email}
              </a>
            )}
            {contactInfo.phone && <span>{contactInfo.phone}</span>}
            {contactInfo.website && (
              <a
                href={contactInfo.website}
                target="_blank"
                rel="noopener noreferrer"
                style={{ color: "var(--portal-primary, #2563EB)", textDecoration: "none" }}
              >
                {contactInfo.website}
              </a>
            )}
            {contactInfo.address && <span>{contactInfo.address}</span>}
          </div>
        )}

        {/* Bottom row: powered by + legal links */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            flexWrap: "wrap",
            gap: 16,
            fontSize: 12,
            color: "#9CA3AF",
          }}
        >
          <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
            {poweredByEnabled && (
              <span>
                Powered by{" "}
                <a
                  href="https://constructionos.world"
                  target="_blank"
                  rel="noopener noreferrer"
                  style={{
                    color: "var(--portal-primary, #2563EB)",
                    textDecoration: "none",
                    fontWeight: 500,
                  }}
                >
                  ConstructionOS
                </a>
              </span>
            )}
          </div>

          <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
            <a
              href="/privacy"
              style={{ color: "#9CA3AF", textDecoration: "none" }}
            >
              Privacy
            </a>
            <a
              href="/terms"
              style={{ color: "#9CA3AF", textDecoration: "none" }}
            >
              Terms
            </a>
            <a
              href={reportAbuseUrl}
              style={{ color: "#9CA3AF", textDecoration: "none" }}
            >
              Report this page
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
