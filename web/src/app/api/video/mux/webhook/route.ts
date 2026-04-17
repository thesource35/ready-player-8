// Phase 22 — POST /api/video/mux/webhook
// Mux-driven source/asset state transitions. HMAC verify (D-32) → dedupe → handle event.
// D-27: 5-min disconnect grace — disconnected event only flips source to 'offline', does
// NOT close the live asset row. The cs_video_assets row is closed only when Mux fires
// 'video.live_stream.idle' (meaning the reconnect window has truly elapsed).
//
// Webhook handlers MUST return 2xx fast (<5s) to avoid Mux retry storms. On internal
// errors we log and still 200 so Mux doesn't retry forever — handler errors are captured
// to cs_video_webhook_events.processing_error for ops visibility.

import { NextResponse } from 'next/server'
import crypto from 'crypto'
import { createServiceRoleClient } from '@/lib/supabase/server'
import { verifyMuxSignature, recordWebhookEvent } from '@/lib/video/webhook-verify'
import { videoError, VideoErrorCode } from '@/lib/video/errors'
import { emitVideoEvent } from '@/lib/video/analytics'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function POST(req: Request) {
  const secret = process.env.MUX_WEBHOOK_SECRET
  if (!secret) {
    console.error('[video:webhook] MUX_WEBHOOK_SECRET not set')
    return NextResponse.json(
      videoError(VideoErrorCode.WebhookSignatureInvalid, 'Server misconfigured.', false),
      { status: 500 },
    )
  }

  const rawBody = await req.text() // MUST read raw body for HMAC
  const sigHeader = req.headers.get('mux-signature')
  if (!verifyMuxSignature(rawBody, sigHeader, secret)) {
    console.warn('[video:webhook] Signature verification FAILED', {
      sigHeader: sigHeader?.slice(0, 40),
    })
    return NextResponse.json(
      videoError(VideoErrorCode.WebhookSignatureInvalid, 'Webhook signature verification failed.', false),
      { status: 401 },
    )
  }

  let event: { id?: string; type?: string; data?: Record<string, unknown> }
  try {
    event = JSON.parse(rawBody)
  } catch {
    return NextResponse.json(
      videoError(VideoErrorCode.WebhookSignatureInvalid, 'Malformed payload.', false),
      { status: 400 },
    )
  }

  const eventId = event.id
  const eventType = event.type
  if (!eventId || !eventType) {
    return NextResponse.json(
      videoError(VideoErrorCode.WebhookSignatureInvalid, 'Missing id or type.', false),
      { status: 400 },
    )
  }

  let supabase
  try {
    supabase = createServiceRoleClient()
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[video:webhook] service role client init failed:', msg)
    return NextResponse.json(
      videoError(VideoErrorCode.WebhookSignatureInvalid, 'Server misconfigured.', false),
      { status: 500 },
    )
  }

  // D-32 dedupe — insert into cs_video_webhook_events with PK. Duplicate → 200 fast.
  const payloadHash = crypto.createHash('sha256').update(rawBody).digest('hex')
  try {
    const result = await recordWebhookEvent(supabase, {
      eventId,
      eventType,
      payloadHash,
    })
    if (result === 'duplicate') {
      return NextResponse.json({ ok: true, dedupe: 'hit' }, { status: 200 })
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[video:webhook] dedupe insert failed:', msg)
    // Still 200 to avoid retry storms; ops will investigate from logs.
    return NextResponse.json({ ok: true, dedupe: 'error' }, { status: 200 })
  }

  try {
    const data = (event.data ?? {}) as Record<string, unknown>
    switch (eventType) {
      case 'video.live_stream.active': {
        const liveInputId = data.id as string | undefined
        if (!liveInputId) break
        const { data: src } = await supabase
          .from('cs_video_sources')
          .select('id, org_id, project_id, created_by, mux_playback_id')
          .eq('mux_live_input_id', liveInputId)
          .maybeSingle()
        if (!src) {
          console.warn('[video:webhook] active for unknown live_input', liveInputId)
          break
        }
        await supabase
          .from('cs_video_sources')
          .update({ status: 'active', last_active_at: new Date().toISOString() })
          .eq('id', src.id)

        // If no open live asset row exists, create one. status='ready' = live-available.
        const { data: open } = await supabase
          .from('cs_video_assets')
          .select('id')
          .eq('source_id', src.id)
          .eq('kind', 'live')
          .is('ended_at', null)
          .maybeSingle()
        if (!open) {
          await supabase.from('cs_video_assets').insert({
            source_id: src.id,
            org_id: src.org_id,
            project_id: src.project_id,
            source_type: 'fixed_camera',
            kind: 'live',
            mux_playback_id: src.mux_playback_id,
            status: 'ready',
            started_at: new Date().toISOString(),
            retention_expires_at: null,
            portal_visible: false,
            created_by: src.created_by,
          })
        }
        // D-40 analytics: live_stream_started
        emitVideoEvent({
          event: 'live_stream_started',
          source_id: src.id,
          mux_live_input_id: liveInputId,
          project_id: src.project_id,
          org_id: src.org_id,
        })
        break
      }

      case 'video.live_stream.disconnected': {
        // D-27: do NOT close the asset row here. Just mark source offline during the grace window.
        const liveInputId = data.id as string | undefined
        if (!liveInputId) break
        await supabase
          .from('cs_video_sources')
          .update({ status: 'offline' })
          .eq('mux_live_input_id', liveInputId)
        break
      }

      case 'video.live_stream.idle': {
        // Mux's reconnect window elapsed without reconnect — session truly ended (past D-27 grace).
        const liveInputId = data.id as string | undefined
        if (!liveInputId) break
        const { data: src } = await supabase
          .from('cs_video_sources')
          .select('id')
          .eq('mux_live_input_id', liveInputId)
          .maybeSingle()
        if (!src) break

        // D-10: live assets retain for 24h past session close.
        const expires = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString()
        await supabase
          .from('cs_video_assets')
          .update({ ended_at: new Date().toISOString(), retention_expires_at: expires })
          .eq('source_id', src.id)
          .eq('kind', 'live')
          .is('ended_at', null)
        await supabase.from('cs_video_sources').update({ status: 'idle' }).eq('id', src.id)

        // D-40 analytics: live_stream_disconnected
        // Compute session_elapsed_s from the open live asset row's started_at to now.
        const { data: closedAsset } = await supabase
          .from('cs_video_assets')
          .select('started_at')
          .eq('source_id', src.id)
          .eq('kind', 'live')
          .order('started_at', { ascending: false })
          .limit(1)
          .maybeSingle()
        const sessionElapsedS = closedAsset?.started_at
          ? Math.round((Date.now() - new Date(closedAsset.started_at as string).getTime()) / 1000)
          : 0
        // Need project_id + org_id — re-fetch source with those fields
        const { data: srcFull } = await supabase
          .from('cs_video_sources')
          .select('project_id, org_id')
          .eq('id', src.id)
          .maybeSingle()
        if (srcFull) {
          emitVideoEvent({
            event: 'live_stream_disconnected',
            source_id: src.id,
            session_elapsed_s: sessionElapsedS,
            reason: 'idle',
            project_id: srcFull.project_id,
            org_id: srcFull.org_id,
          })
        }
        break
      }

      case 'video.asset.ready':
      case 'video.asset.created': {
        // Archive-asset events for a live session — wire mux_asset_id + duration onto
        // the live asset row so retention cron can delete the Mux archive later.
        const liveStreamId = data.live_stream_id as string | undefined
        if (!liveStreamId) break
        const { data: src } = await supabase
          .from('cs_video_sources')
          .select('id')
          .eq('mux_live_input_id', liveStreamId)
          .maybeSingle()
        if (!src) break
        await supabase
          .from('cs_video_assets')
          .update({
            mux_asset_id: data.id as string,
            duration_s: (data.duration as number | undefined) ?? null,
          })
          .eq('source_id', src.id)
          .eq('kind', 'live')
          .is('mux_asset_id', null)
          .is('ended_at', null)
        break
      }

      default:
        // Unknown event type — log but don't error (Mux may add new events).
        console.info('[video:webhook] unhandled type:', eventType)
    }

    // Mark processed.
    await supabase
      .from('cs_video_webhook_events')
      .update({ processed_at: new Date().toISOString() })
      .eq('event_id', eventId)
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'unknown'
    console.error('[video:webhook] handler error:', msg)
    await supabase
      .from('cs_video_webhook_events')
      .update({ processing_error: msg })
      .eq('event_id', eventId)
    // Return 200 anyway — Mux retries on 5xx would loop. Ops reads processing_error for repair.
  }

  return NextResponse.json({ ok: true }, { status: 200 })
}
