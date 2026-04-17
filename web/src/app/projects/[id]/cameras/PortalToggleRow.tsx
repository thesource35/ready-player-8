'use client'
// Phase 22-09 — Show cameras toggle for Phase 20 portal-link editor.
// Wired to cs_portal_config.show_cameras via PUT /api/portal/[id]/config.
// D-21: Toggle controls whether portal viewers see the Cameras section.
// Purple ON-state per UI-SPEC color vocabulary.

import { useState } from 'react'

type PortalToggleRowProps = {
  portalConfigId: string
  initialShowCameras: boolean
  onChange?: (value: boolean) => void
}

export function PortalToggleRow({
  portalConfigId,
  initialShowCameras,
  onChange,
}: PortalToggleRowProps) {
  const [showCameras, setShowCameras] = useState(initialShowCameras)
  const [saving, setSaving] = useState(false)

  async function handleToggle() {
    const next = !showCameras
    setSaving(true)

    try {
      const res = await fetch(`/api/portal/${portalConfigId}/config`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ show_cameras: next }),
      })

      if (res.ok) {
        setShowCameras(next)
        onChange?.(next)
      } else {
        console.error('[PortalToggleRow] Failed to update show_cameras:', await res.text())
      }
    } catch (err) {
      console.error('[PortalToggleRow] Error updating show_cameras:', err)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'flex-start',
        gap: 12,
        padding: '12px 14px',
        background: 'var(--surface)',
        borderRadius: 10,
        border: '1px solid var(--border)',
      }}
    >
      <div style={{ flex: 1 }}>
        <div
          style={{
            fontSize: 14,
            fontWeight: 500,
            color: 'var(--text)',
            marginBottom: 4,
          }}
        >
          Show cameras
        </div>
        <div style={{ fontSize: 12, color: 'var(--muted)', lineHeight: 1.4 }}>
          Portal viewers can watch live streams (head-only) and any clips you&apos;ve flagged as
          shareable below.
        </div>
      </div>
      <button
        type="button"
        role="switch"
        aria-checked={showCameras}
        aria-label="Show cameras"
        disabled={saving}
        onClick={() => void handleToggle()}
        style={{
          width: 44,
          height: 24,
          borderRadius: 12,
          border: 'none',
          cursor: saving ? 'wait' : 'pointer',
          background: showCameras ? 'var(--purple)' : 'var(--border)',
          position: 'relative',
          transition: 'background 0.2s ease-out',
          flexShrink: 0,
          marginTop: 2,
          opacity: saving ? 0.6 : 1,
        }}
      >
        <span
          style={{
            position: 'absolute',
            top: 2,
            left: showCameras ? 22 : 2,
            width: 20,
            height: 20,
            borderRadius: '50%',
            background: '#fff',
            transition: 'left 0.2s ease-out',
            boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
          }}
        />
      </button>
    </div>
  )
}
