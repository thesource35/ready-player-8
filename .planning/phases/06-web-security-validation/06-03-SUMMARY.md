---
phase: 06-web-security-validation
plan: 03
subsystem: web-projects
tags: [validation, persistence, form-feedback, security]
dependency_graph:
  requires: []
  provides: [database-persisting-add-project-form, client-side-validation-feedback]
  affects: [web/src/app/projects/page.tsx]
tech_stack:
  added: []
  patterns: [async-form-submit, inline-validation-error, maxLength-input-constraints]
key_files:
  modified:
    - web/src/app/projects/page.tsx
decisions:
  - key: persist-via-post
    summary: "Wire addProject to POST /api/projects instead of local-only state update"
  - key: client-side-validation
    summary: "Validate name and client fields before API call to provide instant feedback"
metrics:
  duration_seconds: 106
  completed: 2026-04-05T18:55:22Z
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 06 Plan 03: Wire addProject to POST /api/projects Summary

Projects add form now persists to Supabase via POST /api/projects with client-side validation and inline error feedback for empty fields and API failures.

## What Was Done

### Task 1: Wire addProject to POST /api/projects with validation feedback
**Commit:** 720abdc

Replaced the local-only `addProject()` function with an async version that:

1. **Client-side validation** -- checks that project name and client name are non-empty (trimmed), shows specific error messages inline in the form
2. **Database persistence** -- sends POST to `/api/projects` with trimmed fields, uses server-returned data to populate the local project list
3. **Error handling** -- displays API error messages (e.g., "Sign in required", "Failed to create project") and network errors in a styled inline error banner
4. **Loading state** -- disables the Save button and shows "Saving..." text during the API call
5. **Input constraints** -- added `maxLength` attributes to all 4 form inputs (name: 200, client: 200, type: 100, budget: 50) and the search input (200) to mitigate T-06-12 (DoS via oversized input)
6. **Error clearing** -- clears addError when the Add Project button is toggled open

## Deviations from Plan

None -- plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-06-11 (Tampering) | Client-side validation for name/client + server-side validation in route handler |
| T-06-12 (DoS) | maxLength on all 5 inputs (4 form + 1 search) |
| T-06-13 (Info Disclosure) | Error messages are generic, no stack traces exposed |

## Known Stubs

None -- all form functionality is fully wired to the API.

## Self-Check: PASSED
