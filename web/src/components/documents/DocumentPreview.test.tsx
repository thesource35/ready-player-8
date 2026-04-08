import { describe, it, expect } from "vitest";
import { DocumentPreview } from "./DocumentPreview";

describe("DocumentPreview", () => {
  it("is a function component", () => {
    expect(typeof DocumentPreview).toBe("function");
  });
  it.todo("renders iframe for application/pdf");
  it.todo("renders img for image/png");
  it.todo("renders error state on fetch failure");
});
