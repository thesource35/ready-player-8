export default function CompliancePage() {
  const tabs = ["Toolbox Talks", "Payroll", "Environmental"];

  const toolboxTopics = [
    { title: "Fall Protection - Harness Inspection", category: "Fall Protection", duration: "15 min", required: true },
    { title: "Trenching & Excavation Safety", category: "Excavation", duration: "20 min", required: true },
    { title: "Electrical Safety - Lockout/Tagout", category: "Electrical", duration: "15 min", required: true },
    { title: "Heat Illness Prevention", category: "Weather", duration: "10 min", required: false },
    { title: "Scaffold Safety", category: "Fall Protection", duration: "15 min", required: true },
    { title: "Silica Dust Exposure", category: "Health", duration: "20 min", required: true },
    { title: "Fire Prevention on Jobsite", category: "Fire Safety", duration: "15 min", required: false },
    { title: "PPE Inspection & Usage", category: "General", duration: "10 min", required: true },
  ];

  const payrollWeeks = [
    { week: "Week 12 (Mar 17-23)", employees: 38, hours: 1520, amount: "$98,400", status: "SUBMITTED" },
    { week: "Week 11 (Mar 10-16)", employees: 41, hours: 1640, amount: "$106,200", status: "APPROVED" },
    { week: "Week 10 (Mar 3-9)", employees: 36, hours: 1440, amount: "$93,600", status: "APPROVED" },
  ];

  const environmental = [
    { item: "SWPPP Plan", status: "CURRENT", lastInspection: "Mar 20", nextInspection: "Apr 20" },
    { item: "Dust Monitoring", status: "CURRENT", lastInspection: "Mar 24", nextInspection: "Mar 31" },
    { item: "Noise Compliance", status: "DUE", lastInspection: "Mar 10", nextInspection: "Mar 25" },
    { item: "Erosion Controls", status: "CURRENT", lastInspection: "Mar 22", nextInspection: "Apr 5" },
    { item: "Waste Disposal Log", status: "CURRENT", lastInspection: "Mar 25", nextInspection: "Apr 1" },
    { item: "EPA Stormwater Permit", status: "ACTIVE", lastInspection: "Jan 15", nextInspection: "Jan 15/27" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(217,77,72,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--red)" }}>COMPLIANCE</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Safety & Regulatory</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Toolbox talks, certified payroll, and environmental compliance</p>
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--red)" : "var(--surface)", color: i === 0 ? "white" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Toolbox Talks */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>WEEKLY TOOLBOX TALKS</h2>
      {toolboxTopics.map(t => (
        <div key={t.title} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <span style={{ fontSize: 14 }}>{t.required ? "🛡" : "📋"}</span>
            <div>
              <div style={{ fontSize: 11, fontWeight: 800 }}>{t.title}</div>
              <div style={{ fontSize: 9, color: "var(--muted)" }}>{t.category} &bull; {t.duration}</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {t.required && <span style={{ fontSize: 8, fontWeight: 900, color: "var(--red)" }}>REQUIRED</span>}
            <a href="/login" style={{ background: "var(--gold)", color: "var(--bg)", border: "none", borderRadius: 4, padding: "4px 10px", fontSize: 9, fontWeight: 800, cursor: "pointer", textDecoration: "none" }}>START</a>
          </div>
        </div>
      ))}

      {/* Certified Payroll */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--purple)", marginBottom: 10, marginTop: 20 }}>CERTIFIED PAYROLL (WH-347)</h2>
      {payrollWeeks.map(w => (
        <div key={w.week} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <span style={{ fontSize: 12, fontWeight: 800 }}>{w.week}</span>
            <span style={{ fontSize: 8, fontWeight: 900, color: w.status === "APPROVED" ? "var(--green)" : "var(--gold)" }}>{w.status}</span>
          </div>
          <div style={{ display: "flex", gap: 16, fontSize: 10 }}>
            <span style={{ color: "var(--muted)" }}>{w.employees} employees</span>
            <span style={{ color: "var(--cyan)" }}>{w.hours} hrs</span>
            <span style={{ fontWeight: 900, color: "var(--accent)" }}>{w.amount}</span>
          </div>
        </div>
      ))}

      {/* Environmental */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 10, marginTop: 20 }}>ENVIRONMENTAL COMPLIANCE</h2>
      {environmental.map(e => (
        <div key={e.item} style={{ background: "var(--surface)", borderRadius: 8, padding: 10, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <div style={{ width: 6, height: 6, borderRadius: "50%", background: e.status === "DUE" ? "var(--gold)" : "var(--green)" }} />
            <span style={{ fontSize: 11, fontWeight: 700 }}>{e.item}</span>
          </div>
          <div style={{ display: "flex", gap: 12, fontSize: 9, color: "var(--muted)" }}>
            <span>Last: {e.lastInspection}</span>
            <span style={{ color: e.status === "DUE" ? "var(--gold)" : "var(--muted)", fontWeight: e.status === "DUE" ? 800 : 400 }}>Next: {e.nextInspection}</span>
            <span style={{ fontWeight: 900, color: e.status === "DUE" ? "var(--gold)" : "var(--green)" }}>{e.status}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
