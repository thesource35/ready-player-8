import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ─── Mocks (must be at module top level) ─────────────────────────────

const mockUpsert = vi.fn().mockResolvedValue({ error: null });
const mockMaybeSingle = vi.fn().mockResolvedValue({ data: null });
const mockListUsers = vi.fn().mockResolvedValue({
  data: {
    users: [{ id: "user-1", email: "test@test.com" }],
  },
  error: null,
});

vi.mock("@supabase/supabase-js", () => ({
  createClient: () => ({
    auth: {
      admin: {
        listUsers: mockListUsers,
      },
    },
    from: () => ({
      upsert: mockUpsert,
      select: () => ({
        eq: () => ({
          maybeSingle: mockMaybeSingle,
        }),
      }),
    }),
  }),
}));

vi.mock("@/lib/supabase/env", () => ({
  getSupabaseUrl: () => "https://test.supabase.co",
  getSupabaseServerKey: () => "test-key",
}));

import { POST } from "./route";

// ─── Helpers ─────────────────────────────────────────────────────────

async function generateSignature(
  body: string,
  secret: string,
  timestampOverride?: number,
): Promise<string> {
  const timestamp = timestampOverride ?? Math.floor(Date.now() / 1000);
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const payload = `${timestamp}.${body}`;
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  const hex = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `ts=${timestamp};h1=${hex}`;
}

const subscriptionBody = {
  event_type: "subscription.created",
  data: {
    id: "sub-123",
    customer_id: "cust-456",
    customer: { email: "test@test.com" },
    items: [{ price: { product_id: "pro_field", name: "Field Pro" } }],
  },
};

function makeRequest(body: string, headers: Record<string, string> = {}): Request {
  return new Request("http://localhost:3000/api/webhooks/paddle", {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body,
  });
}

const SECRET = "test-webhook-secret";

// ─── Tests ───────────────────────────────────────────────────────────

describe("Paddle webhook route", () => {
  beforeEach(() => {
    vi.stubEnv("PADDLE_WEBHOOK_SECRET", SECRET);
    mockListUsers.mockResolvedValue({
      data: { users: [{ id: "user-1", email: "test@test.com" }] },
      error: null,
    });
    mockUpsert.mockResolvedValue({ error: null });
    mockMaybeSingle.mockResolvedValue({ data: null });
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
  });

  it("returns 503 when PADDLE_WEBHOOK_SECRET is missing", async () => {
    vi.stubEnv("PADDLE_WEBHOOK_SECRET", "");
    const res = await POST(makeRequest("{}"));
    expect(res.status).toBe(503);
    const json = await res.json();
    expect(json.error).toMatch(/not configured/i);
  });

  it("returns 401 when paddle-signature header is missing", async () => {
    const res = await POST(makeRequest("{}"));
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error).toMatch(/missing signature/i);
  });

  it("returns 401 when body is tampered after signing", async () => {
    const originalBody = JSON.stringify(subscriptionBody);
    const signature = await generateSignature(originalBody, SECRET);
    const tamperedBody = JSON.stringify({ ...subscriptionBody, extra: "tampered" });
    const req = makeRequest(tamperedBody, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(401);
    const json = await res.json();
    expect(json.error).toMatch(/invalid signature/i);
  });

  it("returns 401 when timestamp is expired (older than 5 minutes)", async () => {
    const body = JSON.stringify(subscriptionBody);
    const expiredTs = Math.floor(Date.now() / 1000) - 600; // 10 minutes ago
    const signature = await generateSignature(body, SECRET, expiredTs);
    const req = makeRequest(body, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it("returns success with tier for valid subscription.created", async () => {
    const body = JSON.stringify(subscriptionBody);
    const signature = await generateSignature(body, SECRET);
    const req = makeRequest(body, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.success).toBe(true);
    expect(json.tier).toBe("field");
  });

  it("sets tier to free on subscription.canceled", async () => {
    const canceledBody = {
      ...subscriptionBody,
      event_type: "subscription.canceled",
    };
    const body = JSON.stringify(canceledBody);
    const signature = await generateSignature(body, SECRET);
    const req = makeRequest(body, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.success).toBe(true);
    expect(json.tier).toBe("free");
  });

  it("returns { received: true } for non-subscription events", async () => {
    const transactionBody = {
      event_type: "transaction.completed",
      data: { id: "txn-789" },
    };
    const body = JSON.stringify(transactionBody);
    const signature = await generateSignature(body, SECRET);
    const req = makeRequest(body, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.received).toBe(true);
  });

  it("returns warning when no matching user is found", async () => {
    mockListUsers.mockResolvedValue({
      data: { users: [] },
      error: null,
    });
    mockMaybeSingle.mockResolvedValue({ data: null });

    const body = JSON.stringify(subscriptionBody);
    const signature = await generateSignature(body, SECRET);
    const req = makeRequest(body, { "paddle-signature": signature });
    const res = await POST(req);
    expect(res.status).toBe(200);
    const json = await res.json();
    expect(json.received).toBe(true);
    expect(json.warning).toBeDefined();
  });

  it("returns 503 when Supabase env vars are missing", async () => {
    // Re-mock env module to return empty strings
    const envModule = await import("@/lib/supabase/env");
    vi.spyOn(envModule, "getSupabaseUrl").mockReturnValue("");
    vi.spyOn(envModule, "getSupabaseServerKey").mockReturnValue("test-key");

    const body = JSON.stringify(subscriptionBody);
    const signature = await generateSignature(body, SECRET);
    const req = makeRequest(body, { "paddle-signature": signature });

    // Need to re-import route to pick up the spied module
    // Instead, we test by dynamically importing
    const { POST: POST2 } = await import("./route");
    const res = await POST2(req);
    expect(res.status).toBe(503);
    const json = await res.json();
    expect(json.error).toMatch(/not configured/i);
  });
});
