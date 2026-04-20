// Phase 29 LIVE-11 — GET /api/live-feed/budget?project_id=<uuid>
// Returns { used, remaining, cap, resetsAt } counting cs_live_suggestions rows
// for the project since UTC midnight today. Auth via cookie-scoped Supabase
// client (RLS scopes the count to the caller's org; no service-role leakage).

import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'
import { readBudget } from '@/lib/live-feed/budget'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const projectId = req.nextUrl.searchParams.get('project_id')
  if (!projectId) {
    return NextResponse.json(
      {
        error: {
          code: 'missing_project_id',
          message: 'project_id query param required',
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
          message: 'Sign in to view budget',
          retryable: false,
        },
      },
      { status: 401 },
    )
  }

  try {
    const status = await readBudget(supabase, projectId)
    return NextResponse.json(status)
  } catch (err) {
    console.error('[live-feed/budget] read failed:', err)
    return NextResponse.json(
      {
        error: {
          code: 'budget_read_failed',
          message: 'Could not read budget',
          retryable: true,
        },
      },
      { status: 500 },
    )
  }
}
