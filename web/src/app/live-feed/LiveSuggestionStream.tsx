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
//
// Parent lifts useSuggestions via props so the Last-analyzed timestamp +
// TrafficUnifiedCard can share the same poll loop (Rule 1 fix: avoid
// duplicate polling if both this stream and the parent called the hook
// independently).

'use client'

import { useSuggestions, type LiveSuggestion } from './useSuggestions'
import { LiveSuggestionCard } from './LiveSuggestionCard'

export type LiveSuggestionStreamProps = {
  // Option A: self-managed — pass a projectId and the component drives its own hook.
  projectId?: string | null
  // Option B: parent-managed — pass the hook outputs so sibling components can reuse them.
  suggestions?: LiveSuggestion[]
  loading?: boolean
  error?: string | null
  dismiss?: (id: string) => void | Promise<void>
}

export function LiveSuggestionStream(props: LiveSuggestionStreamProps) {
  const parentProvided = 'suggestions' in props && props.suggestions !== undefined
  // Always call the hook to keep hook order stable; when the parent provided
  // its own snapshot, we pass a null projectId so the hook stays idle.
  const hookProjectId = parentProvided ? null : props.projectId ?? null
  const hook = useSuggestions(hookProjectId)
  const suggestions = parentProvided ? props.suggestions! : hook.suggestions
  const loading = parentProvided ? (props.loading ?? false) : hook.loading
  const error = parentProvided ? (props.error ?? null) : hook.error
  const dismiss = parentProvided ? (props.dismiss ?? (() => {})) : hook.dismiss

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
