---
phase: 260511-thn
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - "ready player 8/AppInfrastructure.swift"
  - "ready player 8/LeverageSystemView.swift"
  - "/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md"
autonomous: true
requirements:
  - QUICK-260511-thn-CI-FIX
must_haves:
  truths:
    - "iOS build succeeds for iPhone 17 Simulator (local default)"
    - "iOS build succeeds for iPhone 16 Pro / iOS 18.5 (CI parity)"
    - "CrashReporter.reportError(...) is callable from nonisolated free functions (loadJSON/saveJSON) without Swift concurrency errors"
    - "All 74 existing CrashReporter.shared.reportError(...) call sites compile unchanged"
    - "LeverageSystemView's Chart body resolves to ChartContentBuilder (not MapContentBuilder)"
    - "MEMORY.md states iOS 18.2+ matching project.pbxproj truth"
  artifacts:
    - path: "ready player 8/AppInfrastructure.swift"
      provides: "nonisolated reportError API"
      contains: "nonisolated func reportError"
    - path: "ready player 8/LeverageSystemView.swift"
      provides: "Chart body extracted into @ChartContentBuilder var"
      contains: "@ChartContentBuilder"
    - path: "/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md"
      provides: "iOS deployment target matching pbxproj"
      contains: "iOS 18.2+"
  key_links:
    - from: "AppStorageJSON.swift loadJSON/saveJSON (nonisolated free funcs)"
      to: "CrashReporter.shared.reportError(...)"
      via: "direct call from nonisolated context"
      pattern: "CrashReporter\\.shared\\.reportError"
    - from: "LeverageSystemView.leverageHistoryPanel"
      to: "Chart { leverageChartContent }"
      via: "@ChartContentBuilder private var"
      pattern: "@ChartContentBuilder"
---

<objective>
Fix the two iOS compile errors surfaced by the 999.10 CI honesty fix and reconcile MEMORY.md to pbxproj truth, so the next CI push lands a green build-and-test on macos-15 + Xcode 16.4 + iPhone 16 Pro/iOS 18.5.

Purpose: 999.10 closed the silent no-op trap in CI -- now the build genuinely runs and surfaces real Swift 6 strict-concurrency + Charts type-inference errors that have been latent. Unblocking next push.

Output:
- 1-line nonisolated modifier on CrashReporter.reportError (unblocks 74 cross-codebase call sites simultaneously)
- ~15-line surgical extraction of LeverageSystemView Chart body into @ChartContentBuilder var (disambiguates result-builder resolution)
- 1-line MEMORY.md correction (iOS 26.2+ -> iOS 18.2+)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/260511-thn-fix-ios-compile-errors-surfaced-by-999-1/260511-thn-CONTEXT.md

# Source files being modified (current state on main)
@ready player 8/AppInfrastructure.swift
@ready player 8/AppStorageJSON.swift
@ready player 8/LeverageSystemView.swift

<interfaces>
<!-- Current state of CrashReporter.reportError (line 86 of AppInfrastructure.swift) -->
<!-- Class is @MainActor -- the API change makes the FUNCTION nonisolated while leaving class-level @Published state isolated -->

```swift
// CURRENT (line 73-100 of AppInfrastructure.swift):
@MainActor
final class CrashReporter: ObservableObject {
    static let shared = CrashReporter()
    @Published var crashLogs: [CrashLog] = []
    private let key = "ConstructOS.Crashes"

    init() {
        crashLogs = loadJSON(key, default: [CrashLog]())
        setupCrashHandler()
    }

    func reportError(_ error: String, file: String = #file, line: Int = #line, function: String = #function) {
        let log = CrashLog(...)
        crashLogs.insert(log, at: 0)
        if crashLogs.count > 100 { crashLogs = Array(crashLogs.prefix(100)) }
        saveJSON(key, value: crashLogs)
    }
    ...
}
```

