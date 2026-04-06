export default function ElectricalPage() {
  const trades = [
    { name: "Electrician", icon: "⚡", color: "#FCC757" },
    { name: "Fiber Installer", icon: "🌐", color: "#4AC4CC" },
    { name: "Low Voltage", icon: "🔌", color: "#8A8FCC" },
    { name: "Solar Installer", icon: "☀️", color: "#F29E3D" },
    { name: "Generator Tech", icon: "🔋", color: "#69D294" },
    { name: "Fire Alarm", icon: "🚨", color: "#D94D48" },
  ];

  const contractors = [
    { name: "Mike Rodriguez", company: "Rodriguez Electric", trade: "Electrician", license: "ME-48291", state: "TX", verified: true, rating: 4.9, reviews: 127, rate: "$85/hr", experience: 18, available: true, certs: ["Master Electrician", "OSHA 30"], initials: "MR" },
    { name: "Sarah Chen", company: "FiberLink Pro", trade: "Fiber Installer", license: "FI-33892", state: "TX", verified: true, rating: 4.8, reviews: 94, rate: "$75/hr", experience: 12, available: true, certs: ["BICSI RCDD", "FOA CFOT"], initials: "SC" },
    { name: "James Wilson", company: "Wilson Low Voltage", trade: "Low Voltage", license: "LV-22145", state: "TX", verified: true, rating: 4.7, reviews: 68, rate: "$70/hr", experience: 15, available: false, certs: ["NICET Level III", "ESA NTS"], initials: "JW" },
    { name: "Ana Gutierrez", company: "SunPower Systems", trade: "Solar Installer", license: "SI-55672", state: "TX", verified: true, rating: 4.9, reviews: 156, rate: "$80/hr", experience: 10, available: true, certs: ["NABCEP PV", "OSHA 10"], initials: "AG" },
    { name: "David Park", company: "GenTech Solutions", trade: "Generator Tech", license: "GT-18834", state: "TX", verified: true, rating: 4.6, reviews: 42, rate: "$90/hr", experience: 20, available: true, certs: ["Generac Certified", "Kohler Dealer"], initials: "DP" },
    { name: "Tom Bradley", company: "FireSafe Systems", trade: "Fire Alarm", license: "FA-77123", state: "TX", verified: true, rating: 4.8, reviews: 83, rate: "$85/hr", experience: 14, available: true, certs: ["NICET Fire Alarm III", "EST Certified"], initials: "TB" },
  ];

  const leads = [
    { title: "Panel Upgrade — 200A to 400A", trade: "Electrician", location: "Katy, TX", budget: "$8,500-$12,000", urgency: "HIGH", bids: 4 },
    { title: "Fiber to the Home — 48 Units", trade: "Fiber Installer", location: "Sugar Land, TX", budget: "$45,000-$62,000", urgency: "MEDIUM", bids: 2 },
    { title: "Solar Array — 25kW Commercial", trade: "Solar Installer", location: "Houston, TX", budget: "$52,000-$68,000", urgency: "LOW", bids: 6 },
    { title: "Fire Alarm Retrofit — 12 Floors", trade: "Fire Alarm", location: "Downtown Houston", budget: "$28,000-$35,000", urgency: "HIGH", bids: 1 },
  ];

  const fiberProjects = [
    { name: "Riverside Lofts FTTH", isp: "AT&T Fiber", units: 48, status: "IN PROGRESS", completion: 65 },
    { name: "Harbor Crossing MDU", isp: "Comcast", units: 120, status: "BIDDING", completion: 0 },
    { name: "Pine Ridge Data Network", isp: "Spectrum Enterprise", units: 24, status: "COMPLETE", completion: 100 },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(252,199,87,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)" }}>ELECTRIC</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Electrical & Fiber Hub</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Licensed contractors, leads, fiber projects, and emergency services</p>
      </div>

      {/* Trade Categories */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(6, 1fr)", gap: 8, marginBottom: 20 }}>
        {trades.map(t => (
          <div key={t.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, textAlign: "center", cursor: "pointer" }}>
            <div style={{ fontSize: 24 }}>{t.icon}</div>
            <div style={{ fontSize: 9, fontWeight: 800, color: t.color, marginTop: 4 }}>{t.name}</div>
          </div>
        ))}
      </div>

      {/* Contractor Cards */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>VERIFIED CONTRACTORS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(350px, 1fr))", gap: 10, marginBottom: 20 }}>
        {contractors.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 8 }}>
              <div style={{ width: 40, height: 40, borderRadius: "50%", background: "linear-gradient(135deg, var(--accent), var(--gold))", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14, fontWeight: 900, color: "var(--bg)" }}>{c.initials}</div>
              <div style={{ flex: 1 }}>
                <div style={{ display: "flex", justifyContent: "space-between" }}>
                  <span style={{ fontSize: 12, fontWeight: 800 }}>{c.name}</span>
                  <span role="status" aria-label={`Status: ${c.available ? "Available" : "Busy"}`} style={{ fontSize: 8, fontWeight: 900, color: c.available ? "var(--green)" : "var(--muted)" }}>{c.available ? "AVAILABLE" : "BUSY"}</span>
                </div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>{c.company} &bull; {c.trade}</div>
              </div>
            </div>
            <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginBottom: 6 }}>
              <span>★ {c.rating} ({c.reviews})</span><span>{c.rate}</span><span>{c.experience} yrs</span><span>{c.state} #{c.license}</span>
            </div>
            <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
              {c.certs.map(cert => (
                <span key={cert} style={{ fontSize: 8, padding: "2px 6px", borderRadius: 3, background: "rgba(74,196,204,0.08)", color: "var(--cyan)" }}>{cert}</span>
              ))}
              {c.verified && <span style={{ fontSize: 8, padding: "2px 6px", borderRadius: 3, background: "rgba(105,210,148,0.1)", color: "var(--green)" }}>✓ VERIFIED</span>}
            </div>
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Leads */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>ACTIVE LEADS</h2>
          {leads.map(l => (
            <div key={l.title} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                <span style={{ fontSize: 11, fontWeight: 800 }}>{l.title}</span>
                <span role="status" aria-label={`Urgency: ${l.urgency}`} style={{ fontSize: 8, fontWeight: 900, color: l.urgency === "HIGH" ? "var(--red)" : l.urgency === "MEDIUM" ? "var(--gold)" : "var(--green)" }}>{l.urgency}</span>
              </div>
              <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)" }}>
                <span>{l.trade}</span><span>{l.location}</span><span style={{ color: "var(--gold)" }}>{l.budget}</span><span>{l.bids} bids</span>
              </div>
            </div>
          ))}
        </div>

        {/* Fiber Projects */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>FIBER PROJECTS</h2>
          {fiberProjects.map(f => (
            <div key={f.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                <span style={{ fontSize: 11, fontWeight: 800 }}>{f.name}</span>
                <span role="status" aria-label={`Status: ${f.status}`} style={{ fontSize: 8, fontWeight: 900, color: f.status === "COMPLETE" ? "var(--green)" : f.status === "IN PROGRESS" ? "var(--cyan)" : "var(--gold)" }}>{f.status}</span>
              </div>
              <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)" }}>
                <span>{f.isp}</span><span>{f.units} units</span>
              </div>
              {f.completion > 0 && f.completion < 100 && (
                <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 4, marginTop: 6 }}>
                  <div style={{ background: "var(--cyan)", borderRadius: 3, height: 4, width: `${f.completion}%` }} />
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
