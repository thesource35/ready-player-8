'use client'
// Phase 22-08 — Camera card tile for the web Cameras section.
// Renders a VideoSource with 16:9 thumbnail area, status badge, name, location.
// Click opens parent-controlled expanded state (LiveStreamView inline).
// Context menu (3-dot) visible only when canManage=true.

import type { VideoSource } from '@/lib/video/types'
import styles from './playerChrome.module.css'

type CameraCardProps = {
  source: VideoSource
  canManage: boolean
  onOpen: () => void
  onDelete: () => void
}

function statusBadge(source: VideoSource) {
  const isOffline = source.status === 'offline'
  const isLive = source.status === 'active'

  // D-27: check reconnect grace (5 min)
  let isReconnecting = false
  if (isOffline && source.last_active_at) {
    const elapsed = Date.now() - new Date(source.last_active_at).getTime()
    isReconnecting = elapsed < 300_000
  }

  if (isReconnecting) {
    return (
      <div className={styles.badge} aria-label="Reconnecting">
        <span className={styles.badgeDotIdle} aria-hidden />
        RECONNECTING
      </div>
    )
  }

  const dotClass = isLive
    ? styles.badgeDotLive
    : isOffline
      ? styles.badgeDotOffline
      : styles.badgeDotIdle
  const label = isLive ? 'LIVE' : isOffline ? 'OFFLINE' : 'IDLE'

  return (
    <div className={styles.badge} aria-label={`Camera ${label.toLowerCase()}`}>
      <span className={dotClass} aria-hidden />
      {label}
    </div>
  )
}

export function CameraCard({ source, canManage, onOpen, onDelete }: CameraCardProps) {
  return (
    <div
      style={{
        background: 'var(--surface)',
        borderRadius: 14,
        overflow: 'hidden',
        cursor: 'pointer',
        border: source.status === 'active'
          ? '1px solid var(--accent)'
          : '1px solid var(--border)',
        transition: 'border-color 0.2s ease-out',
        position: 'relative',
      }}
      onClick={onOpen}
      role="button"
      tabIndex={0}
      aria-label={`Open camera ${source.name}`}
      onKeyDown={(e) => { if (e.key === 'Enter') onOpen() }}
    >
      {/* 16:9 thumbnail area */}
      <div
        style={{
          aspectRatio: '16/9',
          background: 'var(--panel)',
          position: 'relative',
        }}
      >
        {statusBadge(source)}
      </div>

      {/* Name + location */}
      <div style={{ padding: '8px 10px' }}>
        <div
          style={{
            fontSize: 13,
            fontWeight: 500,
            color: 'var(--text)',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}
        >
          {source.name}
        </div>
        {source.location_label && (
          <div
            style={{
              fontSize: 10,
              color: 'var(--muted)',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
              marginTop: 2,
            }}
          >
            {source.location_label}
          </div>
        )}
      </div>

      {/* 3-dot menu (canManage only) */}
      {canManage && (
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation()
            if (confirm('Delete this camera?\n\nThis will disconnect the live stream and remove the Mux ingest endpoint. Recorded clips from this camera will remain. This cannot be undone.')) {
              onDelete()
            }
          }}
          style={{
            position: 'absolute',
            top: 8,
            right: 8,
            background: 'rgba(22, 40, 50, 0.85)',
            border: 'none',
            borderRadius: 6,
            padding: '4px 6px',
            cursor: 'pointer',
            fontSize: 14,
            color: 'var(--muted)',
            lineHeight: 1,
          }}
          aria-label="Camera actions"
        >
          &#8942;
        </button>
      )}
    </div>
  )
}
