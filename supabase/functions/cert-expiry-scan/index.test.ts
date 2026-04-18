// Phase 25 — cert-expiry-scan Deno tests
// Tests all 4 thresholds, dedupe, grouping, dismiss-suppress, first-deploy guard,
// rate cap, recipient resolution, and delivery channels.
import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handle } from "./index.ts";

// ─── Stub Factory ────────────────────────────────────────────────────────────

function makeStubSupabase(state: {
  certs?: any[];
  expiredCerts?: any[];
  existingEvents?: number;
  assignment?: { project_id: string } | null;
  pmAssignments?: any[];
  members?: any[];
  projects?: any[];
  dismissedNotifications?: any[];
  isFirstDeploy?: boolean;
}) {
  const inserted: any[] = [];
  const flipped: any[] = [];

  const today = new Date();
  const todayStr = today.toISOString().slice(0, 10);
  const target30 = new Date(today);
  target30.setUTCDate(today.getUTCDate() + 30);
  const target30Str = target30.toISOString().slice(0, 10);

  // Track query context for smarter routing
  let currentQueryContext: {
    table: string;
    filters: Record<string, any>;
    selectOpts?: any;
    isHead?: boolean;
    orderCol?: string;
    limitVal?: number;
    gtFilter?: { col: string; val: string };
  } = { table: "", filters: {} };

  function builder(table: string) {
    currentQueryContext = { table, filters: {} };

    const self: any = {
      _table: table,

      select(cols?: string, opts?: any) {
        currentQueryContext.selectOpts = opts;
        currentQueryContext.isHead = opts?.head ?? false;
        return self;
      },

      eq(col: string, val: any) {
        currentQueryContext.filters[col] = val;

        // Terminal check: is this the first-deploy or dedupe count query?
        if (table === "cs_activity_events" && currentQueryContext.isHead) {
          // First-deploy check: entity_type = 'certifications' only filter
          if (col === "entity_type" && Object.keys(currentQueryContext.filters).length === 1) {
            // This is the first-deploy check — return based on isFirstDeploy flag
            return {
              filter() { return this; },
              eq() { return this; },
              then(resolve: any) {
                const count = state.isFirstDeploy === true ? 0 : (state.existingEvents ?? 0);
                resolve({ count });
              },
            };
          }
        }

        return self;
      },

      filter(path: string, op: string, val: any) {
        currentQueryContext.filters[path] = val;

        // If this is a dedupe query on cs_activity_events (payload-based), return count
        if (table === "cs_activity_events" && currentQueryContext.isHead) {
          return {
            filter(p2: string, o2: string, v2: any) {
              return {
                then(resolve: any) {
                  resolve({ count: state.existingEvents ?? 0 });
                },
              };
            },
            then(resolve: any) {
              resolve({ count: state.existingEvents ?? 0 });
            },
          };
        }

        // Dismiss-suppress query on cs_notifications
        if (table === "cs_notifications") {
          return {
            not() {
              return {
                then(resolve: any) {
                  resolve({ data: state.dismissedNotifications ?? [] });
                },
              };
            },
            then(resolve: any) {
              resolve({ data: state.dismissedNotifications ?? [] });
            },
          };
        }

        return self;
      },

      not(col: string, op: string, val: any) {
        // dismiss query terminal
        return {
          then(resolve: any) {
            resolve({ data: state.dismissedNotifications ?? [] });
          },
        };
      },

      gte(col: string, val: any) {
        currentQueryContext.filters[`${col}_gte`] = val;
        return self;
      },

      lte(col: string, val: any) {
        currentQueryContext.filters[`${col}_lte`] = val;
        return self;
      },

      lt(col: string, val: any) {
        currentQueryContext.filters[`${col}_lt`] = val;
        return self;
      },

      gt(col: string, val: any) {
        currentQueryContext.gtFilter = { col, val };
        return self;
      },

      or(expr: string) {
        currentQueryContext.filters["_or"] = expr;
        return self;
      },

      in(col: string, vals: any[]) {
        currentQueryContext.filters[`${col}_in`] = vals;

        // Route based on table
        if (table === "cs_team_members") {
          return {
            then(resolve: any) {
              resolve({
                data: state.members ?? [
                  { id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" },
                ],
              });
            },
          };
        }

        if (table === "cs_projects") {
          return {
            then(resolve: any) {
              resolve({
                data: state.projects ?? [{ id: "p1", created_by: "u-proj-creator" }],
              });
            },
          };
        }

        // cs_project_assignments with .in()
        if (table === "cs_project_assignments") {
          return {
            eq(col2: string, val2: any) {
              // If filtering by status + or (PM resolution)
              return {
                or(expr: string) {
                  return {
                    then(resolve: any) {
                      resolve({
                        data: state.pmAssignments ?? [
                          { project_id: "p1", member_id: "m-pm1" },
                        ],
                      });
                    },
                  };
                },
                then(resolve: any) {
                  // Regular assignments query
                  const assignmentData = state.assignment
                    ? [{ member_id: vals[0], project_id: state.assignment.project_id }]
                    : [];
                  resolve({ data: assignmentData });
                },
              };
            },
            then(resolve: any) {
              resolve({ data: [] });
            },
          };
        }

        return self;
      },

      order(col: string, opts?: any) {
        currentQueryContext.orderCol = col;
        return self;
      },

      limit(n: number) {
        currentQueryContext.limitVal = n;
        return self;
      },

      maybeSingle() {
        return Promise.resolve({
          data: state.assignment ?? null,
          error: null,
        });
      },

      update(patch: any) {
        return {
          lt(col: string, val: any) {
            return {
              eq(col2: string, val2: any) {
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

      // Terminal: resolve the query based on current context
      then(resolve: any) {
        // cs_certifications batch queries
        if (table === "cs_certifications" && currentQueryContext.orderCol === "id") {
          // Active certs query (has gte + lte on expires_at, status=active)
          if (currentQueryContext.filters["status"] === "active") {
            // Return certs only on first page (no gt filter set)
            if (!currentQueryContext.gtFilter) {
              resolve({ data: state.certs ?? [] });
            } else {
              resolve({ data: [] }); // pagination terminates
            }
            return;
          }
          // Expired certs query (has status=expired, lt on expires_at)
          if (currentQueryContext.filters["status"] === "expired") {
            if (!currentQueryContext.gtFilter) {
              resolve({ data: state.expiredCerts ?? [] });
            } else {
              resolve({ data: [] });
            }
            return;
          }
        }

        // cs_project_assignments
        if (table === "cs_project_assignments") {
          const assignmentData = state.assignment
            ? [{ member_id: "m1", project_id: state.assignment.project_id }]
            : [];
          resolve({ data: assignmentData });
          return;
        }

        // Default
        resolve({ data: [], count: 0 });
      },
    };

    return self;
  }

  const client: any = { from: (t: string) => builder(t) };
  return { client, inserted, flipped };
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

const SR = "test-service-role-key";
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", SR);
Deno.env.set("SUPABASE_URL", "http://localhost");

function authReq(): Request {
  return new Request("http://x", {
    method: "POST",
    headers: { authorization: `Bearer ${SR}` },
  });
}

function daysFromNow(n: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - n);
  return d.toISOString().slice(0, 10);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

Deno.test("rejects request without service-role auth", async () => {
  const { client } = makeStubSupabase({});
  const res = await handle(new Request("http://x", { method: "POST" }), {
    supabase: client,
  });
  assertEquals(res.status, 401);
});

Deno.test("inserts event for 30-day threshold", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c1", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(25) },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.threshold, 30);
  assertEquals(evt?.row.summary.includes("expires in 30 days"), true);
});

Deno.test("inserts event for 7-day threshold", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c2", member_id: "m1", name: "Forklift", expires_at: daysFromNow(5) },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.threshold, 7);
  assertEquals(evt?.row.summary.includes("expires in 7 days"), true);
});

Deno.test("inserts event for day-of threshold", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c3", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(0) },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.threshold, 0);
  assertEquals(evt?.row.summary.includes("expires today"), true);
});

Deno.test("inserts event for post-expiry weekly", async () => {
  const { client, inserted } = makeStubSupabase({
    expiredCerts: [
      { id: "c4", member_id: "m1", name: "OSHA 30", expires_at: daysAgo(7), status: "expired" },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.threshold, "post-expiry");
  assertEquals(evt?.row.summary.includes("has expired"), true);
});

Deno.test("skips post-expiry when not on weekly boundary", async () => {
  const { client, inserted } = makeStubSupabase({
    expiredCerts: [
      { id: "c5", member_id: "m1", name: "OSHA 30", expires_at: daysAgo(5), status: "expired" },
    ],
    assignment: { project_id: "p1" },
  });
  await handle(authReq(), { supabase: client });
  const events = inserted.filter((i: any) => i.table === "cs_activity_events");
  assertEquals(events.length, 0);
});

Deno.test("dedupe: skips when payload-marker event exists", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c6", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
    ],
    existingEvents: 1,
    assignment: { project_id: "p1" },
  });
  await handle(authReq(), { supabase: client });
  const events = inserted.filter((i: any) => i.table === "cs_activity_events");
  assertEquals(events.length, 0);
});

Deno.test("groups multiple certs for same member at same threshold", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c7", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
      { id: "c8", member_id: "m1", name: "Forklift", expires_at: daysFromNow(4) },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const events = inserted.filter((i: any) => i.table === "cs_activity_events");
  assertEquals(events.length, 1);
  assertEquals(events[0].row.payload.cert_names.length, 2);
  assertEquals(events[0].row.summary.includes("OSHA 30"), true);
  assertEquals(events[0].row.summary.includes("Forklift"), true);
});

Deno.test("dismiss-suppress: excludes dismissed user from recipients", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c9", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
    ],
    assignment: { project_id: "p1" },
    members: [
      { id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" },
      { id: "m-pm1", name: "PM Jane", user_id: "u-pm", created_by: "u-admin" },
    ],
    dismissedNotifications: [{ user_id: "u-member" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.suppress_user_ids.includes("u-member"), true);
  assertEquals(evt?.row.payload.recipient_user_ids.includes("u-member"), false);
});

Deno.test("first-deploy: fires only most urgent threshold", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c10", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
    ],
    isFirstDeploy: true,
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const events = inserted.filter((i: any) => i.table === "cs_activity_events");
  // Should fire 7-day (most urgent for a cert 5 days out), not 30-day
  assertEquals(events.length, 1);
  assertEquals(events[0].row.payload.threshold, 7);
});

