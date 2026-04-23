// Phase 30 D-21 c — APNs payload shape invariants.
// Asserts: aps.alert.title/body, aps.badge, aps.sound, aps['thread-id'],
// aps['category'] (cert-only), top-level event_id/project_id/category.
// Run: deno test --allow-env --no-check supabase/functions/notifications-fanout/apns-payload-shape.test.ts

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { handle, type ActivityEvent, type Deps } from './index.ts'

Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')

function makeStub(tokens: Array<{ user_id: string; device_token: string }>) {
  const state = (t: string) => {
    if (t === 'cs_project_members') return [{ user_id: 'user-a' }, { user_id: 'user-actor' }]
    if (t === 'cs_device_tokens') return tokens
    return []
  }
  const supabase = {
    from(table: string) {
      const b: Record<string, (...a: unknown[]) => unknown> = {}
      b.select = () => b
      b.insert = () => Promise.resolve({ error: null })
      b.delete = () => b
      b.in = () => b
      b.eq = () => new Proxy(b, {
        get(t, p) {
          if (p === 'then') return (r: (v: unknown) => void) => r({ data: state(table), error: null })
          return (t as Record<string, unknown>)[p as string]
        },
      })
      return b
    },
  }
  return supabase
}

type ApnsCall = { token: string; payload: Record<string, unknown> }

function captureApns() {
  const calls: ApnsCall[] = []
  return { sendApns: async (token: string, payload: unknown) => { calls.push({ token, payload: payload as Record<string, unknown> }) }, calls }
}

function makeReq(overrides: Partial<ActivityEvent> = {}): Request {
  const event: ActivityEvent = {
    id: 'evt-42', project_id: 'proj-1', entity_type: 'cs_rfis', entity_id: 'rfi-9',
    action: 'insert', category: 'assigned_task', actor_id: 'user-actor',
    payload: { name: 'Plumbing rough-in' }, created_at: new Date().toISOString(),
    ...overrides,
  }
  return new Request('https://example.com/', {
    method: 'POST',
    headers: { 'authorization': 'Bearer test-service-role-key', 'content-type': 'application/json' },
    body: JSON.stringify({ type: 'INSERT', table: 'cs_activity_events', record: event, schema: 'public', old_record: null }),
  })
}

Deno.test('aps.alert has title + body; badge=1; sound=default; thread-id=project_id', async () => {
  const supabase = makeStub([{ user_id: 'user-a', device_token: 'tok-a' }])
  const { sendApns, calls } = captureApns()
  await handle(makeReq(), { supabase: supabase as unknown as Deps['supabase'], sendApns })
  assertEquals(calls.length, 1)
  const aps = calls[0].payload.aps as Record<string, unknown>
  const alert = aps.alert as Record<string, unknown>
  assertEquals(typeof alert.title, 'string')
  assert((alert.title as string).length > 0)
  assertEquals(typeof alert.body, 'string')
  assert((alert.body as string).length > 0)
  assertEquals(aps.badge, 1)
  assertEquals(aps.sound, 'default')
  assertEquals(aps['thread-id'], 'proj-1')
})

Deno.test('top-level event_id + project_id + category mirror the source event', async () => {
  const supabase = makeStub([{ user_id: 'user-a', device_token: 'tok-a' }])
  const { sendApns, calls } = captureApns()
  await handle(makeReq({ id: 'evt-777', project_id: 'proj-XYZ', category: 'bid_deadline' }), { supabase: supabase as unknown as Deps['supabase'], sendApns })
  const p = calls[0].payload
  assertEquals(p.event_id, 'evt-777')
  assertEquals(p.project_id, 'proj-XYZ')
  assertEquals(p.category, 'bid_deadline')
})

Deno.test('non-cert events do NOT include aps.category', async () => {
  const supabase = makeStub([{ user_id: 'user-a', device_token: 'tok-a' }])
  const { sendApns, calls } = captureApns()
  await handle(makeReq({ category: 'safety_alert' }), { supabase: supabase as unknown as Deps['supabase'], sendApns })
  const aps = calls[0].payload.aps as Record<string, unknown>
  assertEquals(aps.category, undefined)
})
