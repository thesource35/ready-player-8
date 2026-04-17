# Phase 25: Certification Expiry Notifications - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Close INT-06 and FLOW-02: make certification expiration trigger the full escalating notification cadence (30 / 7 / day-of / weekly post-expiry) through the existing Phase 14 notification pipeline. Expand the cert-expiry-scan Edge Function, add UI urgency indicators, deep-linking, renewal CTAs, and cross-platform parity (iOS, web, visionOS, CarPlay push + status tab). Includes lightweight MCP tool for Angelic AI and cert compliance widget for reporting.

Does NOT cover: batch cert renewal, cert sharing between orgs, snooze/remind-me-later, per-category notification preferences, email/SMS delivery (but architecture is channel-agnostic for future), cert compliance report export (deferred to reporting phase).

</domain>

<decisions>
## Implementation Decisions

### Escalation Thresholds & Cadence
- **D-01:** Expand cert-expiry-scan Edge Function from single 30-day check to full cadence: **30 days, 7 days, day-of, weekly post-expiry**. Post-expiry pings continue indefinitely until cert status becomes `active` (renewed) or row is deleted.
- **D-02:** **Dedupe via payload marker** — no new side table. Store `threshold` key in `cs_activity_events.payload` alongside `cert_id` and `expires_at`. Query for existing event where `payload->>'cert_id' = X AND payload->>'threshold' = '7' AND payload->>'expires_at' = Y`. The `expires_at` in the payload scopes dedupe to each expiry cycle, so a renewed cert with a new `expires_at` naturally gets a fresh cadence.
- **D-03:** **Paginated batch processing** — process certs in batches of 100 with cursor-based pagination. Timeout guard: track elapsed time per batch, bail out after 50 seconds with structured log of unprocessed cert_ids for next run.
- **D-04:** **Rate cap per run** — limit to 200 activity events per scan run. If exceeded, process most urgent thresholds first (day-of > 7-day > 30-day > post-expiry). Log warning.

### Notification Content & Copy
- **D-05:** **All thresholds send push** — every threshold fires both push (APNs) and in-app inbox. Visual severity stays uniform; **copy escalates**: "expires in 30 days" → "expires in 7 days" → "expires today" → "has expired".
- **D-06:** **Group by member** — one notification per member per threshold sweep. E.g., "John Doe: OSHA 30 + Forklift expire in 7 days". Reduces noise when multiple certs share a threshold.
- **D-07:** **Specific names in copy** — include member name and cert names in both push and inbox notifications. Actionable without opening the app.
- **D-08:** **Static post-expiry copy** — weekly pings use the same text: "John Doe: OSHA 30 has expired". No escalating duration counter.
- **D-09:** **No regulatory references** — keep notifications action-focused. No OSHA citations or jurisdiction-specific claims.
- **D-10:** **Push notification format** — Title: "Cert Expiring in 7 Days". Body: "John Doe: OSHA 30 + Forklift". Subtitle: project name if assigned. Uses APNs alert.title / alert.body / alert.subtitle split.

### Dismiss & Suppress Behavior
- **D-11:** **Dismiss suppresses future pings** for that cert at the current threshold level, per-user only. Dismissing a 30-day alert suppresses further 30-day repeats for that user, but the 7-day threshold still fires. Other recipients (other PMs) are NOT affected — each user's dismiss is independent.
- **D-12:** Dismiss remains a soft delete via `dismissed_at` (Phase 14 D-11 pattern). Edge Function checks for dismissed notifications per user before inserting new events.

### Recipient Resolution
- **D-13:** Recipients = (a) the member's linked internal `user_id` if present (or `created_by` user for external members), AND (b) **all PMs on all active projects** the member is assigned to. A member on 5 projects → all 5 project PMs get alerted.
- **D-14:** **PM defined by role_on_project** — case-insensitive match on `role_on_project` containing "project manager" or "PM". Also always include `created_by` of the project.
- **D-15:** If member is unassigned from all projects, alerts still fire to the `created_by` user. The cert is still expiring — someone should know.

