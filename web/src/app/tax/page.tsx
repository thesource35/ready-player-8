export default function TaxPage() {
  const categories = [
    { name: "Materials", icon: "🧱", amount: 142500, count: 34, color: "var(--gold)" },
    { name: "Labor", icon: "👷", amount: 298400, count: 12, color: "var(--cyan)" },
    { name: "Equipment Rental", icon: "🏗", amount: 48200, count: 18, color: "var(--accent)" },
    { name: "Fuel & Mileage", icon: "⛽", amount: 8900, count: 45, color: "var(--green)" },
    { name: "Insurance", icon: "🛡", amount: 24600, count: 4, color: "var(--purple)" },
    { name: "Permits & Fees", icon: "📄", amount: 12300, count: 8, color: "var(--red)" },
    { name: "Tools & Supplies", icon: "🔧", amount: 6800, count: 22, color: "orange" },
    { name: "Office & Admin", icon: "💼", amount: 4200, count: 6, color: "var(--muted)" },
    { name: "Meals & Travel", icon: "🍽", amount: 3100, count: 28, color: "var(--cyan)" },
    { name: "Subcontractors", icon: "🤝", amount: 186000, count: 7, color: "var(--gold)" },
    { name: "Depreciation", icon: "📉", amount: 32000, count: 3, color: "var(--purple)" },
    { name: "Professional Services", icon: "💳", amount: 8500, count: 5, color: "var(--accent)" },
  ];

  const totalDeductions = categories.reduce((a, b) => a + b.amount, 0);

  const quarterlyEstimates = [
    { quarter: "Q1 2026", due: "Apr 15", estimated: "$18,400", status: "DUE" },
    { quarter: "Q2 2026", due: "Jun 15", estimated: "$18,400", status: "UPCOMING" },
    { quarter: "Q3 2026", due: "Sep 15", estimated: "$18,400", status: "UPCOMING" },
    { quarter: "Q4 2026", due: "Jan 15", estimated: "$18,400", status: "UPCOMING" },
  ];

  const subs1099 = [
    { name: "Apex Concrete LLC", ein: "**-***4521", totalPaid: 148200, needs1099: true, filed: false },
    { name: "Elite Steel Erectors", ein: "**-***7834", totalPaid: 86400, needs1099: true, filed: true },
    { name: "Prime Electric Co", ein: "**-***2198", totalPaid: 62000, needs1099: true, filed: false },
    { name: "Quick Plumbing", ein: "**-***5567", totalPaid: 44800, needs1099: true, filed: true },
  ];

  const cpas = [
    { name: "Robert Steinberg", firm: "Steinberg & Associates", specialty: "Construction & Real Estate", rate: "$275/hr", rating: 4.9, certs: ["CPA", "CCA"], available: true },
    { name: "Linda Tran", firm: "BuildTax Advisory", specialty: "Contractor Tax Planning", rate: "$225/hr", rating: 4.8, certs: ["CPA", "EA"], available: true },
    { name: "Michael O'Donnell", firm: "O'Donnell Tax Group", specialty: "Small Business Construction", rate: "$195/hr", rating: 4.7, certs: ["CPA", "QB ProAdvisor"], available: false },
    { name: "Anita Sharma", firm: "Sharma & Partners", specialty: "Multi-State Contractor Tax", rate: "$250/hr", rating: 4.9, certs: ["CPA", "MST"], available: true },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(252,199,87,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)" }}>TAX CENTER</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Construction Tax Accountant</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>12 IRS categories, deductions tracker, quarterly estimates, 1099s, CPA directory</p>
      </div>

      {/* Summary */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 20 }}>
        <div style={{ textAlign: "center", padding: 16, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 26, fontWeight: 900, color: "var(--green)" }}>${(totalDeductions / 1000).toFixed(0)}K</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>TOTAL DEDUCTIONS</div>
        </div>
        <div style={{ textAlign: "center", padding: 16, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 26, fontWeight: 900, color: "var(--accent)" }}>12</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>IRS CATEGORIES</div>
        </div>
        <div style={{ textAlign: "center", padding: 16, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 26, fontWeight: 900, color: "var(--gold)" }}>{categories.reduce((a, b) => a + b.count, 0)}</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>TOTAL EXPENSES</div>
        </div>
      </div>

      {/* Deduction Categories */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>DEDUCTION CATEGORIES</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 8, marginBottom: 20 }}>
        {categories.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
              <span style={{ fontSize: 18 }}>{c.icon}</span>
              <span style={{ fontSize: 8, color: "var(--muted)" }}>{c.count} items</span>
            </div>
            <div style={{ fontSize: 10, fontWeight: 800, marginBottom: 2 }}>{c.name}</div>
            <div style={{ fontSize: 14, fontWeight: 900, color: c.color }}>${(c.amount / 1000).toFixed(1)}K</div>
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>
        {/* Quarterly Estimates */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--red)", marginBottom: 10 }}>QUARTERLY ESTIMATES</h2>
          {quarterlyEstimates.map(q => (
            <div key={q.quarter} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800 }}>{q.quarter}</div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>Due: {q.due}</div>
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 12, fontWeight: 900, color: "var(--accent)" }}>{q.estimated}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: q.status === "DUE" ? "var(--red)" : "var(--muted)" }}>{q.status}</span>
              </div>
            </div>
          ))}
        </div>

        {/* 1099 Tracking */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--purple)", marginBottom: 10 }}>1099 TRACKING</h2>
          {subs1099.map(s => (
            <div key={s.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800 }}>{s.name}</div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>EIN: {s.ein} &bull; ${(s.totalPaid / 1000).toFixed(1)}K paid</div>
              </div>
              <span style={{ fontSize: 8, fontWeight: 900, color: s.filed ? "var(--green)" : "var(--gold)" }}>{s.filed ? "FILED" : "PENDING"}</span>
            </div>
          ))}
        </div>
      </div>

      {/* CPA Directory */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>CONSTRUCTION CPA DIRECTORY</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 10 }}>
        {cpas.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800 }}>{c.name}</div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>{c.firm}</div>
              </div>
              <span style={{ fontSize: 12, fontWeight: 900, color: "var(--gold)" }}>★ {c.rating}</span>
            </div>
            <div style={{ fontSize: 10, color: "var(--cyan)", marginBottom: 4 }}>{c.specialty}</div>
            <div style={{ display: "flex", gap: 4, marginBottom: 4 }}>
              {c.certs.map(cert => (
                <span key={cert} style={{ fontSize: 7, fontWeight: 700, padding: "2px 5px", borderRadius: 3, background: "rgba(74,196,204,0.1)", color: "var(--cyan)" }}>{cert}</span>
              ))}
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 9 }}>
              <span style={{ color: "var(--muted)" }}>{c.rate}</span>
              <span style={{ fontWeight: 900, color: c.available ? "var(--green)" : "var(--red)" }}>{c.available ? "AVAILABLE" : "BOOKED"}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
