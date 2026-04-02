export default function AnalyticsPage() {
  const tabs = ["Bids", "Labor", "Risk AI"];

  const bidStats = [
    { label: "WIN RATE", value: "68%", color: "var(--green)" },
    { label: "BIDS YTD", value: "47", color: "var(--accent)" },
    { label: "PIPELINE", value: "$142M", color: "var(--gold)" },
    { label: "AVG MARKUP", value: "12.4%", color: "var(--cyan)" },
  ];

  const sectors = [
    { name: "Commercial", submitted: 18, won: 13, rate: 72 },
    { name: "Healthcare", submitted: 8, won: 6, rate: 75 },
    { name: "Industrial", submitted: 7, won: 4, rate: 57 },
    { name: "Residential", submitted: 9, won: 7, rate: 78 },
    { name: "Infrastructure", submitted: 5, won: 2, rate: 40 },
  ];

  const laborTrades = [
    { trade: "Concrete (CY/hr)", actual: 2.8, benchmark: 2.5, delta: "+12%" },
    { trade: "Framing (SF/hr)", actual: 14.2, benchmark: 12.0, delta: "+18%" },
    { trade: "Electrical (dev/hr)", actual: 3.1, benchmark: 3.5, delta: "-11%" },
    { trade: "Drywall (SF/hr)", actual: 22.5, benchmark: 20.0, delta: "+13%" },
    { trade: "Plumbing (fix/hr)", actual: 1.8, benchmark: 2.0, delta: "-10%" },
    { trade: "Painting (SF/hr)", actual: 45.0, benchmark: 40.0, delta: "+13%" },
  ];

  const risks = [
    { project: "Riverside Lofts", score: 92, factors: ["Weather delays (3x in 30d)", "Sub default risk", "Permit renewal pending"], verdict: "HIGH RISK - Schedule slip likely" },
    { project: "Harbor Crossing", score: 34, factors: ["On-time deliveries", "Strong sub performance"], verdict: "LOW RISK - On track" },
    { project: "Pine Ridge Ph.2", score: 67, factors: ["Inspection backlog", "Labor shortage trend", "Material price volatility"], verdict: "MODERATE - Monitor closely" },
  ];

  const rateColor = (r: number) => r >= 70 ? "var(--green)" : r >= 50 ? "var(--gold)" : "var(--red)";
  const riskColor = (s: number) => s >= 70 ? "var(--red)" : s >= 40 ? "var(--gold)" : "var(--green)";

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>ANALYTICS</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Business Intelligence</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Bid win/loss, labor productivity, ML-based risk scoring</p>
      </div>

      <div style={{ display: "flex", gap: 0, marginBottom: 16, borderRadius: 8, overflow: "hidden" }}>
        {tabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 10, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--accent)" : "var(--surface)", color: i === 0 ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Bid Analytics */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>BID WIN/LOSS ANALYTICS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 10, marginBottom: 16 }}>
        {bidStats.map(s => (
          <div key={s.label} style={{ textAlign: "center", padding: 12, background: `${s.color}10`, borderRadius: 10 }}>
            <div style={{ fontSize: 22, fontWeight: 900, color: s.color }}>{s.value}</div>
            <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>{s.label}</div>
          </div>
        ))}
      </div>

      {sectors.map(s => (
        <div key={s.name} style={{ display: "flex", alignItems: "center", gap: 10, marginBottom: 8, padding: "8px 0" }}>
          <span style={{ fontSize: 11, fontWeight: 800, width: 100, color: "var(--text)" }}>{s.name}</span>
          <div style={{ flex: 1, background: "rgba(51,84,94,0.3)", borderRadius: 4, height: 8 }}>
            <div style={{ background: rateColor(s.rate), borderRadius: 4, height: 8, width: `${s.rate}%` }} />
          </div>
          <span style={{ fontSize: 11, fontWeight: 900, color: rateColor(s.rate), width: 40, textAlign: "right" }}>{s.rate}%</span>
          <span style={{ fontSize: 9, fontFamily: "monospace", color: "var(--muted)", width: 35 }}>{s.won}/{s.submitted}</span>
        </div>
      ))}

      {/* Labor Productivity */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10, marginTop: 24 }}>LABOR PRODUCTIVITY</h2>
      {laborTrades.map(t => (
        <div key={t.trade} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800 }}>{t.trade}</div>
            <div style={{ fontSize: 9, color: "var(--muted)" }}>Benchmark: {t.benchmark}</div>
          </div>
          <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
            <span style={{ fontSize: 18, fontWeight: 900, color: t.actual >= t.benchmark ? "var(--green)" : "var(--red)" }}>{t.actual}</span>
            <span style={{ fontSize: 10, fontWeight: 800, color: t.delta.startsWith("+") ? "var(--green)" : "var(--red)" }}>{t.delta}</span>
          </div>
        </div>
      ))}

      {/* AI Risk Scoring */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--red)", marginBottom: 6, marginTop: 24 }}>AI RISK SCORING</h2>
      <p style={{ fontSize: 10, color: "var(--muted)", marginBottom: 12 }}>ML-based project risk prediction using historical patterns</p>
      {risks.map(r => (
        <div key={r.project} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
            <span style={{ fontSize: 13, fontWeight: 800 }}>{r.project}</span>
            <span style={{ fontSize: 16, fontWeight: 900, color: riskColor(r.score) }}>{r.score}/100</span>
          </div>
          <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginBottom: 6 }}>
            {r.factors.map(f => (
              <span key={f} style={{ fontSize: 9, padding: "3px 8px", borderRadius: 4, background: "rgba(51,84,94,0.3)", color: "var(--muted)" }}>{f}</span>
            ))}
          </div>
          <p style={{ fontSize: 10, fontWeight: 700, color: riskColor(r.score), margin: 0 }}>{r.verdict}</p>
        </div>
      ))}
    </div>
  );
}
