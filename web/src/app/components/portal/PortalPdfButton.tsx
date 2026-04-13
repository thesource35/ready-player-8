"use client";

/**
 * PortalPdfButton: "Download PDF" button for portal header area (D-22).
 * Captures the rendered portal DOM via html2canvas and generates a branded PDF.
 * Uses generatePortalPdf() from portalPdf.ts and file-saver for download.
 */

import { useState, useCallback } from "react";
import type { CompanyBranding } from "@/lib/portal/types";

type PortalPdfButtonProps = {
  branding: CompanyBranding;
  projectName: string;
};

export default function PortalPdfButton({
  branding,
  projectName,
}: PortalPdfButtonProps) {
  const [isGenerating, setIsGenerating] = useState(false);

  const handleDownload = useCallback(async () => {
    if (isGenerating) return;

    const portalElement = document.getElementById("portal-shell");
    if (!portalElement) {
      console.error("[PortalPdfButton] portal-shell element not found");
      return;
    }

    setIsGenerating(true);

    try {
      // Dynamic imports to keep initial bundle small
      const { generatePortalPdf } = await import("@/lib/portal/portalPdf");
      const { saveAs } = await import("file-saver");

      const generatedDate = new Date().toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });

      const blob = await generatePortalPdf({
        portalElement,
        branding,
        projectName,
        generatedDate,
      });

      // D-22: Filename format {projectName}-portal-{date}.pdf
      const dateSlug = new Date().toISOString().split("T")[0];
      const safeProjectName = projectName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "");
      const filename = `${safeProjectName}-portal-${dateSlug}.pdf`;

      saveAs(blob, filename);
    } catch (err) {
      console.error("[PortalPdfButton] PDF generation failed:", err);
    } finally {
      setIsGenerating(false);
    }
  }, [isGenerating, branding, projectName]);

  return (
    <button
      onClick={handleDownload}
      disabled={isGenerating}
      aria-label="Download portal as PDF"
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        padding: "8px 16px",
        fontSize: 14,
        fontWeight: 500,
        color: isGenerating ? "#9CA3AF" : "var(--portal-primary, #2563EB)",
        background: isGenerating
          ? "#F1F3F5"
          : "var(--portal-card-bg, #FFFFFF)",
        border: `1px solid ${isGenerating ? "#E2E5E9" : "var(--portal-primary, #2563EB)"}`,
        borderRadius: "var(--portal-radius, 8px)",
        cursor: isGenerating ? "not-allowed" : "pointer",
        transition: "all 200ms ease-in-out",
      }}
    >
      {isGenerating ? (
        <>
          {/* Loading spinner */}
          <svg
            width={16}
            height={16}
            viewBox="0 0 16 16"
            fill="none"
            style={{
              animation: "spin 1s linear infinite",
            }}
          >
            <circle
              cx={8}
              cy={8}
              r={6}
              stroke="currentColor"
              strokeWidth={2}
              strokeDasharray="28"
              strokeDashoffset="8"
              strokeLinecap="round"
            />
          </svg>
          <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
          Generating PDF...
        </>
      ) : (
        <>
          {/* Download icon (Lucide-style) */}
          <svg
            width={16}
            height={16}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={2}
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
            <polyline points="7 10 12 15 17 10" />
            <line x1={12} y1={15} x2={12} y2={3} />
          </svg>
          Download PDF
        </>
      )}
    </button>
  );
}
