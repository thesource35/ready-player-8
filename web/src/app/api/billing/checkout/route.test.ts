import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ─── Mocks (must be at module top level) ─────────────────────────────

vi.mock("server-only", () => ({}));

vi.mock("@/lib/billing/square", () => ({
  getSquarePaymentLink: vi.fn(() => "https://square.link/test-checkout"),
}));

import { POST, GET } from "./route";
import { getSquarePaymentLink } from "@/lib/billing/square";

// ─── Helpers ─────────────────────────────────────────────────────────

function makePostRequest(body: unknown): Request {
  return new Request("http://localhost:3000/api/billing/checkout", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

function makeGetRequest(params: Record<string, string>): Request {
  const url = new URL("http://localhost:3000/api/billing/checkout");
  Object.entries(params).forEach(([k, v]) => url.searchParams.set(k, v));
  return new Request(url.toString());
}

// ─── Tests ───────────────────────────────────────────────────────────

describe("Checkout route", () => {
  beforeEach(() => {
    vi.mocked(getSquarePaymentLink).mockReturnValue("https://square.link/test-checkout");
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("POST", () => {
    it("returns 200 with provider, payMethod, and url for valid input", async () => {
      const res = await POST(makePostRequest({
        planId: "pm",
        billing: "monthly",
        payMethod: "card",
      }));
      expect(res.status).toBe(200);
      const json = await res.json();
      expect(json.provider).toBe("square");
      expect(json.payMethod).toBe("card");
      expect(json.url).toBe("https://square.link/test-checkout");
    });

    it("returns 400 for invalid planId", async () => {
      const res = await POST(makePostRequest({
        planId: "enterprise",
        billing: "monthly",
        payMethod: "card",
      }));
      expect(res.status).toBe(400);
      const json = await res.json();
      expect(json.error).toMatch(/invalid plan/i);
    });

    it("returns 400 for invalid billing interval", async () => {
      const res = await POST(makePostRequest({
        planId: "pm",
        billing: "weekly",
        payMethod: "card",
      }));
      expect(res.status).toBe(400);
      const json = await res.json();
      expect(json.error).toMatch(/invalid billing/i);
    });

    it("returns 400 for unsupported payment method", async () => {
      const res = await POST(makePostRequest({
        planId: "pm",
        billing: "monthly",
        payMethod: "crypto",
      }));
      expect(res.status).toBe(400);
      const json = await res.json();
      expect(json.error).toMatch(/unsupported payment/i);
    });

    it("returns 400 for invalid JSON body", async () => {
      const req = new Request("http://localhost:3000/api/billing/checkout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: "not json",
      });
      const res = await POST(req);
      expect(res.status).toBe(400);
    });

    it("returns 503 when getSquarePaymentLink returns empty string", async () => {
      vi.mocked(getSquarePaymentLink).mockReturnValue("");
      const res = await POST(makePostRequest({
        planId: "pm",
        billing: "monthly",
        payMethod: "card",
      }));
      expect(res.status).toBe(503);
      const json = await res.json();
      expect(json.error).toBeDefined();
    });

    it("returns apple payMethod in response when apple is selected", async () => {
      const res = await POST(makePostRequest({
        planId: "pm",
        billing: "annual",
        payMethod: "apple",
      }));
      expect(res.status).toBe(200);
      const json = await res.json();
      expect(json.payMethod).toBe("apple");
      expect(json.provider).toBe("square");
    });
  });

  describe("GET", () => {
    it("returns redirect for valid query params", async () => {
      const res = await GET(makeGetRequest({
        plan: "pm",
        billing: "monthly",
        payMethod: "card",
      }));
      // NextResponse.redirect returns 307
      expect(res.status).toBe(307);
      const location = res.headers.get("location");
      expect(location).toContain("square.link");
    });

    it("returns 400 for invalid plan in query params", async () => {
      const res = await GET(makeGetRequest({
        plan: "invalid",
        billing: "monthly",
      }));
      expect(res.status).toBe(400);
      const json = await res.json();
      expect(json.error).toBeDefined();
    });
  });
});
