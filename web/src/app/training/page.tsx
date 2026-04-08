export default function TrainingPage() {
  const courses = [
    { title: "OSHA 30-Hour Construction", category: "Safety", hours: 30, status: "IN PROGRESS", progress: 65, provider: "OSHA Education Center", certification: "OSHA 30", required: true },
    { title: "First Aid / CPR / AED", category: "Safety", hours: 8, status: "COMPLETED", progress: 100, provider: "American Red Cross", certification: "First Aid Cert", required: true },
    { title: "Confined Space Entry", category: "Safety", hours: 4, status: "UPCOMING", progress: 0, provider: "Safety Council", certification: "CSE Card", required: true },
    { title: "Crane Signal Person", category: "Operations", hours: 8, status: "COMPLETED", progress: 100, provider: "NCCCO", certification: "NCCCO Signal", required: false },
    { title: "Fall Protection Competent Person", category: "Safety", hours: 16, status: "UPCOMING", progress: 0, provider: "Safety Unlimited", certification: "Fall Pro CP", required: true },
    { title: "Project Management Professional", category: "Management", hours: 35, status: "IN PROGRESS", progress: 40, provider: "PMI", certification: "PMP", required: false },
    { title: "Blueprint Reading", category: "Technical", hours: 12, status: "COMPLETED", progress: 100, provider: "AGC of America", certification: "Blueprint Cert", required: false },
    { title: "Hazardous Waste Operations", category: "Safety", hours: 40, status: "UPCOMING", progress: 0, provider: "HAZWOPER", certification: "HAZWOPER 40", required: true },
  ];

  const certifications = [
    { name: "OSHA 10-Hour", earned: "Jan 2024", expires: "N/A", status: "ACTIVE" },
    { name: "First Aid / CPR", earned: "Mar 2025", expires: "Mar 2027", status: "ACTIVE" },
    { name: "NCCCO Signal Person", earned: "Jun 2025", expires: "Jun 2030", status: "ACTIVE" },
    { name: "Blueprint Reading", earned: "Nov 2025", expires: "N/A", status: "ACTIVE" },
    { name: "Scaffolding Competent Person", earned: "Feb 2024", expires: "Feb 2026", status: "EXPIRING" },
  ];

  const completed = courses.filter(c => c.status === "COMPLETED").length;
  const inProgress = courses.filter(c => c.status === "IN PROGRESS").length;
  const totalHours = courses.filter(c => c.status === "COMPLETED").reduce((a, b) => a + b.hours, 0);

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>TRAINING</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Training & Certifications</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>OSHA, safety certs, professional development, and compliance training</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: courses.length.toString(), label: "TOTAL COURSES", color: "var(--accent)" },
          { val: completed.toString(), label: "COMPLETED", color: "var(--green)" },
          { val: inProgress.toString(), label: "IN PROGRESS", color: "var(--cyan)" },
          { val: `${totalHours}h`, label: "HOURS EARNED", color: "var(--gold)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>COURSE CATALOG</h2>
      {courses.map(c => (
        <div key={c.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
            <div>
              <span style={{ fontSize: 12, fontWeight: 800 }}>{c.title}</span>
              {c.required && <span style={{ fontSize: 8, fontWeight: 900, color: "var(--red)", marginLeft: 8 }}>REQUIRED</span>}
            </div>
            <span role="status" aria-label={`Status: ${c.status}`} style={{ fontSize: 8, fontWeight: 900, color: c.status === "COMPLETED" ? "var(--green)" : c.status === "IN PROGRESS" ? "var(--cyan)" : "var(--muted)" }}>{c.status}</span>
          </div>
          {c.progress > 0 && c.progress < 100 && (
            <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 4, marginBottom: 6 }}>
              <div style={{ background: "var(--cyan)", borderRadius: 3, height: 4, width: `${c.progress}%` }} />
            </div>
          )}
          <div style={{ display: "flex", gap: 14, fontSize: 9, color: "var(--muted)" }}>
            <span>{c.category}</span><span>{c.hours} hours</span><span>{c.provider}</span><span style={{ color: "var(--gold)" }}>{c.certification}</span>
          </div>
        </div>
      ))}

      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 10, marginTop: 20 }}>ACTIVE CERTIFICATIONS</h2>
      {certifications.map(c => (
        <div key={c.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <span style={{ fontSize: 11, fontWeight: 800 }}>{c.name}</span>
            <span style={{ fontSize: 9, color: "var(--muted)", marginLeft: 10 }}>Earned: {c.earned}</span>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {c.expires !== "N/A" && <span style={{ fontSize: 9, color: c.status === "EXPIRING" ? "var(--gold)" : "var(--muted)" }}>Exp: {c.expires}</span>}
            <span role="status" aria-label={`Status: ${c.status}`} style={{ fontSize: 8, fontWeight: 900, color: c.status === "ACTIVE" ? "var(--green)" : "var(--gold)" }}>{c.status}</span>
          </div>
        </div>
      ))}
    </div>
  );
}
