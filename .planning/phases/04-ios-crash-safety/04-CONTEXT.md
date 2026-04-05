# Phase 4: iOS Crash Safety - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning
**Mode:** Auto-generated (infrastructure phase — discuss skipped)

<domain>
## Phase Boundary

No force unwrap or fatalError can crash the app at runtime -- all replaced with safe unwrapping and graceful fallbacks.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — pure infrastructure phase. Use ROADMAP phase goal, success criteria, and codebase conventions to guide decisions.

</decisions>

<code_context>
## Existing Code Insights

### Crash Sites Identified
- `SupabaseService.swift:217,242` — `URL(string:)!` force unwraps on auth endpoints
- `ContentView.swift:96,98,100` — `URL(string:)!` force unwraps on footer links (Terms, Privacy, Support)
- `PersistenceController.swift:42,51` — `fatalError()` on Core Data load failures
- `OperationsField.swift`, `OperationsCore.swift`, `SecurityAccessView.swift` — force unwraps to audit

### Established Patterns
- Error handling uses `AppError` enum from `AppError.swift` with cases for `.network()`, `.supabaseHTTP()`, `.decoding()`, etc.
- `CrashReporter.shared.reportError()` for logging
- Guard-let with early return is the preferred safe unwrap pattern

### Integration Points
- `SupabaseService` is used by all data-dependent views — changes must preserve API contract
- `PersistenceController` is initialized at app startup — fallback must not block launch

</code_context>

<specifics>
## Specific Ideas

No specific requirements — infrastructure phase. Refer to ROADMAP phase description and success criteria.

</specifics>

<deferred>
## Deferred Ideas

None — discuss phase skipped.

</deferred>
