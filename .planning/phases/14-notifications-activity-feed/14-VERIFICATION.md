---
phase: 14-notifications-activity-feed
verified: 2026-04-19T15:55:00Z
status: partial
score: 2/5 must-haves verified, 3/5 unsatisfied with evidence
re_verification: false
human_verification:
  - test: "Open a project's Activity tab on web (/projects/[id]/activity) after uploading a document via Phase 13 UI"
    expected: "Chronological activity timeline shows the document_uploaded event with the DOC badge, filename, and historical indicator if the event is from the backfill. Also shows project/RFI/change-order events per Phase 14-01 triggers."
    why_human: "End-to-end document → activity fanout depends on the Phase 24 trigger being deployed remotely; visual confirmation of the DOC badge, DETAIL_LABELS rendering, and ordering requires a browser walk-through"
  - test: "iOS: install build on a real device, accept the notification permission prompt, sign in, and trigger a cert-expiry event by setting a cs_certifications.expires_at 30 days in the future"
    expected: "iOS receives an APNs push via the Phase 25 cert-expiry-scan Edge Function with the VIEW_CERT category action; tapping the notification opens the Certifications tab"
    why_human: "NOTIF-05 end-to-end delivery cannot be verified on simulator (APNs only works on real devices unless simctl push is used); also requires the Apple Developer portal Push Notifications capability toggle (14-05-SUMMARY.md)"
---

# Phase 14: Notifications & Activity Feed Verification Report

**Phase Goal (ROADMAP.md line 80):** Users see what changed, what needs attention, and what's coming due.

**Verified:** 2026-04-19T15:55:00Z
**Status:** partial (D-02 honest verdict — 2 satisfied + 3 unsatisfied with specific evidence)
**Re-verification:** No — initial verification (created by Phase 28 retroactive sweep)
**Score:** 2/5 must-haves verified, 3/5 unsatisfied with evidence

> **D-02 disclosure:** This VERIFICATION.md ships an honest partial verdict per the Phase 28 CONTEXT.md directive. NOTIF-02 and NOTIF-04 are marked **Satisfied** because the code is present AND the cross-phase gap each depended on has been closed (Phase 24 for NOTIF-02, Phase 25 for NOTIF-04). NOTIF-01, NOTIF-03, and NOTIF-05 are marked **UNSATISFIED** — code is present but the ROADMAP success criteria are not met end-to-end due to missing UI completeness and unverified iOS push delivery. Phase 28 does NOT implement the missing requirements; remediation is delegated to a new ROADMAP phase appended by Plan 28-02.

## Goal Achievement

### Observable Truths

