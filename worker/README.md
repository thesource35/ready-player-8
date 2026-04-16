# ConstructionOS Video Transcode Worker

Standalone ffmpeg transcode service for Phase 22 (Live Site Video -- per-project HLS camera feeds).

## Role

This worker converts user-uploaded clips into HLS manifests ready for streaming via the web portal and iOS app. It runs outside the Vercel serverless runtime because ffmpeg transcoding exceeds function limits (memory, CPU time, disk).

## Flow

1. Receives `POST /transcode` from a Supabase pg_net trigger when a new row lands in `cs_video_assets` with `kind='vod'` and `status='uploading'`.
2. Downloads the raw file (`raw.{ext}`) from Supabase Storage using the service-role key.
3. Validates codec via ffprobe (allowlist: h264, hevc, prores per D-31). Rejects unsupported codecs without retry.
4. Runs `ffmpeg` to produce:
   - HLS manifest (`index.m3u8`) at 720p (libx264 veryfast)
   - Segmented `.ts` files (~6s each, `hls_time 6`)
   - `poster.jpg` thumbnail from the 3-second mark
5. Uploads outputs to `videos/{org}/{project}/{asset}/hls/` and `poster.jpg` in Supabase Storage.
6. Updates the `cs_video_assets` row: `status='ready'`, `duration_s`, `retention_expires_at=now+30d`.
7. On failure, retries 2x with exponential backoff (30s / 2min per D-33); on final failure marks `status='failed'` with `last_error`.

## Target Platform

Fly.io (primary). The `Dockerfile` bundles ffmpeg on Debian Bookworm and runs a Hono HTTP server on port 8080.

## Endpoints

- `GET /health` -- 200 liveness check (Fly.io http_checks)
- `POST /transcode` -- accepts `{ asset_id, storage_path, org_id, project_id }` with `X-Worker-Secret` header. Returns 202 immediately; processes async.

## Layout

```
worker/
  src/
    server.ts          # Hono app -- POST /transcode, GET /health
    transcode.ts       # ffmpeg pipeline + retry + codec validation
    supabase.ts        # service-role Supabase client
    config.ts          # env config (fail-fast on missing vars)
  __tests__/
    transcode.smoke.test.ts   # real ffmpeg smoke test (skips if ffmpeg absent)
  Dockerfile
  fly.toml             # Fly.io deployment: shared-cpu-1x, 2GB RAM, always-on
  package.json
  tsconfig.json
  vitest.config.ts
```

## Commands

```bash
npm install          # install deps
npm run dev          # tsx live-reload against src/server.ts
npm run build        # tsc -> dist/
npm run test         # vitest --run
npm run start        # node dist/server.js (production)
```

## Secrets

Set via `fly secrets set KEY=value` (NOT committed):

- `WORKER_SHARED_SECRET` -- constant-time compared against X-Worker-Secret header
- `NEXT_PUBLIC_SUPABASE_URL` -- Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` -- bypasses RLS for storage reads/writes and row updates

## Deploy

```bash
cd worker
fly launch --no-deploy          # first time only
fly secrets set WORKER_SHARED_SECRET=<hex> NEXT_PUBLIC_SUPABASE_URL=<url> SUPABASE_SERVICE_ROLE_KEY=<key>
fly deploy
```

Then set the DB GUCs so the pg_net trigger can reach this worker:

```sql
ALTER DATABASE postgres SET app.ffmpeg_worker_url = 'https://constructionos-video-worker.fly.dev/transcode';
ALTER DATABASE postgres SET app.ffmpeg_worker_secret = '<same WORKER_SHARED_SECRET value>';
```

## Owner Plan

Scaffolded by `22-00-PLAN.md` (Wave 0). Filled in by `22-04-PLAN.md` (Wave 2).
