// Phase 29 LIVE-09 — client hook for cs_live_suggestions.
//
// Fetches via GET /api/live-feed/suggestions (not the Supabase browser client
// directly) so the route's RLS-scoped SELECT + response-shape whitelist apply.
// Polls every 30 s; cancels on unmount. Optimistic dismiss with revert-on-error
// so a failed PATCH never silently "sticks" a removal (CLAUDE.md no silent
// failures).

'use client'

import { useCallback, useEffect, useRef, useState } from 'react'

export type LiveSuggestionSeverity = 'routine' | 'opportunity' | 'alert'

export type LiveSuggestionActionHint = {
  verb?: string | null
  severity: LiveSuggestionSeverity
  structured_fields?: Record<string, unknown>
} | null

export type LiveSuggestion = {
  id: string
  project_id: string
  generated_at: string
  source_asset_id: string | null
  model: string
  suggestion_text: string
  action_hint: LiveSuggestionActionHint
  dismissed_at: string | null
}

const POLL_INTERVAL_MS = 30_000

export type UseSuggestionsResult = {
  suggestions: LiveSuggestion[]
  loading: boolean
  error: string | null
  dismiss: (id: string) => Promise<void>
  refresh: () => Promise<void>
}

export function useSuggestions(projectId: string | null): UseSuggestionsResult {
  const [suggestions, setSuggestions] = useState<LiveSuggestion[]>([])
  const [loading, setLoading] = useState<boolean>(false)
  const [error, setError] = useState<string | null>(null)
  // Keep a ref for the polling loop so we can skip unmounted/stale updates.
  const cancelledRef = useRef<boolean>(false)

  const fetchOnce = useCallback(
    async (id: string | null): Promise<void> => {
      if (!id) {
        setSuggestions([])
        setLoading(false)
        return
      }
      setLoading(true)
      try {
        const res = await fetch(
          `/api/live-feed/suggestions?project_id=${encodeURIComponent(id)}`,
          { cache: 'no-store' },
        )
        if (!res.ok) {
          const parsed = await res.json().catch(() => ({}))
          throw new Error(
            (parsed as { error?: { message?: string } })?.error?.message ??
              'Failed to load suggestions',
          )
        }
        const parsed = (await res.json()) as { suggestions?: LiveSuggestion[] }
        if (cancelledRef.current) return
        setSuggestions(parsed.suggestions ?? [])
        setError(null)
      } catch (e: unknown) {
        if (cancelledRef.current) return
        setError(e instanceof Error ? e.message : 'Failed to load suggestions')
      } finally {
        if (!cancelledRef.current) setLoading(false)
      }
    },
    [],
  )

  useEffect(() => {
    cancelledRef.current = false
    void fetchOnce(projectId)
    if (!projectId) return
    const t = window.setInterval(() => {
      void fetchOnce(projectId)
    }, POLL_INTERVAL_MS)
    return () => {
      cancelledRef.current = true
      window.clearInterval(t)
    }
  }, [projectId, fetchOnce])

  const dismiss = useCallback(
    async (id: string): Promise<void> => {
      const prev = suggestions
      // Optimistic removal so the UI feels instant.
      setSuggestions((s) => s.filter((x) => x.id !== id))
      try {
        const res = await fetch(
          `/api/live-feed/suggestions/${encodeURIComponent(id)}`,
          { method: 'PATCH' },
        )
        if (!res.ok) {
          const parsed = await res.json().catch(() => ({}))
          throw new Error(
            (parsed as { error?: { message?: string } })?.error?.message ??
              'Failed to dismiss',
          )
        }
      } catch (e: unknown) {
        // Revert on failure — never silently drop.
        setSuggestions(prev)
        const msg = e instanceof Error ? e.message : 'Failed to dismiss'
        setError(msg)
        throw e instanceof Error ? e : new Error(msg)
      }
    },
    [suggestions],
  )

  const refresh = useCallback(
    () => fetchOnce(projectId),
    [fetchOnce, projectId],
  )

  return { suggestions, loading, error, dismiss, refresh }
}
