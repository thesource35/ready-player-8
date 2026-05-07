# Launch Runbook — ConstructionOS

> Sequential checklist for taking the app from "code-ready" to "publicly
> launched." Steps 1-6 are the canonical critical path; everything else is
> post-launch.
>
> Last updated: 2026-05-07.

## Canonical domain: `constructionos.world`

Decided 2026-05-07. Source code now uses `constructionos.world` everywhere
(swept all `.com` and `.app` references in commit on 2026-05-07).

Defensive registrations of `.com` and `.app` are recommended (~$25/yr
combined) to prevent typo-squatting / brand confusion, but they are NOT
required for launch — just 301-redirect them to `.world` if you register.

---

## Step 1 — Register `constructionos.world`

**Status:** ☐ Not started ☐ In progress ☐ Done

### What to do
1. Pick a registrar — recommended: **Cloudflare** (at-cost pricing, free DNS, integrates cleanly with Vercel)
2. Register `constructionos.world` (~$22/yr at Cloudflare)
3. (Optional defensive) Also register `constructionos.com` (~$10/yr) and `constructionos.app` (~$14/yr) — set them up to 301-redirect to `.world`
4. Use a real email you check — registrar contact must be reachable for renewal + ICANN verification
5. Turn on **auto-renew** (don't let `.world` lapse and get squatted)
6. Turn on **WHOIS privacy** (free at most registrars)

### Confirmation
- `constructionos.world` shows in your Cloudflare dashboard
- DNS panel for `.world` is accessible (you'll need it for steps 2 + 4)

---

## Step 2 — Verify `constructionos.world` with Resend

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Step 1 must be complete

### What to do
1. Sign in to Resend dashboard: https://resend.com/domains
2. Click **Add Domain** → enter `constructionos.world`
3. Resend shows 3-5 DNS records (TXT for SPF/DKIM, optional MX for receiving, optional TXT for DMARC)
4. In Cloudflare DNS panel for `constructionos.world`, add each record EXACTLY as Resend specifies
5. Back in Resend, click **Verify DNS Records** — should turn green within minutes (DNS propagation)

### Confirmation
- Resend dashboard shows `constructionos.world` with green "Verified" badge
- Test send: in Resend dashboard, click your domain → "Send test email" → enter your inbox → arrives within seconds

### Common gotchas
- TXT record values: Cloudflare auto-wraps in quotes — paste WITHOUT quotes
- DKIM record name is long (e.g., `resend._domainkey.constructionos.world`) — paste the FULL name into the Cloudflare "Name" field
- DMARC: start at `v=DMARC1; p=none` (monitoring only). Tighten to `p=quarantine` after a week of confirmed delivery, then `p=reject` once you're confident

---

## Step 3 — Support / Privacy / Terms pages

**Status:** ☑ Code done — pages exist as Next.js routes
**Blocker:** Domain must point at Vercel deploy (covered by step 4)

### What's ALREADY done in code
- `web/src/app/support/page.tsx` — Support page with email contacts at `*@constructionos.world`
- `web/src/app/privacy/page.tsx` — 11-section privacy policy with CCPA/GDPR rights
- `web/src/app/terms/page.tsx` — Terms of service
- `web/public/logo.png` + `logo-sm.png` — used by emails + nav

### What you need to do
1. After step 4 sets `constructionos.world` to point at the Vercel deploy, visit:
   - https://constructionos.world/support → should render the support page
   - https://constructionos.world/privacy → should render the privacy page
   - https://constructionos.world/terms → should render the terms page
2. If anything looks off, tell me — both are Next.js routes, easy to update

### Note for Apple submission
- Apple requires Privacy URL to be publicly accessible (no auth)
- Apple requires Support URL to be publicly accessible (no auth)
- Both `/support` and `/privacy` are public routes (no auth gate) — confirmed

---

## Step 4 — Vercel: attach domain + set `NEXT_PUBLIC_APP_URL`

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Step 1 must be complete (DNS-controllable domain)

### What to do
1. Sign in to Vercel: https://vercel.com/dashboard
2. Open the ConstructionOS project (linked to `thesource35/ready-player-8`)
3. **Settings → Domains:**
   - Click **Add Domain** → enter `constructionos.world` → Vercel shows DNS records
   - In Cloudflare, add the records (typically a `CNAME` for `www.constructionos.world` → `cname.vercel-dns.com`, and `A`/`AAAA` for the apex via Vercel's listed IPs OR a Cloudflare flatten/proxy)
   - Add both `constructionos.world` AND `www.constructionos.world` (Vercel will offer to auto-redirect www → apex or vice versa)
   - If you also registered `.com` and `.app`, add them too with 301-redirect to `https://constructionos.world`
4. **Settings → Environment Variables:**
   - Add `NEXT_PUBLIC_APP_URL` with value `https://constructionos.world`
   - Apply to: **Production** (also Preview + Development if you want consistent behavior across envs)
5. **Trigger a fresh deploy** so the new env var bakes in:
   - Either push any commit (auto-deploys), OR click **Deployments → ⋯ → Redeploy** on the latest

### Confirmation
- `https://constructionos.world` loads the ConstructionOS web app
- Browser network tab shows requests resolving to the same origin
- No "fallback APP_URL" warnings in any logged email body or console

---

## Step 5 — NOTIF-05 push test on physical iPhone

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** iPhone 15 Pro Max + access to Supabase dashboard

### What to do
1. **On Mac (Supabase dashboard):**
   - Open https://supabase.com/dashboard/project/nzdbphddnrfybwecvsvq/settings/api
   - Find "Project API keys" → row labeled **`anon` `public`** (the `eyJ...` JWT, NOT `sb_publishable_*`)
   - Click the Copy icon
   - Paste into a new note in iCloud Notes (so it syncs to your iPhone)

2. **On iPhone:**
   - Open Notes → wait for the new note to sync → long-press the JWT → Copy
   - Open ConstructionOS app
   - On AuthGateView, tap the **green ✓ "Backend configured"** row (with pencil icon — this is Phase 30.1 (c))
   - BackendConfigSheet opens — Base URL should already show `https://nzdbphddnrfybwecvsvq.supabase.co`
   - Tap Anon API Key field → long-press → Paste → tap **Save**
   - Sheet closes; you're back on AuthGateView
   - Sign in with your real Supabase credentials → land on ContentView

3. **Tell me you're signed in** — I'll guide:
   - Verify `cs_device_tokens` got a fresh row (SQL: `SELECT * FROM cs_device_tokens WHERE user_id = '<your-uid>' ORDER BY created_at DESC LIMIT 1`)
   - Trigger a server-side test push (via Supabase dashboard SQL editor calling the notifications-fanout edge function)
   - Verify push arrives on iPhone lock screen

### Confirmation
- Test push notification appears on iPhone lock screen
- AUTH-GATE-04 fully closed (REQUIREMENTS.md flips from `[~]` to `[x]`)
- 999.5 (j) in ROADMAP marked done

---

## Step 6 — Resubmit App Store build

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Steps 1-5 complete

### What to do
1. **In Xcode:**
   - Open `ready player 8.xcodeproj`
   - Confirm bundle identifier: `nailed-it-network.ready-player-8`
   - **Product → Archive** (Release config, generic iOS device target)
   - Wait ~5-10 min for archive to complete

2. **In Organizer (opens automatically post-archive):**
   - Select the new archive → **Distribute App** → **App Store Connect** → **Upload**
   - Wait for Apple's processing (5-30 min — they re-encode the binary)

3. **In App Store Connect (https://appstoreconnect.apple.com):**
   - Open the ConstructionOS app entry
   - Verify the new build appears under TestFlight or the active App Store version
   - **App Privacy:**
     - Privacy Policy URL: `https://constructionos.world/privacy`
   - **App Information:**
     - Support URL: `https://constructionos.world/support`
     - Marketing URL: `https://constructionos.world` (optional, recommended)
   - **Submit for Review** with the new build selected

### Confirmation
- App Store Connect shows status: "Waiting for Review" → "In Review" (1-3 days) → "Approved" → "Pending Developer Release" or "Ready for Sale"

---

## Post-launch follow-ups (priority order)

After app is in App Store + email is delivering:

1. **999.10 — Fix CI iOS test pipeline** (1-2 hours): currently silently no-ops on macos-15 runner. Fix via `maxim-lobanov/setup-xcode@v1` + `xcodes runtimes install`. Until done: **iOS verification depends on `xcodebuild test` running locally before each push.**

2. **999.9 — React Compiler refactor pass** (1 day): 92 ESLint warnings currently downgraded. Refactor `useEffect setState` patterns + `react-hooks/refs|purity|immutability` violations.

3. **Schema FK refactor** (`.planning/drafts/cs_schedule_events_cs_todos_fk_refactor.sql`): answer 4 open questions, then apply. Unlocks proper team collaboration on cs_todos + cs_schedule_events.

4. **Multi-tenancy runtime test enablement**: existing test in `web/src/__tests__/multi-tenancy/rls-isolation.test.ts` is skipped by default. Add `SUPABASE_TEST_*` env vars to a staging Supabase + flip the test on in CI.

5. **PR #1 (ECC bot bundle)**: review + merge or close. From March 31, stale.

---

## What's in code vs what needs your action

| Item | Code state | Your action |
|---|---|---|
| Domain registration | N/A | Step 1 |
| Resend `from` addresses | `noreply@constructionos.world`, `reports@constructionos.world` (swept 2026-05-07) | Verify domain (step 2) |
| Email logo | Points at `https://constructionos.world/logo.png` | Confirm logo.png is served when domain goes live (step 4) |
| Support/Privacy/Terms pages | Built (Next.js routes) | Step 4 (Vercel deploy) |
| Fallback `NEXT_PUBLIC_APP_URL` | Defaults to `https://constructionos.world` | Step 4 (set env var to override) |
| App Store Privacy/Support URLs | Will be set in App Store Connect | Step 6 — use `constructionos.world/*` |
| iOS push notifications | Code green; UAT deferred | Step 5 |
| CI for iOS | Silently no-ops (999.10) | Post-launch fix |

---

## Resume checklist for a fresh session

If you come back to this and don't remember where you left off:

```bash
# Check what's done
gh run list --branch main --limit 3       # CI status
git log --oneline -15                      # recent commits
cat .planning/STATE.md                     # current state
cat .planning/LAUNCH-RUNBOOK.md            # this file
```

Update the `☐` / `☑` checkboxes at the top of each step as you complete them.
