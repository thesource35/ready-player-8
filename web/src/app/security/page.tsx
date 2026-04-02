export default function SecurityPage() {
  const securityFeatures = [
    { name: "Face ID / Touch ID", status: "ENABLED", desc: "Biometric authentication required to access the app", icon: "face.smiling" },
    { name: "Two-Factor Authentication", status: "ENABLED", desc: "Authenticator app as primary 2FA method", icon: "lock.shield" },
    { name: "Keychain Storage", status: "ACTIVE", desc: "All API keys and secrets stored in encrypted Keychain", icon: "key" },
    { name: "Session Management", status: "ACTIVE", desc: "Auto-lock after 5 minutes of inactivity", icon: "clock" },
    { name: "Data Encryption", status: "AES-256", desc: "All data encrypted at rest and in transit", icon: "lock" },
    { name: "Audit Logging", status: "ACTIVE", desc: "All actions logged with timestamps and user IDs", icon: "doc.text" },
  ];

  const sessions = [
    { device: "iPhone 15 Pro Max", location: "Houston, TX", lastActive: "Now", status: "CURRENT", ip: "192.168.1.xxx" },
    { device: "MacBook Pro M3", location: "Houston, TX", lastActive: "2 hours ago", status: "ACTIVE", ip: "192.168.1.xxx" },
    { device: "iPad Pro", location: "Dallas, TX", lastActive: "3 days ago", status: "EXPIRED", ip: "10.0.0.xxx" },
  ];

  const auditLog = [
    { action: "Login via Face ID", timestamp: "Mar 31, 10:42 AM", user: "admin@constructionos.world", severity: "INFO" },
    { action: "API Key rotated: Supabase", timestamp: "Mar 30, 4:15 PM", user: "admin@constructionos.world", severity: "WARNING" },
    { action: "Failed login attempt (2FA)", timestamp: "Mar 30, 2:33 PM", user: "unknown@gmail.com", severity: "CRITICAL" },
    { action: "New device registered", timestamp: "Mar 29, 9:00 AM", user: "admin@constructionos.world", severity: "INFO" },
    { action: "Role changed: Field → PM", timestamp: "Mar 28, 11:20 AM", user: "mike.torres@company.com", severity: "WARNING" },
    { action: "Export: Commander Report", timestamp: "Mar 28, 8:45 AM", user: "admin@constructionos.world", severity: "INFO" },
  ];

  const twoFactorMethods = [
    { method: "Authenticator App", status: "PRIMARY", desc: "Google Authenticator, Authy, or 1Password" },
    { method: "SMS OTP", status: "BACKUP", desc: "Text message to +1 (713) ***-**42" },
    { method: "Email OTP", status: "BACKUP", desc: "One-time code sent to admin@constructionos.world" },
  ];

  const sevColor = (s: string) => s === "CRITICAL" ? "var(--red)" : s === "WARNING" ? "var(--gold)" : "var(--green)";

  return (
    <div style={{ padding: 20, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ background: "var(--surface)", borderRadius: 14, padding: 20, marginBottom: 16, border: "1px solid rgba(242,158,61,0.08)" }}>
        <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 4, color: "var(--gold)" }}>SECURITY</div>
        <h1 style={{ fontSize: 24, fontWeight: 900, margin: "4px 0" }}>Security & Access Control</h1>
        <p style={{ fontSize: 12, color: "var(--muted)" }}>Biometric auth, 2FA, session management, encryption, and audit trail</p>
      </div>

      {/* Security Features */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: 10, marginBottom: 20 }}>
        {securityFeatures.map(f => (
          <div key={f.name} style={{ background: "var(--surface)", borderRadius: 10, padding: 14 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 6 }}>
              <span style={{ fontSize: 12, fontWeight: 800 }}>{f.name}</span>
              <span style={{ fontSize: 8, fontWeight: 900, color: "var(--green)", background: "rgba(105,210,148,0.1)", padding: "3px 8px", borderRadius: 4 }}>{f.status}</span>
            </div>
            <p style={{ fontSize: 10, color: "var(--muted)", margin: 0 }}>{f.desc}</p>
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20, marginBottom: 20 }}>
        {/* 2FA Methods */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--accent)", marginBottom: 10 }}>TWO-FACTOR METHODS</h2>
          {twoFactorMethods.map(m => (
            <div key={m.method} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={{ fontSize: 11, fontWeight: 700 }}>{m.method}</div>
                <div style={{ fontSize: 9, color: "var(--muted)" }}>{m.desc}</div>
              </div>
              <span style={{ fontSize: 8, fontWeight: 900, color: m.status === "PRIMARY" ? "var(--green)" : "var(--muted)" }}>{m.status}</span>
            </div>
          ))}
        </div>

        {/* Active Sessions */}
        <div>
          <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--cyan)", marginBottom: 10 }}>ACTIVE SESSIONS</h2>
          {sessions.map(s => (
            <div key={s.device} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, marginBottom: 6 }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span style={{ fontSize: 11, fontWeight: 700 }}>{s.device}</span>
                <span style={{ fontSize: 8, fontWeight: 900, color: s.status === "CURRENT" ? "var(--green)" : s.status === "ACTIVE" ? "var(--cyan)" : "var(--muted)" }}>{s.status}</span>
              </div>
              <div style={{ display: "flex", gap: 12, fontSize: 9, color: "var(--muted)", marginTop: 4 }}>
                <span>{s.location}</span><span>{s.ip}</span><span>{s.lastActive}</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Audit Log */}
      <h2 style={{ fontSize: 11, fontWeight: 800, letterSpacing: 3, color: "var(--gold)", marginBottom: 10 }}>AUDIT LOG</h2>
      <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
        {auditLog.map((a, i) => (
          <div key={i} style={{ background: "var(--surface)", borderRadius: 8, padding: 12, display: "flex", justifyContent: "space-between", alignItems: "center", borderLeft: `3px solid ${sevColor(a.severity)}` }}>
            <div>
              <span style={{ fontSize: 11, fontWeight: 700 }}>{a.action}</span>
              <span style={{ fontSize: 9, color: "var(--muted)", marginLeft: 10 }}>{a.user}</span>
            </div>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <span style={{ fontSize: 9, color: "var(--muted)" }}>{a.timestamp}</span>
              <span style={{ fontSize: 8, fontWeight: 900, color: sevColor(a.severity) }}>{a.severity}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