```swift
// CURRENT (lines 9-43 of AppStorageJSON.swift):
// Free functions in module scope -- CALLER context is nonisolated by default.
// These currently fail to compile because they cross the @MainActor boundary
// to call reportError() without await/Task hop.
func loadJSON<T: Decodable>(_ key: String, default defaultValue: T) -> T {
    ...
    } catch {
        CrashReporter.shared.reportError("AppStorageJSON decode failed for key '\(key)': \(error.localizedDescription)")
        ...
    }
}

func saveJSON<T: Encodable>(_ key: String, value: T) {
    ...
        if sizeBytes > oneMB {
            CrashReporter.shared.reportError(...)
        }
    ...
    } catch {
        CrashReporter.shared.reportError("AppStorageJSON encode failed for key '\(key)': \(error.localizedDescription)")
    }
}
```

```swift
// CURRENT (LeverageSystemView.swift lines 137-146):
// ForEach inside Chart {} is being inferred as MapContentBuilder content
// because some other file in the module transitively imports MapKit.
// Chart {} itself takes a @ChartContentBuilder closure but the type checker
// can't disambiguate without an explicit hint.
Chart {
    ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
        LineMark(
            x: .value("Date", snapshot.createdAt),
            y: .value("Total", snapshot.totalScore)
        )
        .foregroundStyle(Theme.cyan)
        .symbol(Circle())
    }
}
.chartYScale(domain: 0...100)
.chartYAxis { ... }
.frame(height: 140)
.padding(14).background(Theme.surface).cornerRadius(12)
.premiumGlow(cornerRadius: 12, color: Theme.cyan)
```
</interfaces>

# Established precedent (per CONTEXT.md canonical_refs)
- **Compile-only verification** is the standard for iOS work in this codebase since Phase 22 (re-affirmed Phase 29.1, 30, 30.1). `xcodebuild build` (NOT `build-for-testing`) is the green-light criterion. Pre-existing async errors in `ready_player_8Tests.swift` + `ReportTests.swift` block `build-for-testing` and are tracked in phase deferred-items -- DO NOT attempt to fix them in this scope.
- **Project structure preserved per CLAUDE.md constraint**: the monolithic ContentView.swift is NOT touched; AppInfrastructure.swift and LeverageSystemView.swift are already extracted files and we modify in place.
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix Swift 6 concurrency + Chart inference compile errors</name>
  <files>ready player 8/AppInfrastructure.swift, ready player 8/LeverageSystemView.swift</files>
  <action>
Make TWO surgical edits in a single commit (both unblock `xcodebuild build`; verify together).

**Edit A — AppInfrastructure.swift line 86 (per D-01 nonisolated decision):**

Change the function signature from:
```swift
    func reportError(_ error: String, file: String = #file, line: Int = #line, function: String = #function) {
```

To:
```swift
    nonisolated func reportError(_ error: String, file: String = #file, line: Int = #line, function: String = #function) {
```

ONE-WORD addition (`nonisolated` prefix). DO NOT touch:
- The `@MainActor` class-level annotation on `CrashReporter` (line 73)
- The function body (lines 87-100)
- The `@Published var crashLogs` declaration
- Any of the 74 caller sites in the codebase

**Threat T-thn-01 mitigation (in-memory buffer race):** The function body mutates `crashLogs: [CrashLog]` (`@Published` array) and calls `saveJSON()` (which writes UserDefaults). Making the FUNCTION nonisolated while the CLASS stays `@MainActor` means Swift will:
1. Allow the function to be CALLED from any context (this is what we want — fixes the 74 callers + the 3 AppStorageJSON sites)
2. Still treat `self.crashLogs` access inside the body as crossing into MainActor isolation — the compiler will error if the body is not safe.

If Swift 6 strict mode rejects the nonisolated body because of `crashLogs` mutation:
- **First fallback:** Wrap the body in `Task { @MainActor in ... }` (changes log ordering — acceptable for fire-and-forget logging).
- **Second fallback:** Switch to `nonisolated(unsafe)` and add a comment `// TODO(swift6-audit): formal Sendable guard when SWIFT_VERSION=6.0`.
- Do NOT cascade `@MainActor` to the 74 callers.

Pre-edit grep proof (run before editing):
```bash
grep -n "func reportError" "ready player 8/AppInfrastructure.swift"
# Expect: 1 hit at line 86
```

