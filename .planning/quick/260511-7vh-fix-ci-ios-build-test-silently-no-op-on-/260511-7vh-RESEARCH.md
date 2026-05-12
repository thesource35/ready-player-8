# 260511-7vh: Fix CI iOS build/test silently no-op on macos-15 — Research

**Researched:** 2026-05-11
**Domain:** GitHub Actions iOS CI on macos-15 hosted runner
**Confidence:** HIGH (live-verified against actions/runner-images main branch + Alamofire/Kingfisher reference workflows + Apple/GitHub deprecation notices)

## Summary

Two compounding bugs caused the previous CI silent no-op:

1. **Wrong Xcode pin.** The workflow selected `Xcode_16.2.app`. macos-15's image inventory (live snapshot 2026-04-28, image `20260428.0039.1`) ships **iOS 18.5, 18.6, 26.0, 26.1, 26.2** simulator runtimes — but **no iOS 18.2** simulator runtime. Xcode 16.2's matched runtime (iOS 18.2) was removed under GitHub's August 2025 "three runtimes max" policy [VERIFIED: actions/runner-images macos-15-Readme.md, github.blog 2025-07-11 changelog]. So `name=iPhone 16,OS=latest` matched zero destinations.
2. **`| xcpretty || true` swallowed the failure.** xcpretty exits 0 even when xcodebuild fails, and `|| true` masked the chained exit code. The job exited 0 in ~20 seconds while compiling/testing nothing.

The earlier remediation attempt (commit `bed1175`, reverted as `2c074e3`) tried `xcodebuild -downloadPlatform iOS` against Xcode 16.2 and hit the well-documented `exit 70: Unable to connect to simulator` CoreSimulatorService bug — Apple has a known race in the simulator daemon when a runtime is downloaded into a non-default Xcode that wasn't pre-paired with it [CITED: developer.apple.com/forums/thread/773602, github.com/dotnet/maui/issues/28239].

**Primary recommendation:** Switch the Xcode pin from 16.2 → **16.4** (which IS the macos-15 default and DOES have a matching iOS 18.5 simulator runtime pre-installed). Pair with `xcbeautify --renderer github-actions` (already pre-installed on macos-15 at v3.2.1), `set -o pipefail`, and remove `|| true`. Keep verification at **`xcodebuild build` only** — `xcodebuild test` will fail on 30+ pre-existing async/concurrency errors in `ready_player_8Tests.swift` documented since Phase 22 (compile-only verification precedent).

## Standard Stack

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `macos-15` runner | image `20260428.0039.1` | Hosted runner | Free tier; arm64; Apple silicon |
| Xcode | **16.4** (default) | Compiler + SDK | iOS 18.5 simulator pre-installed (matches Xcode 16.4 SDK); avoids `-downloadPlatform` race |
| `xcbeautify` | 3.2.1 | xcodebuild log formatter | **Pre-installed** on macos-15; native GitHub Actions renderer; preserves exit codes |
| `set -o pipefail` | bash builtin | Exit-code preservation | Prevents formatter exit code from masking `xcodebuild` failure |

### Why NOT Xcode 16.2

| Reason | Evidence |
|--------|----------|
| iOS 18.2 simulator runtime not in image | macos-15-Readme.md "Installed Simulators" section — only 18.5, 18.6, 26.0, 26.1, 26.2 listed |
| `-downloadPlatform iOS` against Xcode 16.2 hits CoreSimulatorService daemon race | Apple Developer Forums thread 773602; dotnet/maui#28239; runner-images#11695 |
| Alamofire CI matrix marks Xcode 16.2 + iOS 18.2 as `runsOn: self-xcode162` (self-hosted) | github.com/Alamofire/Alamofire/.github/workflows/ci.yml lines 154-157 — they gave up on hosted runner for this combo |
| Kingfisher uses `xcode: '16.2'` only for `sdk: iphonesimulator` (no destination/test) | github.com/onevcat/Kingfisher/.github/workflows/build.yaml — they only build, never `xcodebuild test` against 16.2 |

[ASSUMED] Project's `IPHONEOS_DEPLOYMENT_TARGET` is 18.2 — the SDK in Xcode 16.4 (iOS 18.5) builds backward to 18.2 fine, no source change needed. **Verify after the swap** by running `xcodebuild -showsdks` locally; flag if a Swift 6.0 vs 6.1 strict-concurrency regression appears.

