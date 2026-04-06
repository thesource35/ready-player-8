export default function FieldPage() {
  const tabs = ["Daily Log", "Timecards", "Equipment", "Permits"];

  const dailyLogs = [
    { date: "03/31/26", weather: "Partly Cloudy", tempHigh: 82, tempLow: 65, manpower: 47, workPerformed: "Concrete pour Level 3, MEP rough-in B-wing, exterior framing continued", visitors: "Owner rep, inspector", delays: "30 min — crane repositioning", safetyNotes: "Toolbox talk: fall protection. Zero incidents.", photoCount: 24, createdBy: "Mike Torres" },
    { date: "03/28/26", weather: "Sunny", tempHigh: 85, tempLow: 68, manpower: 52, workPerformed: "Steel erection grid C-D, underground plumbing, fire stopping", visitors: "Architect", delays: "None", safetyNotes: "Heat advisory protocol activated. Extra water breaks.", photoCount: 18, createdBy: "Mike Torres" },
    { date: "03/27/26", weather: "Rain", tempHigh: 72, tempLow: 58, manpower: 28, workPerformed: "Interior framing only — exterior work suspended. MEP coordination.", visitors: "None", delays: "4 hrs — weather", safetyNotes: "Wet conditions slip hazard. Extra caution signage deployed.", photoCount: 8, createdBy: "James Wright" },
  ];

  const timecards = [
    { crewMember: "Mike Torres", trade: "Concrete", clockIn: "6:00 AM", clockOut: "2:30 PM", hoursRegular: 8, hoursOT: 0.5, rate: 45, site: "Riverside Lofts", date: "03/25" },
    { crewMember: "Sarah Kim", trade: "Electrical", clockIn: "7:00 AM", clockOut: "5:30 PM", hoursRegular: 8, hoursOT: 2.5, rate: 55, site: "Harbor Crossing", date: "03/25" },
    { crewMember: "James Wright", trade: "Framing", clockIn: "6:30 AM", clockOut: "3:00 PM", hoursRegular: 8, hoursOT: 0, rate: 42, site: "Pine Ridge Ph.2", date: "03/25" },
    { crewMember: "Carlos Mendez", trade: "Plumbing", clockIn: "6:00 AM", clockOut: "4:00 PM", hoursRegular: 8, hoursOT: 2, rate: 52, site: "Riverside Lofts", date: "03/25" },
  ];

  const equipment = [
    { name: "CAT 320 Excavator", tag: "EQ-001", category: "Heavy", site: "Riverside Lofts", hours: 2340, nextService: "50 hrs", status: "ACTIVE" },
    { name: "JLG 600S Boom Lift", tag: "EQ-014", category: "Aerial", site: "Harbor Crossing", hours: 890, nextService: "110 hrs", status: "ACTIVE" },
    { name: "Bobcat S770", tag: "EQ-008", category: "Earthmoving", site: "Pine Ridge Ph.2", hours: 1560, nextService: "40 hrs", status: "SERVICE DUE" },
    { name: "Wacker Compactor", tag: "EQ-022", category: "Compaction", site: "Yard", hours: 420, nextService: "80 hrs", status: "IDLE" },
  ];

  const permits = [
    { number: "BP-2026-4821", type: "Building", jurisdiction: "City of Houston", issued: "01/15/26", expires: "01/15/27", site: "Riverside Lofts", status: "ACTIVE", contact: "J. Martinez" },
    { number: "EP-2026-1193", type: "Electrical", jurisdiction: "Harris County", issued: "02/01/26", expires: "08/01/26", site: "Harbor Crossing", status: "ACTIVE", contact: "R. Chen" },
    { number: "GP-2026-0782", type: "Grading", jurisdiction: "City of Houston", issued: "12/01/25", expires: "06/01/26", site: "Pine Ridge Ph.2", status: "EXPIRING", contact: "A. Patel" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>FIELD OPS</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Field Operations Center</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Daily logs, timecards, equipment tracking, and permits</p>
      </div>

      {/* Tab pills */}
      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--cyan)" : "var(--surface)", color: i === 0 ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Daily Logs */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>DAILY FIELD REPORTS</h2>
      {dailyLogs.map(log => (
        <div key={log.date} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
            <div style={{ display: "flex", gap: 12, alignItems: "center" }}>
              <span style={{ fontSize: 13, fontWeight: 900 }}>{log.date}</span>
              <span style={{ fontSize: 10, color: "var(--cyan)" }}>{log.weather} {log.tempHigh}/{log.tempLow}°F</span>
            </div>
            <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
              <span style={{ fontSize: 10, fontWeight: 800, color: "var(--accent)" }}>{log.manpower} workers</span>
              <span style={{ fontSize: 10, color: "var(--muted)" }}>{log.photoCount} photos</span>
            </div>
          </div>
          <p style={{ fontSize: 11, color: "var(--text)", margin: "0 0 6px" }}>{log.workPerformed}</p>
          <div style={{ display: "flex", gap: 16, fontSize: 9, color: "var(--muted)" }}>
            <span>Visitors: {log.visitors}</span>
            <span style={{ color: log.delays === "None" ? "var(--green)" : "var(--gold)" }}>Delays: {log.delays}</span>
            <span>By: {log.createdBy}</span>
          </div>
          <p style={{ fontSize: 9, color: "var(--green)", margin: "4px 0 0" }}>{log.safetyNotes}</p>
        </div>
      ))}

      {/* Timecards */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10, marginTop: 20 }}>CREW TIMECARDS</h2>
      <div style={{ background: "var(--surface)", borderRadius: 10, overflow: "hidden", marginBottom: 20 }}>
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr 1fr 1fr 1fr", padding: "8px 12px", fontSize: 8, fontWeight: 800, color: "var(--muted)", letterSpacing: 1, borderBottom: "1px solid var(--border)" }}>
          <span>NAME</span><span>TRADE</span><span>IN</span><span>OUT</span><span>REG</span><span>OT</span><span>TOTAL</span>
        </div>
        {timecards.map(tc => (
          <div key={tc.crewMember} style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr 1fr 1fr 1fr", padding: "10px 12px", fontSize: 10, alignItems: "center", borderBottom: "1px solid rgba(51,84,94,0.15)" }}>
            <span style={{ fontWeight: 700 }}>{tc.crewMember}</span>
            <span style={{ color: "var(--cyan)" }}>{tc.trade}</span>
            <span style={{ color: "var(--muted)" }}>{tc.clockIn}</span>
            <span style={{ color: "var(--muted)" }}>{tc.clockOut}</span>
            <span>{tc.hoursRegular}h</span>
            <span style={{ color: tc.hoursOT > 0 ? "var(--gold)" : "var(--muted)" }}>{tc.hoursOT}h</span>
            <span style={{ fontWeight: 800, color: "var(--accent)" }}>${((tc.hoursRegular * tc.rate) + (tc.hoursOT * tc.rate * 1.5)).toFixed(0)}</span>
          </div>
        ))}
      </div>

      {/* Equipment + Permits side by side */}
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>EQUIPMENT TRACKER</h2>
          {equipment.map(e => (
            <div key={e.tag} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <span style={{ fontSize: 11, fontWeight: 800 }}>{e.name}</span>
                  <span style={{ fontSize: 9, color: "var(--muted)", marginLeft: 6 }}>{e.tag}</span>
                </div>
                <span role="status" aria-label={`Status: ${e.status}`} style={{ fontSize: 8, fontWeight: 900, color: e.status === "ACTIVE" ? "var(--green)" : e.status === "SERVICE DUE" ? "var(--gold)" : "var(--muted)" }}>{e.status}</span>
              </div>
              <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginTop: 4 }}>
                <span>{e.category}</span><span>{e.site}</span><span>{e.hours} hrs</span><span>Next: {e.nextService}</span>
              </div>
            </div>
          ))}
        </div>
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>PERMITS</h2>
          {permits.map(p => (
            <div key={p.number} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 11, fontWeight: 800 }}>{p.number}</span>
                <span role="status" aria-label={`Status: ${p.status}`} style={{ fontSize: 8, fontWeight: 900, color: p.status === "ACTIVE" ? "var(--green)" : "var(--gold)" }}>{p.status}</span>
              </div>
              <div style={{ fontSize: 10, color: "var(--muted)", marginTop: 2 }}>{p.type} &bull; {p.jurisdiction} &bull; {p.site}</div>
              <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginTop: 2 }}>
                <span>Issued: {p.issued}</span><span>Expires: {p.expires}</span><span>Contact: {p.contact}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
