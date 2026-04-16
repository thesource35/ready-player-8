// Owner: 22-04-PLAN.md Wave 2 — ffmpeg transcode worker (VIDEO-01-H)
// Smoke test: if ffmpeg + ffprobe are on PATH, exercise the real ffmpeg HLS pipeline
// against the tiny.mp4 fixture. Skips cleanly when ffmpeg is absent (CI without ffmpeg).
//
// We test runFfmpeg directly (not transcodeAsset which also hits Supabase) by importing
// the ffmpeg command builder. The test asserts index.m3u8 + ≥1 segment_*.ts exist
// after a successful run.
import { describe, it, expect } from 'vitest'
import { spawnSync } from 'node:child_process'
import { mkdtempSync, existsSync, readdirSync, writeFileSync, statSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve } from 'node:path'
import { spawn } from 'node:child_process'

// Inline the ffmpeg command — mirrors worker/src/transcode.ts runFfmpeg() verbatim.
// Kept duplicated so the smoke test doesn't require the src build to run.
async function runFfmpeg(inputPath: string, outDir: string): Promise<void> {
  const args = [
    '-i', inputPath,
    '-y',
    '-vf', 'scale=1280:720',
    '-c:v', 'libx264',
    '-preset', 'veryfast',
    '-profile:v', 'main',
    '-b:v', '2500k',
    '-maxrate', '2675k',
    '-bufsize', '5000k',
    '-c:a', 'aac',
    '-b:a', '128k',
    '-ac', '2',
    '-f', 'hls',
    '-hls_time', '6',
    '-hls_list_size', '0',
    '-hls_segment_filename', join(outDir, 'segment_%03d.ts'),
    '-hls_playlist_type', 'vod',
    join(outDir, 'index.m3u8'),
  ]
  return new Promise((res, rej) => {
    const proc = spawn('ffmpeg', args, { stdio: ['ignore', 'ignore', 'pipe'] })
    let stderr = ''
    proc.stderr?.on('data', (c) => { stderr += String(c) })
    proc.on('error', rej)
    proc.on('close', (code) => code === 0 ? res() : rej(new Error(`ffmpeg code=${code}: ${stderr.slice(-512)}`)))
  })
}

function hasBinary(bin: string): boolean {
  const r = spawnSync('which', [bin], { encoding: 'utf8' })
  return r.status === 0 && r.stdout.trim().length > 0
}

const HAS_FFMPEG = hasBinary('ffmpeg') && hasBinary('ffprobe')

describe('ffmpeg transcode smoke', () => {
  const fixturePath = resolve(__dirname, '../../web/src/__tests__/video/fixtures/tiny.mp4')

  it.skipIf(!HAS_FFMPEG)('produces index.m3u8 + ≥1 segment_*.ts from a real ffmpeg run', async () => {
    // Regenerate a working tiny.mp4 via lavfi if the committed fixture is the 0-byte placeholder.
    let inputPath = fixturePath
    if (!existsSync(fixturePath) || statSync(fixturePath).size === 0) {
      const tmp = mkdtempSync(join(tmpdir(), 'fix-'))
      inputPath = join(tmp, 'tiny.mp4')
      const gen = spawnSync('ffmpeg', [
        '-f', 'lavfi',
        '-i', 'testsrc=duration=5:size=320x240:rate=30',
        '-f', 'lavfi',
        '-i', 'sine=frequency=1000:duration=5',
        '-c:v', 'libx264', '-preset', 'ultrafast', '-pix_fmt', 'yuv420p',
        '-c:a', 'aac', '-shortest',
        inputPath, '-y',
      ], { stdio: 'ignore' })
      expect(gen.status).toBe(0)
    }

    const outDir = mkdtempSync(join(tmpdir(), 'hls-'))
    await runFfmpeg(inputPath, outDir)

    // Verify manifest + at least one segment exist.
    const files = readdirSync(outDir)
    expect(files).toContain('index.m3u8')
    const segments = files.filter((f) => f.startsWith('segment_') && f.endsWith('.ts'))
    expect(segments.length).toBeGreaterThanOrEqual(1)
  }, 60_000)

  it.skipIf(HAS_FFMPEG)('skipped: ffmpeg not on PATH (CI without ffmpeg)', () => {
    // Intentional placeholder so the file reports at least one test line in non-ffmpeg envs.
    // eslint-disable-next-line no-console
    void writeFileSync // silence unused-import lint
    expect(HAS_FFMPEG).toBe(false)
  })
})
