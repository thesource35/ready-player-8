'use client'
// Phase 22-07 — Web live-stream player. Mirrors the iOS LiveStreamView contract from 22-06:
// - LL-HLS via Mux Player (`streamType="ll-live"`)
// - Boots muted every session (D-35); unmuted state does NOT persist
// - Optional `portalToken` (D-19) disables DVR scrub + download affordances (D-34(a/b))
// - Fetches the signed Mux JWT via usePlaybackToken → tokens.playback
// - UI-SPEC loading / error / offline copy; accent scrubber via `accentColor="var(--accent)"`
//
// Note on DVR scrub: mux-player-react accepts `targetLiveWindow` as a prop. Passing 0 tells the
// player "there is no seekable window" — the scrub bar collapses to head-only, satisfying D-34(a).
import MuxPlayer from '@mux/mux-player-react'
import type { VideoSource } from '@/lib/video/types'
import { usePlaybackToken } from './usePlaybackToken'
import styles from './playerChrome.module.css'

type LiveStreamViewProps = {
  source: VideoSource
  portalToken?: string | null
}

export function LiveStreamView({ source, portalToken }: LiveStreamViewProps) {
  const isPortal = Boolean(portalToken)
  const { token, playbackId, loading, error, refresh } = usePlaybackToken({
    sourceId: source.id,
    portalToken: portalToken ?? null,
  })

  // Offline short-circuit — operator still sees the card but no player tile loads.
  if (source.status === 'offline') {
    return (
      <div className={styles.container} data-testid="live-offline">
        <div className={styles.badge} aria-label="Camera offline">
          <span className={styles.badgeDotOffline} aria-hidden />
          OFFLINE
        </div>
        <div className={styles.placeholder}>
          <span>Offline · last seen recently</span>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className={styles.container} data-testid="live-loading">
        <div className={styles.placeholder}>
          <span>Connecting to stream…</span>
        </div>
      </div>
    )
  }

  if (error || !token || !playbackId) {
    return (
      <div className={styles.container} data-testid="live-error">
        <div className={styles.placeholder}>
          <span>
            Couldn&apos;t start playback. Refresh the page and try again — if this keeps happening,
            contact support.
          </span>
          <button
            type="button"
            className={styles.retryButton}
            onClick={() => {
              void refresh()
            }}
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  // D-27 status badge — idle/active vocabulary.
  const badgeClass =
    source.status === 'active' ? styles.badgeDotLive : styles.badgeDotIdle
  const badgeLabel = source.status === 'active' ? 'LIVE' : 'IDLE'

  return (
    <div
      className={`${styles.container}${isPortal ? ' ' + styles.portalNoDownload : ''}`}
      data-testid="live-ready"
    >
      <div className={styles.badge} aria-label={`Camera ${badgeLabel.toLowerCase()}`}>
        <span className={badgeClass} aria-hidden />
        {badgeLabel}
      </div>
      <MuxPlayer
        streamType="ll-live"
        playbackId={playbackId}
        tokens={{ playback: token }}
        accentColor="var(--accent)"
        muted
        defaultHiddenCaptions
        // Portal mode: D-34(a) head-only. targetLiveWindow=0 collapses the seekable range so
        // there is no DVR scrub; nohotkeys/noDownload also blocks keyboard-driven scrubbing.
        targetLiveWindow={isPortal ? 0 : undefined}
        nohotkeys={isPortal || undefined}
        style={{
          aspectRatio: '16/9',
          width: '100%',
          height: '100%',
          // Accent scrubber — mux-player honors CSS custom props as an API surface.
          ['--media-primary-color' as string]: 'var(--accent)',
        }}
      />
    </div>
  )
}
