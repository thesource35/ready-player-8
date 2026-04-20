// Phase 29 LIVE-09 — PATCH /api/live-feed/suggestions/:id
// Per-user dismiss. Sets dismissed_at=now() and dismissed_by=auth.uid() via the
// authenticated Supabase client — RLS policy cs_live_suggestions_dismiss enforces
// (a) caller is in the row's org and (b) dismissed_by must equal auth.uid().
//
// Rate-limited to 30 req/min/IP per Phase 22 D-37 pattern (shared limiter).

import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'
import { rateLimit } from '@/lib/rate-limit'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const ip =
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
  const limit = await rateLimit(ip, '/api/live-feed/suggestions')
  if (!limit.success) {
    return NextResponse.json(
      {
        error: {
          code: 'rate_limited',
          message: 'Too many dismissals — try again in a minute',
          retryable: true,
        },
      },
      {
        status: 429,
        headers: {
          'Retry-After': String(
            Math.max(1, Math.ceil((limit.reset - Date.now()) / 1000)),
          ),
        },
      },
    )
  }

  const { id } = await params
  if (!id) {
    return NextResponse.json(
      {
        error: {
          code: 'missing_id',
          message: 'Suggestion id required in path',
          retryable: false,
        },
      },
      { status: 400 },
    )
  }

  const supabase = await createServerSupabase()
  if (!supabase) {
    return NextResponse.json(
      {
        error: {
          code: 'supabase_not_configured',
          message: 'Database not configured',
          retryable: false,
        },
      },
      { status: 503 },
    )
  }

  const {
    data: { user },
  } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json(
      {
        error: {
          code: 'unauthenticated',
          message: 'Sign in to dismiss',
          retryable: false,
        },
      },
      { status: 401 },
    )
  }

  const { data, error } = await supabase
    .from('cs_live_suggestions')
    .update({
      dismissed_at: new Date().toISOString(),
      dismissed_by: user.id,
    })
    .eq('id', id)
    .select('id, dismissed_at, dismissed_by')
    .single()

  if (error) {
    console.error('[live-feed/suggestions PATCH] failed:', error)
    // PGRST116 = No rows returned (either does not exist OR RLS hid it).
    // Treat as 404 to avoid leaking whether the id exists in another org.
    const status = error.code === 'PGRST116' ? 404 : 403
    return NextResponse.json(
      {
        error: {
          code: status === 404 ? 'not_found' : 'forbidden',
          message: error.message,
          retryable: false,
        },
      },
      { status },
    )
  }

  return NextResponse.json({ suggestion: data })
}