### iOS & Web UI
- **D-16:** **Deep-link from notification to specific cert** — tapping navigates to CertificationsView with the cert highlighted/scrolled-to. On web: `/team/certifications?highlight={certId}`. On iOS: navigate to Team tab → Certifications sub-view with cert_id passed.
- **D-17:** **Full cold-launch deep-link support** — handle `userNotificationCenter(_:didReceive:)` in app delegate to navigate on cold launch from push.
- **D-18:** **Inline urgency badges on cert cards** — green (>30d), amber (7–30d), red (≤7d or expired). Calculated locally from cached cert data (works offline). Both iOS CertificationsView and web `/team/certifications`.
- **D-19:** **Summary banner at top** of CertificationsView / web cert page: "2 expiring within 30 days · 1 expired". Tapping scrolls to relevant certs.
- **D-20:** **Renewal CTA on both** notification row AND cert card — "Update Cert" button opens edit form with `expires_at` and optional document attachment (Phase 13 integration).
- **D-21:** **Full web parity** — web gets urgency badges, renewal CTA, summary banner, deep-linking. HeaderBell notification rows also get renewal CTA.
- **D-22:** **Cert alerts count in HeaderBell unread badge** — standard Phase 14 unread query naturally includes cert notifications. No separate badge.
- **D-23:** **Cert alerts appear in project activity timeline** — activity events have project_id from assignment resolution, so they naturally show in per-project Activity tab.
- **D-24:** **Subtle pulse animation** for day-of and expired cert badges on iOS. 30-day and 7-day badges are static colored. Web: CSS animation equivalent.

### Push Notification Categories
- **D-25:** **Distinct `cert-expiry` APNs category** with "View Cert" action button on lock screen. Uses Phase 14 push infrastructure but adds the custom category for cert-specific UX.

### Timezone Handling
- **D-26:** **Evaluate expiry in user's local timezone** — resolve timezone from the project's location (city/state). Falls back to UTC if no project assignment or no location data. The scan compares `expires_at` against `now()` in the resolved timezone.

### Migration Strategy
- **D-27:** **Fire only the most urgent threshold** for existing certs when first deployed. A cert expiring in 5 days gets only the 7-day alert, not the missed 30-day. Avoids notification flood on deployment day. Future thresholds fire normally.

### Cert Renewal Workflow
- **D-28:** **Edit in place** — tapping "Update Cert" opens the existing cert form pre-filled. User updates `expires_at`, optionally attaches new document scan (Phase 13 document_id FK). Status auto-flips to `active` on save.
- **D-29:** **Optional document attachment prompt** — cert edit form shows "Attach new cert scan" button using Phase 13 document picker. Not required to save.
- **D-30:** **Cert renewal emits activity event** — AFTER UPDATE trigger on `cs_certifications` fires an activity event when status flips to `active`, showing "John Doe renewed OSHA 30" in project activity. Closes the alert-to-resolution loop.

### Cert Name Taxonomy
- **D-31:** **Suggested + free-text** — autocomplete suggestions from existing `CERT_NAMES` list (OSHA 10, OSHA 30, First Aid/CPR, Forklift, Crane Operator, MEWP, Welding). Free-text entry allowed for regional/specialty certs.

### Edge Cases
- **D-32:** **Cert deleted mid-escalation** — clean up orphaned notifications. Mark related notifications as dismissed when cert row is deleted.
- **D-33:** **Full restart on re-expiry** — renewed cert with new `expires_at` gets a fresh full cadence (30/7/1/weekly). Payload markers scoped by `expires_at` prevent collision with old cycle.

### Channel Future-Proofing
- **D-34:** **Channel-agnostic events** — activity event payload includes `delivery_channels` array (e.g., `['push', 'inbox']`). Fanout reads this to decide delivery. Adding email/SMS later is a fanout change only.

### Angelic AI Integration
- **D-35:** **Add `get_expiring_certs` MCP tool** — queries `cs_certifications` for certs expiring within N days. Enables "which certs expire this month?" queries. Low effort, reuses existing MCP pattern from `get_crew_deploy`.

### Reporting Dashboard
- **D-36:** **Cert compliance widget** — add a lightweight cert compliance widget to Phase 19 reporting showing expiry trends, expired count, renewal rate. Also noted for Phase 28 verification review.

### Logging & Observability
- **D-37:** **Structured JSON summary per run** — `{ scanned: N, alerts_created: N, skipped_dedupe: N, skipped_dismissed: N, errors: N, elapsed_ms: N, batches: N }`. No PII in logs.
- **D-38:** **Admin-only status badge** — "Last cert scan: 2h ago, 5 alerts sent" on Team or Settings page. Visible only to admin-role users.

### Error Handling
- **D-39:** **Log and continue** on partial failures — if one cert fails (DB error, fanout timeout), log error with cert_id and continue. Failed certs retried on next daily run since their dedupe markers weren't created.

