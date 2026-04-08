// Phase 15 — cert-expiry-scan Deno tests
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handle } from "./index.ts";

function makeStubSupabase(state: {
  certs?: any[];
  existingEvents?: number;
  assignment?: { project_id: string } | null;
}) {
  const inserted: any[] = [];
  const flipped: any[] = [];

  function builder(table: string) {
    const self: any = {
      _table: table,
      _filters: {} as Record<string, any>,
      _selectOpts: undefined as any,
      select(_cols?: string, opts?: any) {
        self._selectOpts = opts;
        if (table === "cs_activity_events" && opts?.head) {
          // Terminal count query — return a thenable resolving to { count }
          return {
            eq() { return this; },
            gte() { return Promise.resolve({ count: state.existingEvents ?? 0 }); },
          };
        }
        if (table === "cs_certifications") {
          return {
            eq(_k: string, _v: any) {
              const chain: any = {
                eq(_k2: string, _v2: any) {
                  return Promise.resolve({ data: state.certs ?? [], error: null });
                },
              };
              return chain;
            },
          };
        }
        if (table === "cs_project_assignments") {
          return {
            eq() { return this; },
            limit() { return this; },
            maybeSingle() {
              return Promise.resolve({ data: state.assignment ?? null, error: null });
            },
          };
        }
        return self;
      },
      update(patch: any) {
        return {
          lt(_k: string, _v: any) {
            return {
              eq(_k2: string, _v2: any) {
                flipped.push({ table, patch });
                return Promise.resolve({ error: null });
              },
            };
          },
        };
      },
      insert(row: any) {
        inserted.push({ table, row });
        return Promise.resolve({ error: null });
      },
    };
    return self;
  }

  const client: any = { from: (t: string) => builder(t) };
  return { client, inserted, flipped };
}

const SR = "test-service-role-key";
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", SR);
Deno.env.set("SUPABASE_URL", "http://localhost");

Deno.test("rejects request without service-role auth", async () => {
  const { client } = makeStubSupabase({});
  const res = await handle(new Request("http://x", { method: "POST" }), { supabase: client });
  assertEquals(res.status, 401);
});

Deno.test("inserts cs_activity_events with category='assigned_task'", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [{ id: "c1", member_id: "m1", name: "OSHA 30", expires_at: "2026-05-08" }],
    assignment: { project_id: "p1" },
  });
  const req = new Request("http://x", {
    method: "POST",
    headers: { authorization: `Bearer ${SR}` },
  });
  await handle(req, { supabase: client });
  const evt = inserted.find((i) => i.table === "cs_activity_events");
  assertEquals(evt?.row.category, "assigned_task");
  assertEquals(evt?.row.entity_type, "certifications");
  assertEquals(evt?.row.entity_id, "c1");
  assertEquals(evt?.row.project_id, "p1");
});

Deno.test("dedupe: skips when event already exists in last 20h", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [{ id: "c1", member_id: "m1", name: "OSHA 30", expires_at: "2026-05-08" }],
    existingEvents: 1,
  });
  const req = new Request("http://x", {
    method: "POST",
    headers: { authorization: `Bearer ${SR}` },
  });
  await handle(req, { supabase: client });
  assertEquals(inserted.filter((i) => i.table === "cs_activity_events").length, 0);
});

Deno.test("auto-flips expired active certs to status='expired'", async () => {
  const { client, flipped } = makeStubSupabase({ certs: [] });
  const req = new Request("http://x", {
    method: "POST",
    headers: { authorization: `Bearer ${SR}` },
  });
  await handle(req, { supabase: client });
  const flip = flipped.find((f) => f.table === "cs_certifications");
  assertEquals(flip?.patch.status, "expired");
});
