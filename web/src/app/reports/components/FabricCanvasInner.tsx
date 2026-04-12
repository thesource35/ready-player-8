"use client";

import {
  useEffect,
  useRef,
  useImperativeHandle,
  forwardRef,
  useCallback,
} from "react";

// Internal Fabric.js canvas component — loaded only on client (ssr: false via parent)
// Provides circle, arrow, highlight, and freeform draw tools per D-98

type AnnotationTool = "select" | "circle" | "arrow" | "highlight" | "draw";

type FabricCanvasInnerProps = {
  width: number;
  height: number;
  activeTool: AnnotationTool;
};

type FabricRef = {
  toJSON: () => unknown;
  loadFromJSON: (json: unknown) => void;
  clear: () => void;
  toDataURL: () => string;
};

/* eslint-disable @typescript-eslint/no-explicit-any */

const FabricCanvasInner = forwardRef<FabricRef, FabricCanvasInnerProps>(
  function FabricCanvasInner({ width, height, activeTool }, ref) {
    const canvasElRef = useRef<HTMLCanvasElement>(null);
    const fabricCanvasRef = useRef<any>(null);
    const fabricModuleRef = useRef<any>(null);

    // Initialize Fabric.js canvas
    useEffect(() => {
      let mounted = true;

      async function initFabric() {
        try {
          const fabric = await import("fabric");
          if (!mounted || !canvasElRef.current) return;
          fabricModuleRef.current = fabric;

          const canvas = new fabric.Canvas(canvasElRef.current, {
            width,
            height,
            backgroundColor: "transparent",
            selection: true,
          });

          fabricCanvasRef.current = canvas;
        } catch (err) {
          console.error("[FabricCanvasInner] Failed to initialize Fabric.js:", err);
        }
      }

      initFabric();

      return () => {
        mounted = false;
        if (fabricCanvasRef.current) {
          fabricCanvasRef.current.dispose();
          fabricCanvasRef.current = null;
        }
      };
    }, [width, height]);

    // Update canvas mode based on active tool
    useEffect(() => {
      const canvas = fabricCanvasRef.current;
      const fabric = fabricModuleRef.current;
      if (!canvas || !fabric) return;

      // Reset drawing mode
      canvas.isDrawingMode = false;
      canvas.selection = true;

      if (activeTool === "draw") {
        canvas.isDrawingMode = true;
        if (canvas.freeDrawingBrush) {
          canvas.freeDrawingBrush.color = "#f59e0b";
          canvas.freeDrawingBrush.width = 2;
        }
      } else if (activeTool === "select") {
        canvas.selection = true;
      }

      // For shape tools (circle, arrow, highlight), we add objects on mouse down
      const handleMouseDown = (opt: any) => {
        if (activeTool === "select" || activeTool === "draw") return;

        const pointer = canvas.getScenePoint
          ? canvas.getScenePoint(opt.e)
          : canvas.getPointer
            ? canvas.getPointer(opt.e)
            : { x: 0, y: 0 };

        if (activeTool === "circle") {
          const circle = new fabric.Circle({
            left: pointer.x - 20,
            top: pointer.y - 20,
            radius: 20,
            fill: "transparent",
            stroke: "#ef4444",
            strokeWidth: 2,
          });
          canvas.add(circle);
        } else if (activeTool === "arrow") {
          const line = new fabric.Line(
            [pointer.x, pointer.y, pointer.x + 60, pointer.y],
            {
              stroke: "#22d3ee",
              strokeWidth: 2,
            }
          );
          // Arrow head triangle
          const triangle = new fabric.Triangle({
            left: pointer.x + 55,
            top: pointer.y - 6,
            width: 12,
            height: 12,
            fill: "#22d3ee",
            angle: 90,
          });
          canvas.add(line);
          canvas.add(triangle);
        } else if (activeTool === "highlight") {
          const rect = new fabric.Rect({
            left: pointer.x - 30,
            top: pointer.y - 10,
            width: 60,
            height: 20,
            fill: "rgba(245, 158, 11, 0.3)",
            stroke: "transparent",
            strokeWidth: 0,
          });
          canvas.add(rect);
        }

        canvas.renderAll();
      };

      canvas.on("mouse:down", handleMouseDown);

      return () => {
        canvas.off("mouse:down", handleMouseDown);
      };
    }, [activeTool]);

    // Expose methods to parent via ref
    const toJSON = useCallback(() => {
      if (!fabricCanvasRef.current) return { objects: [] };
      return fabricCanvasRef.current.toJSON();
    }, []);

    const loadFromJSON = useCallback((json: unknown) => {
      if (!fabricCanvasRef.current) return;
      fabricCanvasRef.current.loadFromJSON(json, () => {
        fabricCanvasRef.current?.renderAll();
      });
    }, []);

    const clear = useCallback(() => {
      if (!fabricCanvasRef.current) return;
      fabricCanvasRef.current.clear();
      fabricCanvasRef.current.backgroundColor = "transparent";
      fabricCanvasRef.current.renderAll();
    }, []);

    const toDataURL = useCallback(() => {
      if (!fabricCanvasRef.current) return "";
      return fabricCanvasRef.current.toDataURL({ format: "png" });
    }, []);

    useImperativeHandle(ref, () => ({
      toJSON,
      loadFromJSON,
      clear,
      toDataURL,
    }));

    return (
      <canvas
        ref={canvasElRef}
        style={{
          display: "block",
          width,
          height,
        }}
      />
    );
  }
);

export default FabricCanvasInner;
