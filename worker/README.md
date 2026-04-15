# ConstructionOS Video Transcode Worker

Standalone ffmpeg transcode service for Phase 22 (Live Site Video — per-project HLS camera feeds).

## Role

This worker converts user-uploaded clips into HLS manifests ready for streaming via the web portal and iOS app. It runs outside the Vercel serverless runtime because ffmpeg transcoding exceeds function limits (memory, CPU time, disk).

## Flow

1. Receives `POST /transcode` from a Supabase database webhook when a new row lands in `cs_video_assets` with `source_type='upload'` and `status='pending'`.
2. Downloads the raw file (`raw.{ext}`) from Supabase Storage using the service-role key.
3. Runs `ffmpeg` to produce:
   - HLS manifest (`index.m3u8`) at 720p and 1080p rungs
   - Segmented `.ts` files (~6s each)
   - `poster.jpg` thumbnail from the first frame
4. Uploads outputs to the matching `hls/` and `posters/` prefixes in Supabase Storage.
5. Updates the `cs_video_assets` row: `status='ready'`, `duration`, `playback_manifest_path`, `poster_path`.
6. Marks `status='failed'` with an error message if any stage throws.

## Target Platform

Fly.io (primary). See Wave 2 plan `22-04-PLAN.md` for deploy configuration. The `Dockerfile` bundles ffmpeg on Debian Bookworm and runs a Hono HTTP server on port 8080.

## Layout (filled in by Wave 2)

```
worker/
  src/
    server.ts          # Hono app — POST /transcode, GET /healthz
    transcode.ts       # ffmpeg pipeline
    supabase.ts        # storage upload/download helpers
  __tests__/
    transcode.smoke.test.ts   # created here in 22-00
  Dockerfile
  package.json
  tsconfig.json
  vitest.config.ts
```

## Commands

```bash
npm install          # install deps (Wave 2 executor runs this — pinned here)
npm run dev          # tsx live-reload against src/server.ts
npm run build        # tsc → dist/
npm run test         # vitest --run
npm run start        # node dist/server.js (production)
```

## Secrets

Set in Fly.io (NOT committed):

- `SUPABASE_URL` — project URL
- `SUPABASE_SERVICE_ROLE_KEY` — bypasses RLS for storage reads/writes and `cs_video_assets` updates
- `TRANSCODE_SHARED_SECRET` — HMAC secret used to authenticate Supabase webhook → worker calls

## Owner Plan

Scaffolded by `.planning/phases/22-live-site-video-per-project-hls-camera-feeds-tied-to-project/22-00-PLAN.md` (Wave 0). Filled in by `22-04-PLAN.md` (Wave 2).
