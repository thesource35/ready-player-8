# Launch Runbook — ConstructionOS

> Sequential checklist for taking the app from "code-ready" to "publicly
> launched." Steps 1-6 in `.planning/ROADMAP.md` 999.x discussion, expanded
> with exact commands + screenshots' worth of detail.
>
> Last updated: 2026-05-07.

## Pre-flight: pick canonical domain

The codebase has 3 different `constructionos.*` domains in source
(35 `.world`, 15 `.com`, 11 `.app`). Before anything else, decide:

- **Recommended canonical: `constructionos.com`** — universal, App Store-friendly,
  shortest, easy for users to type
- Register `.app` and `.world` defensively (~$50/yr total) but redirect them to `.com`
- After step 1, I (Claude) will sweep the source replacing `.app` and `.world`
  references with `.com` in a single commit

If you pick a different canonical, just tell me which one — the sweep is
mechanical regardless.

---

## Step 1 — Register domains

**Status:** ☐ Not started ☐ In progress ☐ Done

### What to do
1. Pick a registrar — recommended: **Cloudflare** (at-cost pricing, free DNS)
2. Register all 3:
   - `constructionos.com` (~$10/yr)
   - `constructionos.app` (~$14/yr, requires HTTPS by default)
   - `constructionos.world` (~$22/yr)
