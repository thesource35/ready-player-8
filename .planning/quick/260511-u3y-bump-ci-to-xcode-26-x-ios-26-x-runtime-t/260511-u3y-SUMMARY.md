---
phase: quick-260511-u3y
plan: 01
status: complete
completed: 2026-05-12
---

# Quick 260511-u3y Summary — CI bump to macos-26 + Xcode 26.3 + iOS 26.2

## 6 Surgical YAML Edits

| # | Location | FROM | TO |
|---|----------|------|-----|
| 1 | `runs-on` (build-and-test) | `macos-15` | `macos-26` |
| 2 | comment block (build-and-test) | macos-15 / Xcode 16.4 / iOS 18.5 context | macos-26 / Xcode 26.3 / iOS 26.2 context (preserves T-999.10-02 audit reference) |
| 3 | `DEVELOPER_DIR` | `Xcode_16.4.app` | `Xcode_26.3.app` |
| 4 | destination pin | `iPhone 16 Pro,OS=18.5` | `iPhone 17 Pro,OS=26.2` |
| 5 | `actions/checkout` (×3 jobs) | `@v4` | `@v5` |
| 6 | `actions/setup-node` (×2 jobs) | `@v4` | `@v5` |

## Verification (run 2026-05-12)

```
yaml-parse: PASS
macos-26: PASS
Xcode 26.3: PASS
iPhone 17 Pro/OS=26.2: PASS
checkout@v5 x3: PASS
setup-node@v5 x2: PASS
old-refs-removed: PASS
999.10-invariants: PASS (no `|| true`, no `xcpretty`)
todo-marker: PASS (TODO(999.10) preserved)
xcbeautify: PASS
diagnostic-step: PASS (grep count = 2 — step name + comment ref)
```

Single-file diff: `.github/workflows/ci.yml` only. No Swift, no web/, no other workflows.

## 999.10 Invariants Preserved

- Workflow-level `defaults.run.shell: bash -eo pipefail {0}` (line 11) untouched
- `xcbeautify --renderer github-actions` (line 59) untouched
- `Show available iOS Simulator destinations` diagnostic step (lines 37-41) untouched
- `TODO(999.10)` marker (line 47) untouched
- `continue-on-error: true` on link-health (line 88) untouched
- Zero `|| true` literals; zero `xcpretty` references

## Threat-Model Status

| Threat | Disposition | Evidence |
|--------|-------------|----------|
| T-u3y-01 (Xcode_26.3 removed) | mitigate | Explicit DEVELOPER_DIR pin makes failure loud; diagnostic step shows what's installed; 1-line recovery |
| T-u3y-02 (iOS 26.2 removed) | mitigate | 999.10 diagnostic step surfaces drift on first affected run; recovery is changing one digit |
| T-u3y-03 (checkout@v5 breaking change) | accept | v5 is GA + widely deployed; failure loud not silent; one-line revert if needed |
| T-u3y-04 (test target still blocked) | accept | Out of scope; TODO(999.10) marker preserved for future phase |

## Deferred: Real-CI Verification

This change cannot be exercised locally — macos-26 runner image + its pre-installed Xcode 26.3 + iOS 26.2 simulator runtime only exist on GitHub Actions infrastructure. Real verification happens on next push.

**Expected outcomes on next CI run (4-state matrix per 999.10 T-999.10-04 acceptance pattern):**

| Outcome | Meaning | Action |
|---------|---------|--------|
| 1. build-and-test GREEN + diagnostic step shows iOS 26.2 destination | Win. Closes 260511-7vh + 260511-thn + 999.10 simultaneously. | Flip 7vh + thn from "Needs Review" → "Verified" in STATE.md; close 999.10. |
| 2. build-and-test RED on real Swift compile error | New iOS 26 SDK errors not yet visible locally — surfaces real bugs to fix | Triage; likely a separate fix quick task |
| 3. build-and-test RED on missing Xcode_26.3.app | macos-26 image rotated; bump pin to next-available Xcode 26.x | 1-line patch fix |
| 4. build-and-test GREEN in <30s (silent re-recurrence) | Should be impossible — diagnostic step + pipefail prevent it | Investigate immediately; do not trust the green |

## Hand-off

Push to main → watch CI run → expect Outcome 1. If Outcome 1, this triplet (7vh + thn + u3y) closes 999.10 end-to-end with full real-CI verification.
