export default function HubPage() {
  const integrations = [
    { name: "Supabase", category: "Database & Auth", status: "CONNECTED", color: "var(--green)", desc: "Real-time database, authentication, and offline sync" },
    { name: "Firebase", category: "Push Notifications", status: "AVAILABLE", color: "var(--gold)", desc: "Push notifications and cloud messaging" },
    { name: "Outlook", category: "Email & Calendar", status: "AVAILABLE", color: "var(--cyan)", desc: "Mail, calendar, and field notifications" },
    { name: "QuickBooks", category: "Accounting", status: "AVAILABLE", color: "var(--green)", desc: "Invoices, billing, and accounting handoff" },
    { name: "Microsoft 365", category: "Productivity", status: "AVAILABLE", color: "var(--gold)", desc: "Excel, SharePoint, OneDrive, and docs" },
    { name: "Procore", category: "Project Management", status: "AVAILABLE", color: "var(--accent)", desc: "Bidirectional sync with Procore projects" },
    { name: "PlanGrid", category: "Field Docs", status: "AVAILABLE", color: "var(--cyan)", desc: "Drawing sets, RFIs, and field reports" },
    { name: "DocuSign", category: "E-Signatures", status: "AVAILABLE", color: "var(--purple)", desc: "Contract execution and lien waivers" },
  ];

  const apiKeys = [
    { name: "Supabase Base URL", key: "ConstructOS.Integrations.Backend.BaseURL", configured: true },
    { name: "Supabase API Key", key: "ConstructOS.Integrations.Backend.ApiKey", configured: true },
    { name: "Anthropic API Key", key: "ConstructOS.AngelicAI.APIKey", configured: true },
    { name: "Mapbox Token", key: "ConstructOS.Maps.MapboxToken", configured: false },
    { name: "Stripe Key", key: "ConstructOS.Pay.StripeKey", configured: false },
  ];

  const webhooks = [
    { event: "project.created", endpoint: "/api/webhooks/project", status: "ACTIVE", lastTriggered: "2 hours ago" },
    { event: "payment.received", endpoint: "/api/webhooks/payment", status: "ACTIVE", lastTriggered: "5 hours ago" },
    { event: "safety.incident", endpoint: "/api/webhooks/safety", status: "ACTIVE", lastTriggered: "3 days ago" },
    { event: "bid.submitted", endpoint: "/api/webhooks/bid", status: "PAUSED", lastTriggered: "1 week ago" },
  ];

  const roles = [
    { name: "FIELD", color: "var(--green)", desc: "Daily logs, timecards, safety reports" },
    { name: "PM", color: "var(--cyan)", desc: "RFIs, submittals, change orders, schedules" },
    { name: "ACCOUNTING", color: "var(--gold)", desc: "Pay apps, lien waivers, payroll, 1099s" },
    { name: "EXECUTIVE", color: "var(--accent)", desc: "Dashboards, P&L, pipeline, analytics" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--cyan)" }}>HUB</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Integration Hub</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Connect your tools, configure APIs, manage webhooks and role-based access</p>
      </div>

      {/* Role Presets */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)", marginBottom: 10 }}>ROLE-BASED ACCESS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 20 }}>
        {roles.map(r => (
          <div key={r.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, textAlign: "center", border: `1px solid ${r.color}30` }}>
            <div style={{ fontSize: 14, fontWeight: 900, color: r.color, marginBottom: 4 }}>{r.name}</div>
            <div style={{ fontSize: 9, color: "var(--muted)" }}>{r.desc}</div>
          </div>
        ))}
      </div>

      {/* Platform Integrations */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)", marginBottom: 10 }}>PLATFORM INTEGRATIONS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 10, marginBottom: 20 }}>
        {integrations.map(i => (
          <div key={i.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
              <span style={{ fontSize: 13, fontWeight: 800 }}>{i.name}</span>
              <span style={{ fontSize: 8, fontWeight: 900, color: i.status === "CONNECTED" ? "var(--green)" : "var(--muted)", background: i.status === "CONNECTED" ? "rgba(105,210,148,0.1)" : "rgba(158,189,194,0.1)", padding: "3px 8px", borderRadius: 4 }}>{i.status}</span>
            </div>
            <div style={{ fontSize: 9, fontWeight: 700, color: i.color, marginBottom: 4 }}>{i.category}</div>
            <p style={{ fontSize: 10, color: "var(--muted)", margin: 0 }}>{i.desc}</p>
            {i.status !== "CONNECTED" && (
              <a href="/login" style={{ marginTop: 8, background: i.color, color: "var(--bg)", border: "none", borderRadius: 6, padding: "5px 12px", fontSize: 9, fontWeight: 800, cursor: "pointer", textDecoration: "none", display: "inline-block" }}>CONNECT</a>
            )}
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* API Keys */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--purple)", marginBottom: 10 }}>API CONFIGURATION</h2>
          {apiKeys.map(k => (
            <div key={k.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700 }}>{k.name}</div>
                <div style={{ fontSize: 9, color: "var(--muted)", fontFamily: "monospace" }}>{k.key}</div>
              </div>
              <span style={{ fontSize: 8, fontWeight: 900, color: k.configured ? "var(--green)" : "var(--muted)" }}>{k.configured ? "SET" : "NOT SET"}</span>
            </div>
          ))}
        </div>

        {/* Webhooks */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)", marginBottom: 10 }}>WEBHOOKS</h2>
          {webhooks.map(w => (
            <div key={w.event} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 11, fontWeight: 700 }}>{w.event}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: w.status === "ACTIVE" ? "var(--green)" : "var(--gold)" }}>{w.status}</span>
              </div>
              <div style={{ fontSize: 9, color: "var(--muted)", fontFamily: "monospace", marginTop: 2 }}>{w.endpoint}</div>
              <div style={{ fontSize: 8, color: "var(--muted)", marginTop: 2 }}>Last: {w.lastTriggered}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
