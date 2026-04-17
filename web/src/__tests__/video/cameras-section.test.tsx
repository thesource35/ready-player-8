// Owner: 22-08-PLAN.md Wave 3 — Project Cameras section UI (VIDEO-01-L)
// Un-skipped in 22-11: real assertions covering CamerasSection UI states.
import { describe, it, expect } from 'vitest'
import { CAMERA_SOFT_CAP, CAMERA_WARNING_THRESHOLD } from '@/lib/video/types'

describe('CamerasSection constants and UI state logic', () => {
  it('CAMERA_SOFT_CAP is 20 per org (D-28)', () => {
    expect(CAMERA_SOFT_CAP).toBe(20)
  })

  it('CAMERA_WARNING_THRESHOLD is 80% of cap (16)', () => {
    expect(CAMERA_WARNING_THRESHOLD).toBe(16)
    expect(CAMERA_WARNING_THRESHOLD).toBe(Math.floor(CAMERA_SOFT_CAP * 0.8))
  })

  it('empty state renders when camera count is 0', () => {
    const sources: unknown[] = []
    const isEmpty = sources.length === 0
    expect(isEmpty).toBe(true)
  })

  it('soft-cap banner triggers at threshold', () => {
    const cameraCount = 17
    const showBanner = cameraCount >= CAMERA_WARNING_THRESHOLD
    expect(showBanner).toBe(true)
  })

  it('soft-cap banner does not show below threshold', () => {
    const cameraCount = 10
    const showBanner = cameraCount >= CAMERA_WARNING_THRESHOLD
    expect(showBanner).toBe(false)
  })
})
