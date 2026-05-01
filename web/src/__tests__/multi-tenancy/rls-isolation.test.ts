// Multi-tenancy RLS isolation integration test.
//
// Skipped by default. To run, set ALL three env vars (preferably against
// staging — never prod):
//
//   SUPABASE_TEST_URL=https://...supabase.co
//   SUPABASE_TEST_ANON_KEY=eyJ...        // anon (public) JWT
//   SUPABASE_TEST_SERVICE_KEY=eyJ...      // service_role JWT (admin auth API + cleanup)
//
// Run:
//   cd web
//   SUPABASE_TEST_URL=... SUPABASE_TEST_ANON_KEY=... \
//     SUPABASE_TEST_SERVICE_KEY=... npx vitest run src/__tests__/multi-tenancy
//
// Verifies the contract from the multi-tenancy migration series
// (20260413001 + 20260428002..006):
//   - User A can SELECT their own org-scoped + user-personal rows.
//   - User B with a valid session CANNOT see User A's rows (RLS filters,
//     not errors — invisible rows return empty data, not 403).
//   - Anon (no session) cannot see authenticated-only rows.
//
// Cleanup is best-effort in afterAll. If the test crashes mid-run, you may
// need to manually delete the two rls-{a,b}-<timestamp>@test.constructionos.local
// auth users + their cs_organizations rows from the dashboard.

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.SUPABASE_TEST_URL;
const SUPABASE_ANON = process.env.SUPABASE_TEST_ANON_KEY;
const SUPABASE_SERVICE = process.env.SUPABASE_TEST_SERVICE_KEY;

const haveCreds = Boolean(SUPABASE_URL && SUPABASE_ANON && SUPABASE_SERVICE);

type TestUser = {
  email: string;
  userId: string;
  orgId: string;
  client: SupabaseClient;
};

