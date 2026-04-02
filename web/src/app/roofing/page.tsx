export default function RoofingPage() {
  const materials = [
    { name: "Asphalt Shingles (3-Tab)", pricePerSF: 3.50, lifespan: "20-25 yrs", warranty: "25 yrs", rating: "Good", weight: "2.5 lbs/SF" },
    { name: "Architectural Shingles", pricePerSF: 4.25, lifespan: "30 yrs", warranty: "30 yrs", rating: "Better", weight: "3.5 lbs/SF" },
    { name: "Standing Seam Metal", pricePerSF: 8.50, lifespan: "40-60 yrs", warranty: "40 yrs", rating: "Premium", weight: "1.5 lbs/SF" },
    { name: "TPO Membrane", pricePerSF: 5.75, lifespan: "25-30 yrs", warranty: "20 yrs", rating: "Commercial", weight: "0.5 lbs/SF" },
    { name: "EPDM Rubber", pricePerSF: 4.50, lifespan: "25-30 yrs", warranty: "15 yrs", rating: "Commercial", weight: "0.4 lbs/SF" },
    { name: "Clay Tile", pricePerSF: 12.00, lifespan: "50-100 yrs", warranty: "50 yrs", rating: "Premium", weight: "9.5 lbs/SF" },
    { name: "Slate", pricePerSF: 18.00, lifespan: "75-150 yrs", warranty: "75 yrs", rating: "Luxury", weight: "10 lbs/SF" },
    { name: "Built-Up (BUR)", pricePerSF: 6.25, lifespan: "20-30 yrs", warranty: "20 yrs", rating: "Commercial", weight: "2.0 lbs/SF" },
    { name: "Modified Bitumen", pricePerSF: 5.00, lifespan: "20-30 yrs", warranty: "20 yrs", rating: "Commercial", weight: "1.5 lbs/SF" },
  ];

  const pitches = [
    { ratio: "1:12", degrees: "4.8°", type: "Flat", multiplier: 1.00 },
    { ratio: "3:12", degrees: "14.0°", type: "Low Slope", multiplier: 1.03 },
    { ratio: "6:12", degrees: "26.6°", type: "Standard", multiplier: 1.12 },
    { ratio: "9:12", degrees: "36.9°", type: "Steep", multiplier: 1.25 },
    { ratio: "12:12", degrees: "45.0°", type: "Very Steep", multiplier: 1.41 },
  ];

  const demoEstimate = {
    roofArea: 2400,
    material: "Architectural Shingles",
    pitch: "6:12",
    materialCost: 10200,
    laborCost: 6000,
    tearOff: 2400,
    permits: 450,
    dumpster: 600,
    total: 19650,
  };

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)" }}>SATELLITE ROOFING</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>AI Roof Estimator</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>9 materials, pitch calculator, full cost breakdown with satellite measurement</p>
      </div>

      {/* Demo Estimate */}
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 20, border: "1px solid rgba(105,210,148,0.08)" }}>
        <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--green)", marginBottom: 12 }}>SAMPLE ESTIMATE</h2>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 12 }}>
          <div style={{ textAlign: "center", padding: 10, background: "rgba(242,158,61,0.06)", borderRadius: 8 }}>
            <div style={{ fontSize: 20, fontWeight: 900, color: "var(--accent)" }}>{demoEstimate.roofArea} SF</div>
            <div style={{ fontSize: 8, color: "var(--muted)" }}>ROOF AREA</div>
          </div>
          <div style={{ textAlign: "center", padding: 10, background: "rgba(74,196,204,0.06)", borderRadius: 8 }}>
            <div style={{ fontSize: 20, fontWeight: 900, color: "var(--cyan)" }}>{demoEstimate.pitch}</div>
            <div style={{ fontSize: 8, color: "var(--muted)" }}>PITCH</div>
          </div>
          <div style={{ textAlign: "center", padding: 10, background: "rgba(105,210,148,0.06)", borderRadius: 8 }}>
            <div style={{ fontSize: 20, fontWeight: 900, color: "var(--green)" }}>${(demoEstimate.total / 1000).toFixed(1)}K</div>
            <div style={{ fontSize: 8, color: "var(--muted)" }}>TOTAL COST</div>
          </div>
        </div>
        <div style={{ fontSize: 11, color: "var(--text)" }}>
          {[
            { label: "Material", amount: demoEstimate.materialCost },
            { label: "Labor", amount: demoEstimate.laborCost },
            { label: "Tear-off & Disposal", amount: demoEstimate.tearOff },
            { label: "Permits", amount: demoEstimate.permits },
            { label: "Dumpster", amount: demoEstimate.dumpster },
          ].map(line => (
            <div key={line.label} style={{ display: "flex", justifyContent: "space-between", padding: "4px 0", borderBottom: "1px solid rgba(51,84,94,0.15)" }}>
              <span style={{ color: "var(--muted)" }}>{line.label}</span>
              <span style={{ fontWeight: 800, color: "var(--accent)" }}>${line.amount.toLocaleString()}</span>
            </div>
          ))}
          <div style={{ display: "flex", justifyContent: "space-between", padding: "8px 0", fontWeight: 900 }}>
            <span>TOTAL</span>
            <span style={{ color: "var(--green)", fontSize: 14 }}>${demoEstimate.total.toLocaleString()}</span>
          </div>
        </div>
      </div>

      {/* Materials */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>ROOFING MATERIALS</h2>
      <div style={{ background: "var(--surface)", borderRadius: 10, overflow: "hidden", marginBottom: 20 }}>
        <div style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr 1fr 1fr", padding: "8px 12px", fontSize: 8, fontWeight: 800, color: "var(--muted)", letterSpacing: 1, borderBottom: "1px solid var(--border)" }}>
          <span>MATERIAL</span><span>$/SF</span><span>LIFESPAN</span><span>WARRANTY</span><span>RATING</span><span>WEIGHT</span>
        </div>
        {materials.map(m => (
          <div key={m.name} style={{ display: "grid", gridTemplateColumns: "2fr 1fr 1fr 1fr 1fr 1fr", padding: "10px 12px", fontSize: 10, alignItems: "center", borderBottom: "1px solid rgba(51,84,94,0.15)" }}>
            <span style={{ fontWeight: 700 }}>{m.name}</span>
            <span style={{ fontWeight: 900, color: "var(--accent)" }}>${m.pricePerSF.toFixed(2)}</span>
            <span style={{ color: "var(--muted)" }}>{m.lifespan}</span>
            <span style={{ color: "var(--cyan)" }}>{m.warranty}</span>
            <span style={{ fontWeight: 800, color: m.rating === "Luxury" ? "var(--gold)" : m.rating === "Premium" ? "var(--accent)" : "var(--muted)" }}>{m.rating}</span>
            <span style={{ color: "var(--muted)" }}>{m.weight}</span>
          </div>
        ))}
      </div>

      {/* Pitch Calculator */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>ROOF PITCH REFERENCE</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8 }}>
        {pitches.map(p => (
          <div key={p.ratio} style={{ background: "var(--surface)", borderRadius: 10, padding: 12, textAlign: "center" }}>
            <div style={{ fontSize: 16, fontWeight: 900, color: "var(--accent)" }}>{p.ratio}</div>
            <div style={{ fontSize: 10, color: "var(--cyan)", marginBottom: 2 }}>{p.degrees}</div>
            <div style={{ fontSize: 9, fontWeight: 800, color: "var(--muted)" }}>{p.type}</div>
            <div style={{ fontSize: 8, color: "var(--gold)", marginTop: 4 }}>×{p.multiplier.toFixed(2)} area</div>
          </div>
        ))}
      </div>
    </div>
  );
}
