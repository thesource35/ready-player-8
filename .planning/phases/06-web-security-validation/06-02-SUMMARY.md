---
phase: 06-web-security-validation
plan: 02
subsystem: web-forms
tags: [validation, security, forms, input-sanitization]
dependency_graph:
  requires: []
  provides: [client-side-form-validation, input-length-limits]
  affects: [login-page, profile-page, jobs-page, rentals-page]
tech_stack:
  added: []
  patterns: [email-regex-validation, phone-regex-validation, maxLength-attributes]
key_files:
  created: []
  modified:
    - web/src/app/login/page.tsx
    - web/src/app/profile/page.tsx
    - web/src/app/jobs/page.tsx
    - web/src/app/rentals/page.tsx
decisions:
  - Used inline EMAIL_REGEX constant per file rather than shared util to keep changes minimal and self-contained
  - Applied RFC 5321 max email length (254 chars) for all email inputs
metrics:
  duration: 5m
  completed: 2026-04-05T18:58:54Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 06 Plan 02: Client-Side Form Validation Summary

Add email regex, phone format, and maxLength input validation to login, profile, jobs, and rental pages; fix rental form race condition showing false success.

## What Was Done

### Task 1: Email/Phone Validation + Race Condition Fix
- Added `EMAIL_REGEX` (`/^[^\s@]+@[^\s@]+\.[^\s@]+$/`) validation to login `handleAuth()` and `handleForgotPassword()` before Supabase calls
- Replaced weak `email.includes("@")` check on profile page with proper regex validation
- Added `EMAIL_REGEX` validation to jobs page `handleSubmit()` for optional `contactEmail` field
- Added `EMAIL_REGEX` and `PHONE_REGEX` (`/^\+?[\d\s\-().]{7,20}$/`) validation to rentals `submitLead()`
- Fixed rental form race condition: removed unconditional `setSubmitted(true)` after catch block; success screen now only appears when `res.ok` is true
- Added `validationError` state and error display UI to rentals quote form
- Added proper error handling for non-ok API responses in rentals (parses error JSON, shows message)

### Task 2: maxLength Attributes
- Added 39 `maxLength` attributes across all 4 form pages:
  - Login: 10 attributes (email=254, password=128, confirmPassword=128, fullName=200, company=200, title=100, location=200, phone=20, forgot-email=254, 2FA code already had maxLength=6)
  - Profile: 10 attributes (fullName=200, email=254, phone=20, location=200, bio=1000, company=200, title=100, experience=3, licenseNumber=50, licenseState=10)
  - Jobs: 9 attributes (title=200, company=200, location=200, pay=50, startLabel=100, duration=100, description=5000, requirements=2000, contactEmail=254)
  - Rentals: 10 attributes (equipmentType=200, quantity=4, rentalStart=50, projectName=300, projectLocation=300, notes=2000, fullName=200, email=254, phone=20, company=200)

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 698121c | Email/phone validation and rental form race condition fix |
| 2 | 89ba819 | maxLength attributes on all text inputs |

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-06-07 | EMAIL_REGEX validation before Supabase auth call on login page |
| T-06-08 | Email + phone regex validation on rental form; success only on res.ok |
| T-06-09 | 39 maxLength attributes prevent oversized input payloads |
| T-06-10 | EMAIL_REGEX validation on jobs contactEmail before POST |

## Self-Check: PASSED
