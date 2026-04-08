// Phase 16 FIELD-03: Deterministic SVG renderer for LayerJsonV1.
//
// Used by tests (snapshot) and by the web editor as a preview layer.
// Pure function: no randomness, no ids, no timestamps.
//
// T-16-XSS: text is escaped and emitted as SVG text content, never as
// raw markup.

import type { LayerJsonV1, Shape } from "./schema";

function escapeXml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function fmt(n: number): string {
  if (!Number.isFinite(n)) return "0";
  return Number.parseFloat(n.toFixed(3)).toString();
}

function renderShape(shape: Shape, w: number, h: number): string {
  switch (shape.type) {
    case "stroke": {
      if (shape.points.length === 0) return "";
      const d = shape.points
        .map(([x, y], i) => `${i === 0 ? "M" : "L"}${fmt(x * w)},${fmt(y * h)}`)
        .join(" ");
      return `<path d="${d}" fill="none" stroke="${escapeXml(shape.color)}" stroke-width="${fmt(shape.width)}" stroke-linecap="round" stroke-linejoin="round"/>`;
    }
    case "arrow": {
      const [x1, y1] = shape.from;
      const [x2, y2] = shape.to;
      const X1 = x1 * w;
      const Y1 = y1 * h;
      const X2 = x2 * w;
      const Y2 = y2 * h;
      const dx = X2 - X1;
      const dy = Y2 - Y1;
      const len = Math.hypot(dx, dy) || 1;
      const ux = dx / len;
      const uy = dy / len;
      const head = Math.max(8, shape.width * 3);
      const ax1 = X2 - ux * head - uy * head * 0.5;
      const ay1 = Y2 - uy * head + ux * head * 0.5;
      const ax2 = X2 - ux * head + uy * head * 0.5;
      const ay2 = Y2 - uy * head - ux * head * 0.5;
      const color = escapeXml(shape.color);
      const sw = fmt(shape.width);
      return (
        `<line x1="${fmt(X1)}" y1="${fmt(Y1)}" x2="${fmt(X2)}" y2="${fmt(Y2)}" stroke="${color}" stroke-width="${sw}" stroke-linecap="round"/>` +
        `<line x1="${fmt(X2)}" y1="${fmt(Y2)}" x2="${fmt(ax1)}" y2="${fmt(ay1)}" stroke="${color}" stroke-width="${sw}" stroke-linecap="round"/>` +
        `<line x1="${fmt(X2)}" y1="${fmt(Y2)}" x2="${fmt(ax2)}" y2="${fmt(ay2)}" stroke="${color}" stroke-width="${sw}" stroke-linecap="round"/>`
      );
    }
    case "rect": {
      return `<rect x="${fmt(shape.x * w)}" y="${fmt(shape.y * h)}" width="${fmt(shape.w * w)}" height="${fmt(shape.h * h)}" fill="none" stroke="${escapeXml(shape.color)}" stroke-width="${fmt(shape.width)}"/>`;
    }
    case "ellipse": {
      return `<ellipse cx="${fmt(shape.cx * w)}" cy="${fmt(shape.cy * h)}" rx="${fmt(shape.rx * w)}" ry="${fmt(shape.ry * h)}" fill="none" stroke="${escapeXml(shape.color)}" stroke-width="${fmt(shape.width)}"/>`;
    }
    case "text": {
      return `<text x="${fmt(shape.x * w)}" y="${fmt(shape.y * h)}" fill="${escapeXml(shape.color)}" font-size="${fmt(shape.size)}" font-family="sans-serif">${escapeXml(shape.text)}</text>`;
    }
  }
}

/**
 * Deterministic SVG renderer. Shapes are rendered in array order.
 */
export function renderToSvg(layer: LayerJsonV1, w: number, h: number): string {
  const body = layer.shapes.map((s) => renderShape(s, w, h)).join("");
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${fmt(w)} ${fmt(h)}" width="${fmt(w)}" height="${fmt(h)}">${body}</svg>`;
}