### Offline / Sync
- **D-40:** **Local urgency calculation** — CertificationsView calculates urgency badges locally from cached cert data (`expires_at` vs today). Works offline. Notifications require connectivity but visual urgency is independent.
- **D-41:** **Natural sync catch-up** — missed notifications appear retroactively when device reconnects. Existing Supabase Realtime subscription handles this.

### Multi-Org
- **D-42:** **RLS handles org isolation** — scan runs with service-role. Fanout inserts into `cs_notifications` with RLS. Recipients resolved via project membership (already org-scoped). No extra org logic in scan.

### Accessibility
- **D-43:** **Semantic VoiceOver labels** — urgency badges get labels like "Expiring in 7 days — warning" or "Expired — critical". Summary banner reads as "Alert: 2 certifications expiring within 30 days, 1 expired". Color supplemented, not sole indicator.

### Platform Support
- **D-44:** **visionOS** — shared adaptive CertificationsView layout. Urgency badges work as-is. No spatial-specific work.
- **D-45:** **CarPlay** — push notifications delivered natively via APNs. Add a CPTemplate cert status tab showing expiring/expired count summary.

### Analytics
- **D-46:** **Lightweight analytics tracking** — `cert_alert_opened`, `cert_renewed_after_alert` events via existing `AnalyticsEngine`. Measures alert effectiveness.

### Testing & Verification
- **D-47:** **Unit tests + contract tests** for Edge Function — expand `index.test.ts` with cases for each threshold (30/7/1/post-expiry), dedupe via payload marker, grouping by member, dismiss-suppress behavior. Contract test verifying activity_event payload shape matches fanout expectations.
- **D-48:** **XCTest for iOS** — urgency color calculation (given `expires_at`, return green/amber/red) and deep-link payload parsing (given notification `userInfo`, return correct `cert_id` + nav target).
- **D-49:** **Vitest for web** — mirror iOS test coverage: urgency color function + deep-link URL construction for `/team/certifications?highlight={id}`.
- **D-50:** **Dismiss-suppress unit test** — mock `cs_notifications` query to return dismissed row, assert function skips that cert's threshold.
- **D-51:** **Manual test plan** — document checklist: seed cert with `expires_at = today+30`, trigger cron manually, verify notification in inbox + push received. Repeat for each threshold.

### Scheduling
- **D-52:** **Fixed daily pg_cron at 13:15 UTC** — keep existing schedule. Cert expiry is date-level; more frequent runs add no value.

### Cert Priority
- **D-53:** **All cert types equal priority** — sort alerts by urgency (threshold closeness), not by cert type.

### Notification Preferences
- **D-54:** **Cert alerts are mandatory** — no opt-out. Deferred to future per-category preferences phase.

### Data Retention
- **D-55:** **Same retention as other notifications** — follow Phase 14 policy. Cert alerts aren't special.

### Claude's Discretion
- Exact column names beyond what's specified
- Loading skeleton design for cert list
- Exact animation timing and easing for pulse effect
- CarPlay CPTemplate layout details
- Admin status badge placement (Team tab vs Settings)
- Cert compliance widget visual design for reporting dashboard
- Grouping threshold for "close together" cert expiries (same day? same week?)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & Roadmap
- `.planning/REQUIREMENTS.md` §TEAM-04 — "User receives alerts when certifications are nearing expiration"
- `.planning/REQUIREMENTS.md` §NOTIF-04 — "User can dismiss notifications"
- `.planning/ROADMAP.md` §"Phase 25: Certification Expiry Notifications" — Goal, dependencies (Phase 14, 15), gap closure (INT-06, FLOW-02)

### Upstream phase context (MUST read)
- `.planning/phases/14-notifications-activity-feed/14-CONTEXT.md` — Notification pipeline architecture: D-02 (triggers), D-03 (fanout), D-14 (APNs), D-15 (device tokens), D-16 (push categories), D-17 (pg_cron + Edge Function pattern)
- `.planning/phases/15-team-crew-management/15-CONTEXT.md` — Cert model: D-04 (cs_certifications table), D-05 (escalating cadence spec), D-06 (recipient resolution chain)
- `.planning/phases/24-document-activity-event-emission/24-CONTEXT.md` — Activity event emission pattern for cert renewal events (D-30)

