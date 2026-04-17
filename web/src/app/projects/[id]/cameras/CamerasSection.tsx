'use client'
// Phase 22-08 — Cameras section for the web project detail page.
//
// Client component that fetches sources + assets on mount, renders:
// - SoftCapBanner (D-28)
// - Header with Add camera + Upload clip CTAs
// - Live cameras grid (CameraCard -> LiveStreamView on expand)
// - Recent clips list (ClipCard -> VideoClipPlayer on expand)
// - Empty states per UI-SPEC
//
// Polls every 5s while any asset has status='transcoding' or 'uploading'.
// 24px outer padding, 32px gap.

import { useEffect, useState, useCallback, useRef } from 'react'
import type { VideoSource, VideoAsset } from '@/lib/video/types'
import { CAMERA_SOFT_CAP, CAMERA_WARNING_THRESHOLD } from '@/lib/video/types'
import { SoftCapBanner } from './SoftCapBanner'
import { CameraCard } from './CameraCard'
import { ClipCard } from './ClipCard'
import { AddCameraWizard } from './AddCameraWizard'
import { ClipUploadCard } from './ClipUploadCard'
import { LiveStreamView } from './LiveStreamView'
import { VideoClipPlayer } from './VideoClipPlayer'

type CamerasSectionProps = {
  projectId: string
  orgId: string
  canManage: boolean
}

