# Silent-failure / Tier 2 audit — 2026-05-02

Comprehensive audit of silent-failure patterns across iOS + web,
spawned by the 999.5 (d) Tier 2 work. Documents what was fixed in
the 2026-05-01/02 session burst, what remains, and what's
intentionally silent.

## Methodology

Greps used:
```
# iOS catch+mock fallback
grep -rn "} catch" "ready player 8"/*.swift
xargs awk '/} catch/{p=NR; get=1} get && NR<=p+8 && /(mock|MOCK)/{...}'

# iOS try? near data operations
grep -rn "try?" "ready player 8"/*.swift | grep -E "supabase|fetch|insert|update|delete|Auth"

# iOS fire-and-forget Task {}
grep -rn "^[[:space:]]*Task {" "ready player 8"/*.swift

# Web fetch without res.ok check
awk '/await fetch\(/{...} got && NR<=p+10 && /res\.ok|response\.ok/{...}'

# Web silent-failure comments
grep -rn "Silently fail\|silently fail" web/src
```

## Fixed in 2026-05-01/02 session burst (8 commits)

| Spot | Pattern | Commit |
|---|---|---|
| iOS MCPServer 5 tool cases | catch+silent mock substitute | `6d3010f` |
| Web 4 list API routes | unconfigured/error/empty conflated | `f5aa3a7` |
| iOS MapsView equipment + photos | error banner + fake pins simultaneously | `d9e3047` |
| iOS EquipmentCheckInView | catch+silent mock with no UI surface | `d9e3047` |
| iOS ProjectsView/ContractsView filter refetch | catch+silent log, no UI | `6cdf0ba` |
| iOS Wealth Suite (5 views) | `try? await supabase.insert(...)` | `a3a611b` |
| iOS Tier 3 mock bundle gating | 20 mock arrays in 12 files | `03018f4` + `1b48aeb` |
| Web vitest test infra | server-only + 6 test path corrections | `2ee3659` |

## Remaining silent-failure spots (NOT yet fixed)

### Web — Client-side `catch { /* silent */ }` (22 spots)

Pattern: user-initiated action triggers fetch; fetch fails; UI shows nothing; the
inline comment "Silently fail — user can retry" is the literal anti-pattern.

**Group A — Pagination "Load More" handlers (uniform pattern, mass fix candidate):**

| File | Line | Note |
|---|---|---|
| `src/app/projects/page.tsx` | 84 | Load More projects |
| `src/app/contracts/page.tsx` | 76 | Load More contracts |
| `src/app/feed/page.tsx` | 127 | Load More feed posts |
| `src/app/tasks/page.tsx` | 86 | Load More tasks |
| `src/app/ops/page.tsx` | 123 | Load More ops alerts |
| `src/app/punch/page.tsx` | 80 | Load More punch items |

Severity: **medium** — user clicks "Load More," nothing happens, no error
shown. They keep trying or give up. Worse than ideal UX, not data-corrupting.

Proposed fix: each handler adds `setLoadMoreError(string)` state + a banner
or inline message in the empty-state slot. Or upgrade to a global toast.

**Group B — Mutation/upload paths (need careful per-file review):**

| File | Line | Note |
|---|---|---|
| `src/app/jobs/page.tsx` | 158 | Job posting POST |
| `src/app/projects/page.tsx` | 129 | Project create/delete |
| `src/app/portals/page.tsx` | 30, 41 | Portal CRUD |
| `src/app/components/portal/PortalCreateDialog.tsx` | 140 | Portal create dialog |
| `src/app/projects/[id]/cameras/ClipUploadCard.tsx` | 106 | Video clip upload |
| `src/app/projects/[id]/cameras/AddCameraWizard.tsx` | 59 | Camera registration |
| `src/app/portal/[slug]/[project]/cameras/PortalCamerasSection.tsx` | 40 | Portal cameras read |
| `src/app/live-feed/DroneUploadButton.tsx` | 66, 98 | **Drone footage upload** |
| `src/app/checkout/page.tsx` | 60 | **Subscription checkout** |
| `src/app/maps/page.tsx` | 435 | Maps data fetch |
| `src/app/reports/components/ScheduleManagement.tsx` | 551 | Report schedule |
| `src/app/reports/components/CollaborationPanel.tsx` | 73 | Report collaboration |
| `src/app/reports/components/DataExportBackup.tsx` | 38 | Data export |
| `src/lib/links/linkHealth.ts` | 156 | Link health check (utility — likely intentional) |

Severity: **HIGH for DroneUploadButton + checkout** — silent failure on a
user uploading a 500MB drone video file would be catastrophic for UX. Same
for checkout: silent payment-API failure is a billing bug and a trust bug.
**MEDIUM for the rest.**

Proposed fix per spot:
- Upload paths: progress indicator + error toast + retry CTA
- Mutations: error toast + form stays open + clear error text
- Read paths: inline error banner on the affected section

### iOS — `try?` swallowing high-stakes operations (~10 real spots)

**Group A — MFA setup (ContentView.swift):**

| Line | Operation | Severity |
|---|---|---|
| 173 | `(try? await supabase.listMFAFactors()) ?? []` | HIGH — silent failure makes MFA appear unconfigured |
| 176 | `try? await supabase.createMFAChallenge(...)` | HIGH — silent failure breaks MFA enrollment |
| 591 | `try? await supabase.createMFAChallenge(...)` | HIGH — same |

