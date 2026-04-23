// Phase 30 D-21 b — cs_device_tokens query shape + error tolerance.
// Run: deno test --allow-env --no-check supabase/functions/notifications-fanout/device-token-lookup.test.ts

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { handle, type ActivityEvent, type Deps } from './index.ts'

Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')

type QueryCall = { table: string; op: string; col?: string; val?: unknown }

function makeTrackedSupabaseStub(opts: {
  members?: Array<{ user_id: string }>
  tokens?: Array<{ user_id: string; device_token: string }>
  tokensError?: string
}) {
  const calls: QueryCall[] = []
  const inserted: Record<string, unknown[]> = {}
  const supabase = {
    from(table: string) {
      const state: { data: unknown; error: { message: string } | null } = { data: null, error: null }
      if (table === 'cs_device_tokens') {
        state.data = opts.tokens ?? []
        if (opts.tokensError) state.error = { message: opts.tokensError }
      }
      if (table === 'cs_project_members') state.data = opts.members ?? []

      const builder: Record<string, (...args: unknown[]) => unknown> = {}
      builder.select = (...a: unknown[]) => { calls.push({ table, op: 'select', col: String(a[0] ?? '*') }); return builder }
      builder.insert = (rows: unknown) => {
        calls.push({ table, op: 'insert' })
        inserted[table] = (inserted[table] ?? []).concat(rows as unknown[])
        return Promise.resolve({ error: null })
      }
      builder.delete = () => { calls.push({ table, op: 'delete' }); return builder }
      builder.in = (col: unknown, vals: unknown) => {
        calls.push({ table, op: 'in', col: col as string, val: vals })
        return builder
      }
      builder.eq = (col: unknown, val: unknown) => {
        calls.push({ table, op: 'eq', col: col as string, val })
        return new Proxy(builder, {
          get(target, prop) {
            if (prop === 'then') {
              return (r: (v: unknown) => void) => r({ data: state.data, error: state.error })
            }
            return (target as Record<string, unknown>)[prop as string]
          },
        })
      }
      return builder
    },
  }
  return { supabase, calls, inserted }
}

function makeEvent(): ActivityEvent {
  return {
    id: 'e-1', project_id: 'proj-1', entity_type: 'cs_rfis', entity_id: 'rfi-1',
    action: 'insert', category: 'safety_alert', actor_id: 'user-actor',
    payload: {}, created_at: new Date().toISOString(),
  }
}

function makeReq(event: ActivityEvent): Request {
  return new Request('https://example.com/', {
    method: 'POST',
    headers: { 'authorization': 'Bearer test-service-role-key', 'content-type': 'application/json' },
    body: JSON.stringify({ type: 'INSERT', table: 'cs_activity_events', record: event, schema: 'public', old_record: null }),
  })
}

function makeSendApnsStub() {
  const c: Array<{ token: string; payload: unknown }> = []
  return { sendApns: async (t: string, p: unknown) => { c.push({ token: t, payload: p }) }, calls: c }
}

Deno.test('device-token lookup uses in(user_id, recipients) + eq(platform, ios)', async () => {
  const { supabase, calls } = makeTrackedSupabaseStub({
    members: [{ user_id: 'r1' }, { user_id: 'r2' }, { user_id: 'r3' }, { user_id: 'user-actor' }],
    tokens: [{ user_id: 'r1', device_token: 'tok-1' }],
  })
  const { sendApns } = makeSendApnsStub()
  await handle(makeReq(makeEvent()), { supabase: supabase as unknown as Deps['supabase'], sendApns })

  const tokenCalls = calls.filter((c) => c.table === 'cs_device_tokens')
  assert(tokenCalls.some((c) => c.op === 'in' && c.col === 'user_id'))
  assert(tokenCalls.some((c) => c.op === 'eq' && c.col === 'platform' && c.val === 'ios'))
})

Deno.test('device-token lookup error returns 200 with tokenError sentinel — no webhook retry', async () => {
  const { supabase } = makeTrackedSupabaseStub({
    members: [{ user_id: 'r1' }, { user_id: 'user-actor' }],
    tokensError: 'Simulated RLS failure',
  })
  const { sendApns } = makeSendApnsStub()
  const res = await handle(makeReq(makeEvent()), { supabase: supabase as unknown as Deps['supabase'], sendApns })
  assertEquals(res.status, 200)
  const body = await res.json()
  assertEquals(body.tokenError, true)
})

Deno.test('zero recipients short-circuits before cs_device_tokens lookup', async () => {
  const { supabase, calls } = makeTrackedSupabaseStub({
    members: [{ user_id: 'user-actor' }],  // only the actor, who is filtered out
  })
  const { sendApns } = makeSendApnsStub()
  await handle(makeReq(makeEvent()), { supabase: supabase as unknown as Deps['supabase'], sendApns })

  const tokenCalls = calls.filter((c) => c.table === 'cs_device_tokens')
  assertEquals(tokenCalls.length, 0)
})