3. Use a real email you check — registrar contact must be reachable
4. Turn on **auto-renew** on `.com` (don't let it lapse and get squatted)
5. Turn on **WHOIS privacy** (free at most registrars)

### Confirmation
- All 3 domains show in your registrar's dashboard
- You can see the DNS panel for each (need this for step 2)

---

## Step 2 — Verify `.com` with Resend (email sender)

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Step 1 must be complete

### What to do
1. Sign in to Resend dashboard: https://resend.com/domains
2. Click **Add Domain** → enter `constructionos.com`
3. Resend will show 3-5 DNS records (TXT for SPF/DKIM/DMARC, MX for receiving)
4. In Cloudflare (or your registrar's DNS panel), add each record EXACTLY as Resend specifies
5. Back in Resend, click **Verify DNS Records** — should turn green within minutes (DNS propagation)

### Confirmation
- Resend dashboard shows `constructionos.com` with green "Verified" badge
- Test send: in Resend dashboard, click your domain → "Send test email" → enter your inbox → arrives in seconds

### Common gotchas
- TXT records: Cloudflare wraps values in quotes automatically — paste WITHOUT quotes
- DKIM record name is long (e.g., `resend._domainkey.constructionos.com`) — paste the full name
- DMARC: leave at minimum `v=DMARC1; p=none` initially; tighten to `quarantine` once delivery is confirmed working

---

## Step 3 — Deploy support/privacy pages at the canonical domain

**Status:** ☑ Code done — pages exist at `/support`, `/privacy`, `/terms`
**Blocker:** Domain must point at Vercel deployment (covered by step 4)

### What's ALREADY done in code
- `web/src/app/support/page.tsx` — Support page with email contacts
- `web/src/app/privacy/page.tsx` — 11-section privacy policy
- `web/src/app/terms/page.tsx` — Terms of service
- `web/public/logo.png` — used by email templates (commit 701507b)

### What you need to do
1. After step 4 sets `constructionos.com` to point at the Vercel deploy, visit:
   - https://constructionos.com/support → should render the support page
   - https://constructionos.com/privacy → should render the privacy page
2. If anything looks off, tell me and I'll fix in source — both are Next.js routes, easy to update

### Note for Apple submission
- Apple requires Privacy URL to be publicly accessible (no auth)
- Apple requires Support URL to be publicly accessible
- Both `/support` and `/privacy` are public routes (no auth gate) — confirmed

---

## Step 4 — Set `NEXT_PUBLIC_APP_URL` env var on Vercel

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Step 1 + 2 must be done (domain reachable)

### What to do
1. Sign in to Vercel: https://vercel.com/dashboard
2. Open the ConstructionOS project (`thesource35/ready-player-8`)
3. **Settings → Domains:**
   - Click **Add Domain** → `constructionos.com`
   - Vercel will show DNS records to add — for Cloudflare, set the `A` and/or `AAAA` records as instructed (or use a `CNAME` to `cname.vercel-dns.com`)
   - Add `www.constructionos.com` too (Vercel will offer to set up the redirect)
   - Repeat for `constructionos.app` and `constructionos.world` if you want them all routed (see canonical domain note above — usually you'd 301-redirect `.app` and `.world` to `.com`)
4. **Settings → Environment Variables:**
   - Add `NEXT_PUBLIC_APP_URL` with value `https://constructionos.com`
   - Apply to: Production (and Preview + Development if you want consistent behavior)
5. **Trigger a fresh deploy** so the new env var is baked in:
   - Either push any commit, or click **Deployments → ... → Redeploy** on the latest

### Confirmation
- `https://constructionos.com` loads the ConstructionOS web app
- Network tab shows requests to the same origin (no fallback APP_URL warnings in console)

---

## Step 5 — NOTIF-05 push test on physical iPhone

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Need iPhone 15 Pro Max + Supabase anon key

### What to do
1. **On Mac (Supabase dashboard):**
   - Open https://supabase.com/dashboard/project/nzdbphddnrfybwecvsvq/settings/api
   - Find "Project API keys" → row labeled `anon` `public` (`eyJ...` JWT, NOT `sb_publishable_*`)
   - Click Copy icon
   - Paste into a new note in iCloud Notes (so it syncs to iPhone)

2. **On iPhone:**
   - Open Notes → wait for the new note to sync → long-press the JWT → Copy
   - Open ConstructionOS app
   - On AuthGateView, tap the **green ✓ "Backend configured"** row (with pencil icon — Phase 30.1 c)
   - BackendConfigSheet opens — Base URL should already show `https://nzdbphddnrfybwecvsvq.supabase.co`
   - Tap Anon API Key field → long-press → Paste → tap **Save**
   - Sheet closes; you're back on AuthGateView
   - Sign in with your real Supabase credentials → land on ContentView

3. **Tell me you're signed in** — I'll guide:
   - Verify `cs_device_tokens` got a fresh row
   - Trigger a server-side test push from the dashboard or via SQL
   - Verify push arrives on lock screen

### Confirmation
- Test push notification appears on iPhone lock screen
- AUTH-GATE-04 fully closed
- 999.5 (j) in ROADMAP can be marked done

---

## Step 6 — Resubmit App Store build

**Status:** ☐ Not started ☐ In progress ☐ Done
**Blocker:** Steps 1-5 complete

### What to do
1. **In Xcode:**
   - Open `ready player 8.xcodeproj`
   - Confirm bundle identifier: `nailed-it-network.ready-player-8`
   - **Product → Archive** (with Release config + iOS device target)
   - Wait for archive to complete (~5-10 min)

2. **In Organizer (opens automatically after archive):**
   - Select the archive → **Distribute App** → App Store Connect → Upload
   - Wait for upload + processing (5-30 min)

3. **In App Store Connect (https://appstoreconnect.apple.com):**
   - Open the ConstructionOS app
   - Verify the new build appears under TestFlight or App Store tab
   - **App Privacy:**
     - Set Privacy Policy URL: `https://constructionos.com/privacy`
   - **App Information:**
     - Set Support URL: `https://constructionos.com/support`
     - Set Marketing URL: `https://constructionos.com` (optional but recommended)
   - **Submit for Review** with the new build selected

### Confirmation
- App Store Connect shows status: "Waiting for Review" (then "In Review" → "Approved" → "Pending Developer Release" or "Ready for Sale")
- Apple's review usually takes 1-3 days

---

## Post-launch follow-ups (in priority order)

After app is in App Store:

1. **999.10 — Fix CI iOS testing** (1-2 hours): currently CI iOS build silently no-ops. Fix via `maxim-lobanov/setup-xcode@v1` or `arduino/xcodes-action`. Until done, **iOS verification depends on local `xcodebuild test` before each push.**

2. **999.9 — React Compiler refactor pass** (1 day): 92 ESLint warnings currently downgraded. Do the proper refactor when you have a focused window.

3. **Schema FK refactor** (`.planning/drafts/cs_schedule_events_cs_todos_fk_refactor.sql`): answers 4 open questions, then apply. Unlocks proper team collaboration on cs_todos + cs_schedule_events.

4. **Multi-tenancy runtime test enablement**: existing test in
   `web/src/__tests__/multi-tenancy/rls-isolation.test.ts` is skipped by
   default. Add `SUPABASE_TEST_*` env vars to a staging Supabase + flip
   the test on in CI.

5. **PR #1 (ECC bot bundle)**: review + merge or close. From March 31, stale.

---

## Quick reference: what's in code vs what needs your action

| Item | Code state | Your action |
|---|---|---|
| Domain registration | N/A | Step 1 |
| Resend `from` addresses | Hardcoded `noreply@constructionos.com`, `reports@constructionos.com` | Verify domain (step 2) |
| Email logo | Points at `https://constructionos.com/logo.png` (commit 701507b) | Confirm logo.png is served when domain goes live |
| Support/Privacy/Terms pages | Built (Next.js routes) | Step 4 (Vercel deploy) |
| Fallback `NEXT_PUBLIC_APP_URL` | Defaults to `https://constructionos.com` | Step 4 (set env var to override) |
| App Store Privacy/Support URLs | Documented in `docs/AppStore-Metadata.md` as `constructionos.app/*` | Step 6 (set in App Store Connect — recommend `constructionos.com/*` instead for consistency) |
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

The Status checkboxes at the top of each step (☐ / ☑) are how you mark
your own progress. Update them as you go.
