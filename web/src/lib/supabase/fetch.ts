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

/** Update a row only if it belongs to the given user. Returns null if not found or not owned. (RLS-06) */
export async function updateOwnedRow<T>(
  table: string,
  id: string,
  userId: string,
  updates: Partial<T>
): Promise<T | null> {
  const supabase = await createServerSupabase();
  if (!supabase) return null;

  const { data, error } = await supabase
    .from(table)
    .update(updates)
    .eq("id", id)
    .eq("user_id", userId)
    .select()
    .single();

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
