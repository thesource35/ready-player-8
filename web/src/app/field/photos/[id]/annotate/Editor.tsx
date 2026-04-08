"use client";

// Phase 16 FIELD-03: Client-side annotation editor.
//
// Tools: stroke (freehand) / arrow / rect / ellipse / text / undo / save.
// Coordinates are normalized 0..1 against the displayed image's
// naturalWidth/naturalHeight so rendering is resolution-independent.
//
// Uses plain SVG polylines — perfect-freehand is not a project
// dependency. The render.ts module handles deterministic display.

import { useCallback, useRef, useState } from "react";
import type { LayerJsonV1, Shape } from "@/lib/field/annotations/schema";
import { saveAnnotation } from "./actions";

type Tool = "stroke" | "arrow" | "rect" | "ellipse" | "text";

type Props = {
  documentId: string;
  photoUrl: string;
  initialLayer: LayerJsonV1;
};

const COLORS: readonly string[] = ["#FF3B30", "#FFCC00", "#34C759", "#5AC8FA", "#FFFFFF"];

export function Editor({ documentId, photoUrl, initialLayer }: Props) {
  const [layer, setLayer] = useState<LayerJsonV1>(initialLayer);
  const [tool, setTool] = useState<Tool>("stroke");
  const [color, setColor] = useState<string>("#FF3B30");
  const [width, setWidth] = useState<number>(3);
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState<string>("");

  const svgRef = useRef<SVGSVGElement | null>(null);
  const dragStart = useRef<[number, number] | null>(null);
  const drawingStroke = useRef<[number, number][] | null>(null);

  const pointerToNorm = useCallback((e: React.PointerEvent<SVGSVGElement>) => {
    const svg = svgRef.current;
    if (!svg) return [0, 0] as [number, number];
    const rect = svg.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width;
    const y = (e.clientY - rect.top) / rect.height;
    return [Math.max(0, Math.min(1, x)), Math.max(0, Math.min(1, y))] as [number, number];
  }, []);

  const onPointerDown = (e: React.PointerEvent<SVGSVGElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    const p = pointerToNorm(e);
    if (tool === "stroke") {
      drawingStroke.current = [p];
    } else {
      dragStart.current = p;
    }
  };

  const onPointerMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (tool === "stroke" && drawingStroke.current) {
      drawingStroke.current.push(pointerToNorm(e));
      // trigger re-render by shallow-copying layer
      setLayer((l) => ({ ...l }));
    }
  };

  const onPointerUp = (e: React.PointerEvent<SVGSVGElement>) => {
    const end = pointerToNorm(e);
    if (tool === "stroke" && drawingStroke.current) {
      const points = drawingStroke.current.slice();
      drawingStroke.current = null;
      if (points.length >= 2) {
        const s: Shape = { type: "stroke", points, color, width };
        setLayer((l) => ({ ...l, shapes: [...l.shapes, s] }));
      }
      return;
    }
    const start = dragStart.current;
    dragStart.current = null;
    if (!start) return;
    if (tool === "arrow") {
      setLayer((l) => ({
        ...l,
        shapes: [...l.shapes, { type: "arrow", from: start, to: end, color, width }],
      }));
    } else if (tool === "rect") {
      const x = Math.min(start[0], end[0]);
      const y = Math.min(start[1], end[1]);
      const w = Math.abs(end[0] - start[0]);
      const h = Math.abs(end[1] - start[1]);
      setLayer((l) => ({ ...l, shapes: [...l.shapes, { type: "rect", x, y, w, h, color, width }] }));
    } else if (tool === "ellipse") {
      const cx = (start[0] + end[0]) / 2;
      const cy = (start[1] + end[1]) / 2;
      const rx = Math.abs(end[0] - start[0]) / 2;
      const ry = Math.abs(end[1] - start[1]) / 2;
      setLayer((l) => ({
        ...l,
        shapes: [...l.shapes, { type: "ellipse", cx, cy, rx, ry, color, width }],
      }));
    } else if (tool === "text") {
      const text = window.prompt("Label text:");
      if (text) {
        setLayer((l) => ({
          ...l,
          shapes: [...l.shapes, { type: "text", x: end[0], y: end[1], text, color, size: 24 }],
        }));
      }
    }
  };

  const undo = () => setLayer((l) => ({ ...l, shapes: l.shapes.slice(0, -1) }));

  const save = async () => {
    setSaving(true);
    setStatus("");
    const result = await saveAnnotation(documentId, layer);
    setSaving(false);
    setStatus(result.ok ? "Saved" : `Error ${result.status}: ${result.error}`);
  };

  return (
    <div>
      <div style={{ display: "flex", gap: 8, marginBottom: 12, flexWrap: "wrap" }}>
        {(["stroke", "arrow", "rect", "ellipse", "text"] as Tool[]).map((t) => (
          <button
            key={t}
            onClick={() => setTool(t)}
            style={{
              padding: "6px 12px",
              borderRadius: 6,
              border: "1px solid var(--border, #333)",
              background: tool === t ? "var(--accent, #f90)" : "transparent",
              color: tool === t ? "#000" : "inherit",
              cursor: "pointer",
            }}
          >
            {t}
          </button>
        ))}
        <div style={{ display: "flex", gap: 4, alignItems: "center" }}>
          {COLORS.map((c) => (
            <button
              key={c}
              onClick={() => setColor(c)}
              aria-label={`color ${c}`}
              style={{
                width: 24,
                height: 24,
                borderRadius: 12,
                background: c,
                border: color === c ? "2px solid #fff" : "1px solid #333",
                cursor: "pointer",
              }}
            />
          ))}
        </div>
        <input
          type="range"
          min={1}
          max={10}
          value={width}
          onChange={(e) => setWidth(Number(e.target.value))}
          aria-label="stroke width"
        />
        <button onClick={undo} disabled={layer.shapes.length === 0}>
          Undo
        </button>
        <button onClick={save} disabled={saving}>
          {saving ? "Saving…" : "Save"}
        </button>
        {status && <span style={{ marginLeft: 8 }}>{status}</span>}
      </div>

      <div style={{ position: "relative", display: "inline-block", maxWidth: "100%" }}>
        {photoUrl && (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={photoUrl}
            alt="photo to annotate"
            style={{ display: "block", maxWidth: "100%", height: "auto" }}
          />
        )}
        <svg
          ref={svgRef}
          viewBox="0 0 1 1"
          preserveAspectRatio="none"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          style={{
            position: "absolute",
            inset: 0,
            width: "100%",
            height: "100%",
            touchAction: "none",
            cursor: "crosshair",
          }}
        >
          {layer.shapes.map((s, i) => (
            <ShapeElement key={i} shape={s} />
          ))}
          {drawingStroke.current && drawingStroke.current.length >= 2 && (
            <polyline
              points={drawingStroke.current.map(([x, y]) => `${x},${y}`).join(" ")}
              fill="none"
              stroke={color}
              strokeWidth={width / 1000}
              strokeLinecap="round"
              strokeLinejoin="round"
              vectorEffect="non-scaling-stroke"
            />
          )}
        </svg>
      </div>
    </div>
  );
}

