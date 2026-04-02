export default function EmpirePage() {
  const divisions = [
    { name: "ConstructionOS Pay", icon: "💵", desc: "Payment processing for the construction industry", stats: { volume: "$4.2M", transactions: "342", fee: "1.5%" }, color: "var(--green)" },
    { name: "ConstructionOS Capital", icon: "🏦", desc: "Invoice factoring and credit lines for contractors", stats: { creditLine: "$500K", available: "$347K", outstanding: "$153K" }, color: "var(--accent)" },
    { name: "ConstructionOS Insurance", icon: "🛡", desc: "GL, Workers Comp, Builder's Risk, and bonds", stats: { policies: "4", coverage: "$5M", premium: "$24K/yr" }, color: "var(--cyan)" },
    { name: "ConstructionOS Workforce", icon: "👥", desc: "Payroll, benefits, and compliance for construction crews", stats: { employees: "85", payroll: "$298K/mo", states: "3" }, color: "var(--gold)" },
    { name: "ConstructionOS Supply Chain", icon: "📦", desc: "Material procurement, vendor management, and logistics", stats: { vendors: "42", orders: "$1.2M", savings: "12%" }, color: "var(--purple)" },
    { name: "ConstructionOS Bonds", icon: "📜", desc: "Bid bonds, performance bonds, and payment bonds", stats: { capacity: "$10M", active: "3", rate: "2.5%" }, color: "var(--red)" },
    { name: "ConstructionOS Intelligence", icon: "📊", desc: "Market data, competitor analysis, and predictive analytics", stats: { markets: "8", signals: "24/day", accuracy: "87%" }, color: "var(--cyan)" },
  ];

  const transactions = [
    { from: "Metro Development", to: "You", amount: "$284,500", type: "invoice", project: "Riverside Lofts", status: "completed", fee: "$4,268" },
    { from: "You", to: "Apex Concrete LLC", amount: "$48,200", type: "payroll", project: "Riverside Lofts", status: "completed", fee: "$723" },
    { from: "You", to: "Nucor Steel", amount: "$62,400", type: "material", project: "Harbor Crossing", status: "processing", fee: "$936" },
    { from: "Harbor Industries", to: "You", amount: "$198,750", type: "invoice", project: "Harbor Crossing", status: "pending", fee: "$0" },
    { from: "You", to: "United Rentals", amount: "$8,500", type: "rental", project: "Pine Ridge", status: "completed", fee: "$128" },
  ];

  const factoring = [
    { ref: "PAY-APP-07", client: "Metro Development", invoice: "$284,500", advance: "$256,050", holdback: "$28,450", fee: "2.5%", days: 1, status: "available" },
    { ref: "PAY-APP-04", client: "Harbor Industries", invoice: "$198,750", advance: "$178,875", holdback: "$19,875", fee: "2.5%", days: 1, status: "available" },
    { ref: "PAY-APP-12", client: "Urban Living", invoice: "$156,200", advance: "$140,580", holdback: "$15,620", fee: "2.5%", days: 1, status: "funded" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>FINANCIAL EMPIRE</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>ConstructionOS Financial Infrastructure</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Pay, Capital, Insurance, Workforce, Supply Chain, Bonds, Intelligence</p>
      </div>

      {/* Division Cards */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: 12, marginBottom: 24 }}>
        {divisions.map(d => (
          <div key={d.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: `1px solid ${d.color}20` }}>
            <div style={{ display: "flex", gap: 10, alignItems: "center", marginBottom: 10 }}>
              <span style={{ fontSize: 28 }}>{d.icon}</span>
              <div>
                <h3 style={{ fontSize: 13, fontWeight: 800, color: d.color, margin: 0 }}>{d.name}</h3>
                <p style={{ fontSize: 9, color: "var(--muted)", margin: "2px 0 0" }}>{d.desc}</p>
              </div>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 6 }}>
              {Object.entries(d.stats).map(([key, val]) => (
                <div key={key} style={{ textAlign: "center", padding: 6, background: "var(--panel)", borderRadius: 6 }}>
                  <div style={{ fontSize: 13, fontWeight: 900, color: d.color }}>{val}</div>
                  <div style={{ fontSize: 7, fontWeight: 700, color: "var(--muted)", textTransform: "uppercase" }}>{key}</div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Recent Transactions */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 10 }}>RECENT TRANSACTIONS</h2>
      {transactions.map((t, i) => (
        <div key={i} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 700 }}>{t.from} → {t.to}</div>
            <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginTop: 2 }}>
              <span>{t.type}</span><span>{t.project}</span><span>Fee: {t.fee}</span>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 13, fontWeight: 900, color: t.to === "You" ? "var(--green)" : "var(--accent)" }}>{t.amount}</span>
            <span style={{ fontSize: 8, fontWeight: 900, color: t.status === "completed" ? "var(--green)" : t.status === "processing" ? "var(--cyan)" : "var(--gold)" }}>{t.status.toUpperCase()}</span>
          </div>
        </div>
      ))}

      {/* Invoice Factoring */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10, marginTop: 20 }}>CAPITAL — INVOICE FACTORING</h2>
      {factoring.map(f => (
        <div key={f.ref} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
            <div>
              <span style={{ fontSize: 11, fontWeight: 900, fontFamily: "monospace", color: "var(--accent)" }}>{f.ref}</span>
              <span style={{ fontSize: 10, color: "var(--muted)", marginLeft: 8 }}>{f.client}</span>
            </div>
            <span style={{ fontSize: 8, fontWeight: 900, color: f.status === "funded" ? "var(--green)" : "var(--gold)" }}>{f.status.toUpperCase()}</span>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
            <div><div style={{ fontSize: 12, fontWeight: 900, color: "var(--gold)" }}>{f.invoice}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>INVOICE</div></div>
            <div><div style={{ fontSize: 12, fontWeight: 900, color: "var(--green)" }}>{f.advance}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>ADVANCE (90%)</div></div>
            <div><div style={{ fontSize: 12, fontWeight: 900, color: "var(--muted)" }}>{f.holdback}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>HOLDBACK</div></div>
            <div><div style={{ fontSize: 12, fontWeight: 900, color: "var(--cyan)" }}>{f.days} day</div><div style={{ fontSize: 7, color: "var(--muted)" }}>TO FUND</div></div>
          </div>
        </div>
      ))}
    </div>
  );
}
