'use client'
// Phase 22-07 — Web VOD player. Mirrors the iOS VideoClipPlayer contract from 22-06:
// - `streamType="on-demand"` with `src` pointed at our signed-manifest route
// - Boots muted every session (D-35)
// - Optional `portalToken` (D-19) → /api/portal/video/playback-url and download affordances suppressed (D-34(b))
// - Status-aware placeholders: uploading / transcoding / failed / ready
// - No PiP in web v1 per UI-SPEC §Player interaction rules.
import MuxPlayer from '@mux/mux-player-react'
import type { VideoAsset } from '@/lib/video/types'
import styles from './playerChrome.module.css'

type VideoClipPlayerProps = {
  asset: VideoAsset
  portalToken?: string | null
}

function buildManifestUrl(assetId: string, portalToken: string | null | undefined): string {
  if (portalToken) {
    return `/api/portal/video/playback-url?asset_id=${encodeURIComponent(
      assetId,
    )}&portal_token=${encodeURIComponent(portalToken)}`
  }
  return `/api/video/vod/playback-url?asset_id=${encodeURIComponent(assetId)}`
}

export function VideoClipPlayer({ asset, portalToken }: VideoClipPlayerProps) {
  const isPortal = Boolean(portalToken)

  // Status-aware placeholders — UI-SPEC "Loading and transitional states" + "Error states".
  if (asset.status === 'uploading') {
    return (
      <div className={styles.container} data-testid="clip-uploading">
        <div className={styles.placeholder}>
          <span>Uploading…</span>
        </div>
      </div>
    )
  }

  if (asset.status === 'transcoding') {
    return (
      <div
        className={`${styles.container} ${styles.shimmer}`}
        data-testid="clip-transcoding"
      >
        <div className={styles.placeholder}>
          <span>Transcoding…</span>
        </div>
      </div>
    )
  }

  if (asset.status === 'failed') {
    return (
      <div className={styles.container} data-testid="clip-failed">
        <div className={`${styles.placeholder} ${styles.placeholderFailed}`}>
          <span>
            Transcode failed. Tap Retry, or re-upload the source file if the problem persists.
          </span>
          {asset.last_error ? (
            <span style={{ fontSize: 11, color: 'var(--muted)', fontWeight: 500 }}>
              {asset.last_error}
            </span>
          ) : null}
        </div>
      </div>
    )
  }

  // status === 'ready' — wire the real player. Portal mode suppresses the download affordance
  // via the playerChrome module's portalNoDownload class + CSS variables (D-34(b)).
  const manifestUrl = buildManifestUrl(asset.id, portalToken)

  return (
    <div
      className={`${styles.container}${isPortal ? ' ' + styles.portalNoDownload : ''}`}
      data-testid="clip-ready"
    >
      <MuxPlayer
        streamType="on-demand"
        src={manifestUrl}
        accentColor="var(--accent)"
        muted
        defaultHiddenCaptions
        // UI-SPEC: no picture-in-picture in web v1.
        disablePictureInPicture
        style={{
          aspectRatio: '16/9',
          width: '100%',
          height: '100%',
          ['--media-primary-color' as string]: 'var(--accent)',
        }}
      />
    </div>
  )
}
