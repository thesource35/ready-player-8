export default function ScannerPage() {
  const recentScans = [
    { type: "QR Code", content: "PO-4422 — Graybar Conduit Shipment", timestamp: "Mar 31, 10:15 AM", site: "Riverside Lofts", category: "Material Delivery" },
    { type: "Barcode", content: "EQ-001 — CAT 320 Excavator", timestamp: "Mar 31, 8:30 AM", site: "Riverside Lofts", category: "Equipment Check-in" },
    { type: "QR Code", content: "Badge — Mike Torres (Concrete Foreman)", timestamp: "Mar 31, 6:02 AM", site: "Riverside Lofts", category: "Crew Sign-in" },
    { type: "Document", content: "RFI-042 — MEP Routing Confirmation", timestamp: "Mar 30, 3:45 PM", site: "Harbor Crossing", category: "Document Scan" },
    { type: "QR Code", content: "Safety Inspection Tag — Grid B-7", timestamp: "Mar 30, 11:20 AM", site: "Pine Ridge Ph.2", category: "Safety Tag" },
    { type: "Barcode", content: "MAT-2026-0892 — Steel Rebar Bundle", timestamp: "Mar 29, 2:00 PM", site: "Harbor Crossing", category: "Material Tracking" },
  ];

  const scanCategories = [
    { name: "Crew Sign-in/out", count: 142, icon: "👷", desc: "Badge QR codes for time tracking" },
    { name: "Material Delivery", count: 38, icon: "📦", desc: "PO verification and receiving" },
    { name: "Equipment Tracking", count: 24, icon: "🏗", desc: "Asset tag scans for utilization" },
    { name: "Document Scan", count: 67, icon: "📄", desc: "Plans, RFIs, submittals, reports" },
    { name: "Safety Inspection", count: 19, icon: "🛡", desc: "Tag verification and compliance" },
    { name: "Inventory Count", count: 31, icon: "📋", desc: "Warehouse and laydown area audits" },
  ];

  const totalScans = scanCategories.reduce((a, b) => a + b.count, 0);

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(74,196,204,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)" }}>SCANNER</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>QR & Barcode Scanner</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Scan crew badges, material POs, equipment tags, and documents</p>
      </div>

      {/* Scanner Viewport */}
      <div style={{ background: "var(--panel)", borderRadius: 14, height: 200, marginBottom: 16, display: "flex", alignItems: "center", justifyContent: "center", border: "2px dashed var(--cyan)", position: "relative" }}>
        <div style={{ position: "absolute", width: 120, height: 120, border: "2px solid var(--cyan)", borderRadius: 12, opacity: 0.5 }} />
        <div style={{ textAlign: "center", zIndex: 1 }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>📷</div>
          <div style={{ fontSize: 12, fontWeight: 700, color: "var(--cyan)" }}>Point camera at QR code or barcode</div>
          <div style={{ fontSize: 10, color: "var(--muted)", marginTop: 4 }}>Uses device camera — available in the iOS app</div>
        </div>
      </div>

      {/* Stats */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 10, marginBottom: 20 }}>
        <div style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 24, fontWeight: 900, color: "var(--accent)" }}>{totalScans}</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>TOTAL SCANS</div>
        </div>
        <div style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 24, fontWeight: 900, color: "var(--green)" }}>6</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>CATEGORIES</div>
        </div>
        <div style={{ textAlign: "center", padding: 14, background: "var(--surface)", borderRadius: 10 }}>
          <div style={{ fontSize: 24, fontWeight: 900, color: "var(--cyan)" }}>3</div>
          <div style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)" }}>ACTIVE SITES</div>
        </div>
      </div>

      {/* Categories */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--gold)", marginBottom: 10 }}>SCAN CATEGORIES</h2>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 10, marginBottom: 20 }}>
        {scanCategories.map(c => (
          <div key={c.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14, textAlign: "center" }}>
            <div style={{ fontSize: 24, marginBottom: 4 }}>{c.icon}</div>
            <div style={{ fontSize: 11, fontWeight: 800, marginBottom: 2 }}>{c.name}</div>
            <div style={{ fontSize: 18, fontWeight: 900, color: "var(--accent)" }}>{c.count}</div>
            <div style={{ fontSize: 8, color: "var(--muted)", marginTop: 2 }}>{c.desc}</div>
          </div>
        ))}
      </div>

      {/* Recent Scans */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 2, color: "var(--cyan)", marginBottom: 10 }}>RECENT SCANS</h2>
      {recentScans.map((s, i) => (
        <div key={i} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 11, fontWeight: 800 }}>{s.content}</div>
            <div style={{ display: "flex", gap: 10, fontSize: 9, color: "var(--muted)", marginTop: 2 }}>
              <span>{s.type}</span><span>{s.site}</span><span>{s.category}</span>
            </div>
          </div>
          <span style={{ fontSize: 9, color: "var(--muted)" }}>{s.timestamp}</span>
        </div>
      ))}
    </div>
  );
}
