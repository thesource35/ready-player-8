export default function WealthPage() {
  const subTabs = ["Money Lens", "Psychology", "Power Thinking", "Leverage", "Opportunity"];

  // Money Lens data
  const principles = [
    { title: "The 10X Rule", source: "Grant Cardone", insight: "Set targets 10X what you think you need, then take 10X the action.", category: "Mindset" },
    { title: "Compounding Capital", source: "Warren Buffett", insight: "Never interrupt compounding. Reinvest profits into assets that generate more capital.", category: "Finance" },
    { title: "Leverage Other People's Time", source: "Robert Kiyosaki", insight: "Build systems and hire teams so your income isn't tied to your hours.", category: "Leverage" },
    { title: "First Principles Thinking", source: "Elon Musk", insight: "Break problems down to fundamental truths and build up from there.", category: "Strategy" },
    { title: "Own the Platform", source: "Jay-Z", insight: "Don't just participate in markets — own the infrastructure.", category: "Empire" },
  ];

  const wealthTracking = [
    { category: "Business Revenue", value: "$4.2M", change: "+18%", color: "var(--green)" },
    { category: "Real Estate Equity", value: "$1.8M", change: "+12%", color: "var(--accent)" },
    { category: "Investments", value: "$620K", change: "+8%", color: "var(--cyan)" },
    { category: "Cash Reserves", value: "$340K", change: "+5%", color: "var(--gold)" },
    { category: "Equipment Assets", value: "$85K", change: "+12%", color: "var(--purple)" },
  ];

  // Psychology Decoder data
  const mindsetQuestions = [
    "I actively seek out uncomfortable situations for growth",
    "I believe I deserve to build generational wealth",
    "I see every problem as a revenue opportunity",
    "I invest in myself before anything else",
    "I think in decades, not days",
  ];

  const archetypes = [
    { name: "Builder", score: 92, desc: "Creates enterprises from the ground up", color: "var(--accent)" },
    { name: "Strategist", score: 78, desc: "Sees the board 10 moves ahead", color: "var(--cyan)" },
    { name: "Connector", score: 85, desc: "Builds empire through relationships", color: "var(--gold)" },
    { name: "Visionary", score: 88, desc: "Shapes industries others haven't imagined", color: "var(--green)" },
  ];

  // Leverage System data
  const leverageCategories = [
    { name: "Financial Capital", score: 72, icon: "💰", desc: "Access to capital, credit lines, and investment capacity" },
    { name: "Human Capital", score: 85, icon: "👥", desc: "Team quality, talent pipeline, and organizational leverage" },
    { name: "Intellectual Capital", score: 68, icon: "🧠", desc: "Patents, processes, proprietary knowledge, and systems" },
    { name: "Social Capital", score: 90, icon: "🤝", desc: "Network reach, reputation, and relationship leverage" },
    { name: "Digital Capital", score: 55, icon: "💻", desc: "Technology, automation, data, and digital infrastructure" },
  ];

  // Opportunity Filter data
  const opportunities = [
    { name: "Houston Medical Complex Bid", score: 94, roi: "22%", timeframe: "18 months", risk: "LOW", capital: "$2.2M" },
    { name: "Multifamily Development — Katy", score: 87, roi: "35%", timeframe: "24 months", risk: "MEDIUM", capital: "$4.5M" },
    { name: "Equipment Rental Expansion", score: 82, roi: "28%", timeframe: "12 months", risk: "LOW", capital: "$800K" },
  ];

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(252,199,87,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)" }}>WEALTH SUITE</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Wealth Intelligence System</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Think like Mansa Musa and Elon Musk combined</p>
      </div>

      {/* Sub-tabs */}
      <div style={{ display: "flex", gap: 0, marginBottom: 20, borderRadius: 8, overflow: "hidden" }}>
        {subTabs.map((t, i) => (
          <div key={t} style={{ flex: 1, textAlign: "center", padding: "9px 0", fontSize: 9, fontWeight: 800, letterSpacing: 1, background: i === 0 ? "var(--gold)" : "var(--surface)", color: i === 0 ? "var(--bg)" : "var(--muted)", cursor: "pointer" }}>{t.toUpperCase()}</div>
        ))}
      </div>

      {/* Money Lens Section */}
      <h2 style={{ fontSize: 12, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 12 }}>💎 BILLIONAIRE MONEY LENS</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: 10, marginBottom: 20 }}>
        {wealthTracking.map(w => (
          <div key={w.category} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontSize: 12, fontWeight: 700 }}>{w.category}</span>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 18, fontWeight: 900, color: w.color }}>{w.value}</div>
              <div style={{ fontSize: 10, fontWeight: 800, color: "var(--green)" }}>{w.change}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Principles */}
      <h3 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--accent)", marginBottom: 10 }}>WEALTH PRINCIPLES</h3>
      {principles.map(p => (
        <div key={p.title} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, marginBottom: 8 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
            <span style={{ fontSize: 13, fontWeight: 800 }}>{p.title}</span>
            <span style={{ fontSize: 8, fontWeight: 800, color: "var(--cyan)", background: "rgba(74,196,204,0.1)", padding: "2px 8px", borderRadius: 4 }}>{p.category}</span>
          </div>
          <p style={{ fontSize: 11, color: "var(--text)", margin: "4px 0" }}>{p.insight}</p>
          <span style={{ fontSize: 9, color: "var(--gold)" }}>— {p.source}</span>
        </div>
      ))}

      {/* Psychology Decoder */}
      <h2 style={{ fontSize: 12, fontWeight: 800, letterSpacing: 2, color: "var(--purple)", marginBottom: 12, marginTop: 28 }}>🧠 PSYCHOLOGY DECODER</h2>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>
        <div>
          <h3 style={{ fontSize: 10, fontWeight: 800, color: "var(--accent)", marginBottom: 8 }}>WEALTH ARCHETYPES</h3>
          {archetypes.map(a => (
            <div key={a.name} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 4 }}>
                <span style={{ fontSize: 12, fontWeight: 800 }}>{a.name}</span>
                <span style={{ fontSize: 16, fontWeight: 900, color: a.color }}>{a.score}</span>
              </div>
              <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 4, marginBottom: 4 }}>
                <div style={{ background: a.color, borderRadius: 3, height: 4, width: `${a.score}%` }} />
              </div>
              <span style={{ fontSize: 9, color: "var(--muted)" }}>{a.desc}</span>
            </div>
          ))}
        </div>
        <div>
          <h3 style={{ fontSize: 10, fontWeight: 800, color: "var(--gold)", marginBottom: 8 }}>MINDSET ASSESSMENT</h3>
          {mindsetQuestions.map((q, i) => (
            <div key={i} style={{ background: "var(--surface)", borderRadius: 8, padding: 10, marginBottom: 6, display: "flex", gap: 8, alignItems: "center" }}>
              <span style={{ fontSize: 12, fontWeight: 900, color: "var(--gold)", width: 20 }}>{i + 1}</span>
              <span style={{ fontSize: 10 }}>{q}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Leverage System */}
      <h2 style={{ fontSize: 12, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 12 }}>⚡ LEVERAGE SYSTEM</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(200px, 1fr))", gap: 10, marginBottom: 20 }}>
        {leverageCategories.map(l => (
          <div key={l.name} style={{ background: "var(--surface)", borderRadius: 12, padding: 16, textAlign: "center" }}>
            <div style={{ fontSize: 28, marginBottom: 6 }}>{l.icon}</div>
            <div style={{ fontSize: 11, fontWeight: 800, marginBottom: 4 }}>{l.name}</div>
            <div style={{ fontSize: 28, fontWeight: 900, color: l.score >= 80 ? "var(--green)" : l.score >= 60 ? "var(--gold)" : "var(--red)", marginBottom: 4 }}>{l.score}</div>
            <div style={{ background: "rgba(51,84,94,0.3)", borderRadius: 3, height: 4, marginBottom: 6 }}>
              <div style={{ background: l.score >= 80 ? "var(--green)" : l.score >= 60 ? "var(--gold)" : "var(--red)", borderRadius: 3, height: 4, width: `${l.score}%` }} />
            </div>
            <p style={{ fontSize: 8, color: "var(--muted)", margin: 0 }}>{l.desc}</p>
          </div>
        ))}
      </div>

      {/* Opportunity Filter */}
      <h2 style={{ fontSize: 12, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 12 }}>🎯 OPPORTUNITY FILTER</h2>
      {opportunities.map(o => (
        <div key={o.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 16, marginBottom: 10 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
            <span style={{ fontSize: 14, fontWeight: 800 }}>{o.name}</span>
            <span style={{ fontSize: 22, fontWeight: 900, color: "var(--green)" }}>{o.score}</span>
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
            <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--accent)" }}>{o.roi}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>ROI</div></div>
            <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--cyan)" }}>{o.timeframe}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>TIMEFRAME</div></div>
            <div><div style={{ fontSize: 14, fontWeight: 900, color: o.risk === "LOW" ? "var(--green)" : "var(--gold)" }}>{o.risk}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>RISK</div></div>
            <div><div style={{ fontSize: 14, fontWeight: 900, color: "var(--gold)" }}>{o.capital}</div><div style={{ fontSize: 7, color: "var(--muted)" }}>CAPITAL REQ</div></div>
          </div>
        </div>
      ))}
    </div>
  );
}
