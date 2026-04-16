// Phase 22 ffmpeg worker — HTTP server.
// Endpoints:
//   GET  /health      — 200 liveness check for Fly.io http_checks.
//   POST /transcode   — accepts job descriptor from the DB pg_net trigger (22-01) or
//                        manual requeue (22-10 requeue_stuck_uploads function).
//                        Requires X-Worker-Secret header (constant-time compare).
//                        Returns 202 immediately; actual transcode runs async.
//
// Single-machine, single-process serialization: setImmediate() hands the job to the
// event loop. ffmpeg is the concurrency bottleneck anyway; scaling beyond one active
// transcode at a time requires horizontal Fly.io scale (out of scope for v1).

import { Hono } from 'hono'
import { serve } from '@hono/node-server'
import { timingSafeEqual } from 'node:crypto'
import { config } from './config.js'
import { transcodeAsset, type TranscodeJob } from './transcode.js'

const app = new Hono()

app.get('/health', (c) => c.json({ ok: true }))

app.post('/transcode', async (c) => {
  // Constant-time secret compare (D-22-04-01 mitigation).
  const provided = c.req.header('x-worker-secret') ?? ''
  const expected = config.workerSecret
  const providedBuf = Buffer.from(provided)
  const expectedBuf = Buffer.from(expected)
  if (
    providedBuf.length !== expectedBuf.length ||
    !timingSafeEqual(providedBuf, expectedBuf)
  ) {
    return c.json({ error: 'Unauthorized' }, 401)
  }

  const body = (await c.req.json().catch(() => null)) as Partial<TranscodeJob> | null
  if (
    !body ||
    typeof body.asset_id !== 'string' ||
    typeof body.storage_path !== 'string' ||
    typeof body.org_id !== 'string' ||
    typeof body.project_id !== 'string'
  ) {
    return c.json({ error: 'Missing fields: asset_id, storage_path, org_id, project_id required' }, 400)
  }

  // Fire-and-forget: return 202 immediately so the DB trigger completes fast;
  // the worker processes the job in background. Any top-level throw is swallowed
  // by transcodeAsset() itself (marks row failed); this catch is a belt-and-braces log.
  const job: TranscodeJob = {
    asset_id: body.asset_id,
    storage_path: body.storage_path,
    org_id: body.org_id,
    project_id: body.project_id,
  }
  setImmediate(() => {
    transcodeAsset(job).catch((err) =>
      console.error('[worker] transcodeAsset unhandled:', err instanceof Error ? err.message : err)
    )
  })

  return c.json({ accepted: true, asset_id: body.asset_id }, 202)
})

// Only start listening when invoked as the main module (not when imported in tests).
const invokedDirectly = process.argv[1]?.endsWith('/server.js') || process.argv[1]?.endsWith('/server.ts')
if (invokedDirectly) {
  serve({ fetch: app.fetch, port: config.port })
  console.log(`[worker] listening on :${config.port}`)
}

export { app }
