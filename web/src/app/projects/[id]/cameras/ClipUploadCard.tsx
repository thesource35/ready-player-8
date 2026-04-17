'use client'
// Phase 22-08 — Clip upload component with drag-drop + file input.
//
// On file select: client-side pre-check (D-31): size <= 2GB, extension in {mp4, mov},
// duration probe via <video> metadata (max 60min).
// Name field pre-filled with filename stripped of extension (D-38).
// Uses tus-js-client: 6MB chunks, retryDelays [0, 3000, 5000, 10000, 20000].
// POST /api/video/vod/upload-url -> tus upload to Supabase Storage.

import { useState, useRef, useCallback } from 'react'
import * as tus from 'tus-js-client'
import {
  MAX_UPLOAD_SIZE_BYTES,
  MAX_UPLOAD_DURATION_SECONDS,
  ALLOWED_UPLOAD_MIME_TYPES,
} from '@/lib/video/types'

type ClipUploadCardProps = {
  projectId: string
  orgId: string
  onComplete: () => void
  onClose: () => void
}

function stripExtension(filename: string): string {
  const idx = filename.lastIndexOf('.')
  return idx > 0 ? filename.substring(0, idx) : filename
}

async function probeDuration(file: File): Promise<number> {
  return new Promise((resolve) => {
    const video = document.createElement('video')
    video.preload = 'metadata'
    const url = URL.createObjectURL(file)
    video.src = url
    video.onloadedmetadata = () => {
      URL.revokeObjectURL(url)
      resolve(isFinite(video.duration) ? video.duration : 0)
    }
    video.onerror = () => {
      URL.revokeObjectURL(url)
      resolve(0) // Can't probe — skip duration check
    }
  })
}

