# Phase 25: Certification Expiry Notifications - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 25-certification-expiry-notifications
**Areas discussed:** Escalation thresholds & dedupe, Notification content & urgency, iOS & web UI treatment, Testing & verification, Edge cases, Performance, Migration strategy, Recipient resolution, Logging & observability, Accessibility, Offline/sync behavior, Rate limiting, Cert renewal workflow, Multi-org isolation, Channel future-proofing, Angelic AI integration, Reporting dashboard, Analytics tracking, Cert taxonomy, Error handling, Bell count, Timezone handling, Project activity, Data retention, Push preview format, CarPlay/visionOS, Regulatory compliance, Cert priority, UI animations, Notification preferences, Scheduling, Cert document attachment, Notification grouping

---

## Escalation Thresholds & Dedupe

| Option | Description | Selected |
|--------|-------------|----------|
| Side table | New cs_certification_alerts_sent table with (cert_id, threshold_key, sent_at) | |
| Payload marker | Store threshold_key in cs_activity_events.payload and query for existence | ✓ |
| You decide | Claude picks best approach | |

**User's choice:** Payload marker — no new table, leverage existing event log.

| Option | Description | Selected |
|--------|-------------|----------|
| Cap at 4 weeks | Fire weekly pings for 4 weeks, then stop | |
| Indefinite until resolved | Keep pinging weekly until renewed or deleted | ✓ |

**User's choice:** Indefinite pings until resolved — matches Phase 15 D-05 literally.

## Notification Content & Urgency

| Option | Description | Selected |
|--------|-------------|----------|
| Escalating severity | 30-day=info, 7-day=warning, day-of=critical. Push only at 7d+ | |
| All push, same severity | Every threshold sends push with same severity | |
| All push, escalating copy | Every threshold sends push, copy escalates | ✓ |

**User's choice:** All push with escalating copy.

| Option | Description | Selected |
|--------|-------------|----------|
| Group by member | One notification per member per threshold | ✓ |
| Individual per cert | One notification per cert | |

**User's choice:** Group by member.

| Option | Description | Selected |
|--------|-------------|----------|
| Specific names | Include member + cert names | ✓ |
| Generic with count | Just count of certs | |

**User's choice:** Specific names.

| Option | Description | Selected |
|--------|-------------|----------|
| Include duration since expiry | Growing urgency counter | |
| Static expired copy | Same text each week | ✓ |

**User's choice:** Static expired copy.

| Option | Description | Selected |
|--------|-------------|----------|
| Standard dismiss | Same Phase 14 behavior, future pings still fire | |
| Dismiss + suppress future | Dismissing suppresses pings at current threshold | ✓ |

**User's choice:** Dismiss suppresses future pings per-user only.

| Option | Description | Selected |
|--------|-------------|----------|
| Per-user only | Each PM's dismiss is independent | ✓ |
| Per-cert global | Any dismiss suppresses for all | |

**User's choice:** Per-user — other PMs still get alerted.

## iOS & Web UI Treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Deep-link to cert | Navigate to specific cert in CertificationsView | ✓ |
| Link to team tab | Open team tab generically | |

| Option | Description | Selected |
|--------|-------------|----------|
| Inline urgency badges | Green/amber/red on cert cards | ✓ |
| Notification-only urgency | Urgency via inbox only | |

**User's choice:** Both — inline badges AND notification urgency.

| Option | Description | Selected |
|--------|-------------|----------|
| CTA on cert card only | Renewal button on cert card | |
| CTA on both | Renewal button on notification AND cert card | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Full web parity | Web gets badges, CTA, summary banner | ✓ |
| Simplified web | Badges only, no inline CTA | |

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse Phase 14 format | Same APNs category | |
| Distinct cert category | Custom cert-expiry category with action button | |
| Integrate both | Phase 14 infrastructure + distinct cert category | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Full cold-launch support | Deep-link works from cold launch | ✓ |
| Warm-only deep-link | Only works when app is running | |

| Option | Description | Selected |
|--------|-------------|----------|
| Direct deep-link | Notification links to /team/certifications?highlight= | ✓ |
| Notification detail first | Intermediate detail page | |

| Option | Description | Selected |
|--------|-------------|----------|
| Summary banner | Compact banner showing expiring/expired counts | ✓ |
| No summary banner | Individual badges sufficient | |

| Option | Description | Selected |
|--------|-------------|----------|
| Title + body split | Structured APNs push format | ✓ |
| Single body line | Simple single-line format | |

## Testing & Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Unit tests + contract tests | Full test coverage for Edge Function | ✓ |
| Unit tests only | Basic threshold tests | |

| Option | Description | Selected |
|--------|-------------|----------|
| XCTest for badge + routing | iOS urgency calc + deep-link parsing tests | ✓ |
| Skip iOS unit tests | Trust simple badge logic | |

| Option | Description | Selected |
|--------|-------------|----------|
| Vitest for web parity | Mirror iOS test coverage on web | ✓ |
| Skip web tests | Trust visual rendering | |

| Option | Description | Selected |
|--------|-------------|----------|
| Edge Function unit test | Mock cs_notifications for dismiss-suppress | ✓ |
| Integration test | Seed real data in test DB | |

| Option | Description | Selected |
|--------|-------------|----------|
| Document manual test plan | Checklist for full pipeline verification | ✓ |
| Automated only | Trust unit/contract tests | |

