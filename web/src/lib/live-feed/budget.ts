// Phase 29 LIVE-11 — Shared budget helper. Single source of truth for the 96/project/day
// cost cap (D-22). Both the web Analyze-Now route (29-10) and the Edge Function
// generate-live-suggestions (29-03) enforce the same pre-call count check.
//
// v1 rollover = next UTC midnight (per CONTEXT.md Claude's Discretion on project-local
// timezone). cs_live_suggestions rows are counted irrespective of model — including
// 'budget_reached_marker' sentinels written by the Edge Function — because that row
// is itself a generation event the user saw reflected as a card state.

import type { SupabaseClient } from '@supabase/supabase-js'

export const LIVE_SUGGESTION_DAILY_CAP = 96

export type BudgetStatus = {
  used: number
  remaining: number
  cap: number
  resetsAt: string // ISO; v1 = next UTC midnight
}

/**
 * Count cs_live_suggestions rows for a project since UTC midnight today.
 * RLS on the supabase client enforces org-scope — callers should pass an
 * authenticated client (cookie-scoped) unless they are service-role paths
 * explicitly validated upstream.
 */
export async function readBudget(
  supabase: SupabaseClient,
  projectId: string,
): Promise<BudgetStatus> {
  const todayStart = new Date()
  todayStart.setUTCHours(0, 0, 0, 0)

  const { count, error } = await supabase
    .from('cs_live_suggestions')
    .select('id', { count: 'exact', head: true })
    .eq('project_id', projectId)
    .gte('generated_at', todayStart.toISOString())
  if (error) throw error

  const used = count ?? 0
  const tomorrow = new Date(todayStart)
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1)

  return {
    used,
    remaining: Math.max(0, LIVE_SUGGESTION_DAILY_CAP - used),
    cap: LIVE_SUGGESTION_DAILY_CAP,
    resetsAt: tomorrow.toISOString(),
  }
}

/**
 * Pre-call guard for the Analyze-Now route. Throws an Error tagged with
 * `code: 'budget_reached'` and `status: BudgetStatus` when the cap is hit,
 * so the caller can translate to HTTP 429 with a structured envelope.
 */
export async function assertBudgetAvailable(
  supabase: SupabaseClient,
  projectId: string,
): Promise<BudgetStatus> {
  const status = await readBudget(supabase, projectId)
  if (status.remaining <= 0) {
    const err = new Error('budget_reached') as Error & {
      code: string
      status: BudgetStatus
    }
    err.code = 'budget_reached'
    err.status = status
    throw err
  }
  return status
}
