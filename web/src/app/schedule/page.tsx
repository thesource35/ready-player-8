export default function SchedulePage() {
  const ganttTasks = [
    { name: "Site Prep & Grading", trade: "Earthwork", startWeek: 1, duration: 3, complete: 100, critical: true },
    { name: "Foundation", trade: "Concrete", startWeek: 4, duration: 4, complete: 100, critical: true },
    { name: "Structural Steel", trade: "Steel", startWeek: 8, duration: 6, complete: 75, critical: true },
    { name: "Rough Plumbing", trade: "Plumbing", startWeek: 10, duration: 4, complete: 60, critical: false },
    { name: "Electrical Rough-in", trade: "Electrical", startWeek: 11, duration: 5, complete: 45, critical: false },
    { name: "HVAC Ductwork", trade: "HVAC", startWeek: 12, duration: 4, complete: 30, critical: false },
    { name: "Exterior Envelope", trade: "Exterior", startWeek: 14, duration: 5, complete: 10, critical: true },
    { name: "Drywall & Framing", trade: "Framing", startWeek: 16, duration: 4, complete: 0, critical: true },
    { name: "Finishes", trade: "Finishing", startWeek: 20, duration: 3, complete: 0, critical: true },
    { name: "Commissioning", trade: "General", startWeek: 23, duration: 2, complete: 0, critical: true },
  ];

  const totalWeeks = 26;
  const milestones = [
    { name: "Foundation Complete", week: 7, status: "DONE" },
    { name: "Structural Topping Out", week: 13, status: "IN PROGRESS" },
    { name: "Dry-In / Weather Tight", week: 18, status: "UPCOMING" },
    { name: "MEP Rough Complete", week: 16, status: "UPCOMING" },
    { name: "Substantial Completion", week: 24, status: "UPCOMING" },
    { name: "Final CO / Turnover", week: 26, status: "UPCOMING" },
  ];

  const lookahead = [
    { week: "Week 13 (Mar 24-28)", tasks: ["Steel erection grid C-D", "Plumbing rough-in B-wing", "Electrical panel installation"], crew: 52 },
    { week: "Week 14 (Mar 31-Apr 4)", tasks: ["Exterior framing start", "HVAC ductwork Level 2", "Fire stopping inspections"], crew: 48 },
    { week: "Week 15 (Apr 7-11)", tasks: ["Exterior sheathing", "Roof membrane prep", "MEP coordination walk"], crew: 55 },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>SCHEDULE</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Project Timeline & Gantt</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Critical path highlighted &bull; 26-week schedule &bull; 3-week lookahead</p>
      </div>

      {/* Gantt Chart */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>PROJECT TIMELINE</h2>
      <div style={{ background: "var(--surface)", borderRadius: 12, padding: 16, marginBottom: 20, overflowX: "auto" }}>
        {/* Week headers */}
        <div style={{ display: "flex", marginBottom: 8 }}>
          <div style={{ width: 140, flexShrink: 0, fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>TASK</div>
          <div style={{ flex: 1, display: "flex" }}>
            {Array.from({ length: 7 }, (_, i) => (
              <div key={i} style={{ flex: 1, fontSize: 7, fontWeight: 800, color: "var(--muted)", textAlign: "center" }}>W{i * 4 + 1}</div>
            ))}
          </div>
        </div>
        {ganttTasks.map(task => (
          <div key={task.name} style={{ display: "flex", alignItems: "center", marginBottom: 4 }}>
            <div style={{ width: 140, flexShrink: 0 }}>
              <div style={{ fontSize: 9, fontWeight: 800, color: "var(--text)", lineHeight: 1.2 }}>{task.name}</div>
              <div style={{ fontSize: 7, color: "var(--muted)" }}>{task.trade}</div>
            </div>
            <div style={{ flex: 1, position: "relative", height: 18 }}>
              {/* Bar background */}
              <div style={{
                position: "absolute",
                left: `${((task.startWeek - 1) / totalWeeks) * 100}%`,
                width: `${(task.duration / totalWeeks) * 100}%`,
                height: 14,
                top: 2,
                borderRadius: 3,
                background: task.critical ? "rgba(217,77,72,0.15)" : "var(--panel)",
              }} />
              {/* Progress fill */}
              {task.complete > 0 && (
                <div style={{
                  position: "absolute",
                  left: `${((task.startWeek - 1) / totalWeeks) * 100}%`,
                  width: `${(task.duration / totalWeeks) * (task.complete / 100) * 100}%`,
                  height: 14,
                  top: 2,
                  borderRadius: 3,
                  background: task.complete === 100 ? "var(--green)" : task.critical ? "rgba(217,77,72,0.6)" : "rgba(74,196,204,0.6)",
                }} />
              )}
              {/* Percentage label */}
              <div style={{
                position: "absolute",
                left: `${((task.startWeek - 1) / totalWeeks) * 100}%`,
                top: 2,
                height: 14,
                display: "flex",
                alignItems: "center",
                paddingLeft: 4,
                fontSize: 7,
                fontWeight: 900,
                color: "var(--text)",
              }}>{task.complete > 0 ? `${task.complete}%` : ""}</div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        {/* Milestones */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>KEY MILESTONES</h2>
          {milestones.map(m => (
            <div key={m.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 10, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 12 }}>{m.status === "DONE" ? "✅" : m.status === "IN PROGRESS" ? "🔄" : "📅"}</span>
                <div>
                  <div style={{ fontSize: 10, fontWeight: 800 }}>{m.name}</div>
                  <div style={{ fontSize: 8, color: "var(--muted)" }}>Week {m.week}</div>
                </div>
              </div>
              <span role="status" aria-label={`Status: ${m.status}`} style={{ fontSize: 8, fontWeight: 900, color: m.status === "DONE" ? "var(--green)" : m.status === "IN PROGRESS" ? "var(--cyan)" : "var(--muted)" }}>{m.status}</span>
            </div>
          ))}
        </div>

        {/* 3-Week Lookahead */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>3-WEEK LOOKAHEAD</h2>
          {lookahead.map(w => (
            <div key={w.week} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
                <span style={{ fontSize: 11, fontWeight: 800 }}>{w.week}</span>
                <span style={{ fontSize: 10, fontWeight: 800, color: "var(--accent)" }}>{w.crew} crew</span>
              </div>
              {w.tasks.map(t => (
                <div key={t} style={{ fontSize: 10, color: "var(--muted)", padding: "2px 0", paddingLeft: 12, borderLeft: "2px solid var(--cyan)" }}>{t}</div>
              ))}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
