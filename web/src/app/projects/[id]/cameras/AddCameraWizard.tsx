'use client'
// Phase 22-08 — 2-step Add Camera wizard (modal overlay).
//
// Step 1: Name (1-128 chars) + Location label (0-256) + Audio toggle with D-35 consent.
//   Audio ON shows red jurisdiction warning stripe + confirmation modal.
// Step 2: RTMP URL + Stream key in monospace with Copy buttons (D-23).
//   Stream key shown ONCE. Copy button: "Copy" -> "Copied" (reverts 2s).
//
// POST /api/video/mux/create-live-input on Continue.
// Handles 403 camera_limit_reached + 500/502 mux_ingest_failed.

import { useState, useCallback } from 'react'

type AddCameraWizardProps = {
  projectId: string
  orgId: string
  onComplete: () => void
  onClose: () => void
}

export function AddCameraWizard({
  projectId,
  orgId,
  onComplete,
  onClose,
}: AddCameraWizardProps) {
  const [step, setStep] = useState(1)

  // Step 1 fields
  const [name, setName] = useState('')
  const [locationLabel, setLocationLabel] = useState('')
  const [audioEnabled, setAudioEnabled] = useState(false)
  const [showAudioConfirm, setShowAudioConfirm] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Step 2 credentials
  const [rtmpUrl, setRtmpUrl] = useState('')
  const [streamKey, setStreamKey] = useState('')

  // Copy states
  const [rtmpCopied, setRtmpCopied] = useState(false)
  const [keyCopied, setKeyCopied] = useState(false)

  const nameValid = name.trim().length >= 1 && name.length <= 128

  const handleAudioToggle = useCallback(() => {
    if (!audioEnabled) {
      setShowAudioConfirm(true)
    } else {
      setAudioEnabled(false)
    }
  }, [audioEnabled])

  const handleContinue = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const res = await fetch('/api/video/mux/create-live-input', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: projectId,
          org_id: orgId,
          name: name.trim(),
          location_label: locationLabel.trim(),
          audio_enabled: audioEnabled,
        }),
      })

      if (res.status === 403) {
        const body = await res.json().catch(() => ({ error: 'Forbidden' }))
        if (body.code === 'camera_limit_reached') {
          setError(
            'Camera limit reached (20). Archive an unused camera or contact support to raise the cap.',
          )
        } else {
          setError('Permission denied. You may not have the required role to add cameras.')
        }
        return
      }

      if (res.status >= 500) {
        setError(
          "Couldn't reach Mux to create the camera. Check your connection and try again — nothing has been saved.",
        )
        return
      }

      if (!res.ok) {
        setError(`Couldn't create the camera (HTTP ${res.status}). Please try again.`)
        return
      }

      const data = (await res.json()) as {
        source_id: string
        rtmp_url: string
        stream_key: string
        playback_id: string
      }

      setRtmpUrl(data.rtmp_url)
      setStreamKey(data.stream_key)
      setStep(2)
    } catch {
      setError(
        "Couldn't reach Mux to create the camera. Check your connection and try again — nothing has been saved.",
      )
    } finally {
      setLoading(false)
    }
  }, [projectId, orgId, name, locationLabel, audioEnabled])

  const copyText = useCallback(
    async (text: string, setCopied: (v: boolean) => void) => {
      try {
        await navigator.clipboard.writeText(text)
        setCopied(true)
        setTimeout(() => setCopied(false), 2000)
      } catch {
        // Fallback
      }
    },
    [],
  )

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 100,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'rgba(0,0,0,0.6)',
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose()
      }}
    >
      <div
        style={{
          background: 'var(--bg)',
          borderRadius: 14,
          border: '1px solid var(--border)',
          maxWidth: 480,
          width: '90%',
          maxHeight: '85vh',
          overflow: 'auto',
          padding: 24,
        }}
      >
        {/* Header */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            marginBottom: 16,
          }}
        >
          <h2 style={{ fontSize: 16, fontWeight: 700, color: 'var(--text)', margin: 0 }}>
            {step === 1 ? 'Add camera' : 'Camera credentials'}
          </h2>
          <button
            type="button"
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--muted)',
              fontSize: 16,
              cursor: 'pointer',
            }}
            aria-label="Close"
          >
            &#10005;
          </button>
        </div>

        {step === 1 ? (
          <>
            {/* D-35 jurisdiction warning stripe */}
            {audioEnabled && (
              <div
                style={{
                  padding: 12,
                  borderRadius: 10,
                  background: 'rgba(217, 77, 72, 0.1)',
                  marginBottom: 16,
                  display: 'flex',
                  gap: 8,
                  alignItems: 'flex-start',
                }}
              >
                <span style={{ color: 'var(--red)', fontSize: 14 }}>&#9888;</span>
                <span style={{ fontSize: 12, fontWeight: 500, color: 'var(--red)' }}>
                  Recording audio may require consent from everyone on site. Confirm you have
                  consent before enabling, or leave audio off.
                </span>
              </div>
            )}

            {/* Name field */}
            <label style={{ display: 'block', marginBottom: 16 }}>
              <span
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  display: 'block',
                  marginBottom: 6,
                }}
              >
                NAME
              </span>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Camera name"
                maxLength={128}
                style={{
                  width: '100%',
                  fontSize: 13,
                  color: 'var(--text)',
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  padding: '10px 12px',
                  outline: 'none',
                  boxSizing: 'border-box',
                }}
              />
            </label>

            {/* Location label */}
            <label style={{ display: 'block', marginBottom: 16 }}>
              <span
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  display: 'block',
                  marginBottom: 6,
                }}
              >
                LOCATION LABEL
              </span>
              <input
                type="text"
                value={locationLabel}
                onChange={(e) => setLocationLabel(e.target.value)}
                placeholder="Optional — e.g. NW corner, Level 3"
                maxLength={256}
                style={{
                  width: '100%',
                  fontSize: 13,
                  color: 'var(--text)',
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  borderRadius: 10,
                  padding: '10px 12px',
                  outline: 'none',
                  boxSizing: 'border-box',
                }}
              />
            </label>

            {/* Audio toggle */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: 16,
              }}
            >
              <span style={{ fontSize: 13, fontWeight: 500, color: 'var(--text)' }}>
                Capture audio
              </span>
              <button
                type="button"
                onClick={handleAudioToggle}
                role="switch"
                aria-checked={audioEnabled}
                aria-label="Capture audio"
                style={{
                  width: 44,
                  height: 24,
                  borderRadius: 12,
                  border: 'none',
                  background: audioEnabled ? 'var(--accent)' : 'var(--panel)',
                  cursor: 'pointer',
                  position: 'relative',
                  transition: 'background 0.2s',
                }}
              >
                <span
                  style={{
                    position: 'absolute',
                    top: 2,
                    left: audioEnabled ? 22 : 2,
                    width: 20,
                    height: 20,
                    borderRadius: '50%',
                    background: 'var(--text)',
                    transition: 'left 0.2s',
                  }}
                />
              </button>
            </div>

            {/* D-35 audio consent confirmation dialog */}
            {showAudioConfirm && (
              <div
                style={{
                  padding: 16,
                  borderRadius: 10,
                  background: 'var(--surface)',
                  border: '1px solid var(--border)',
                  marginBottom: 16,
                }}
              >
                <h3
                  style={{
                    fontSize: 14,
                    fontWeight: 700,
                    color: 'var(--text)',
                    margin: '0 0 8px',
                  }}
                >
                  Enable audio capture?
                </h3>
                <p
                  style={{
                    fontSize: 12,
                    color: 'var(--muted)',
                    margin: '0 0 12px',
                    lineHeight: 1.5,
                  }}
                >
                  Recording audio may require two-party consent in your state or country. Only turn
                  this on if everyone who may be recorded has given consent.
                </p>
                <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                  <button
                    type="button"
                    onClick={() => setShowAudioConfirm(false)}
                    style={{
                      fontSize: 12,
                      fontWeight: 600,
                      padding: '8px 16px',
                      borderRadius: 8,
                      border: '1px solid var(--border)',
                      background: 'var(--accent)',
                      color: 'var(--bg)',
                      cursor: 'pointer',
                    }}
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setAudioEnabled(true)
                      setShowAudioConfirm(false)
                    }}
                    style={{
                      fontSize: 12,
                      fontWeight: 600,
                      padding: '8px 16px',
                      borderRadius: 8,
                      border: 'none',
                      background: 'var(--accent)',
                      color: 'var(--bg)',
                      cursor: 'pointer',
                    }}
                  >
                    Enable audio
                  </button>
                </div>
              </div>
            )}

            {/* Error */}
            {error && (
              <div
                style={{
                  padding: 12,
                  borderRadius: 10,
                  background: 'rgba(217, 77, 72, 0.1)',
                  marginBottom: 16,
                  fontSize: 12,
                  color: 'var(--red)',
                }}
              >
                {error}
              </div>
            )}

            {/* Continue button */}
            <button
              type="button"
              onClick={() => void handleContinue()}
              disabled={!nameValid || loading}
              style={{
                width: '100%',
                fontSize: 14,
                fontWeight: 700,
                padding: '12px 0',
                borderRadius: 10,
                border: 'none',
                background:
                  nameValid && !loading ? 'var(--accent)' : 'rgba(158, 189, 194, 0.3)',
                color: 'var(--bg)',
                cursor: nameValid && !loading ? 'pointer' : 'not-allowed',
              }}
            >
              {loading ? 'Creating...' : 'Continue'}
            </button>
          </>
        ) : (
          <>
            <p
              style={{
                fontSize: 13,
                fontWeight: 500,
                color: 'var(--muted)',
                marginBottom: 16,
              }}
            >
              Your camera is registered. Copy the credentials below into your encoder or camera
              settings.
            </p>

            {/* RTMP URL */}
            <div style={{ marginBottom: 16 }}>
              <span
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  display: 'block',
                  marginBottom: 6,
                }}
              >
                RTMP INGEST URL
              </span>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: 12,
                  background: 'var(--surface)',
                  borderRadius: 10,
                }}
              >
                <code
                  style={{
                    fontFamily: "ui-monospace, 'SF Mono', monospace",
                    fontSize: 12,
                    fontWeight: 500,
                    color: 'var(--text)',
                    flex: 1,
                    wordBreak: 'break-all',
                  }}
                >
                  {rtmpUrl}
                </code>
                <button
                  type="button"
                  onClick={() => void copyText(rtmpUrl, setRtmpCopied)}
                  style={{
                    fontSize: 12,
                    fontWeight: 600,
                    color: rtmpCopied ? 'var(--green)' : 'var(--accent)',
                    background: 'var(--panel)',
                    border: 'none',
                    borderRadius: 8,
                    padding: '6px 10px',
                    cursor: 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {rtmpCopied ? 'Copied' : 'Copy'}
                </button>
              </div>
              <span style={{ fontSize: 11, color: 'var(--muted)', display: 'block', marginTop: 4 }}>
                Paste this into your camera or encoder&apos;s streaming settings.
              </span>
            </div>

            {/* Stream key */}
            <div style={{ marginBottom: 16 }}>
              <span
                style={{
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: 2,
                  color: 'var(--muted)',
                  display: 'block',
                  marginBottom: 6,
                }}
              >
                STREAM KEY
              </span>
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 8,
                  padding: 12,
                  background: 'var(--surface)',
                  borderRadius: 10,
                }}
              >
                <code
                  style={{
                    fontFamily: "ui-monospace, 'SF Mono', monospace",
                    fontSize: 12,
                    fontWeight: 500,
                    color: 'var(--text)',
                    flex: 1,
                    wordBreak: 'break-all',
                  }}
                >
                  {streamKey}
                </code>
                <button
                  type="button"
                  onClick={() => void copyText(streamKey, setKeyCopied)}
                  style={{
                    fontSize: 12,
                    fontWeight: 600,
                    color: keyCopied ? 'var(--green)' : 'var(--accent)',
                    background: 'var(--panel)',
                    border: 'none',
                    borderRadius: 8,
                    padding: '6px 10px',
                    cursor: 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {keyCopied ? 'Copied' : 'Copy'}
                </button>
              </div>
              <span style={{ fontSize: 11, color: 'var(--muted)', display: 'block', marginTop: 4 }}>
                Keep this secret — it works like a password. You can copy it now, but it won&apos;t be
                shown again.
              </span>
            </div>

            {/* Finish button */}
            <button
              type="button"
              onClick={() => {
                onComplete()
                onClose()
              }}
              style={{
                width: '100%',
                fontSize: 14,
                fontWeight: 700,
                padding: '12px 0',
                borderRadius: 10,
                border: 'none',
                background: 'var(--accent)',
                color: 'var(--bg)',
                cursor: 'pointer',
              }}
            >
              Finish
            </button>
          </>
        )}
      </div>
    </div>
  )
}
