import { describe, it, expect } from "vitest";
import { AttachmentList } from "./AttachmentList";

describe("AttachmentList", () => {
  it("is a function component", () => {
    expect(typeof AttachmentList).toBe("function");
  });
  it.todo("shows empty state when list is empty");
  it.todo("renders one row per document");
  it.todo("opens DocumentPreview when row clicked");
});
