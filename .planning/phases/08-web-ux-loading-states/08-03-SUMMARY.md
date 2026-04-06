---
phase: 08-web-ux-loading-states
plan: 03
subsystem: web-ux
tags: [ssr-safety, feature-gating, premium-features]
dependency_graph:
  requires: [08-02]
  provides: [ssr-safe-angelic-toggle, punch-feature-gate, trust-feature-gate]
  affects: [web/src/app/components/AngelicPromptToggle.tsx, web/src/app/punch/page.tsx, web/src/app/trust/page.tsx, web/src/lib/subscription/featureAccess.ts, web/src/lib/subscription/featurePreviews.ts]
tech_stack:
  added: []
  patterns: [PremiumFeatureGate-wrapping, SSR-safe-localStorage]
key_files:
  created: []
  modified:
    - web/src/app/components/AngelicPromptToggle.tsx
    - web/src/lib/subscription/featureAccess.ts
    - web/src/lib/subscription/featurePreviews.ts
    - web/src/app/punch/page.tsx
    - web/src/app/trust/page.tsx
decisions:
  - Used typeof window guard in useState initializer rather than useEffect-only pattern to prevent SSR crash while keeping synchronous initial state
  - Extracted page content into non-exported helper functions (PunchPageContent, TrustPageContent) following plan specification rather than inline JSX wrapping used by ops page
metrics:
  duration: 1815s
  completed: 2026-04-06T00:47:00Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 5
---

# Phase 08 Plan 03: SSR Fix and Feature Gating Summary

SSR-safe localStorage guard in AngelicPromptToggle plus PremiumFeatureGate wrapping for punch and trust pages with PM-tier feature key registration.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Fix AngelicPromptToggle SSR safety and register feature keys | 260ad72 | typeof window guard, punch-list/trust-score keys in featurePlanMap and previewMap |
| 2 | Wrap punch and trust pages with PremiumFeatureGate | 78656fe | PunchPageContent/TrustPageContent extraction, PremiumFeatureGate wrappers |

## Changes Made

### AngelicPromptToggle SSR Fix
- Added `if (typeof window === "undefined") return true;` as first line inside the useState initializer callback
- This prevents the SSR crash caused by direct `window.localStorage` access during server-side rendering
- Default value of `true` (enabled) matches the existing fallback behavior

### Feature Key Registration
- Added `"punch-list": "pm"` and `"trust-score": "pm"` to featurePlanMap in featureAccess.ts
- Kept existing `punch: "pm"` entry intact (may be used by other code paths)
- Added full preview entries for both features in featurePreviews.ts with titles, descriptions, highlights, and example data

### Page Gating
- Punch page: imported PremiumFeatureGate, renamed body to PunchPageContent (non-exported), wrapped with `<PremiumFeatureGate feature="punch-list">`
- Trust page: imported PremiumFeatureGate, renamed body to TrustPageContent (non-exported), wrapped with `<PremiumFeatureGate feature="trust-score">`
- Both follow the same pattern but use extracted content functions per plan specification

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

All 5 files verified present. Both commits (260ad72, 78656fe) verified in git log.
