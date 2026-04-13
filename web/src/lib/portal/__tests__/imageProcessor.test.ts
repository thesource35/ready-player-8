import { describe, it, expect } from "vitest";
import { validateSVG } from "../imageProcessor";

describe("SVG Validation", () => {
  it("rejects SVG with script tags", () => {
    const result = validateSVG('<svg><script>alert(1)</script></svg>');
    expect(result.valid).toBe(false);
    expect(result.error).toContain("script");
  });

  it("rejects SVG with onclick handlers", () => {
    const result = validateSVG('<svg onclick="alert(1)"><rect/></svg>');
    expect(result.valid).toBe(false);
    expect(result.error).toContain("event handler");
  });

  it("rejects SVG with onerror handlers", () => {
    const result = validateSVG('<svg><image onerror="alert(1)"/></svg>');
    expect(result.valid).toBe(false);
    expect(result.error).toContain("event handler");
  });

  it("rejects SVG with onload handlers", () => {
    const result = validateSVG('<svg onload="alert(1)"><rect/></svg>');
    expect(result.valid).toBe(false);
    expect(result.error).toContain("event handler");
  });

  it("rejects SVG with javascript: protocol", () => {
    const result = validateSVG('<svg><a href="javascript:alert(1)">click</a></svg>');
    expect(result.valid).toBe(false);
    expect(result.error).toContain("javascript:");
  });

  it("rejects SVG with external URL references (D-124)", () => {
    const result = validateSVG(
      '<svg><image xlink:href="https://evil.com/track.png"/></svg>'
    );
    expect(result.valid).toBe(false);
    expect(result.error).toContain("external URL");
  });

  it("rejects SVG with data: URI references (D-124)", () => {
    const result = validateSVG(
      '<svg><image href="data:image/png;base64,iVBORw0KGgo"/></svg>'
    );
    expect(result.valid).toBe(false);
    expect(result.error).toContain("data: URI");
  });

  it("accepts clean SVG with basic shapes", () => {
    const result = validateSVG(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><rect width="100" height="100" fill="blue"/><circle cx="50" cy="50" r="40" fill="red"/></svg>'
    );
    expect(result.valid).toBe(true);
    expect(result.error).toBeUndefined();
  });

  it("accepts clean SVG with text and paths", () => {
    const result = validateSVG(
      '<svg><text x="10" y="20" fill="black">Logo</text><path d="M0 0 L10 10" stroke="black"/></svg>'
    );
    expect(result.valid).toBe(true);
  });

  it("rejects empty/null SVG input", () => {
    const result = validateSVG("");
    expect(result.valid).toBe(false);
    expect(result.error).toContain("Empty");
  });

  it("rejects null input", () => {
    const result = validateSVG(null as unknown as string);
    expect(result.valid).toBe(false);
  });
});
