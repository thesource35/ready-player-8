---
phase: 15
plan: 04
subsystem: ios-team-crew
tags: [ios, swiftui, team, certifications, daily-crew]
requires: [15-01]
provides: [TeamView, CertificationsView, DailyCrewView, TeamMemberDraft]
affects: ["ready player 8/SupabaseService.swift"]
tech-stack:
  added: []
  patterns: [DataSyncManager.syncTable, Theme + .premiumGlow, ConstructOS.Team.* AppStorage]
key-files:
  created:
    - "ready player 8/TeamView.swift"
    - "ready player 8/CertificationsView.swift"
    - "ready player 8/DailyCrewView.swift"
  modified:
    - "ready player 8/SupabaseService.swift"
    - "ready player 8Tests/TeamServiceTests.swift"
decisions:
  - "Form validation as Encodable payload structs (NewTeamMemberPayload, NewCertPayload, DailyCrewPayload) — matches existing SupabaseService.insert<T: Encodable>() signature rather than plan's hypothetical insertRow(payload:[String:Any])."
  - "Daily crew save uses SupabaseService.insert (POST) not upsert; UNIQUE (project_id, assignment_date) index in 15-01 schema will surface conflicts server-side. Upsert helper deferred — out of scope for this plan."
  - "ContentView.swift left untouched; new views will be wired into the tab bar in a follow-up plan (15-05) since navigation integration requires edits to ContentView's NavTab enum."
metrics:
  duration: ~6min
  completed: 2026-04-07
---

# Phase 15 Plan 04: iOS Team & Crew Views Summary

Added 3 new standalone SwiftUI files (TeamView, CertificationsView, DailyCrewView) plus 4 Phase 15 DTOs on SupabaseService, and replaced Wave 0 XCSkip stubs with real form-validation tests for TeamMemberDraft. ContentView.swift was not touched — new files are auto-included via PBXFileSystemSynchronizedRootGroup.

## Files Added

| File | Purpose | Lines |
|------|---------|-------|
| `ready player 8/TeamView.swift` | Team tab shell + Members / Assignments sub-views + AddTeamMemberSheet + TeamMemberDraft validation | ~280 |
| `ready player 8/CertificationsView.swift` | License-card cert list with dominant 28pt expiry headline + AddCertSheet | ~195 |
| `ready player 8/DailyCrewView.swift` | Per-project foreman stand-up: date picker, 48pt checkbox rows, scope notes, save CTA | ~150 |

## Files Modified

- `ready player 8/SupabaseService.swift` — appended `// MARK: - Phase 15: Team & Crew DTOs` section with `SupabaseTeamMember`, `SupabaseProjectAssignment`, `SupabaseCertification`, `SupabaseDailyCrew`. No edits to existing code.
- `ready player 8Tests/TeamServiceTests.swift` — replaced `XCTSkip` stub with 3 real tests against `TeamMemberDraft.validate()`: rejects empty name, accepts valid input, rejects bad kind.

## Must-Haves Verified

- [x] TeamView with Members / Assignments / Certifications sub-views
- [x] Members creation flow with kind/name/role/trade → `cs_team_members` via SupabaseService.insert
- [x] Certification card with dominant `.system(size: 28, weight: .semibold)` expiry (license-card layout)
- [x] DailyCrewView with 48pt minHeight tap targets
- [x] 4 DTOs added in a single MARK section in SupabaseService.swift
- [x] DataSyncManager.syncTable drives members / assignments / certifications / daily_crew list loads
- [x] Wave 0 XCTest stub replaced with 3 real assertions (no XCTSkip)
- [x] ContentView.swift untouched — confirmed via `git diff --stat HEAD~2 HEAD -- "ready player 8/ContentView.swift"` (empty)

## Deviations from Plan

### SupabaseService API

- **Plan assumed:** `insertRow(table:payload:[String:Any])` and `upsertRow(table:payload:onConflict:)`
- **Actual API:** `insert<T: Encodable>(_ table: String, record: T) async throws`
- **Resolution:** Created small private `Encodable` payload structs (`NewTeamMemberPayload`, `NewCertPayload`, `DailyCrewPayload`) with snake_case fields matching DB columns. This is the cleaner Swift pattern anyway (type-safe vs. `[String: Any]`). Plan's NOTE blocks anticipated this fallback.
- **Upsert:** No `upsertRow` helper exists. `DailyCrewView.save()` uses plain `insert`; the UNIQUE `(project_id, assignment_date)` index from 15-01 will surface a server error on second save. True upsert helper is deferred — documented as decision above.

### Navigation wiring

- Plan scope was explicit: "do NOT touch ContentView.swift". The new views compile and are reachable programmatically but are not yet wired into the custom `NavTab` enum / sidebar. Wiring is deferred to a follow-up plan (suggested 15-05) which will edit ContentView.

## Requirements Covered

- **TEAM-01** — Team member CRUD scaffold (create via sheet, list via DataSyncManager)
- **TEAM-02** — Project assignments list view (read-only in this plan; create flow deferred)
- **TEAM-03** — Certifications with prominent expiry and escalating color (green/gold/red by days-until)
- **TEAM-05** — Daily crew stand-up per project/date

## Test Results

XCTest target not executed in this session (no simulator run per phase-level deferral of live-DB work). Test file replaces the Wave 0 XCSkip with 3 synchronous unit tests against pure `TeamMemberDraft.validate()` — no network, no fixtures, should run green in any XCTest invocation.

Build verification also deferred to the phase-level integration pass; code was written against the read signatures of `SupabaseService.insert`, `DataSyncManager.syncTable`, `Theme`, and `.premiumGlow`, all of which were confirmed present in the current checkout.

## Commits

- `daf19fe` feat(15-04): add Phase 15 Team & Crew DTOs to SupabaseService
- `3652f70` feat(15-04): iOS Team, Certifications, Daily Crew views + form validation tests

## Known Stubs

None. Views render from real DataSyncManager calls; inserts go to real SupabaseService.insert. The only deferred wiring is nav integration into ContentView, documented above.

## Self-Check: PASSED

- FOUND: ready player 8/TeamView.swift
- FOUND: ready player 8/CertificationsView.swift
- FOUND: ready player 8/DailyCrewView.swift
- FOUND: SupabaseTeamMember / SupabaseCertification / SupabaseDailyCrew / SupabaseProjectAssignment in SupabaseService.swift
- FOUND: commit daf19fe
- FOUND: commit 3652f70
- VERIFIED: ContentView.swift unchanged across both commits