function ShapeElement({ shape }: { shape: Shape }) {
  const sw = shape.type === "text" ? 0 : shape.width;
  switch (shape.type) {
    case "stroke":
      return (
        <polyline
          points={shape.points.map(([x, y]) => `${x},${y}`).join(" ")}
          fill="none"
          stroke={shape.color}
          strokeWidth={sw}
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />
      );
    case "arrow":
      return (
        <line
          x1={shape.from[0]}
          y1={shape.from[1]}
          x2={shape.to[0]}
          y2={shape.to[1]}
          stroke={shape.color}
          strokeWidth={sw}
          vectorEffect="non-scaling-stroke"
          markerEnd="url(#arrow)"
        />
      );
    case "rect":
      return (
        <rect
          x={shape.x}
          y={shape.y}
          width={shape.w}
          height={shape.h}
          fill="none"
          stroke={shape.color}
          strokeWidth={sw}
          vectorEffect="non-scaling-stroke"
        />
      );
    case "ellipse":
      return (
        <ellipse
          cx={shape.cx}
          cy={shape.cy}
          rx={shape.rx}
          ry={shape.ry}
          fill="none"
          stroke={shape.color}
          strokeWidth={sw}
          vectorEffect="non-scaling-stroke"
        />
      );
    case "text":
      return (
        <text
          x={shape.x}
          y={shape.y}
          fill={shape.color}
          fontSize={shape.size / 1000}
          fontFamily="sans-serif"
        >
          {shape.text}
        </text>
      );
  }
}
