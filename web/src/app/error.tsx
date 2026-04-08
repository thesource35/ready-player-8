"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div style={{ minHeight: "60vh", display: "flex", alignItems: "center", justifyContent: "center", padding: 20 }}>
      <div style={{ textAlign: "center", maxWidth: 400 }}>
        <div style={{ fontSize: 48, marginBottom: 12 }}>⚠️</div>
        <h2 style={{ fontSize: 20, fontWeight: 900, marginBottom: 8 }}>Something went wrong</h2>
        <p style={{ fontSize: 12, color: "var(--muted)", marginBottom: 20 }}>
          {error.message || "An unexpected error occurred. Please try again."}
        </p>
        <button
          onClick={reset}
          style={{
            padding: "10px 24px",
            borderRadius: 10,
            fontSize: 13,
            fontWeight: 800,
            color: "#080E12",
            background: "linear-gradient(90deg, #F29E3D, #FCC757)",
            border: "none",
            cursor: "pointer",
          }}
        >
          Try Again
        </button>
      </div>
    </div>
  );
}
