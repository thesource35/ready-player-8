# Quick 260512-nn1: 999.7(b) bootstrap-from-zero migration — Research

**Researched:** 2026-05-12
**Confidence:** HIGH (inline; codebase + grep evidence)

## Headline finding

**999.7(b) is substantially already closed.** The original backlog framing from 2026-04-28 was written before `00000000000_baseline_pre_migration_tables.sql` was authored. That file (commit context: ~2026-04-28) addresses the core concern.

## What's actually in the repo

### `supabase/migrations/00000000000_baseline_pre_migration_tables.sql`

- 372 lines
- 19 CREATE TABLE statements with `IF NOT EXISTS` (idempotent on prod, applies cleanly on fresh DB)
- All 19 tables from the original backlog list:
  - cs_projects, cs_contracts, cs_market_data, cs_ai_messages, cs_change_orders, cs_decision_journal, cs_feed_posts, cs_leverage_snapshots, cs_ops_alerts, cs_psychology_sessions, cs_punch_pro, cs_rental_leads, cs_rfis, cs_tax_expenses, cs_timecards, cs_transactions, cs_wealth_opportunities, cs_wealth_tracking, cs_daily_logs
- Filename uses 11 leading zeros so it sorts BEFORE `001_updated_at_triggers.sql` (which depends on these tables)

### Header comment (lines 21-27) explicitly documents out-of-scope

```
-- Out of scope (deferred to a real "baseline-cleanup" phase):
--   - GRANT / ALTER OWNER statements (require superuser; service-role
--     and Supabase-managed roles handle access in practice)
--   - COMMENT ON statements (would require schema-owner privileges)
--   - Indexes on these tables (Phase-specific migrations add what's
--     needed; missing indexes can be added in a follow-up)
--   - RLS policies — added by 20260428002..004 multi-tenancy migrations
```

The superuser-required statements that the backlog warned about (`ALTER OWNER`, `GRANT`, `CREATE TYPE`) were **deliberately stripped** during file authoring. Zero such statements exist in the file body.

### Cross-reference: cs_* tables across all migrations

- **24 distinct cs_* tables have CREATE TABLE migrations**: 19 in baseline + 5 in phase migrations (cs_photo_annotations, cs_project_log_templates, cs_punch_items, cs_safety_incidents, cs_submittals)
- The ~50 other cs_* "references" in grep output are mostly index names, policy names, FK constraint names, enum-type names — false positives for "missing table" detection

## What still cannot be verified locally

**Real-staging end-to-end test.** Confirming `supabase db push --include-all` succeeds against a genuinely empty Supabase project requires:
1. Provisioning a fresh Supabase project (cost + cleanup overhead)
2. Linking the local repo to it
3. Running the full push
4. Tearing down

This is a user-initiated action — cannot be autonomously verified.

## Research answers to the 5 open questions

| # | Question | Answer |
|---|---|---|
| 1 | Exact prod schema for each of the 19 tables | Already captured in `00000000000_baseline_pre_migration_tables.sql` (faithful prod schema dump from 2026-04-28) |
| 2 | FK dependency graph | Baseline file uses no FKs (deliberate — keeps the file simple + applies in any order). FKs are added by later phase migrations (org_id FKs in 20260428002..004 multi-tenancy migrations) |
| 3 | cs_* tables BEYOND the 19 lacking migrations | None found via grep. The 24 cs_* tables that have CREATE TABLE migrations cover the universe. cs_report_* orphans mentioned in 999.5(f) are separate (consumers shipped but never expected to work; deferred to a focused reporting phase) |
| 4 | Best practice for superuser statements | Already followed: stripped from baseline; documented in header as out-of-scope. Service-role and Supabase-managed roles handle access in practice |
| 5 | Should cs_report_schedules be in baseline | NO. It was promoted via separate migration `20260511001_phase19_report_schedules_promote.sql` (quick task 260510-v81). Keeping it separate preserves Phase 19 traceability |

## Recommendation

**Mark 999.7(b) closed-pending-staging-verify in ROADMAP.md.** Document:
- What's done (the baseline file, idempotent, superuser-statement-clean)
- The single remaining unknown (real staging E2E test — user-initiated)
- Recovery path if the staging test reveals a gap (recommend a 999.7(c) row at that point)

This honors today's "honesty win" theme: don't claim closed when only verified, don't keep open when 95% done with a clear gap rationale.

## References

- `supabase/migrations/00000000000_baseline_pre_migration_tables.sql` — the baseline file
- ROADMAP.md row 999.7 — current backlog state
- Commit `2c688ec` (2026-05-11) — closed 999.7(a) (bare-timestamp rename)
- Commit `748320d` (quick 260510-v81) — promoted cs_report_schedules separately
- 20260428002..004 — multi-tenancy migrations adding RLS + FKs to baseline tables
