# Quick 260511-u3y: Bump CI to Xcode 26.x + iOS 26.x — Research

**Researched:** 2026-05-12
**Domain:** GitHub Actions iOS CI / runner image selection
**Confidence:** HIGH

## Summary

`macos-26` (Tahoe) is GA on GitHub-hosted runners (announced 2026-02-26). It ships with **Xcode 26.0.1 / 26.1.1 / 26.2 (default) / 26.3 / 26.4.1 / 26.5-beta** pre-installed, plus iOS Simulator runtimes for **iOS 26.1, 26.2, and 26.4** with the **iPhone 17 / 17 Pro / 17 Pro Max / 16e** device fleet baked in. iOS **26.3 is NOT pre-installed** — the closest match for the developer's local Xcode 26.3 / iOS 26.3 sim is **Xcode 26.3 + iOS 26.2 destination** (or upgrade to iOS 26.4 destination, also pre-installed). Same major SDK = same Chart inference / Swift 6 concurrency behavior; patch mismatch is irrelevant for compile-only verification.

**Primary recommendation:** Switch `runs-on: macos-15` → `macos-26`, pin `DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer`, pin destination to `platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2`. Zero runtime download. No `xcodes` CLI. No caching needed. ~30-line YAML diff.

## User Constraints (from task focus)

### Locked
- Bump CI to Xcode 26.x + iOS 26.x — must match developer's local Xcode 26.3 / iOS 26.3 SDK behavior (Chart inference + Swift 6 concurrency on the iOS 26 SDK)
- Single GitHub-hosted runner job (no self-hosted, no Codemagic)
- Preserve compile-only verification (TODO(999.10) marker for test re-enable stays)

### Claude's Discretion
- macos-26 vs macos-15 + xcodes install
- Specific Xcode 26 patch version (26.2 vs 26.3)
- Specific iOS 26 destination patch version (26.1 / 26.2 / 26.4)
- Whether to bundle `actions/checkout@v4 → v5` + `actions/setup-node@v4 → v5` Node 20 deprecation cleanup

### Out of Scope
- Re-enabling `xcodebuild test` (still blocked by pre-existing `ready_player_8Tests.swift` async errors — separate phase)
- web-build / link-health job changes beyond optional v4→v5 action bumps
- Local Xcode/runtime install (developer machine already has Xcode 26.3 + iOS 26.3 sim)

## Recommended Approach

### Pick: `macos-26` runner + pinned Xcode 26.3 + iOS 26.2 destination

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Runner image | `macos-26` (GA 2026-02-26) | iOS 26 simulator runtimes pre-bundled; zero download; no `xcodes` Apple-ID friction; no 12–15 GB cache thrash |
| Xcode | `Xcode_26.3.app` via `DEVELOPER_DIR` env | Exact match to developer-local Xcode 26.3 — same Swift compiler version that compiled the 260511-thn fixes |
| Destination | `platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2` | iPhone 17 Pro + iOS 26.2 are both pre-installed (verified in `macos-26-arm64-Readme.md`). iOS 26.3 sim is NOT in the image; iOS 26.2 is the closest pre-bundled runtime that exercises the iOS 26 SDK code paths. Hard-pinned (not `OS=latest`) per 999.10 lesson. |
| Cache | None | Xcode + iOS runtime are pre-installed; no install step = nothing to cache |
| Actions versions | `actions/checkout@v5`, `actions/setup-node@v5` | Node 20 EOL April 2026; forced-Node-24 default starts 2026-06-02. Cheap bundled cleanup. [VERIFIED: github.blog changelog] |

**Why not macos-15 + xcodes CLI?** macos-15 actually pre-installs Xcode 26.0.1–26.3 too (per `macos-15-Readme.md` as of May 2026), so technically it'd also work — BUT only iOS 18.5 / 18.6 / 26.0 / 26.1 / 26.2 simulator runtimes are present, and macos-15 has been receiving runtime-removal updates ("three runtimes max" policy that bit 999.10). `macos-26` is the cleaner, future-proof target image: Apple Silicon native, no historical-runtime baggage, and the platform-team explicitly recommends it for Xcode 26 workflows (Alamofire's reference matrix landed on it).

**Why not `OS=26.3`?** Verified via raw `macos-26-arm64-Readme.md`: iOS 26.3 simulator runtime is not in the image (jumps 26.2 → 26.4). Hard-pinning a missing OS would silently no-op exactly like 999.10. `OS=26.2` is pre-bundled and definitive.

**Why not `OS=26.4`?** Also pre-bundled and would work — but pre-release issue #13853 (March 2026) flagged Xcode 26.4 RC vs runtime mismatch, and 26.4 was the in-flux runtime as of the user-confirmed local environment baseline. iOS 26.2 is the most stable, longest-pre-installed iOS 26 runtime on `macos-26`. Easy to bump later.

## Concrete YAML Diff

