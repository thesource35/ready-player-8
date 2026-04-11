// Phase 14 — notifications-fanout handle() unit tests
// Run: deno test --allow-env supabase/functions/notifications-fanout/index.test.ts

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { handle, PUSH_CATEGORIES, type ActivityEvent, type Deps } from './index.ts'

Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')

function makeEvent(overrides: Partial<ActivityEvent> = {}): ActivityEvent {
  return {
    id: 'evt-1',
    project_id: 'proj-1',
    entity_type: 'cs_rfis',
    entity_id: 'rfi-1',
    action: 'insert',
    category: 'generic',
    actor_id: 'user-actor',
    payload: { name: 'Test RFI' },
    created_at: new Date().toISOString(),
    ...overrides,
  }
}

function makeRequest(event: ActivityEvent): Request {
  return new Request('https://example.com/', {
    method: 'POST',
    headers: {
      'authorization': 'Bearer test-service-role-key',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      type: 'INSERT',
      table: 'cs_activity_events',
      record: event,
      schema: 'public',
      old_record: null,
    }),
  })
}

// Minimal chainable stub for the Supabase PostgREST builder
type Call = { op: string; args: unknown[] }

function makeSupabaseStub(opts: {
  members?: Array<{ user_id: string }>
  tokens?: Array<{ user_id: string; device_token: string }>
  insertError?: string
}) {
  const calls: Record<string, Call[]> = {}
  const inserted: Record<string, unknown[]> = {}
  const deleted: Array<{ table: string; match: Record<string, unknown> }> = []

  const supabase = {
    from(table: string) {
      calls[table] = calls[table] ?? []
      const state: { match: Record<string, unknown>; data: unknown } = {
        match: {},
        data: null,
      }

      const builder: Record<string, (...args: unknown[]) => unknown> = {}

      builder.select = (..._a: unknown[]) => {
        calls[table].push({ op: 'select', args: _a })
        if (table === 'cs_project_members') state.data = opts.members ?? []
        if (table === 'cs_device_tokens') state.data = opts.tokens ?? []
        return builder
      }
      builder.insert = (rows: unknown) => {
        calls[table].push({ op: 'insert', args: [rows] })
        inserted[table] = (inserted[table] ?? []).concat(rows as unknown[])
        if (opts.insertError) {
          return Promise.resolve({ error: { message: opts.insertError } })
        }
        return Promise.resolve({ error: null })
      }
      builder.delete = () => {
        calls[table].push({ op: 'delete', args: [] })
        return builder
      }
      builder.eq = (col: unknown, val: unknown) => {
        state.match[col as string] = val
        // For delete chain, record on final .eq in promise resolution below
        const p: Promise<{ error: null }> & Record<string, unknown> = Promise.resolve({
          error: null,
        }) as Promise<{ error: null }> & Record<string, unknown>
        // Return builder so chaining continues
        return new Proxy(builder, {
          get(target, prop) {
            if (prop === 'then') {
              // Terminal await on a select chain → resolve with data
              if (calls[table].some((c) => c.op === 'select')) {
                deleted.push({ table, match: { ...state.match } })
                return (resolve: (v: unknown) => void) =>
                  resolve({ data: state.data, error: null })
              }
              if (calls[table].some((c) => c.op === 'delete')) {
                deleted.push({ table, match: { ...state.match } })
                return (resolve: (v: unknown) => void) =>
                  resolve({ error: null })
              }
            }
            return (target as Record<string, unknown>)[prop as string]
          },
        })
      }
      builder.in = (col: unknown, vals: unknown) => {
        state.match[col as string] = vals
        return builder
      }
      return builder
    },
  }

  return { supabase, calls, inserted, deleted }
}

