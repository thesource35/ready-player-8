"use client";

// PDF Preview component — Phase 19 Plan 07
// D-29: Opens preview with download button
// D-34f: DRAFT watermark shown on preview
// D-34g: Executive summary textarea
// D-34h: Password protection checkbox

import { useState, useRef, useCallback } from "react";
import { generateReportPDF, generateFilename } from "@/lib/reports/pdf-generator";
import type { ProjectReport, PortfolioRollup } from "@/lib/reports/types";

// ---------- Types ----------

type PDFPreviewProps = {
  reportRef: React.RefObject<HTMLDivElement | null>;
  projectName: string;
  companyName?: string;
  companyLogo?: string;
  reportUrl?: string;
  reportData?: ProjectReport | PortfolioRollup;
};

// ---------- Component ----------

export function PDFPreview({
  reportRef,
  projectName,
  companyName,
  companyLogo,
  reportUrl,
}: PDFPreviewProps) {
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // D-34h: password protection
  const [usePassword, setUsePassword] = useState(false);
  const [password, setPassword] = useState("");

  // D-34g: executive summary
  const [executiveSummary, setExecutiveSummary] = useState("");

  // D-34f: confidentiality toggle
  const [confidential, setConfidential] = useState(false);

  // D-34f: DRAFT watermark (shown on preview, removed on final export)
  const [isDraft, setIsDraft] = useState(true);

  const downloadRef = useRef<HTMLAnchorElement>(null);

  const handleDownload = useCallback(async () => {
    if (!reportRef.current) {
      setError("Report element not found. Please try again.");
      return;
    }

    setGenerating(true);
    setError(null);

    try {
      const blob = await generateReportPDF({
        reportElement: reportRef.current,
        projectName,
        companyName,
        companyLogo,
        password: usePassword && password.length >= 4 ? password : undefined,
        isDraft: false, // Final export removes DRAFT watermark
        executiveSummary: executiveSummary.trim() || undefined,
        confidential,
        reportUrl,
      });

      // Trigger download
      const url = URL.createObjectURL(blob);
      const a = downloadRef.current;
      if (a) {
        a.href = url;
        a.download = generateFilename(projectName);
        a.click();
      }
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("[PDFPreview] PDF generation failed:", err);
      setError(err instanceof Error ? err.message : "PDF generation failed");
    } finally {
      setGenerating(false);
    }
  }, [
    reportRef,
    projectName,
    companyName,
    companyLogo,
    usePassword,
    password,
    executiveSummary,
    confidential,
    reportUrl,
  ]);

  return (
    <div
      style={{
        background: "var(--surface)",
        borderRadius: 14,
        padding: 20,
        marginBottom: 16,
      }}
    >
      {/* Hidden download anchor */}
      <a ref={downloadRef} style={{ display: "none" }} aria-hidden="true" />

      <div
        style={{
          fontSize: 12,
          fontWeight: 800,
          color: "var(--text)",
          marginBottom: 16,
          textTransform: "uppercase",
          letterSpacing: 2,
        }}
      >
        PDF Export Options
      </div>

      {/* D-34g: Executive summary textarea */}
      <div style={{ marginBottom: 12 }}>
        <label
          htmlFor="pdf-exec-summary"
          style={{ fontSize: 8, fontWeight: 800, color: "var(--muted)", display: "block", marginBottom: 4 }}
        >
          EXECUTIVE SUMMARY (OPTIONAL)
        </label>
        <textarea
          id="pdf-exec-summary"
          value={executiveSummary}
          onChange={(e) => setExecutiveSummary(e.target.value)}
          placeholder="Add notes that will appear as the Executive Summary section..."
          maxLength={2000}
          style={{
            width: "100%",
            minHeight: 60,
            background: "var(--panel)",
            color: "var(--text)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            padding: 8,
            fontSize: 12,
            resize: "vertical",
            fontFamily: "inherit",
          }}
        />
      </div>

      {/* Options row */}
      <div style={{ display: "flex", gap: 16, flexWrap: "wrap", marginBottom: 12, alignItems: "center" }}>
        {/* D-34f: Confidentiality toggle */}
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            fontSize: 12,
            color: "var(--text)",
            cursor: "pointer",
          }}
        >
          <input
            type="checkbox"
            checked={confidential}
            onChange={(e) => setConfidential(e.target.checked)}
            style={{ accentColor: "var(--accent)" }}
          />
          Confidential footer
        </label>

        {/* D-34f: DRAFT watermark toggle (preview only) */}
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            fontSize: 12,
            color: "var(--text)",
            cursor: "pointer",
          }}
        >
          <input
            type="checkbox"
            checked={isDraft}
            onChange={(e) => setIsDraft(e.target.checked)}
            style={{ accentColor: "var(--accent)" }}
          />
          Show DRAFT watermark (preview)
        </label>

        {/* D-34h: Password protection */}
        <label
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            fontSize: 12,
            color: "var(--text)",
            cursor: "pointer",
          }}
        >
          <input
            type="checkbox"
            checked={usePassword}
            onChange={(e) => setUsePassword(e.target.checked)}
            style={{ accentColor: "var(--accent)" }}
          />
          Password protect
        </label>

        {usePassword && (
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Min 4 characters"
            minLength={4}
            aria-label="PDF password"
            style={{
              background: "var(--panel)",
              color: "var(--text)",
              border: "1px solid var(--border)",
              borderRadius: 6,
              padding: "4px 8px",
              fontSize: 12,
              width: 160,
            }}
          />
        )}
      </div>

      {/* Password validation hint */}
      {usePassword && password.length > 0 && password.length < 4 && (
        <div style={{ fontSize: 8, color: "var(--gold)", marginBottom: 8 }}>
          Password must be at least 4 characters
        </div>
      )}

      {/* Error display */}
      {error && (
        <div style={{ fontSize: 12, color: "var(--red)", marginBottom: 8 }}>
          {error}
        </div>
      )}

      {/* Download button */}
      <button
        onClick={handleDownload}
        disabled={generating || (usePassword && password.length > 0 && password.length < 4)}
        aria-busy={generating}
        style={{
          background: generating ? "var(--muted)" : "var(--accent)",
          color: "var(--bg)",
          fontSize: 12,
          fontWeight: 800,
          padding: "8px 24px",
          borderRadius: 8,
          border: "none",
          cursor: generating ? "wait" : "pointer",
          opacity: generating ? 0.7 : 1,
          display: "flex",
          alignItems: "center",
          gap: 8,
        }}
      >
        {generating ? (
          <>
            <span
              style={{
                display: "inline-block",
                width: 14,
                height: 14,
                border: "2px solid var(--bg)",
                borderTopColor: "transparent",
                borderRadius: "50%",
                animation: "spin 0.8s linear infinite",
              }}
            />
            Generating PDF...
          </>
        ) : (
          "Download PDF"
        )}
      </button>

      {/* Inline CSS for spinner animation */}
      <style>{`@keyframes spin { to { transform: rotate(360deg) } }`}</style>
    </div>
  );
}
