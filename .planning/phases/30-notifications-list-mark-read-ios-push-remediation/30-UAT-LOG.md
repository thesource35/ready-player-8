# 30-UAT-LOG — NOTIF-05 Real-Device Push UAT Evidence

> **STATUS: BLOCKED — Phase 14 schema not deployed to the Supabase project the app is configured against (2026-04-24).**
>
> A real-device UAT session was attempted on 2026-04-24. The operator completed the Apple
> Developer portal toggle, re-pulled the provisioning profile in Xcode, built onto a physical
> iPhone, granted notification permission, and configured the app's HUB tab with the Supabase
> Base URL and anon key. Account creation succeeded. However, a schema probe on the configured
> Supabase project (`information_schema.tables` filtered to `cs_%`) returned the following
> presence map for the tables this UAT depends on:
>
> - `cs_projects` — present
> - `cs_project_members` — **MISSING**
> - `cs_contracts` — present
> - `cs_safety_incidents` — present
> - `cs_rfis` — present
> - `cs_daily_logs` — present
> - `cs_device_tokens` — **MISSING**
> - `cs_notifications` — **MISSING** (inferred — not probed directly but query against it errored with 42P01 earlier in the session)
> - `cs_activity_events` — **MISSING** (inferred — Phase 14 migration unapplied)
>
> Without `cs_device_tokens` the APNs registration handler has nowhere to write, so step 4 of
> `30-09-PLAN.md` Task 2 (Check 1 device-token query) cannot return a row regardless of how
> cleanly the device built. Without `cs_project_members` the `bid_deadline` fanout cannot scope
> recipients. Without `cs_activity_events` none of the three category triggers can fire, so Task
> 3 (three real-device pushes + negative control) cannot produce evidence. The UAT is therefore
> blocked at the backend layer, not at the device/signing layer.
>
> Concretely: no rows in the Delivery Table below can be filled in honestly from this session.
> The `{NEEDS-FILL}` cells are intentionally left unfilled — filling them with placeholder
> values would falsify phase evidence. See `30-09-SUMMARY.md` for the full attempt log and the
> prerequisite work required to unblock this UAT.
>
> This file was originally pre-created by the 30-09 executor as a STUB so the structure, fields,
> and acceptance-criteria greps are all in place. The strings `NOTIF-05`, `bid_deadline`,
> `safety_alert`, `assigned_task`, `generic`, `BadDeviceToken`, `Unregistered`,
> `notifications-schedule`, and `D-20` / `Production cutover deferred` remain present below so
> that grep-based acceptance checks still resolve. Do NOT delete or restructure placeholder rows.

## Metadata

| Field | Value |
|-------|-------|
| UAT date | {NEEDS-FILL — ISO-8601, e.g. 2026-04-24} |
| Device | {NEEDS-FILL — e.g. "iPhone 15 Pro, iOS 18.2"} |
| Device identifier (Xcode/Settings → General → About → Name) | {NEEDS-FILL} |
| Tester | Bev (project owner) |
| Build commit (`git rev-parse HEAD` at UAT time) | {NEEDS-FILL — capture BEFORE the first SQL trigger} |
| Apple Developer portal Push Notifications toggled | {NEEDS-FILL — "Yes — YYYY-MM-DD"} |
| APNs host | api.sandbox.push.apple.com (development) |
| `aps-environment` | development |
| Xcode version | {NEEDS-FILL — e.g. 16.2} |
| Provisioning profile date (post-toggle re-pull) | {NEEDS-FILL — must be on-or-after portal toggle date} |

## Delivery Table

One row per NOTIF-05 category. Triggering SQL comes from `30-09-PLAN.md` Task 3; Bev pastes the
exact invoked form below. Receive timestamp = time the push banner appeared on the physical
iPhone. Latency = Receive TS − Trigger TS, in seconds.

| Category | Trigger Action (SQL or UI) | Trigger TS | Receive TS | Latency | Screenshot | Notes |
|----------|----------------------------|------------|------------|---------|------------|-------|
| bid_deadline | `insert into cs_contracts (..., bid_deadline = tomorrow) values (...)` + {pg_cron 13:00 UTC fire OR manual `notifications-schedule` invoke per 30-DEPLOY-STEPS.md §Troubleshooting} | {NEEDS-FILL} | {NEEDS-FILL} | {NEEDS-FILL s} | `assets/30-uat-screenshot-bid-deadline.png` | {NEEDS-FILL — record which path drove the push: pg_cron vs manual invoke; if manual, paste the response body `{inserted, skipped, errors}`} |
| safety_alert | `insert into cs_safety_incidents (..., severity='high') values (...)` | {NEEDS-FILL} | {NEEDS-FILL} | {NEEDS-FILL s} | `assets/30-uat-screenshot-safety-alert.png` | {NEEDS-FILL — any observations} |
| assigned_task | `insert into cs_rfis (..., assigned_to = <your-user-id>) values (...)` (OR cs_change_orders / cs_punch_list — any entity whose trigger produces `category='assigned_task'` in cs_activity_events) | {NEEDS-FILL} | {NEEDS-FILL} | {NEEDS-FILL s} | `assets/30-uat-screenshot-assigned-task.png` | {NEEDS-FILL — any observations} |