### Alternatives Considered

| Instead of Xcode 16.4 | Could Use | Tradeoff |
|------------------------|-----------|----------|
| Xcode 16.4 + iOS 18.5 sim (PRE-INSTALLED) | Xcode 26.x + iOS 26.x sim | Aligns with local dev convention (iPhone 17, iOS 26.3 per CLAUDE.md/Phase 30.1) but Xcode 26 may surface new Swift 6.2/6.3 strict-concurrency errors; phased adoption recommended |
| Xcode 16.4 + iOS 18.5 sim | macos-26 runner + Xcode 26.4 | Fully matches local dev but `macos-26` is GA only since 2025-09-11 [CITED: github.blog 2025-09-11 changelog]; deferred until needed |
| `xcbeautify` (pre-installed) | `xcpretty` (Ruby gem, also pre-installed) | xcbeautify is faster, native Swift binary, has `--renderer github-actions` annotations; xcpretty is in maintenance mode [CITED: github.com/cpisciotta/xcbeautify README]. Same exit-code-passthrough behavior with `set -o pipefail` |
| `xcodebuild build` only | `build-for-testing` + `test-without-building` | Two-step is faster (skips relink) but requires fixing pre-existing test errors first; defer until test suite is repaired |

## Recommended Workflow Diff

Replace the entire `build-and-test` job in `.github/workflows/ci.yml`:

```yaml
defaults:
  run:
    shell: bash -eo pipefail {0}   # pipefail at workflow level — Kingfisher pattern

jobs:
  build-and-test:
    runs-on: macos-15
    timeout-minutes: 30
    env:
      DEVELOPER_DIR: /Applications/Xcode_16.4.app/Contents/Developer
    steps:
      - uses: actions/checkout@v4

      # Sanity assertion: surface destination availability in the log so future
      # silent no-ops are caught the FIRST CI run, not weeks later.
      - name: Show available iOS Simulator destinations
        run: |
          xcodebuild -version
          echo "--- iOS Simulator destinations ---"
          xcrun simctl list devices available | grep -E "iOS|iPhone" || true

      - name: Build iOS (compile-only — see deferred-items.md)
        run: |
          xcodebuild build \
            -project "ready player 8.xcodeproj" \
            -scheme "ready player 8" \
            -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" \
            -configuration Debug \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcbeautify --renderer github-actions
```

**Key deltas vs. current broken workflow:**

| Change | Why |
|--------|-----|
| `Xcode_16.4.app` (was 16.2) | iOS 18.5 sim pre-installed; no `-downloadPlatform` needed |
| `name=iPhone 16 Pro,OS=18.5` (was `iPhone 16,OS=latest`) | Pinned to a known-present device + OS combo from the image inventory; `OS=latest` is fragile when image inventory changes month-to-month |
| `xcbeautify --renderer github-actions` (was `xcpretty`) | Inline GitHub annotations for build errors; pre-installed |
| `defaults.run.shell: bash -eo pipefail` (workflow-level) | Pipefail applies to every step automatically; no per-step boilerplate |
| Removed `\| xcpretty \|\| true` | Real failures fail CI |
| Removed `Run Tests` step | Pre-existing 30+ async errors in `ready_player_8Tests.swift` block `xcodebuild test`; compile-only per Phase 22/29.1/30 precedent (see Open Question) |
| `DEVELOPER_DIR` env var (replaces `xcode-select`) | No `sudo` needed; cleaner; Alamofire/Kingfisher pattern |
| `Show available destinations` diagnostic step | Forces visible inventory in CI log so the next runtime-removal silently doesn't break things |

## Reference Workflows from Major Swift OSS

### 1. Alamofire — CI matrix [VERIFIED: github.com/Alamofire/Alamofire/.github/workflows/ci.yml]
- Uses `set -o pipefail && env NSUnbufferedIO=YES xcodebuild ... 2>&1 | xcbeautify --renderer github-actions`
- Sets `DEVELOPER_DIR` env var (no sudo xcode-select)
- **Telling: their iOS 18.2 / Xcode 16.2 row is `runsOn: self-xcode162`** — they could not get hosted macos-15 runner to find this combo; same as our problem.
- Their hosted-runner iOS rows use `runsOn: macos-26 # Run on GH since hosted runners can't find it.` — explicit comment confirming the hosted/self-hosted gap.

