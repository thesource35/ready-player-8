// @vitest-environment jsdom
// Owner: 29-10-PLAN.md Wave 4 — LIVE-09 (web): LiveSuggestionCard dismiss flow.
// Un-skipped from Wave 0 stub. Asserts the three card-contract properties:
//   1) suggestion_text renders
//   2) severity drives the border color (UI-SPEC §Color Suggestion Card Severity)
//   3) clicking the × button calls onDismiss with the suggestion id

import { describe, it, expect, afterEach, vi } from 'vitest'
import { render, screen, fireEvent, cleanup } from '@testing-library/react'
import { LiveSuggestionCard } from '../LiveSuggestionCard'
import type { LiveSuggestion } from '../useSuggestions'

afterEach(() => cleanup())

function makeSuggestion(
  overrides: Partial<LiveSuggestion> = {},
): LiveSuggestion {
  return {
    id: 'sug-123',
    project_id: 'proj-abc',
    generated_at: '2026-04-19T12:00:00Z',
    source_asset_id: 'asset-xyz',
    model: 'claude-haiku-4-5-20251001',
    suggestion_text: 'Concrete pour continuing at the east foundation.',
    action_hint: { verb: 'Monitor', severity: 'routine' },
    dismissed_at: null,
    ...overrides,
  }
}

describe('LiveSuggestionCard', () => {
  it('renders suggestion_text', () => {
    render(
      <LiveSuggestionCard
        suggestion={makeSuggestion()}
        onDismiss={() => {}}
      />,
    )
    expect(
      screen.getByText('Concrete pour continuing at the east foundation.'),
    ).toBeTruthy()
  })

  it('sets border color based on severity (routine/opportunity/alert)', () => {
    // routine → green
    const { rerender } = render(
      <LiveSuggestionCard
        suggestion={makeSuggestion({
          action_hint: { verb: null, severity: 'routine' },
        })}
        onDismiss={() => {}}
      />,
    )
    let card = screen.getByTestId('live-suggestion-card')
    expect(card.getAttribute('data-severity')).toBe('routine')
    // style prop carries the border CSS; jsdom exposes it via inline `style.border`
    expect(card.style.border).toContain('var(--green)')

    // opportunity → gold
    rerender(
      <LiveSuggestionCard
        suggestion={makeSuggestion({
          action_hint: { verb: null, severity: 'opportunity' },
        })}
        onDismiss={() => {}}
      />,
    )
    card = screen.getByTestId('live-suggestion-card')
    expect(card.getAttribute('data-severity')).toBe('opportunity')
    expect(card.style.border).toContain('var(--gold)')

    // alert → red
    rerender(
      <LiveSuggestionCard
        suggestion={makeSuggestion({
          action_hint: { verb: null, severity: 'alert' },
        })}
        onDismiss={() => {}}
      />,
    )
    card = screen.getByTestId('live-suggestion-card')
    expect(card.getAttribute('data-severity')).toBe('alert')
    expect(card.style.border).toContain('var(--red)')
  })

  it('calls onDismiss with the suggestion id when × button clicked', () => {
    const onDismiss = vi.fn()
    render(
      <LiveSuggestionCard
        suggestion={makeSuggestion({ id: 'sug-dismiss-me' })}
        onDismiss={onDismiss}
      />,
    )
    const btn = screen.getByLabelText(/Dismiss suggestion/)
    fireEvent.click(btn)
    expect(onDismiss).toHaveBeenCalledWith('sug-dismiss-me')
  })
})
