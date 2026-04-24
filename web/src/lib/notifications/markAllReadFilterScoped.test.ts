// Phase 30 D-13 — markAllRead filter-scope regression
// per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract
//
// Locks the real-Supabase path of `markAllRead(projectId)`:
//   1. WHEN projectId is passed → the chained `.eq('project_id', projectId)` is invoked
//   2. WHEN projectId is null/undefined → NO `.eq('project_id', …)` call is made
//   3. The `.update(...)` payload is exactly `{ read_at: <ISO8601> }` (no other columns)
//   4. Signed-out users → returns 0 without touching `.update()`
//
// This guards the SQL contract laid out in
// .planning/phases/30-notifications-list-mark-read-ios-push-remediation/30-PARITY-SPEC.md.
// A future regression that drops the project_id predicate OR widens the update
// payload fails CI here before shipping to users.

import { describe, it, expect, vi, beforeEach } from "vitest";

// Track every `.eq(col, val)` call on the chainable fake.
const eqCalls: Array<[string, unknown]> = [];
// Capture the argument passed to `.update(...)` so Case 3 can inspect payload shape.
let lastUpdatePayload: unknown = undefined;
// Count invocations of `.update(...)` — Case 4 asserts it's never called when signed out.
let updateCallCount = 0;

// Configurable auth return — default signed-in; Case 4 flips this to null.
let authUser: { id: string } | null = { id: "user-abc" };

// Configurable final count value returned by the chain.
let finalCount = 3;

// Build a chainable mock: every terminal method (.eq/.is/.neq/.update) returns
// either `this` (for intermediate chain nodes) or a resolved thenable so
// `await q` works (the Supabase builder is thenable at the terminal step).
function makeQueryBuilder() {
  const thenable: Record<string, unknown> = {};
  thenable.update = vi.fn((payload: unknown) => {
    updateCallCount += 1;
    lastUpdatePayload = payload;
    return thenable;
  });
  thenable.eq = vi.fn((col: string, val: unknown) => {
    eqCalls.push([col, val]);
    return thenable;
  });
  thenable.is = vi.fn(() => thenable);
  thenable.select = vi.fn(() => thenable);
  // Terminal await: Supabase builders are PromiseLike; `.then` resolves with
  // `{ error, count }`. Include both shapes so code paths that read `count`
  // from the update-with-count-option form still work.
  thenable.then = (resolve: (v: { error: null; count: number; data: null }) => unknown) =>
    resolve({ error: null, count: finalCount, data: null });
  return thenable;
}

const fakeClient = {
  auth: {
    getUser: vi.fn(async () => ({ data: { user: authUser } })),
  },
  from: vi.fn(() => makeQueryBuilder()),
};

vi.mock("../supabase/server", () => ({
  createServerSupabase: vi.fn(async () => fakeClient),
}));

import { markAllRead } from "../notifications";

beforeEach(() => {
  eqCalls.length = 0;
  lastUpdatePayload = undefined;
  updateCallCount = 0;
  authUser = { id: "user-abc" };
  finalCount = 3;
  fakeClient.auth.getUser.mockClear();
  fakeClient.from.mockClear();
});

describe("markAllRead — D-13 filter scope (per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract)", () => {
  it("Case 1: applies .eq('project_id', id) when projectId passed (per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract)", async () => {
    await markAllRead("proj-A");
    const projectIdEqs = eqCalls.filter(([col]) => col === "project_id");
    expect(projectIdEqs.length).toBe(1);
    expect(projectIdEqs[0]).toEqual(["project_id", "proj-A"]);
  });

  it("Case 2: omits .eq('project_id', …) when projectId is null (per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract)", async () => {
    await markAllRead(null);
    expect(eqCalls.every(([col]) => col !== "project_id")).toBe(true);
    // Sanity: user_id predicate still present (global scope, not wildcard).
    expect(eqCalls.some(([col, val]) => col === "user_id" && val === "user-abc")).toBe(true);
  });

  it("Case 3: update payload contains only read_at with a valid ISO8601 string (per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract)", async () => {
    await markAllRead("proj-B");
    expect(lastUpdatePayload).toBeDefined();
    const payload = lastUpdatePayload as Record<string, unknown>;
    expect(Object.keys(payload)).toEqual(["read_at"]);
    const parsed = new Date(payload.read_at as string);
    expect(Number.isFinite(parsed.getTime())).toBe(true);
  });

  it("Case 4: signed-out user returns 0 and never calls .update() (per D-13 + 30-PARITY-SPEC §Mark-All-Read Scope Contract)", async () => {
    authUser = null;
    const result = await markAllRead("proj-A");
    expect(result).toBe(0);
    expect(updateCallCount).toBe(0);
    // `.eq` must not fire either — the signed-out branch returns before `.from()`.
    expect(eqCalls.length).toBe(0);
  });
});
