// Owner: 29-03-PLAN.md Wave 2 — LIVE-08: Anthropic vision adapter JSON validation
import { describe, it, expect, vi } from 'vitest'
import {
  buildVisionPrompt,
  callAnthropicVision,
  LiveSuggestionResponseSchema,
  DEFAULT_VISION_MODEL,
} from '../anthropic-vision'

describe('buildVisionPrompt', () => {
  it('returns a user message with image + text blocks', () => {
    const messages = buildVisionPrompt({
      imageUrl: 'https://signed.example/poster.jpg',
      projectName: 'Riverfront Tower',
      activeEquipment: ['excavator', 'crane'],
      weather: '68F overcast',
    })
    expect(messages).toHaveLength(1)
    expect(messages[0].role).toBe('user')
    expect(messages[0].content[0]).toMatchObject({
      type: 'image',
      source: { type: 'url', url: 'https://signed.example/poster.jpg' },
    })
    expect(messages[0].content[1].type).toBe('text')
    expect((messages[0].content[1] as { type: 'text'; text: string }).text).toContain('Riverfront Tower')
  })
})

describe('LiveSuggestionResponseSchema', () => {
  it('accepts a well-formed response', () => {
    const r = LiveSuggestionResponseSchema.safeParse({
      suggestion_text: 'Crew staging rebar at east bay.',
      action_hint: {
        verb: 'flag east gate',
        severity: 'opportunity',
        structured_fields: { equipment_active_count: 3, people_visible_count: 8 },
      },
    })
    expect(r.success).toBe(true)
  })

  it('rejects empty suggestion_text', () => {
    const r = LiveSuggestionResponseSchema.safeParse({
      suggestion_text: '',
      action_hint: { verb: null, severity: 'routine', structured_fields: {} },
    })
    expect(r.success).toBe(false)
  })

  it('rejects suggestion_text > 2000 chars', () => {
    const r = LiveSuggestionResponseSchema.safeParse({
      suggestion_text: 'x'.repeat(2001),
      action_hint: { verb: null, severity: 'routine', structured_fields: {} },
    })
    expect(r.success).toBe(false)
  })

  it('rejects invalid severity', () => {
    const r = LiveSuggestionResponseSchema.safeParse({
      suggestion_text: 'ok',
      action_hint: { verb: null, severity: 'emergency', structured_fields: {} },
    })
    expect(r.success).toBe(false)
  })
})

describe('callAnthropicVision', () => {
  it('parses and validates a 200 response', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              suggestion_text: 'Concrete pour at NW corner.',
              action_hint: { verb: null, severity: 'routine', structured_fields: {} },
            }),
          },
        ],
      }),
    } as unknown as Response)
    const result = await callAnthropicVision({
      imageUrl: 'https://x/poster.jpg',
      promptInput: { imageUrl: 'https://x/poster.jpg' },
      model: DEFAULT_VISION_MODEL,
      apiKey: 'sk-ant-test',
      fetchImpl: fetchImpl as unknown as typeof fetch,
    })
    expect(result.suggestion_text).toBe('Concrete pour at NW corner.')
    expect(result.action_hint.severity).toBe('routine')
  })

  it('retries once on 5xx then throws', async () => {
    const fetchImpl = vi
      .fn()
      .mockResolvedValueOnce({ ok: false, status: 503, json: async () => ({}) } as unknown as Response)
      .mockResolvedValueOnce({ ok: false, status: 500, json: async () => ({}) } as unknown as Response)
    await expect(
      callAnthropicVision({
        imageUrl: 'https://x/poster.jpg',
        promptInput: { imageUrl: 'https://x/poster.jpg' },
        model: DEFAULT_VISION_MODEL,
        apiKey: 'sk-ant-test',
        fetchImpl: fetchImpl as unknown as typeof fetch,
      }),
    ).rejects.toThrow(/anthropic_vision_http_500/)
    expect(fetchImpl).toHaveBeenCalledTimes(2)
  })

  it('throws when response body has no JSON block', async () => {
    const fetchImpl = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ content: [{ type: 'text', text: 'I cannot produce JSON.' }] }),
    } as unknown as Response)
    await expect(
      callAnthropicVision({
        imageUrl: 'https://x/poster.jpg',
        promptInput: { imageUrl: 'https://x/poster.jpg' },
        model: DEFAULT_VISION_MODEL,
        apiKey: 'sk-ant-test',
        fetchImpl: fetchImpl as unknown as typeof fetch,
      }),
    ).rejects.toThrow(/anthropic_vision_no_json/)
  })
})