export function ClipUploadCard({
  projectId,
  orgId,
  onComplete,
  onClose,
}: ClipUploadCardProps) {
  const [file, setFile] = useState<File | null>(null)
  const [clipName, setClipName] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [dragging, setDragging] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const uploadRef = useRef<tus.Upload | null>(null)

  const validateFile = useCallback(async (f: File): Promise<string | null> => {
    // Size check
    if (f.size > MAX_UPLOAD_SIZE_BYTES) {
      return 'File is too large. Clips must be 2 GB or smaller — try trimming the video or exporting at a lower bitrate.'
    }

    // Extension / MIME check
    const mime = f.type.toLowerCase()
    const allowedMimes: readonly string[] = ALLOWED_UPLOAD_MIME_TYPES
    if (!allowedMimes.includes(mime) && !f.name.match(/\.(mp4|mov|m4v)$/i)) {
      return 'Unsupported file type. Use MP4 or MOV — HEVC, H.264, and ProRes are all accepted.'
    }

    // Duration check
    const duration = await probeDuration(f)
    if (duration > MAX_UPLOAD_DURATION_SECONDS) {
      return 'Clip is too long. Maximum length is 60 minutes — please split the recording into shorter segments.'
    }

    return null
  }, [])

  const handleFileSelect = useCallback(
    async (f: File) => {
      setError(null)
      const validationError = await validateFile(f)
      if (validationError) {
        setError(validationError)
        return
      }
      setFile(f)
      setClipName(stripExtension(f.name))
    },
    [validateFile],
  )

  const handleUpload = useCallback(async () => {
    if (!file) return
    setUploading(true)
    setError(null)
    setProgress(0)

    try {
      // Step 1: Get upload URL from server
      const res = await fetch('/api/video/vod/upload-url', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          project_id: projectId,
          org_id: orgId,
          name: clipName || stripExtension(file.name),
          file_size_bytes: file.size,
          duration_s: await probeDuration(file),
          container: file.name.split('.').pop()?.toLowerCase() ?? 'mp4',
        }),
      })

      if (!res.ok) {
        const body = await res.json().catch(() => ({ error: 'Upload failed' }))
        setError(body.error ?? `Upload failed (HTTP ${res.status})`)
        setUploading(false)
        return
      }

      const data = (await res.json()) as {
        asset_id: string
        upload_url: string
        auth_token: string
        object_name: string
        bucket_name: string
      }

      // Step 2: tus upload
      const upload = new tus.Upload(file, {
        endpoint: data.upload_url,
        chunkSize: 6 * 1024 * 1024,
        retryDelays: [0, 3000, 5000, 10000, 20000],
        headers: {
          authorization: `Bearer ${data.auth_token}`,
          'x-upsert': 'false',
        },
        metadata: {
          bucketName: data.bucket_name,
          objectName: data.object_name,
          contentType: file.type,
        },
        onProgress: (bytesUploaded, bytesTotal) => {
          setProgress(bytesUploaded / bytesTotal)
        },
        onSuccess: () => {
          setUploading(false)
          onComplete()
          onClose()
        },
        onError: (err) => {
          setUploading(false)
          setError(err.message || 'Upload failed after 3 tries. Check your connection and tap Retry, or cancel to start over.')
        },
      })

      uploadRef.current = upload

      // Check for previous uploads (resumable)
      const previousUploads = await upload.findPreviousUploads()
      if (previousUploads.length > 0) {
        upload.resumeFromPreviousUpload(previousUploads[0])
      }

      upload.start()
    } catch {
      setUploading(false)
      setError('Upload failed. Check your connection and try again.')
    }
  }, [file, projectId, orgId, clipName, onComplete, onClose])

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
        if (e.target === e.currentTarget && !uploading) onClose()
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
            Upload clip
          </h2>
          <button
            type="button"
            onClick={() => {
              if (!uploading) {
                uploadRef.current?.abort()
                onClose()
              }
            }}
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

        {!file ? (
          <>
            {/* Drag-drop zone */}
            <div
              onDragOver={(e) => {
                e.preventDefault()
                setDragging(true)
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault()
                setDragging(false)
                const f = e.dataTransfer.files[0]
                if (f) void handleFileSelect(f)
              }}
              onClick={() => inputRef.current?.click()}
              style={{
                border: `2px dashed ${dragging ? 'var(--accent)' : 'var(--border)'}`,
                borderRadius: 14,
                padding: 48,
                textAlign: 'center',
                cursor: 'pointer',
                background: dragging ? 'rgba(242, 158, 61, 0.05)' : 'var(--surface)',
                transition: 'all 0.2s',
              }}
              role="button"
              tabIndex={0}
              aria-label="Drop a video file here or click to browse"
            >
              <div style={{ fontSize: 32, marginBottom: 8 }}>&#127909;</div>
              <div style={{ fontSize: 13, fontWeight: 500, color: 'var(--text)' }}>
                Drop a video file here, or click to browse
              </div>
              <div style={{ fontSize: 11, color: 'var(--muted)', marginTop: 4 }}>
                MP4 or MOV, up to 2 GB, max 60 minutes
              </div>
            </div>
            <input
              ref={inputRef}
              type="file"
              accept="video/mp4,video/quicktime,video/x-m4v"
              style={{ display: 'none' }}
              onChange={(e) => {
                const f = e.target.files?.[0]
                if (f) void handleFileSelect(f)
              }}
            />
          </>
        ) : (
          <>
            {/* File selected — show name + upload controls */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                padding: 12,
                background: 'var(--surface)',
                borderRadius: 10,
                marginBottom: 16,
              }}
            >
              <span style={{ fontSize: 16 }}>&#127909;</span>
              <span
                style={{
                  fontSize: 13,
                  color: 'var(--text)',
                  flex: 1,
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {file.name}
              </span>
              {!uploading && (
                <button
                  type="button"
                  onClick={() => {
                    setFile(null)
                    setClipName('')
                    setError(null)
                  }}
                  style={{
                    fontSize: 12,
                    fontWeight: 600,
                    color: 'var(--accent)',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                  }}
                >
                  Change
                </button>
              )}
            </div>

            {/* Name field (D-38) */}
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
                CLIP NAME
              </span>
              <input
                type="text"
                value={clipName}
                onChange={(e) => setClipName(e.target.value)}
                placeholder="Clip name"
                disabled={uploading}
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

            {/* Progress bar */}
            {uploading && (
              <div style={{ marginBottom: 16 }}>
                <div
                  style={{
                    height: 4,
                    borderRadius: 2,
                    background: 'var(--panel)',
                    overflow: 'hidden',
                  }}
                >
                  <div
                    style={{
                      height: '100%',
                      width: `${Math.round(progress * 100)}%`,
                      background: 'var(--gold)',
                      transition: 'width 0.3s',
                      borderRadius: 2,
                    }}
                  />
                </div>
                <div
                  style={{
                    fontSize: 12,
                    fontWeight: 600,
                    color: 'var(--muted)',
                    marginTop: 4,
                    textAlign: 'center',
                  }}
                >
                  Uploading &middot; {Math.round(progress * 100)}%
                </div>
              </div>
            )}
          </>
        )}

        {/* Error */}
        {error && (
          <div
            style={{
              padding: 12,
              borderRadius: 10,
              background: 'rgba(217, 77, 72, 0.1)',
              marginTop: 16,
              fontSize: 12,
              color: 'var(--red)',
            }}
          >
            {error}
          </div>
        )}

        {/* Upload button */}
        {file && !uploading && (
          <button
            type="button"
            onClick={() => void handleUpload()}
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
              marginTop: 16,
            }}
          >
            Upload clip
          </button>
        )}
      </div>
    </div>
  )
}
