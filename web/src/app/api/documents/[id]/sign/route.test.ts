import { describe, it, expect, vi, beforeEach } from "vitest";

let user: { id: string } | null = null;
let docResp: {
  data: { storage_path: string; mime_type: string; filename: string } | null;
  error: { message: string } | null;
} = { data: null, error: null };
let signResp: {
  data: { signedUrl: string } | null;
  error: { message: string } | null;
} = { data: null, error: null };

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          single: vi.fn(async () => docResp),
        })),
      })),
    })),
    storage: {
      from: vi.fn(() => ({
        createSignedUrl: vi.fn(async () => signResp),
      })),
    },
  })),
}));

import { GET } from "./route";

const ctx = (id: string) => ({ params: Promise.resolve({ id }) });

beforeEach(() => {
  user = { id: "u1" };
  docResp = {
    data: {
      storage_path: "org/p/1/abc.pdf",
      mime_type: "application/pdf",
      filename: "abc.pdf",
    },
    error: null,
  };
  signResp = {
    data: { signedUrl: "https://signed.example/abc" },
    error: null,
  };
});

describe("GET /api/documents/[id]/sign", () => {
  it("returns 401 when no user", async () => {
    user = null;
    const res = await GET(new Request("http://x"), ctx("doc-1"));
    expect(res.status).toBe(401);
  });

  it("returns 404 when not found", async () => {
    docResp = { data: null, error: { message: "not found" } };
    const res = await GET(new Request("http://x"), ctx("doc-1"));
    expect(res.status).toBe(404);
  });

  it("returns 200 with signed url on success", async () => {
    const res = await GET(new Request("http://x"), ctx("doc-1"));
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      url: string;
      mime_type: string;
      filename: string;
      expires_at: string;
    };
    expect(json.url).toBe("https://signed.example/abc");
    expect(json.mime_type).toBe("application/pdf");
    expect(json.filename).toBe("abc.pdf");
    expect(json.expires_at).toBeTruthy();
  });

  it("returns 500 when sign fails", async () => {
    signResp = { data: null, error: { message: "boom" } };
    const res = await GET(new Request("http://x"), ctx("doc-1"));
    expect(res.status).toBe(500);
  });
});
