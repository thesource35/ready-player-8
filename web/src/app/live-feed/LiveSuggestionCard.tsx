// Phase 29 LIVE-09 — suggestion card (web).
//
// Severity → border color per UI-SPEC §Color Suggestion Card Severity:
//   routine -> var(--green), opportunity -> var(--gold), alert -> var(--red)
// Color is paired with an inline SVG shape (circle/diamond/triangle) per
// UI-SPEC §Accessibility (color-blind safety — never color alone).
//
// Typography (UI-SPEC §Typography, Phase 21 inherited scale):
//   - action-verb: Label 9px/800 tracking(2px), uppercase
//   - suggestion_text: Body 12px/400 line-height 1.45

'use client'

import type { LiveSuggestion, LiveSuggestionSeverity } from './useSuggestions'

const severityColor: Record<LiveSuggestionSeverity, string> = {
  routine: 'var(--green)',
  opportunity: 'var(--gold)',
  alert: 'var(--red)',
}

function SeverityShape({ severity }: { severity: LiveSuggestionSeverity }) {
  const color = severityColor[severity]
  if (severity === 'routine') {
    return (
      <svg
        width={10}
        height={10}
        viewBox="0 0 10 10"
        aria-hidden="true"
        focusable="false"
      >
        <circle cx={5} cy={5} r={4} fill={color} />
      </svg>
    )
  }
  if (severity === 'opportunity') {
    return (
      <svg
        width={10}
        height={10}
        viewBox="0 0 10 10"
        aria-hidden="true"
        focusable="false"
      >
        <rect x={1} y={1} width={8} height={8} fill={color} transform="rotate(45 5 5)" />
      </svg>
    )
  }
  return (
    <svg
      width={10}
      height={10}
      viewBox="0 0 10 10"
      aria-hidden="true"
      focusable="false"
    >
      <polygon points="5,1 9,9 1,9" fill={color} />
    </svg>
  )
}

export function LiveSuggestionCard({
  suggestion,
  onDismiss,
}: {
  suggestion: LiveSuggestion
  onDismiss: (id: string) => void | Promise<void>
}) {
  const severity: LiveSuggestionSeverity =
    suggestion.action_hint?.severity ?? 'routine'
  const border = severityColor[severity]
  const verb = suggestion.action_hint?.verb ?? null

  return (
    <article
      data-testid="live-suggestion-card"
      data-severity={severity}
      style={{
        position: 'relative',
        background: 'var(--surface)',
        border: `1px solid ${border}`,
        borderRadius: 12,
        padding: 16,
        paddingRight: 36, // reserve space for dismiss button
        marginBottom: 12,
        boxShadow: `0 0 0 1px ${border}22, 0 8px 24px -12px ${border}44`,
      }}
    >
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          marginBottom: verb ? 8 : 0,
        }}
      >
        <SeverityShape severity={severity} />
        {verb && (
          <span
            style={{
              fontSize: 9,
              fontWeight: 800,
              letterSpacing: 2,
              color: severity === 'opportunity' ? 'var(--accent)' : border,
              textTransform: 'uppercase',
            }}
          >
            {verb}
          </span>
        )}
      </div>
      <p
        style={{
          fontSize: 12,
          fontWeight: 400,
          lineHeight: 1.45,
          color: 'var(--text)',
          margin: 0,
        }}
      >
        {suggestion.suggestion_text}
      </p>
      <button
        type="button"
        onClick={() => void onDismiss(suggestion.id)}
        aria-label={`Dismiss suggestion, ${severity}`}
        style={{
          position: 'absolute',
          top: 8,
          right: 8,
          background: 'transparent',
          border: 'none',
          color: 'var(--muted)',
          cursor: 'pointer',
          fontSize: 14,
          lineHeight: 1,
          padding: 4,
        }}
      >
        ×
      </button>
    </article>
  )
}
