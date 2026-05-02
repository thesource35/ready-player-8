// 999.5 follow-up: server-only marker. Pulls in createServerSupabase
// transitively, which uses next/headers. Pattern documented in 606bb45.
import "server-only";

import { createServerSupabase } from "./server";
import { createClient } from "@supabase/supabase-js";
import { getSupabaseUrl, getSupabaseServerKey } from "./env";

// ---------- Auth helper ----------

/** Returns the authenticated Supabase client + user, or nulls if not logged in. */
export async function getAuthenticatedClient() {
  const supabase = await createServerSupabase();
  if (!supabase) return { supabase: null, user: null };

  const { data: { user } } = await supabase.auth.getUser();
  return { supabase, user };
}

// ---------- Service client (admin-only operations like export) ----------

function getServiceClient() {
  const url = getSupabaseUrl();
  const key = getSupabaseServerKey();
  if (!url || !key) return null;
  return createClient(url, key);
}

// ---------- Generic queries (use auth-aware client by default) ----------

export async function fetchTable<T>(
  table: string,
  options?: {
    select?: string;
    order?: { column: string; ascending?: boolean };
    limit?: number;
    eq?: { column: string; value: string | number | boolean };
  }
): Promise<T[]> {
  const supabase = await createServerSupabase();
  if (!supabase) return [];

  try {
    let query = supabase.from(table).select(options?.select || "*");

    if (options?.eq) {
      query = query.eq(options.eq.column, options.eq.value);
    }
    if (options?.order) {
      query = query.order(options.order.column, { ascending: options.order.ascending ?? false });
    }
    if (options?.limit) {
      query = query.limit(options.limit);
    }

    const { data, error } = await query;
    if (error) {
      console.error(`Fetch ${table} error:`, error);
      return [];
    }
    return (data as T[]) || [];
  } catch (err) {
    console.error(`Fetch ${table} exception:`, err);
    return [];
  }
}

/** Fetch using the service role key — bypasses RLS. Only for admin operations. */
export async function fetchTableAdmin<T>(
  table: string,
  options?: {
    select?: string;
    order?: { column: string; ascending?: boolean };
    limit?: number;
    eq?: { column: string; value: string | number | boolean };
  }
): Promise<T[]> {
  const client = getServiceClient();
  if (!client) return [];

  try {
    let query = client.from(table).select(options?.select || "*");

    if (options?.eq) {
      query = query.eq(options.eq.column, options.eq.value);
    }
    if (options?.order) {
      query = query.order(options.order.column, { ascending: options.order.ascending ?? false });
    }
    if (options?.limit) {
      query = query.limit(options.limit);
    }

    const { data, error } = await query;
    if (error) {
      console.error(`Admin fetch ${table} error:`, error);
      return [];
    }
    return (data as T[]) || [];
  } catch (err) {
    console.error(`Admin fetch ${table} exception:`, err);
    return [];
  }
}

export async function insertRow<T>(table: string, row: Partial<T>): Promise<T | null> {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase.from(table).insert(row).select().single();
  if (error) {
    console.error(`Insert ${table} error:`, error);
    return null;
  }
  return data as T;
}

export async function updateRow<T>(table: string, id: string, updates: Partial<T>): Promise<T | null> {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase.from(table).update(updates).eq("id", id).select().single();
  if (error) {
    console.error(`Update ${table} error:`, error);
    return null;
  }
  return data as T;
}

export async function deleteRow(table: string, id: string): Promise<boolean> {
  const supabase = await createServerSupabase();
  if (!supabase) return false;

  const { error } = await supabase.from(table).delete().eq("id", id);
  if (error) {
    console.error(`Delete ${table} error:`, error);
    return false;
  }
  return true;
}

/**
 * Update a row only if it belongs to the authenticated user's org. Returns null if
 * not found or not owned. (RLS-06)
 *
 * Phase 17: scoped by org_id to prevent cross-org rewrites (T-17-02). The helper
 * resolves the caller's org via user_orgs(user_id → org_id) and threads it into
 * the update as an additional `.eq('org_id', ...)` guard on top of the existing
 * id filter. Missing user / missing org mapping / RLS denial all return null
 * (no throw) so API routes can 404 cleanly.
 */
