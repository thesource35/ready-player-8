// Phase 14 — notifications-schedule Edge Function
// Invoked nightly by pg_cron. Scans cs_contracts.bid_deadline and inserts
// cs_activity_events rows (category='bid_deadline'), which flow through the
// same Database Webhook → notifications-fanout path as real-time events (D-17).
//
// De-dupe guard: skips insertion if an event with the same entity_id + category
// + days_out was already created in the last 20 hours.

import { createClient } from 'npm:@supabase/supabase-js@2'

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
)

const WINDOWS = [
  { days: 0, label: 'today' },
  { days: 1, label: 'in 1 day' },
  { days: 3, label: 'in 3 days' },
]

Deno.serve(async (req) => {
  // Verify caller carries the service-role key (pg_cron or admin)
  const auth = req.headers.get('authorization') ?? ''
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  if (!serviceKey || !auth.includes(serviceKey)) {
    return new Response('unauthorized', { status: 401 })
  }

  let inserted = 0
  let skipped = 0
  const errors: string[] = []

  for (const w of WINDOWS) {
    const target = new Date()
    target.setUTCDate(target.getUTCDate() + w.days)
    const targetDate = target.toISOString().slice(0, 10) // YYYY-MM-DD

    // bid_deadline is stored as text (see SupabaseService.swift DTO comments) —
    // equality against YYYY-MM-DD works for ISO-date strings.
    const { data: contracts, error: cErr } = await supabase
      .from('cs_contracts')
      .select('id, project_id, name, bid_deadline')
      .eq('bid_deadline', targetDate)

    if (cErr) {
      errors.push(`contracts[${w.label}]: ${cErr.message}`)
      continue
    }

    for (const c of contracts ?? []) {
      // De-dupe within a 20-hour window on entity_id + category + days_out payload
      const since = new Date(Date.now() - 20 * 3600 * 1000).toISOString()
      const { count } = await supabase
        .from('cs_activity_events')
        .select('id', { count: 'exact', head: true })
        .eq('entity_id', c.id)
        .eq('category', 'bid_deadline')
        .gte('created_at', since)
        .contains('payload', { days_out: w.days })

      if ((count ?? 0) > 0) {
        skipped++
        continue
      }

      const { error: insErr } = await supabase.from('cs_activity_events').insert({
        project_id: c.project_id,
        entity_type: 'cs_contracts',
        entity_id: c.id,
        action: 'update',
        category: 'bid_deadline',
        actor_id: null,
        payload: {
          contract_id: c.id,
          contract_name: c.name,
          bid_deadline: c.bid_deadline,
          days_out: w.days,
          label: w.label,
        },
      })

      if (insErr) {
        errors.push(`insert ${c.id} (${w.label}): ${insErr.message}`)
      } else {
        inserted++
      }
    }
  }

  return new Response(
    JSON.stringify({ inserted, skipped, errors, windows: WINDOWS.map((w) => w.label) }),
    { status: 200, headers: { 'content-type': 'application/json' } },
  )
})