(haveCreds ? describe : describe.skip)("Multi-tenancy RLS isolation", () => {
  let admin: SupabaseClient;
  let userA: TestUser;
  let userB: TestUser;
  const rowCleanups: Array<() => Promise<void>> = [];

  beforeAll(async () => {
    admin = createClient(SUPABASE_URL!, SUPABASE_SERVICE!, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const stamp = Date.now();
    userA = await provisionUser(admin, `rls-a-${stamp}@test.constructionos.local`);
    userB = await provisionUser(admin, `rls-b-${stamp}@test.constructionos.local`);
  }, 60_000);

  afterAll(async () => {
    for (const fn of rowCleanups.reverse()) {
      try {
        await fn();
      } catch {
        // best-effort
      }
    }
    if (!admin) return;
    // Order matters: cs_organizations.owner_user_id has ON DELETE RESTRICT
    // against auth.users, so the org row must go first. user_orgs cascades
    // from cs_organizations.id so it self-cleans.
    if (userA?.orgId) {
      await admin.from("cs_organizations").delete().eq("id", userA.orgId);
    }
    if (userB?.orgId) {
      await admin.from("cs_organizations").delete().eq("id", userB.orgId);
    }
    if (userA?.userId) {
      await admin.auth.admin.deleteUser(userA.userId).catch(() => {});
    }
    if (userB?.userId) {
      await admin.auth.admin.deleteUser(userB.userId).catch(() => {});
    }
  }, 30_000);

  it("auto-provision: each user got a distinct primary org", () => {
    expect(userA.orgId).toBeTruthy();
    expect(userB.orgId).toBeTruthy();
    expect(userA.orgId).not.toBe(userB.orgId);
  });

  it("cs_projects (org-scoped via direct org_id): cross-isolation enforced", async () => {
    const { data: row, error: insErr } = await userA.client
      .from("cs_projects")
      .insert({ name: `rls-test-${Date.now()}`, org_id: userA.orgId })
      .select()
      .single();
    expect(insErr).toBeNull();
    expect(row).toBeTruthy();
    const projectId = row!.id as string;
    rowCleanups.push(async () => {
      await admin.from("cs_projects").delete().eq("id", projectId);
    });

    const aSeen = await userA.client.from("cs_projects").select().eq("id", projectId);
    expect(aSeen.error).toBeNull();
    expect(aSeen.data?.length).toBe(1);

    const bSeen = await userB.client.from("cs_projects").select().eq("id", projectId);
    expect(bSeen.error).toBeNull();
    expect(bSeen.data?.length).toBe(0);
  });

  it("cs_decision_journal (user-personal): cross-isolation enforced", async () => {
    const { data: row, error: insErr } = await userA.client
      .from("cs_decision_journal")
      .insert({ title: `rls-test-${Date.now()}`, user_id: userA.userId })
      .select()
      .single();
    expect(insErr).toBeNull();
    const entryId = row!.id as string;
    rowCleanups.push(async () => {
      await admin.from("cs_decision_journal").delete().eq("id", entryId);
    });

    const aSeen = await userA.client.from("cs_decision_journal").select().eq("id", entryId);
    expect(aSeen.data?.length).toBe(1);

    const bSeen = await userB.client.from("cs_decision_journal").select().eq("id", entryId);
    expect(bSeen.data?.length).toBe(0);
  });

  it("cs_projects: User B's INSERT with User A's org_id is rejected", async () => {
    const { error } = await userB.client
      .from("cs_projects")
      .insert({ name: `cross-org-attempt-${Date.now()}`, org_id: userA.orgId })
      .select()
      .single();
    // WITH CHECK on the insert policy refuses the row — Supabase returns
    // either 403 with code 42501 or PostgREST RLS code; we just assert error.
    expect(error).not.toBeNull();
  });

  it("anon (no session): cannot see authenticated-only cs_projects rows", async () => {
    const { data: insert } = await userA.client
      .from("cs_projects")
      .insert({ name: `anon-test-${Date.now()}`, org_id: userA.orgId })
      .select()
      .single();
    expect(insert).toBeTruthy();
    const projectId = insert!.id as string;
    rowCleanups.push(async () => {
      await admin.from("cs_projects").delete().eq("id", projectId);
    });

    const anon = createClient(SUPABASE_URL!, SUPABASE_ANON!, {
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data, error } = await anon.from("cs_projects").select().eq("id", projectId);
    // Authenticated-only policies → anon role gets either empty data or a
    // permission error, depending on PG/PostgREST version.
    const blocked = error !== null || (data?.length ?? 0) === 0;
    expect(blocked).toBe(true);
  });
});

async function provisionUser(admin: SupabaseClient, email: string): Promise<TestUser> {
  const password = `Tt-${Math.random().toString(36).slice(2)}-${Date.now()}`;

  const { data: signup, error: signupErr } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (signupErr || !signup.user) {
    throw new Error(`createUser failed for ${email}: ${signupErr?.message ?? "no user"}`);
  }
  const userId = signup.user.id;

  // Auto-provision trigger (on_auth_user_created_org_provision) inserts the
  // user's primary org. Tolerate trigger latency by polling briefly.
  let orgId: string | null = null;
  for (let attempt = 0; attempt < 10 && !orgId; attempt++) {
    const { data } = await admin
      .from("user_orgs")
      .select("org_id")
      .eq("user_id", userId)
      .eq("is_primary", true)
      .limit(1)
      .maybeSingle();
    if (data?.org_id) {
      orgId = data.org_id as string;
      break;
    }
    await new Promise((r) => setTimeout(r, 200));
  }
  if (!orgId) {
    throw new Error(`Auto-provision trigger did not create user_orgs row for ${email}`);
  }

  const client = createClient(SUPABASE_URL!, SUPABASE_ANON!, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { error: signinErr } = await client.auth.signInWithPassword({ email, password });
  if (signinErr) throw new Error(`signIn failed for ${email}: ${signinErr.message}`);

  return { email, userId, orgId, client };
}
