// Phase 30 — D-01 regression test for the /inbox Server Action path
// Locks the contract that `markReadAction(formData)`:
//   1. Calls `markRead(id)` exactly once with the FormData `id` value
//   2. Calls `revalidatePath("/inbox")` on success
//   3. No-ops (does NOT call markRead, does NOT call revalidatePath) when `id` is missing
// See 14-03-SUMMARY.md Known Limitation #1 for the regression this protects against.

import { describe, it, expect, vi, beforeEach } from "vitest";

// vi.mock factories are hoisted; reference mocks via vi.hoisted so they exist
// at hoist time (see https://vitest.dev/api/vi.html#vi-hoisted).
const { markReadMock, markAllReadMock, revalidatePathMock } = vi.hoisted(() => ({
  markReadMock: vi.fn(),
  markAllReadMock: vi.fn(),
  revalidatePathMock: vi.fn(),
}));

vi.mock("@/lib/notifications/server", () => ({
  markRead: markReadMock,
  markAllRead: markAllReadMock,
}));
vi.mock("next/cache", () => ({ revalidatePath: revalidatePathMock }));

import { markReadAction } from "@/app/inbox/actions";

beforeEach(() => {
  markReadMock.mockReset();
  markAllReadMock.mockReset();
  revalidatePathMock.mockReset();
});

describe("markReadAction (Server Action)", () => {
  it("calls markRead with the id from FormData", async () => {
    markReadMock.mockResolvedValueOnce(true);
    const fd = new FormData();
    fd.set("id", "n-1");
    await markReadAction(fd);
    expect(markReadMock).toHaveBeenCalledExactlyOnceWith("n-1");
  });

  it("revalidates /inbox on success", async () => {
    markReadMock.mockResolvedValueOnce(true);
    const fd = new FormData();
    fd.set("id", "n-1");
    await markReadAction(fd);
    expect(revalidatePathMock).toHaveBeenCalledExactlyOnceWith("/inbox");
  });

  it("no-ops when id is missing (null)", async () => {
    const fd = new FormData();
    await markReadAction(fd);
    expect(markReadMock).not.toHaveBeenCalled();
    expect(revalidatePathMock).not.toHaveBeenCalled();
  });

  it("no-ops when id is empty string", async () => {
    const fd = new FormData();
    fd.set("id", "");
    await markReadAction(fd);
    expect(markReadMock).not.toHaveBeenCalled();
    expect(revalidatePathMock).not.toHaveBeenCalled();
  });
});
