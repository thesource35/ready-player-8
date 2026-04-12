import { describe, it, expect } from "vitest";

describe("Portal Rate Limiting", () => {
  it.todo("limits portal views to 100/day per link (D-109)");
  it.todo("limits management requests to 50/hour per user (D-109)");
  it.todo("limits failed lookups to 10/min per IP (D-122)");
  it.todo("returns 429 with rate limit headers on exceeded");
  it.todo("adds 200ms delay on 404 responses (D-122)");
});
