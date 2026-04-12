import { describe, it, expect } from "vitest";

describe("CSS Sanitization", () => {
  it.todo("strips expression() calls");
  it.todo("strips javascript: URLs");
  it.todo("strips @import rules");
  it.todo("strips behavior: property");
  it.todo("strips -moz-binding");
  it.todo("allows safe visual properties (color, background, border)");
  it.todo("limits CSS to 10KB");
});
