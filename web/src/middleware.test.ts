import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";

// vi.hoisted so mock factories can reference these
const { mockGetUser } = vi.hoisted(() => ({
  mockGetUser: vi.fn().mockResolvedValue({ data: { user: null } }),
}));

vi.mock("@supabase/ssr", () => ({
  createServerClient: vi.fn().mockImplementation(
    (_url: string, _key: string, _config: unknown) => ({
      auth: { getUser: mockGetUser },
    })
  ),
}));

vi.mock("@/lib/rate-limit", () => ({
  rateLimit: vi.fn().mockResolvedValue({
    success: true,
    limit: 30,
    remaining: 29,
    reset: Date.now() + 60000,
  }),
  getRateLimitHeaders: vi.fn().mockReturnValue({
    "X-RateLimit-Limit": "30",
    "X-RateLimit-Remaining": "29",
    "X-RateLimit-Reset": String(Date.now() + 60000),
  }),
}));

import { middleware } from "./middleware";
import { NextRequest } from "next/server";
import { rateLimit } from "@/lib/rate-limit";

function makeNextRequest(
  path: string,
  cookies?: Record<string, string>
): NextRequest {
  const url = new URL(path, "http://localhost:3000");
  const req = new NextRequest(url);
  if (cookies) {
    Object.entries(cookies).forEach(([name, value]) =>
      req.cookies.set(name, value)
    );
  }
  return req;
}

function makeFakeJWT(claims: {
  sub: string;
  email: string;
  exp: number;
}): string {
  const header = Buffer.from(JSON.stringify({ alg: "HS256" })).toString(
    "base64url"
  );
  const payload = Buffer.from(JSON.stringify(claims)).toString("base64url");
  return `${header}.${payload}.fakesignature`;
}

describe("middleware", () => {
  beforeEach(() => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "https://test.supabase.co");
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "test-anon-key");
    vi.mocked(rateLimit).mockResolvedValue({
      success: true,
      limit: 30,
      remaining: 29,
      reset: Date.now() + 60000,
    });
    mockGetUser.mockResolvedValue({ data: { user: null } });
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.clearAllMocks();
  });

  it('passes through public route "/"', async () => {
    const res = await middleware(makeNextRequest("/"));
    expect(res.status).toBe(200);
  });

  it('passes through public route "/login"', async () => {
    const res = await middleware(makeNextRequest("/login"));
    expect(res.status).toBe(200);
  });

  it("passes through static files (/_next/static/chunk.js)", async () => {
    const res = await middleware(makeNextRequest("/_next/static/chunk.js"));
    expect(res.status).toBe(200);
  });

  it("passes through files with extensions (/favicon.ico)", async () => {
    const res = await middleware(makeNextRequest("/favicon.ico"));
    expect(res.status).toBe(200);
  });

  it("returns 429 when API rate limit exceeded", async () => {
    vi.mocked(rateLimit).mockResolvedValueOnce({
      success: false,
      limit: 30,
      remaining: 0,
      reset: Date.now() + 60000,
    });
    const res = await middleware(makeNextRequest("/api/chat"));
    expect(res.status).toBe(429);
    const json = await res.json();
    expect(json.error).toContain("Rate limit");
  });

  it("passes through API route within rate limit with headers", async () => {
    const res = await middleware(makeNextRequest("/api/chat"));
    expect(res.status).toBe(200);
    expect(res.headers.get("X-RateLimit-Limit")).toBe("30");
  });

  it("passes through with valid JWT cookie (future exp)", async () => {
    const futureExp = Math.floor(Date.now() / 1000) + 3600;
    const jwt = makeFakeJWT({
      sub: "user-1",
      email: "test@test.com",
      exp: futureExp,
    });
    const res = await middleware(
      makeNextRequest("/dashboard", { "sb-test-auth-token": jwt })
    );
    expect(res.status).toBe(200);
  });

  it("passes through with expired JWT but valid Supabase user", async () => {
    const pastExp = Math.floor(Date.now() / 1000) - 3600;
    const jwt = makeFakeJWT({
      sub: "user-1",
      email: "test@test.com",
      exp: pastExp,
    });
    mockGetUser.mockResolvedValueOnce({
      data: { user: { id: "user-1", email: "test@test.com" } },
    });
    const res = await middleware(
      makeNextRequest("/dashboard", { "sb-test-auth-token": jwt })
    );
    expect(res.status).toBe(200);
  });

  it("redirects to /login when no session on protected route", async () => {
    const res = await middleware(makeNextRequest("/dashboard"));
    expect(res.status).toBe(307);
    const location = res.headers.get("location") || "";
    expect(location).toContain("/login");
    expect(location).toContain("redirect=%2Fdashboard");
  });

  it("passes through in demo mode (no Supabase env vars)", async () => {
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_URL", "");
    vi.stubEnv("NEXT_PUBLIC_SUPABASE_ANON_KEY", "");
    const res = await middleware(makeNextRequest("/dashboard"));
    expect(res.status).toBe(200);
  });
});
