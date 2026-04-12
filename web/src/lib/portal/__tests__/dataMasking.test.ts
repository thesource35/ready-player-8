import { describe, it, expect } from "vitest";

describe("Data Masking", () => {
  it.todo("never queries disabled sections from database (D-123)");
  it.todo(
    "masks budget to percentages when show_exact_amounts is false (D-30)",
  );
  it.todo("shows exact amounts when show_exact_amounts is true");
  it.todo("hides change order dollars when budget section disabled (D-38)");
  it.todo(
    "hides change order dollars when budget enabled but masked (D-38)",
  );
  it.todo("hides empty sections from portal (D-44)");
});