| # | Truth (from ROADMAP.md success criteria lines 84-88) | Status | Evidence |
|---|-------|--------|----------|
| 1 | User sees a notification list with an unread count badge (NOTIF-01) | UNSATISFIED | **iOS half is present but web half is incomplete.** iOS: `InboxView.swift` exists with unread count and mark-read flow (14-04-SUMMARY.md lines 9-10); `NotificationsStore.displayBadge` handles 99+ cap per D-13; header bell in `LayoutChrome.swift` `HeaderView` exposes badge. BUT per 14-04-SUMMARY.md Known Limitation #4 "InboxView project filter is not exposed in the UI yet." Web: `grep -l 'NotificationsStore\|InboxView' web/src/app/` returns **0 files** — the iOS inbox-style UI was never mirrored on web as a functional equivalent. Web has `/inbox/page.tsx` and `HeaderBell.tsx` but per 14-03-SUMMARY.md Known Limitation #1: "the per-row mark-read form submits as POST to `/api/notifications/[id]?_method=PATCH` — the API route only exports PATCH/DELETE, so the form will need a small JS shim or a dedicated `/mark-read` POST endpoint to fully wire up." NOTIF-01's "unread count badge" is half-done: iOS shows the badge but lacks the filter chooser D-12 requires; web shows a bell but the inbox page's mark-read interaction is broken by its own summary's admission. |
| 2 | User can view a chronological activity timeline per project (NOTIF-02) | VERIFIED | iOS: `ProjectActivityView` in `ready player 8/ProjectsView.swift` (6 references) renders day-grouped activity events via `SupabaseService.fetchActivityEvents` — 14-04-SUMMARY.md. Web: `web/src/app/projects/[id]/activity/page.tsx` exists (14-03-SUMMARY.md). **Gap to this truth closed by Phase 24**: document routes originally did not emit cs_activity_events (INT-02 per audit), leaving the feed empty for document ops. Phase 24 `emit_document_activity_event()` trigger on cs_documents + cs_document_attachments resolves this — cite `.planning/phases/24-document-activity-event-emission/24-01-SUMMARY.md` (trigger + backfill) and `24-02-SUMMARY.md` (ENTITY_LABELS + DETAIL_LABELS + DOC badge rendering, 7 vitest rendering tests green). Page + code + downstream fanout now all flow end-to-end for the document domain. |
| 3 | User can mark notifications as read individually or all at once (NOTIF-03) | UNSATISFIED | API surface exists on both platforms but **web UI exercising mark-read is broken by documented limitation.** iOS: `SupabaseService.markNotificationRead`, `markAllNotificationsRead` present (14-04-SUMMARY.md Files Modified section); InboxView provides swipe-to-dismiss + toolbar Mark All Read. Web: `markRead`, `markAllRead`, `dismiss` helpers exist in `web/src/lib/notifications.ts` + `PATCH /api/notifications/[id]` + `POST /api/notifications/mark-all-read`; BUT 14-03-SUMMARY.md Known Limitation #1 (verbatim): "the per-row mark-read form submits as POST to `/api/notifications/[id]?_method=PATCH` — the API route only exports PATCH/DELETE, so the form will need a small JS shim or a dedicated `/mark-read` POST endpoint to fully wire up." Net effect: a web user clicking a per-row mark-read button does NOT mark the row read. Mark-all-read form on web does work (POST endpoint matches). **Unsatisfied as shipped** — web per-row UI is broken; iOS side alone does not satisfy the ROADMAP goal which is implicitly both-platforms. Remediation: dedicated POST alias route + client-side fetch wrapper (14-03-SUMMARY.md Known Limitations #1 Recommended option B). |
| 4 | User can dismiss notifications (NOTIF-04) | VERIFIED | iOS: `markNotificationDismissed` in SupabaseService.swift; swipe-to-dismiss in InboxView (14-04-SUMMARY.md). Web: soft-delete via `dismiss` helper + `DELETE /api/notifications/[id]` (14-03-SUMMARY.md D-11). **Cert-dismiss suppress pattern** (D-02-adjacent closure): Phase 25 layers `suppress_user_ids` on payload so dismissed cert alerts don't re-fire — cite `.planning/phases/25-certification-expiry-notifications/25-01-SUMMARY.md` (payload-marker dedupe + suppress_user_ids) and `25-02-SUMMARY.md` (fanout consumption). NOTIF-04 is owned by Phase 25 in REQUIREMENTS.md traceability but cited here for completeness. |
| 5 | User receives iOS push notifications for bid deadlines, safety alerts, and assigned tasks (NOTIF-05) | UNSATISFIED | **Entitlement present, end-to-end push delivery unverified.** `grep -c 'aps-environment' 'ready player 8/ready player 8.entitlements'` = **1** (development environment configured). AppDelegate callbacks wired: `didRegisterForRemoteNotificationsWithDeviceToken` → `SupabaseService.upsertDeviceToken` (14-05-SUMMARY.md Files Modified). Edge Function `notifications-fanout` routes PUSH_CATEGORIES via APNs HTTP/2 (14-02-SUMMARY.md). HOWEVER per 14-05-SUMMARY.md "Manual Steps Required Before Push Delivery Works" — "The `.entitlements` file alone does NOT enable Push Notifications on the App ID in Apple's developer portal. Without this step, APNs will reject device tokens with `BadDeviceToken`." Steps 1–6 on https://developer.apple.com/account/resources/identifiers/list need a human click. This is the **literal "missing iOS push registration" gap** that CONTEXT.md D-02 names. No evidence exists on file that the portal step was completed; no recorded real-device push delivery test result. Ship as UNSATISFIED per D-02. |

