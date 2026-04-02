export default function NotFound() {
  return (
    <div style={{ minHeight: "80vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 20 }}>
      <div style={{ textAlign: "center", maxWidth: 400 }}>
        <div style={{ fontSize: 64, marginBottom: 16 }}>🏗</div>
        <h1 style={{ fontSize: 48, fontWeight: 900, color: "var(--accent)", marginBottom: 8 }}>404</h1>
        <h2 style={{ fontSize: 20, fontWeight: 800, marginBottom: 8 }}>Page Not Found</h2>
        <p style={{ fontSize: 13, color: "var(--muted)", marginBottom: 24 }}>This page doesn&apos;t exist — like a building without a foundation. Let&apos;s get you back on solid ground.</p>
        <div style={{ display: "flex", gap: 10, justifyContent: "center" }}>
          <a href="/" style={{ padding: "10px 24px", borderRadius: 10, fontSize: 13, fontWeight: 800, color: "#080E12", background: "linear-gradient(90deg, #F29E3D, #FCC757)", textDecoration: "none" }}>Go Home</a>
          <a href="/feed" style={{ padding: "10px 24px", borderRadius: 10, fontSize: 13, fontWeight: 800, color: "#4AC4CC", border: "1px solid #4AC4CC", textDecoration: "none" }}>Network</a>
          <a href="/ai" style={{ padding: "10px 24px", borderRadius: 10, fontSize: 13, fontWeight: 800, color: "#9EBDC2", border: "1px solid #33545E", textDecoration: "none" }}>Ask AI</a>
        </div>
      </div>
    </div>
  );
}
