"use client";

import { useState, useRef, useEffect, type RefObject } from "react";
import html2canvas from "html2canvas";

type ChartExportButtonProps = {
  chartRef: RefObject<HTMLDivElement | null>;
  filename: string;
};

/** D-26c: PNG/SVG export per chart. 24x24 hit area, positioned top-right. */
export function ChartExportButton({ chartRef, filename }: ChartExportButtonProps) {
  const [open, setOpen] = useState(false);
  const [exporting, setExporting] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown on outside click
  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, [open]);

  const exportPNG = async () => {
    if (!chartRef.current) return;
    setExporting(true);
    try {
      const canvas = await html2canvas(chartRef.current, {
        backgroundColor: null,
        scale: 2,
      });
      const link = document.createElement("a");
      link.download = `${filename}.png`;
      link.href = canvas.toDataURL("image/png");
      link.click();
    } catch (err) {
      console.error("[ChartExport] PNG export failed:", err);
    } finally {
      setExporting(false);
      setOpen(false);
    }
  };

  const exportSVG = () => {
    if (!chartRef.current) return;
    setExporting(true);
    try {
      const svgElement = chartRef.current.querySelector("svg");
      if (!svgElement) {
        console.error("[ChartExport] No SVG element found in chart");
        return;
      }
      const serializer = new XMLSerializer();
      const svgString = serializer.serializeToString(svgElement);
      const blob = new Blob([svgString], { type: "image/svg+xml;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.download = `${filename}.svg`;
      link.href = url;
      link.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error("[ChartExport] SVG export failed:", err);
    } finally {
      setExporting(false);
      setOpen(false);
    }
  };

  return (
    <div ref={dropdownRef} style={{ position: "relative" }}>
      <button
        onClick={() => setOpen(!open)}
        disabled={exporting}
        aria-label="Export chart"
        title="Export chart (PNG/SVG)"
        style={{
          width: 24,
          height: 24,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          background: "transparent",
          border: "none",
          cursor: exporting ? "wait" : "pointer",
          padding: 0,
          color: "var(--muted)",
          borderRadius: 4,
        }}
      >
        {/* Download icon SVG */}
        <svg width={14} height={14} viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round">
          <path d="M7 1v8M3.5 5.5 7 9l3.5-3.5" />
          <path d="M1.5 10v1.5a1 1 0 001 1h9a1 1 0 001-1V10" />
        </svg>
      </button>
      {open && (
        <div
          style={{
            position: "absolute",
            top: 28,
            right: 0,
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 6,
            overflow: "hidden",
            zIndex: 10,
            minWidth: 80,
          }}
        >
          <button
            onClick={exportPNG}
            style={{
              display: "block",
              width: "100%",
              padding: "6px 12px",
              fontSize: 10,
              fontWeight: 800,
              color: "var(--text)",
              background: "transparent",
              border: "none",
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            PNG
          </button>
          <button
            onClick={exportSVG}
            style={{
              display: "block",
              width: "100%",
              padding: "6px 12px",
              fontSize: 10,
              fontWeight: 800,
              color: "var(--text)",
              background: "transparent",
              border: "none",
              cursor: "pointer",
              textAlign: "left",
              borderTop: "1px solid var(--border)",
            }}
          >
            SVG
          </button>
        </div>
      )}
    </div>
  );
}
