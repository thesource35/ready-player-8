// Phase 29 LIVE-11 — manual Analyze-Now trigger.
//
// - Disabled when budget.remaining <= 0 (D-22 cap; the server also enforces
//   this via the analyze route's assertBudgetAvailable pre-check — the client
//   state is only UI guidance).
// - Tooltip copy matches UI-SPEC Copywriting Contract line 422 verbatim.
// - Typography: Label 9px/800 tracking(2px), uppercase (Phase 21 scale).

'use client'

import { useState } from 'react'
import type { Budget } from './useBudget'

export function AnalyzeNowButton({
  projectId,
  budget,
  onAnalyzed,
}: {
  projectId: string | null
  budget: Budget | null
  onAnalyzed?: () => void
}) {
  const [busy, setBusy] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)

  const reached = (budget?.remaining ?? 1) <= 0
  const disabled = !projectId || busy || reached

  async function analyze() {
    if (!projectId) return
    setBusy(true)
    setError(null)
    try {
      const res = await fetch('/api/live-feed/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ project_id: projectId }),
      })
      if (!res.ok) {
        const parsed = await res.json().catch(() => ({}))
        throw new Error(
          (parsed as { error?: { message?: string } })?.error?.message ??
            'Analysis failed',
        )
      }
      onAnalyzed?.()
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Analysis failed')
    } finally {
      setBusy(false)
    }
  }

  const tooltip = reached
    ? 'Suggestion budget reached for today — resumes at 00:00 project-local time.'
    : busy
      ? 'Analyzing…'
      : 'Analyze Now'

  return (
    <div>
      <button
        type="button"
        onClick={analyze}
        disabled={disabled}
        aria-label={tooltip}
        title={tooltip}
        data-testid="analyze-now-button"
        data-disabled={disabled ? 'true' : 'false'}
        style={{
          fontSize: 9,
          fontWeight: 800,
          letterSpacing: 2,
          textTransform: 'uppercase',
          padding: '8px 12px',
          background: disabled ? 'var(--surface)' : 'var(--accent)',
          color: disabled ? 'var(--muted)' : 'var(--bg)',
          border: 'none',
          borderRadius: 8,
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.6 : 1,
        }}
      >
        {busy ? 'Analyzing…' : 'Analyze Now'}
      </button>
      {error && (
        <p
          role="alert"
          style={{ fontSize: 12, color: 'var(--red)', marginTop: 4 }}
        >
          {error}
        </p>
      )}
    </div>
  )
}
