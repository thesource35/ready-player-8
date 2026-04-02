export default function TechPage() {
  const categories = [
    { name: "Digital Twin", icon: "🏗", desc: "Real-time 3D replicas of construction sites for monitoring and planning", features: ["Live IoT sensor integration", "As-built vs. design comparison", "Progress visualization", "Defect detection"], color: "var(--cyan)" },
    { name: "Construction Robotics", icon: "🤖", desc: "Autonomous and semi-autonomous robots for construction tasks", features: ["Bricklaying robots", "Rebar tying automation", "Demolition robots", "3D printing structures"], color: "var(--accent)" },
    { name: "3D Laser Scanning", icon: "📡", desc: "High-accuracy point cloud capture for existing conditions", features: ["BIM model generation", "Clash detection input", "Progress documentation", "Quality verification"], color: "var(--green)" },
    { name: "Sustainability Tech", icon: "🌿", desc: "Tools and systems for net-zero and green building", features: ["Embodied carbon tracking", "Energy modeling", "LEED automation", "Material passport system"], color: "var(--gold)" },
    { name: "Wearable Technology", icon: "⌚", desc: "Smart PPE and biometric monitoring for safety", features: ["Smart hard hats with AR", "Fatigue detection", "Location tracking", "Environmental sensors"], color: "var(--purple)" },
    { name: "Modular & Prefab", icon: "📦", desc: "Factory-built components assembled on site", features: ["BIM-to-factory pipeline", "Transport logistics", "Assembly sequence AI", "Quality tracking"], color: "var(--red)" },
    { name: "5G & IoT Jobsite", icon: "📶", desc: "Connected jobsite with real-time data from every sensor", features: ["Private 5G networks", "Concrete curing sensors", "Structural monitoring", "Equipment telematics"], color: "var(--cyan)" },
    { name: "AI & Machine Learning", icon: "🧠", desc: "Predictive analytics and automation for construction", features: ["Schedule optimization", "Cost prediction", "Safety risk scoring", "Resource allocation"], color: "var(--accent)" },
  ];

  const timeline = [
    { year: "2024", milestone: "AI-powered scheduling becomes mainstream", status: "ACHIEVED" },
    { year: "2025", milestone: "First fully autonomous bricklaying on commercial project", status: "ACHIEVED" },
    { year: "2026", milestone: "Digital twin standard on projects >$10M", status: "IN PROGRESS" },
    { year: "2027", milestone: "Prefab reaches 30% of new commercial construction", status: "PROJECTED" },
    { year: "2028", milestone: "Carbon-neutral construction methods reach cost parity", status: "PROJECTED" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>TECH 2026</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Construction Technology 2026</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Digital twins, robotics, 3D scanning, sustainability, wearables, modular, 5G, AI</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 12, marginBottom: 24 }}>
        {categories.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: `1px solid ${c.color}20` }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>{c.icon}</div>
            <h3 style={{ fontSize: 14, fontWeight: 800, color: c.color, marginBottom: 4 }}>{c.name}</h3>
            <p style={{ fontSize: 10, color: "var(--muted)", marginBottom: 10 }}>{c.desc}</p>
            {c.features.map(f => (
              <div key={f} style={{ fontSize: 9, color: "var(--text)", padding: "3px 0", paddingLeft: 10, borderLeft: `2px solid ${c.color}50` }}>{f}</div>
            ))}
          </div>
        ))}
      </div>

      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>CONSTRUCTION TECH TIMELINE</h2>
      {timeline.map(t => (
        <div key={t.year} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
            <span style={{ fontSize: 18, fontWeight: 900, color: "var(--accent)" }}>{t.year}</span>
            <span style={{ fontSize: 12, fontWeight: 700 }}>{t.milestone}</span>
          </div>
          <span style={{ fontSize: 8, fontWeight: 900, color: t.status === "ACHIEVED" ? "var(--green)" : t.status === "IN PROGRESS" ? "var(--cyan)" : "var(--muted)" }}>{t.status}</span>
        </div>
      ))}
    </div>
  );
}