export default function CamerasSection({
  projectId,
  orgId,
  canManage,
}: CamerasSectionProps) {
  const [sources, setSources] = useState<VideoSource[]>([])
  const [assets, setAssets] = useState<VideoAsset[]>([])
  const [loading, setLoading] = useState(true)
  const [showWizard, setShowWizard] = useState(false)
  const [showUpload, setShowUpload] = useState(false)
  const [expandedSourceId, setExpandedSourceId] = useState<string | null>(null)
  const [expandedAssetId, setExpandedAssetId] = useState<string | null>(null)
  const pollRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const fetchData = useCallback(async () => {
    try {
      const [srcRes, assetRes] = await Promise.all([
        fetch(`/api/video/sources?project_id=${encodeURIComponent(projectId)}`),
        fetch(`/api/video/assets?project_id=${encodeURIComponent(projectId)}`),
      ])
      if (srcRes.ok) {
        const data = (await srcRes.json()) as VideoSource[]
        setSources(Array.isArray(data) ? data : [])
      }
      if (assetRes.ok) {
        const data = (await assetRes.json()) as VideoAsset[]
        setAssets(Array.isArray(data) ? data : [])
      }
    } catch {
      // Silently keep stale data on network error
    } finally {
      setLoading(false)
    }
  }, [projectId])

  // Initial fetch
  useEffect(() => {
    void fetchData()
  }, [fetchData])

  // Poll while any asset is transcoding or uploading
  useEffect(() => {
    const needsPoll = assets.some(
      (a) => a.status === 'transcoding' || a.status === 'uploading',
    )
    if (needsPoll) {
      pollRef.current = setInterval(() => {
        void fetchData()
      }, 5000)
    }
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [assets, fetchData])

  // Filtered lists
  const liveSources = sources.filter(
    (s) => s.kind === 'fixed_camera' && s.status !== 'archived',
  )
  const recentClips = [...assets]
    .filter((a) => a.kind === 'vod')
    .sort((a, b) => new Date(b.started_at).getTime() - new Date(a.started_at).getTime())

  // D-28 soft cap count (all fixed cameras in this org)
  const fixedCameraCount = sources.filter(
    (s) => s.kind === 'fixed_camera' && s.status !== 'archived',
  ).length
  const atCap = fixedCameraCount >= CAMERA_SOFT_CAP

  const handleRefresh = useCallback(() => {
    void fetchData()
  }, [fetchData])

  if (loading) {
    return (
      <section
        style={{
          padding: 24,
          background: 'var(--surface)',
          borderRadius: 14,
          marginTop: 32,
          border: '1px solid var(--border)',
        }}
      >
        <div style={{ color: 'var(--muted)', fontSize: 13 }}>Loading cameras...</div>
      </section>
    )
  }

  return (
    <section
      style={{
        padding: 24,
        background: 'var(--surface)',
        borderRadius: 14,
        marginTop: 32,
        border: '1px solid var(--border)',
      }}
    >
      {/* Soft-cap banner */}
      {fixedCameraCount >= CAMERA_WARNING_THRESHOLD && (
        <div style={{ marginBottom: 16 }}>
          <SoftCapBanner fixedCameraCount={fixedCameraCount} />
        </div>
      )}

      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          marginBottom: 24,
        }}
      >
        <h2
          style={{
            fontSize: 16,
            fontWeight: 700,
            color: 'var(--text)',
            margin: 0,
            flex: 1,
          }}
        >
          Cameras
        </h2>
        {canManage && (
          <>
            <button
              type="button"
              onClick={() => setShowUpload(true)}
              style={{
                fontSize: 12,
                fontWeight: 600,
                color: 'var(--text)',
                background: 'var(--surface)',
                border: '1px solid var(--border)',
                borderRadius: 8,
                padding: '6px 10px',
                cursor: 'pointer',
              }}
            >
              Upload clip
            </button>
            <button
              type="button"
              onClick={() => setShowWizard(true)}
              disabled={atCap}
              style={{
                fontSize: 12,
                fontWeight: 600,
                color: 'var(--bg)',
                background: atCap ? 'rgba(158, 189, 194, 0.3)' : 'var(--accent)',
                border: 'none',
                borderRadius: 8,
                padding: '6px 10px',
                cursor: atCap ? 'not-allowed' : 'pointer',
              }}
            >
              Add camera
            </button>
          </>
        )}
      </div>

      {/* Content */}
      {liveSources.length === 0 && recentClips.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '48px 0' }}>
          <h3 style={{ fontSize: 16, fontWeight: 700, color: 'var(--text)', margin: '0 0 8px' }}>
            No cameras yet
          </h3>
          <p
            style={{
              fontSize: 13,
              fontWeight: 500,
              color: 'var(--muted)',
              maxWidth: 400,
              margin: '0 auto',
              lineHeight: 1.5,
            }}
          >
            Register a jobsite camera to start streaming, or upload a recorded clip. Live streams
            use Mux; uploads transcode in the background.
          </p>
        </div>
      ) : (
        <>
          {/* Live Cameras */}
          {liveSources.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '24px 0' }}>
              <h3
                style={{
                  fontSize: 16,
                  fontWeight: 700,
                  color: 'var(--text)',
                  margin: '0 0 8px',
                }}
              >
                No live cameras
              </h3>
              <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--muted)' }}>
                You have {recentClips.length} recorded clips below. Add a camera to watch the site
                in real time.
              </p>
            </div>
          ) : (
            <div style={{ marginBottom: 32 }}>
              <div
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  marginBottom: 8,
                }}
              >
                LIVE CAMERAS
              </div>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                  gap: 12,
                }}
              >
                {liveSources.map((source) =>
                  expandedSourceId === source.id ? (
                    <div key={source.id}>
                      <LiveStreamView source={source} />
                      <button
                        type="button"
                        onClick={() => setExpandedSourceId(null)}
                        style={{
                          fontSize: 12,
                          fontWeight: 600,
                          color: 'var(--muted)',
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          marginTop: 4,
                        }}
                      >
                        Close
                      </button>
                    </div>
                  ) : (
                    <CameraCard
                      key={source.id}
                      source={source}
                      canManage={canManage}
                      onOpen={() => setExpandedSourceId(source.id)}
                      onDelete={() => {
                        void fetch(`/api/video/mux/delete-live-input`, {
                          method: 'DELETE',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ source_id: source.id }),
                        }).then(() => handleRefresh())
                      }}
                    />
                  ),
                )}
              </div>
            </div>
          )}

          {/* Recent Clips */}
          {recentClips.length === 0 && liveSources.length > 0 ? (
            <div style={{ textAlign: 'center', padding: '24px 0' }}>
              <h3
                style={{
                  fontSize: 16,
                  fontWeight: 700,
                  color: 'var(--text)',
                  margin: '0 0 8px',
                }}
              >
                No clips yet
              </h3>
              <p style={{ fontSize: 13, fontWeight: 500, color: 'var(--muted)' }}>
                Recorded clips from this project will appear here for 30 days. Upload a file or
                wait for a live session to archive.
              </p>
            </div>
          ) : recentClips.length > 0 ? (
            <div>
              <div
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  marginBottom: 8,
                }}
              >
                RECENT CLIPS
              </div>
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))',
                  gap: 12,
                }}
              >
                {recentClips.map((asset) =>
                  expandedAssetId === asset.id ? (
                    <div key={asset.id}>
                      <VideoClipPlayer asset={asset} />
                      <button
                        type="button"
                        onClick={() => setExpandedAssetId(null)}
                        style={{
                          fontSize: 12,
                          fontWeight: 600,
                          color: 'var(--muted)',
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          marginTop: 4,
                        }}
                      >
                        Close
                      </button>
                    </div>
                  ) : (
                    <ClipCard
                      key={asset.id}
                      asset={asset}
                      canManage={canManage}
                      onPlay={() => setExpandedAssetId(asset.id)}
                      onRetry={() => {
                        // TODO: Wire retry transcode API call
                      }}
                      onToggleVisibility={(visible) => {
                        void fetch(`/api/video/assets/${asset.id}/portal-visible`, {
                          method: 'PATCH',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify({ portal_visible: visible }),
                        }).then(() => handleRefresh())
                      }}
                      onDelete={() => {
                        void fetch(`/api/video/assets/${asset.id}`, {
                          method: 'DELETE',
                        }).then(() => handleRefresh())
                      }}
                    />
                  ),
                )}
              </div>
            </div>
          ) : null}
        </>
      )}

      {/* Modals */}
      {showWizard && (
        <AddCameraWizard
          projectId={projectId}
          orgId={orgId}
          onComplete={handleRefresh}
          onClose={() => setShowWizard(false)}
        />
      )}
      {showUpload && (
        <ClipUploadCard
          projectId={projectId}
          orgId={orgId}
          onComplete={handleRefresh}
          onClose={() => setShowUpload(false)}
        />
      )}
    </section>
  )
}