### 2. Kingfisher — build.yaml [VERIFIED: github.com/onevcat/Kingfisher/.github/workflows/build.yaml]
- Workflow-level `defaults.run.shell: bash -eo pipefail {0}` — single source of pipefail truth.
- Matrix entries for `xcode: '16.2', runner: macos-15, sdk: iphonesimulator` — note: they only **build the framework** against this combo (no `-destination`, no `xcodebuild test`), avoiding the simulator-runtime mismatch entirely.
- For Xcode 26.x rows they switch to `runner: macos-26`.

### 3. Pointfree swift-composable-architecture — ci.yml [VERIFIED: github.com/pointfreeco/swift-composable-architecture/.github/workflows/ci.yml]
- Uses `runs-on: macos-15` + `xcode: '16.4'` (not 16.2) — confirming 16.4 is the safe-default Xcode pin on macos-15.
- Caches DerivedData via `actions/cache@v3` keyed on Swift sources hash — relevant if we add testing later (build incremental between runs).
- Sets `defaults write com.apple.dt.XCBuild IgnoreFileSystemDeviceInodeChanges -bool YES` to fix incremental build flakiness on hosted runners — worth adopting if we ever see "file system inode changes" warnings in CI logs.

## Cache Strategy for iOS Runtimes

**Not needed in the recommended approach.** iOS 18.5 simulator runtime is **already in the image**, so there is nothing to download/cache.

If we later move to Xcode 26.x or need a non-pre-installed runtime, the cache key pattern from Pointfree TCA is:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/Library/Developer/CoreSimulator/Profiles/Runtimes
    key: ios-runtime-${{ matrix.xcode }}-${{ matrix.ios-version }}
```

Caveat: simulator runtimes are ~7GB; macos-15 runners advertise ~14GB free disk after image setup. Watch for "no space left on device" if matrix expands. GitHub's official guidance is `xcodebuild -downloadPlatform iOS -buildVersion 18.5` [CITED: actions/runner-images#13392, #12541] but reports of CoreSimulatorService races are widespread enough that we should avoid it on hosted runners until the situation stabilizes.

## Common Pitfalls

### Pitfall 1: `OS=latest` is unstable across image refreshes
**What goes wrong:** Image gets refreshed (typically monthly), removes the runtime that `latest` was resolving to, destination silently no longer matches.
**How to avoid:** Pin the exact OS version (`OS=18.5`) and the exact device (`iPhone 16 Pro`). Add a `Show available destinations` step at the top of the job so any future inventory shift is visible in the log.

### Pitfall 2: `xcpretty || true` (current workflow) hides everything
**What goes wrong:** `xcpretty` exits 0 even when xcodebuild output contained fatal errors; `|| true` further masks the pipe's exit code; job exits 0 with no actual work done.
**How to avoid:** Use workflow-level `bash -eo pipefail`, drop `|| true` entirely, prefer `xcbeautify` which preserves stderr more cleanly. Add a sanity assertion (e.g., grep for "BUILD SUCCEEDED" or "Compiling" in stdout) if extra paranoia is wanted.

### Pitfall 3: `xcodebuild -downloadPlatform iOS` against a non-default Xcode races CoreSimulatorService
**What goes wrong:** Runtime downloads but isn't paired with the active Xcode's simulator daemon; subsequent build/test fails `exit 70: Unable to connect to simulator`. This is what killed commit `bed1175`.
**How to avoid:** Use the macos-15 default Xcode (16.4) which has its matching runtime pre-paired. Only resort to `-downloadPlatform` if matrix-testing forces a non-default Xcode.

### Pitfall 4: `xcodebuild test` against pre-existing test target errors
**What goes wrong:** `ready_player_8Tests.swift` has 30+ async/concurrency errors documented in phase deferred-items since Phase 22. Running `xcodebuild test` exits 65 (TEST FAILED).
**How to avoid:** Use `xcodebuild build` only (matches Phase 22/29.1/30-02/30-04/30-07 compile-only verification precedent codified in STATE.md). Re-enable `test` only after a focused phase repairs the test target. Document this gap in the workflow comments.

### Pitfall 5: Trusting a green CI badge without log inspection
**What goes wrong:** This whole bug existed for weeks because `gh run view` showed ✓ in 20s and nobody opened the logs. CI's success signal was lying.
**How to avoid:** Add a final assertion step that greps for evidence the build actually ran, e.g., `grep -q "BUILD SUCCEEDED" build.log || (echo "::error::xcodebuild did not produce BUILD SUCCEEDED" && exit 1)`. Make the noise loud when the next failure mode (whatever it is) emerges.

## Open Questions

1. **Should we re-enable `xcodebuild test` or stay `build`-only?**
   - **What we know:** `ready_player_8Tests.swift` has 30+ pre-existing async/concurrency errors blocking `xcodebuild build-for-testing`. Phase 22, 29.1, 30-02, 30-04, 30-07 all explicitly adopted compile-only verification per documented precedent (STATE.md). New tests added since (`AuthGateTests`, `BackendConfigSheetTests`, `NotificationsStoreTests`, `InboxViewTests`, `SupabaseNotificationDTOTests`, etc.) compile clean individually but the umbrella build fails.
   - **What's unclear:** Whether the user wants this CI quick-task to ALSO bundle a fix for the pre-existing test errors, or just close the silent-failure half.
   - **Recommendation:** Ship `build`-only in this quick-task. Add an inline comment `# TODO: re-enable test step after ready_player_8Tests.swift async errors are fixed (tracked in Phase 22 deferred-items)` so the gap is grep-discoverable. File a separate quick-task / phase to repair the test target.

