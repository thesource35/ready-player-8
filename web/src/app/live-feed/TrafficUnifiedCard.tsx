// Phase 29 LIVE-10 — unified Traffic card.
//
// Two sections under one TRAFFIC heading per UI-SPEC §Component Inventory /
// D-18:
//   ROAD    — flow-color dot + (light/moderate/heavy) label + optional ETA.
//             v1 takes `roadSummary` from a prop so we can defer Phase-21
//             traffic-tile wiring without blocking the layout.
//   ON-SITE — structured_fields read from the latest suggestion's action_hint.
//             Fields match the Zod schema in @/lib/live-feed/anthropic-vision:
//               equipment_active_count, people_visible_count,
//               deliveries_in_progress, perimeter_activity, weather_visible.
//
// Empty-state copy: "No data — waiting for next analysis" (UI-SPEC §Interaction
// Contracts LIVE-10 line 320).

'use client'

import type { LiveSuggestion } from './useSuggestions'

export type RoadTrafficFlow = 'light' | 'moderate' | 'heavy'

export type RoadTrafficSummary = {
  flow: RoadTrafficFlow | null
  etaMinutes: number | null
}

type StructuredFields = {
  equipment_active_count?: number
  people_visible_count?: number
  deliveries_in_progress?: number
  perimeter_activity?: 'clear' | 'vehicle_approach' | 'unidentified_activity'
  weather_visible?: 'clear' | 'overcast' | 'rain' | 'dust' | 'unknown'
}

const flowColor: Record<RoadTrafficFlow, string> = {
  light: 'var(--green)',
  moderate: 'var(--gold)',
  heavy: 'var(--red)',
}

const EMPTY_COPY = 'No data — waiting for next analysis'

export function TrafficUnifiedCard({
  roadSummary,
  latestSuggestion,
}: {
  roadSummary: RoadTrafficSummary | null
  latestSuggestion: LiveSuggestion | null
}) {
  const onSite = (latestSuggestion?.action_hint?.structured_fields ??
    undefined) as StructuredFields | undefined

  const hasOnSite = Boolean(
    onSite &&
      (typeof onSite.equipment_active_count === 'number' ||
        typeof onSite.people_visible_count === 'number' ||
        typeof onSite.deliveries_in_progress === 'number' ||
        onSite.perimeter_activity ||
        onSite.weather_visible),
  )

  return (
    <section
      aria-label="Traffic summary"
      data-testid="traffic-unified-card"
      style={{
        background: 'var(--surface)',
        borderRadius: 14,
        padding: 20,
      }}
    >
      <h3
        style={{
          fontSize: 11,
          fontWeight: 800,
          letterSpacing: 2,
          color: 'var(--accent)',
          margin: 0,
          marginBottom: 12,
          textTransform: 'uppercase',
        }}
      >
        TRAFFIC
      </h3>

      <div
        style={{
          borderBottom: '1px solid var(--border, #1a2a34)',
          paddingBottom: 12,
          marginBottom: 12,
        }}
      >
        <div
          style={{
            fontSize: 9,
            fontWeight: 800,
            letterSpacing: 2,
            color: 'var(--muted)',
            marginBottom: 8,
            textTransform: 'uppercase',
          }}
        >
          ROAD
        </div>
        {roadSummary?.flow ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span
              aria-hidden="true"
              style={{
                width: 8,
                height: 8,
                borderRadius: '50%',
                background: flowColor[roadSummary.flow],
                display: 'inline-block',
              }}
            />
            <span
              style={{
                fontSize: 12,
                color: 'var(--text)',
                textTransform: 'capitalize',
              }}
            >
              {roadSummary.flow}
            </span>
            {roadSummary.etaMinutes !== null && (
              <span
                style={{
                  fontSize: 12,
                  color: 'var(--gold)',
                  marginLeft: 'auto',
                }}
              >
                ETA {roadSummary.etaMinutes} min
              </span>
            )}
          </div>
        ) : (
          <span style={{ fontSize: 12, color: 'var(--muted)' }}>{EMPTY_COPY}</span>
        )}
      </div>

      <div>
        <div
          style={{
            fontSize: 9,
            fontWeight: 800,
            letterSpacing: 2,
            color: 'var(--muted)',
            marginBottom: 8,
            textTransform: 'uppercase',
          }}
        >
          ON-SITE
        </div>
        {hasOnSite && onSite ? (
          <ul
            style={{
              listStyle: 'none',
              padding: 0,
              margin: 0,
              fontSize: 12,
              lineHeight: 1.5,
              color: 'var(--text)',
            }}
          >
            {typeof onSite.equipment_active_count === 'number' && (
              <li>
                Equipment active:{' '}
                <span style={{ color: 'var(--green)' }}>
                  {onSite.equipment_active_count}
                </span>
              </li>
            )}
            {typeof onSite.people_visible_count === 'number' && (
              <li>
                People visible:{' '}
                <span style={{ color: 'var(--cyan)' }}>
                  {onSite.people_visible_count}
                </span>
              </li>
            )}
            {typeof onSite.deliveries_in_progress === 'number' && (
              <li>
                Deliveries in progress:{' '}
                <span style={{ color: 'var(--purple)' }}>
                  {onSite.deliveries_in_progress}
                </span>
              </li>
            )}
            {onSite.perimeter_activity && (
              <li>
                Perimeter:{' '}
                <span
                  style={{
                    color:
                      onSite.perimeter_activity === 'clear'
                        ? 'var(--green)'
                        : onSite.perimeter_activity === 'unidentified_activity'
                          ? 'var(--red)'
                          : 'var(--gold)',
                    textTransform: 'capitalize',
                  }}
                >
                  {onSite.perimeter_activity.replace(/_/g, ' ')}
                </span>
              </li>
            )}
            {onSite.weather_visible && onSite.weather_visible !== 'unknown' && (
              <li style={{ textTransform: 'capitalize' }}>
                Weather: {onSite.weather_visible}
              </li>
            )}
          </ul>
        ) : (
          <span style={{ fontSize: 12, color: 'var(--muted)' }}>{EMPTY_COPY}</span>
        )}
      </div>
    </section>
  )
}
