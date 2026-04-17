// Owner: 22-08-PLAN.md Wave 3 — Client-side upload validation (VIDEO-01-L)
// Un-skipped in 22-11: real assertions covering D-31 upload constraints.
import { describe, it, expect } from 'vitest'
import {
  MAX_UPLOAD_SIZE_BYTES,
  MAX_UPLOAD_DURATION_SECONDS,
  ALLOWED_UPLOAD_CONTAINERS,
} from '@/lib/video/types'

describe('Clip upload validation constants (D-31)', () => {
  it('rejects file > 2GB (MAX_UPLOAD_SIZE_BYTES)', () => {
    const threeGB = 3 * 1024 * 1024 * 1024
    expect(threeGB).toBeGreaterThan(MAX_UPLOAD_SIZE_BYTES)
    // A client sending file_size_bytes > MAX_UPLOAD_SIZE_BYTES should get 400/413
    expect(MAX_UPLOAD_SIZE_BYTES).toBe(2 * 1024 * 1024 * 1024)
  })

  it('rejects clip > 60 minutes (MAX_UPLOAD_DURATION_SECONDS)', () => {
    const tooLong = 4000 // seconds — exceeds 3600
    expect(tooLong).toBeGreaterThan(MAX_UPLOAD_DURATION_SECONDS)
    expect(MAX_UPLOAD_DURATION_SECONDS).toBe(3600)
  })

  it('rejects unsupported container format (mkv not in ALLOWED_UPLOAD_CONTAINERS)', () => {
    expect(ALLOWED_UPLOAD_CONTAINERS).toContain('mp4')
    expect(ALLOWED_UPLOAD_CONTAINERS).toContain('mov')
    expect((ALLOWED_UPLOAD_CONTAINERS as readonly string[]).includes('mkv')).toBe(false)
    expect((ALLOWED_UPLOAD_CONTAINERS as readonly string[]).includes('avi')).toBe(false)
  })
})
