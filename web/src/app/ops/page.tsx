"use client";
import { useState, useEffect } from "react";
import Link from "next/link";
import PremiumFeatureGate from "@/app/components/PremiumFeatureGate";

interface Alert {
  title: string;
  detail: string;
  owner: string;
  severity: number;
  due: string;
}
interface QueueItem {
  action: string;
  team: string;
  eta: string;
  ref: string;
}
interface PanelItem {
  ref: string;
  desc: string;
  amount: string;
  status: string;
}
interface Panel {
  title: string;
  items: PanelItem[];
}

const fallbackAlerts: Alert[] = [
  { title: "Delayed conduit shipment", detail: "PO-4422 pushed from 03-13 to 03-20. Electrical rough-in impacted.", owner: "Procurement", severity: 3, due: "Today 4PM" },
  { title: "Open recordable incident", detail: "Grid B-7 fall incident corrective action still open.", owner: "Safety", severity: 3, due: "Today 1PM" },
  { title: "Pending CO over $20k", detail: "CO-003 foundation depth increase pending owner approval.", owner: "PM", severity: 2, due: "Tomorrow 10AM" },
  { title: "Inspection prep", detail: "Fire-stopping punch list has 6 unresolved tags.", owner: "Superintendent", severity: 1, due: "Tomorrow 8AM" },
];

const fallbackQueue: QueueItem[] = [
  { action: "Call Graybar and lock revised delivery truck", team: "Procurement", eta: "45m", ref: "PO-4422" },
  { action: "Submit CO-003 backup package with geotech memo", team: "PM", eta: "30m", ref: "CO-003" },
  { action: "Close scaffold harness corrective action", team: "Safety", eta: "25m", ref: "INC-03-14" },
  { action: "Notify drywall foreman of revised sequence", team: "Field Ops", eta: "15m", ref: "SEQ-DELTA" },
];

const fallbackPanels: Panel[] = [
  { title: "Change Orders", items: [
    { ref: "CO-001", desc: "Add elevator pit waterproofing", amount: "+$14,200", status: "APPROVED" },
    { ref: "CO-002", desc: "Upgrade to impact-rated windows", amount: "+$38,500", status: "PENDING" },
    { ref: "CO-003", desc: "Foundation depth increase", amount: "+$22,800", status: "SUBMITTED" },
  ]},
  { title: "Safety Incidents", items: [
    { ref: "INC-03-14", desc: "Fall from scaffold — Grid B-7", amount: "Recordable", status: "OPEN" },
    { ref: "INC-03-08", desc: "Near-miss crane swing", amount: "Near-miss", status: "CLOSED" },
    { ref: "INC-02-28", desc: "Eye injury — grinding", amount: "First Aid", status: "CLOSED" },
  ]},
  { title: "RFIs", items: [
    { ref: "RFI-042", desc: "Confirm MEP routing at grid line D-4", amount: "Structural", status: "OPEN" },
    { ref: "RFI-041", desc: "Alternate masonry detail at parapet", amount: "Arch", status: "ANSWERED" },
    { ref: "RFI-040", desc: "Confirm fire-rated assembly at shaft", amount: "Fire/Life", status: "ANSWERED" },
  ]},
];

