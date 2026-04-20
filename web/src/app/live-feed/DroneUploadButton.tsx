// Phase 29 LIVE-01 / LIVE-02 — web drone upload (drag-and-drop + file input).
//
// Routes through the Phase 22 route POST /api/video/vod/upload-url with
// `source_type: 'drone'` — that body field is the 29-02 widened enum gate
// (Zod-validated server-side; T-29-09-03). The client value is only a label;
// the server is authoritative.
//
// Upload strategy is a single-shot POST to Supabase Storage's resumable tus
// endpoint with Tus-Resumable / Authorization / bucket metadata headers — the
// same approach VideoUploadClient.swift uses (see ready player 8/Video/
// VideoUploadClient.swift). This matches the PLAN's "single-shot for v1"
// spec and keeps web/iOS parity. A follow-up can migrate to tus-js-client
// for chunked resumable uploads (Phase 22's ClipUploadCard pattern).
//
// Error copy per 29-UI-SPEC §Copywriting (lines 426-429). No silent failures.

"use client";

import { useRef, useState } from "react";

type UploadState = "idle" | "uploading" | "success" | "error";

type UploadResponse = {
  asset_id: string;
  bucket_name: string;
  object_name: string;
  upload_url: string;
  auth_token: string;
};

const MAX_SIZE = 2 * 1024 * 1024 * 1024; // 2 GB (D-31)
const ALLOWED_CONTAINERS = new Set(["mp4", "mov", "m4v"]);

type Props = {
  projectId: string;
  orgId: string;
  onComplete?: (assetId: string) => void;
};

export function DroneUploadButton({ projectId, orgId, onComplete }: Props) {
  const [state, setState] = useState<UploadState>("idle");
  const [progress, setProgress] = useState<number>(0);
  const [error, setError] = useState<string | null>(null);
  const [dragOver, setDragOver] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  async function handleFile(file: File) {
    setError(null);
    setProgress(0);
    setState("uploading");

    const ext = (file.name.split(".").pop() ?? "").toLowerCase();
    if (!ALLOWED_CONTAINERS.has(ext)) {
      setState("error");
      setError("Unsupported codec — use MP4 or MOV (H.264 / H.265).");
      return;
    }
    if (file.size > MAX_SIZE) {
      setState("error");
      setError("Clip exceeds 2 GB limit.");
      return;
    }

    let uploadInfo: UploadResponse;
    try {
      const resp = await fetch("/api/video/vod/upload-url", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          project_id: projectId,
          org_id: orgId,
          name: file.name,
          file_size_bytes: file.size,
          container: ext,
          source_type: "drone", // LIVE-01: widened route (29-02)
        }),
      });
      if (!resp.ok) {
        const msg = await resp.text().catch(() => "");
        throw new Error(
          `Upload URL failed (${resp.status}): ${msg || "see server logs"}`,
        );
      }
      uploadInfo = (await resp.json()) as UploadResponse;
    } catch (e) {
      setState("error");
      setError(
        e instanceof Error ? e.message : "Upload failed — network unreachable.",
      );
      return;
    }

    // Single-shot POST to Supabase Storage tus endpoint — matches iOS
    // VideoUploadClient.swift upload(). For v1 this is acceptable; a future
    // iteration should use tus-js-client for chunked resumable uploads.
    try {
      const contentType = ext === "mov" ? "video/quicktime" : "video/mp4";
      const putResp = await fetch(uploadInfo.upload_url, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${uploadInfo.auth_token}`,
          "Tus-Resumable": "1.0.0",
          "Content-Type": contentType,
          "x-upsert": "true",
          bucketName: uploadInfo.bucket_name,
          objectName: uploadInfo.object_name,
          contentType,
        },
        body: file,
      });
      if (!putResp.ok && putResp.status !== 201 && putResp.status !== 204) {
        throw new Error(`Storage returned ${putResp.status}`);
      }
      setProgress(1);
      setState("success");
      onComplete?.(uploadInfo.asset_id);
    } catch (e) {
      setState("error");
      setError(
        e instanceof Error ? e.message : "Upload failed — network unreachable.",
      );
    }
  }

  function onDrop(e: React.DragEvent) {
    e.preventDefault();
    setDragOver(false);
    const file = e.dataTransfer.files[0];
    if (file) void handleFile(file);
  }

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault();
        setDragOver(true);
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={onDrop}
      role="region"
      aria-label="Drone upload drop zone"
      style={{
        border: `2px dashed ${dragOver ? "var(--accent)" : "var(--surface)"}`,
        borderRadius: 14,
        padding: 24,
        background: dragOver ? "rgba(242,158,61,0.08)" : "var(--surface)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 8,
      }}
    >
      <input
        ref={fileRef}
        type="file"
        accept="video/mp4,video/quicktime"
        style={{ display: "none" }}
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) void handleFile(f);
        }}
      />
      <button
        type="button"
        onClick={() => fileRef.current?.click()}
        disabled={state === "uploading"}
        style={{
          fontSize: 11,
          fontWeight: 800,
          letterSpacing: 2,
          padding: "10px 16px",
          borderRadius: 10,
          background: "var(--accent)",
          color: "black",
          border: "none",
          cursor: state === "uploading" ? "not-allowed" : "pointer",
          opacity: state === "uploading" ? 0.6 : 1,
        }}
      >
        {state === "uploading"
          ? `Uploading… ${Math.round(progress * 100)}%`
          : "Upload Drone Clip"}
      </button>
      <span style={{ fontSize: 12, color: "var(--muted)" }}>
        Drag MP4 / MOV here — up to 2 GB / 60 min
      </span>
      {state === "success" && (
        <span style={{ fontSize: 12, color: "var(--green)" }}>
          Drone clip uploaded — analysis in progress.
        </span>
      )}
      {state === "error" && error && (
        <span style={{ fontSize: 12, color: "var(--red)" }}>{error}</span>
      )}
    </div>
  );
}
