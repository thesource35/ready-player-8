// Phase 29 LIVE-09 — vertical side panel of non-dismissed suggestions.
//
// States (UI-SPEC §States — Loading / Empty / Error):
//   - loading + no prior data → 3 pulsing skeleton cards
//   - error → inline red message
//   - empty → "Analysis Pending" / UI-SPEC Copywriting Contract line 419
//   - populated → list of LiveSuggestionCard
//
// Lives in the right column at ≥ 1280 px (see LiveFeedClient grid); collapses
// below 1024 px per UI-SPEC §Responsive.

'use client'

import { useSuggestions } from './useSuggestions'
import { LiveSuggestionCard } from './LiveSuggestionCard'

export function LiveSuggestionStream({
  projectId,
}: {
  projectId: string | null
}) {
  const { suggestions, loading, error, dismiss } = useSuggestions(projectId)

  if (loading && suggestions.length === 0) {
    return (
      <aside
        aria-label="Suggestion stream"
        data-testid="live-suggestion-stream"
        data-state="loading"
        style={{ padding: 16 }}
      >
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            aria-hidden="true"
            style={{
              background: 'var(--surface)',
              height: 88,
              borderRadius: 12,
              marginBottom: 12,
              opacity: 1 - i * 0.2,
              animation: 'pulse 1.4s ease-in-out infinite',
            }}
          />
        ))}
      </aside>
    )
  }

  if (error) {
    return (
      <aside
        aria-label="Suggestion stream error"
        data-testid="live-suggestion-stream"
        data-state="error"
        role="alert"
        style={{ padding: 16, color: 'var(--red)', fontSize: 12 }}
      >
        {error}
      </aside>
    )
  }

  if (suggestions.length === 0) {
    return (
      <aside
        aria-label="No suggestions"
        data-testid="live-suggestion-stream"
        data-state="empty"
        style={{ padding: 16, color: 'var(--muted)' }}
      >
        <h3
          style={{
            fontSize: 20,
            fontWeight: 800,
            margin: 0,
            marginBottom: 8,
            color: 'var(--text)',
          }}
        >
          Analysis Pending
        </h3>
        <p style={{ fontSize: 12, margin: 0 }}>
          The first AI suggestion will appear here within 15 minutes, or tap
          Analyze Now.
        </p>
      </aside>
    )
  }

  return (
    <aside
      aria-label="Suggestion stream"
      data-testid="live-suggestion-stream"
      data-state="populated"
      style={{ padding: 16, overflowY: 'auto' }}
    >
      {suggestions.map((s) => (
        <LiveSuggestionCard key={s.id} suggestion={s} onDismiss={dismiss} />
      ))}
    </aside>
  )
}
