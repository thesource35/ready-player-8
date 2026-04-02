export default function FinancePage() {
  const tabs = ["Invoices", "Lien Waivers", "Cash Flow"];

  const invoices = [
    { ref: "#07", project: "Riverside Lofts", amount: "$284,500", retainage: "$28,450", status: "SUBMITTED" },
    { ref: "#06", project: "Riverside Lofts", amount: "$312,100", retainage: "$31,210", status: "APPROVED" },
    { ref: "#04", project: "Harbor Crossing", amount: "$198,750", retainage: "$19,875", status: "DRAFT" },
    { ref: "#12", project: "Pine Ridge Ph.2", amount: "$156,200", retainage: "$15,620", status: "PAID" },
  ];

  const waivers = [
    { sub: "Apex Concrete", type: "Conditional Progress", amount: "$48,200", status: "RECEIVED", due: "Apr 1" },
    { sub: "Elite Steel", type: "Conditional Progress", amount: "$32,100", status: "PENDING", due: "Apr 1" },
    { sub: "Prime Electric", type: "Unconditional", amount: "$15,800", status: "RECEIVED", due: "N/A" },
    { sub: "Quick Plumbing", type: "Conditional Final", amount: "$22,400", status: "REQUESTED", due: "Apr 15" },
  ];

  const cashFlow = [
    { month: "Apr", ar: 485000, ap: 342000 },
    { month: "May", ar: 520000, ap: 398000 },
    { month: "Jun", ar: 610000, ap: 445000 },
    { month: "Jul", ar: 475000, ap: 380000 },
  ];

  const statusColor = (s: string) => s === "PAID" ? "var(--green)" : s === "APPROVED" ? "var(--cyan)" : s === "SUBMITTED" ? "var(--gold)" : "var(--muted)";

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(105,210,148,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--green)" }}>FINANCE HUB</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Financial Command Center</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>AIA pay apps, lien waivers, cash flow forecasting</p>
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--green)" : "var(--surface)", color: i === 0 ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Invoices */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>AIA G702/G703 PAY APPLICATIONS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 10, marginBottom: 16 }}>
        <div style={{ textAlign: "center", padding: 14, background: "rgba(242,158,61,0.06)", borderRadius: 10 }}>
          <div style={{ fontSize: 24, fontWeight: 900, color: "var(--accent)" }}>$952K</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>BILLED</div>
        </div>
        <div style={{ textAlign: "center", padding: 14, background: "rgba(252,199,87,0.06)", borderRadius: 10 }}>
          <div style={{ fontSize: 24, fontWeight: 900, color: "var(--gold)" }}>$95K</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>RETAINAGE</div>
        </div>
      </div>

      {invoices.map(inv => (
        <div key={inv.ref} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <span style={{ fontSize: 12, fontWeight: 800 }}>Pay App {inv.ref}</span>
            <span style={{ fontSize: 10, color: "var(--muted)", marginLeft: 8 }}>{inv.project}</span>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 12, fontWeight: 900, color: "var(--accent)" }}>{inv.amount}</div>
              <div style={{ fontSize: 8, color: "var(--gold)" }}>Ret: {inv.retainage}</div>
            </div>
            <span style={{ fontSize: 8, fontWeight: 900, color: statusColor(inv.status), background: `${statusColor(inv.status)}15`, padding: "3px 8px", borderRadius: 4 }}>{inv.status}</span>
          </div>
        </div>
      ))}

      {/* Lien Waivers */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--purple)", marginBottom: 10, marginTop: 20 }}>LIEN WAIVER MANAGER</h2>
      {waivers.map(w => (
        <div key={w.sub} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            <div style={{ width: 8, height: 8, borderRadius: "50%", background: w.status === "RECEIVED" ? "var(--green)" : "var(--gold)" }} />
            <div>
              <div style={{ fontSize: 11, fontWeight: 800 }}>{w.sub}</div>
              <div style={{ fontSize: 9, color: "var(--muted)" }}>{w.type} &bull; {w.amount}</div>
            </div>
          </div>
          <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
            {w.due !== "N/A" && <span style={{ fontSize: 9, fontWeight: 800, color: "var(--gold)" }}>Due: {w.due}</span>}
            <span style={{ fontSize: 8, fontWeight: 900, color: w.status === "RECEIVED" ? "var(--green)" : "var(--gold)" }}>{w.status}</span>
          </div>
        </div>
      ))}

      {/* Cash Flow */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10, marginTop: 20 }}>CASH FLOW FORECAST</h2>
      {cashFlow.map(m => (
        <div key={m.month} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <span style={{ fontSize: 13, fontWeight: 800 }}>{m.month}</span>
            <span style={{ fontSize: 13, fontWeight: 900, color: "var(--green)" }}>+${Math.round((m.ar - m.ap) / 1000)}K</span>
          </div>
          <div style={{ display: "flex", gap: 16, fontSize: 10 }}>
            <span style={{ color: "var(--green)" }}>AR: ${Math.round(m.ar / 1000)}K</span>
            <span style={{ color: "var(--red)" }}>AP: ${Math.round(m.ap / 1000)}K</span>
          </div>
          <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 6, marginTop: 6 }}>
            <div style={{ background: "var(--green)", borderRadius: 3, height: 6, width: `${Math.round((m.ar / (m.ar + m.ap)) * 100)}%` }} />
          </div>
        </div>
      ))}
    </div>
  );
}
