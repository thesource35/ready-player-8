"use client";
import { useEffect, useState } from "react";

type Props = { documentId: string };

type State =
  | { kind: "loading" }
  | { kind: "ready"; url: string; mimeType: string; filename: string }
  | { kind: "error"; message: string };

export function DocumentPreview({ documentId }: Props) {
  const [state, setState] = useState<State>({ kind: "loading" });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`/api/documents/${documentId}/sign`);
        if (!res.ok) {
          const j = await res.json().catch(() => ({}));
          throw new Error(j.error ?? `HTTP ${res.status}`);
        }
        const data = await res.json();
        if (!cancelled)
          setState({
            kind: "ready",
            url: data.url,
            mimeType: data.mime_type,
            filename: data.filename,
          });
      } catch (e) {
        if (!cancelled)
          setState({ kind: "error", message: (e as Error).message });
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [documentId]);

  if (state.kind === "loading")
    return (
      <div style={{ padding: 24, color: "var(--muted)" }}>Loading preview…</div>
    );
  if (state.kind === "error")
    return (
      <div role="alert" style={{ padding: 24, color: "var(--red)" }}>
        Preview failed: {state.message}
      </div>
    );
  if (state.mimeType === "application/pdf") {
    return (
      <iframe
        title={state.filename}
        src={state.url}
        style={{
          width: "100%",
          height: "80vh",
          border: "none",
          borderRadius: 8,
        }}
      />
    );
  }
  return (
    <img
      src={state.url}
      alt={state.filename}
      style={{ maxWidth: "100%", maxHeight: "80vh", borderRadius: 8 }}
    />
  );
}
