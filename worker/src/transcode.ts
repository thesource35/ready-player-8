// Phase 22 ffmpeg worker — transcode pipeline.
// Flow:
//   1. Update row status='transcoding'.
//   2. Download raw.{ext} from Supabase Storage to /tmp/{asset_id}/raw.{ext}.
//   3. ffprobe to validate codec (h264/hevc/prores per D-31) + extract duration.
//      Unsupported codec -> status='failed' + last_error, NO retry.
//   4. ffmpeg: HLS transcode (6s segments, libx264 preset veryfast). On failure
//      retry up to 2x with [30s, 2min] backoff (D-33).
//   5. Extract poster frame (best-effort; does not fail the transcode if it errors).
//   6. Upload index.m3u8 + segment_*.ts to videos/{org}/{project}/{asset}/hls/ and
//      poster.jpg to videos/{org}/{project}/{asset}/poster.jpg with service-role client.
//   7. Update row: status='ready', duration_s, retention_expires_at=now+30d (D-09).
//   8. On final failure: status='failed', last_error; emit video_transcode_failed marker.

import { spawn } from 'node:child_process'
import { mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import { config } from './config.js'
import { supabase } from './supabase.js'

export type TranscodeJob = {
  asset_id: string
  storage_path: string
  org_id: string
  project_id: string
}

type FfprobeInfo = { codec: string; duration: number }

export async function transcodeAsset(job: TranscodeJob): Promise<void> {
  const { asset_id, storage_path, org_id, project_id } = job
  const workDir = join(tmpdir(), `transcode-${asset_id}`)
  const hlsDir = join(workDir, 'hls')

  // 1. Mark transcoding.
  await updateAssetRow(asset_id, { status: 'transcoding' })

  const transcodeStartMs = Date.now()
  try {
    await mkdir(hlsDir, { recursive: true })

    // 2. Download raw upload.
    const ext = storage_path.split('.').pop() ?? 'mp4'
    const rawPath = join(workDir, `raw.${ext}`)
    await downloadRaw(storage_path, rawPath)

    // 3. Codec allowlist (D-31). NON-RETRYABLE failure on unsupported codec.
    const info = await probeCodec(rawPath)
    if (!(config.allowedCodecs as readonly string[]).includes(info.codec.toLowerCase())) {
      await markFailed(asset_id, `unsupported codec: ${info.codec}`)
      console.error(`[worker] video_transcode_failed asset=${asset_id} reason=unsupported_codec codec=${info.codec}`)
      return
    }

    // 4. ffmpeg with retries (D-33).
    await runFfmpegWithRetry(rawPath, hlsDir)

    // 5. Poster — best-effort.
    const posterPath = join(workDir, 'poster.jpg')
    try {
      await extractPoster(rawPath, posterPath)
    } catch (err) {
      console.warn(`[worker] poster extraction failed for ${asset_id}:`, err instanceof Error ? err.message : err)
    }

    // 6. Upload HLS artefacts.
    const hlsStoragePrefix = `${org_id}/${project_id}/${asset_id}/hls`
    const files = await readdir(hlsDir)
    for (const f of files) {
      const body = await readFile(join(hlsDir, f))
      const contentType = f.endsWith('.m3u8')
        ? 'application/vnd.apple.mpegurl'
        : f.endsWith('.ts')
          ? 'video/mp2t'
          : 'application/octet-stream'
      const { error: upErr } = await supabase.storage
        .from(config.bucket)
        .upload(`${hlsStoragePrefix}/${f}`, body, { contentType, upsert: true })
      if (upErr) throw new Error(`upload ${f}: ${upErr.message}`)
    }
    // Poster (outside hls/ for quick thumbnail access).
    try {
      const posterBody = await readFile(posterPath)
      await supabase.storage
        .from(config.bucket)
        .upload(`${org_id}/${project_id}/${asset_id}/poster.jpg`, posterBody, {
          contentType: 'image/jpeg',
          upsert: true,
        })
    } catch {
      // poster missing — non-fatal
    }

    // 7. Mark ready + set retention (D-09: 30 days).
    const retentionExpiresAt = new Date(Date.now() + config.retentionDays * 24 * 60 * 60 * 1000).toISOString()
    await updateAssetRow(asset_id, {
      status: 'ready',
      duration_s: Math.round(info.duration),
      retention_expires_at: retentionExpiresAt,
      ended_at: new Date().toISOString(),
    })

    // D-40 analytics: video_transcode_succeeded (structured log — pipeline consumes from Fly.io logs)
    const transcodeElapsedMs = Date.now() - transcodeStartMs
    console.log('[analytics]', JSON.stringify({
      event: 'video_transcode_succeeded',
      asset_id,
      duration_s: Math.round(info.duration),
      transcode_elapsed_ms: transcodeElapsedMs,
      project_id,
      org_id,
    }))
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err)
    await markFailed(asset_id, msg)
    // D-40 analytics: video_transcode_failed (structured log)
    const errorCategory = msg.includes('codec') ? 'codec' : msg.includes('upload') ? 'upload' : msg.includes('ffmpeg') ? 'ffmpeg' : 'unknown'
    console.log('[analytics]', JSON.stringify({
      event: 'video_transcode_failed',
      asset_id,
      attempt_number: 3,
      error_category: errorCategory,
      project_id,
      org_id,
    }))
    console.error(`[worker] video_transcode_failed asset=${asset_id} reason=${msg}`)
  } finally {
    await rm(workDir, { recursive: true, force: true }).catch(() => {})
  }
}