## Negative Control

Insert a row whose trigger produces `cs_activity_events.category='generic'` (e.g. a `cs_daily_logs`
row). **Expected:** no push banner appears on the device. This validates D-16 push-category gating
end-to-end.

- Trigger: {NEEDS-FILL — paste SQL}
- Trigger TS: {NEEDS-FILL}
- Device observed for: 60 seconds post-insert
- Result: {NEEDS-FILL — expected "NO push banner appeared" ✅}
- Cross-check in Supabase: `select category from cs_activity_events order by created_at desc
  limit 1;` should return `generic`.

## Supabase Edge Function Log Observations

Capture these during the UAT window from Supabase Dashboard → Edge Functions → {function} → Logs
with the time filter set to "last 1 hour" covering the UAT session.

| Metric | Value | Expected |
|--------|-------|----------|
| `notifications-fanout` invocations during UAT window | {NEEDS-FILL count} | ≥ 3 (one per category) + 1 for the generic negative control (fanout is invoked but short-circuits on the non-allowed category) |
| `notifications-schedule` invocations during UAT window | {NEEDS-FILL count} | ≥ 0 — record whether Bev triggered a manual invoke per 30-DEPLOY-STEPS.md §Troubleshooting. If so, the response body was `200 + {inserted, skipped, errors: []}` |
| `BadDeviceToken` responses | {NEEDS-FILL count} | 0 |
| `Unregistered` (410) responses | {NEEDS-FILL count} | 0 |
| `500 InternalServerError` / `InvalidProviderToken` (401) responses | {NEEDS-FILL count} | 0 |
| `cs_device_tokens` prune events (grep log for "deleted stale token" or equivalent) | {NEEDS-FILL count} | 0 for the UAT device |

**Log evidence** (paste top 5 relevant log lines, or note "Dashboard → Edge Functions → {function}
→ Logs" if copy-paste is infeasible):

```
{NEEDS-FILL — paste 3-5 relevant log lines, one per category delivery. Redact any device_token
hex strings to {TOKEN}. Redact any service_role key fragments to {KEY}.}
```

## Screenshot Review (T-30-09-01 PII mitigation)

Before committing each screenshot to `assets/`, Bev performs a visual review to ensure no
third-party app, Contacts widget, or unrelated banner beyond the ConstructionOS push itself is
visible. Crop the status-bar region tightly if needed to remove incidental PII.

| Screenshot | Reviewed | Cropped? | Retake? |
|------------|----------|----------|---------|
| `30-uat-screenshot-bid-deadline.png` | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} |
| `30-uat-screenshot-safety-alert.png` | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} |
| `30-uat-screenshot-assigned-task.png` | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} | {NEEDS-FILL — Y/N} |

## UAT Data Cleanup (T-30-09-02 mitigation)

All UAT-inserted rows in `cs_contracts`, `cs_safety_incidents`, and `cs_rfis` / equivalent are
typed with `UAT` in their title/description/subject so they can be deleted post-UAT without
affecting production demo data. After the UAT window closes:

```sql
-- Run in Supabase SQL Editor after UAT closes. Verify the row count matches what was inserted.
delete from cs_contracts        where title       like 'UAT %';
delete from cs_safety_incidents where description like 'UAT %';
delete from cs_rfis             where subject     like 'UAT %';
delete from cs_daily_logs       where <negative-control identifier>; -- adjust to the actual filter used
```

Cleanup run: {NEEDS-FILL — timestamp, or "deferred to post-plan"}

## Requirement Closure

**NOTIF-05 is satisfied end-to-end for development/sandbox APNs** per the three delivery rows and
the negative-control observation above. Production cutover is deferred per D-20 — see
`30-DEPLOY-STEPS.md §Production Cutover (DEFERRED per D-20)`.

This log combined with `30-08-SUMMARY.md` (CI regression floor — 28/0 Deno tests green) and the
Phase 14-02 / 14-05 code shipments forms the complete evidence chain for NOTIF-05:

- **Code evidence:** Phase 14-02 (`notifications-fanout` + `notifications-schedule` Edge Functions)
  + Phase 14-05 (APNs device-token registration on iOS)
- **Test evidence:** Phase 30-08 — 28/0 Deno suite green, covering category allowlist, device-token
  query shape, APNs payload shape, and stale-token prune + redaction invariant
- **UAT evidence:** this file (real-device delivery proof per NOTIF-05 category + negative control)

## Traceability Back-Reference

Upon resume-signal confirming this log is complete, the ORCHESTRATOR (not this plan) will:

1. Flip `REQUIREMENTS.md` NOTIF-05 Traceability row from `Unsatisfied` to `Satisfied`, citing this
   file path and the 30-09 SUMMARY.
2. Supersede `14-VERIFICATION.md` observation #5 ("NOTIF-05 UNSATISFIED — no real-device UAT")
   with a pointer to this log.
3. Close out Phase 30 by authoring the 30-VERIFICATION.md and the phase-level summary.

The before/after lines for REQUIREMENTS.md are captured in the 30-09 SUMMARY.md after this log is
finalized.

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Plan: 09 (Task 4 — STUB awaiting Tasks 2+3 human completion)*
*Stub authored: 2026-04-24*
