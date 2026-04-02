"use client";
import { useState } from "react";

export default function ProjectsPage() {
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("All");
  const allProjects = [
    { name: "Riverside Lofts", client: "Metro Development", type: "Mixed-Use", status: "On Track", progress: 72, budget: "$4.2M", score: 88, superintendent: "Mike Torres", startDate: "Jan 2026", endDate: "Nov 2026" },
    { name: "Harbor Crossing", client: "Harbor Industries", type: "Commercial", status: "Ahead", progress: 45, budget: "$8.1M", score: 92, superintendent: "Sarah Kim", startDate: "Mar 2026", endDate: "Feb 2027" },
    { name: "Pine Ridge Ph.2", client: "Urban Living", type: "Residential", status: "Delayed", progress: 28, budget: "$2.8M", score: 61, superintendent: "James Wright", startDate: "Feb 2026", endDate: "Sep 2026" },
    { name: "Skyline Tower", client: "Apex Corp", type: "High-Rise", status: "On Track", progress: 15, budget: "$22.5M", score: 85, superintendent: "David Chen", startDate: "Apr 2026", endDate: "Dec 2027" },
    { name: "Metro Station Retrofit", client: "City of Houston", type: "Infrastructure", status: "At Risk", progress: 55, budget: "$6.3M", score: 54, superintendent: "Ana Rodriguez", startDate: "Nov 2025", endDate: "Aug 2026" },
  ];

  const statusFilters = ["All", "On Track", "Ahead", "Delayed", "At Risk"];
  const projects = allProjects.filter(p => {
    const matchesSearch = !search || p.name.toLowerCase().includes(search.toLowerCase()) || p.client.toLowerCase().includes(search.toLowerCase()) || p.type.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = filterStatus === "All" || p.status === filterStatus;
    return matchesSearch && matchesFilter;
  });
  const activeCount = projects.filter(p => p.status !== "Delayed").length;
  const avgScore = Math.round(projects.reduce((a, b) => a + b.score, 0) / projects.length);
  const totalBudget = "$43.9M";

  const statusColor = (s: string) => s === "On Track" ? "var(--green)" : s === "Ahead" ? "var(--cyan)" : s === "At Risk" ? "var(--red)" : "var(--gold)";

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      {/* Header */}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--accent)" }}>PROJECTS</div>
            <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Project Command</h1>
            <p style={{ fontSize: 12, color: "var(--muted)" }}>Full project lifecycle management with real-time tracking</p>
          </div>
          <a href="/login" style={{ background: "var(--accent)", color: "var(--bg)", border: "none", borderRadius: 8, padding: "8px 16px", fontWeight: 700, fontSize: 12, cursor: "pointer", textDecoration: "none", display: "inline-block" }}>+ Add Project</a>
        </div>
      </div>

      {/* Search */}
      <input placeholder="Search projects, clients, types..." value={search} onChange={e => setSearch(e.target.value)} style={{ width: "100%", marginBottom: 12 }} />

      {/* Status Filters */}
      <div style={{ display: "flex", gap: 6, marginBottom: 16, flexWrap: "wrap" }}>
        {statusFilters.map(f => (
          <span key={f} onClick={() => setFilterStatus(f)} style={{ fontSize: 10, fontWeight: 700, padding: "5px 12px", borderRadius: 6, background: filterStatus === f ? "var(--accent)" : "var(--surface)", color: filterStatus === f ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{f}</span>
        ))}
      </div>

      {/* Stats Row */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: projects.length.toString(), label: "TOTAL", color: "var(--accent)" },
          { val: activeCount.toString(), label: "ACTIVE", color: "var(--green)" },
          { val: avgScore.toString(), label: "AVG SCORE", color: "var(--cyan)" },
          { val: totalBudget, label: "PIPELINE", color: "var(--gold)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)", marginTop: 4 }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Project Cards */}
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        {projects.map(p => (
          <div key={p.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, border: "1px solid rgba(74,196,204,0.06)" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 10 }}>
              <div>
                <h3 style={{ fontSize: 14, fontWeight: 800, margin: 0 }}>{p.name}</h3>
                <p style={{ fontSize: 11, color: "var(--muted)", margin: "2px 0 0" }}>{p.client} &bull; {p.type}</p>
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 16, fontWeight: 900, color: "var(--cyan)" }}>{p.score}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: statusColor(p.status), background: `${statusColor(p.status)}15`, padding: "3px 8px", borderRadius: 4 }}>{p.status.toUpperCase()}</span>
              </div>
            </div>
            <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 4, height: 6, marginBottom: 8 }}>
              <div style={{ background: "var(--accent)", borderRadius: 4, height: 6, width: `${p.progress}%`, transition: "width 0.3s" }} />
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", fontSize: 10, color: "var(--muted)" }}>
              <span><b style={{ color: "var(--accent)" }}>{p.progress}%</b> complete</span>
              <span>Superintendent: {p.superintendent}</span>
              <span>Budget: <b style={{ color: "var(--gold)" }}>{p.budget}</b></span>
              <span>{p.startDate} &mdash; {p.endDate}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
