import { describe, it, expect } from "vitest";
import { createDailyLog } from "../dailyLogCreate";
import { MockOpenMeteoClient } from "../openMeteoClient";

// Tiny stub of the supabase-js builder surface that createDailyLog touches.
// Each .from(table) returns a per-table chain that the test pre-programs.
type TableScript = {
  selectResult?: { data: unknown; error: unknown; count?: number };
  insertResult?: { data: unknown; error: unknown };
};

function makeSupabase(scripts: Record<string, TableScript>, insertedDailyLog?: { data: unknown; error: unknown }) {
  return {
    from(table: string) {
      const script = scripts[table] ?? {};
      const chain: Record<string, unknown> = {};
      const passthrough = () => chain;
      chain.select = (_cols?: unknown, opts?: { count?: string; head?: boolean }) => {
        if (opts?.head) {
          // count head query — return thenable
          return {
            eq: () => ({
              eq: () => Promise.resolve({ data: null, error: null, count: script.selectResult?.count ?? 0 }),
            }),
          };
        }
        return chain;
      };
      chain.eq = passthrough;
      chain.maybeSingle = () => Promise.resolve(script.selectResult ?? { data: null, error: null });
      chain.single = () =>
        Promise.resolve(insertedDailyLog ?? script.selectResult ?? { data: null, error: null });
      chain.insert = (_row: unknown) => ({
        select: () => ({
          single: () => Promise.resolve(insertedDailyLog ?? { data: null, error: null }),
        }),
      });
      // Allow await on chain for crew query: returns selectResult directly
      (chain as { then?: unknown }).then = (resolve: (v: unknown) => void) => {
        resolve(script.selectResult ?? { data: [], error: null });
      };
      return chain;
    },
  };
}

const projectRow = {
  data: { id: "p1", latitude: 30.27, longitude: -97.74, template_layer: null },
  error: null,
};

describe("createDailyLog", () => {
  it("happy path: inserts log with frozen template + prefilled content", async () => {
    const supabase = makeSupabase(
      {
        cs_projects: { selectResult: projectRow },
        cs_daily_crew: { selectResult: { data: [{ id: "c1" }], error: null } },
        cs_rfis: { selectResult: { count: 3, data: null, error: null } },
        cs_punch_items: { selectResult: { count: 2, data: null, error: null } },
        cs_daily_logs: { selectResult: { data: null, error: null } },
      },
      { data: { id: "log-123" }, error: null },
    );

    const openMeteo = new MockOpenMeteoClient();
    const r = await createDailyLog({
      projectId: "p1",
      logDate: "2026-04-08",
      role: "superintendent",
      openMeteo,
      supabase,
    });

    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.id).toBe("log-123");
      expect(r.templateSnapshot).toBeDefined();
      expect(openMeteo.calls.length).toBe(1);
      expect((r.weather as { tempC?: number }).tempC).toBe(21);
    }
  });

  it("Open-Meteo failure: weather_jsonb gets error blob, log still created", async () => {
    const failingClient = {
      async fetch() {
        throw new Error("network down");
      },
    };
    const supabase = makeSupabase(
      {
        cs_projects: { selectResult: projectRow },
        cs_daily_crew: { selectResult: { data: [], error: null } },
        cs_rfis: { selectResult: { count: 0, data: null, error: null } },
        cs_punch_items: { selectResult: { count: 0, data: null, error: null } },
        cs_daily_logs: { selectResult: { data: null, error: null } },
      },
      { data: { id: "log-err" }, error: null },
    );

    const r = await createDailyLog({
      projectId: "p1",
      logDate: "2026-04-08",
      role: "superintendent",
      openMeteo: failingClient,
      supabase,
    });

    expect(r.ok).toBe(true);
    if (r.ok) {
      expect((r.weather as { error?: string }).error).toMatch(/open-meteo unavailable/);
    }
  });

  it("UNIQUE violation → 409 with existingId", async () => {
    let insertCalls = 0;
    const supabase = {
      from(table: string) {
        const chain: Record<string, unknown> = {};
        const pass = () => chain;
        chain.select = (_c?: unknown, opts?: { head?: boolean }) => {
          if (opts?.head) {
            return { eq: () => ({ eq: () => Promise.resolve({ count: 0, data: null, error: null }) }) };
          }
          return chain;
        };
        chain.eq = pass;
        chain.maybeSingle = () => {
          if (table === "cs_projects") return Promise.resolve(projectRow);
          if (table === "cs_daily_logs") return Promise.resolve({ data: { id: "existing-1" }, error: null });
          return Promise.resolve({ data: null, error: null });
        };
        chain.single = () => Promise.resolve({ data: null, error: null });
        chain.insert = () => ({
          select: () => ({
            single: () => {
              insertCalls++;
              return Promise.resolve({
                data: null,
                error: { code: "23505", message: "duplicate key" },
              });
            },
          }),
        });
        (chain as { then?: unknown }).then = (resolve: (v: unknown) => void) => {
          resolve({ data: [], error: null });
        };
        return chain;
      },
    };
    const r = await createDailyLog({
      projectId: "p1",
      logDate: "2026-04-08",
      role: "superintendent",
      openMeteo: new MockOpenMeteoClient(),
      supabase,
    });
    expect(r.ok).toBe(false);
    if (!r.ok) {
      expect(r.status).toBe(409);
      expect(r.existingId).toBe("existing-1");
    }
    expect(insertCalls).toBe(1);
  });

  it("NaN lat throws validation error before insert", async () => {
    const supabase = makeSupabase(
      {
        cs_projects: {
          selectResult: { data: { id: "p1", latitude: NaN, longitude: -97.74, template_layer: null }, error: null },
        },
      },
      { data: { id: "x" }, error: null },
    );
    await expect(
      createDailyLog({
        projectId: "p1",
        logDate: "2026-04-08",
        role: "superintendent",
        openMeteo: new MockOpenMeteoClient(),
        supabase,
      }),
    ).rejects.toThrow(/lat must be a finite number/);
  });
});
