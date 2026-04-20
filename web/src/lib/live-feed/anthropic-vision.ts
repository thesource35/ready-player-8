// Phase 29 LIVE-08 — Shared Anthropic vision adapter.
// Used by both the Supabase Edge Function (mirrored at supabase/functions/_shared/anthropic-vision.ts)
// and the /api/live-feed/analyze route (29-10). Keep the two copies in sync.

import { z } from 'zod'

// cs_live_suggestions.action_hint jsonb shape (UI-SPEC §Suggestion Card Severity + RESEARCH Pattern 4).
// Severity enum locks to exactly 3 values per UI-SPEC §Color line 121.
export const ActionHintSchema = z.object({
  verb: z.string().min(1).max(120).nullable(),
  severity: z.enum(['routine', 'opportunity', 'alert']),
  structured_fields: z
    .object({
      equipment_active_count: z.number().int().min(0).max(999).optional(),
      people_visible_count: z.number().int().min(0).max(999).optional(),
      perimeter_activity: z
        .enum(['clear', 'vehicle_approach', 'unidentified_activity'])
        .optional(),
      deliveries_in_progress: z.number().int().min(0).max(99).optional(),
      weather_visible: z
        .enum(['clear', 'overcast', 'rain', 'dust', 'unknown'])
        .optional(),
    })
    .default({}),
})
export type ActionHint = z.infer<typeof ActionHintSchema>

// Must match cs_live_suggestions.suggestion_text check (29-01): 1..2000 chars.
export const LiveSuggestionResponseSchema = z.object({
  suggestion_text: z.string().min(1).max(2000),
  action_hint: ActionHintSchema,
})
export type LiveSuggestionResponse = z.infer<typeof LiveSuggestionResponseSchema>

// Locked to cs_live_suggestions.model check (29-01): 3 model values (marker is sentinel-only).
export type AnthropicVisionModel =
  | 'claude-haiku-4-5-20251001'
  | 'claude-sonnet-4-6'
  | 'claude-opus-4-7'

export const DEFAULT_VISION_MODEL: AnthropicVisionModel = 'claude-haiku-4-5-20251001'

// System prompt — RESEARCH Pattern 4. Card is 1-3 sentences (D-13) with optional action verb.
export const SITE_ANALYST_SYSTEM_PROMPT = [
  'You are the site analyst for ConstructionOS. You look at a single frame from a drone',
  'camera over an active construction project and produce ONE short observation card',
  '(1-3 sentences) describing what is happening on site right now.',
  '',
  'Output ONLY valid JSON matching this schema:',
  '{',
  '  "suggestion_text": "<1-3 sentences, max 2000 chars>",',
  '  "action_hint": {',
  '    "verb": "<short imperative verb phrase or null>",',
  '    "severity": "routine" | "opportunity" | "alert",',
  '    "structured_fields": {',
  '      "equipment_active_count": <integer 0-999 optional>,',
  '      "people_visible_count": <integer 0-999 optional>,',
  '      "perimeter_activity": "clear" | "vehicle_approach" | "unidentified_activity",',
  '      "deliveries_in_progress": <integer 0-99 optional>,',
  '      "weather_visible": "clear" | "overcast" | "rain" | "dust" | "unknown"',
  '    }',
  '  }',
  '}',
  '',
  'Severity guidance:',
  '- routine: informational observation (e.g., "Concrete pour continuing")',
  '- opportunity: actionable opportunity (e.g., "Material truck at gate — prep dock")',
  '- alert: attention-required signal (e.g., "Perimeter activity after hours")',
  '',
  'Do NOT invent facts not visible in the frame or present in the structured context.',
].join('\n')

export interface VisionPromptInput {
  imageUrl: string
  projectName?: string
  activeEquipment?: string[]
  recentDeliveries?: string[]
  weather?: string
  roadTraffic?: string
}

export function buildVisionPrompt(input: VisionPromptInput) {
  const userText = [
    input.projectName ? `Project: ${input.projectName}` : '',
    input.activeEquipment?.length
      ? `Active equipment: ${input.activeEquipment.join(', ')}`
      : 'Active equipment: unknown',
    input.recentDeliveries?.length
      ? `Recent deliveries (last 4h): ${input.recentDeliveries.join('; ')}`
      : 'Recent deliveries: none in last 4 hours',
    input.weather ? `Weather: ${input.weather}` : 'Weather: unknown',
    input.roadTraffic ? `Road traffic (nearest route): ${input.roadTraffic}` : 'Road traffic: unknown',
    '',
    "What's happening on this drone frame?",
  ]
    .filter(Boolean)
    .join('\n')

  return [
    {
      role: 'user' as const,
      content: [
        { type: 'image' as const, source: { type: 'url' as const, url: input.imageUrl } },
        { type: 'text' as const, text: userText },
      ],
    },
  ]
}

export interface CallAnthropicVisionInput {
  imageUrl: string
  promptInput: VisionPromptInput
  model: AnthropicVisionModel
  apiKey: string
  maxTokens?: number
  fetchImpl?: typeof fetch
}

/**
 * Calls Anthropic Messages API with vision content. Returns parsed + validated LiveSuggestionResponse.
 * Throws on HTTP error (after 1 retry on 5xx), on non-JSON body, or on Zod parse failure.
 */
export async function callAnthropicVision(
  input: CallAnthropicVisionInput,
): Promise<LiveSuggestionResponse> {
  const { imageUrl, promptInput, model, apiKey, maxTokens = 400 } = input
  const fetchFn = input.fetchImpl ?? fetch

  const body = {
    model,
    max_tokens: maxTokens,
    system: SITE_ANALYST_SYSTEM_PROMPT,
    messages: buildVisionPrompt({ ...promptInput, imageUrl }),
  }

  const doCall = async () =>
    fetchFn('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify(body),
    })

  let res = await doCall()
  if (res.status >= 500 && res.status < 600) {
    // Single retry on 5xx
    res = await doCall()
  }
  if (!res.ok) {
    throw new Error(`anthropic_vision_http_${res.status}`)
  }

  const envelope = (await res.json()) as {
    content?: Array<{ type: string; text?: string }>
  }
  const textBlock = envelope.content?.find((c) => c.type === 'text')?.text ?? ''

  // Claude may wrap the JSON with prose — try to extract the first {...} block.
  const jsonMatch = textBlock.match(/\{[\s\S]*\}/)
  if (!jsonMatch) {
    throw new Error('anthropic_vision_no_json')
  }

  let parsed: unknown
  try {
    parsed = JSON.parse(jsonMatch[0])
  } catch {
    throw new Error('anthropic_vision_invalid_json')
  }

  const validated = LiveSuggestionResponseSchema.safeParse(parsed)
  if (!validated.success) {
    // Full Zod error — no truncation (CLAUDE.md core value: no silent data loss).
    // Multi-field violations would be clipped at 200 chars; operators need the whole thing to diagnose.
    throw new Error(`anthropic_vision_zod_failed: ${validated.error.message}`)
  }
  return validated.data
}
