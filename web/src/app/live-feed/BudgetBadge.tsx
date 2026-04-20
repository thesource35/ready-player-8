// Phase 29 LIVE-11 — cost cap visibility.
//
// 3 states per UI-SPEC §Budget Badge States:
//   healthy  (< 80/96)  → surface bg, muted text,   surface border
//   warning  (80–95/96) → surface bg, gold  text,   gold    border
//   reached  (≥ 96/96)  → red@15% bg,   red   text, red     border
//
// Typography: Label 9px/800 tracking(2px), uppercase — Phase 21 scale.
// VoiceOver label per UI-SPEC §Accessibility line 447.

'use client'

import type { Budget } from './useBudget'

export type BudgetBadgeState = 'healthy' | 'warning' | 'reached'

export function budgetState(budget: Budget | null): BudgetBadgeState | null {
  if (!budget) return null
  if (budget.used >= budget.cap) return 'reached'
  if (budget.used >= budget.cap - 16) return 'warning' // cap=96, warning at ≥80
  return 'healthy'
}

export function BudgetBadge({ budget }: { budget: Budget | null }) {
  if (!budget) return null
  const state = budgetState(budget) ?? 'healthy'
  const color =
    state === 'reached'
      ? 'var(--red)'
      : state === 'warning'
        ? 'var(--gold)'
        : 'var(--muted)'
  const background =
    state === 'reached' ? 'rgba(217, 77, 72, 0.15)' : 'var(--surface)'
  const border =
    state === 'reached'
      ? 'var(--red)'
      : state === 'warning'
        ? 'var(--gold)'
        : 'var(--surface)'
  return (
    <span
      data-testid="budget-badge"
      data-state={state}
      aria-label={`Suggestion budget, ${budget.used} of ${budget.cap} used today, ${state}`}
      style={{
        display: 'inline-block',
        fontSize: 9,
        fontWeight: 800,
        letterSpacing: 2,
        color,
        background,
        border: `1px solid ${border}`,
        borderRadius: 8,
        padding: '4px 8px',
        textTransform: 'uppercase',
      }}
    >
      {budget.used} / {budget.cap} TODAY
    </span>
  )
}
