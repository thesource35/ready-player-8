# 30-DEPLOY-STEPS — Operator Runbook: Apple Developer Portal Push Capability + UAT Push Invocation

## Purpose

This file exists because one step in shipping APNs push delivery for ConstructionOS cannot be automated: the
**Push Notifications** capability on the App ID `nailed-it-network.ready-player-8` must be toggled by a
human in the Apple Developer portal. Apple does not publish an API for App ID capability toggling
(origin: Phase 30 `30-CONTEXT.md §D-19`). This runbook exists so Bev (project owner) can perform that
one-time step and the follow-on fresh-device build without guesswork, then manually trigger a
`bid_deadline` push during UAT when the pg_cron scheduler window has not yet fired.

Scope: **development / sandbox APNs only** (`aps-environment=development`). Production cutover is
explicitly deferred per D-20 — see §Production Cutover below.

## Preconditions

- Active Apple Developer account with admin/member access to the Apple ID that owns the
  `nailed-it-network.ready-player-8` bundle identifier
- Xcode 16.2+ installed locally on this machine
- A real iPhone running iOS 18.2+ paired to the same Apple ID (Simulator is insufficient — APNs
  sandbox only delivers pushes to real devices; origin: `30-CONTEXT.md §D-18`)
- `aps-environment=development` already set in `ready player 8/ready player 8.entitlements`
  (confirmed shipped in Phase 14-05; verified by inspection at 30-09 authoring time)
- Supabase project URL + `service_role` key accessible from Supabase Dashboard → Project Settings → API
  (required ONLY for §Troubleshooting manual invoke — not for the main runbook flow)

## Step-by-Step

Do these in order. Do not skip steps. Screenshot each result if helpful for the UAT log.

1. Open https://developer.apple.com/account/resources/identifiers/list in a browser. Sign in with
   the Apple Developer account that owns the bundle identifier.
2. In the Identifiers list, click `nailed-it-network.ready-player-8`.
3. Scroll to the **Capabilities** section (located below the App ID description block).
4. Find the **Push Notifications** row. Check the checkbox on the left edge of that row.
5. Click **Save** at the top-right of the page.
6. A confirmation dialog warns that the provisioning profile will be regenerated. Click **Save**
   again (or **Continue**, depending on the portal version) to confirm.
7. Return to Xcode. Open `ready player 8.xcodeproj`.
8. Select the `ready player 8` target → **Signing & Capabilities** tab. Under **Automatically manage
   signing**, if the checkbox is already checked, uncheck it and re-check it to force a
   provisioning-profile re-pull. Otherwise, check it.
9. Verify that Xcode pulls the updated provisioning profile. You should see a brief progress
   indicator under "Provisioning Profile"; the resulting profile name should include "Push" or be
   dated today. If it is NOT dated today, see §Troubleshooting → "No provisioning profile found".
10. Plug in the real iPhone via USB. Trust the computer if prompted on the device.
11. Select the device from Xcode's run destination dropdown (top-center of Xcode, next to the Play
    button).
12. Press `Cmd+R` to build and run on the device. Wait for the app to launch on the iPhone.
13. When iOS shows the "ConstructionOS Would Like to Send You Notifications" prompt, tap **Allow**.

## Verification Checkpoints

Run these three SQL queries in Supabase Dashboard → SQL Editor. Expected results are noted inline.
Do NOT paste raw token values into the UAT log (T-30-09-04 mitigation — only query the columns shown).

```sql
-- Check 1: confirm a device token was uploaded after step 13
select user_id, platform, app_version, last_seen_at
from cs_device_tokens
order by last_seen_at desc
limit 5;
-- Expected: at least one row with your user_id + platform='ios' + last_seen_at ~= now()
```

```sql
-- Check 2: after Task 3 triggers a push (e.g. inserting a contract with bid_deadline 1 day out),
-- confirm a cs_notifications row was created
select id, user_id, category, title, body, created_at
from cs_notifications
where user_id = '<your-user-id>'
order by created_at desc
limit 10;
-- Expected: at least one row with category in ('bid_deadline','safety_alert','assigned_task')
-- and created_at within the last 30 minutes
```

```sql
-- Check 3: confirm no BadDeviceToken prune happened for your device in the UAT window
select user_id, platform, app_version, last_seen_at
from cs_device_tokens
where user_id = '<your-user-id>';
-- Expected: row still present (no prune → APNs accepted the token)
```

## Troubleshooting

### "No provisioning profile found" in Xcode after the portal toggle
- Reopen Xcode → target → Signing & Capabilities.
- Toggle **Automatically manage signing** off, wait 2 seconds, toggle it on again.
- Ensure the Team dropdown shows the same Apple ID that owns the bundle.
- If still failing: Xcode → Settings → Accounts → select the Apple ID → **Download Manual
  Profiles**.

### "No push received" on the device after a triggering action
- Open Supabase Dashboard → Edge Functions → **notifications-fanout** → Logs. Look for APNs errors.
- If you see `status=401 reason=InvalidProviderToken`, the Supabase secrets `APNS_AUTH_KEY`,
  `APNS_KEY_ID`, or `APNS_TEAM_ID` may be stale (Phase 14-02 scope — OUT OF SCOPE for this plan).
- If you see `status=400 reason=BadDeviceToken` for YOUR device token specifically, the capability
  toggle in steps 3-6 may not have saved. Re-visit the portal (step 1) and confirm the checkbox
  shows as checked **without hovering** — the portal sometimes shows an unsaved preview on hover.
  Save again and redo steps 7-13.

