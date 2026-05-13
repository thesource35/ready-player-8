# Phase 31: Org Schema Foundation & Personal-Org Backfill — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-13
**Phase:** 31-org-schema-foundation-personal-org-backfill
**Areas discussed:** Schema reconciliation, is_primary semantics, Backfill verification, Invitation table scope

---

## Scouting findings that drove the discussion

Before any user questions, scouted the codebase and surfaced a critical mismatch:
- v2.1 migration `20260413001_user_orgs_multi_tenancy.sql` header documents a 2026-04-28 design session that locked: **3 roles (owner/admin/member)**, table names `user_orgs` + `cs_organizations`, `cs_org_invitations` explicitly deferred.
- Yesterday's v2.2 REQUIREMENTS.md spec (ORG-01..04) assumed: **4 roles incl viewer**, table names `cs_orgs` + `cs_user_orgs`.
- Blast radius: 16 migration files reference `user_orgs`, 8 reference `cs_organizations`. Renaming would mean 24+ file updates.

This finding made schema reconciliation the #1 gray area.

---

## Schema reconciliation (table names + roles)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep v2.1 names + 3 roles | Honor 2026-04-28 lock. `user_orgs` + `cs_organizations` + 3 roles stay. Update REQUIREMENTS.md ORG-01/02 to match. Phase 31 becomes purely additive: cs_org_invitations + slug column + backfill audit. | ✓ |
| Keep v2.1 names, add viewer role | ALTER role check constraint to allow 'viewer'. Minor migration. | |
| Rename to canonical v2.2 names + 4 roles | Rename user_orgs → cs_user_orgs, cs_organizations → cs_orgs, add viewer. 24+ file blast radius. | |
| Pause and audit first | Read all 16 + 8 references before deciding. | |

**User's choice:** Keep v2.1 names + 3 roles (Recommended)
**Notes:** Honors the 2026-04-28 design session lock. Reconciliation work is now: update REQUIREMENTS.md ORG-01/02 to match v2.1 reality (NOT a rename).

---

## is_primary column semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Keep as sticky default; cookie/@AppStorage overrides | is_primary stays. Active-org = cookie/@AppStorage > is_primary > first-membership. New users auto-set is_primary on personal org. | ✓ |
| Drop is_primary entirely | ALTER TABLE DROP COLUMN. Active-org = cookie/@AppStorage with first-membership fallback. New device = no remembered preference. | |
| Keep is_primary, deprecate cookie/@AppStorage idea | is_primary IS the active org. UI switch updates DB. Cookie/storage just caches. | |

**User's choice:** Keep as sticky default; cookie/@AppStorage overrides (Recommended)
**Notes:** Construction-industry users with one primary org get zero-friction; multi-org users can still switch per-device via cookie/@AppStorage. is_primary is the persistent anchor; session overrides for current device.

---

## Backfill verification + reconciliation

| Option | Description | Selected |
|--------|-------------|----------|
| Idempotent backfill + audit | One migration: audits NULL org_ids + orphan refs across 47 cs_* tables (RAISE NOTICE), then INSERT WHERE NOT EXISTS + UPDATE WHERE NULL. On prod: largely no-op. On fresh staging: full bootstrap. | ✓ |
| Audit-only (read-only) | Report NULL org_ids + orphan refs but don't change anything. Conservative. | |
| Skip backfill in Phase 31 entirely | Trust v2.1; only add cs_org_invitations + slug. Push idempotent bootstrap to 999.7(c). | |
| Full backfill rerun (defensive) | Re-run v2.1 logic with idempotency guards. Highest blast radius. | |

**User's choice:** Idempotent backfill + audit (Recommended)
**Notes:** Matches REQ ORG-04 idempotency clause. Audit phase surfaces gaps in CI logs without blocking. Connects to 999.7(b) bootstrap-from-zero story — Phase 31's migration becomes part of the fresh-project bootstrap.

---

## cs_org_invitations table scope

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 31 owns the table | Schema-in-31, API-in-32 separation. Table + RLS in 31; endpoints in 32. All schema reconciliation in one phase. | ✓ |
| Phase 32 owns it (atomic invitation feature) | Reassign ORG-03 from 31 → 32. Table + endpoints + RLS as one cohesive feature. Phase 31 stays minimal. | |

**User's choice:** Phase 31 owns the table (Recommended)
**Notes:** RLS policies on cs_org_invitations need to reference user_orgs.role and cs_organizations — also Phase 31 territory. Keeping all schema reconciliation + RLS work in one phase makes review tractable.

---

## Claude's Discretion

User did not explicitly defer any decisions, but the following are not load-bearing user choices and were captured as Claude's discretion in CONTEXT.md:
- Audit query exact SQL form (CTE vs explicit per-table queries)
- Slug generation regex pattern, retry count, suffix length (D-06 baseline recommended but algorithm specifics are implementation)
- Migration ordering within the single Phase 31 migration
- RLS policy names for cs_org_invitations (follow project convention)

## Deferred Ideas

- **Viewer role** — out of scope for v2.2. If needed for read-only stakeholders, future v2.3+ backlog.
- **Invitation endpoints** — Phase 32 owns the API.
- **Org switcher UI** — Phase 33.
- **Org settings UI** — Phase 34.
- **Multi-org E2E** — Phase 35.
- **999.7(c) recovery** — if Phase 31's audit reveals real gaps in v2.1's prod state, open 999.7(c).