export default function OpsPage() {
  const [alerts, setAlerts] = useState<Alert[]>(fallbackAlerts);
  const [queue] = useState<QueueItem[]>(fallbackQueue);
  const [panels, setPanels] = useState<Panel[]>(fallbackPanels);
  const [fetchError, setFetchError] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/ops")
      .then(res => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        return res.json();
      })
      .then((data: { alerts?: Record<string, unknown>[]; rfis?: Record<string, unknown>[]; changeOrders?: Record<string, unknown>[] }) => {
        if (data.alerts && data.alerts.length > 0) {
          setAlerts(data.alerts.map(a => ({
            title: (a.title as string) || "",
            detail: (a.detail as string) || (a.description as string) || "",
            owner: (a.owner as string) || "",
            severity: (a.severity as number) || 1,
            due: (a.due as string) || (a.due_date as string) || "",
          })));
        }
        const newPanels: Panel[] = [];
        if (data.changeOrders && data.changeOrders.length > 0) {
          newPanels.push({ title: "Change Orders", items: data.changeOrders.map(c => ({
            ref: (c.ref as string) || (c.id as string) || "",
            desc: (c.desc as string) || (c.description as string) || "",
            amount: (c.amount as string) || "",
            status: (c.status as string) || "",
          }))});
        }
        if (data.rfis && data.rfis.length > 0) {
          newPanels.push({ title: "RFIs", items: data.rfis.map(r => ({
            ref: (r.ref as string) || (r.id as string) || "",
            desc: (r.desc as string) || (r.description as string) || "",
            amount: (r.amount as string) || (r.category as string) || "",
            status: (r.status as string) || "",
          }))});
        }
        if (newPanels.length > 0) {
          setPanels(prev => {
            const safetyPanel = prev.find(p => p.title === "Safety Incidents");
            return safetyPanel ? [newPanels[0], safetyPanel, ...newPanels.slice(1)].filter(Boolean) : newPanels;
          });
        }
      })
      .catch((err) => { setFetchError(`Failed to load ops data: ${err.message}`); });
  }, []);

  const sevColor = (s: number) => s >= 3 ? "var(--red)" : s === 2 ? "var(--gold)" : "var(--cyan)";
  const sevLabel = (s: number) => s >= 3 ? "CRITICAL" : s === 2 ? "HIGH" : "NORMAL";
  const critCount = alerts.filter(a => a.severity >= 3).length;
  const highCount = alerts.filter(a => a.severity === 2).length;
  const todayCount = alerts.filter(a => a.due.toLowerCase().includes("today")).length;

  return (
    <PremiumFeatureGate feature="ops">
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      {fetchError && (
        <div style={{ background: "var(--surface)", border: "1px solid var(--red)", borderRadius: 10, padding: "10px 14px", marginBottom: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <span style={{ color: "var(--red)", fontSize: 12 }}>{fetchError}</span>
          <button onClick={() => setFetchError(null)} style={{ background: "none", border: "none", color: "var(--muted)", cursor: "pointer", fontSize: 14 }}>✕</button>
        </div>
      )}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16 }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--accent)" }}>OPS</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Operations Command Center</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>12-panel ops suite: change orders, safety, materials, punch list, RFIs, submittals, budget</p>
      </div>

      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {[
          { val: critCount, label: "CRITICAL", color: "var(--red)" },
          { val: highCount, label: "HIGH", color: "var(--gold)" },
          { val: todayCount, label: "DUE TODAY", color: "var(--accent)" },
          { val: queue.length, label: "QUEUE", color: "var(--cyan)" },
        ].map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
            <div style={{ fontSize: 24, fontWeight: 900, color: s.color }}>{s.val}</div>
            <div style={{ fontSize: 8, fontWeight: 800, letterSpacing: 2, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Priority Alerts */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--red)", marginBottom: 10 }}>PRIORITY ALERTS</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 20 }}>
        {alerts.map(a => (
          <div key={a.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, borderLeft: `3px solid ${sevColor(a.severity)}` }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
              <span style={{ fontSize: 12, fontWeight: 800 }}>{a.title}</span>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 8, fontWeight: 900, color: sevColor(a.severity) }}>{sevLabel(a.severity)}</span>
                <span style={{ fontSize: 9, color: "var(--gold)" }}>Due: {a.due}</span>
              </div>
            </div>
            <p style={{ fontSize: 10, color: "var(--muted)", margin: "2px 0" }}>{a.detail}</p>
            <span style={{ fontSize: 9, color: "var(--cyan)" }}>Owner: {a.owner}</span>
          </div>
        ))}
      </div>

      {/* Action Queue */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)", marginBottom: 10 }}>ACTION QUEUE</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 8, marginBottom: 20 }}>
        {queue.map(q => (
          <div key={q.ref} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div>
              <div style={{ fontSize: 11, fontWeight: 700 }}>{q.action}</div>
              <div style={{ fontSize: 9, color: "var(--muted)", marginTop: 2 }}>{q.team} &bull; Ref: {q.ref}</div>
            </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span style={{ fontSize: 10, fontWeight: 800, color: "var(--gold)" }}>ETA {q.eta}</span>
              <Link href="/login?redirect=%2Fops" style={{ background: "var(--green)", color: "var(--bg)", border: "none", borderRadius: 4, padding: "4px 10px", fontSize: 9, fontWeight: 800, cursor: "pointer", textDecoration: "none" }}>DONE</Link>
            </div>
          </div>
        ))}
      </div>

      {/* Ops Panels */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(350px, 1fr))", gap: 16 }}>
        {panels.map(panel => (
          <div key={panel.title}>
            <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>{panel.title.toUpperCase()}</h3>
            {panel.items.map(item => (
              <div key={item.ref} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div>
                  <span style={{ fontSize: 11, fontWeight: 800 }}>{item.ref}</span>
                  <span style={{ fontSize: 10, color: "var(--muted)", marginLeft: 8 }}>{item.desc}</span>
                </div>
                <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                  <span style={{ fontSize: 10, fontWeight: 800, color: "var(--accent)" }}>{item.amount}</span>
                  <span style={{ fontSize: 8, fontWeight: 900, color: item.status === "APPROVED" || item.status === "CLOSED" || item.status === "ANSWERED" ? "var(--green)" : item.status === "OPEN" ? "var(--red)" : "var(--gold)" }}>{item.status}</span>
                </div>
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
    </PremiumFeatureGate>
  );
}
