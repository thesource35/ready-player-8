'use client'
// Phase 22-08 — Soft cap banner (D-28).
// At count >= 20: red text "Camera limit reached (20)..." + Contact support CTA.
// At count >= 16 (80%): gold warning "16 of 20 cameras used".
// Hidden below 16.

import { CAMERA_SOFT_CAP, CAMERA_WARNING_THRESHOLD } from '@/lib/video/types'

type SoftCapBannerProps = {
  fixedCameraCount: number
}

export function SoftCapBanner({ fixedCameraCount }: SoftCapBannerProps) {
  if (fixedCameraCount < CAMERA_WARNING_THRESHOLD) return null

  const isLimitReached = fixedCameraCount >= CAMERA_SOFT_CAP

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 8,
        padding: 12,
        borderRadius: 10,
        background: isLimitReached
          ? 'rgba(217, 77, 72, 0.1)'
          : 'rgba(252, 199, 87, 0.1)',
      }}
    >
      <span
        style={{
          fontSize: 14,
          color: isLimitReached ? 'var(--red)' : 'var(--gold)',
        }}
        aria-hidden
      >
        &#9888;
      </span>
      <span
        style={{
          fontSize: 12,
          fontWeight: 500,
          color: isLimitReached ? 'var(--red)' : 'var(--gold)',
          flex: 1,
        }}
      >
        {isLimitReached
          ? 'Camera limit reached (20). Archive an unused camera or contact support to raise the cap.'
          : `${fixedCameraCount} of 20 cameras used`}
      </span>
      {isLimitReached && (
        <button
          type="button"
          style={{
            fontSize: 11,
            fontWeight: 600,
            color: 'var(--accent)',
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            whiteSpace: 'nowrap',
          }}
        >
          Contact support
        </button>
      )}
    </div>
  )
}
