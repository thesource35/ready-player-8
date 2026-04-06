---
phase: 09-web-performance-dynamic-content
plan: 04
subsystem: billing, database
tags: [square, checkout, payment-method, supabase, triggers, updated_at]
dependency_graph:
  requires: []
  provides: [payMethod-passthrough, updated_at-triggers]
  affects: [web/src/lib/billing/square.ts, web/src/app/api/billing/checkout/route.ts, supabase/migrations/001_updated_at_triggers.sql]
tech_stack:
  added: []
  patterns: [url-parameter-passthrough, idempotent-sql-migration, plpgsql-trigger-function]
key_files:
  created:
    - supabase/migrations/001_updated_at_triggers.sql
  modified:
    - web/src/lib/billing/square.ts
    - web/src/app/api/billing/checkout/route.ts
    - web/src/lib/billing/plans.ts
    - web/scripts/schema.sql
decisions:
  - Used preferred_payment_method URL param name for Square payment link passthrough
  - Made payMethod optional with card as default (no URL modification for card)
  - Applied triggers to all 19 cs_* tables listed in plan regardless of current updated_at column presence
metrics:
  duration: 287s
  completed: 2026-04-06
  tasks: 2/2
  files: 5
---

# Phase 09 Plan 04: Square Checkout payMethod and updated_at Triggers Summary

Square checkout now passes user-selected payment method as URL parameter; Supabase migration adds BEFORE UPDATE triggers for automatic updated_at timestamps on all 19 cs_* tables.

## Tasks Completed

### Task 1: Pass payment method through Square checkout URL
- **Commit:** 88d405a
- Added `payMethod?: PaymentMethodId` parameter to `getSquarePaymentLink`
- Appends `preferred_payment_method={payMethod}` to Square URL for non-card methods
- Updated both POST and GET handlers in checkout route to pass validated payMethod through
- Confirmed billing interval passthrough already working (uses different env var keys per interval)

### Task 2: Create Supabase migration for updated_at triggers
- **Commit:** a4f4bb7
- Created `update_updated_at_column()` plpgsql trigger function
- Applied `set_updated_at` BEFORE UPDATE trigger to all 19 cs_* tables
- Migration is fully idempotent (DROP IF EXISTS + CREATE OR REPLACE)
- Added reference comment in `web/scripts/schema.sql`

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

All 5 files verified present. Both commit hashes (88d405a, a4f4bb7) confirmed in git log.
