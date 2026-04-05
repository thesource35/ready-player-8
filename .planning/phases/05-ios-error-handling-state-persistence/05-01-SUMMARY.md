---
phase: 05-ios-error-handling-state-persistence
plan: 01
subsystem: ios-supabase-service
tags: [error-handling, auth-hardening, state-persistence, security]
dependency_graph:
  requires: []
  provides:
    - "Hardened SupabaseService auth with token validation"
    - "Size-guarded AppStorageJSON with CrashReporter logging"
  affects:
    - "ready player 8/SupabaseService.swift"
    - "ready player 8/AppStorageJSON.swift"
tech_stack:
  added: []
  patterns:
    - "do-catch with CrashReporter.shared.reportError for all auth/encode/decode paths"
    - "Conditional Bearer token in applyHeaders rejecting empty credentials"
    - "1MB size guard on UserDefaults writes with 75% warning threshold"
key_files:
  modified:
    - "ready player 8/SupabaseService.swift"
    - "ready player 8/AppStorageJSON.swift"
decisions:
  - "Kept single try? for Task.sleep in throttle() as idiomatic Swift for non-critical sleep"
  - "Made applyHeaders throwing to enforce credential validation at all request sites"
metrics:
  duration: "2m 41s"
  completed: "2026-04-05"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 05 Plan 01: Harden SupabaseService Auth and AppStorageJSON Summary

Hardened SupabaseService auth methods with do-catch error handling, token validation, and conditional Bearer headers; added 1MB size guard to AppStorageJSON with CrashReporter logging for encode/decode failures.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Harden SupabaseService auth and credential handling | 65088a5 | ready player 8/SupabaseService.swift |
| 2 | Add AppStorageJSON size guard and verify Wealth Suite persistence | 3281905 | ready player 8/AppStorageJSON.swift |

## Changes Made

### Task 1: SupabaseService Auth Hardening (ERR-02, DATA-03, DATA-04)

- **refreshToken()**: Replaced 3 chained `try?` calls with proper `do-catch` block. Failures now logged via `CrashReporter.shared.reportError()`. Returns `accessToken != nil` instead of unconditional `true`.
- **applyHeaders()**: Changed from unconditional `Bearer \(accessToken ?? apiKey)` to conditional logic that validates token/apiKey exist before setting header. Throws `SupabaseError.notConfigured` if neither is available. Made the function `throws` and updated all 5 call sites.
- **queueWrite()**: Replaced `try? encoder.encode(record)` with do-catch that logs encoding failures.
- **listMFAFactors()**: Replaced `try? JSONDecoder().decode` with do-catch and CrashReporter logging.
- **hasMFAEnabled()**: Replaced `try? await listMFAFactors()` with do-catch and CrashReporter logging.
- **verifyMFA()**: Replaced `try? JSONSerialization.jsonObject` with do-catch and CrashReporter logging.
- **try? count**: Reduced from 8 to 1 (remaining: `try? await Task.sleep` in throttle, intentionally kept as idiomatic).

### Task 2: AppStorageJSON Size Guard (STATE-09) and Wealth Suite Verification (STATE-05/06/07/08)

- **saveJSON()**: Added 1MB size check with CrashReporter warning. Added 75% threshold debug print. Wrapped encoding in do-catch with CrashReporter logging.
- **loadJSON()**: Replaced `try?` decode with do-catch that logs failures via CrashReporter before returning default.
- **Wealth Suite verification**: Confirmed MoneyLensView (loadJSON), OpportunityFilterView (@AppStorage + loadJSON), PsychologyDecoderView (@AppStorage), and LeverageSystemView (@AppStorage) all have intact persistence patterns.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] applyHeaders made throwing required caller updates**
- **Found during:** Task 1
- **Issue:** Making `applyHeaders` throw required all 5 call sites to add `try`. The fetch/insert/update/delete methods already throw, so this was a simple addition. The `flushPendingWrites` call site was already inside a do-catch block.
- **Fix:** Added `try` prefix at all 5 call sites.
- **Files modified:** ready player 8/SupabaseService.swift
- **Commit:** 65088a5

**2. [Rule 1 - Bug] signIn already had token guard (plan expected it missing)**
- **Found during:** Task 1
- **Issue:** Plan stated signIn method "does NOT guard for nil afterward" but it already had `guard accessToken != nil` at line 266. No change needed.
- **Fix:** Verified existing guard is correct; no modification required.

## Threat Mitigations Applied

| Threat ID | Status | Implementation |
|-----------|--------|----------------|
| T-05-01 (Spoofing) | Mitigated | Token validation guard in both signUp (line 237) and signIn (line 266) |
| T-05-02 (Info Disclosure) | Mitigated | refreshToken uses do-catch with CrashReporter logging |
| T-05-03 (DoS) | Mitigated | saveJSON warns at 1MB, logs at 75% threshold |
| T-05-04 (Tampering) | Mitigated | applyHeaders rejects requests with empty credentials |

## Self-Check: PASSED

All files verified present. All commits verified in git log.
