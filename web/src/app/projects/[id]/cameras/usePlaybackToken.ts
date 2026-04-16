'use client'
// Phase 22-07 — Mux playback token minter hook.
// Routes to /api/video/mux/playback-token by default; to /api/portal/video/playback-token when a
// portalToken is supplied (D-19 dual-path). Auto-refreshes 30s before the server-declared TTL
// expires (D-14 5-min JWT). Tears down the refresh timer on unmount and ignores late responses
// via a cancelledRef guard so we never call setState on an unmounted component.
import { useEffect, useRef, useState, useCallback } from 'react'
import { VideoErrorCode } from '@/lib/video/errors'

export type PlaybackTokenState = {
  token: string | null
  playbackId: string | null
  ttl: number
  loading: boolean
  error: string | null
}

export type UsePlaybackTokenOptions = {
  sourceId: string
  portalToken?: string | null
}

export type UsePlaybackTokenReturn = PlaybackTokenState & {
  refresh: () => Promise<void>
}

export function usePlaybackToken(opts: UsePlaybackTokenOptions): UsePlaybackTokenReturn {
  const { sourceId, portalToken } = opts
  const [state, setState] = useState<PlaybackTokenState>({
    token: null,
    playbackId: null,
    ttl: 0,
    loading: true,
    error: null,
  })
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)
  const cancelledRef = useRef(false)

  const fetchToken = useCallback(async () => {
    if (cancelledRef.current) return
    setState((s) => ({ ...s, loading: true, error: null }))
    try {
      const url = portalToken
        ? '/api/portal/video/playback-token'
        : '/api/video/mux/playback-token'
      const body: Record<string, string> = { source_id: sourceId }
      if (portalToken) body.portal_token = portalToken
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      })
      if (!res.ok) {
        const err = await res
          .json()
          .catch(() => ({
            error: 'Playback token mint failed',
            code: VideoErrorCode.PlaybackTokenMintFailed,
          }))
        throw new Error(err.error || `HTTP ${res.status}`)
      }
      const data = (await res.json()) as {
        token: string
        ttl: number
        playback_id: string
      }
      if (cancelledRef.current) return
      setState({
        token: data.token,
        playbackId: data.playback_id,
        ttl: data.ttl,
        loading: false,
        error: null,
      })
      // Auto-refresh 30s before expiry (D-14 TTL ~300s → refresh ~270s in). Floor at 5s to keep
      // a short TTL from hammering the server.
      const refreshMs = Math.max(5_000, (data.ttl - 30) * 1000)
      if (timerRef.current) clearTimeout(timerRef.current)
      timerRef.current = setTimeout(() => {
        void fetchToken()
      }, refreshMs)
    } catch (e) {
      if (cancelledRef.current) return
      const msg = e instanceof Error ? e.message : String(e)
      setState({
        token: null,
        playbackId: null,
        ttl: 0,
        loading: false,
        error: msg,
      })
    }
  }, [sourceId, portalToken])

  useEffect(() => {
    cancelledRef.current = false
    void fetchToken()
    return () => {
      cancelledRef.current = true
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [fetchToken])

  return { ...state, refresh: fetchToken }
}