### Existing code touchpoints
- `supabase/functions/cert-expiry-scan/index.ts` — **Primary target**: expand from 30-day-only to full cadence
- `supabase/functions/cert-expiry-scan/index.test.ts` — Expand with threshold/dedupe/grouping tests
- `supabase/migrations/20260408001_phase15_pgcron_cert_sweep.sql` — Existing pg_cron schedule (13:15 UTC daily)
- `supabase/functions/notifications-fanout/index.ts` — Fanout pipeline that delivers to inbox + APNs
- `ready player 8/CertificationsView.swift` — Add urgency badges, summary banner, renewal CTA, pulse animation
- `ready player 8/SupabaseService.swift` — Cert CRUD methods, SupabaseCertification DTO
- `ready player 8/ContentView.swift` — Deep-link routing from push notification to cert
- `ready_player_8App.swift` — Cold-launch deep-link handler (userNotificationCenter didReceive)
- `ready player 8/MCPServer.swift` — Add get_expiring_certs MCP tool
- `web/src/app/team/certifications/page.tsx` — Web urgency badges, summary banner, renewal CTA, deep-link highlight
- `web/src/app/components/HeaderBell.tsx` — Cert alerts included in unread count naturally
- `web/src/app/projects/[id]/activity/page.tsx` — Cert events appear in project activity

### External docs
- Apple APNs — custom notification categories with action buttons
- Apple CarPlay — CPTemplate for cert status tab
- Supabase Edge Functions — batch processing, timeout handling

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `cert-expiry-scan/index.ts` — working Edge Function, needs threshold expansion (currently 30-day only)
- `notifications-fanout/index.ts` — complete fanout pipeline (inbox + APNs), ready to receive cert events
- `CertificationsView.swift` — license-card layout with `licenseCard()`, `CERT_NAMES` array, `AddCertSheet`
- `SupabaseService` — generic REST client with cert CRUD (`SupabaseCertification` DTO)
- `Theme` struct — `Theme.green`, `Theme.accent` (amber), `Theme.red` for urgency colors
- `AnalyticsEngine.shared` — analytics tracking singleton for cert alert events
- `MCPServer.swift` — existing MCP tools pattern (`get_crew_deploy`, `get_crew_schedule`)
- `HeaderBell.tsx` — web notification bell with unread count badge

### Established Patterns
- Supabase table prefix: `cs_*`
- Activity events: immutable `cs_activity_events` log → fanout → `cs_notifications` per-user
- pg_cron → Edge Function pattern (Phase 14 + Phase 15 both use this)
- Payload marker dedupe via `cs_activity_events.payload` JSON querying
- Monolithic file tolerance per CLAUDE.md
- AppStorage key namespace: `ConstructOS.{Feature}.{Property}`

### Integration Points
- Phase 14 notification pipeline: triggers → activity events → fanout → inbox + APNs
- Phase 15 `cs_certifications` table: source data for expiry scan
- Phase 13 `cs_documents`: cert document attachment via `document_id` FK
- Phase 24 activity emission: cert renewal events use same AFTER UPDATE trigger pattern
- Project activity timeline: cert events show via `project_id` in activity events
- CarPlay scene in `ready_player_8App.swift`: add CPTemplate for cert status

</code_context>

<specifics>
## Specific Ideas

- Cert alerts should feel like calendar reminders, not spam — group by member when multiple certs expire close together (Phase 15 specifics)
- Push notification should be scannable on lock screen: Title/Body/Subtitle split with cert names and project
- "Update Cert" button should feel as natural as editing a contact — pre-filled form, one tap to save
- Urgency badges should be immediately visible without scrolling — summary banner at top gives instant situational awareness
- Day-of and expired badges get subtle pulse animation to draw attention without being distracting
- Deep-link from push must work on cold launch — foreman taps notification from lock screen and lands on the exact cert
- Local urgency calculation ensures badges work on construction sites with poor connectivity

</specifics>

<deferred>
## Deferred Ideas

- **Batch cert renewal** — multi-select renewal after company-wide training days (future phase)
- **Cert sharing between orgs** — subcontractor certs visible across GC orgs (major multi-tenancy feature)
- **Snooze/remind-me-later** — Phase 14 explicitly deferred this
- **Per-category notification preferences** — Phase 14 deferred; cert alerts are mandatory for now
- **Email/SMS delivery channels** — architecture is channel-agnostic (D-34) but delivery is push + inbox only
- **Cert compliance report export (PDF/CSV)** — deferred to reporting phase
- **Spatial visionOS cert dashboard** — shared adaptive layout instead
- **Cert verification against external registries** — Phase 15 deferred
- **Cert type priority tiers** — all certs treated equally, sorted by urgency

### Reviewed Todos (not folded)
None — no pending todos matched this phase.

</deferred>

---

*Phase: 25-certification-expiry-notifications*
*Context gathered: 2026-04-17*
