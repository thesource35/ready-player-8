import { describe, it, expect } from "vitest";
import {
  nonEmptyEntityTypes,
  shouldEnableAttachment,
} from "./entityPickerQuery";

// Shape-compatible mock of the subset of SupabaseClient used by the helper:
// `.from(table).select(cols, opts)` returning `{ count, error }`.
function mockSupabase(counts: Record<string, number>) {
  const calls: string[] = [];
  return {
    calls,
    client: {
      from(table: string) {
        calls.push(table);
        return {
          select(_cols: string, _opts?: unknown) {
            return Promise.resolve({
              count: counts[table] ?? 0,
              error: null,
            });
          },
        };
      },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } as any,
  };
}

describe("nonEmptyEntityTypes", () => {
  it("returns only types whose table has rows", async () => {
    const m = mockSupabase({ cs_projects: 3, cs_daily_logs: 1 });
    const out = await nonEmptyEntityTypes(m.client);
    expect(out.sort()).toEqual(["daily_log", "project"]);
  });

  it("returns [] when every table is empty", async () => {
    const m = mockSupabase({});
    const out = await nonEmptyEntityTypes(m.client);
    expect(out).toEqual([]);
  });

  it("makes exactly one query per entity type (no N+1)", async () => {
    const m = mockSupabase({ cs_projects: 1 });
    await nonEmptyEntityTypes(m.client);
    // 7 entity types → 7 HEAD count queries
    expect(m.calls.length).toBe(7);
  });
});

describe("shouldEnableAttachment", () => {
  it("returns true when current entity is in non-empty set", () => {
    expect(shouldEnableAttachment("rfi", ["rfi"])).toBe(true);
  });

  it("returns true for project regardless of global state", () => {
    expect(shouldEnableAttachment("project", [])).toBe(true);
  });

  it("returns false when current entity has no rows and is not project", () => {
    expect(shouldEnableAttachment("rfi", [])).toBe(false);
  });
});
