"use client";
import { useState, useEffect } from "react";

const priorities = { critical: { color: "#D94D48", label: "CRITICAL" }, high: { color: "#FCC757", label: "HIGH" }, medium: { color: "#4AC4CC", label: "MEDIUM" }, low: { color: "#9EBDC2", label: "LOW" } };
const categories = ["all", "ops", "finance", "procurement", "compliance", "permits", "safety", "bids", "schedule"];
type Priority = "critical" | "high" | "medium" | "low";

const initialTodos = [
  { id: "1", title: "Submit CO-003 backup package", desc: "Foundation depth increase — need geotech memo attached", priority: "high" as Priority, status: "pending", category: "ops", project: "Pine Ridge Ph.2", due: "Apr 2", time: "10:00 AM" },
  { id: "2", title: "Follow up on Pay App #07", desc: "Metro Development — $284,500 submitted, awaiting approval", priority: "high" as Priority, status: "pending", category: "finance", project: "Riverside Lofts", due: "Apr 3", time: "2:00 PM" },
  { id: "3", title: "Order conduit for electrical rough-in", desc: "PO-4422 replacement — Graybar quote pending", priority: "critical" as Priority, status: "in_progress", category: "procurement", project: "Harbor Crossing", due: "Apr 2", time: "4:00 PM" },
  { id: "4", title: "Schedule fire-stopping inspection", desc: "6 unresolved tags on punch list need closure first", priority: "medium" as Priority, status: "pending", category: "compliance", project: "Riverside Lofts", due: "Apr 4", time: "8:00 AM" },
  { id: "5", title: "Renew grading permit GP-2026-0782", desc: "Expires Jun 1 — City of Houston requires 30-day lead time", priority: "high" as Priority, status: "pending", category: "permits", project: "Pine Ridge Ph.2", due: "Apr 15", time: "" },
  { id: "6", title: "Weekly toolbox talk — Fall Protection", desc: "Required OSHA topic — harness inspection focus", priority: "medium" as Priority, status: "pending", category: "safety", project: "", due: "Apr 3", time: "6:30 AM" },
  { id: "7", title: "Review bid package for Houston Medical", desc: "Score 94 — deadline Apr 15. Need to finalize pricing.", priority: "critical" as Priority, status: "in_progress", category: "bids", project: "Houston Medical Complex", due: "Apr 10", time: "" },
  { id: "8", title: "Update Skyline Tower schedule", desc: "Steel erection starting Week 14 — confirm crane availability", priority: "medium" as Priority, status: "pending", category: "schedule", project: "Skyline Tower", due: "Apr 5", time: "9:00 AM" },
];

const events = [
  { title: "OAC Meeting — Riverside Lofts", type: "meeting", date: "Apr 3", start: "10:00 AM", end: "11:30 AM", location: "Riverside Lofts Trailer", color: "#F29E3D" },
  { title: "Concrete Pour — Level 3 Deck", type: "milestone", date: "Apr 4", start: "6:00 AM", end: "2:00 PM", location: "Riverside Lofts", color: "#4AC4CC" },
  { title: "Safety Walk — All Sites", type: "inspection", date: "Apr 3", start: "7:00 AM", end: "12:00 PM", location: "All Sites", color: "#D94D48" },
  { title: "Bid Due — Houston Medical", type: "deadline", date: "Apr 15", start: "5:00 PM", end: "", location: "Online", color: "#FCC757" },
  { title: "Steel Delivery — Skyline Tower", type: "delivery", date: "Apr 7", start: "6:30 AM", end: "8:00 AM", location: "Skyline Tower", color: "#69D294" },
  { title: "Sub Coordination — Harbor", type: "meeting", date: "Apr 4", start: "2:00 PM", end: "3:30 PM", location: "Harbor Crossing", color: "#8A8FCC" },
];

const aiReminders = [
  { icon: "🔴", title: "Equipment Service Due", message: "Bobcat S770 (EQ-008) needs service in 40 hours. Schedule before it goes down on Pine Ridge.", time: "Now" },
  { icon: "💰", title: "Pay App Follow-up", message: "Metro Development hasn't responded to your $284,500 pay app in 5 days. Follow up today.", time: "9:00 AM" },
  { icon: "📋", title: "Bid Deadline — 13 Days", message: "Houston Medical Complex ($18.2M, score 94) is due Apr 15. Finalize pricing this week.", time: "10:00 AM" },
  { icon: "🛡", title: "Toolbox Talk Due", message: "Weekly Fall Protection talk is required. 6 of 8 OSHA topics still needed this month.", time: "3:00 PM" },
  { icon: "📄", title: "Permit Renewal — 30 Day Warning", message: "Grading permit GP-2026-0782 expires Jun 1. Start renewal NOW.", time: "Tomorrow" },
];

