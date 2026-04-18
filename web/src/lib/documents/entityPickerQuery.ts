import type { SupabaseClient } from "@supabase/supabase-js";
import {
  ENTITY_TYPES,
  ENTITY_TABLE_MAP,
  type DocumentEntityType,
} from "./validation";

/**
 * Phase 26 D-12: returns the subset of DocumentEntityType values whose
 * backing table has at least one row visible to the current user.
 *
 * Implementation: one `select('id', { count: 'exact', head: true })` per
 * entity type — 7 batched HEAD requests in parallel, no row transfer.
 * No N+1 recursion, no manual SQL.
 *
 * Table names are resolved through the hard-coded `ENTITY_TABLE_MAP`
 * literal from validation.ts — user input never flows into the
 * table-name position (T-26-SQLI defense-in-depth).
 */
export async function nonEmptyEntityTypes(
  supabase: SupabaseClient,
): Promise<DocumentEntityType[]> {
  const results = await Promise.all(
    ENTITY_TYPES.map(async (t) => {
      const table = ENTITY_TABLE_MAP[t];
      const { count, error } = await supabase
        .from(table)
        .select("id", { count: "exact", head: true });
      if (error) {
        console.error(
          `[entityPickerQuery] count ${table} failed:`,
          error.message,
        );
        return { t, hasRow: false };
      }
      return { t, hasRow: (count ?? 0) > 0 };
    }),
  );
  return results.filter((r) => r.hasRow).map((r) => r.t);
}

/**
 * Synchronous helper for component use: given the set of non-empty types
 * and the current entity context (the thing the user is already viewing),
 * decide whether to enable attachment. Always true if the current entity
 * context matches the prop — the user is inside that entity, so they
 * must be allowed to attach even if the global picker would hide the type.
 *
 * `project` is treated as always-safe: cs_projects is the anchor table
 * for the organization, is populated before any dependent entity can
 * exist, and its pre-flight is guaranteed by the Phase 26 Plan 03
 * ENTITY_TABLE_MAP contract.
 */
export function shouldEnableAttachment(
  currentEntityType: DocumentEntityType,
  nonEmpty: DocumentEntityType[],
): boolean {
  return (
    nonEmpty.includes(currentEntityType) ||
    currentEntityType === "project" // project type is always safe
  );
}
