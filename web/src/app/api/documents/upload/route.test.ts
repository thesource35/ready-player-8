import { describe, it, expect, vi, beforeEach } from "vitest";

type StorageResp = { error: { message: string } | null };
type InsertResp = { error: { message: string } | null };

let user: { id: string; app_metadata?: { org_id?: string } } | null = null;
let storageUploadResp: StorageResp = { error: null };
let docInsertResp: InsertResp = { error: null };
let attachInsertResp: InsertResp = { error: null };
const removed: string[][] = [];
const insertedRows: { table: string; row: unknown }[] = [];

vi.mock("@/lib/supabase/server", () => ({
  createServerSupabase: vi.fn(async () => ({
    auth: { getUser: vi.fn(async () => ({ data: { user } })) },
    storage: {
      from: vi.fn(() => ({
        upload: vi.fn(async () => storageUploadResp),
        remove: vi.fn(async (paths: string[]) => {
          removed.push(paths);
          return { error: null };
        }),
      })),
    },
    from: vi.fn((table: string) => ({
      insert: vi.fn(async (row: unknown) => {
        insertedRows.push({ table, row });
        if (table === "cs_documents") return docInsertResp;
        if (table === "cs_document_attachments") return attachInsertResp;
        return { error: null };
      }),
    })),
  })),
}));

import { POST } from "./route";

function makeReq(form: FormData): Request {
  return new Request("http://localhost/api/documents/upload", {
    method: "POST",
    body: form,
  });
}

function makeFile(contents: string, name: string, type: string): File {
  return new File([contents], name, { type });
}

beforeEach(() => {
  user = { id: "user-1", app_metadata: { org_id: "org-1" } };
  storageUploadResp = { error: null };
  docInsertResp = { error: null };
  attachInsertResp = { error: null };
  removed.length = 0;
  insertedRows.length = 0;
});

describe("POST /api/documents/upload", () => {
  it("returns 401 when no user", async () => {
    user = null;
    const fd = new FormData();
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(401);
  });

  it("returns 400 when file missing", async () => {
    const fd = new FormData();
    fd.append("entity_type", "project");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(400);
  });

  it("returns 400 when entity_type invalid", async () => {
    const fd = new FormData();
    fd.append("file", makeFile("hi", "a.pdf", "application/pdf"));
    fd.append("entity_type", "bogus");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(400);
  });

  it("returns 400 when entity_id missing", async () => {
    const fd = new FormData();
    fd.append("file", makeFile("hi", "a.pdf", "application/pdf"));
    fd.append("entity_type", "project");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(400);
  });

  it("returns 413 when file too large", async () => {
    // Bypass real FormData (which would force the File to be re-read with
    // its actual byte size). Provide a fake request whose formData() yields
    // a File-like object with a fabricated `size`.
    const fakeFile = Object.assign(
      new File(["x"], "a.pdf", { type: "application/pdf" }),
      {}
    );
    Object.defineProperty(fakeFile, "size", { value: 52428801 });
    const fakeForm = {
      get(key: string) {
        if (key === "file") return fakeFile;
        if (key === "entity_type") return "project";
        if (key === "entity_id") return "p1";
        return null;
      },
    } as unknown as FormData;
    const fakeReq = {
      formData: async () => fakeForm,
    } as unknown as Request;
    const res = await POST(fakeReq);
    expect(res.status).toBe(413);
  });

  it("returns 415 when MIME disallowed", async () => {
    const fd = new FormData();
    fd.append(
      "file",
      makeFile("x", "a.exe", "application/x-msdownload")
    );
    fd.append("entity_type", "project");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(415);
  });

  it("returns 500 when storage upload errors", async () => {
    storageUploadResp = { error: { message: "boom" } };
    const fd = new FormData();
    fd.append("file", makeFile("hi", "a.pdf", "application/pdf"));
    fd.append("entity_type", "project");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(500);
  });

  it("rolls back storage and returns 500 when DB insert fails", async () => {
    docInsertResp = { error: { message: "db boom" } };
    const fd = new FormData();
    fd.append("file", makeFile("hi", "a.pdf", "application/pdf"));
    fd.append("entity_type", "project");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(500);
    expect(removed.length).toBe(1);
  });

  it("returns 200 with document_id on success and inserts attachment", async () => {
    const fd = new FormData();
    fd.append("file", makeFile("hi", "a.pdf", "application/pdf"));
    fd.append("entity_type", "project");
    fd.append("entity_id", "p1");
    const res = await POST(makeReq(fd));
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      document_id: string;
      version_chain_id: string;
      path: string;
    };
    expect(json.document_id).toBeTruthy();
    expect(json.version_chain_id).toBe(json.document_id);
    expect(json.path).toContain("org-1/project/p1/");
    const docRow = insertedRows.find((r) => r.table === "cs_documents")?.row as
      | { version_number: number; is_current: boolean }
      | undefined;
    expect(docRow?.version_number).toBe(1);
    expect(docRow?.is_current).toBe(true);
    expect(
      insertedRows.some((r) => r.table === "cs_document_attachments")
    ).toBe(true);
  });
});