2. **Should we pin `iPhone 16 Pro` or `iPhone 17 Pro` as the destination device?**
   - **What we know:** Local dev convention (CLAUDE.md, Phase 30.1 verification) uses `iPhone 17, OS=26.3`. The recommended pin here is `iPhone 16 Pro, OS=18.5` — different device family + iOS major version.
   - **What's unclear:** Whether the local-vs-CI device skew matters for the build-only CI signal we're trying to restore. (For build-only, the simulator is barely used — it just resolves the SDK and architecture; the binary is never actually launched.)
   - **Recommendation:** `iPhone 16 Pro, OS=18.5` for now (uses image's pre-installed runtime, zero download time). Revisit when re-enabling `xcodebuild test` — at that point match local dev (iPhone 17, OS=26.x) by switching to Xcode 26.x + macos-26 runner.

3. **Should we add a DerivedData cache like Pointfree TCA does?**
   - **What we know:** Without caching, every CI run does a clean compile. Project is monolithic (~12,500-line `ContentView.swift`), so cold compile is meaningful (likely 2-4 min for the whole project on macos-15).
   - **What's unclear:** Run frequency (PR + push to main) and whether the latency hurts.
   - **Recommendation:** Defer caching — get green CI first, optimize later if cold-compile time becomes painful.

## Sources

### Primary (HIGH confidence — live-fetched 2026-05-11)
- [actions/runner-images macos-15 Readme](https://raw.githubusercontent.com/actions/runner-images/main/images/macos/macos-15-Readme.md) — verified Xcode 16.2 SDK present but iOS 18.2 simulator runtime NOT in "Installed Simulators" inventory; xcbeautify 3.2.1 pre-installed
- [Alamofire CI workflow (master)](https://github.com/Alamofire/Alamofire/blob/master/.github/workflows/ci.yml) — confirms iOS 18.2/Xcode 16.2 unworkable on hosted runners; their iOS matrix uses self-hosted runners for that combo
- [Kingfisher build workflow (master)](https://github.com/onevcat/Kingfisher/blob/master/.github/workflows/build.yaml) — `bash -eo pipefail` workflow defaults pattern; Xcode 16.2 only used for SDK builds, never `xcodebuild test`
- [pointfreeco/swift-composable-architecture CI](https://github.com/pointfreeco/swift-composable-architecture/blob/main/.github/workflows/ci.yml) — confirms Xcode 16.4 as the safe-default pin on macos-15
- [xcbeautify README](https://github.com/cpisciotta/xcbeautify) — canonical `set -o pipefail && xcodebuild [flags] | xcbeautify --renderer github-actions`
- [GitHub Actions changelog 2025-07-11: Xcode support policy update](https://github.blog/changelog/2025-07-11-upcoming-changes-to-macos-hosted-runners-macos-latest-migration-and-xcode-support-policy-updates/) — "three runtimes max" policy effective Aug 11, 2025
- [actions/runner-images#13392: macOS 15 runtime deprecation](https://github.com/actions/runner-images/issues/13392) — Jan 12, 2026 deprecation cycle; recommends `xcodebuild -downloadPlatform`
- [actions/runner-images#12541: New Xcode/simulator policy](https://github.com/actions/runner-images/issues/12541) — three-runtime cap rationale (disk space)
- [actions/runner-images#11695: iOS 18.2 not installed on macos-15-arm64](https://github.com/actions/runner-images/issues/11695) — confirms reproducibility of the iOS 18.2 / Xcode 16.2 mismatch

### Secondary (MEDIUM confidence)
- [Apple Developer Forums #773602: iOS 18.3 simulator runtime unavailable](https://developer.apple.com/forums/thread/773602) — CoreSimulatorService daemon race when downloading runtime into non-default Xcode
- [dotnet/maui#28239: iOS 18.2 simulators fail to launch on CI](https://github.com/dotnet/maui/issues/28239) — independent reproduction of the `exit 70` failure mode
- [GitHub Actions changelog 2025-09-11: macOS 26 image GA](https://github.blog/changelog/2025-09-11-actions-macos-26-image-now-in-public-preview/) — confirms `macos-26` runner availability if/when we move to Xcode 26.x
- [Quality Coding: GitHub Actions for Xcode CI](https://qualitycoding.org/github-actions-ci-xcode/) — general best practice (extract workflow into local script for debuggability)

## Metadata

**Confidence breakdown:**
- Standard stack (Xcode 16.4 + xcbeautify + iPhone 16 Pro/iOS 18.5): HIGH — directly verified against macos-15 image inventory
- Workflow YAML: HIGH — pattern matches Kingfisher (proven against macos-15 + Xcode 16.x)
- Reference workflows: HIGH — fetched live from canonical OSS repos
- Pitfalls: HIGH — root causes traced to specific commits, issues, and forum threads
- Pre-existing test errors / compile-only stance: HIGH — explicit precedent in STATE.md across Phase 22/29.1/30

**Research date:** 2026-05-11
**Valid until:** 2026-06-11 (image inventory may shift monthly; specifically watch for the Jan 12, 2026 deprecation cycle and any subsequent runtime-removal events)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Project's `IPHONEOS_DEPLOYMENT_TARGET` is ≤ 18.5 (so Xcode 16.4 SDK builds it) | Standard Stack | LOW — virtually all iOS projects target ≤ current SDK; if deployment target is set to e.g. 26.0, build will fail with a clear error and we switch to Xcode 26.x + macos-26 runner |
| A2 | Project compiles clean under Swift 6.0 strict concurrency (Xcode 16.4 ships Swift 6.1) | Standard Stack | LOW — Swift 6.1 is a superset; new strict-concurrency diagnostics are typically warnings, not errors. If they're errors, we either fix them in this quick-task or downgrade to Xcode 16.3 (also pre-installed, also ships matching runtime) |

## Quick-Task Delivery Notes

This is a single-file workflow change with low blast radius. Suggested execution order:

1. Replace `build-and-test` job per the YAML diff above.
2. Push to a branch, open a PR, watch the CI log:
   - `Show available destinations` step should print `iPhone 16 Pro (18.5)` etc.
   - `Build iOS` step should print `Compiling X.swift` lines (xcbeautify output) and end with `BUILD SUCCEEDED`.
3. If green: merge.
4. If red with real compile errors: that's actually the win — CI is now telling the truth. Fix the surfaced errors in a follow-up.
5. Update `.planning/STATE.md` Session Continuity to note the silent-failure trap is closed and CI is honest again. Cross-link backlog item 999.10 to the closing commit.

When ready to verify this works end-to-end, push the workflow change to a feature branch and ask me to run a browser-driven check of the GitHub Actions run page for the actual build log (vs. just the green checkmark).
