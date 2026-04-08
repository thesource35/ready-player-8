
"use client";
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div style={{ padding: 40, textAlign: "center", maxWidth: 500, margin: "80px auto" }}>
      <div style={{ fontSize: 40, marginBottom: 16 }}>🆘</div>
      <h2 style={{ fontSize: 18, fontWeight: 800, marginBottom: 8, color: "var(--text)" }}>Something went wrong</h2>
      <p style={{ fontSize: 13, color: "var(--muted)", marginBottom: 20 }}>{error.message || "An unexpected error occurred."}</p>
      <button onClick={reset} style={{ padding: "10px 24px", borderRadius: 8, border: "none", cursor: "pointer", fontWeight: 700, fontSize: 13, color: "#080E12", background: "linear-gradient(90deg, #F29E3D, #FCC757)" }}>Try Again</button>
    </div>
  );
}
