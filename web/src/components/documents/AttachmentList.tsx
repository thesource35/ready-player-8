"use client";
import { useEffect, useState, useCallback } from "react";
import type { Document } from "@/lib/supabase/types";
import { UploadButton } from "./UploadButton";
import { DocumentPreview } from "./DocumentPreview";

type Props = {
  entityType: "project" | "rfi" | "submittal" | "change_order";
  entityId: string;
};

function formatSize(bytes: number) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export function AttachmentList({ entityType, entityId }: Props) {
  const [docs, setDocs] = useState<Document[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [previewId, setPreviewId] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);
    try {
      const res = await fetch(
        `/api/documents/list?entity_type=${entityType}&entity_id=${entityId}`,
      );
      if (!res.ok) {
        const j = await res.json().catch(() => ({}));
        throw new Error(j.error ?? `HTTP ${res.status}`);
      }
      const data = await res.json();
      setDocs(data.documents);
    } catch (e) {
      setError((e as Error).message);
      setDocs([]);
    }
  }, [entityType, entityId]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <section
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        padding: 20,
      }}
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
          Attachments
        </h2>
        <UploadButton
          entityType={entityType}
          entityId={entityId}
          onUploaded={() => load()}
        />
      </header>
      {error && (
        <div role="alert" style={{ color: "var(--red)", marginBottom: 12 }}>
          {error}{" "}
          <button type="button" onClick={load}>
            Retry
          </button>
        </div>
      )}
      {docs === null && <div style={{ color: "var(--muted)" }}>Loading…</div>}
      {docs && docs.length === 0 && (
        <div style={{ color: "var(--muted)" }}>No attachments yet.</div>
      )}
      {docs && docs.length > 0 && (
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
          {docs.map((d) => (
            <li
              key={d.id}
              style={{
                display: "flex",
                justifyContent: "space-between",
                padding: 12,
                background: "var(--panel)",
                borderRadius: 10,
                cursor: "pointer",
              }}
              onClick={() => setPreviewId(d.id)}
            >
              <div>
                <div style={{ fontWeight: 700 }}>{d.filename}</div>
                <div style={{ fontSize: 12, color: "var(--muted)" }}>
                  {d.mime_type} · {formatSize(d.size_bytes)} · v
                  {d.version_number}
                </div>
              </div>
              <a
                href={`/documents/${d.version_chain_id}/versions?entity_type=${entityType}&entity_id=${entityId}`}
                onClick={(e) => e.stopPropagation()}
                style={{ color: "var(--accent)", fontSize: 12 }}
              >
                History
              </a>
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
