// Phase 30 D-21 d — stale-token prune + redaction invariant.
// Run: deno test --allow-env --no-check supabase/functions/notifications-fanout/bad-device-token.test.ts

import { assertEquals, assert } from 'https://deno.land/std@0.224.0/assert/mod.ts'
import { handle, type ActivityEvent, type Deps } from './index.ts'

Deno.env.set('SUPABASE_SERVICE_ROLE_KEY', 'test-service-role-key')

function makeStub(tokens: Array<{ user_id: string; device_token: string }>) {
  const deleted: Array<{ user_id?: string; device_token?: string }> = []
  const state = (t: string) => {
    if (t === 'cs_project_members') return [{ user_id: 'user-a' }, { user_id: 'user-actor' }]
    if (t === 'cs_device_tokens') return tokens
    return []
  }
  const supabase = {
    from(table: string) {
      const match: Record<string, unknown> = {}
      const isDelete: { on: boolean } = { on: false }
      const b: Record<string, (...a: unknown[]) => unknown> = {}
      b.select = () => b
      b.insert = () => Promise.resolve({ error: null })
      b.delete = () => { isDelete.on = true; return b }
      b.in = () => b
      b.eq = (col: unknown, val: unknown) => {
        match[col as string] = val
        return new Proxy(b, {
          get(t, p) {
            if (p === 'then') {
              if (isDelete.on && table === 'cs_device_tokens') {
                deleted.push({ user_id: match.user_id as string, device_token: match.device_token as string })
              }
              return (r: (v: unknown) => void) => r({ data: state(table), error: null })
            }
            return (t as Record<string, unknown>)[p as string]
          },
        })
      }
      return b
    },
  }
  return { supabase, deleted }
}

function makeReq(): Request {
  const event: ActivityEvent = {
    id: 'e1', project_id: 'p1', entity_type: 'cs_rfis', entity_id: 'r1',
    action: 'insert', category: 'safety_alert', actor_id: 'user-actor',
    payload: {}, created_at: new Date().toISOString(),
  }
  return new Request('https://example.com/', {
    method: 'POST',
    headers: { 'authorization': 'Bearer test-service-role-key', 'content-type': 'application/json' },
    body: JSON.stringify({ type: 'INSERT', table: 'cs_activity_events', record: event, schema: 'public', old_record: null }),
  })
}

function failingSendApns(status: number, reason: string) {
  return async (_token: string, _payload: unknown) => {
    const e = new Error(`APNs ${status}`) as Error & { status: number; reason: string }
    e.status = status
    e.reason = reason
    throw e
  }
}

function captureConsole() {
  const logs: string[] = []
  const warn = console.warn
  const error = console.error
  console.warn = (...a: unknown[]) => { logs.push(a.map(String).join(' ')) }
  console.error = (...a: unknown[]) => { logs.push(a.map(String).join(' ')) }
  return {
    logs,
    restore: () => { console.warn = warn; console.error = error },
  }
}

Deno.test('410 Unregistered → stale token pruned from cs_device_tokens', async () => {
  const { supabase, deleted } = makeStub([{ user_id: 'user-a', device_token: 'tok-sensitive-AAA' }])
  const cc = captureConsole()
  try {
    const res = await handle(makeReq(), {
      supabase: supabase as unknown as Deps['supabase'],
      sendApns: failingSendApns(410, 'Unregistered'),
    })
    assertEquals(res.status, 200)
    assertEquals(deleted.length, 1)
    assertEquals(deleted[0].user_id, 'user-a')
    assertEquals(deleted[0].device_token, 'tok-sensitive-AAA')
    // Redaction invariant: console output MUST NOT contain the token string.
    assert(cc.logs.every((l) => !l.includes('tok-sensitive-AAA')), `token leaked in logs: ${cc.logs.join(' | ')}`)
  } finally { cc.restore() }
})

Deno.test('400 BadDeviceToken → stale token pruned', async () => {
  const { supabase, deleted } = makeStub([{ user_id: 'user-a', device_token: 'tok-sensitive-BBB' }])
  const cc = captureConsole()
  try {
    const res = await handle(makeReq(), {
      supabase: supabase as unknown as Deps['supabase'],
      sendApns: failingSendApns(400, 'BadDeviceToken'),
    })
    assertEquals(res.status, 200)
    assertEquals(deleted.length, 1)
    assert(cc.logs.every((l) => !l.includes('tok-sensitive-BBB')))
  } finally { cc.restore() }
})

Deno.test('500 InternalServerError → token NOT pruned (non-stale-token failure mode)', async () => {
  const { supabase, deleted } = makeStub([{ user_id: 'user-a', device_token: 'tok-keep-CCC' }])
  const cc = captureConsole()
  try {
    const res = await handle(makeReq(), {
      supabase: supabase as unknown as Deps['supabase'],
      sendApns: failingSendApns(500, 'InternalServerError'),
    })
    assertEquals(res.status, 200)
    assertEquals(deleted.length, 0)
    assert(cc.logs.every((l) => !l.includes('tok-keep-CCC')))
  } finally { cc.restore() }
})
