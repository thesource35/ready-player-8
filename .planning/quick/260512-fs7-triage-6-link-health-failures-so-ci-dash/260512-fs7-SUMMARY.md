---
phase: quick-260512-fs7
plan: 01
status: complete
completed: 2026-05-12
---

# Quick 260512-fs7 Summary — link-health triage

## 4 Tasks Executed

| Task | Action | Verdict |
|---|---|---|
| 1 | Added `knownExceptions` array + `findKnownException()` helper + `skipped` status to `web/scripts/link-health.mjs` | PASS (9 grep invariants + syntax check + logic test) |
| 2 | Fixed dozr URL in `ready player 8/RentalSearchView.swift:121` (`/equipment-rental` → `/rent`) | PASS (URL verified HTTP 200 via curl pre-change) |
| 3 | Fixed test fixture in `web/src/lib/reports/__tests__/email.test.ts:194` (`app.constructionos.world` → `example.com`) | PASS (vitest 13/13) |
| 4 | Local link-health run | DEFERRED (ripgrep not installed locally — only Claude shim exists; CI installs via apt-get) |

## 5 knownExceptions + 2 Source-Fixes

### Skip-list entries (script-level)

| URL | Reason | expires |
|---|---|---|
| `https://constructionos-video-worker.fly.dev/transcode` | POST-only Fly.io worker endpoint; GET returns error but URL is correct | — |
| `https://nzdbphddnrfybwecvsvq.supabase.co` | Supabase project root returns 404 by design; REST APIs require /rest/v1/ path | — |
| `https://hooks.zapier.com/hooks/catch/` | Zapier base URL placeholder in WebhookConfig.tsx | — |
| `https://company.com` | Sample placeholder text across 3 UI surfaces; real domain blocks bots | — |
| `https://docs.constructionos.world/reports` | Help link awaiting 999.8 domain registration | **2027-01-01** |

### Source-fixes

| File | Change | Why |
|---|---|---|
| `ready player 8/RentalSearchView.swift:121` | `dozr.com/equipment-rental?ref=constructionos` → `dozr.com/rent?ref=constructionos` | Real dead URL — dozr removed `/equipment-rental` path; verified `/rent?ref=...` returns HTTP 200 |
| `web/src/lib/reports/__tests__/email.test.ts:194` | `app.constructionos.world/reports` → `example.com/reports` | Test fixtures shouldn't depend on production domain reg; RFC 2606 example.com is auto-filtered by `isPlaceholderHost()` |

## Architectural Decisions Honored

Per CONTEXT.md locked decisions:

- **Skip mechanism: explicit `knownExceptions` array** (not extended `isPlaceholderHost`, not HEAD-retry, not hybrid). Each entry has stated reason. `expires` field on the only deferred-domain entry forces re-evaluation after 999.8 ships.
- **Dozr: source-fix** (not knownExceptions) — the URL is genuinely dead, fixing it preserves link-health value.
- **Test fixture: RFC 2606 example.com** (not knownExceptions, not test-path-blanket-skip) — decouples test from 999.8 domain reg.

## Threat-Model Status

| Threat | Disposition | Evidence |
|---|---|---|
| T-fs7-01 (knownExceptions dumping ground) | mitigate | Every entry has `reason`; `expires` for deferred entries; summary line prints honest count |
| T-fs7-02 (reviewer laziness) | accept | Doc-level discipline only; no quick task can prevent this |
| T-fs7-03 (dozr URL drift) | accept | Source-fix preserves link-health detection capability |
| T-fs7-04 (999.8 ships but page not deployed) | mitigate | `expires: 2027-01-01` provides slack; expiry surfaces it back |

## Deferred: Real-CI Verification

Cannot run `node web/scripts/link-health.mjs` locally — ripgrep binary not installed (only Claude shim). CI installs ripgrep via `sudo apt-get install -y ripgrep` (line 95 of ci.yml). Real verification happens on next push.

**Expected outcome on next CI run:**

| Outcome | Meaning |
|---|---|
| link-health job → success | All 7 prior failures resolved (5 skipped + 2 source-fixed); the ONLY remaining red job on the dashboard goes green |
| link-health job → failure with NEW URLs | The fix worked but new drift surfaced; triage in a follow-up quick task |
| link-health job → failure with SAME URLs | Logic bug in knownExceptions match (unlikely — local node REPL test confirmed exact-match works) |

## Files Changed

| File | Lines | Commit |
|---|---|---|
| `web/scripts/link-health.mjs` | +49 / -1 | pending |
| `ready player 8/RentalSearchView.swift` | +1 / -1 | pending |
| `web/src/lib/reports/__tests__/email.test.ts` | +1 / -1 | pending |

## Hand-off

Push to main → watch CI run → expect link-health job=success → flips fs7 to "Verified" in STATE.md.
