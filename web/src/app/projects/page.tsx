"use client";
import { useState, useEffect } from "react";
import PremiumFeatureGate from "@/app/components/PremiumFeatureGate";
import SubscriberActionButton from "@/app/components/SubscriberActionButton";

interface Project {
  name: string;
  client: string;
  type: string;
  status: string;
  progress: number;
  budget: string;
  score: number;
  superintendent: string;
  startDate: string;
  endDate: string;
}

const fallbackProjects: Project[] = [
  { name: "Riverside Lofts", client: "Metro Development", type: "Mixed-Use", status: "On Track", progress: 72, budget: "$4.2M", score: 88, superintendent: "Mike Torres", startDate: "Jan 2026", endDate: "Nov 2026" },
  { name: "Harbor Crossing", client: "Harbor Industries", type: "Commercial", status: "Ahead", progress: 45, budget: "$8.1M", score: 92, superintendent: "Sarah Kim", startDate: "Mar 2026", endDate: "Feb 2027" },
  { name: "Pine Ridge Ph.2", client: "Urban Living", type: "Residential", status: "Delayed", progress: 28, budget: "$2.8M", score: 61, superintendent: "James Wright", startDate: "Feb 2026", endDate: "Sep 2026" },
  { name: "Skyline Tower", client: "Apex Corp", type: "High-Rise", status: "On Track", progress: 15, budget: "$22.5M", score: 85, superintendent: "David Chen", startDate: "Apr 2026", endDate: "Dec 2027" },
  { name: "Metro Station Retrofit", client: "City of Houston", type: "Infrastructure", status: "At Risk", progress: 55, budget: "$6.3M", score: 54, superintendent: "Ana Rodriguez", startDate: "Nov 2025", endDate: "Aug 2026" },
];

