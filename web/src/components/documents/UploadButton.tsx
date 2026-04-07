"use client";
import { useState, useRef } from "react";
import {
  validateDocumentUpload,
  ALLOWED_MIME,
} from "@/lib/documents/validation";
import type { Document } from "@/lib/supabase/types";

type Props = {
  entityType: "project" | "rfi" | "submittal" | "change_order";
  entityId: string;
  chainId?: string;
  onUploaded: (doc: Document) => void;
};

export function UploadButton({
  entityType,
  entityId,
  chainId,
  onUploaded,
}: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function uploadOnce(file: File): Promise<Document> {
    const form = new FormData();
    form.append("file", file);
    form.append("entity_type", entityType);
    form.append("entity_id", entityId);
    const endpoint = chainId
      ? `/api/documents/${chainId}/versions`
      : `/api/documents/upload`;
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      xhr.open("POST", endpoint);
      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable)
          setProgress(Math.round((e.loaded / e.total) * 100));
      };
      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            resolve(JSON.parse(xhr.responseText) as Document);
          } catch {
            reject(new Error("Bad JSON"));
          }
        } else {
          let msg = `HTTP ${xhr.status}`;
          try {
            msg = JSON.parse(xhr.responseText).error ?? msg;
          } catch {}
          reject(new Error(msg));
        }
      };
      xhr.onerror = () => reject(new Error("Network error"));
      xhr.send(form);
    });
  }

  async function handleFile(file: File) {
    setError(null);
    setProgress(0);
    setBusy(true);
    const v = validateDocumentUpload({ size: file.size, mimeType: file.type });
    if (!v.ok) {
      setError(v.error);
      setBusy(false);
      return;
    }
    let lastErr: Error | null = null;
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const doc = await uploadOnce(file);
        onUploaded(doc);
        setBusy(false);
        setProgress(0);
        return;
      } catch (e) {
        lastErr = e as Error;
        if (attempt < 3)
          await new Promise((r) => setTimeout(r, 1000 * attempt));
      }
    }
    setError(lastErr?.message ?? "Upload failed");
    setBusy(false);
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
      <input
        ref={inputRef}
        type="file"
        accept={Array.from(ALLOWED_MIME).join(",")}
        style={{ display: "none" }}
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) handleFile(f);
        }}
      />
      <button
        type="button"
        disabled={busy}
        onClick={() => inputRef.current?.click()}
        style={{
          padding: "10px 16px",
          borderRadius: 10,
          background: "var(--accent)",
          color: "#000",
          fontWeight: 700,
          border: "none",
          cursor: busy ? "wait" : "pointer",
          minHeight: 44,
        }}
      >
        {busy
          ? `Uploading ${progress}%`
          : chainId
            ? "Upload new version"
            : "Attach file"}
      </button>
      {busy && (
        <div
          role="progressbar"
          aria-valuenow={progress}
          aria-valuemin={0}
          aria-valuemax={100}
          style={{
            width: "100%",
            height: 4,
            background: "var(--surface)",
            borderRadius: 2,
          }}
        >
          <div
            style={{
              width: `${progress}%`,
              height: "100%",
              background: "var(--accent)",
              borderRadius: 2,
            }}
          />
        </div>
      )}
      {error && (
        <div role="alert" style={{ color: "var(--red)", fontSize: 13 }}>
          {error}
          <button
            type="button"
            onClick={() => {
              setError(null);
              inputRef.current?.click();
            }}
            style={{
              marginLeft: 8,
              textDecoration: "underline",
              background: "none",
              border: "none",
              color: "var(--accent)",
              cursor: "pointer",
            }}
          >
            Retry
          </button>
        </div>
      )}
    </div>
  );
}
