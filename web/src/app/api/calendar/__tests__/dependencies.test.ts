import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/csrf", () => ({ verifyCsrfOrigin: () => true }));

const fetchTableMock = vi.fn();
const insertRowMock = vi.fn();
const getAuthMock = vi.fn();

vi.mock("@/lib/supabase/fetch", () => ({
  fetchTable: (...a: unknown[]) => fetchTableMock(...a),
  insertRow: (...a: unknown[]) => insertRowMock(...a),
  deleteOwnedRow: vi.fn(),
  getAuthenticatedClient: () => getAuthMock(),
}));

import { POST, wouldCreateCycle } from "../dependencies/route";

beforeEach(() => {
  vi.clearAllMocks();
  getAuthMock.mockResolvedValue({ user: { id: "u1" }, supabase: {} });
});

function jsonReq(body: unknown): Request {
  return new Request("http://x/api/calendar/dependencies", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("wouldCreateCycle (unit)", () => {
  it("detects direct cycle A↔B", () => {
    const deps = [{ predecessor_task_id: "A", successor_task_id: "B" }];
    // adding B→A would cycle
    expect(wouldCreateCycle(deps, "B", "A")).toBe(true);
  });

  it("detects self-loop", () => {
    expect(wouldCreateCycle([], "A", "A")).toBe(true);
  });

  it("allows non-cyclic edge", () => {
    const deps = [{ predecessor_task_id: "A", successor_task_id: "B" }];
    expect(wouldCreateCycle(deps, "B", "C")).toBe(false);
  });

  it("detects transitive cycle A→B→C, adding C→A", () => {
    const deps = [
      { predecessor_task_id: "A", successor_task_id: "B" },
      { predecessor_task_id: "B", successor_task_id: "C" },
    ];
    expect(wouldCreateCycle(deps, "C", "A")).toBe(true);
  });
});

describe("POST /api/calendar/dependencies", () => {
  it("rejects A→B when B→A exists (409 cycle)", async () => {
    fetchTableMock.mockResolvedValue([
      { id: "d1", predecessor_task_id: "B", successor_task_id: "A" },
    ]);
    const res = await POST(jsonReq({ predecessor_task_id: "A", successor_task_id: "B" }));
    expect(res.status).toBe(409);
    expect(insertRowMock).not.toHaveBeenCalled();
  });

  it("rejects self-loop A→A (409)", async () => {
    const res = await POST(jsonReq({ predecessor_task_id: "A", successor_task_id: "A" }));
    expect(res.status).toBe(409);
    expect(insertRowMock).not.toHaveBeenCalled();
  });

  it("accepts a valid new edge", async () => {
    fetchTableMock.mockResolvedValue([]);
    insertRowMock.mockResolvedValue({ id: "d2", predecessor_task_id: "A", successor_task_id: "B" });
    const res = await POST(jsonReq({ predecessor_task_id: "A", successor_task_id: "B" }));
    expect(res.status).toBe(201);
    expect(insertRowMock).toHaveBeenCalled();
  });
});
