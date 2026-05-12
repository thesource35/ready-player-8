# Quick Task 260511-thn: Fix iOS compile errors surfaced by 999.10 CI - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Task Boundary

Fix the iOS build-and-test compile errors surfaced by the 999.10 CI honesty fix (commit `e03d681` red on push). Two distinct error classes plus a memory-vs-truth discrepancy:

1. **Swift 6 strict-concurrency error** at `ready player 8/AppStorageJSON.swift:17,30,41` — free functions `loadJSON()`/`saveJSON()` call `@MainActor CrashReporter.shared.reportError(...)` from nonisolated contexts. Xcode 16.4 + SWIFT_VERSION 5.0 still rejects this. Sister sites at `AppEnvironment.swift:43` and `NetworkClient.swift:143` (Sendable warning) bundled.
2. **Chart-builder type-inference error** at `ready player 8/LeverageSystemView.swift:138` — `ForEach` inside `Chart {}` is being inferred as `MapContentBuilder` instead of `ChartContentBuilder`. Source file imports only Charts/Foundation/SwiftUI; some other file in the module is transitively bringing MapContentBuilder into scope.
3. **Project memory drift** — `MEMORY.md` claims "iOS 26.2+" but `project.pbxproj:310` says `IPHONEOS_DEPLOYMENT_TARGET = 18.2`. pbxproj is the build-truth.

Goal: green build-and-test on next CI push, with 74 cross-codebase `CrashReporter.shared.reportError(...)` call sites unblocked by a single API change.

</domain>

<decisions>
## Implementation Decisions

### Concurrency strategy for CrashReporter.reportError()

**Decision: Make `reportError(...)` nonisolated.**

One-line API change in `ready player 8/AppInfrastructure.swift:86` — add `nonisolated` modifier to the function. Fixes all 74 call sites at once without touching any caller. Class `CrashReporter` stays `@MainActor` for its `@Published` state.

**Why safe**: `reportError` is logging-only (append to in-memory buffer + print + notify) — no UI work, no MainActor-required state mutation. The `@Published` notification is itself thread-safe via Combine.

**Why not the alternatives**:
- Marking helpers `@MainActor`: would cascade requirement to ~74 callers, many of which are background/sync paths (Codable initializers, network completion handlers).
- `Task { @MainActor in ... }` wrapping: changes log ordering (interleaving), loses sync guarantees, requires touching all 74 sites.
- `nonisolated(unsafe)`: shifts safety burden to reviewers; bad precedent before formal Swift 6 adoption.

### Chart inference fix

**Decision: Add explicit `@ChartContentBuilder` annotation.**

Surgical 1-line fix at `LeverageSystemView.swift:138`. Add `@ChartContentBuilder` either via an explicit closure type annotation or a wrapper function. Disambiguates the result-builder resolution so the compiler can't fall back to `MapContentBuilder`.

**Why not the alternatives**:
- Hunt the transitive MapKit import: slower, doesn't prevent recurrence in other files (any future Charts code in the same module hits the same trap).
- Refactor to `Chart(leverageHistory) { ... }`: works but changes the API shape unnecessarily; the `@ChartContentBuilder` annotation is the minimal patch.

### Project memory drift (iOS 26.2+ vs pbxproj 18.2)

**Decision: Trust pbxproj. Update MEMORY.md to say "iOS 18.2+".**

`project.pbxproj` is the actual build truth. The codebase deploys to iOS 18.2; CI is correctly running against iOS 18.5 simulator (matching). Zero code change; one MEMORY.md edit.

**Why not the alternatives**:
- Bumping pbxproj to 26.2 would cut off iOS 18-25 users without evidence we actually USE iOS 26 APIs.
- Deferring would leave a documented contradiction in the project memory that could mislead future sessions.

### Claude's Discretion

- **Whether to also fix the `NetworkClient.swift:143` Sendable warning** (`'responses' of 'Sendable'-conforming class 'MockAPIClient' is mutable`): if it's a build-blocker after the concurrency fix, address it inline; if it's a `!` warning that doesn't block compilation, leave it for a separate Swift 6 audit phase to keep this scope tight.
- **Local verification destination**: prefer `iPhone 17` (matches Phase 22/29.1/30.x convention per CLAUDE.md). If iPhone 17 sim isn't available locally, fall back to whatever Xcode lists with `xcrun simctl list devices`. Bonus: also verify against `iPhone 16 Pro,OS=18.5` to match CI exactly.
- **Whether to also bundle a 75th-call-site audit**: skip — making `reportError` nonisolated is a strict superset of any caller-side fix, so unverified callers are automatically OK after the API change.

</decisions>

<specifics>
## Specific Ideas

- **`AppInfrastructure.swift` line 86 currently:** `func reportError(_ error: String, file: String = #file, line: Int = #line, function: String = #function)` — add `nonisolated` prefix.
- **`LeverageSystemView.swift` line 137-146 currently:**
  ```swift
  Chart {
      ForEach(leverageHistory.sorted(by: { $0.createdAt < $1.createdAt })) { snapshot in
          LineMark(x: .value("Date", snapshot.createdAt), y: .value("Total", snapshot.totalScore))
              .foregroundStyle(Theme.cyan)
              .symbol(Circle())
      }
  }
  ```
  Two viable `@ChartContentBuilder` patterns:
  (a) extract to a private helper: `@ChartContentBuilder private var leverageChartContent: some ChartContent { ... }` then `Chart { leverageChartContent }`.
  (b) annotate inline via closure type: `Chart { @ChartContentBuilder in ... }` (Swift 5.7+ inline result-builder syntax).

- **`MEMORY.md`** — find the line "iOS 26.2+, macOS 15.6+, visionOS supported" and change `iOS 26.2+` to `iOS 18.2+` (matching pbxproj). Note: the macOS target should also be cross-checked.

</specifics>

<canonical_refs>
## Canonical References

- `project.pbxproj` lines 310, 357, 501, 527, 552 (and ~14 more) — `IPHONEOS_DEPLOYMENT_TARGET = 18.2` (canonical truth)
- `project.pbxproj` lines 326, 373, 512, 538, 563 — `SWIFT_VERSION = 5.0`
- `STATE.md` Phase 22/29.1/30 "compile-only verification adopted" precedent for handling pre-existing test errors
- `30.1-VERIFICATION.md` for the established threat-model + scoped-edit pattern
- CI run `25706962432` — the red build-and-test job that surfaced these errors after 999.10 landed (commit `e03d681`)
- Apple docs: `@MainActor` class isolation + `nonisolated` member exception (https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Actor-Isolation)

</canonical_refs>