const aiSuggestions = [
  { icon: "💡", suggestion: "Move CO-003 before the concrete pour — if foundation change isn't approved, the pour may need redesign.", action: "Reprioritize CO-003" },
  { icon: "📊", suggestion: "Houston Medical bid (score 94) is your strongest opportunity. Dedicate 2 hours today to pricing.", action: "Block time for bid" },
  { icon: "👥", suggestion: "Harbor Crossing has 18 crew but only 1 delivery. Move 4 crew to Pine Ridge to recover the delay.", action: "Reassign crew" },
  { icon: "💰", suggestion: "3 invoices totaling $639K are outstanding. Factor the Riverside pay app for same-day cash.", action: "View Capital options" },
];

export default function TasksPage() {
  const [activeTab, setActiveTab] = useState(0);
  const [filter, setFilter] = useState("all");
  const [todos, setTodos] = useState(initialTodos);
  const [dismissedReminders, setDismissedReminders] = useState<Set<number>>(new Set());
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);

  const mapTodo = (t: Record<string, unknown>, i: number) => ({
    id: (t.id as string) || String(i + 1),
    title: (t.title as string) || "",
    desc: (t.desc as string) || (t.description as string) || "",
    priority: ((t.priority as string) || "medium") as Priority,
    status: (t.status as string) || "pending",
    category: (t.category as string) || "ops",
    project: (t.project as string) || "",
    due: (t.due as string) || (t.due_date as string) || "",
    time: (t.time as string) || "",
  });

  useEffect(() => {
    fetch("/api/tasks?page=0")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data: { todos?: Record<string, unknown>[]; events?: Record<string, unknown>[]; reminders?: Record<string, unknown>[]; hasMore?: boolean }) => {
        if (data.todos && Array.isArray(data.todos) && data.todos.length > 0) {
          setTodos(data.todos.map(mapTodo));
        }
        setHasMore(data.hasMore || false);
      })
      .catch((err) => { setFetchError(`Failed to load tasks: ${err.message}`); })
      .finally(() => { setLoading(false); });
  }, []);

  const loadMore = async () => {
    setLoadingMore(true);
    try {
      const nextPage = page + 1;
      const res = await fetch(`/api/tasks?page=${nextPage}`);
      const data = await res.json();
      if (data.todos && Array.isArray(data.todos)) {
        setTodos(prev => [...prev, ...data.todos.map(mapTodo)]);
      }
      setHasMore(data.hasMore || false);
      setPage(nextPage);
    } catch {
      // Silently fail — user can retry
    } finally {
      setLoadingMore(false);
    }
  };
  const tabs = ["Tasks", "Schedule", "AI Reminders"];

  const filteredTodos = filter === "all" ? todos : todos.filter(t => t.category === filter);
  const pendingCount = todos.filter(t => t.status === "pending").length;
  const criticalCount = todos.filter(t => t.priority === "critical").length;
  const todayCount = todos.filter(t => t.due === "Apr 2").length;

  const toggleTodo = (id: string) => {
    setTodos(prev => prev.map(t => t.id === id ? { ...t, status: t.status === "done" ? "pending" : "done" } : t));
  };

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
    <div style={{ padding: 20, maxWidth: 1000, margin: "0 auto" }}>
      {fetchError && (
        <div style={{ background: "var(--surface)", border: "1px solid var(--red)", borderRadius: 10, padding: "10px 14px", marginBottom: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ color: "var(--red)", fontSize: 12 }}>{fetchError}</span>
          <button onClick={() => setFetchError(null)} aria-label="Dismiss error" style={{ background: "none", border: "none", color: "var(--muted)", cursor: "pointer", fontSize: 14 }}>✕</button>
        </div>
      )}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>TASK CENTER</div>
            <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>AI Task Manager</h1>
            <p style={{ fontSize: 12, color: "var(--muted)" }}>Todos, schedule, and AI-powered reminders</p>
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            {[{ val: criticalCount, label: "CRITICAL", color: "var(--red)" }, { val: todayCount, label: "DUE TODAY", color: "var(--gold)" }, { val: pendingCount, label: "PENDING", color: "var(--cyan)" }].map(s => (
              <div key={s.label} style={{ textAlign: "center", padding: "6px 14px", background: `${s.color}15`, borderRadius: 8 }}>
                <div style={{ fontSize: 18, fontWeight: 900, color: s.color }}>{s.val}</div>
                <div style={{ fontSize: 7, color: "var(--muted)" }}>{s.label}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} onClick={() => setActiveTab(i)} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: activeTab === i ? "var(--accent)" : "var(--surface)", color: activeTab === i ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>
            {t.toUpperCase()}
            {i === 2 && dismissedReminders.size < aiReminders.length && <span style={{ display: "inline-block", width: 6, height: 6, borderRadius: "50%", background: "var(--red)", marginLeft: 4, verticalAlign: "middle" }} />}
          </div>
        ))}
      </div>

      {activeTab === 0 && (
        <>
          <div style={{ display: "flex", gap: 4, marginBottom: 12, flexWrap: "wrap" }}>
            {categories.map(c => (
              <span key={c} onClick={() => setFilter(c)} style={{ fontSize: 9, fontWeight: 700, padding: "4px 10px", borderRadius: 6, background: filter === c ? "var(--accent)" : "var(--surface)", color: filter === c ? "var(--bg)" : "var(--muted)", cursor: "pointer", textTransform: "uppercase" }}>{c}</span>
            ))}
          </div>
          {filteredTodos.map(t => (
            <div key={t.id} onClick={() => toggleTodo(t.id)} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 6, borderLeft: `3px solid ${priorities[t.priority].color}`, cursor: "pointer", opacity: t.status === "done" ? 0.5 : 1 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                  <div style={{ width: 20, height: 20, borderRadius: 4, border: `2px solid ${t.status === "done" ? "var(--green)" : "var(--border)"}`, background: t.status === "done" ? "var(--green)" : "transparent", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, color: "white", flexShrink: 0, marginTop: 2 }}>{t.status === "done" ? "✓" : ""}</div>
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 800, textDecoration: t.status === "done" ? "line-through" : "none" }}>{t.title}</div>
                    <div style={{ fontSize: 10, color: "var(--muted)", marginTop: 2 }}>{t.desc}</div>
                    <div style={{ display: "flex", gap: 8, marginTop: 4, fontSize: 9 }}>
                      {t.project && <span style={{ color: "var(--cyan)" }}>{t.project}</span>}
                      <span style={{ color: "var(--muted)" }}>{t.category}</span>
                    </div>
                  </div>
                </div>
                <div style={{ textAlign: "right", flexShrink: 0 }}>
                  <span style={{ fontSize: 8, fontWeight: 900, color: priorities[t.priority].color }}>{priorities[t.priority].label}</span>
                  <div style={{ fontSize: 9, color: "var(--gold)", marginTop: 2 }}>{t.due}</div>
                  {t.time && <div style={{ fontSize: 8, color: "var(--muted)" }}>{t.time}</div>}
                </div>
              </div>
            </div>
          ))}

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
        </>
      )}

      {activeTab === 1 && (
        <>
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>UPCOMING EVENTS</h3>
          {events.map(e => (
            <div key={e.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, borderLeft: `3px solid ${e.color}` }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 800 }}>{e.title}</div>
                  <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginTop: 4 }}>
                    <span style={{ fontWeight: 800, color: e.color }}>{e.date}</span>
                    <span>{e.start}{e.end ? ` — ${e.end}` : ""}</span>
                    <span>{e.location}</span>
                  </div>
                </div>
                <span style={{ fontSize: 8, fontWeight: 900, color: e.color, background: `${e.color}15`, padding: "3px 8px", borderRadius: 4 }}>{e.type.toUpperCase()}</span>
              </div>
            </div>
          ))}
        </>
      )}

      {activeTab === 2 && (
        <>
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--red)", marginBottom: 10 }}>AI REMINDERS</h3>
          {aiReminders.map((r, i) => !dismissedReminders.has(i) && (
            <div key={i} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, borderLeft: "3px solid var(--gold)" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                  <span style={{ fontSize: 20 }}>{r.icon}</span>
                  <div>
                    <div style={{ fontSize: 12, fontWeight: 800 }}>{r.title}</div>
                    <p style={{ fontSize: 11, color: "var(--text)", margin: "4px 0" }}>{r.message}</p>
                    <span style={{ fontSize: 8, fontWeight: 800, color: "var(--gold)" }}>{r.time}</span>
                  </div>
                </div>
                <button onClick={() => setDismissedReminders(prev => new Set(prev).add(i))} aria-label="Dismiss reminder" style={{ background: "none", border: "none", color: "var(--muted)", fontSize: 14, cursor: "pointer" }}>✕</button>
              </div>
            </div>
          ))}
          <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10, marginTop: 20 }}>AI SUGGESTIONS</h3>
          {aiSuggestions.map((s, i) => (
            <div key={i} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8, border: "1px solid rgba(74,196,204,0.1)" }}>
              <div style={{ display: "flex", gap: 10, alignItems: "flex-start" }}>
                <span style={{ fontSize: 20 }}>{s.icon}</span>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 11, color: "var(--text)", margin: "0 0 8px" }}>{s.suggestion}</p>
                  <button style={{ background: "var(--cyan)", color: "var(--bg)", border: "none", borderRadius: 6, padding: "5px 12px", fontSize: 9, fontWeight: 800, cursor: "pointer" }}>{s.action}</button>
                </div>
              </div>
            </div>
          ))}
        </>
      )}
    </div>
  );
}
