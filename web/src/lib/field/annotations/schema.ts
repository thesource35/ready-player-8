// Phase 16 FIELD-03: v1 annotation layer_json schema.
//
// All coordinates are normalized 0..1 against the photo's intrinsic
// dimensions so the same layer renders correctly at any display size.
//
// Forward-compat rule (T-16-FWDCOMPAT): parseLayerJson silently drops
// shape entries whose `type` is unknown to this version. New shape types
// added in future schema revisions must not crash v1 readers.
//
// zod is NOT a dependency in web/ — we hand-roll validation, matching
// the convention used in field/attachments.ts.

export type Point = [number, number];

export type Shape =
  | { type: "stroke"; points: Point[]; color: string; width: number }
  | { type: "arrow"; from: Point; to: Point; color: string; width: number }
  | { type: "rect"; x: number; y: number; w: number; h: number; color: string; width: number }
  | {
      type: "ellipse";
      cx: number;
      cy: number;
      rx: number;
      ry: number;
      color: string;
      width: number;
    }
  | { type: "text"; x: number; y: number; text: string; color: string; size: number };

export type LayerJsonV1 = {
  schema_version: 1;
  shapes: Shape[];
};

export const KNOWN_SHAPE_TYPES = [
  "stroke",
  "arrow",
  "rect",
  "ellipse",
  "text",
] as const;

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null;
}

function isNum(v: unknown): v is number {
  return typeof v === "number" && Number.isFinite(v);
}

function isNormNum(v: unknown): v is number {
  // Allow slight float slop; clamp callers can re-clamp.
  return isNum(v) && v >= -0.0001 && v <= 1.0001;
}

function isPoint(v: unknown): v is Point {
  return Array.isArray(v) && v.length === 2 && isNormNum(v[0]) && isNormNum(v[1]);
}

function isColor(v: unknown): v is string {
  return typeof v === "string" && v.length > 0 && v.length <= 32;
}

function isText(v: unknown): v is string {
  return typeof v === "string" && v.length <= 2000;
}

function validateShape(raw: unknown): Shape | null {
  if (!isObject(raw)) return null;
  const t = raw.type;
  if (typeof t !== "string") return null;

  switch (t) {
    case "stroke": {
      if (!Array.isArray(raw.points)) return null;
      const points: Point[] = [];
      for (const p of raw.points) {
        if (!isPoint(p)) return null;
        points.push([p[0], p[1]]);
      }
      if (!isColor(raw.color) || !isNum(raw.width)) return null;
      return { type: "stroke", points, color: raw.color, width: raw.width };
    }
    case "arrow": {
      if (!isPoint(raw.from) || !isPoint(raw.to)) return null;
      if (!isColor(raw.color) || !isNum(raw.width)) return null;
      return {
        type: "arrow",
        from: [raw.from[0], raw.from[1]],
        to: [raw.to[0], raw.to[1]],
        color: raw.color,
        width: raw.width,
      };
    }
    case "rect": {
      if (!isNormNum(raw.x) || !isNormNum(raw.y)) return null;
      if (!isNum(raw.w) || !isNum(raw.h)) return null;
      if (!isColor(raw.color) || !isNum(raw.width)) return null;
      return {
        type: "rect",
        x: raw.x,
        y: raw.y,
        w: raw.w,
        h: raw.h,
        color: raw.color,
        width: raw.width,
      };
    }
    case "ellipse": {
      if (!isNormNum(raw.cx) || !isNormNum(raw.cy)) return null;
      if (!isNum(raw.rx) || !isNum(raw.ry)) return null;
      if (!isColor(raw.color) || !isNum(raw.width)) return null;
      return {
        type: "ellipse",
        cx: raw.cx,
        cy: raw.cy,
        rx: raw.rx,
        ry: raw.ry,
        color: raw.color,
        width: raw.width,
      };
    }
    case "text": {
      if (!isNormNum(raw.x) || !isNormNum(raw.y)) return null;
      if (!isText(raw.text)) return null;
      if (!isColor(raw.color) || !isNum(raw.size)) return null;
      return {
        type: "text",
        x: raw.x,
        y: raw.y,
        text: raw.text,
        color: raw.color,
        size: raw.size,
      };
    }
    default:
      // Unknown shape type — forward compat: drop silently.
      return null;
  }
}

export type ParseResult =
  | { ok: true; value: LayerJsonV1; droppedUnknown: number }
  | { ok: false; error: string };

/**
 * Parse untrusted JSON into a LayerJsonV1.
 * - Unknown `type` entries are dropped silently (forward compat).
 * - Malformed known shapes cause a hard failure (400).
 */
export function parseLayerJson(input: unknown): ParseResult {
  if (!isObject(input)) {
    return { ok: false, error: "layer_json must be an object" };
  }
  if (input.schema_version !== 1) {
    return { ok: false, error: "unsupported schema_version" };
  }
  if (!Array.isArray(input.shapes)) {
    return { ok: false, error: "shapes must be an array" };
  }

  const shapes: Shape[] = [];
  let droppedUnknown = 0;

  for (const raw of input.shapes) {
    const t = isObject(raw) ? raw.type : undefined;
    const isKnown =
      typeof t === "string" &&
      (KNOWN_SHAPE_TYPES as readonly string[]).includes(t);

    if (!isKnown) {
      droppedUnknown += 1;
      continue;
    }

    const shape = validateShape(raw);
    if (!shape) {
      return { ok: false, error: `invalid shape of type ${t}` };
    }
    shapes.push(shape);
  }

  return {
    ok: true,
    value: { schema_version: 1, shapes },
    droppedUnknown,
  };
}

export function emptyLayer(): LayerJsonV1 {
  return { schema_version: 1, shapes: [] };
}
