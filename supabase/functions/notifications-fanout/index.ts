// Phase 14 — notifications-fanout Edge Function
// Triggered by Supabase Database Webhook on cs_activity_events INSERT.
// Resolves recipients from cs_project_members, bulk-inserts cs_notifications,
// and sends APNs push ONLY for NOTIF-05 categories (D-16 hard line).
//
// Decisions: D-03 (single fanout path), D-16 (push gating), T-14-06/07 (auth verify)

import { createClient, SupabaseClient } from 'npm:@supabase/supabase-js@2'
import { sendApns as realSendApns, ApnsError } from './apns.ts'

export type ActivityEvent = {
  id: string
  project_id: string | null
  entity_type: string
  entity_id: string | null
  action: string
  category: 'bid_deadline' | 'safety_alert' | 'assigned_task' | 'generic' | string
  actor_id: string | null
  payload: Record<string, unknown>
  created_at: string
}

export type WebhookBody = {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: ActivityEvent
  schema: string
  old_record: ActivityEvent | null
}

export type Deps = {
  supabase: SupabaseClient
  sendApns: typeof realSendApns
}

// Hard line: only these categories produce APNs pushes (D-16)
export const PUSH_CATEGORIES = new Set(['bid_deadline', 'safety_alert', 'assigned_task'])

export function titleFor(event: ActivityEvent): string {
  switch (event.category) {
    case 'bid_deadline':
      return 'Bid deadline approaching'
    case 'safety_alert':
      return 'Safety alert'
    case 'assigned_task':
      return 'New assignment'
    default:
      return 'Activity'
  }
}

export function bodyFor(event: ActivityEvent): string {
  const entity = event.entity_type.replace(/^cs_/, '')
  const payload = event.payload ?? {}
  const name = (payload['name'] ?? payload['title'] ?? payload['description']) as string | undefined
  const prefix = `${entity} ${event.action}`
  return name ? `${prefix}: ${name}` : prefix
}

export async function handle(req: Request, deps: Deps): Promise<Response> {
  // T-14-06/07: verify caller carries the service-role auth header.
  const auth = req.headers.get('authorization') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!serviceKey || !auth.includes(serviceKey)) {
    return new Response('unauthorized', { status: 401 })
  }

  let body: WebhookBody
  try {
    body = (await req.json()) as WebhookBody
  } catch {
    return new Response('invalid json', { status: 400 })
  }

  if (body.type !== 'INSERT' || body.table !== 'cs_activity_events' || !body.record) {
    return new Response('ignored', { status: 200 })
  }

  const event = body.record
  const { supabase, sendApns } = deps

  // 1. Resolve recipients (project members minus the actor).
  //    If project_id is null, broadcast is out of scope — skip.
  if (!event.project_id) {
    return new Response(JSON.stringify({ skipped: 'no project_id' }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    })
  }

  const { data: members, error: memErr } = await supabase
    .from('cs_project_members')
    .select('user_id')
    .eq('project_id', event.project_id)

  if (memErr) {
    console.error('[notifications-fanout] member lookup failed:', memErr.message)
    return new Response(memErr.message, { status: 500 })
  }

  const recipients = (members ?? [])
    .map((m: { user_id: string }) => m.user_id)
    .filter((uid: string) => uid && uid !== event.actor_id)

  if (recipients.length === 0) {
    return new Response(JSON.stringify({ recipients: 0 }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    })
  }

  // 2. Bulk insert cs_notifications (single round-trip)
  const title = titleFor(event)
  const bodyText = bodyFor(event)
  const rows = recipients.map((user_id: string) => ({
    user_id,
    event_id: event.id,
    project_id: event.project_id,
    category: event.category,
    title,
    body: bodyText,
    entity_type: event.entity_type,
    entity_id: event.entity_id,
  }))

  const { error: insErr } = await supabase.from('cs_notifications').insert(rows)
  if (insErr) {
    console.error('[notifications-fanout] notification insert failed:', insErr.message)
    return new Response(insErr.message, { status: 500 })
  }

  // 3. Push gating — D-16 hard line
  if (!PUSH_CATEGORIES.has(event.category)) {
    return new Response(JSON.stringify({ recipients: recipients.length, pushed: 0 }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    })
  }

  // 4. Fetch iOS device tokens for recipients
  const { data: tokens, error: tokErr } = await supabase
    .from('cs_device_tokens')
    .select('user_id, device_token')
    .in('user_id', recipients)
    .eq('platform', 'ios')

  if (tokErr) {
    console.error('[notifications-fanout] device token lookup failed:', tokErr.message)
    // Notifications already inserted — return 200 so webhook doesn't retry
    return new Response(JSON.stringify({ recipients: recipients.length, pushed: 0, tokenError: true }), {
      status: 200,
      headers: { 'content-type': 'application/json' },
    })
  }

  // 5. Send pushes in parallel; tolerate per-device failures
  let pushed = 0
  await Promise.allSettled(
    (tokens ?? []).map(async (t: { user_id: string; device_token: string }) => {
      try {
        await sendApns(t.device_token, {
          aps: {
            alert: { title, body: bodyText },
            sound: 'default',
            badge: 1,
            'thread-id': event.project_id ?? 'global',
          },
          event_id: event.id,
          project_id: event.project_id,
          category: event.category,
        })
        pushed++
      } catch (err) {
        const apnsErr = err as ApnsError
        // 410 Unregistered / 400 BadDeviceToken → delete the dead token
        if (
          apnsErr?.status === 410 ||
          apnsErr?.reason === 'Unregistered' ||
          apnsErr?.reason === 'BadDeviceToken'
        ) {
          await supabase
            .from('cs_device_tokens')
            .delete()
            .eq('user_id', t.user_id)
            .eq('device_token', t.device_token)
          console.warn(
            `[notifications-fanout] deleted stale token for ${t.user_id} (status=${apnsErr.status} reason=${apnsErr.reason})`,
          )
        } else {
          console.error('[notifications-fanout] APNs send failed:', apnsErr?.message ?? err)
        }
      }
    }),
  )

  return new Response(
    JSON.stringify({ recipients: recipients.length, pushed }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  )
}

// Default deps wiring — only used at runtime, tests pass their own stubs.
if (import.meta.main) {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
  Deno.serve((req) => handle(req, { supabase, sendApns: realSendApns }))
}