```diff
 jobs:
   build-and-test:
-    runs-on: macos-15
+    runs-on: macos-26
     timeout-minutes: 30
-    # Pin Xcode 16.4 (macos-15 default) — its matching iOS 18.5 simulator runtime
-    # is pre-installed in the image. Xcode 16.2 was previously pinned but its
-    # matching iOS 18.2 runtime was removed under GitHub's Aug 2025 "three
-    # runtimes max" policy, causing the previous "latest" OS pin to match zero destinations and
-    # the job to silently no-op (backlog 999.10).
+    # Pin Xcode 26.3 (matches developer-local) + iOS 26.2 destination (matching
+    # iOS 26 SDK major; iOS 26.3 simulator runtime is NOT pre-installed on
+    # macos-26 as of May 2026 — image ships iOS 26.1 / 26.2 / 26.4). Patch
+    # mismatch is fine for compile-only verification of iOS 26 SDK semantics
+    # (Chart inference + Swift 6 concurrency).
     #
     # Audit periodically against:
-    #   https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md
-    # If iOS 18.5 is removed from the image, this pin must move to the next
-    # pre-installed runtime (likely 18.6 or 26.x) — failing to do so will
-    # surface visibly in the "Show available iOS Simulator destinations" step
-    # below, NOT silently as before. (T-999.10-02)
+    #   https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md
+    # If iOS 26.2 is removed, this pin must move to the next pre-installed
+    # iOS 26.x runtime — failing to do so will surface visibly in the
+    # "Show available iOS Simulator destinations" step below, NOT silently
+    # (T-999.10-02 still applies).
     env:
-      DEVELOPER_DIR: /Applications/Xcode_16.4.app/Contents/Developer
+      DEVELOPER_DIR: /Applications/Xcode_26.3.app/Contents/Developer
     steps:
-      - uses: actions/checkout@v4
+      - uses: actions/checkout@v5

       - name: Show available iOS Simulator destinations
         run: |
           xcodebuild -version
           echo "--- iOS Simulator destinations ---"
           xcrun simctl list devices available | { grep -E "iOS|iPhone" || :; }

       - name: Build iOS (compile-only — see TODO above)
         run: |
           xcodebuild build \
             -project "ready player 8.xcodeproj" \
             -scheme "ready player 8" \
-            -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" \
+            -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2" \
             -configuration Debug \
             CODE_SIGN_IDENTITY="" \
             CODE_SIGNING_REQUIRED=NO \
             | xcbeautify --renderer github-actions

   web-build:
     runs-on: ubuntu-latest
     timeout-minutes: 10
     defaults:
       run:
         working-directory: web
     steps:
-      - uses: actions/checkout@v4
-      - uses: actions/setup-node@v4
+      - uses: actions/checkout@v5
+      - uses: actions/setup-node@v5
         with:
           node-version: "20"
           ...

   link-health:
     ...
     steps:
-      - uses: actions/checkout@v4
-      - uses: actions/setup-node@v4
+      - uses: actions/checkout@v5
+      - uses: actions/setup-node@v5
         with:
           node-version: "20"
```

Net change: 1 runner-line, 1 env-line, 1 destination-line, 3 comment-block lines, 4 action-version bumps. ~10 real-content lines.

## Reference Workflows (May 2026)

| Project | Runner | Xcode | Destination | URL |
|---------|--------|-------|-------------|-----|
| Alamofire | `macos-26` | `Xcode_26.4` (pinned via `DEVELOPER_DIR`) | `OS=26.4,name=iPhone 17 Pro` | https://github.com/Alamofire/Alamofire/blob/master/.github/workflows/ci.yml |
| Kingfisher | `macos-26` | `26.3` (matrix) | `sdk: iphonesimulator` | https://github.com/onevcat/Kingfisher/blob/master/.github/workflows/build.yaml |
| Pointfree TCA | `macos-15` (lagging) | `16.4` | (Makefile-internal) | https://github.com/pointfreeco/swift-composable-architecture/blob/main/.github/workflows/ci.yml |

**Pattern consensus:** Alamofire is the closest match — `macos-26` + explicit Xcode pin via `DEVELOPER_DIR` env + hard-pinned `OS=N.N,name=iPhone 17 Pro` destination. They run a matrix; we run one row of it. Kingfisher confirms 26.3 is a valid pin on `macos-26`.

## Pre-installed Inventory (macos-26-arm64, verified 2026-05-12)

[VERIFIED: https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md]

| Component | Versions Available |
|-----------|---------------------|
| Xcode | 26.0.1, 26.1.1, 26.2 (default), 26.3, 26.4.1, 26.5-beta |
| iOS Sim Runtimes | 26.1, 26.2, 26.4 (NOT 26.3, NOT 26.0) |
| iPhone Sim Devices (under 26.2) | iPhone 16e, iPhone 17, iPhone 17 Pro, iPhone 17 Pro Max, iPhone Air |
| iPad Sim Devices (under 26.2) | iPad (A16), iPad Air 11/13" (M3), iPad mini (A17 Pro), iPad Pro 11/13" (M5) |

Xcode path: `/Applications/Xcode_26.3.0.app` (also symlinked as `/Applications/Xcode_26.3.app` — both work in `DEVELOPER_DIR`).

## Pitfalls + Mitigations

