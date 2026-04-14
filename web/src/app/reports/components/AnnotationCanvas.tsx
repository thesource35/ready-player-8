"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import dynamic from "next/dynamic";
import type { FabricRef } from "./FabricCanvasInner";

// D-98: Visual annotation/drawing tools on charts
// Fabric.js loaded via dynamic import with ssr: false per RESEARCH.md assumption A5
// Tools: circle, arrow, highlight, freeform draw per D-98

type AnnotationTool = "select" | "circle" | "arrow" | "highlight" | "draw";

type AnnotationCanvasProps = {
  reportHistoryId: string;
  chartId: string;
  width?: number;
  height?: number;
};

// Lazy-load the canvas implementation to avoid SSR issues with Fabric.js
const FabricCanvas = dynamic(() => import("./FabricCanvasInner"), {
  ssr: false,
  loading: () => (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        height: 300,
        color: "var(--muted, #888)",
        fontSize: 12,
      }}
    >
      Loading annotation tools...
    </div>
  ),
});

export default function AnnotationCanvas({
  reportHistoryId,
  chartId,
  width = 600,
  height = 400,
}: AnnotationCanvasProps) {
  const [activeTool, setActiveTool] = useState<AnnotationTool>("select");
  const [saving, setSaving] = useState(false);
  const [annotationId, setAnnotationId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const fabricRef = useRef<FabricRef | null>(null);

  // Load existing annotations
  useEffect(() => {
    async function loadAnnotations() {
      try {
        const params = new URLSearchParams({ report_history_id: reportHistoryId });
        const res = await fetch(`/api/reports/annotations?${params}`);
        if (!res.ok) return;
        const data = await res.json();
        const existing = (data.annotations ?? []).find(
          (a: { chart_id: string }) => a.chart_id === chartId
        );
        if (existing && fabricRef.current) {
          setAnnotationId(existing.id);
          fabricRef.current.loadFromJSON(existing.fabric_json);
        }
      } catch {
        // Silent fail on load — user can still draw fresh annotations
      }
    }
    if (reportHistoryId) {
      loadAnnotations();
    }
  }, [reportHistoryId, chartId]);

  const handleSave = useCallback(async () => {
    if (!fabricRef.current) return;
    setSaving(true);
    setError(null);

    const fabricJson = fabricRef.current.toJSON();

    try {
      if (annotationId) {
        // Update existing
        const res = await fetch("/api/reports/annotations", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id: annotationId, fabric_json: fabricJson }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({ error: "Save failed" }));
          throw new Error(err.error || "Failed to save");
        }
      } else {
        // Create new
        const res = await fetch("/api/reports/annotations", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            report_history_id: reportHistoryId,
            chart_id: chartId,
            fabric_json: fabricJson,
          }),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({ error: "Save failed" }));
          throw new Error(err.error || "Failed to save");
        }
        const data = await res.json();
        setAnnotationId(data.annotation?.id ?? null);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to save annotation");
    } finally {
      setSaving(false);
    }
  }, [annotationId, reportHistoryId, chartId]);

  const handleClear = useCallback(() => {
    if (fabricRef.current) {
      fabricRef.current.clear();
    }
  }, []);

  /** Export canvas as PNG data URL for PDF inclusion (D-98) */
  const handleExportImage = useCallback((): string | null => {
    if (!fabricRef.current) return null;
    // FabricCanvasInner exposes toDataURL via the ref
    const canvas = fabricRef.current as unknown as { toDataURL?: () => string };
    return canvas.toDataURL ? canvas.toDataURL() : null;
  }, []);

  const tools: { id: AnnotationTool; label: string; icon: string }[] = [
    { id: "select", label: "Select", icon: "pointer" },
    { id: "circle", label: "Circle", icon: "circle" },
    { id: "arrow", label: "Arrow", icon: "arrow" },
    { id: "highlight", label: "Highlight", icon: "highlight" },
    { id: "draw", label: "Draw", icon: "pencil" },
  ];

  // Expose export function for parent components
  void handleExportImage;

  return (
    <div
      style={{
        position: "relative",
        background: "var(--surface, #1a1a2e)",
        borderRadius: 14,
        padding: 12,
        border: "1px solid var(--border, #333)",
      }}
    >
      {/* Toolbar */}
      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 6,
          marginBottom: 8,
          flexWrap: "wrap",
        }}
      >
        <span
          style={{
            fontSize: 12,
            fontWeight: 700,
            color: "var(--text, #e5e5e5)",
            marginRight: 8,
            textTransform: "uppercase",
            letterSpacing: 1,
          }}
        >
          Annotate
        </span>

        {tools.map((tool) => (
          <button
            key={tool.id}
            onClick={() => setActiveTool(tool.id)}
            title={tool.label}
            style={{
              padding: "4px 10px",
              fontSize: 11,
              fontWeight: activeTool === tool.id ? 700 : 500,
              background:
                activeTool === tool.id
                  ? "var(--accent, #f59e0b)"
                  : "transparent",
              color:
                activeTool === tool.id ? "#000" : "var(--muted, #888)",
              border: "1px solid var(--border, #333)",
              borderRadius: 4,
              cursor: "pointer",
            }}
          >
            {tool.label}
          </button>
        ))}

        <div style={{ flex: 1 }} />

        <button
          onClick={handleClear}
          style={{
            padding: "4px 10px",
            fontSize: 11,
            fontWeight: 500,
            background: "transparent",
            color: "var(--red, #ef4444)",
            border: "1px solid var(--red, #ef4444)",
            borderRadius: 4,
            cursor: "pointer",
          }}
        >
          Clear
        </button>

        <button
          onClick={handleSave}
          disabled={saving}
          style={{
            padding: "4px 12px",
            fontSize: 11,
            fontWeight: 700,
            background: "var(--green, #22c55e)",
            color: "#000",
            border: "none",
            borderRadius: 4,
            cursor: saving ? "not-allowed" : "pointer",
            opacity: saving ? 0.5 : 1,
          }}
        >
          {saving ? "Saving..." : "Save"}
        </button>
      </div>

      {error && (
        <div
          style={{
            padding: 6,
            marginBottom: 8,
            background: "rgba(239,68,68,0.1)",
            border: "1px solid var(--red, #ef4444)",
            borderRadius: 6,
            fontSize: 11,
            color: "var(--red, #ef4444)",
          }}
        >
          {error}
        </div>
      )}

      {/* Canvas overlay area */}
      <div
        style={{
          position: "relative",
          width,
          height,
          border: "1px dashed var(--border, #333)",
          borderRadius: 8,
          overflow: "hidden",
        }}
      >
        <FabricCanvas
          ref={fabricRef}
          width={width}
          height={height}
          activeTool={activeTool}
        />
      </div>
    </div>
  );
}