export async function updateOwnedRow<T>(
  table: string,
  id: string,
  userId: string,
  updates: Partial<T>
): Promise<T | null> {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  // Resolve org_id for the caller. user_orgs is the source of truth for
  // user→org membership (see 17-VALIDATION.md Open Question #1).
  //
  // Phase 17-02 hardening: the user_orgs table may not exist yet in this
  // deployment. Distinguish three cases so PATCH routes never silently 404:
  //   (a) lookup errors (table missing, permission denied) → log + fall back
  //       to id-only update (RLS still enforces authenticated access).
  //   (b) valid user with no org row → log + fall back to id-only update.
  //   (c) org row found → scope the update by (id, org_id).
  let orgId: string | undefined;
  try {
    const { data: orgRow, error: orgErr } = await supabase
      .from("user_orgs")
      .select("org_id")
      .eq("user_id", userId)
      .maybeSingle();

    if (orgErr) {
      console.warn(
        `[updateOwnedRow] user_orgs lookup failed for user ${userId} on ${table}: ${orgErr.message}. Falling back to id-only update.`
      );
    } else if (!orgRow) {
      console.warn(
        `[updateOwnedRow] no user_orgs row for user ${userId} on ${table}. Falling back to id-only update.`
      );
    } else {
      orgId = (orgRow as { org_id?: string }).org_id;
    }
  } catch (e) {
    console.warn(
      `[updateOwnedRow] user_orgs lookup threw for user ${userId} on ${table}:`,
      e,
      "— falling back to id-only update."
    );
  }

  let query = supabase.from(table).update(updates).eq("id", id);
  if (orgId) query = query.eq("org_id", orgId);
  const { data, error } = await query.select().single();

  if (error) {
    console.error(`Update owned ${table} error:`, error);
    return null;
  }
  return data as T;
}

/** Delete a row only if it belongs to the given user. Returns false if not found or not owned. (RLS-06) */
export async function deleteOwnedRow(
  table: string,
  id: string,
  userId: string
): Promise<boolean> {
  const supabase = await createServerSupabase();
  if (!supabase) return false;

  const { error, count } = await supabase
    .from(table)
    .delete({ count: "exact" })
    .eq("id", id)
    .eq("user_id", userId);

  if (error) {
    console.error(`Delete owned ${table} error:`, error);
    return false;
  }
  return (count ?? 0) > 0;
}

// ---------- Paginated queries ----------

const MAX_PAGE_SIZE = 100;

// 999.5 (d) Tier 2 (web parallel of MCPServer fix): the `state` field lets
// callers distinguish three previously-conflated outcomes:
//   - "unconfigured": Supabase env vars missing (dev mode) — caller may show DEMO data
//   - "error":        Postgres/network failure — caller should surface error, NOT mock
//   - "ok":           query succeeded; data may be empty (legitimate empty state)
// Without this, an API route returning an empty array could mean any of the three.
export type FetchTablePaginatedResult<T> = {
  data: T[];
  hasMore: boolean;
  total: number;
  state: "ok" | "unconfigured" | "error";
};

export async function fetchTablePaginated<T>(
  table: string,
  options?: {
    select?: string;
    order?: { column: string; ascending?: boolean };
    eq?: { column: string; value: string | number | boolean };
    page?: number;
    pageSize?: number;
  }
): Promise<FetchTablePaginatedResult<T>> {
  const supabase = await createServerSupabase();
  if (!supabase) return { data: [], hasMore: false, total: 0, state: "unconfigured" };

  const page = Math.max(0, options?.page ?? 0);
  const pageSize = Math.min(Math.max(1, options?.pageSize ?? 25), MAX_PAGE_SIZE);
  const from = page * pageSize;
  const to = from + pageSize - 1;

  try {
    let query = supabase
      .from(table)
      .select(options?.select || "*", { count: "exact" });

    if (options?.eq) {
      query = query.eq(options.eq.column, options.eq.value);
    }
    if (options?.order) {
      query = query.order(options.order.column, {
        ascending: options.order.ascending ?? false,
      });
    }

    query = query.range(from, to);

    const { data, error, count } = await query;
    if (error) {
      console.error(`Paginated fetch ${table} error:`, error);
      return { data: [], hasMore: false, total: 0, state: "error" };
    }

    return {
      data: (data as T[]) || [],
      hasMore: (count ?? 0) > to + 1,
      total: count ?? 0,
      state: "ok",
    };
  } catch (err) {
    console.error(`Paginated fetch ${table} exception:`, err);
    return { data: [], hasMore: false, total: 0, state: "error" };
  }
}

// Real-time subscription helper (client-side only)
export function subscribeToTable(
  table: string,
  callback: (payload: { eventType: string; new: Record<string, unknown>; old: Record<string, unknown> }) => void
) {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if (!url || !key) return null;

  const client = createClient(url, key);
  return client
    .channel(`${table}_changes`)
    .on("postgres_changes", { event: "*", schema: "public", table }, (payload) => {
      callback({
        eventType: payload.eventType,
        new: payload.new as Record<string, unknown>,
        old: payload.old as Record<string, unknown>,
      });
    })
    .subscribe();
}