### "Still rejected with BadDeviceToken even after a fresh build"
- Delete the app from the iPhone (long-press → Remove App → Delete App).
- Reinstall via `Cmd+R` from Xcode.
- Grant notification permission on first launch.
- Re-run Check 1 (Verification Checkpoints). If `last_seen_at` is still stale, the token registration
  handler in `ready_player_8App.swift` may need inspection — that is Phase 14-05 scope, not this plan.

## Troubleshooting: Forcing a bid_deadline push during UAT

**Why this section exists:** The `bid_deadline` category is produced by the `notifications-schedule`
Edge Function, which normally runs via `pg_cron` at **13:00 UTC daily**. If UAT happens outside
that window (which is typical), Bev must invoke the function manually. Follow **one** of the two
paths below; Path A is the Supabase Dashboard click-path (recommended), Path B is a shell fallback.

Contract verified against `supabase/functions/notifications-schedule/index.ts` at 30-09 authoring
time: the handler reads only request headers, accepts `{}` body, returns HTTP 200 with
`{ inserted, skipped, errors }`.

### Path A — Supabase Dashboard (recommended)

1. Open https://supabase.com/dashboard and select the `ready-player-8` project.
2. Left sidebar → **Edge Functions**.
3. Click the `notifications-schedule` function.
4. In the function detail page, click the **Invoke** tab (or **Test** button, depending on
   dashboard version).
5. Configure the request:
   - **Method:** `POST`
   - **Headers:** add one row:
     - Name: `Authorization`
     - Value: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}` — paste the literal value from Project Settings
       → API → `service_role` key. The function handler accepts any header value that CONTAINS the
       service-role key (implementation uses `auth.includes(serviceKey)`); `Bearer <key>` is the
       canonical form.
   - **Headers:** add a second row:
     - Name: `Content-Type`
     - Value: `application/json`
   - **Body (JSON):** `{}` — the function reads no body; an empty JSON object is the minimum valid
     payload for the Invoke form.
6. Click **Send** / **Invoke**.
7. **Expected response:**
   - HTTP status: `200`
   - JSON body: `{ "inserted": <n>, "skipped": <n>, "errors": [] }`
   - `inserted` should be `≥ 1` if you created a `cs_contracts` row earlier in Task 3 with
     `bid_deadline` (or `bid_due`, depending on schema) set to today, tomorrow, or 3 days out.
   - `skipped > 0` is normal (the function's de-dupe guard).
   - A non-empty `errors` array indicates a DB access issue — copy the message into 30-UAT-LOG.md
     and stop the UAT until it is resolved.
8. Within ~10 seconds, the inserted `cs_activity_events` row(s) will fan out through the Database
   Webhook → `notifications-fanout` path and deliver the push to your device.

**Unauthorized response (HTTP 401, body `unauthorized`):** the Authorization header is missing or
does not contain the service-role key. Fix the header and retry.

### Path B — shell fallback (if the dashboard Invoke tab is unavailable)

```bash
# Replace <YOUR-PROJECT-REF> with the project ref from Supabase Dashboard → Project Settings → General.
# Set SUPABASE_SERVICE_ROLE_KEY in your shell BEFORE running; do NOT paste the literal key here.

curl -i -X POST \
  "https://<YOUR-PROJECT-REF>.supabase.co/functions/v1/notifications-schedule" \
  -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected: `HTTP/2 200` followed by `{"inserted":<n>,"skipped":<n>,"errors":[]}`. Unauthorized →
`HTTP/2 401` + body `unauthorized`.

### Precondition for the invoke to produce a push for YOU specifically

For the manual invoke to actually deliver a push to your UAT device, two things must already be true:

- A `cs_contracts` row must exist with `bid_deadline` (or the schema's equivalent `bid_due` field)
  equal to today, tomorrow, or 3 days out — the function's scheduler windows are `[0, 1, 3]` days
  out, per `notifications-schedule/index.ts`.
- That contract's `project_id` must point to a project where **you are a member** (i.e. a row exists
  in `cs_project_members` for your `user_id` and the contract's `project_id`).

Without both, the function returns `inserted: 0` and no push fires. If you have not already inserted
the UAT contract, run the Category 1 SQL from the 30-09 plan (Task 3) first, then come back to this
runbook and invoke the function.

## Production Cutover (DEFERRED per D-20)

- This runbook targets **development / sandbox** APNs only:
  - `aps-environment=development` in the entitlements
  - APNs host: `api.sandbox.push.apple.com`
  - Development APNs auth key
- Production cutover requires flipping `aps-environment` to `production`, repointing the Edge
  Function to `api.push.apple.com`, installing a production APNs auth key, and running a TestFlight
  smoke pass.
- Production cutover is **NOT on the current v2.1 roadmap** per D-20. Do NOT flip
  `aps-environment=production` for this UAT.
- A future phase (tracked separately from this milestone) will own the production cutover.

## References

- Phase 14-05 SUMMARY §"Manual Steps Required Before Push Delivery Works" — origin of the
  capability-toggle gap closed by this runbook
- Phase 30 `30-CONTEXT.md` §D-18 (real-device UAT requirement), §D-19 (capability toggle authority),
  §D-20 (production cutover deferral)
- Phase 30-08 `30-08-SUMMARY.md` — defense-in-depth Deno tests on `notifications-fanout` that assure
  push-path regressions are caught in CI before reaching this runbook
- `ready player 8/ready player 8.entitlements` — authoritative `aps-environment=development` source
- `supabase/functions/notifications-schedule/index.ts` — authoritative contract for the manual-invoke
  Authorization header + `{}` body + `{inserted, skipped, errors}` response documented in
  §Troubleshooting: Forcing a bid_deadline push during UAT

---
*Phase: 30-notifications-list-mark-read-ios-push-remediation*
*Plan: 09 (Task 1)*
*Authored: 2026-04-24*
