// @vitest-environment jsdom
// Owner: 29-10-PLAN.md Wave 4 — LIVE-11 (web): BudgetBadge healthy/warning/reached states.
// Un-skipped from Wave 0 stub. Asserts UI-SPEC §Budget Badge States thresholds.

import { describe, it, expect, afterEach } from 'vitest'
import { render, screen, cleanup } from '@testing-library/react'
import { BudgetBadge } from '../BudgetBadge'

afterEach(() => cleanup())

const resetsAt = '2026-04-20T00:00:00.000Z'

describe('BudgetBadge', () => {
  it('renders "0 / 96 TODAY" when used=0', () => {
    render(
      <BudgetBadge
        budget={{ used: 0, remaining: 96, cap: 96, resetsAt }}
      />,
    )
    const badge = screen.getByTestId('budget-badge')
    expect(badge.textContent?.replace(/\s+/g, ' ').trim()).toBe('0 / 96 TODAY')
  })

  it('uses healthy styling (muted color) when used=10', () => {
    render(
      <BudgetBadge
        budget={{ used: 10, remaining: 86, cap: 96, resetsAt }}
      />,
    )
    const badge = screen.getByTestId('budget-badge')
    expect(badge.getAttribute('data-state')).toBe('healthy')
    expect(badge.style.color).toContain('var(--muted)')
  })

  it('uses warning styling (gold) when used=85 (cap−16 threshold)', () => {
    render(
      <BudgetBadge
        budget={{ used: 85, remaining: 11, cap: 96, resetsAt }}
      />,
    )
    const badge = screen.getByTestId('budget-badge')
    expect(badge.getAttribute('data-state')).toBe('warning')
    expect(badge.style.color).toContain('var(--gold)')
  })

  it('uses reached styling (red text + red-tinted bg) when used=96', () => {
    render(
      <BudgetBadge
        budget={{ used: 96, remaining: 0, cap: 96, resetsAt }}
      />,
    )
    const badge = screen.getByTestId('budget-badge')
    expect(badge.getAttribute('data-state')).toBe('reached')
    expect(badge.style.color).toContain('var(--red)')
    // Red-tinted bg per UI-SPEC §Budget Badge States "Reached" row
    expect(badge.style.background.replace(/\s+/g, '')).toContain(
      'rgba(217,77,72,0.15)',
    )
  })
})
