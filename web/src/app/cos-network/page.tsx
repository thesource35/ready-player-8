export default function COSNetworkPage() {
  const networkStats = [
    { val: "Growing", label: "MEMBERS", color: "var(--accent)" },
    { val: "8,420", label: "COMPANIES", color: "var(--cyan)" },
    { val: "25", label: "TRADES", color: "var(--gold)" },
    { val: "48", label: "COUNTRIES", color: "var(--green)" },
  ];

  const features = [
    { name: "Social Feed", icon: "📱", desc: "Project updates, industry news, and professional networking", link: "/feed" },
    { name: "Stories", icon: "📸", desc: "24-hour jobsite stories with photos and quick updates", link: "/feed" },
    { name: "Direct Messages", icon: "💬", desc: "Encrypted messaging between construction professionals", link: "/feed" },
    { name: "Job Board", icon: "💼", desc: "Post and find construction jobs across all trades", link: "/feed" },
    { name: "Equipment Marketplace", icon: "🏗", desc: "Buy, sell, and rent equipment from the network", link: "/rentals" },
    { name: "Company Pages", icon: "🏢", desc: "Verified company profiles with portfolio and reviews", link: "/contractors" },
  ];

  const verificationTiers = [
    { tier: "Identity Verified", price: "FREE", icon: "✅", color: "var(--green)", features: ["Email & phone verified", "Basic profile badge", "Access to public feed", "View job listings"] },
    { tier: "Licensed Professional", price: "$27.99/mo", icon: "🏆", color: "var(--gold)", features: ["State license verification", "Gold verification badge", "Priority in search results", "Bid on projects", "Post job listings"] },
    { tier: "Verified Company", price: "$49.99/mo", icon: "🏢", color: "var(--cyan)", features: ["Business license verified", "Company page with portfolio", "Unlimited job postings", "Equipment marketplace access", "Analytics dashboard", "API access"] },
  ];

  const tradeRequirements = [
    { trade: "General Contractor", states: 50, licenseType: "Contractor License", avgProcessing: "2-5 days" },
    { trade: "Electrician", states: 50, licenseType: "Electrical License", avgProcessing: "1-3 days" },
    { trade: "Plumber", states: 48, licenseType: "Plumbing License", avgProcessing: "1-3 days" },
    { trade: "HVAC Technician", states: 45, licenseType: "HVAC License", avgProcessing: "2-4 days" },
    { trade: "Structural Engineer", states: 50, licenseType: "PE License", avgProcessing: "3-7 days" },
    { trade: "Architect", states: 50, licenseType: "Architecture License", avgProcessing: "3-7 days" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>COS NETWORK</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>ConstructionOS Network</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>The professional network for the $13 trillion construction industry</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 20 }}>
        {networkStats.map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 16, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Network Features */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>NETWORK FEATURES</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 10, marginBottom: 24 }}>
        {features.map(f => (
          <a key={f.name} href={f.link} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, textAlign: "center", textDecoration: "none", color: "inherit", display: "block" }}>
            <div style={{ fontSize: 28, marginBottom: 6 }}>{f.icon}</div>
            <div style={{ fontSize: 11, fontWeight: 800, marginBottom: 4 }}>{f.name}</div>
            <div style={{ fontSize: 9, color: "var(--muted)" }}>{f.desc}</div>
          </a>
        ))}
      </div>

      {/* Verification Tiers */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>3-TIER VERIFICATION SYSTEM</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12, marginBottom: 24 }}>
        {verificationTiers.map(t => (
          <div key={t.tier} style={{ background: "var(--surface)", borderRadius: 12, padding: 18, border: `1px solid ${t.color}30` }}>
            <div style={{ fontSize: 32, textAlign: "center", marginBottom: 8 }}>{t.icon}</div>
            <h3 style={{ fontSize: 14, fontWeight: 800, color: t.color, textAlign: "center", marginBottom: 4 }}>{t.tier}</h3>
            <div style={{ fontSize: 20, fontWeight: 900, textAlign: "center", marginBottom: 12 }}>{t.price}</div>
            {t.features.map(f => (
              <div key={f} style={{ fontSize: 10, color: "var(--muted)", padding: "3px 0", paddingLeft: 12, borderLeft: `2px solid ${t.color}50` }}>{f}</div>
            ))}
          </div>
        ))}
      </div>

      <div style={{ textAlign: "center", marginBottom: 20 }}>
        <a href="/verify" style={{ display: "inline-block", padding: "14px 32px", borderRadius: 12, fontSize: 14, fontWeight: 800, color: "#080E12", background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>GET VERIFIED NOW</a>
      </div>

      {/* License Verification */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 10 }}>LICENSE VERIFICATION BY TRADE</h2>
      <div style={{ background: "var(--surface)", borderRadius: 10, overflow: "hidden" }}>
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 2fr 1fr", padding: "8px 12px", fontSize: 8, fontWeight: 800, color: "var(--muted)", letterSpacing: 1, borderBottom: "1px solid var(--border)" }}>
          <span>TRADE</span><span>STATES</span><span>LICENSE TYPE</span><span>PROCESSING</span>
        </div>
        {tradeRequirements.map(t => (
          <div key={t.trade} style={{ display: "grid", gridTemplateColumns: "2fr 1fr 2fr 1fr", padding: "10px 12px", fontSize: 10, alignItems: "center", borderBottom: "1px solid rgba(51,84,94,0.15)" }}>
            <span style={{ fontWeight: 700 }}>{t.trade}</span>
            <span style={{ color: "var(--cyan)" }}>{t.states}</span>
            <span style={{ color: "var(--muted)" }}>{t.licenseType}</span>
            <span style={{ color: "var(--gold)" }}>{t.avgProcessing}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
