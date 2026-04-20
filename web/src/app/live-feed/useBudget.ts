// Phase 29 LIVE-11 — client hook for the daily budget counter.
//
// Polls GET /api/live-feed/budget every 30 s. Same cancel/revert discipline
// as useSuggestions — a failed poll sets `error` and leaves the last-known
// budget in place rather than wiping it (no silent UI flash back to
// unknown-state).

'use client'

import { useCallback, useEffect, useRef, useState } from 'react'

export type Budget = {
  used: number
  remaining: number
  cap: number
  resetsAt: string
}

const POLL_INTERVAL_MS = 30_000

export type UseBudgetResult = {
  budget: Budget | null
  error: string | null
  refresh: () => Promise<void>
}

export function useBudget(projectId: string | null): UseBudgetResult {
  const [budget, setBudget] = useState<Budget | null>(null)
  const [error, setError] = useState<string | null>(null)
  const cancelledRef = useRef<boolean>(false)

  const fetchOnce = useCallback(
    async (id: string | null): Promise<void> => {
      if (!id) {
        setBudget(null)
        return
      }
      try {
        const res = await fetch(
          `/api/live-feed/budget?project_id=${encodeURIComponent(id)}`,
          { cache: 'no-store' },
        )
        if (!res.ok) {
          const parsed = await res.json().catch(() => ({}))
          throw new Error(
            (parsed as { error?: { message?: string } })?.error?.message ??
              'Failed to read budget',
          )
        }
        const parsed = (await res.json()) as Budget
        if (cancelledRef.current) return
        setBudget(parsed)
        setError(null)
      } catch (e: unknown) {
        if (cancelledRef.current) return
        setError(e instanceof Error ? e.message : 'Failed to read budget')
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

  const refresh = useCallback(
    () => fetchOnce(projectId),
    [fetchOnce, projectId],
  )

  return { budget, error, refresh }
}