Post-edit grep proof:
```bash
grep -c "nonisolated func reportError" "ready player 8/AppInfrastructure.swift"
# Expect: 1
```

**Edit B — LeverageSystemView.swift lines 137-146 (per D-02 @ChartContentBuilder decision):**

Choose pattern (a) from CONTEXT specifics: extract Chart body to a private `@ChartContentBuilder` computed var. Place the new var IMMEDIATELY ABOVE `private var leverageHistoryPanel: some View` (around line 122) so it lives in the same MARK section.

Add this new computed property:
```swift
    @ChartContentBuilder private var leverageChartContent: some ChartContent {
        ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
            LineMark(
                x: .value("Date", snapshot.createdAt),
                y: .value("Total", snapshot.totalScore)
            )
            .foregroundStyle(Theme.cyan)
            .symbol(Circle())
        }
    }
```

Then replace the inline Chart body at lines 137-146:
```swift
                Chart {
                    ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
                        LineMark(
                            x: .value("Date", snapshot.createdAt),
                            y: .value("Total", snapshot.totalScore)
                        )
                        .foregroundStyle(Theme.cyan)
                        .symbol(Circle())
                    }
                }
```

With:
```swift
                Chart { leverageChartContent }
```

DO NOT modify:
- The `.chartYScale`, `.chartYAxis`, `.frame`, `.padding`, `.background`, `.cornerRadius`, `.premiumGlow` modifiers below the Chart (they remain on the same line of code as before, attached to the new `Chart { leverageChartContent }`)
- The category breakdown HStack at lines 162-177
- Any other view in the file

**Threat T-thn-02 mitigation (naming collision):** Before editing, grep for the proposed name to confirm it does not collide:
```bash
grep -n "leverageChartContent" "ready player 8/LeverageSystemView.swift"
# Expect: 0 hits (name is free)
```

