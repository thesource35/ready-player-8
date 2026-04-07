import { describe, it, expect, vi, beforeEach } from "vitest";

let user: { id: string; app_metadata?: { org_id?: string } } | null = null;
let chainLookup: {
  data: { version_chain_id: string } | null;
  error: { message: string } | null;
} = { data: null, error: null };
let listResp: {
  data: Array<{ id: string; version_number: number }> | null;
  error: { message: string } | null;
} = { data: null, error: null };
let storageUploadResp: { error: { message: string } | null } = { error: null };
let rpcResp: { data: string | null; error: { message: string } | null } = {
  data: null,
  error: null,
};
const removed: string[][] = [];

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    from: vi.fn(() => {
      const builder = {
        select: vi.fn(() => builder),
        eq: vi.fn(() => builder),
        order: vi.fn(async () => listResp),
        single: vi.fn(async () => chainLookup),
      };
      return builder;
    }),
    storage: {
      from: vi.fn(() => ({
        upload: vi.fn(async () => storageUploadResp),
        remove: vi.fn(async (paths: string[]) => {
          removed.push(paths);
          return { error: null };
        }),
      })),
    },
    rpc: vi.fn(async () => rpcResp),
  })),
}));

import { GET, POST } from "./route";

const ctx = (id: string) => ({ params: Promise.resolve({ id }) });

beforeEach(() => {
  user = { id: "u1", app_metadata: { org_id: "org-1" } };
  chainLookup = { data: { version_chain_id: "chain-1" }, error: null };
  listResp = {
    data: [
      { id: "d2", version_number: 2 },
      { id: "d1", version_number: 1 },
    ],
    error: null,
  };
  storageUploadResp = { error: null };
  rpcResp = { data: "new-doc-id", error: null };
  removed.length = 0;
});

describe("GET /api/documents/[id]/versions", () => {
  it("returns 401 when no user", async () => {
    user = null;
    const res = await GET(new Request("http://x"), ctx("d1"));
    expect(res.status).toBe(401);
  });

  it("returns 404 when chain not found", async () => {
    chainLookup = { data: null, error: { message: "no" } };
    const res = await GET(new Request("http://x"), ctx("d1"));
    expect(res.status).toBe(404);
  });

  it("returns 200 with versions list", async () => {
    const res = await GET(new Request("http://x"), ctx("d1"));
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      versions: Array<{ id: string; version_number: number }>;
    };
    expect(json.versions).toHaveLength(2);
    expect(json.versions[0].version_number).toBe(2);
  });
});

describe("POST /api/documents/[id]/versions", () => {
  function makeFormReq(file: File | null): Request {
    const fakeForm = {
      get(key: string) {
        if (key === "file") return file;
        return null;
      },
    } as unknown as FormData;
    return { formData: async () => fakeForm } as unknown as Request;
  }

  it("returns 401 when no user", async () => {
    user = null;
    const res = await POST(makeFormReq(null), ctx("d1"));
    expect(res.status).toBe(401);
  });

  it("returns 404 when chain not found", async () => {
    chainLookup = { data: null, error: null };
    const res = await POST(makeFormReq(null), ctx("d1"));
    expect(res.status).toBe(404);
  });

  it("returns 400 when no file", async () => {
    const res = await POST(makeFormReq(null), ctx("d1"));
    expect(res.status).toBe(400);
  });

  it("returns 415 on bad MIME", async () => {
    const f = new File(["x"], "a.exe", { type: "application/x-msdownload" });
    const res = await POST(makeFormReq(f), ctx("d1"));
    expect(res.status).toBe(415);
  });

  it("returns 500 and rolls back on rpc error", async () => {
    rpcResp = { data: null, error: { message: "rpc fail" } };
    const f = new File(["x"], "a.pdf", { type: "application/pdf" });
    const res = await POST(makeFormReq(f), ctx("d1"));
    expect(res.status).toBe(500);
    expect(removed.length).toBe(1);
  });

  it("returns 200 with new document_id on success", async () => {
    const f = new File(["x"], "a.pdf", { type: "application/pdf" });
    const res = await POST(makeFormReq(f), ctx("d1"));
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      document_id: string;
      version_chain_id: string;
    };
    expect(json.document_id).toBe("new-doc-id");
    expect(json.version_chain_id).toBe("chain-1");
  });
});
