export default function MarketPage() {
  const regions = ["All", "Northeast", "Southeast", "Midwest", "West", "International"];

  const marketData = [
    { city: "Houston", state: "TX", vacancyRate: 4.2, newPermits: 342, avgPSF: 185, trend: "+8%", hotSectors: ["Healthcare", "Industrial", "Multi-Family"], region: "Southeast" },
    { city: "Dallas", state: "TX", vacancyRate: 5.1, newPermits: 289, avgPSF: 165, trend: "+6%", hotSectors: ["Data Centers", "Logistics", "Office"], region: "Southeast" },
    { city: "Miami", state: "FL", vacancyRate: 3.8, newPermits: 198, avgPSF: 245, trend: "+12%", hotSectors: ["Luxury Residential", "Hospitality", "Mixed-Use"], region: "Southeast" },
    { city: "Denver", state: "CO", vacancyRate: 6.4, newPermits: 156, avgPSF: 178, trend: "+3%", hotSectors: ["Renewable Energy", "Tech Office", "Mountain Resort"], region: "West" },
    { city: "Chicago", state: "IL", vacancyRate: 7.2, newPermits: 234, avgPSF: 195, trend: "-2%", hotSectors: ["Infrastructure", "Adaptive Reuse", "Healthcare"], region: "Midwest" },
    { city: "Phoenix", state: "AZ", vacancyRate: 3.5, newPermits: 312, avgPSF: 155, trend: "+15%", hotSectors: ["Data Centers", "Semiconductor Fab", "Residential"], region: "West" },
    { city: "New York", state: "NY", vacancyRate: 8.1, newPermits: 445, avgPSF: 385, trend: "+1%", hotSectors: ["Life Sciences", "Affordable Housing", "Office-to-Residential"], region: "Northeast" },
    { city: "Atlanta", state: "GA", vacancyRate: 5.5, newPermits: 267, avgPSF: 162, trend: "+7%", hotSectors: ["Film Studios", "Logistics", "Mixed-Use"], region: "Southeast" },
  ];

  const openBids = [
    { title: "Houston Medical Complex", score: 94, value: "$18.2M", sector: "Healthcare" },
    { title: "DFW Airport Terminal C", score: 88, value: "$45.0M", sector: "Aviation" },
    { title: "Baytown Refinery Expansion", score: 82, value: "$12.5M", sector: "Industrial" },
  ];

  const insights = [
    { title: "Phoenix leads nation in permit growth", detail: "15% YoY increase driven by semiconductor and data center construction", impact: "HIGH" },
    { title: "NYC office-to-residential conversions accelerating", detail: "Tax incentive program driving adaptive reuse projects above 50th St", impact: "MEDIUM" },
    { title: "Southeast labor costs rising 8-12%", detail: "Skilled trade shortage pushing wages up across FL, TX, GA markets", impact: "HIGH" },
    { title: "Material prices stabilizing", detail: "Steel and lumber returning to pre-2024 levels. Concrete steady.", impact: "LOW" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--cyan)" }}>MARKET</div>
            <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Market Intelligence</h1>
            <p style={{ fontSize: 12, color: "var(--muted)" }}>Live vacancy, new business, and bid opportunities</p>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ textAlign: "center", padding: "6px 12px", background: "rgba(252,199,87,0.1)", borderRadius: 8 }}>
              <div style={{ fontSize: 18, fontWeight: 900, color: "var(--gold)" }}>{openBids.length}</div>
              <div style={{ fontSize: 7, fontWeight: 800, color: "var(--muted)" }}>OPEN BIDS</div>
            </div>
            <div style={{ textAlign: "center", padding: "6px 12px", background: "rgba(74,196,204,0.1)", borderRadius: 8 }}>
              <div style={{ fontSize: 18, fontWeight: 900, color: "var(--cyan)" }}>{marketData.length}</div>
              <div style={{ fontSize: 7, fontWeight: 800, color: "var(--muted)" }}>MARKETS</div>
            </div>
          </div>
        </div>
      </div>

      {/* Region Filter */}
      <div style={{ display: "flex", gap: 6, marginBottom: 16, flexWrap: "wrap" }}>
        {regions.map(r => (
          <span key={r} style={{ fontSize: 10, fontWeight: 700, padding: "5px 12px", borderRadius: 6, background: r === "All" ? "var(--cyan)" : "var(--surface)", color: r === "All" ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{r}</span>
        ))}
      </div>

      {/* Market Data Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 10, marginBottom: 20 }}>
        {marketData.map(m => (
          <div key={m.city} style={{ background: "var(--surface)", borderRadius: 12, padding: 14, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
              <h3 style={{ fontSize: 14, fontWeight: 800, margin: 0 }}>{m.city}, {m.state}</h3>
              <span style={{ fontSize: 12, fontWeight: 900, color: m.trend.startsWith("+") ? "var(--green)" : "var(--red)" }}>{m.trend}</span>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6, marginBottom: 8 }}>
              <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--accent)" }}>{m.vacancyRate}%</div><div style={{ fontSize: 7, color: "var(--muted)" }}>VACANCY</div></div>
              <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--cyan)" }}>{m.newPermits}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>PERMITS</div></div>
              <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--gold)" }}>${m.avgPSF}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>AVG PSF</div></div>
            </div>
            <div style={{ display: "flex", gap: 4, flexWrap: "wrap" }}>
              {m.hotSectors.map(s => (
                <span key={s} style={{ fontSize: 8, fontWeight: 700, padding: "2px 6px", borderRadius: 3, background: "rgba(74,196,204,0.08)", color: "var(--cyan)" }}>{s}</span>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Open Bids */}
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)", marginBottom: 10 }}>OPEN BID OPPORTUNITIES</h2>
        {openBids.map(b => (
          <div key={b.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <span style={{ fontSize: 12, fontWeight: 800 }}>{b.title}</span>
              <span style={{ fontSize: 10, color: "var(--muted)", marginLeft: 8 }}>{b.sector}</span>
            </div>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <span style={{ fontSize: 14, fontWeight: 900, color: "var(--gold)" }}>{b.value}</span>
              <span style={{ fontSize: 14, fontWeight: 900, color: "var(--green)" }}>{b.score}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Insights */}
      <div>
        <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)", marginBottom: 10 }}>MARKET INSIGHTS</h2>
        {insights.map(i => (
          <div key={i.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h4 style={{ fontSize: 12, fontWeight: 800, margin: 0 }}>{i.title}</h4>
              <span style={{ fontSize: 8, fontWeight: 900, color: i.impact === "HIGH" ? "var(--red)" : i.impact === "MEDIUM" ? "var(--gold)" : "var(--green)" }}>{i.impact}</span>
            </div>
            <p style={{ fontSize: 10, color: "var(--muted)", margin: "4px 0 0" }}>{i.detail}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
