"use client";
import { useEffect, useState, useCallback } from "react";
import type { Document } from "@/lib/supabase/types";
import { DocumentPreview } from "./DocumentPreview";
import { UploadButton } from "./UploadButton";

type Props = {
  chainId: string;
  entityType: "project" | "rfi" | "submittal" | "change_order";
  entityId: string;
};

export function VersionHistory({ chainId, entityType, entityId }: Props) {
  const [versions, setVersions] = useState<Document[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [previewId, setPreviewId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const res = await fetch(`/api/documents/${chainId}/versions`);
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? `HTTP ${res.status}`);
      }
      const data = await res.json();
      setVersions(Array.isArray(data) ? data : (data.versions ?? []));
    } catch (e) {
      setError((e as Error).message);
    }
  }, [chainId]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <section
      style={{ background: "var(--surface)", borderRadius: 14, padding: 20 }}
    >
      <header
        style={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          marginBottom: 16,
        }}
      >
        <h2 style={{ fontSize: 18, fontWeight: 800, margin: 0 }}>
          Version History
        </h2>
        <UploadButton
          entityType={entityType}
          entityId={entityId}
          chainId={chainId}
          onUploaded={() => load()}
        />
      </header>
      {error && (
        <div role="alert" style={{ color: "var(--red)" }}>
          {error}{" "}
          <button type="button" onClick={load}>
            Retry
          </button>
        </div>
      )}
      {versions === null && (
        <div style={{ color: "var(--muted)" }}>Loading…</div>
      )}
      {versions && versions.length === 0 && (
        <div style={{ color: "var(--muted)" }}>No versions found.</div>
      )}
      {versions && versions.length > 0 && (
        <ul
          style={{
            listStyle: "none",
            padding: 0,
            margin: 0,
            display: "flex",
            flexDirection: "column",
            gap: 8,
          }}
        >
          {versions.map((v) => (
            <li
              key={v.id}
              style={{
                display: "flex",
                justifyContent: "space-between",
                padding: 12,
                background: v.is_current ? "var(--accent)" : "var(--panel)",
                color: v.is_current ? "#000" : "inherit",
                borderRadius: 10,
                cursor: "pointer",
              }}
              onClick={() => setPreviewId(v.id)}
            >
              <div>
                <strong>v{v.version_number}</strong>{" "}
                {v.is_current && "(current)"} — {v.filename}
              </div>
              <span style={{ fontSize: 12 }}>
                {new Date(v.created_at).toLocaleString()}
              </span>
            </li>
          ))}
        </ul>
      )}
      {previewId && (
        <div style={{ marginTop: 20 }}>
          <button
            type="button"
            onClick={() => setPreviewId(null)}
            style={{ marginBottom: 8 }}
          >
            Close preview
          </button>
          <DocumentPreview documentId={previewId} />
        </div>
      )}
    </section>
  );
}
