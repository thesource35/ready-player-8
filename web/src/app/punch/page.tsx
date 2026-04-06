"use client";
import { useState, useEffect } from "react";

interface PunchItem {
  id: string;
  description: string;
  location: string;
  trade: string;
  priority: string;
  status: string;
  assignee: string;
  dueDate: string;
  photos: number;
}

const fallbackItems: PunchItem[] = [
  { id: "PL-001", description: "Touch-up paint at stairwell B-2, scuff marks on east wall", location: "Building A, Level 2", trade: "Painting", priority: "HIGH", status: "OPEN", assignee: "Carlos M.", dueDate: "Apr 2", photos: 3 },
  { id: "PL-002", description: "HVAC diffuser not aligned in conference room 204", location: "Building A, Level 2", trade: "HVAC", priority: "MEDIUM", status: "IN PROGRESS", assignee: "HVAC Team", dueDate: "Apr 3", photos: 2 },
  { id: "PL-003", description: "Door hardware loose on suite 310 entry", location: "Building A, Level 3", trade: "Finish Carpentry", priority: "HIGH", status: "OPEN", assignee: "James W.", dueDate: "Apr 1", photos: 1 },
  { id: "PL-004", description: "Caulk gap at window frame, unit 405", location: "Building B, Level 4", trade: "Exterior", priority: "CRITICAL", status: "OPEN", assignee: "Exterior Crew", dueDate: "Mar 31", photos: 4 },
  { id: "PL-005", description: "Floor tile grout color mismatch — lobby east wing", location: "Building A, Level 1", trade: "Tile", priority: "MEDIUM", status: "COMPLETE", assignee: "Tile Sub", dueDate: "Mar 28", photos: 5 },
  { id: "PL-006", description: "Electrical outlet cover plate missing, hallway 2F", location: "Building A, Level 2", trade: "Electrical", priority: "LOW", status: "OPEN", assignee: "Prime Electric", dueDate: "Apr 5", photos: 1 },
  { id: "PL-007", description: "Fire caulking incomplete at penetration, shaft 3", location: "Building B, Level 3", trade: "Fire/Life Safety", priority: "CRITICAL", status: "IN PROGRESS", assignee: "FireSafe", dueDate: "Apr 1", photos: 2 },
  { id: "PL-008", description: "Drywall nail pop — corridor 4A", location: "Building B, Level 4", trade: "Drywall", priority: "LOW", status: "COMPLETE", assignee: "Drywall Crew", dueDate: "Mar 29", photos: 1 },
];

export default function PunchPage() {
  const [items, setItems] = useState<PunchItem[]>(fallbackItems);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/punch")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data: Record<string, unknown>[]) => {
        if (Array.isArray(data) && data.length > 0) {
          setItems(data.map((p, i) => ({
            id: (p.id as string) || `PL-${String(i + 1).padStart(3, "0")}`,
            description: (p.description as string) || "",
            location: (p.location as string) || "",
            trade: (p.trade as string) || "",
            priority: (p.priority as string) || "MEDIUM",
            status: (p.status as string) || "OPEN",
            assignee: (p.assignee as string) || "",
            dueDate: (p.dueDate as string) || (p.due_date as string) || "",
            photos: (p.photos as number) || (p.photo_count as number) || 0,
          })));
        }
      })
      .catch((err) => { setFetchError(`Failed to load punch items: ${err.message}`); })
      .finally(() => { setLoading(false); });
  }, []);

  const open = items.filter(i => i.status === "OPEN").length;
  const inProgress = items.filter(i => i.status === "IN PROGRESS").length;
  const complete = items.filter(i => i.status === "COMPLETE").length;
  const critical = items.filter(i => i.priority === "CRITICAL").length;

  const prioColor = (p: string) => p === "CRITICAL" ? "var(--red)" : p === "HIGH" ? "var(--gold)" : p === "MEDIUM" ? "var(--cyan)" : "var(--muted)";
  const statusColor = (s: string) => s === "COMPLETE" ? "var(--green)" : s === "IN PROGRESS" ? "var(--cyan)" : "var(--gold)";

  if (loading) {
    return (
      <div style={{ minHeight: "40vh", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <div style={{ fontSize: 10, fontWeight: 900, letterSpacing: "0.2em", color: "var(--accent)" }}>
          LOADING...
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      {fetchError && (
        <div style={{ background: "var(--surface)", border: "1px solid var(--red)", borderRadius: 10, padding: "10px 14px", marginBottom: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ color: "var(--red)", fontSize: 12 }}>{fetchError}</span>
          <button onClick={() => setFetchError(null)} style={{ background: "none", border: "none", color: "var(--muted)", cursor: "pointer", fontSize: 14 }}>✕</button>
        </div>
      )}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(105,210,148,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--green)" }}>PUNCH LIST PRO</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Construction Punch List</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Track, assign, and close out punch items with photo documentation</p>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: open, label: "OPEN", color: "var(--gold)" },
          { val: inProgress, label: "IN PROGRESS", color: "var(--cyan)" },
          { val: complete, label: "COMPLETE", color: "var(--green)" },
          { val: critical, label: "CRITICAL", color: "var(--red)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {items.map(item => (
        <div key={item.id} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, borderLeft: `3px solid ${prioColor(item.priority)}` }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: 6 }}>
            <div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 10, fontWeight: 900, color: "var(--accent)", fontFamily: "monospace" }}>{item.id}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: prioColor(item.priority) }}>{item.priority}</span>
              </div>
              <p style={{ fontSize: 12, fontWeight: 700, margin: "4px 0 2px" }}>{item.description}</p>
            </div>
            <span style={{ fontSize: 8, fontWeight: 900, color: statusColor(item.status), background: `${statusColor(item.status)}15`, padding: "3px 8px", borderRadius: 4, whiteSpace: "nowrap" }}>{item.status}</span>
          </div>
          <div style={{ display: "flex", gap: 14, fontSize: 9, color: "var(--muted)" }}>
            <span>{item.location}</span>
            <span style={{ color: "var(--cyan)" }}>{item.trade}</span>
            <span>Assigned: {item.assignee}</span>
            <span>Due: {item.dueDate}</span>
            <span>{item.photos} photos</span>
          </div>
        </div>
      ))}
    </div>
  );
}
