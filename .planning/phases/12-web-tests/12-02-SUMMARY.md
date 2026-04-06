---
phase: 12-web-tests
plan: 02
subsystem: web-api-tests
tags: [testing, vitest, webhooks, billing, security]
dependency_graph:
  requires: []
  provides: [paddle-webhook-tests, checkout-route-tests]
  affects: [web/src/app/api/webhooks/paddle/, web/src/app/api/billing/checkout/]
tech_stack:
  added: []
  patterns: [vitest-mocking, hmac-signature-testing, type-guard-testing]
key_files:
  created:
    - web/src/app/api/webhooks/paddle/route.test.ts
    - web/src/app/api/billing/checkout/route.test.ts
  modified: []
decisions:
  - Used real HMAC-SHA256 via crypto.subtle for realistic signature verification tests
  - Adapted payment method tests to use actual values (card/apple/google) instead of plan-specified cashapp/afterpay which do not exist in the codebase
metrics:
  duration: 5m
  completed: "2026-04-06T15:51:07Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
  test_count: 18
  test_pass: 18
  test_fail: 0
---

# Phase 12 Plan 02: Webhook and Checkout Route Tests Summary

Vitest unit tests for Paddle webhook HMAC signature verification (9 cases) and checkout route input validation (9 cases), covering payment-critical security paths.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Paddle webhook unit tests (WTEST-06) | 00e310f | web/src/app/api/webhooks/paddle/route.test.ts |
| 2 | Checkout flow unit tests (WTEST-07) | 3e493f4 | web/src/app/api/billing/checkout/route.test.ts |

## Test Coverage

### Paddle Webhook (9 tests)
- Missing PADDLE_WEBHOOK_SECRET returns 503
- Missing Supabase env vars returns 503
- Missing paddle-signature header returns 401
- Tampered body (valid sig but body changed) returns 401
- Expired timestamp (10 min old, exceeds 5 min window) returns 401
- Valid signature with subscription.created upserts tier, returns success
- subscription.canceled sets tier to "free"
- Non-subscription event (transaction.completed) returns received: true
- Unknown user (no email match) returns warning

### Checkout Route (9 tests)
- Valid POST with planId/billing/payMethod returns 200 with provider, payMethod, url
- Invalid planId returns 400 "Invalid plan selection"
- Invalid billing returns 400 "Invalid billing interval"
- Unsupported payment method returns 400
- Invalid JSON body returns 400
- No Square payment link configured returns 503
- Apple payMethod passthrough in response
- Valid GET redirect returns 307 with square.link location
- Invalid GET plan returns 400

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Adapted payment method test values to match actual codebase**
- **Found during:** Task 2
- **Issue:** Plan specified "cashapp" and "afterpay" as valid payment methods, but actual PAYMENT_METHOD_IDS in plans.ts are ["card", "apple", "google"]. Tests with cashapp would fail validation (400) instead of testing the intended happy path.
- **Fix:** Used "apple" instead of "cashapp" for the payment method passthrough test. Used "crypto" for the invalid payment method test (correctly rejected).
- **Files modified:** web/src/app/api/billing/checkout/route.test.ts

## Verification

```
vitest run -- 2 passed, 18 tests, 0 failures
```

## Self-Check: PASSED

- [x] web/src/app/api/webhooks/paddle/route.test.ts exists (211 lines, min 100)
- [x] web/src/app/api/billing/checkout/route.test.ts exists (146 lines, min 80)
- [x] Commit 00e310f exists (Task 1)
- [x] Commit 3e493f4 exists (Task 2)
- [x] All 18 tests pass (9 + 9)
