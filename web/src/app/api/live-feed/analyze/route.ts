// Phase 29 LIVE-08 / LIVE-11 — POST /api/live-feed/analyze
// Manual "Analyze Now" trigger. Pre-checks the 96/day cost cap (D-22 / T-29-COST-CAP
// mitigation) BEFORE invoking Anthropic, then delegates generation to the shared
// generateSuggestion helper — the same code path the scheduled Edge Function takes.
//
// Rate-limited 30 req/min/IP (Phase 22 D-37 pattern). Insert path uses a
// service-role client because cs_live_suggestions has no INSERT RLS policy
// (service_role-only writes per 29-01 STEP D); budget pre-check uses the
// cookie-scoped client so RLS keeps cross-org counts honest.

import { NextRequest, NextResponse } from 'next/server'
import {
  createServerSupabase,
  createServiceRoleClient,
} from '@/lib/supabase/server'
import { rateLimit } from '@/lib/rate-limit'
import { assertBudgetAvailable, type BudgetStatus } from '@/lib/live-feed/budget'
import {
  generateSuggestion,
  GenerateSuggestionError,
} from '@/lib/live-feed/generate-suggestion'

export const runtime = 'nodejs'
export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const ip =
    req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() ?? 'unknown'
  const limit = await rateLimit(ip, '/api/live-feed/analyze')
  if (!limit.success) {
    return NextResponse.json(
      {
        error: {
          code: 'rate_limited',
          message: 'Too many analyze requests — try again in a minute',
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

  const body = await req.json().catch(() => ({}))
  const projectId = (body as { project_id?: unknown })?.project_id
  if (!projectId || typeof projectId !== 'string') {
    return NextResponse.json(
      {
        error: {
          code: 'missing_project_id',
          message: 'project_id required in body',
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
          message: 'Sign in to analyze',
          retryable: false,
        },
      },
      { status: 401 },
    )
  }

  // Budget pre-check (T-29-COST-CAP mitigation). Use the cookie-scoped client
  // so RLS enforces org isolation on the count; service-role would bypass it.
  try {
    await assertBudgetAvailable(supabase, projectId)
  } catch (err: unknown) {
    if ((err as { code?: string })?.code === 'budget_reached') {
      return NextResponse.json(
        {
          error: {
            code: 'budget_reached',
            message:
              'Suggestion budget reached for today — resumes at 00:00 project-local time.',
            retryable: false,
          },
          budget: (err as { status: BudgetStatus }).status,
        },
        { status: 429 },
      )
    }
    console.error('[live-feed/analyze] budget check failed:', err)
    return NextResponse.json(
      {
        error: {
          code: 'budget_check_failed',
          message: 'Could not verify budget',
          retryable: true,
        },
      },
      { status: 500 },
    )
  }

  // Before invoking service-role, confirm the user actually has access to the
  // project (belt-and-suspenders alongside the budget pre-check which already
  // exercised RLS on cs_live_suggestions for the same project_id). A service-role
  // caller without this gate could analyze any project in the DB.
  const { data: projectRow, error: projectErr } = await supabase
    .from('cs_projects')
    .select('id')
    .eq('id', projectId)
    .maybeSingle()
  if (projectErr || !projectRow) {
    return NextResponse.json(
      {
        error: {
          code: 'project_not_accessible',
          message: 'No project with that id in your organization',
          retryable: false,
        },
      },
      { status: 404 },
    )
  }

  // Delegate to shared adapter (T-29-VISION-PAYLOAD mitigation: Zod validation
  // lives inside callAnthropicVision). Service-role client required because
  // cs_live_suggestions has no INSERT RLS policy (29-01 STEP D — writes are
  // service_role-only, same as the Edge Function).
  let service
  try {
    service = createServiceRoleClient()
  } catch (err) {
    console.error('[live-feed/analyze] service client unavailable:', err)
    return NextResponse.json(
      {
        error: {
          code: 'service_client_unavailable',
          message: 'Server not configured for analysis',
          retryable: false,
        },
      },
      { status: 503 },
    )
  }

  try {
    const suggestion = await generateSuggestion({
      projectId,
      supabase: service,
      triggeredBy: 'manual',
      userId: user.id,
    })
    return NextResponse.json({ suggestion })
  } catch (err) {
    if (err instanceof GenerateSuggestionError) {
      console.error(
        `[live-feed/analyze] generate failed (${err.code}):`,
        err.message,
      )
      const status =
        err.code === 'no_ready_drone_asset'
          ? 409
          : err.code === 'missing_api_key'
            ? 503
            : 500
      return NextResponse.json(
        {
          error: {
            code: err.code,
            message:
              err.code === 'no_ready_drone_asset'
                ? 'No drone clip ready yet — upload one to analyze.'
                : err.code === 'missing_api_key'
                  ? 'Analysis service not configured'
                  : 'Analysis failed — try again in a moment.',
            retryable: err.code !== 'missing_api_key',
          },
        },
        { status },
      )
    }
    console.error('[live-feed/analyze] unexpected failure:', err)
    return NextResponse.json(
      {
        error: {
          code: 'generate_failed',
          message: 'Analysis failed — try again in a moment.',
          retryable: true,
        },
      },
      { status: 500 },
    )
  }
}