**Score:** 2/5 truths verified (NOTIF-02, NOTIF-04). 3/5 truths unsatisfied with specific evidence (NOTIF-01, NOTIF-03, NOTIF-05).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `supabase/migrations/20260407_phase14_notifications.sql` | cs_notifications, cs_activity_events, cs_device_tokens, cs_project_members + trigger | VERIFIED | File present; 5 triggers attached per 14-01-SUMMARY.md (cs_projects, cs_contracts, cs_rfis, cs_change_orders, cs_daily_logs); webhook `notifications-fanout` on cs_activity_events INSERT wired in Dashboard |
| `supabase/migrations/20260407001_phase14_notifications_rls.sql` | 9 RLS policies across 4 tables | VERIFIED | File present (HANDOFF.md confirms "all 4 new tables, 9 policies") |
| `supabase/migrations/20260407002_phase14_pgcron_schedule.sql` | pg_cron at 13:00 UTC daily | VERIFIED | File present; idempotent unschedule guard (14-02-SUMMARY.md) |
| `supabase/functions/notifications-fanout/index.ts` | Fanout Edge Function with APNs HTTP/2 | VERIFIED | 14-02-SUMMARY.md; 10/10 Deno tests pass including `apns.test.ts` JWT signing |
| `supabase/functions/notifications-schedule/index.ts` | Nightly bid-deadline scanner | VERIFIED | 14-02-SUMMARY.md |
| `web/src/lib/notifications.ts` | Server helpers + Realtime | VERIFIED | Exists; 14-03-SUMMARY.md; 11/11 vitest green |
| `web/src/app/api/notifications/route.ts` | GET unread + list | VERIFIED | Exists |
| `web/src/app/api/notifications/[id]/route.ts` | PATCH mark-read + DELETE dismiss | VERIFIED | Exists |
| `web/src/app/api/notifications/mark-all-read/route.ts` | POST mark-all-read with optional filter | VERIFIED | Exists |
| `web/src/app/inbox/page.tsx` | Server-component inbox | PRESENT BUT INSUFFICIENT | Exists but per 14-03-SUMMARY.md the per-row mark-read form is mis-wired — blocks NOTIF-03 as shipped |
| `web/src/app/projects/[id]/activity/page.tsx` | Activity timeline | VERIFIED | Exists; Phase 24 extended rendering |
| `web/src/app/components/HeaderBell.tsx` | Client bell + realtime | VERIFIED | Exists; 14-03-SUMMARY.md |
| `ready player 8/NotificationsStore.swift` | @MainActor polling store | VERIFIED | Exists; 20-second polling fallback (14-04 Deviation #1); 11 Swift Testing cases |
| `ready player 8/InboxView.swift` | iOS inbox list | PRESENT BUT INSUFFICIENT | Exists; swipe-dismiss + mark-read works BUT project filter UI not exposed per 14-04-SUMMARY.md Known Limitation #4 |
| `ready player 8/ready player 8.entitlements` | aps-environment + app-sandbox | PRESENT BUT INSUFFICIENT | `aps-environment=development` set (14-05-SUMMARY.md); Apple Developer portal Push Notifications toggle STILL UNVERIFIED — blocks NOTIF-05 end-to-end |
| `ready player 8Tests/NotificationsStoreTests.swift` | 11 assertions | VERIFIED | Exists (14-04) |
| `ready player 8Tests/InboxViewTests.swift` | 11 assertions | VERIFIED | Exists (14-04) |
| `ready player 8Tests/APNsRegistrationTests.swift` | 6 hex-encoder tests | VERIFIED | Exists (14-05) |

### Key Link Verification

All greps executed at commit `fe96de7` on 2026-04-19T15:55:00Z.

| Command | Expected | Actual | Status |
|---------|----------|--------|--------|
| `grep -l 'cs_notifications' supabase/migrations/ \| wc -l` | ≥ 1 | **3 files** (phase14 notifications.sql, phase14_notifications_rls.sql, phase25_cert_renewal_trigger.sql) | PASS |
| `grep -l 'cs_activity_events' supabase/migrations/ \| wc -l` | ≥ 1 | **5 files** (phase14 x2, phase24 x1, phase25 x1, phase26 x1) | PASS — confirms cross-phase event flow |
| `grep -c 'NotificationsStore' 'ready player 8/NotificationsStore.swift'` | ≥ 1 | **3** | PASS |
| `grep -c 'fetchUnreadCount' 'ready player 8/SupabaseService.swift'` | ≥ 1 | **1** | PASS |
| `grep -c 'aps-environment' 'ready player 8/ready player 8.entitlements'` | 1 | **1** | PASS (but see NOTIF-05 disclaimer: entitlement alone is insufficient) |
| `grep -l 'NotificationsStore\|InboxView' web/src/app/ \| wc -l` | 0 expected | **0** | PASS — confirms the web half of NOTIF-01 was never mirrored from iOS |
| `grep -l 'markNotificationRead\|markAllNotificationsRead' web/src/` | ≥ 1 | **5 files** (api routes + lib helpers + tests) | PASS (API exists; UI wiring still broken per 14-03 Known Limitation #1) |
| `grep -c 'ProjectActivityView' 'ready player 8/ProjectsView.swift'` | ≥ 1 | **6** | PASS |

### Behavioral Spot-Checks

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Shared build + lint evidence | Cite `.planning/phases/28-retroactive-verification-sweep/28-01-EVIDENCE.md` @ commit `fe96de7` timestamp `2026-04-19T15:46:17Z` | iOS BUILD SUCCEEDED; web lint exit 0; web build exit 0 | PASS |
| Phase 14 vitest (notifications) | `cd web && npx vitest run src/lib/notifications/` | **3 files / 11 tests passed (0 fail)** @ 254ms | PASS |
| iOS test compile | Cite 28-01-EVIDENCE.md — NotificationsStoreTests, InboxViewTests, APNsRegistrationTests all compile under the shared xcodebuild run | BUILD SUCCEEDED | PASS |
| Deno function tests | 14-02-SUMMARY.md: `apns.test.ts` + `index.test.ts` report 10/10 passing (JWT signing, 410 stale-token, push-category gating) | PASS (cite-only) | PASS |

## Integration Gap Closure

| Gap ID | Description | Status | Closed By / Evidence |
|--------|-------------|--------|----------------------|
| INT-02 | Documents do not emit activity events — Phase 14 activity feed empty for document ops (affects NOTIF-02) | CLOSED | Phase 24 — cite `.planning/phases/24-document-activity-event-emission/24-01-SUMMARY.md` (emit_document_activity_event trigger on cs_documents + cs_document_attachments) + `24-02-SUMMARY.md` (DETAIL_LABELS + DOC badge + 7 rendering tests). |
| INT-06 (affecting NOTIF-04) | Cert expiration does not trigger notifications | CLOSED | Phase 25 — cite `.planning/phases/25-certification-expiry-notifications/25-01-SUMMARY.md` (multi-threshold Edge Function + cert renewal trigger + payload-marker dedupe) + `25-02-SUMMARY.md` (cert-specific push copy + VIEW_CERT APNs category). |

## Dependent Requirements Status

| Requirement | Before | After | Evidence |
|-------------|--------|-------|----------|
| **NOTIF-01** — Unread count badge | Pending | **UNSATISFIED** | iOS inbox-store-and-bell present but project filter UI missing (14-04 KL #4); web has no NotificationsStore/InboxView equivalent (grep returns 0 files). Honest verdict per D-02 — remediation deferred to a new ROADMAP phase per D-10. |
| **NOTIF-02** — Per-project activity timeline | Pending | **Satisfied** | Web /projects/[id]/activity + iOS ProjectActivityView exist AND INT-02 closed via Phase 24 trigger. |
| **NOTIF-03** — Mark as read | Pending | **UNSATISFIED** | Web per-row mark-read is mis-wired (14-03 KL #1); iOS works but single-platform does not satisfy the cross-platform success criterion. Honest verdict per D-02. |
| **NOTIF-04** — Dismiss notifications | Pending | **Satisfied** | iOS swipe-to-dismiss + web DELETE endpoint + Phase 25 suppress_user_ids chain. Owned by Phase 25 per REQUIREMENTS.md traceability. |
| **NOTIF-05** — iOS push notifications | Pending | **UNSATISFIED** | aps-environment entitlement set; AppDelegate wired; Edge Function routes pushes; BUT Apple Developer portal toggle + real-device delivery never recorded (14-05 "Manual Steps Required"). Literal D-02 gap. Honest verdict — remediation requires a human with access to the Apple Developer account. |

## Nyquist Note

Per `v2.0-MILESTONE-AUDIT.md` Nyquist Coverage table, **14-VALIDATION.md is missing entirely** (unlike Phases 13/15/16/17/19 which have draft VALIDATION.md). Recommend `/gsd-validate-phase 14` to create it. Out of scope for Phase 28 per D-12.

## Deviations from Plan

### D-02 Honest-verdict rule applied

Three of five requirements ship as **UNSATISFIED** despite code being present because the code is necessary but not sufficient to meet the ROADMAP success criterion end-to-end:

- **NOTIF-01:** UI completeness gap — iOS filter picker missing; web UI mirror missing.
- **NOTIF-03:** UI completeness gap — web per-row mark-read form submits to the wrong method (confirmed by 14-03-SUMMARY.md Known Limitation #1's own words).
- **NOTIF-05:** Out-of-band verification gap — requires Apple Developer portal Push Notifications capability toggle + a real-device delivery test, neither of which are recorded anywhere on disk. Plus a 14-05-SUMMARY.md-listed deviation (#4) deferring notification-tap deep-link routing.

Remediation for each cluster is delegated to a NEW ROADMAP phase that Plan 28-02 will append (per D-10). Phase 28 does not implement any of the missing functionality.

### D-03 Hybrid closure credit applied

- NOTIF-02 verification cites Phase 24 SUMMARYs for the INT-02 closure — no re-verification of the trigger SQL or the activity-feed rendering tests.
- NOTIF-04 verification cites Phase 25 SUMMARYs for the cert-notification + dismiss-suppress chain.

### Web-side NotificationsStore parity gap documented, not fixed

The `grep -l 'NotificationsStore\|InboxView' web/src/app/` returning 0 files is noted as expected evidence of the NOTIF-01 gap, not as a divergence that needs fixing in Phase 28. The new ROADMAP phase emerging from Plan 28-02 will decide whether web needs a full inbox parity UI or a lighter bell+dropdown.

---

_Verified: 2026-04-19T15:55:00Z_
_Verifier: Claude (gsd-executor running plan 28-01) — honest partial verdict per D-02_
_Evidence anchors: 28-01-EVIDENCE.md @ commit `fe96de7`, 24-01-SUMMARY.md + 24-02-SUMMARY.md (INT-02), 25-01-SUMMARY.md + 25-02-SUMMARY.md (INT-06 / NOTIF-04)_
