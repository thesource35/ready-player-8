'use client'
// Phase 22-08 — Clip card tile for the web Cameras section.
// Renders a VideoAsset with status-aware UI per UI-SPEC.
// Purple PORTAL badge when portal_visible. Cyan DRONE pill when source_type === 'drone'.
// Portal toggle and delete only visible to canManage users (D-39).
// D-22: Drone clips have portal toggle disabled with tooltip.
// 200ms ease-out status transitions.

import { useState } from 'react'
import type { VideoAsset } from '@/lib/video/types'
import styles from './playerChrome.module.css'

type ClipCardProps = {
  asset: VideoAsset
  canManage: boolean
  onPlay: () => void
  onRetry: () => void
  onToggleVisibility: (visible: boolean) => void
  onDelete: () => void
}

function formatDuration(seconds: number | null): string | null {
  if (seconds == null || seconds <= 0) return null
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  return `${mins}:${secs.toString().padStart(2, '0')}`
}

export function ClipCard({
  asset,
  canManage,
  onPlay,
  onRetry,
  onToggleVisibility,
  onDelete,
}: ClipCardProps) {
  const [showMenu, setShowMenu] = useState(false)

  const displayName = asset.name ?? new Date(asset.started_at).toLocaleDateString()
  const duration = formatDuration(asset.duration_s)

  // D-33: Retry visible only within 24h of creation
  const retryVisible =
    asset.status === 'failed' &&
    Date.now() - new Date(asset.created_at).getTime() < 86_400_000

  return (
    <div
      style={{
        background: 'var(--surface)',
        borderRadius: 14,
        overflow: 'hidden',
        border: '1px solid var(--border)',
        transition: 'all 0.2s ease-out',
        position: 'relative',
      }}
    >
      {/* 16:9 poster / status area */}
      <div
        style={{
          aspectRatio: '16/9',
          background: 'var(--panel)',
          position: 'relative',
          cursor: asset.status === 'ready' ? 'pointer' : 'default',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}
        onClick={() => {
          if (asset.status === 'ready') onPlay()
        }}
        role={asset.status === 'ready' ? 'button' : undefined}
        tabIndex={asset.status === 'ready' ? 0 : undefined}
        onKeyDown={(e) => {
          if (e.key === 'Enter' && asset.status === 'ready') onPlay()
        }}
      >
        {asset.status === 'ready' && (
          <div className={styles.badge} style={{ position: 'absolute', top: 8, left: 8 }}>
            <span className={styles.badgeDotLive} aria-hidden style={{ animationPlayState: 'paused' }} />
            READY
          </div>
        )}

        {asset.status === 'transcoding' && (
          <div className={styles.shimmer} style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: 'var(--gold)' }}>
              TRANSCODING&hellip;
            </span>
          </div>
        )}

        {asset.status === 'uploading' && (
          <span style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: 'var(--gold)' }}>
            UPLOADING&hellip;
          </span>
        )}

        {asset.status === 'failed' && (
          <div style={{ textAlign: 'center', padding: 16 }}>
            <div style={{ fontSize: 24, color: 'var(--red)', marginBottom: 4 }}>&#10005;</div>
            <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: 2, color: 'var(--red)' }}>
              FAILED
            </div>
            <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4, maxWidth: 240 }}>
              Transcode failed. Tap Retry, or re-upload the source file if the problem persists.
            </div>
            {asset.last_error && (
              <div style={{ fontSize: 10, color: 'var(--muted)', marginTop: 4 }}>
                {asset.last_error}
              </div>
            )}
            {retryVisible && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation()
                  onRetry()
                }}
                className={styles.retryButton}
                style={{ marginTop: 8 }}
              >
                Retry transcode
              </button>
            )}
          </div>
        )}

        {/* Duration overlay (bottom-right) for ready clips */}
        {asset.status === 'ready' && duration && (
          <div
            style={{
              position: 'absolute',
              bottom: 6,
              right: 6,
              fontSize: 11,
              fontWeight: 600,
              color: 'var(--text)',
              background: 'rgba(22, 40, 50, 0.85)',
              padding: '2px 6px',
              borderRadius: 4,
            }}
          >
            {duration}
          </div>
        )}

        {/* Badge pills (top-right) */}
        <div style={{ position: 'absolute', top: 8, right: 8, display: 'flex', gap: 4 }}>
          {asset.portal_visible && (
            <span
              style={{
                fontSize: 9,
                fontWeight: 800,
                letterSpacing: 1,
                color: 'var(--purple)',
                background: 'rgba(138, 143, 204, 0.15)',
                padding: '2px 6px',
                borderRadius: 6,
              }}
            >
              PORTAL
            </span>
          )}
          {asset.source_type === 'drone' && (
            <span
              style={{
                fontSize: 9,
                fontWeight: 800,
                letterSpacing: 1,
                color: 'var(--cyan)',
                background: 'rgba(74, 196, 204, 0.15)',
                padding: '2px 6px',
                borderRadius: 6,
              }}
            >
              DRONE
            </span>
          )}
        </div>
      </div>

      {/* Name + context menu row */}
      <div style={{ padding: '8px 10px', display: 'flex', alignItems: 'center' }}>
        <div
          style={{
            fontSize: 13,
            fontWeight: 500,
            color: 'var(--text)',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
            flex: 1,
          }}
        >
          {displayName}
        </div>

        {canManage && (
          <div style={{ position: 'relative' }}>
            <button
              type="button"
              onClick={() => setShowMenu(!showMenu)}
              style={{
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                fontSize: 14,
                color: 'var(--muted)',
                padding: '2px 4px',
              }}
              aria-label="Clip actions"
            >
              &#8942;
            </button>
            {showMenu && (
              <div
                style={{
                  position: 'absolute',
                  right: 0,
                  top: '100%',
                  background: 'var(--panel)',
                  border: '1px solid var(--border)',
                  borderRadius: 8,
                  padding: 4,
                  zIndex: 10,
                  minWidth: 180,
                }}
              >
                {asset.source_type === 'drone' ? (
                  <div
                    style={{
                      fontSize: 12,
                      color: 'var(--muted)',
                      padding: '6px 10px',
                      cursor: 'not-allowed',
                    }}
                    title="Drone footage can't be shared via portal in this release."
                  >
                    Portal sharing unavailable (drone)
                  </div>
                ) : (
                  <button
                    type="button"
                    onClick={() => {
                      onToggleVisibility(!asset.portal_visible)
                      setShowMenu(false)
                    }}
                    style={{
                      display: 'block',
                      width: '100%',
                      textAlign: 'left',
                      fontSize: 12,
                      color: 'var(--text)',
                      background: 'none',
                      border: 'none',
                      padding: '6px 10px',
                      cursor: 'pointer',
                      borderRadius: 4,
                    }}
                  >
                    {asset.portal_visible ? 'Remove from portal' : 'Share with portal'}
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => {
                    if (
                      confirm(
                        'Delete this clip?\n\nThe clip and its transcoded files will be permanently removed. This cannot be undone.',
                      )
                    ) {
                      onDelete()
                    }
                    setShowMenu(false)
                  }}
                  style={{
                    display: 'block',
                    width: '100%',
                    textAlign: 'left',
                    fontSize: 12,
                    color: 'var(--red)',
                    background: 'none',
                    border: 'none',
                    padding: '6px 10px',
                    cursor: 'pointer',
                    borderRadius: 4,
                  }}
                >
                  Delete clip
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