export default function ProjectsPage() {
  const [search, setSearch] = useState("");
  const [filterStatus, setFilterStatus] = useState("All");
  const [showAddProject, setShowAddProject] = useState(false);
  const [draftProject, setDraftProject] = useState({
    name: "",
    client: "",
    type: "Commercial",
    budget: "",
  });
  const [projectList, setProjectList] = useState<Project[]>(fallbackProjects);
  const [addError, setAddError] = useState<string | null>(null);
  const [addLoading, setAddLoading] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);

  const mapProject = (p: Record<string, unknown>): Project => ({
    name: (p.name as string) || "",
    client: (p.client as string) || "",
    type: (p.type as string) || "",
    status: (p.status as string) || "On Track",
    progress: (p.progress as number) || 0,
    budget: (p.budget as string) || "$0",
    score: Number(p.score) || 0,
    superintendent: (p.superintendent as string) || (p.team as string) || "Unassigned",
    startDate: (p.startDate as string) || (p.start_date as string) || "TBD",
    endDate: (p.endDate as string) || (p.end_date as string) || "TBD",
  });

  useEffect(() => {
    setIsLoading(true);
    fetch("/api/projects?page=0")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((result: Record<string, unknown> | Record<string, unknown>[]) => {
        if (Array.isArray(result)) {
          if (result.length > 0) setProjectList(result.map(mapProject));
          setHasMore(false);
        } else {
          const items = result.data as Record<string, unknown>[] | undefined;
          if (Array.isArray(items) && items.length > 0) setProjectList(items.map(mapProject));
          setHasMore((result.hasMore as boolean) || false);
        }
        setIsLoading(false);
      })
      .catch(() => { setError("Failed to load projects"); setIsLoading(false); });
  }, []);

  const loadMore = async () => {
    setLoadingMore(true);
    try {
      const nextPage = page + 1;
      const res = await fetch(`/api/projects?page=${nextPage}`);
      const result = await res.json();
      if (Array.isArray(result)) {
        setProjectList(prev => [...prev, ...result.map(mapProject)]);
        setHasMore(false);
      } else {
        const items = result.data as Record<string, unknown>[] | undefined;
        setProjectList(prev => [...prev, ...(items || []).map(mapProject)]);
        setHasMore(result.hasMore || false);
      }
      setPage(nextPage);
    } catch {
      // Silently fail — user can retry
    } finally {
      setLoadingMore(false);
    }
  };

  const statusFilters = ["All", "On Track", "Ahead", "Delayed", "At Risk"];
  const projects = projectList.filter(p => {
    const matchesSearch = !search || p.name.toLowerCase().includes(search.toLowerCase()) || p.client.toLowerCase().includes(search.toLowerCase()) || p.type.toLowerCase().includes(search.toLowerCase());
    const matchesFilter = filterStatus === "All" || p.status === filterStatus;
    return matchesSearch && matchesFilter;
  });
  const activeCount = projects.filter(p => p.status !== "Delayed").length;
  const avgScore = Math.round(projects.reduce((a, b) => a + b.score, 0) / projects.length);
  const totalBudget = "$43.9M";

  const statusColor = (s: string) => s === "On Track" ? "var(--green)" : s === "Ahead" ? "var(--cyan)" : s === "At Risk" ? "var(--red)" : "var(--gold)";

  async function addProject() {
    setAddError(null);

    // Client-side validation
    if (!draftProject.name.trim()) {
      setAddError("Project name is required");
      return;
    }
    if (!draftProject.client.trim()) {
      setAddError("Client name is required");
      return;
    }

    setAddLoading(true);
    try {
      const res = await fetch("/api/projects", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: draftProject.name.trim(),
          client: draftProject.client.trim(),
          type: draftProject.type.trim() || "Commercial",
          budget: draftProject.budget.trim() || "$0",
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setAddError(data.error || "Failed to create project");
        setAddLoading(false);
        return;
      }

      // Add the server-returned project to local list
      setProjectList(prev => [
        {
          name: data.name || draftProject.name,
          client: data.client || draftProject.client,
          type: data.type || draftProject.type,
          status: data.status || "On Track",
          progress: data.progress || 0,
          budget: data.budget || draftProject.budget || "$0",
          score: data.score || 80,
          superintendent: data.team || "Unassigned",
          startDate: data.start_date || "TBD",
          endDate: data.end_date || "TBD",
        },
        ...prev,
      ]);
      setDraftProject({ name: "", client: "", type: "Commercial", budget: "" });
      setShowAddProject(false);
    } catch {
      setAddError("Network error. Please try again.");
    }
    setAddLoading(false);
  }

  return (
    <PremiumFeatureGate feature="projects">
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      {/* Header */}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--accent)" }}>PROJECTS</div>
            <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Project Command</h1>
            <p style={{ fontSize: 12, color: "var(--muted)" }}>Full project lifecycle management with real-time tracking</p>
          </div>
          <SubscriberActionButton label="+ Add Project" onPaidClick={() => { setAddError(null); setShowAddProject(v => !v); }} style={{ background: "var(--accent)", color: "var(--bg)", border: "none", borderRadius: 8, padding: "8px 16px", fontWeight: 700, fontSize: 12, cursor: "pointer", display: "inline-block" }} />
        </div>
      </div>

      {showAddProject && (
        <div style={{ background: "var(--surface)", borderRadius: 12, padding: 16, marginBottom: 16, border: "1px solid rgba(74,196,204,0.12)" }}>
          <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>NEW PROJECT</div>
          <div style={{ display: "grid", gridTemplateColumns: "2fr 2fr 1fr 1fr", gap: 10 }}>
            <input placeholder="Project name" maxLength={200} value={draftProject.name} onChange={e => setDraftProject(prev => ({ ...prev, name: e.target.value }))} />
            <input placeholder="Client" maxLength={200} value={draftProject.client} onChange={e => setDraftProject(prev => ({ ...prev, client: e.target.value }))} />
            <input placeholder="Type" maxLength={100} value={draftProject.type} onChange={e => setDraftProject(prev => ({ ...prev, type: e.target.value }))} />
            <input placeholder="Budget" maxLength={50} value={draftProject.budget} onChange={e => setDraftProject(prev => ({ ...prev, budget: e.target.value }))} />
          </div>
          {addError && (
            <div style={{
              marginTop: 8,
              padding: "8px 12px",
              borderRadius: 8,
              fontSize: 12,
              fontWeight: 700,
              color: "var(--red)",
              background: "rgba(217,77,72,0.1)",
              border: "1px solid rgba(217,77,72,0.2)",
            }}>
              {addError}
            </div>
          )}
          <div style={{ display: "flex", gap: 8, marginTop: 10 }}>
            <button onClick={addProject} disabled={addLoading} style={{ background: addLoading ? "var(--panel)" : "var(--accent)", color: "var(--bg)", border: "none", borderRadius: 8, padding: "8px 14px", fontWeight: 800, cursor: addLoading ? "default" : "pointer", opacity: addLoading ? 0.6 : 1 }}>{addLoading ? "Saving..." : "Save Project"}</button>
            <button onClick={() => setShowAddProject(false)} style={{ background: "var(--surface)", color: "var(--muted)", border: "1px solid rgba(51,84,94,0.3)", borderRadius: 8, padding: "8px 14px", fontWeight: 800, cursor: "pointer" }}>Cancel</button>
          </div>
        </div>
      )}

      {/* Search */}
      <input aria-label="Search projects" placeholder="Search projects, clients, types..." maxLength={200} value={search} onChange={e => setSearch(e.target.value)} style={{ width: "100%", marginBottom: 12 }} />

      {isLoading && <div style={{ textAlign: "center", padding: 40, color: "var(--muted)" }}>Loading projects...</div>}
      {error && <div role="alert" style={{ textAlign: "center", padding: 16, color: "var(--red)", background: "rgba(217,77,72,0.1)", borderRadius: 10, marginBottom: 12 }}>{error}</div>}

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

      {hasMore && (
        <div style={{ textAlign: "center", padding: "20px 0" }}>
          <button
            onClick={loadMore}
            disabled={loadingMore}
            style={{
              background: "var(--accent, #FCC757)",
              color: "#0A1A2A",
              border: "none",
              borderRadius: 8,
              padding: "10px 28px",
              fontSize: 14,
              fontWeight: 700,
              cursor: loadingMore ? "wait" : "pointer",
              opacity: loadingMore ? 0.6 : 1,
            }}
          >
            {loadingMore ? "Loading..." : "Load More"}
          </button>
        </div>
      )}
    </div>
    </PremiumFeatureGate>
  );
}