## Edge Cases

| Option | Description | Selected |
|--------|-------------|----------|
| No cleanup needed | Cert deleted, notifications stay | |
| Clean up orphaned notifications | Mark related notifications as dismissed | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Still alert created_by user | Unassigned member, alert cert owner | ✓ |
| Skip alerts entirely | No assignment = no alert | |

| Option | Description | Selected |
|--------|-------------|----------|
| Full restart | Renewed cert gets fresh cadence | ✓ |
| Skip already-fired thresholds | No repeat of fired thresholds | |

## Performance

| Option | Description | Selected |
|--------|-------------|----------|
| Single pass with limit | Query all at once, max 1000 | |
| Paginated batches | Process in batches of 100 | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Timeout guard | Bail after 50 seconds | ✓ |
| No timeout guard | Trust batch completion | |

## Migration Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Fire all applicable thresholds | Retroactive burst | |
| Start clean from today | Only future thresholds | |
| Fire only the most urgent | Closest threshold only | ✓ |

## Recipient Resolution

| Option | Description | Selected |
|--------|-------------|----------|
| All PMs across all projects | Every PM on every active project | ✓ |
| Primary project PM only | First/primary assignment only | |

| Option | Description | Selected |
|--------|-------------|----------|
| Match 'project manager' in role_on_project | Case-insensitive match + created_by | ✓ |
| All project members | Everyone assigned gets alerts | |

## Logging & Observability

| Option | Description | Selected |
|--------|-------------|----------|
| Structured summary | JSON summary per run | ✓ |
| Verbose per-cert logging | Log each cert processed | |
| Minimal | Current { inserted: N } only | |

| Option | Description | Selected |
|--------|-------------|----------|
| No in-app health display | Logs only | |
| Admin-only status badge | Last scan time + count | ✓ |

## Accessibility

| Option | Description | Selected |
|--------|-------------|----------|
| Semantic labels | VoiceOver labels like "Expiring in 7 days — warning" | ✓ |
| Color-only with aria-label | Basic aria-label | |

## Offline/Sync

| Option | Description | Selected |
|--------|-------------|----------|
| Local calculation from cached data | Badges work offline | ✓ |
| Server-only urgency | Requires connectivity | |

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — natural sync | Missed notifications appear retroactively | ✓ |
| Skip old notifications | Only show since last sync | |

## Rate Limiting

| Option | Description | Selected |
|--------|-------------|----------|
| Cap per run | 200 events max, prioritize urgent | ✓ |
| No cap | Let scan create unlimited events | |

## Cert Renewal Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Edit in place | Pre-filled form, update expires_at | ✓ |
| New version with history | Each renewal creates new row | |

## Multi-Org

| Option | Description | Selected |
|--------|-------------|----------|
| RLS handles it | Existing RLS chain sufficient | ✓ |
| Explicit org filter in scan | Add org_id filtering | |

## Channel Future-Proofing

| Option | Description | Selected |
|--------|-------------|----------|
| Channel-agnostic events | delivery_channels array in payload | ✓ |
| Hardcode push+inbox only | Tight coupling | |

## Angelic AI Integration

**User's choice:** Add get_expiring_certs MCP tool — in scope.

## Reporting Dashboard

**User's choice:** Include cert compliance widget in Phase 25, also note for Phase 28.

## Analytics

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight tracking | cert_alert_opened, cert_renewed_after_alert events | ✓ |
| No analytics | Skip tracking | |

## Timezone Handling

| Option | Description | Selected |
|--------|-------------|----------|
| UTC | Date-only, no timezone shift | |
| User's local timezone | Resolve from project location | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Project location | Infer TZ from project city/state | ✓ |
| User profile timezone | TZ field on user profile | |

## Additional Areas

| Area | Decision |
|------|----------|
| Project activity | Cert alerts show in project activity timeline |
| Data retention | Same as other notifications |
| Cert document attachment | Optional attachment prompt on renewal |
| Notification grouping | Grouped per member (primary), digest in structured logs |
| Cert type taxonomy | Suggested + free-text (autocomplete from CERT_NAMES) |
| Error states | Log and continue on partial failures |
| Bell count | Included in HeaderBell unread badge |
| Scheduling | Fixed daily 13:15 UTC |
| Cert priority | All equal, sorted by urgency |
| Notification preferences | Mandatory, no opt-out (deferred) |
| Snooze | Deferred to future phase |
| Push format | Title + body + subtitle split |
| visionOS | Shared adaptive layout |
| CarPlay | Push + CPTemplate cert status tab |
| Regulatory references | No OSHA citations in copy |
| Cert sharing | Deferred — single org only |
| UI animations | Subtle pulse for day-of and expired |
| Cross-org certs | Deferred to future phase |
| Cert compliance export | Deferred to reporting phase |
| Batch renewal | Deferred to future phase |

## Claude's Discretion

- Exact column names beyond specified
- Loading skeleton design for cert list
- Animation timing and easing
- CarPlay CPTemplate layout details
- Admin status badge placement
- Cert compliance widget visual design
- Grouping threshold for "close together" expiries

## Deferred Ideas

- Batch cert renewal
- Cert sharing between orgs
- Snooze/remind-me-later
- Per-category notification preferences
- Email/SMS delivery channels
- Cert compliance report export
- Spatial visionOS dashboard
- Cert verification against registries
- Cert type priority tiers