| Pitfall | Mitigation |
|---------|------------|
| Hard-pinning `OS=26.3` (matches local) → silent no-op because runtime not in image | Use `OS=26.2`. The "Show available destinations" diagnostic step from 999.10 will surface this on the FIRST CI run, not silently. |
| `xcodebuild -downloadPlatform iOS` to install 26.3 sim | DON'T. Reverted in 260511-7vh (commit `2c074e3`) for daemon-race exit 70. Pre-bundled 26.2 avoids entirely. |
| `macos-26` runtime-removal in future (image refresh churn) | Same 999.10 protection in place: diagnostic step + comment block pointing at `macos-26-arm64-Readme.md` for periodic audit. |
| `macos-latest` confusion | `macos-latest` still points at `macos-15` as of May 2026 — never use `-latest`. Hard-pin `macos-26`. |
| iPhone 17 Pro sim device drift | Verified pre-installed in iOS 26.2 device list. Diagnostic step will catch any removal. |
| `actions/checkout@v4` Node 20 deprecation warning | Bundle `@v4 → @v5` upgrade in same PR (cheap, kills the warning across all 3 jobs). v5 is stable on Node 24. [VERIFIED: GitHub Actions changelog 2025-09-19] |
| iOS 26.4 runtime / Xcode 26.4 RC mismatch (issue #13853, "awaiting-deployment" as of Mar 2026) | Avoid by pinning Xcode 26.3 + iOS 26.2. Both fully GA, both shipped together in earlier image releases. |
| Image is Apple Silicon (arm64) only; legacy x64 callers break | None of our build steps assume x64. `macos-26-large` exists for x64 if needed (not needed here). |

## Local Pre-Push Verification

Run on developer machine before pushing (catches the SDK-mismatch case without burning CI minutes):

```bash
# Mimic the CI invocation exactly — only difference is local has iOS 26.3 runtime
xcodebuild build \
  -project "ready player 8.xcodeproj" \
  -scheme "ready player 8" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3" \
  -configuration Debug \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  | xcbeautify --renderer terminal

# Confirm available runtimes (sanity)
xcrun simctl list runtimes available | grep iOS
```

Expected: `BUILD SUCCEEDED`. iOS 26.2 (CI) vs iOS 26.3 (local) is patch-only — same SDK major, same Chart inference, same Swift 6 strict-concurrency behavior. The Chart inference + concurrency errors that 260511-thn fixed are SDK-major triggered (iOS 26 vs iOS 18), not patch-triggered.

## Sources

### Primary (HIGH confidence)
- [actions/runner-images macos-26-arm64 README](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md) — Xcode + iOS runtime + device inventory
- [actions/runner-images macos-15 README](https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md) — Xcode 26 also on macos-15, but with fewer iOS 26 runtimes
- [GitHub Changelog: macos-26 GA (2026-02-26)](https://github.blog/changelog/2026-02-26-macos-26-is-now-generally-available-for-github-hosted-runners/)
- [GitHub Changelog: Node 20 deprecation timeline](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/)

### Secondary (HIGH — verified reference workflows)
- [Alamofire CI](https://github.com/Alamofire/Alamofire/blob/master/.github/workflows/ci.yml) — `macos-26` + `Xcode_26.4` + `OS=26.4,name=iPhone 17 Pro` pattern
- [Kingfisher CI](https://github.com/onevcat/Kingfisher/blob/master/.github/workflows/build.yaml) — `macos-26` + Xcode 26.3 matrix

### Tertiary (issue tracker — context only)
- [Issue #13853: Xcode 26.4 RC iOS 26.4 sim mismatch](https://github.com/actions/runner-images/issues/13853) — "awaiting-deployment" Mar 2026
- [Issue #13435: iOS 26 sim devices missing on macos-26-arm64](https://github.com/actions/runner-images/issues/13435) — Dec 2025, closed as duplicate, since resolved (devices present today)
- [Issue #13854: -downloadPlatform still needed?](https://github.com/actions/runner-images/issues/13854) — duplicate of #13853

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | iOS 26.2 destination on Xcode 26.3 will compile the same code that Xcode 26.3 + iOS 26.3 compiled locally (SDK major dominates over patch for Chart inference + Swift 6 concurrency) | Local Pre-Push Verification | Low. SDK semantics are tied to major version. Worst case: patch-level Chart inference shift, caught by CI run, repinned to iOS 26.4 destination. |
| A2 | `Xcode_26.3.app` symlink path on macos-26-arm64 is stable | YAML diff | Low. Verified from readme; symlink convention has been stable for 5+ Xcode majors. |

## Open Questions

None. All decisions evidenced.

## Metadata

**Confidence breakdown:**
- Runner image inventory: HIGH — directly read from actions/runner-images repo
- Xcode + iOS destination choice: HIGH — cross-confirmed against Alamofire's production matrix
- Action version bumps: HIGH — official GitHub changelog with dated EOL
- Local vs CI patch-version equivalence: HIGH — Swift compiler + iOS SDK major version dominates patch for our specific failure modes (Chart inference + concurrency)

**Research date:** 2026-05-12
**Valid until:** 2026-06-12 (macos-26 image refresh cadence is ~bi-weekly; the "Show available destinations" diagnostic step will surface drift on first affected CI run)