async function downloadRaw(storagePath: string, destPath: string): Promise<void> {
  const { data, error } = await supabase.storage.from(config.bucket).download(storagePath)
  if (error || !data) throw new Error(`download ${storagePath}: ${error?.message ?? 'no data'}`)
  const buf = Buffer.from(await data.arrayBuffer())
  await writeFile(destPath, buf)
}

async function probeCodec(inputPath: string): Promise<FfprobeInfo> {
  // ffprobe -v error -select_streams v:0 -show_entries stream=codec_name:format=duration -of json {input}
  const stdout = await runCapture(config.ffprobeBinary, [
    '-v', 'error',
    '-select_streams', 'v:0',
    '-show_entries', 'stream=codec_name:format=duration',
    '-of', 'json',
    inputPath,
  ])
  const parsed = JSON.parse(stdout) as {
    streams?: { codec_name?: string }[]
    format?: { duration?: string }
  }
  const codec = parsed.streams?.[0]?.codec_name ?? 'unknown'
  const duration = parseFloat(parsed.format?.duration ?? '0') || 0
  return { codec, duration }
}

async function runFfmpegWithRetry(inputPath: string, outDir: string): Promise<void> {
  const attempts = 1 + config.retryDelaysMs.length // initial + 2 retries = 3 total
  let lastErr: unknown
  for (let i = 0; i < attempts; i++) {
    try {
      await runFfmpeg(inputPath, outDir)
      return
    } catch (err) {
      lastErr = err
      if (i < config.retryDelaysMs.length) {
        const delay = config.retryDelaysMs[i]
        console.warn(`[worker] ffmpeg attempt ${i + 1} failed, retrying in ${delay}ms:`, err instanceof Error ? err.message : err)
        await sleep(delay)
      }
    }
  }
  throw lastErr instanceof Error ? lastErr : new Error(String(lastErr))
}

async function runFfmpeg(inputPath: string, outDir: string): Promise<void> {
  // Command from 22-RESEARCH.md §ffmpeg transcode command (VERIFIED).
  // -hls_time 6 -hls_list_size 0 -hls_segment_filename 'segment_%03d.ts' produces index.m3u8
  // plus N segment_000.ts segment_001.ts ... files in outDir.
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
  await runSilent(config.ffmpegBinary, args)
}

async function extractPoster(inputPath: string, outPath: string): Promise<void> {
  // Per 22-RESEARCH.md §poster extraction: second pass, simple 3s frame grab.
  await runSilent(config.ffmpegBinary, [
    '-i', inputPath,
    '-ss', '00:00:03',
    '-frames:v', '1',
    '-q:v', '3',
    outPath,
    '-y',
  ])
}

async function runSilent(bin: string, args: string[]): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn(bin, args, { stdio: ['ignore', 'ignore', 'pipe'] })
    let stderr = ''
    proc.stderr?.on('data', (chunk) => { stderr += String(chunk) })
    proc.on('error', reject)
    proc.on('close', (code) => {
      if (code === 0) resolve()
      else reject(new Error(`${bin} exited with code ${code}: ${stderr.slice(-512)}`))
    })
  })
}

async function runCapture(bin: string, args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    const proc = spawn(bin, args, { stdio: ['ignore', 'pipe', 'pipe'] })
    let stdout = ''
    let stderr = ''
    proc.stdout?.on('data', (chunk) => { stdout += String(chunk) })
    proc.stderr?.on('data', (chunk) => { stderr += String(chunk) })
    proc.on('error', reject)
    proc.on('close', (code) => {
      if (code === 0) resolve(stdout)
      else reject(new Error(`${bin} exited with code ${code}: ${stderr.slice(-512)}`))
    })
  })
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function updateAssetRow(
  asset_id: string,
  patch: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase.from('cs_video_assets').update(patch).eq('id', asset_id)
  if (error) throw new Error(`update row ${asset_id}: ${error.message}`)
}

async function markFailed(asset_id: string, lastError: string): Promise<void> {
  try {
    await supabase
      .from('cs_video_assets')
      .update({ status: 'failed', last_error: lastError.slice(0, 512) })
      .eq('id', asset_id)
  } catch (err) {
    console.error(`[worker] failed to mark asset ${asset_id} failed:`, err)
  }
}
