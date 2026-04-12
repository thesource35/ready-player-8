"use client";

// Full data export/backup component (D-97)
// Generates ZIP with all report data: PDFs, schedules, templates, delivery logs, history.
// Rate limited to 1/hour per T-19-44.

import { useState, useCallback } from "react";

type ExportStatus = "idle" | "exporting" | "complete" | "error";

type ExportProgress = {
  current: number;
  total: number;
  stage: string;
};

export default function DataExportBackup({ userId }: { userId: string }) {
  const [status, setStatus] = useState<ExportStatus>("idle");
  const [progress, setProgress] = useState<ExportProgress>({
    current: 0,
    total: 5,
    stage: "",
  });
  const [downloadUrl, setDownloadUrl] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleExport = useCallback(async () => {
    if (!userId) return;

    setStatus("exporting");
    setError(null);
    setDownloadUrl(null);

    try {
      // Stage 1: Request export
      setProgress({ current: 1, total: 5, stage: "Preparing export..." });

      const res = await fetch("/api/reports/export/full", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId }),
      });

      if (res.status === 429) {
        setStatus("error");
        setError("Export rate limited. You can export once per hour.");
        return;
      }

      if (!res.ok) {
        const errText = await res.text();
        setStatus("error");
        setError(errText || "Export failed");
        return;
      }

      // Stage 2-4: Progress updates (server-side processing)
      setProgress({ current: 2, total: 5, stage: "Collecting report history..." });
      await new Promise((r) => setTimeout(r, 500));
      setProgress({ current: 3, total: 5, stage: "Gathering schedules and templates..." });
      await new Promise((r) => setTimeout(r, 500));
      setProgress({ current: 4, total: 5, stage: "Bundling PDFs..." });

      const data = await res.json();

      // Stage 5: Complete
      setProgress({ current: 5, total: 5, stage: "Export ready!" });
      setDownloadUrl(data.downloadUrl || null);
      setStatus("complete");
    } catch (err) {
      setStatus("error");
      setError(err instanceof Error ? err.message : "Unknown error during export");
    }
  }, [userId]);

  const progressPercent =
    progress.total > 0 ? Math.round((progress.current / progress.total) * 100) : 0;

  return (
    <div
      style={{
        background: "var(--surface, #1e293b)",
        borderRadius: 14,
        padding: 24,
        border: "1px solid var(--border, #334155)",
      }}
    >
      <h3
        style={{
          margin: "0 0 8px",
          fontSize: 16,
          fontWeight: 700,
          color: "var(--text, #f1f5f9)",
        }}
      >
        Data Export &amp; Backup
      </h3>
      <p
        style={{
          margin: "0 0 16px",
          fontSize: 13,
          color: "var(--muted, #94a3b8)",
          lineHeight: 1.5,
        }}
      >
        Export all your report data as a ZIP file. Includes stored PDFs, schedule
        configurations, templates, delivery logs, and report history snapshots.
      </p>

      {/* Automated backup note (D-97) */}
      <div
        style={{
          background: "var(--panel, #0f172a)",
          borderRadius: 8,
          padding: "10px 14px",
          marginBottom: 16,
          fontSize: 12,
          color: "var(--muted, #94a3b8)",
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        <InfoIcon />
        <span>
          Supabase automatically backs up your database daily. This export
          provides a personal copy of your report data.
        </span>
      </div>

      {/* Export contents list */}
      <div
        style={{
          marginBottom: 16,
          fontSize: 13,
          color: "var(--text, #f1f5f9)",
        }}
      >
        <div style={{ fontWeight: 600, marginBottom: 6 }}>Export includes:</div>
        <ul style={{ margin: 0, paddingLeft: 20, lineHeight: 1.8 }}>
          <li>Stored PDFs from report history</li>
          <li>Schedule configurations (JSON)</li>
          <li>Report templates (JSON)</li>
          <li>Delivery logs (CSV)</li>
          <li>Report history snapshots (JSON)</li>
        </ul>
      </div>

      {/* Progress indicator */}
      {status === "exporting" && (
        <div style={{ marginBottom: 16 }}>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              fontSize: 12,
              color: "var(--muted, #94a3b8)",
              marginBottom: 6,
            }}
          >
            <span>{progress.stage}</span>
            <span>{progressPercent}%</span>
          </div>
          <div
            style={{
              height: 6,
              background: "var(--border, #334155)",
              borderRadius: 3,
              overflow: "hidden",
            }}
          >
            <div
              style={{
                width: `${progressPercent}%`,
                height: "100%",
                background: "var(--accent, #f59e0b)",
                borderRadius: 3,
                transition: "width 0.3s ease",
              }}
              role="progressbar"
              aria-valuenow={progressPercent}
              aria-valuemin={0}
              aria-valuemax={100}
              aria-label="Export progress"
            />
          </div>
        </div>
      )}

      {/* Error message */}
      {status === "error" && error && (
        <div
          style={{
            background: "rgba(239, 68, 68, 0.1)",
            border: "1px solid var(--red, #ef4444)",
            borderRadius: 8,
            padding: "10px 14px",
            marginBottom: 16,
            fontSize: 13,
            color: "var(--red, #ef4444)",
          }}
          role="alert"
        >
          {error}
        </div>
      )}

      {/* Download link after successful export */}
      {status === "complete" && downloadUrl && (
        <div
          style={{
            background: "rgba(34, 197, 94, 0.1)",
            border: "1px solid var(--green, #22c55e)",
            borderRadius: 8,
            padding: "10px 14px",
            marginBottom: 16,
            fontSize: 13,
            color: "var(--green, #22c55e)",
          }}
        >
          Export ready!{" "}
          <a
            href={downloadUrl}
            download
            style={{ color: "var(--green, #22c55e)", fontWeight: 600 }}
          >
            Download ZIP
          </a>
        </div>
      )}

      {/* Export button */}
      <button
        onClick={handleExport}
        disabled={status === "exporting"}
        aria-label="Export all report data"
        style={{
          width: "100%",
          padding: "12px 20px",
          borderRadius: 8,
          border: "none",
          background:
            status === "exporting"
              ? "var(--border, #334155)"
              : "var(--accent, #f59e0b)",
          color: status === "exporting" ? "var(--muted, #94a3b8)" : "#1a1a1a",
          fontSize: 14,
          fontWeight: 700,
          cursor: status === "exporting" ? "not-allowed" : "pointer",
          transition: "background 0.2s ease",
        }}
      >
        {status === "exporting"
          ? "Exporting..."
          : status === "complete"
            ? "Export Again"
            : "Export All Data"}
      </button>
    </div>
  );
}

function InfoIcon() {
  return (
    <svg
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      style={{ flexShrink: 0 }}
    >
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="16" x2="12" y2="12" />
      <line x1="12" y1="8" x2="12.01" y2="8" />
    </svg>
  );
}
