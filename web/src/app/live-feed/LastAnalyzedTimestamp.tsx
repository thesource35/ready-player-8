// Phase 29 LIVE-11 — ticking "Last analyzed {N} min ago" label.
//
// Formats per UI-SPEC Copywriting Contract line 424:
//   < 60 s     → "just now"
//   < 60 min   → "{N} min ago"
//   otherwise  → "{N} h ago"
//
// Polls every 30 s client-side so the label stays fresh without a full
// suggestion-list refetch. Renders nothing when `iso` is null ("never
// analyzed" — UI-SPEC §States line 173).

'use client'

import { useEffect, useState } from 'react'

function formatDelta(iso: string): string {
  const delta = Date.now() - new Date(iso).getTime()
  if (!Number.isFinite(delta) || delta < 0) return 'just now'
  const min = Math.floor(delta / 60_000)
  if (min < 1) return 'just now'
  if (min < 60) return `${min} min ago`
  return `${Math.floor(min / 60)} h ago`
}

export function LastAnalyzedTimestamp({ iso }: { iso: string | null }) {
  const [label, setLabel] = useState<string>(iso ? formatDelta(iso) : '')

  useEffect(() => {
    if (!iso) {
      setLabel('')
      return
    }
    setLabel(formatDelta(iso))
    const t = window.setInterval(() => setLabel(formatDelta(iso)), 30_000)
    return () => window.clearInterval(t)
  }, [iso])

  if (!iso) return null
  return (
    <span
      data-testid="last-analyzed-timestamp"
      style={{
        fontSize: 9,
        fontWeight: 800,
        letterSpacing: 2,
        color: 'var(--cyan)',
        textTransform: 'uppercase',
      }}
    >
      LAST ANALYZED {label}
    </span>
  )
}