**Whether to bundle NetworkClient.swift:143 Sendable warning** (per CONTEXT Claude's Discretion): Run the build first AFTER edits A+B. If `xcodebuild build` exits 0 with the warning still present, DO NOT touch NetworkClient — leave it for a Swift 6 audit phase per the CONTEXT discretion guidance (keep scope tight). If it is a hard compile-blocker after edits A+B, address it inline with the minimal fix and document in the SUMMARY.

**Verification commands (run in order):**

Local default (per CONTEXT discretion + Phase 29.1 precedent):
```bash
cd "/Users/beverlyhunter/Desktop/ready player 8"
xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" 2>&1 | tail -50
# Expect: ** BUILD SUCCEEDED **
```

CI parity (per CONTEXT discretion -- this is what 999.10 CI now runs):
```bash
xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" 2>&1 | tail -50
# Expect: ** BUILD SUCCEEDED **
```

If iPhone 17 sim isn't available locally, fall back per CONTEXT discretion:
```bash
xcrun simctl list devices available | grep -E "iPhone (16|17)"
# Use whatever's listed.
```

Grep proofs:
```bash
grep -c "nonisolated func reportError" "ready player 8/AppInfrastructure.swift"   # 1
grep -c "@ChartContentBuilder" "ready player 8/LeverageSystemView.swift"           # 1
grep -c "leverageChartContent" "ready player 8/LeverageSystemView.swift"           # 2  (declaration + call site)
```

DO NOT run `build-for-testing` or `xcodebuild test` — pre-existing async errors in `ready_player_8Tests.swift` + `ReportTests.swift` block those targets and are explicitly out of scope per CONTEXT canonical_refs (Phase 22/29.1/30 compile-only precedent).
  </action>
  <verify>
<automated>cd "/Users/beverlyhunter/Desktop/ready player 8" && xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17" 2>&1 | tail -10 | grep -q "BUILD SUCCEEDED" && xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5" 2>&1 | tail -10 | grep -q "BUILD SUCCEEDED" && [ "$(grep -c 'nonisolated func reportError' 'ready player 8/AppInfrastructure.swift')" = "1" ] && [ "$(grep -c '@ChartContentBuilder' 'ready player 8/LeverageSystemView.swift')" = "1" ]</automated>
  </verify>
  <done>
- `xcodebuild build` exits 0 against iPhone 17 sim (local default)
- `xcodebuild build` exits 0 against iPhone 16 Pro / iOS 18.5 (CI parity — what next push will face)
- `nonisolated func reportError` appears exactly 1 time in AppInfrastructure.swift
- `@ChartContentBuilder` appears exactly 1 time in LeverageSystemView.swift
- `leverageChartContent` appears exactly 2 times in LeverageSystemView.swift (declaration + call site)
- Zero new errors or warnings beyond what was on `main` before this commit (verified via diff of pre/post build output)
- Zero modifications to: project.pbxproj, web/, ContentView.swift, ready_player_8Tests.swift, ReportTests.swift, NetworkClient.swift (unless promoted by hard build-blocker per discretion)
  </done>
</task>

<task type="auto">
  <name>Task 2: Reconcile MEMORY.md iOS deployment target to pbxproj truth</name>
  <files>/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md</files>
  <action>
Per D-03 ("Trust pbxproj"), update the user-memory MEMORY.md so it stops claiming `iOS 26.2+` when `project.pbxproj` actually deploys to iOS 18.2.

Edit MEMORY.md line 6:

FROM:
```
- iOS 26.2+, macOS 15.6+, visionOS supported
```

TO:
```
- iOS 18.2+, macOS 15.6+, visionOS supported
```

ONE-CHARACTER-CLASS change (`26.2` -> `18.2`). DO NOT modify:
- The `macOS 15.6+` portion (per CONTEXT specifics: "the macOS target should also be cross-checked" — but the CONTEXT decision section only locks the iOS fix, so macOS stays untouched in this quick task)
- Any other line in MEMORY.md
- Bundle ID, file structure, or any other claim

**Verification commands:**

```bash
grep -c "iOS 26.2" "/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md"
# Expect: 0

grep -c "iOS 18.2" "/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md"
# Expect: >= 1
```

Cross-check that pbxproj is still 18.2 (sanity — should be unchanged):
```bash
grep -c "IPHONEOS_DEPLOYMENT_TARGET = 18.2" "/Users/beverlyhunter/Desktop/ready player 8/ready player 8.xcodeproj/project.pbxproj"
# Expect: >= 1 (truth source unchanged)
```
  </action>
  <verify>
<automated>[ "$(grep -c 'iOS 26.2' '/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md')" = "0" ] && [ "$(grep -c 'iOS 18.2' '/Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md')" -ge "1" ]</automated>
  </verify>
  <done>
- MEMORY.md no longer contains the string `iOS 26.2`
- MEMORY.md contains `iOS 18.2+` on the App Overview line
- project.pbxproj remains untouched (still `IPHONEOS_DEPLOYMENT_TARGET = 18.2` — truth source preserved)
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| nonisolated free fn -> @MainActor class state | `loadJSON`/`saveJSON` (nonisolated) call `CrashReporter.shared.reportError(...)` which mutates `@Published var crashLogs` (MainActor-isolated) |
| Module-level result-builder resolution | `Chart { ForEach { ... } }` closure resolves against multiple result-builder candidates when MapKit is transitively imported elsewhere in the module |
| User-memory documentation | MEMORY.md is point-in-time observation file; pbxproj is build-truth |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-thn-01 | Tampering (data race) | `CrashReporter.crashLogs` array mutation from nonisolated `reportError` body | mitigate | Function body still references `self.crashLogs` (a `@MainActor` `@Published`); Swift will require correctness inside the nonisolated body. If compiler accepts the body as-is (most likely — it's a single-actor mutation reachable only via the @MainActor class), no race exists. If compiler rejects, fallback ladder: `Task { @MainActor in ... }` body wrap (acceptable log-ordering shift), then `nonisolated(unsafe)` with `TODO(swift6-audit)` marker. |
| T-thn-02 | Confusion (naming collision) | New `leverageChartContent` private var on `LeverageSystemView` | mitigate | Pre-edit `grep -n "leverageChartContent" "ready player 8/LeverageSystemView.swift"` MUST return 0 hits before adding the property. Name is feature-specific (`leverage` prefix) so global collisions are vanishingly unlikely. |
| T-thn-03 | Test target regression | `ready_player_8Tests.swift` + `ReportTests.swift` pre-existing async errors | accept | This plan uses `xcodebuild build` only, NOT `build-for-testing`. Per Phase 22/29.1/30/30.1 compile-only precedent (CONTEXT canonical_refs), test target failures are a separate deferred item. Adding a test fix here would expand scope and risk new errors. |
| T-thn-04 | Information Disclosure | MEMORY.md doc edit | accept | MEMORY.md is local user memory (not in repo, not deployed). The edit reduces a misleading claim, no information leak. |
| T-thn-05 | Repudiation (silent CI green) | Build verification trusts `BUILD SUCCEEDED` string | mitigate | Verify command pipes `xcodebuild` to `tail -10 | grep -q "BUILD SUCCEEDED"` AND parallel checks grep proofs (the actual code change is present). If `BUILD SUCCEEDED` appears but greps fail, the verify fails (compound `&&`). This is the same pattern that caught the 999.10 CI silent no-op trap. |
</threat_model>

<verification>
## Phase-level checks

1. `xcodebuild build` GREEN against BOTH destinations (local default iPhone 17 + CI parity iPhone 16 Pro/iOS 18.5)
2. Three grep proofs PASS (nonisolated, @ChartContentBuilder, MEMORY.md cleanup)
3. `git diff --stat` shows ONLY the 3 files in `files_modified` were touched (no scope creep into pbxproj, web/, ContentView, test files, NetworkClient unless explicitly promoted)
4. No new compiler warnings introduced beyond what existed on `main` before the commit (compare warning-line counts pre/post)

## Out of scope (do NOT verify)

- `xcodebuild test` or `xcodebuild build-for-testing` — pre-existing async errors block these per Phase 22/29.1/30 deferred-items
- Web build (`npm run build`, `npm test`) — this is iOS-only per CONTEXT
- Real CI run — that's the NEXT push after this commit; this plan trusts CI parity destination locally
</verification>

<success_criteria>
- ✅ `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 17"` exits 0
- ✅ `xcodebuild build -scheme "ready player 8" -destination "platform=iOS Simulator,name=iPhone 16 Pro,OS=18.5"` exits 0 (CI parity)
- ✅ `grep -c "nonisolated func reportError" "ready player 8/AppInfrastructure.swift"` = 1
- ✅ `grep -c "@ChartContentBuilder" "ready player 8/LeverageSystemView.swift"` = 1
- ✅ `grep -c "iOS 26.2" /Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md` = 0
- ✅ `grep -c "iOS 18.2" /Users/beverlyhunter/.claude/projects/-Users-beverlyhunter-Desktop-ready-player-8/memory/MEMORY.md` ≥ 1
- ✅ `git diff --name-only` shows exactly: `ready player 8/AppInfrastructure.swift`, `ready player 8/LeverageSystemView.swift` (MEMORY.md is outside repo)
- ✅ Next CI push (after commit) is expected to land green build-and-test on macos-15 — the ACTUAL pass is observed on the next push (deferred per Phase 22/29.1/30 precedent), but this plan ships the local-equivalent green
</success_criteria>

<output>
After completion, create `.planning/quick/260511-thn-fix-ios-compile-errors-surfaced-by-999-1/260511-thn-SUMMARY.md` with:

- Verification table: 4 named expected outcomes for the next CI push (mirroring 260511-7vh's 4-outcome SUMMARY pattern from STATE.md):
  1. iPhone 17 sim local build = SUCCESS
  2. iPhone 16 Pro/iOS 18.5 sim local build (CI parity) = SUCCESS
  3. Next CI push build-and-test job = expected GREEN (real-CI verification deferred)
  4. NetworkClient.swift:143 Sendable warning = either fixed (if was hard blocker) or explicitly deferred to Swift 6 audit phase
- Diff stat: file count + line count for the 3 edits
- Whether T-thn-01 fallback ladder was triggered (if `nonisolated` alone sufficed, note that — provides data for future Swift 6 work)
- Cross-reference to backlog 999.10 (this is the FIRST push that exercises the un-silenced CI; outcomes feed back into 999.10's deferred CI verification)
</output>
