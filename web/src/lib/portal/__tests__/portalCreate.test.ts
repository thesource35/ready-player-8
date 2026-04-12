import { describe, it, expect } from "vitest";

describe("Portal Link Creation", () => {
  it.todo("generates a UUID token for new portal link");
  it.todo("creates portal config with default template sections");
  it.todo("enforces unique (company_slug, slug) constraint");
  it.todo("sets expiry based on selected option (7/30/90/null days)");
  it.todo("validates required fields: project_id, slug, company_slug");
  it.todo("copies URL to clipboard on success");
  it.todo("sends branded email when client_email provided");
});
