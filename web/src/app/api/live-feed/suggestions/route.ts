// Phase 29 LIVE-09 — GET /api/live-feed/suggestions?project_id=<uuid>
// Returns the 20 most recent non-dismissed cs_live_suggestions for the project,
// ordered by generated_at DESC. RLS (29-01 cs_live_suggestions_select) scopes
// to the caller's org — no manual org_id filter needed.
//
// Response shape excludes dismissed_by and org_id to limit leakage surface;
// downstream UI components only need the fields listed in the SELECT.

import { NextRequest, NextResponse } from 'next/server'
import { createServerSupabase } from '@/lib/supabase/server'

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
          message: 'Sign in to view suggestions',
          retryable: false,
        },
      },
      { status: 401 },
    )
  }

  const { data, error } = await supabase
    .from('cs_live_suggestions')
    .select(
      'id, project_id, generated_at, source_asset_id, model, suggestion_text, action_hint, dismissed_at',
    )
    .eq('project_id', projectId)
    .is('dismissed_at', null)
    .order('generated_at', { ascending: false })
    .limit(20)

  if (error) {
    console.error('[live-feed/suggestions] list failed:', error)
    return NextResponse.json(
      {
        error: {
          code: 'suggestions_read_failed',
          message: 'Could not read suggestions',
          retryable: true,
        },
      },
      { status: 500 },
    )
  }

  return NextResponse.json({ suggestions: data ?? [] })
}
