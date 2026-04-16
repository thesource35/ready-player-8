// Phase 22 ffmpeg worker — environment config.
// Fail-fast on missing required vars at startup so Fly.io machines crash-loop
// loudly rather than silently accepting jobs they can't process.

function mustEnv(k: string): string {
  const v = process.env[k]
  if (!v || v.length === 0) throw new Error(`Missing env var: ${k}`)
  return v
}

export const config = {
  port: Number(process.env.PORT ?? 8080),
  workerSecret: mustEnv('WORKER_SHARED_SECRET'),
  supabaseUrl: mustEnv('NEXT_PUBLIC_SUPABASE_URL'),
  supabaseServiceRoleKey: mustEnv('SUPABASE_SERVICE_ROLE_KEY'),
  bucket: 'videos' as const,
  // D-09: transcoded assets kept 30 days then pruned by retention cron (22-10).
  retentionDays: 30,
  // D-33: retry policy — 2 attempts after initial failure (30s, 2min backoff).
  retryDelaysMs: [30_000, 120_000] as const,
  // D-31: server-side codec allowlist. ffprobe rejects others before running ffmpeg.
  allowedCodecs: ['h264', 'hevc', 'prores'] as const,
  ffmpegBinary: process.env.FFMPEG_BIN ?? 'ffmpeg',
  ffprobeBinary: process.env.FFPROBE_BIN ?? 'ffprobe',
}

export type WorkerConfig = typeof config
