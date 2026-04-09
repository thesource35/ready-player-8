import { describe, it, expect, vi, beforeEach } from "vitest";

// Mock dependencies before importing routes.
vi.mock("@/lib/csrf", () => ({
  verifyCsrfOrigin: () => true,
}));

const mockUser = { id: "user-123" };
const fetchTableMock = vi.fn();
const insertRowMock = vi.fn();
const updateOwnedRowMock = vi.fn();
const deleteOwnedRowMock = vi.fn();
const getAuthenticatedClientMock = vi.fn();

vi.mock("@/lib/supabase/fetch", () => ({
  fetchTable: (...a: unknown[]) => fetchTableMock(...a),
  insertRow: (...a: unknown[]) => insertRowMock(...a),
  updateOwnedRow: (...a: unknown[]) => updateOwnedRowMock(...a),
  deleteOwnedRow: (...a: unknown[]) => deleteOwnedRowMock(...a),
  getAuthenticatedClient: () => getAuthenticatedClientMock(),
}));

import { GET, POST } from "../tasks/route";
import { PATCH } from "../tasks/[id]/route";

beforeEach(() => {
  vi.clearAllMocks();
  getAuthenticatedClientMock.mockResolvedValue({ user: mockUser, supabase: {} });
});

function jsonReq(url: string, method: string, body?: unknown): Request {
  return new Request(url, {
    method,
    headers: { "content-type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
}

describe("/api/calendar/tasks", () => {
  it("GET returns tasks for project_id", async () => {
    fetchTableMock.mockResolvedValue([
      { id: "t1", project_id: "p1", name: "Dig", start_date: "2026-04-01", end_date: "2026-04-03" },
    ]);
    const res = await GET(new Request("http://x/api/calendar/tasks?project_id=p1"));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveLength(1);
    expect(fetchTableMock).toHaveBeenCalledWith(
      "cs_project_tasks",
      expect.objectContaining({ eq: { column: "project_id", value: "p1" } })
    );
  });

  it("GET without project_id returns 400", async () => {
    const res = await GET(new Request("http://x/api/calendar/tasks"));
    expect(res.status).toBe(400);
  });

  it("POST validates start<=end", async () => {
    const res = await POST(
      jsonReq("http://x/api/calendar/tasks", "POST", {
        project_id: "p1",
        name: "Bad",
        start_date: "2026-04-10",
        end_date: "2026-04-01",
      })
    );
    expect(res.status).toBe(400);
    expect(insertRowMock).not.toHaveBeenCalled();
  });

  it("POST creates a valid task", async () => {
    insertRowMock.mockResolvedValue({ id: "new", project_id: "p1" });
    const res = await POST(
      jsonReq("http://x/api/calendar/tasks", "POST", {
        project_id: "p1",
        name: "Frame",
        start_date: "2026-04-01",
        end_date: "2026-04-05",
      })
    );
    expect(res.status).toBe(201);
    expect(insertRowMock).toHaveBeenCalled();
  });

  it("PATCH /[id] preserves duration on date move", async () => {
    updateOwnedRowMock.mockImplementation(async (_t, _id, _uid, patch) => ({
      id: "t1",
      project_id: "p1",
      ...patch,
    }));
    const res = await PATCH(
      jsonReq("http://x/api/calendar/tasks/t1", "PATCH", {
        start_date: "2026-04-10",
        end_date: "2026-04-12",
      }),
      { params: Promise.resolve({ id: "t1" }) }
    );
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.start_date).toBe("2026-04-10");
    expect(body.end_date).toBe("2026-04-12");
  });

  it("PATCH rejects non-ISO date strings with 400", async () => {
    const res = await PATCH(
      jsonReq("http://x/api/calendar/tasks/t1", "PATCH", {
        start_date: "2026-04-10T00:00:00Z",
        end_date: "2026-04-12",
      }),
      { params: Promise.resolve({ id: "t1" }) }
    );
    expect(res.status).toBe(400);
    expect(updateOwnedRowMock).not.toHaveBeenCalled();
  });
});
