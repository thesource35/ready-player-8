// Phase 29 LIVE-08 — Shared per-project suggestion generator.
//
// Mirrors the per-project body of supabase/functions/generate-live-suggestions/index.ts
// so the manual /api/live-feed/analyze route (29-10 T-10-E) and the scheduled
// Edge Function both go through the same: latest-drone-asset -> sign poster ->
// build context -> callAnthropicVision -> insert. Keeping the contract narrow
// (one project at a time) lets the caller decide how to count budget, rate-limit,
// iterate, etc.
//
// Budget pre-check is the CALLER's responsibility — this function assumes the
// cap has already been verified via readBudget/assertBudgetAvailable. Calling
// this without the pre-check can exceed the 96/day cap (T-29-COST-CAP).

import type { SupabaseClient } from '@supabase/supabase-js'
import {
  callAnthropicVision,
  DEFAULT_VISION_MODEL,
  type AnthropicVisionModel,
} from './anthropic-vision'

export type GenerateSuggestionArgs = {
  projectId: string
  supabase: SupabaseClient // service-role client — needs storage.createSignedUrl + INSERT on cs_live_suggestions
  triggeredBy: 'manual' | 'scheduled' | 'upload'
  userId?: string // logged for audit; never written to cs_live_suggestions (that column does not exist)
  model?: AnthropicVisionModel
  apiKey?: string // defaults to process.env.ANTHROPIC_API_KEY
}

export type GeneratedSuggestion = {
  id: string
  project_id: string
  generated_at: string
  source_asset_id: string
  model: string
  suggestion_text: string
  action_hint: unknown
}

type DroneAssetRow = {
  id: string
  org_id: string
  project_id: string
  created_at: string
}

type ProjectContext = {
  projectName?: string
  activeEquipment?: string[]
}

export class GenerateSuggestionError extends Error {
  code:
    | 'no_ready_drone_asset'
    | 'poster_sign_failed'
    | 'vision_failed'
    | 'insert_failed'
    | 'missing_api_key'
  constructor(code: GenerateSuggestionError['code'], message: string) {
    super(message)
    this.code = code
  }
}

async function latestDroneAsset(
  supabase: SupabaseClient,
  projectId: string,
): Promise<DroneAssetRow | null> {
  const { data } = await supabase
    .from('cs_video_assets')
    .select('id, org_id, project_id, created_at')
    .eq('project_id', projectId)
    .eq('source_type', 'drone')
    .eq('status', 'ready')
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()
  return (data as DroneAssetRow | null) ?? null
}

async function buildProjectContext(
  supabase: SupabaseClient,
  projectId: string,
): Promise<ProjectContext> {
  const { data: project } = await supabase
    .from('cs_projects')
    .select('name')
    .eq('id', projectId)
    .maybeSingle()

  const { data: equipment } = await supabase
    .from('cs_equipment')
    .select('name')
    .eq('project_id', projectId)
    .eq('status', 'active')
    .limit(8)

  return {
    projectName: (project as { name?: string } | null)?.name ?? undefined,
    activeEquipment: (equipment ?? []).map((e: { name: string }) => e.name),
  }
}

/**
 * Generate and persist one cs_live_suggestions row for a project. Delegates
 * vision work to the shared callAnthropicVision adapter (Zod validation lives
 * there — T-29-VISION-PAYLOAD mitigation).
 *
 * Throws GenerateSuggestionError on every failure path. No silent skips.
 */
export async function generateSuggestion(
  args: GenerateSuggestionArgs,
): Promise<GeneratedSuggestion> {
  const {
    projectId,
    supabase,
    model = DEFAULT_VISION_MODEL,
    apiKey = process.env.ANTHROPIC_API_KEY,
  } = args

  if (!apiKey) {
    throw new GenerateSuggestionError(
      'missing_api_key',
      'ANTHROPIC_API_KEY not configured',
    )
  }

  const asset = await latestDroneAsset(supabase, projectId)
  if (!asset) {
    throw new GenerateSuggestionError(
      'no_ready_drone_asset',
      'No ready drone clip to analyze yet — upload a clip first',
    )
  }

  // Poster lives at <org>/<project>/<asset>/poster.jpg — matches Phase 22 storage layout.
  const posterPath = `${asset.org_id}/${asset.project_id}/${asset.id}/poster.jpg`
  const { data: signed, error: signErr } = await supabase.storage
    .from('videos')
    .createSignedUrl(posterPath, 60)
  if (signErr || !signed?.signedUrl) {
    throw new GenerateSuggestionError(
      'poster_sign_failed',
      signErr?.message ?? 'Could not sign poster URL',
    )
  }

  const context = await buildProjectContext(supabase, projectId)

  let parsed
  try {
    parsed = await callAnthropicVision({
      imageUrl: signed.signedUrl,
      // VisionPromptInput requires imageUrl on the prompt object too; pass
      // the same signed URL through so buildVisionPrompt can reference it.
      promptInput: { ...context, imageUrl: signed.signedUrl },
      model,
      apiKey,
    })
  } catch (err) {
    throw new GenerateSuggestionError(
      'vision_failed',
      err instanceof Error ? err.message : 'Vision call failed',
    )
  }

  const { data: inserted, error: insErr } = await supabase
    .from('cs_live_suggestions')
    .insert({
      project_id: projectId,
      org_id: asset.org_id,
      source_asset_id: asset.id,
      model,
      suggestion_text: parsed.suggestion_text,
      action_hint: parsed.action_hint,
    })
    .select('id, project_id, generated_at, source_asset_id, model, suggestion_text, action_hint')
    .single()

  if (insErr || !inserted) {
    throw new GenerateSuggestionError(
      'insert_failed',
      insErr?.message ?? 'Could not persist suggestion',
    )
  }

  return inserted as GeneratedSuggestion
}
