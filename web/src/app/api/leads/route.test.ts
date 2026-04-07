import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";

// vi.hoisted ensures mockSingle is available when vi.mock factories run (hoisted)
const { mockSingle } = vi.hoisted(() => ({
  mockSingle: vi.fn().mockResolvedValue({
    data: { id: "test-lead-id" },
    error: null,
  }),
}));

vi.mock("@supabase/supabase-js", () => ({
  createClient: vi.fn().mockReturnValue({
    from: vi.fn().mockReturnValue({
      insert: vi.fn().mockReturnValue({
        select: vi.fn().mockReturnValue({
          single: mockSingle,
        }),
      }),
    }),
  }),
}));

vi.mock("@/lib/csrf", () => ({
  verifyCsrfOrigin: vi.fn().mockReturnValue(true),
}));

vi.mock("@/lib/validation", () => {
  const { z } = require("zod");
  return {
    leadSchema: z.object({
      fullName: z.string().min(1),
      email: z.string().email(),
      phone: z.string().optional(),
      company: z.string().optional(),
      equipmentType: z.string().min(1),
      category: z.string().optional(),
      projectName: z.string().optional(),
      projectLocation: z.string().optional(),
      rentalStart: z.string().optional(),
      rentalDuration: z.string().optional(),
      budgetRange: z.string().optional(),
      quantity: z.number().optional(),
      deliveryNeeded: z.boolean().optional(),
      notes: z.string().optional(),
    }),
  };
});

import { POST } from "./route";
import { verifyCsrfOrigin } from "@/lib/csrf";

const validLead = {
  fullName: "John Builder",
  email: "john@construction.com",
  equipmentType: "Excavator",
};

function makeRequest(body: unknown): Request {
  return new Request("http://localhost:3000/api/leads", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      origin: "http://localhost:3000",
      host: "localhost:3000",
    },
    body: JSON.stringify(body),
  });
}

describe("POST /api/leads", () => {
  beforeEach(() => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://test.supabase.co");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "test-key");
    vi.mocked(verifyCsrfOrigin).mockReturnValue(true);
    mockSingle.mockResolvedValue({
      data: { id: "test-lead-id" },
      error: null,
    });
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.clearAllMocks();
  });

  it("returns 200 with success and id for valid lead", async () => {
    const res = await POST(makeRequest(validLead));
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.success).toBe(true);
    expect(json.id).toBe("test-lead-id");
  });

  it("returns 400 for invalid email", async () => {
    const res = await POST(
      makeRequest({ fullName: "Test", email: "not-an-email", equipmentType: "Crane" })
    );
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.details.email).toBeDefined();
    expect(Array.isArray(json.details.email)).toBe(true);
  });

  it("returns 400 for missing fullName", async () => {
    const res = await POST(
      makeRequest({ email: "test@test.com", equipmentType: "Crane" })
    );
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toContain("Validation failed");
  });

  it("returns 403 when CSRF check fails", async () => {
    vi.mocked(verifyCsrfOrigin).mockReturnValueOnce(false);
    const res = await POST(makeRequest(validLead));
    expect(res.status).toBe(403);
    const json = await res.json();
    expect(json.error).toContain("Forbidden");
  });

  it("returns 503 when Supabase env vars are missing", async () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "");
    vi.stubEnv("SUPABASE_SERVICE_ROLE_KEY", "");
    const res = await POST(makeRequest(validLead));
    expect(res.status).toBe(503);
    const json = await res.json();
    expect(json.error).toContain("not configured");
  });

  it("returns 500 when Supabase insert fails", async () => {
    mockSingle.mockResolvedValueOnce({
      data: null,
      error: { message: "insert failed" },
    });
    const res = await POST(makeRequest(validLead));
    expect(res.status).toBe(500);
    const json = await res.json();
    expect(json.error).toContain("Failed to submit lead");
  });
});