function makeSendApnsStub() {
  const calls: Array<{ token: string; payload: unknown }> = []
  let failWith: { status: number; reason: string } | null = null
  const sendApns = async (token: string, payload: unknown) => {
    calls.push({ token, payload })
    if (failWith) {
      const e = new Error(`APNs ${failWith.status}`) as Error & { status: number; reason: string }
      e.status = failWith.status
      e.reason = failWith.reason
      throw e
    }
  }
  return {
    sendApns,
    calls,
    failNext(status: number, reason: string) {
      failWith = { status, reason }
    },
  }
}

Deno.test('rejects requests without service-role auth', async () => {
  const { supabase } = makeSupabaseStub({ members: [] })
  const { sendApns } = makeSendApnsStub()
  const req = new Request('https://example.com/', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ type: 'INSERT', table: 'cs_activity_events', record: makeEvent() }),
  })
  const res = await handle(req, { supabase: supabase as unknown as Deps['supabase'], sendApns })
  assertEquals(res.status, 401)
})

Deno.test('skips events with no project_id', async () => {
  const { supabase } = makeSupabaseStub({})
  const { sendApns, calls } = makeSendApnsStub()
  const res = await handle(
    makeRequest(makeEvent({ project_id: null })),
    { supabase: supabase as unknown as Deps['supabase'], sendApns },
  )
  assertEquals(res.status, 200)
  assertEquals(calls.length, 0)
})

Deno.test('generic category does NOT trigger APNs (D-16)', async () => {
  const { supabase, inserted } = makeSupabaseStub({
    members: [{ user_id: 'user-a' }, { user_id: 'user-b' }, { user_id: 'user-actor' }],
    tokens: [{ user_id: 'user-a', device_token: 'tok-a' }],
  })
  const { sendApns, calls } = makeSendApnsStub()

  const res = await handle(
    makeRequest(makeEvent({ category: 'generic' })),
    { supabase: supabase as unknown as Deps['supabase'], sendApns },
  )

  assertEquals(res.status, 200)
  // Two non-actor recipients → 2 notification rows inserted
  assertEquals((inserted['cs_notifications'] ?? []).length, 2)
  // generic category is NOT in PUSH_CATEGORIES → zero APNs calls
  assertEquals(calls.length, 0)
})

Deno.test('safety_alert category triggers APNs for recipients with tokens', async () => {
  const { supabase, inserted } = makeSupabaseStub({
    members: [{ user_id: 'user-a' }, { user_id: 'user-b' }, { user_id: 'user-actor' }],
    tokens: [
      { user_id: 'user-a', device_token: 'tok-a' },
      { user_id: 'user-b', device_token: 'tok-b' },
    ],
  })
  const { sendApns, calls } = makeSendApnsStub()

  const res = await handle(
    makeRequest(makeEvent({ category: 'safety_alert' })),
    { supabase: supabase as unknown as Deps['supabase'], sendApns },
  )

  assertEquals(res.status, 200)
  assertEquals((inserted['cs_notifications'] ?? []).length, 2)
  assertEquals(calls.length, 2)
  assert(calls.every((c) => c.token === 'tok-a' || c.token === 'tok-b'))
})

Deno.test('actor_id is excluded from recipients', async () => {
  const { supabase, inserted } = makeSupabaseStub({
    members: [{ user_id: 'user-a' }, { user_id: 'user-actor' }],
  })
  const { sendApns } = makeSendApnsStub()

  await handle(
    makeRequest(makeEvent({ category: 'assigned_task', actor_id: 'user-actor' })),
    { supabase: supabase as unknown as Deps['supabase'], sendApns },
  )

  const rows = (inserted['cs_notifications'] ?? []) as Array<{ user_id: string }>
  assertEquals(rows.length, 1)
  assertEquals(rows[0].user_id, 'user-a')
})

Deno.test('PUSH_CATEGORIES exports the D-16 hard-line set', () => {
  assertEquals(PUSH_CATEGORIES.size, 3)
  assert(PUSH_CATEGORIES.has('bid_deadline'))
  assert(PUSH_CATEGORIES.has('safety_alert'))
  assert(PUSH_CATEGORIES.has('assigned_task'))
  assert(!PUSH_CATEGORIES.has('generic'))
})
