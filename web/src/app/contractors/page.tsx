export default function ContractorsPage() {
  const trades = [
    "General Contractor", "Electrical", "Plumbing", "HVAC", "Concrete", "Steel",
    "Framing", "Roofing", "Drywall", "Painting", "Flooring", "Tile",
    "Landscaping", "Excavation", "Fire Protection", "Glass & Glazing",
    "Masonry", "Insulation", "Demolition", "Elevator", "Waterproofing",
    "Solar", "Fiber & Low Voltage", "Heavy Equipment", "Environmental"
  ];

  const contractors = [
    { name: "Torres Construction Group", contact: "Miguel Torres", trade: "General Contractor", location: "Houston, TX", country: "USA", rating: 4.9, projects: 142, employees: 85, verified: true, revenue: "$28M", specialty: "Commercial, Healthcare" },
    { name: "Kim Steel Erectors", contact: "Sarah Kim", trade: "Steel", location: "Dallas, TX", country: "USA", rating: 4.8, projects: 89, employees: 42, verified: true, revenue: "$12M", specialty: "High-Rise, Industrial" },
    { name: "Wright Framing Co", contact: "James Wright", trade: "Framing", location: "Austin, TX", country: "USA", rating: 4.7, projects: 234, employees: 65, verified: true, revenue: "$8M", specialty: "Residential, Multi-Family" },
    { name: "Apex Concrete LLC", contact: "David Chen", trade: "Concrete", location: "Houston, TX", country: "USA", rating: 4.9, projects: 312, employees: 120, verified: true, revenue: "$22M", specialty: "Foundations, Parking Structures" },
    { name: "Elite Electric", contact: "Ana Rodriguez", trade: "Electrical", location: "San Antonio, TX", country: "USA", rating: 4.6, projects: 178, employees: 35, verified: true, revenue: "$6M", specialty: "Commercial, Data Centers" },
    { name: "Nordic Build AB", contact: "Erik Lindqvist", trade: "General Contractor", location: "Stockholm", country: "Sweden", rating: 4.8, projects: 67, employees: 200, verified: true, revenue: "$45M", specialty: "Modular, Sustainable" },
    { name: "Grupo Constructor MX", contact: "Carlos Mendez", trade: "General Contractor", location: "Mexico City", country: "Mexico", rating: 4.7, projects: 95, employees: 150, verified: true, revenue: "$18M", specialty: "Infrastructure, Hospitality" },
    { name: "Pacific Plumbing", contact: "Tom Bradley", trade: "Plumbing", location: "Los Angeles, CA", country: "USA", rating: 4.8, projects: 256, employees: 55, verified: true, revenue: "$10M", specialty: "High-Rise, Medical" },
    { name: "Dubai Build Corp", contact: "Ahmed Al-Rashid", trade: "General Contractor", location: "Dubai", country: "UAE", rating: 4.9, projects: 38, employees: 500, verified: true, revenue: "$120M", specialty: "Luxury, Mega Projects" },
    { name: "Maple Leaf HVAC", contact: "Sarah Thompson", trade: "HVAC", location: "Toronto", country: "Canada", rating: 4.7, projects: 134, employees: 48, verified: true, revenue: "$9M", specialty: "Commercial, Industrial" },
    { name: "Schmidt Bau GmbH", contact: "Hans Schmidt", trade: "General Contractor", location: "Munich", country: "Germany", rating: 4.8, projects: 52, employees: 180, verified: true, revenue: "$55M", specialty: "Infrastructure, Industrial" },
    { name: "Outback Earthworks", contact: "Jack Murray", trade: "Excavation", location: "Sydney", country: "Australia", rating: 4.6, projects: 89, employees: 72, verified: true, revenue: "$14M", specialty: "Mining, Civil" },
  ];

  const countries = ["All", "USA", "Mexico", "Canada", "UAE", "Sweden", "Germany", "Australia"];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>DIRECTORY</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Global Contractor Directory</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>25 trades, {contractors.length} contractors, 6+ countries — verified and rated</p>
      </div>

      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: "25", label: "TRADES", color: "var(--accent)" },
          { val: contractors.length.toString(), label: "CONTRACTORS", color: "var(--cyan)" },
          { val: "6", label: "COUNTRIES", color: "var(--gold)" },
          { val: "100%", label: "VERIFIED", color: "var(--green)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 22, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Country Filter */}
      <div style={{ display: "flex", gap: 6, marginBottom: 12, flexWrap: "wrap" }}>
        {countries.map(c => (
          <span key={c} style={{ fontSize: 10, fontWeight: 700, padding: "5px 12px", borderRadius: 6, background: c === "All" ? "var(--accent)" : "var(--surface)", color: c === "All" ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{c}</span>
        ))}
      </div>

      {/* Trade Tags */}
      <div style={{ display: "flex", gap: 4, marginBottom: 16, flexWrap: "wrap" }}>
        {trades.slice(0, 12).map(t => (
          <span key={t} style={{ fontSize: 8, fontWeight: 700, padding: "3px 8px", borderRadius: 4, background: "var(--surface)", color: "var(--muted)", border: "1px solid rgba(51,84,94,0.3)" }}>{t}</span>
        ))}
        <span style={{ fontSize: 8, fontWeight: 700, padding: "3px 8px", borderRadius: 4, color: "var(--cyan)" }}>+{trades.length - 12} more</span>
      </div>

      {/* Contractor Grid */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(350px, 1fr))", gap: 10 }}>
        {contractors.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 8 }}>
              <div>
                <h3 style={{ fontSize: 13, fontWeight: 800, margin: 0 }}>{c.name}</h3>
                <p style={{ fontSize: 10, color: "var(--muted)", margin: "2px 0" }}>{c.contact} &bull; {c.location}, {c.country}</p>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={{ fontSize: 12, fontWeight: 900, color: "var(--gold)" }}>★ {c.rating}</div>
                {c.verified && <span style={{ fontSize: 7, fontWeight: 900, color: "var(--green)" }}>✓ VERIFIED</span>}
              </div>
            </div>
            <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 6 }}>
              <span style={{ fontSize: 8, fontWeight: 800, padding: "2px 6px", borderRadius: 3, background: "rgba(74,196,204,0.1)", color: "var(--cyan)" }}>{c.trade}</span>
              <span style={{ fontSize: 8, fontWeight: 700, color: "var(--gold)" }}>{c.revenue}</span>
              <span style={{ fontSize: 8, color: "var(--muted)" }}>{c.employees} employees</span>
              <span style={{ fontSize: 8, color: "var(--muted)" }}>{c.projects} projects</span>
            </div>
            <div style={{ fontSize: 9, color: "var(--accent)" }}>Specialty: {c.specialty}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