Deno.test("rate cap: stops at 200 events", async () => {
  // Generate 250 certs with unique member_ids to create 250 groups
  const certs = Array.from({ length: 250 }, (_, i) => ({
    id: `c-rate-${i}`,
    member_id: `m-rate-${i}`,
    name: `Cert ${i}`,
    expires_at: daysFromNow(5),
  }));
  const members = certs.map((c) => ({
    id: c.member_id,
    name: `Member ${c.member_id}`,
    user_id: `u-${c.member_id}`,
    created_by: "u-admin",
  }));
  const { client, inserted } = makeStubSupabase({
    certs,
    assignment: { project_id: "p1" },
    members,
  });
  await handle(authReq(), { supabase: client });
  const events = inserted.filter((i: any) => i.table === "cs_activity_events");
  assertEquals(events.length <= 200, true);
});

Deno.test("auto-flips expired active certs to status='expired'", async () => {
  const { client, flipped } = makeStubSupabase({ certs: [] });
  await handle(authReq(), { supabase: client });
  const flip = flipped.find((f: any) => f.table === "cs_certifications");
  assertEquals(flip?.patch.status, "expired");
});

Deno.test("recipient resolution includes PMs and project created_by", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c11", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
    ],
    assignment: { project_id: "p1" },
    members: [
      { id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" },
      { id: "m-pm1", name: "PM Jane", user_id: "u-pm", created_by: "u-admin" },
    ],
    pmAssignments: [{ project_id: "p1", member_id: "m-pm1" }],
    projects: [{ id: "p1", created_by: "u-proj-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  const recipients = evt?.row.payload.recipient_user_ids ?? [];
  // Should include PM user_id and project created_by
  assertEquals(recipients.includes("u-pm"), true);
  assertEquals(recipients.includes("u-proj-creator"), true);
});

Deno.test("payload includes delivery_channels array", async () => {
  const { client, inserted } = makeStubSupabase({
    certs: [
      { id: "c12", member_id: "m1", name: "OSHA 30", expires_at: daysFromNow(5) },
    ],
    assignment: { project_id: "p1" },
    members: [{ id: "m1", name: "John Doe", user_id: "u-member", created_by: "u-creator" }],
  });
  await handle(authReq(), { supabase: client });
  const evt = inserted.find((i: any) => i.table === "cs_activity_events");
  assertEquals(evt?.row.payload.delivery_channels, ["push", "inbox"]);
});