Fix: do/catch with errorMessage surfaced + CrashReporter log.

**Group B — DocumentSyncManager.swift:**

| Line | Operation | Severity |
|---|---|---|
| 32 | `try? dec.decode(...)` (load cached docs from Keychain) | MEDIUM — local cache decode failure silently empties |
| 40 | `try? enc.encode(...)` (save docs cache) | MEDIUM — silent save failure means cache is stale |
| 245 | `(try? await svc.fetch(...))` (sync row IDs) | MEDIUM — sync silently broken |
| 286 | `(try? await svc.fetch(...))` (delete-detection sync) | MEDIUM — orphan rows persist |

Fix: do/catch + CrashReporter so we have telemetry on sync failures.

**Group C — StoreKit (PlatformFeatures.swift):**

| Line | Operation | Severity |
|---|---|---|
| 390 | `try? await AppStore.sync()` (refresh receipts) | MEDIUM — paid features may not unlock |
| 396 | `try? checkVerified(result)` (verify transaction) | HIGH — fraudulent transaction not detected |

Fix: at minimum log to CrashReporter; ideally surface to user.

**Group D — Image picker `loadTransferable`:**

| File | Line | Severity |
|---|---|---|
| `ConstructionOSNetwork.swift` | 952 | LOW — expected when user cancels |
| `SocialNetworkView.swift` | 136 | LOW |
| `UIHelpers.swift` | 395 | LOW |

These are likely OK as-is — `loadTransferable` returning nil is expected
when the user cancels the picker. But should at least log the case where
it fails for non-cancel reasons (corrupt asset, permission denied).

**Group E — Out-of-scope:**

- `PersistenceController.swift:26,156,163` — CoreData template, unused by app
- `ReportExportView.swift:551` — temp file write; if fails, share sheet shows nothing
- `PowerThinkingView.swift:21,382,467,476` — these are optional `?` not `try?` (false positives)

### iOS — Fire-and-forget `Task {}` blocks (97 occurrences)

Most are intentional (analytics tracking, background sync, UI animations).
Need targeted review of which ones do user-data writes — those should
either await result or surface failure.

Sampling will catch any meaningful ones. Not fully cataloged here.

### iOS — `} catch { CrashReporter.shared.reportError(...) }` only (47 occurrences)

These are "logged but not surfaced to user" — a softer Tier 2 violation.
Sometimes intentional (background work) but often the user is actively
waiting (e.g., ProjectsView/ContractsView filter refetch already fixed in
`6cdf0ba`). Need case-by-case review.

## Out of scope (intentional silent paths)

These were checked and are correctly silent:

- `loadJSON` / `saveJSON` (AppStorageJSON.swift) — both already have
  `try { ... } catch { CrashReporter.shared.reportError(...) }`
- Web Server Actions in `field/`, `inbox/`, `field/logs/`, `field/photos/` —
  all return discriminated `{ok: true} | {ok: false, status, error}` unions
- ConstructionOSNetwork.swift:380 (loadState UserDefaults decode) — falls
  back to mock starter content; the mocks themselves are now empty in
  Release per Tier 3 gating, so silent fallback in release = empty list

## Recommended fix priority order

1. **DroneUploadButton + checkout** — 3 spots. HIGH severity. Silent
   failure on user upload or payment is a trust killer.
2. **iOS MFA setup (3 spots)** — `try?` on MFA listing + challenge create.
   Silent failure makes MFA appear broken.
3. **Web 6 Load More handlers** — uniform pattern, mass fix. Medium severity
   but high volume of user impact.
4. **iOS DocumentSyncManager (4 spots)** — sync silently breaking is hard
   to detect in prod. At minimum, CrashReporter logging.
5. **iOS StoreKit (2 spots)** — paid-feature unlock issues.
6. **Web other mutation paths (~13 spots)** — case-by-case review.
7. **iOS try? loadTransferable (3 spots)** — low priority, expected nil
   on cancel; just add log for non-cancel failures.

## How to re-audit later

```bash
# iOS: catches near mock data
grep -rn "} catch" "ready player 8"/*.swift | xargs awk '...'

# iOS: try? in non-trivial code
grep -rn "try?" "ready player 8"/*.swift | grep -vE "test|sleep|requestFullAccess"

# iOS: catches that only log
grep -rB0 -A4 "} catch {" "ready player 8"/*.swift

# Web: fetch without res.ok
grep -rn "await fetch(" web/src --include='*.ts' --include='*.tsx' \
  | grep -v "test\|__tests__"
# Then for each, check the lines that follow for res.ok / response.ok / status check.

# Web: explicit anti-pattern comment
grep -rn "Silently fail\|silently fail\|silent fail" web/src
```

## Status

Audit doc created 2026-05-02 at end of long session burst.
20 commits shipped to origin/main during this audit-and-fix cycle.
The 6 categories of silent-failure ALREADY fixed represent the most
critical patterns. The remaining ~30 spots cataloged here range from
HIGH-severity (drone upload, checkout, MFA) to LOW-severity (image
picker cancel paths) and should be addressed in follow-up sessions
with appropriate scope per session.
