// Phase 30 — D-02 regression test for the /inbox "Mark All Read" Server Action path
// Locks the contract that `markAllReadAction(formData)`:
//   1. Calls `markAllRead(null)` when no project_id is in FormData
//   2. Calls `markAllRead("proj-42")` when FormData has project_id
//   3. Calls `revalidatePath("/inbox")` after the mutation
//   4. Treats empty-string project_id as null (respects D-13: filter-aware mark-all)

import { describe, it, expect, vi, beforeEach } from "vitest";

// vi.mock factories are hoisted; reference mocks via vi.hoisted so they exist
// at hoist time (see https://vitest.dev/api/vi.html#vi-hoisted).
const { markReadMock, markAllReadMock, revalidatePathMock } = vi.hoisted(() => ({
  markReadMock: vi.fn(),
  markAllReadMock: vi.fn(),
  revalidatePathMock: vi.fn(),
}));

vi.mock("@/lib/notifications", () => ({
  markRead: markReadMock,
  markAllRead: markAllReadMock,
}));
vi.mock("next/cache", () => ({ revalidatePath: revalidatePathMock }));

import { markAllReadAction } from "@/app/inbox/actions";

beforeEach(() => {
  markReadMock.mockReset();
  markAllReadMock.mockReset();
  revalidatePathMock.mockReset();
});

describe("markAllReadAction (Server Action)", () => {
  it("calls markAllRead(null) when no project_id in FormData", async () => {
    markAllReadMock.mockResolvedValueOnce(0);
    const fd = new FormData();
    await markAllReadAction(fd);
    expect(markAllReadMock).toHaveBeenCalledExactlyOnceWith(null);
  });

  it("calls markAllRead with the project_id from FormData", async () => {
    markAllReadMock.mockResolvedValueOnce(3);
    const fd = new FormData();
    fd.set("project_id", "proj-42");
    await markAllReadAction(fd);
    expect(markAllReadMock).toHaveBeenCalledExactlyOnceWith("proj-42");
  });

  it("revalidates /inbox after the mutation", async () => {
    markAllReadMock.mockResolvedValueOnce(2);
    const fd = new FormData();
    fd.set("project_id", "proj-42");
    await markAllReadAction(fd);
    expect(revalidatePathMock).toHaveBeenCalledExactlyOnceWith("/inbox");
  });

  it("treats empty-string project_id as null", async () => {
    markAllReadMock.mockResolvedValueOnce(0);
    const fd = new FormData();
    fd.set("project_id", "");
    await markAllReadAction(fd);
    expect(markAllReadMock).toHaveBeenCalledExactlyOnceWith(null);
  });
});
