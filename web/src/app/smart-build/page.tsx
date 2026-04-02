export default function SmartBuildPage() {
  const modules = [
    { name: "Concrete AI", icon: "🧪", desc: "IoT-powered concrete testing, mix optimization, and strength prediction", features: ["Real-time strength monitoring", "Mix design AI", "Cure time prediction", "Quality control dashboards"], color: "var(--accent)" },
    { name: "BIM Center", icon: "🏗", desc: "Building Information Modeling hub with clash detection and 4D scheduling", features: ["3D model viewer", "Clash detection reports", "4D schedule integration", "Trade coordination"], color: "var(--cyan)" },
    { name: "Net Zero Design", icon: "🌿", desc: "Sustainability tools for energy modeling and LEED certification tracking", features: ["Energy modeling (EUI)", "LEED scorecard", "Carbon calculator", "Renewable integration"], color: "var(--green)" },
    { name: "Modular Construction", icon: "📦", desc: "Prefab/modular planning, factory scheduling, and logistics coordination", features: ["Module tracking", "Factory schedule sync", "Transport logistics", "On-site assembly sequence"], color: "var(--gold)" },
    { name: "Auto Home", icon: "🏠", desc: "Smart home automation integration for residential construction", features: ["Wiring schematics", "Device planning", "Automation scenes", "Commissioning checklists"], color: "var(--purple)" },
  ];

  const concreteTests = [
    { batch: "B-2026-042", mix: "4000 PSI Ready Mix", pour: "Level 3 Deck", cylinders: 6, day7: "3,240 PSI", day28: "4,180 PSI", status: "PASSED", temp: "72°F", slump: "4.5 in" },
    { batch: "B-2026-041", mix: "5000 PSI Structural", pour: "Columns Grid C", cylinders: 6, day7: "4,100 PSI", day28: "5,320 PSI", status: "PASSED", temp: "68°F", slump: "5.0 in" },
    { batch: "B-2026-040", mix: "3000 PSI Sidewalk", pour: "Exterior Flatwork", cylinders: 4, day7: "2,480 PSI", day28: "—", status: "CURING", temp: "75°F", slump: "6.0 in" },
  ];

  const bimClashes = [
    { id: "CLASH-042", type: "Hard", systems: "HVAC Duct vs Structural Beam", location: "Grid D-4, Level 2", severity: "CRITICAL", status: "OPEN" },
    { id: "CLASH-041", type: "Clearance", systems: "Plumbing vs Electrical Conduit", location: "Grid B-7, Level 3", severity: "HIGH", status: "RESOLVED" },
    { id: "CLASH-040", type: "Soft", systems: "Fire Sprinkler vs Ceiling Grid", location: "Grid A-2, Level 1", severity: "MEDIUM", status: "IN REVIEW" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>SMART BUILD</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Smart Build Hub</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>IoT concrete testing, BIM center, net zero design, modular construction, auto home</p>
      </div>

      {/* Module Cards */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(220px, 1fr))", gap: 10, marginBottom: 24 }}>
        {modules.map(m => (
          <div key={m.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: `1px solid ${m.color}20` }}>
            <div style={{ fontSize: 28, marginBottom: 8 }}>{m.icon}</div>
            <h3 style={{ fontSize: 14, fontWeight: 800, color: m.color, marginBottom: 4 }}>{m.name}</h3>
            <p style={{ fontSize: 10, color: "var(--muted)", marginBottom: 8 }}>{m.desc}</p>
            {m.features.map(f => (
              <div key={f} style={{ fontSize: 9, color: "var(--text)", padding: "2px 0", paddingLeft: 10, borderLeft: `2px solid ${m.color}50` }}>{f}</div>
            ))}
          </div>
        ))}
      </div>

      {/* Concrete AI Tests */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>CONCRETE AI — BREAK TEST RESULTS</h2>
      <div style={{ background: "var(--surface)", borderRadius: 10, overflow: "hidden", marginBottom: 20 }}>
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 1.5fr 1.5fr 0.5fr 1fr 1fr 0.8fr", padding: "8px 12px", fontSize: 8, fontWeight: 800, color: "var(--muted)", letterSpacing: 1, borderBottom: "1px solid var(--border)" }}>
          <span>BATCH</span><span>MIX</span><span>POUR</span><span>CYL</span><span>7-DAY</span><span>28-DAY</span><span>STATUS</span>
        </div>
        {concreteTests.map(t => (
          <div key={t.batch} style={{ display: "grid", gridTemplateColumns: "1.2fr 1.5fr 1.5fr 0.5fr 1fr 1fr 0.8fr", padding: "10px 12px", fontSize: 10, alignItems: "center", borderBottom: "1px solid rgba(51,84,94,0.15)" }}>
            <span style={{ fontWeight: 800, fontFamily: "monospace", color: "var(--accent)" }}>{t.batch}</span>
            <span>{t.mix}</span>
            <span style={{ color: "var(--muted)" }}>{t.pour}</span>
            <span>{t.cylinders}</span>
            <span style={{ fontWeight: 800, color: "var(--cyan)" }}>{t.day7}</span>
            <span style={{ fontWeight: 800, color: t.day28 === "—" ? "var(--muted)" : "var(--green)" }}>{t.day28}</span>
            <span style={{ fontWeight: 900, fontSize: 8, color: t.status === "PASSED" ? "var(--green)" : "var(--gold)" }}>{t.status}</span>
          </div>
        ))}
      </div>

      {/* BIM Clash Detection */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>BIM CLASH DETECTION</h2>
      {bimClashes.map(c => (
        <div key={c.id} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center", borderLeft: `3px solid ${c.severity === "CRITICAL" ? "var(--red)" : c.severity === "HIGH" ? "var(--gold)" : "var(--cyan)"}` }}>
          <div>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <span style={{ fontSize: 10, fontWeight: 900, fontFamily: "monospace" }}>{c.id}</span>
              <span style={{ fontSize: 8, fontWeight: 800, color: "var(--cyan)" }}>{c.type}</span>
            </div>
            <div style={{ fontSize: 11, fontWeight: 700, marginTop: 2 }}>{c.systems}</div>
            <div style={{ fontSize: 9, color: "var(--muted)", marginTop: 1 }}>{c.location}</div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 8, fontWeight: 900, color: c.severity === "CRITICAL" ? "var(--red)" : c.severity === "HIGH" ? "var(--gold)" : "var(--cyan)" }}>{c.severity}</span>
            <span style={{ fontSize: 8, fontWeight: 900, color: c.status === "RESOLVED" ? "var(--green)" : c.status === "OPEN" ? "var(--red)" : "var(--gold)" }}>{c.status}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
