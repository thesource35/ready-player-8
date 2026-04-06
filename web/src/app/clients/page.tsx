export default function ClientsPage() {
  const tabs = ["Dashboard", "Selections", "Warranty", "Meetings"];

  const projects = [
    { name: "Riverside Lofts", status: "On Track", progress: 72, budget: "$4.2M" },
    { name: "Harbor Crossing", status: "Ahead", progress: 45, budget: "$8.1M" },
    { name: "Pine Ridge Ph.2", status: "Delayed", progress: 28, budget: "$2.8M" },
  ];

  const selections = [
    { item: "Kitchen Countertops", options: "Quartz vs Granite vs Marble", status: "PENDING", due: "Apr 5" },
    { item: "Flooring - Common Areas", options: "LVP vs Tile vs Polished Concrete", status: "APPROVED", due: "N/A" },
    { item: "Exterior Paint", options: "SW 7015 vs BM HC-172", status: "PENDING", due: "Apr 10" },
    { item: "Light Fixtures - Lobby", options: "Modern LED vs Industrial Pendant", status: "APPROVED", due: "N/A" },
    { item: "Cabinet Hardware", options: "Brushed Nickel vs Matte Black", status: "PENDING", due: "Apr 8" },
  ];

  const warranties = [
    { item: "Roof Membrane (TPO)", manufacturer: "Johns Manville", period: "Jun 2026 - Jun 2046", years: 20 },
    { item: "HVAC System", manufacturer: "Carrier", period: "May 2026 - May 2036", years: 10 },
    { item: "Windows & Glazing", manufacturer: "Pella", period: "Apr 2026 - Apr 2036", years: 10 },
    { item: "Elevator System", manufacturer: "Otis", period: "Jul 2026 - Jul 2031", years: 5 },
    { item: "Waterproofing", manufacturer: "Tremco", period: "Mar 2026 - Mar 2041", years: 15 },
    { item: "Fire Suppression", manufacturer: "Viking Group", period: "Jun 2026 - Jun 2031", years: 5 },
  ];

  const meetings = [
    { date: "Mar 24, 2026", attendees: 8, actionItems: 5, openIssues: 3 },
    { date: "Mar 17, 2026", attendees: 7, actionItems: 4, openIssues: 2 },
    { date: "Mar 10, 2026", attendees: 9, actionItems: 6, openIssues: 1 },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(138,143,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--purple)" }}>CLIENT PORTAL</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Owner & Stakeholder Hub</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Project dashboards, material selections, warranties, and meeting minutes</p>
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--purple)" : "var(--surface)", color: i === 0 ? "white" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Owner Dashboard */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>PROJECT STATUS FOR OWNERS</h2>
      {projects.map(p => (
        <div key={p.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
            <span style={{ fontSize: 13, fontWeight: 800 }}>{p.name}</span>
            <span role="status" aria-label={`Status: ${p.status}`} style={{ fontSize: 9, fontWeight: 900, color: p.status === "On Track" ? "var(--green)" : p.status === "Ahead" ? "var(--cyan)" : "var(--gold)" }}>{p.status}</span>
          </div>
          <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 6, marginBottom: 6 }}>
            <div style={{ background: "var(--accent)", borderRadius: 3, height: 6, width: `${p.progress}%` }} />
          </div>
          <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10 }}>
            <span><b style={{ color: "var(--accent)" }}>{p.progress}%</b> complete</span>
            <span style={{ color: "var(--muted)" }}>Budget: {p.budget}</span>
          </div>
        </div>
      ))}

      {/* Selections */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10, marginTop: 20 }}>MATERIAL & FINISH SELECTIONS</h2>
      {selections.map(s => (
        <div key={s.item} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 14 }}>{s.status === "APPROVED" ? "✅" : "❓"}</span>
            <div>
              <div style={{ fontSize: 11, fontWeight: 800 }}>{s.item}</div>
              <div style={{ fontSize: 9, color: "var(--muted)" }}>{s.options}</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {s.due !== "N/A" && <span style={{ fontSize: 9, fontWeight: 800, color: "var(--gold)" }}>Due: {s.due}</span>}
            <span role="status" aria-label={`Status: ${s.status}`} style={{ fontSize: 8, fontWeight: 900, color: s.status === "APPROVED" ? "var(--green)" : "var(--gold)" }}>{s.status}</span>
          </div>
        </div>
      ))}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginTop: 20 }}>
        {/* Warranties */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>WARRANTY TRACKER</h2>
          {warranties.map(w => (
            <div key={w.item} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 800 }}>{w.item}</div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>{w.manufacturer} &bull; {w.period}</div>
              </div>
              <span style={{ fontSize: 14, fontWeight: 900, color: "var(--cyan)" }}>{w.years} YR</span>
            </div>
          ))}
        </div>

        {/* Meetings */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>OAC MEETING MINUTES</h2>
          {meetings.map(m => (
            <div key={m.date} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ fontSize: 12, fontWeight: 800, marginBottom: 4 }}>{m.date}</div>
              <div style={{ display: "flex", gap: 12, fontSize: 10 }}>
                <span style={{ color: "var(--muted)" }}>{m.attendees} attendees</span>
                <span style={{ color: "var(--cyan)" }}>{m.actionItems} action items</span>
                <span role="status" aria-label={`Open issues: ${m.openIssues}`} style={{ color: m.openIssues > 2 ? "var(--gold)" : "var(--green)" }}>{m.openIssues} open issues</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
