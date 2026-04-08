import { vi, describe, it, expect, beforeEach, afterEach } from "vitest";

// Mock modules before importing the route handler
vi.mock("@/lib/csrf", () => ({
  verifyCsrfOrigin: vi.fn().mockReturnValue(true),
}));

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn().mockResolvedValue(null),
}));

vi.mock("ai", () => ({
  streamText: vi.fn().mockReturnValue({
    toTextStreamResponse: () => new Response("streamed", { status: 200 }),
  }),
}));

vi.mock("@ai-sdk/anthropic", () => ({
  createAnthropic: vi.fn().mockReturnValue(() => "mock-model"),
}));

import { POST } from "./route";
import { verifyCsrfOrigin } from "@/lib/csrf";
import { streamText } from "ai";

function makeRequest(
  body: unknown,
  headers?: Record<string, string>
): Request {
  return new Request("http://localhost:3000/api/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      origin: "http://localhost:3000",
      host: "localhost:3000",
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

describe("POST /api/chat", () => {
  beforeEach(() => {
    vi.stubEnv("ANTHROPIC_API_KEY", "test-key");
    vi.mocked(verifyCsrfOrigin).mockReturnValue(true);
    vi.mocked(streamText).mockReturnValue({
      toTextStreamResponse: () => new Response("streamed", { status: 200 }),
    } as ReturnType<typeof streamText>);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
    vi.clearAllMocks();
  });

  it("returns streaming 200 with valid messages", async () => {
    const res = await POST(
      makeRequest({ messages: [{ role: "user", content: "Hello" }] })
    );
    expect(res.status).toBe(200);
    const text = await res.text();
    expect(text).toContain("streamed");
  });

  it("returns 503 when ANTHROPIC_API_KEY is missing", async () => {
    vi.stubEnv("ANTHROPIC_API_KEY", "");
    const res = await POST(
      makeRequest({ messages: [{ role: "user", content: "Hello" }] })
    );
    expect(res.status).toBe(503);
    const json = await res.json();
    expect(json.error).toContain("not configured");
  });

  it("returns 403 when CSRF check fails", async () => {
    vi.mocked(verifyCsrfOrigin).mockReturnValueOnce(false);
    const res = await POST(
      makeRequest({ messages: [{ role: "user", content: "Hello" }] })
    );
    expect(res.status).toBe(403);
    const json = await res.json();
    expect(json.error).toContain("Forbidden");
  });

  it("returns 400 for invalid JSON body", async () => {
    const req = new Request("http://localhost:3000/api/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        origin: "http://localhost:3000",
        host: "localhost:3000",
      },
      body: "not-json{{{",
    });
    const res = await POST(req);
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toContain("Invalid request body");
  });

  it("returns 400 when messages array is missing", async () => {
    const res = await POST(makeRequest({ prompt: "Hello" }));
    expect(res.status).toBe(400);
    const json = await res.json();
    expect(json.error).toContain("messages array is required");
  });

  it("returns 502 when AI SDK throws 401 error", async () => {
    vi.mocked(streamText).mockImplementationOnce(() => {
      throw new Error("401 Unauthorized");
    });
    const res = await POST(
      makeRequest({ messages: [{ role: "user", content: "Hello" }] })
    );
    expect(res.status).toBe(502);
    const json = await res.json();
    expect(json.error).toContain("API key is invalid");
  });
});
