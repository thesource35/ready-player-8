// Phase 16 FIELD-03 (Wave 3): annotation schema + renderer tests.

import { describe, it, expect } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  parseLayerJson,
  type LayerJsonV1,
} from "@/lib/field/annotations/schema";
import { renderToSvg } from "@/lib/field/annotations/render";

const FIXTURE_PATH = join(
  process.cwd(),
  "..",
  "tests",
  "fixtures",
  "annotations",
  "v1-sample.json"
);

function loadFixture(): unknown {
  return JSON.parse(readFileSync(FIXTURE_PATH, "utf8"));
}

describe("phase-16 annotation schema", () => {
  it("parses the v1 fixture", () => {
    const raw = loadFixture();
    const result = parseLayerJson(raw);
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.value.schema_version).toBe(1);
    expect(result.value.shapes).toHaveLength(5);
    expect(result.droppedUnknown).toBe(0);
  });

  it("silently drops shapes with unknown type (forward compat)", () => {
    const raw = loadFixture() as { shapes: unknown[] };
    raw.shapes.push({
      type: "unknown_future",
      magic: 42,
    });
    raw.shapes.push({
      type: "another_new_thing",
      payload: { nested: true },
    });

    const result = parseLayerJson(raw);
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.value.shapes).toHaveLength(5);
    expect(result.droppedUnknown).toBe(2);
  });

  it("rejects malformed known shapes", () => {
    const bad = {
      schema_version: 1,
      shapes: [{ type: "rect", x: "nope", y: 0, w: 1, h: 1, color: "#000", width: 1 }],
    };
    const result = parseLayerJson(bad);
    expect(result.ok).toBe(false);
  });

  it("rejects wrong schema_version", () => {
    expect(parseLayerJson({ schema_version: 2, shapes: [] }).ok).toBe(false);
  });
});

describe("phase-16 annotation renderer", () => {
  it("renders all 5 shape types from the fixture", () => {
    const raw = loadFixture();
    const parsed = parseLayerJson(raw);
    expect(parsed.ok).toBe(true);
    if (!parsed.ok) return;

    const svg = renderToSvg(parsed.value, 1000, 1000);
    expect(svg).toContain("<svg");
    expect(svg).toContain("</svg>");
    expect(svg).toContain("<path"); // stroke
    expect(svg).toContain("<line"); // arrow (composed of lines)
    expect(svg).toContain("<rect");
    expect(svg).toContain("<ellipse");
    expect(svg).toContain("<text");
    expect(svg).toContain("Crack in slab");
  });

  it("produces deterministic output", () => {
    const layer: LayerJsonV1 = {
      schema_version: 1,
      shapes: [
        {
          type: "stroke",
          color: "#ff0000",
          width: 2,
          points: [
            [0.1, 0.1],
            [0.5, 0.5],
          ],
        },
      ],
    };
    const a = renderToSvg(layer, 100, 100);
    const b = renderToSvg(layer, 100, 100);
    expect(a).toBe(b);
    expect(a).toContain(`d="M10,10 L50,50"`);
    expect(a).toContain(`stroke="#ff0000"`);
  });

  it("escapes text content to prevent SVG injection (T-16-XSS)", () => {
    const layer: LayerJsonV1 = {
      schema_version: 1,
      shapes: [
        {
          type: "text",
          x: 0.5,
          y: 0.5,
          text: "<script>alert(1)</script>",
          color: "#fff",
          size: 12,
        },
      ],
    };
    const svg = renderToSvg(layer, 100, 100);
    expect(svg).not.toContain("<script>");
    expect(svg).toContain("&lt;script&gt;");
  });
});
