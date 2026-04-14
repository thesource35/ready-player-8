// D-15: Expired pages show company branding + "Contact [company] for a new link"
// D-69: Expired pages show company branding colors
// Generic "Page not found" for completely invalid tokens

type ExpiredPageProps = {
  companyName?: string;
  logoUrl?: string;
  isExpired: boolean;
};

export default function ExpiredPage({
  companyName,
  logoUrl,
  isExpired,
}: ExpiredPageProps) {
  // D-15: If expired + branding available: show company logo + friendly message
  // If no branding: generic "Page not found"
  const hasBranding = !!(companyName || logoUrl);

  if (hasBranding) {
    return (
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "100vh",
          padding: 32,
          fontFamily: "var(--portal-font-family, Inter, system-ui, sans-serif)",
          background: "var(--portal-bg, #F8F9FB)",
          color: "var(--portal-text, #374151)",
        }}
      >
        {/* Company logo */}
        {logoUrl && (
          <img
            src={logoUrl}
            alt={`${companyName ?? "Company"} logo`}
            style={{
              maxHeight: 48,
              width: "auto",
              objectFit: "contain",
              marginBottom: 32,
            }}
          />
        )}

        <div
          style={{
            width: 64,
            height: 64,
            borderRadius: 32,
            background: "#FEF2F2",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            marginBottom: 24,
          }}
        >
          <svg
            width="28"
            height="28"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#DC2626"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="12" cy="12" r="10" />
            <polyline points="12 6 12 12 16 14" />
          </svg>
        </div>

        <h1
          style={{
            fontSize: 22,
            fontWeight: 700,
            marginBottom: 8,
            color: "#111827",
            textAlign: "center",
          }}
        >
          This project link has expired
        </h1>

        <p
          style={{
            fontSize: 14,
            color: "#6B7280",
            textAlign: "center",
            maxWidth: 400,
            lineHeight: 1.5,
          }}
        >
          {companyName
            ? `Contact ${companyName} for a new link to view this project.`
            : "Contact the project owner for a new link."}
        </p>
      </div>
    );
  }

  // Generic not found (D-15 fallback for invalid tokens)
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        minHeight: "100vh",
        padding: 32,
        fontFamily: "Inter, system-ui, sans-serif",
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
      <h1
        style={{
          fontSize: 20,
          fontWeight: 700,
          marginBottom: 8,
          color: "#111827",
        }}
      >
        Page not found
      </h1>
      <p
        style={{
          fontSize: 14,
          color: "#6B7280",
          textAlign: "center",
        }}
      >
        This link is invalid or has been removed.
      </p>
    </div>
  );
}
