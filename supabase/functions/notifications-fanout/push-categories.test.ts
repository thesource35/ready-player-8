// Phase 30 D-21 a — strict category-gating coverage.
// Confirms the D-16 hard line: ONLY bid_deadline/safety_alert/assigned_task push.
// Run: deno test --allow-env --no-check supabase/functions/notifications-fanout/push-categories.test.ts

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { handle, PUSH_CATEGORIES, type ActivityEvent, type Deps } from './index.ts'

Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')

// Inline the minimal stub pattern from index.test.ts.
function makeSupabaseStub(opts: {
  members?: Array<{ user_id: string }>
  tokens?: Array<{ user_id: string; device_token: string }>
}) {
  const inserted: Record<string, unknown[]> = {}
  const supabase = {
    from(table: string) {
      const state: { match: Record<string, unknown>; data: unknown } = { match: {}, data: null }
      const builder: Record<string, (...args: unknown[]) => unknown> = {}
      builder.select = () => {
        if (table === 'cs_project_members') state.data = opts.members ?? []
        if (table === 'cs_device_tokens') state.data = opts.tokens ?? []
        return builder
      }
      builder.insert = (rows: unknown) => {
        inserted[table] = (inserted[table] ?? []).concat(rows as unknown[])
        return Promise.resolve({ error: null })
      }
      builder.delete = () => builder
      builder.eq = (col: unknown, val: unknown) => {
        state.match[col as string] = val
        return new Proxy(builder, {
          get(target, prop) {
            if (prop === 'then') {
              return (r: (v: unknown) => void) => r({ data: state.data, error: null })
            }
            return (target as Record<string, unknown>)[prop as string]
          },
        })
      }
      builder.in = (col: unknown, vals: unknown) => { state.match[col as string] = vals; return builder }
      return builder
    },
  }
  return { supabase, inserted }
}

function makeSendApnsStub() {
  const calls: Array<{ token: string; payload: unknown }> = []
  const sendApns = async (token: string, payload: unknown) => { calls.push({ token, payload }) }
  return { sendApns, calls }
}

function makeEvent(category: string): ActivityEvent {
  return {
    id: 'e-1', project_id: 'proj-1', entity_type: 'cs_rfis', entity_id: 'rfi-1',
    action: 'insert', category, actor_id: 'user-actor',
    payload: { name: 'Test' }, created_at: new Date().toISOString(),
  }
}

function makeReq(event: ActivityEvent): Request {
  return new Request('https://example.com/', {
    method: 'POST',
    headers: { 'authorization': 'Bearer test-service-role-key', 'content-type': 'application/json' },
    body: JSON.stringify({ type: 'INSERT', table: 'cs_activity_events', record: event, schema: 'public', old_record: null }),
  })
}

Deno.test('PUSH_CATEGORIES is exactly {bid_deadline, safety_alert, assigned_task}', () => {
  assertEquals(PUSH_CATEGORIES.size, 3)
  assert(PUSH_CATEGORIES.has('bid_deadline'))
  assert(PUSH_CATEGORIES.has('safety_alert'))
  assert(PUSH_CATEGORIES.has('assigned_task'))
  assert(!PUSH_CATEGORIES.has('generic'))
  assert(!PUSH_CATEGORIES.has('document'))
  assert(!PUSH_CATEGORIES.has('cert_renewal'))
})

for (const cat of ['bid_deadline', 'safety_alert', 'assigned_task']) {
  Deno.test(`category ${cat} triggers exactly one APNs call per recipient token`, async () => {
    const { supabase } = makeSupabaseStub({
      members: [{ user_id: 'user-a' }, { user_id: 'user-actor' }],
      tokens: [{ user_id: 'user-a', device_token: 'tok-a' }],
    })
    const { sendApns, calls } = makeSendApnsStub()
    const res = await handle(makeReq(makeEvent(cat)), { supabase: supabase as unknown as Deps['supabase'], sendApns })
    assertEquals(res.status, 200)
    assertEquals(calls.length, 1)
    assertEquals(calls[0].token, 'tok-a')
  })
}

for (const cat of ['generic', 'document', 'cert_renewal', 'unknown_new_category', 'bid_deadlin']) {
  Deno.test(`category ${cat} does NOT trigger APNs (D-16 hard line)`, async () => {
    const { supabase } = makeSupabaseStub({
      members: [{ user_id: 'user-a' }, { user_id: 'user-actor' }],
      tokens: [{ user_id: 'user-a', device_token: 'tok-a' }],
    })
    const { sendApns, calls } = makeSendApnsStub()
    await handle(makeReq(makeEvent(cat)), { supabase: supabase as unknown as Deps['supabase'], sendApns })
    assertEquals(calls.length, 0)
  })
}
