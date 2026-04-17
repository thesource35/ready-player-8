'use client'
// Phase 22-09 — Portal cameras section.
// Renders live cameras + portal-visible VOD clips inside the portal page.
// D-22: No drone sources/assets shown.
// D-34: Players receive portalToken for head-only live / streaming-only VOD.
// D-19: Both LiveStreamView and VideoClipPlayer accept portalToken.
// No upload wizard, no delete controls, no governance UI — read-only viewer.

import { useEffect, useState } from 'react'
import type { VideoSource, VideoAsset } from '@/lib/video/types'
import { LiveStreamView } from '@/app/projects/[id]/cameras/LiveStreamView'
import { VideoClipPlayer } from '@/app/projects/[id]/cameras/VideoClipPlayer'

type PortalCamerasSectionProps = {
  projectId: string
  portalToken: string
}

export default function PortalCamerasSection({
  projectId,
  portalToken,
}: PortalCamerasSectionProps) {
  const [sources, setSources] = useState<VideoSource[]>([])
  const [assets, setAssets] = useState<VideoAsset[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    let cancelled = false

    async function loadData() {
      try {
        // Fetch live camera sources — exclude drones (D-22), only non-archived
        const srcRes = await fetch(
          `/api/portal/video/sources?portal_token=${encodeURIComponent(portalToken)}&project_id=${encodeURIComponent(projectId)}`,
        )
        // If the endpoint doesn't exist yet, degrade gracefully
        const srcData = srcRes.ok ? await srcRes.json() : { sources: [] }

        // Fetch portal-visible VOD clips — exclude drones (D-22)
        const clipRes = await fetch(
          `/api/portal/video/clips?portal_token=${encodeURIComponent(portalToken)}&project_id=${encodeURIComponent(projectId)}`,
        )
        const clipData = clipRes.ok ? await clipRes.json() : { assets: [] }

        if (!cancelled) {
          // Client-side safety filter: exclude drones even if server returns them
          setSources(
            (srcData.sources ?? []).filter(
              (s: VideoSource) => s.kind !== 'drone' && s.status !== 'archived',
            ),
          )
          setAssets(
            (clipData.assets ?? []).filter(
              (a: VideoAsset) =>
                a.source_type !== 'drone' && a.portal_visible && a.status === 'ready',
            ),
          )
          setLoading(false)
        }
      } catch {
        if (!cancelled) setLoading(false)
      }
    }

    void loadData()
    return () => {
      cancelled = true
    }
  }, [portalToken, projectId])

  if (loading) {
    return (
      <div style={{ padding: 24, textAlign: 'center' }}>
        <span style={{ fontSize: 12, color: 'var(--muted)', fontWeight: 600, letterSpacing: 2 }}>
          LOADING CAMERAS...
        </span>
      </div>
    )
  }

  // Nothing to show
  if (sources.length === 0 && assets.length === 0) {
    return null
  }

  return (
    <div style={{ padding: '24px 24px 48px', maxWidth: 1200, margin: '0 auto' }}>
      {/* Section header */}
      <div style={{ marginBottom: 20 }}>
        <h2
          style={{
            fontSize: 11,
            fontWeight: 800,
            letterSpacing: 2,
            color: 'var(--muted)',
            textTransform: 'uppercase',
            marginBottom: 8,
          }}
        >
          CAMERAS
        </h2>
      </div>

      {/* Live cameras grid */}
      {sources.length > 0 && (
        <div style={{ marginBottom: 32 }}>
          <h3
            style={{
              fontSize: 14,
              fontWeight: 600,
              color: 'var(--text)',
              marginBottom: 12,
            }}
          >
            Live Cameras
          </h3>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
              gap: 16,
            }}
          >
            {sources.map((source) => (
              <div key={source.id}>
                <div
                  style={{
                    fontSize: 13,
                    fontWeight: 500,
                    color: 'var(--text)',
                    marginBottom: 6,
                  }}
                >
                  {source.name}
                  {source.location_label && (
                    <span style={{ color: 'var(--muted)', marginLeft: 6 }}>
                      · {source.location_label}
                    </span>
                  )}
                </div>
                <LiveStreamView source={source} portalToken={portalToken} />
              </div>
            ))}
          </div>
        </div>
      )}

      {/* VOD clips grid */}
      {assets.length > 0 && (
        <div>
          <h3
            style={{
              fontSize: 14,
              fontWeight: 600,
              color: 'var(--text)',
              marginBottom: 12,
            }}
          >
            Shared Clips
          </h3>
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))',
              gap: 16,
            }}
          >
            {assets.map((asset) => (
              <div key={asset.id}>
                <div
                  style={{
                    fontSize: 13,
                    fontWeight: 500,
                    color: 'var(--text)',
                    marginBottom: 6,
                  }}
                >
                  {asset.name ?? new Date(asset.started_at).toLocaleDateString()}
                </div>
                <VideoClipPlayer asset={asset} portalToken={portalToken} />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
