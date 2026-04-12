import { describe, it, expect } from "vitest";

describe("Image Processor", () => {
  it.todo("strips GPS EXIF data from photos (D-118)");
  it.todo("preserves date/time EXIF data (D-118)");
  it.todo("validates MIME type matches extension (D-124)");
  it.todo("rejects files exceeding size limit (2MB logo, 5MB cover)");
  it.todo("validates PNG and SVG formats for logos (D-75)");
  it.todo("scans SVG for embedded scripts (D-124)");
  it.todo("resizes images server-side (D-124)");
});
