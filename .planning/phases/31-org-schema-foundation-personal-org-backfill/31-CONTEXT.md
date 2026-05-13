# Phase 31: Org Schema Foundation & Personal-Org Backfill — Context

**Gathered:** 2026-05-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile v2.1's tactical multi-tenancy schema with v2.2's canonical architecture spec. The tables `user_orgs` + `cs_organizations` already exist on prod (shipped by 20260413001 + 20260428002..006 + 20260509001 RLS recursion fix). Phase 31 closes the remaining schema gap: ships `cs_org_invitations`, adds a `slug` column to `cs_organizations`, and ships an idempotent backfill+audit migration that bootstraps a fresh DB OR no-ops on prod.

**Not in scope for Phase 31:** REST endpoints (Phase 32), active-org UI (Phase 33), settings pages (Phase 34), E2E verification (Phase 35).

</domain>

<decisions>
## Implementation Decisions

### Schema reconciliation (table names + role model)
- **D-01:** Keep v2.1 table names. `user_orgs` and `cs_organizations` are CANONICAL — no rename. REQUIREMENTS.md ORG-01/02 must be updated to match (was `cs_orgs` + `cs_user_orgs` — those names never reflected reality).
- **D-02:** Three roles: `owner`, `admin`, `member`. NO `viewer` role. The 4-role version in yesterday's roadmap was speculation; v2.1's 2026-04-28 design session locked 3 roles and that lock holds. Construction-industry read-only stakeholders can be handled at the application layer (read-only flags) if needed in a future phase.

### Primary-org semantics (is_primary column)
- **D-03:** Keep `is_primary boolean` on `user_orgs` (already shipped in v2.1 with partial unique index `where is_primary = true`). Active-org resolution at runtime is:
  1. Session preference (web cookie `cs_active_org`, iOS `@AppStorage("ConstructOS.ActiveOrgId")`) if present AND user is a member
  2. Falls back to user's `is_primary` org
  3. Falls back to first membership (any deterministic order — e.g. ordered by `joined_at`)
  - This decision DIRECTLY informs Phase 33's active-org context work. `is_primary` is the persistent anchor; session overrides for per-device preference.
  - New users: their auto-created personal org is marked `is_primary = true` by the existing signup trigger.

### Backfill scope (idempotent, audit-first)
- **D-04:** Phase 31 ships ONE migration that does both audit + idempotent backfill in one transaction:
  - **Audit phase:** RAISE NOTICE counts of (a) rows with NULL `org_id` per cs_* table (~47 tables), (b) rows with `org_id` not in `cs_organizations.id` (orphan refs). Non-blocking — surfaces gaps in CI logs.
  - **Backfill phase:** `INSERT INTO cs_organizations ... WHERE NOT EXISTS` for any auth.users row without a personal org. `UPDATE cs_*` SET org_id = (lookup) `WHERE org_id IS NULL` for each table.
  - On existing prod: largely no-op (v2.1 backfill is presumed complete) — audit becomes the verification artifact.
  - On fresh staging or future bootstrap: full personal-org creation + cs_* backfill. This is the v2.2 contribution to 999.7(b)'s "bootstrap from zero" story.
  - **Idempotency invariants:** re-running produces zero new rows and zero updates on a fully-backfilled DB. ON CONFLICT DO NOTHING on INSERT; WHERE org_id IS NULL on UPDATE.

### Invitation table scope
- **D-05:** Phase 31 ships `cs_org_invitations` table + RLS. Phase 32 builds the REST endpoints on top. Rationale: schema-in-31, API-in-32 separation. The table needs RLS policies that reference `user_orgs.role` and `cs_organizations`, which are also Phase 31 territory. Keeping all schema reconciliation in one phase makes RLS review tractable.
  - Schema: `id uuid primary key`, `org_id uuid references cs_organizations(id) on delete cascade`, `email text not null`, `role text check (role in ('owner','admin','member')) not null`, `token text unique not null` (cryptographic, generated app-side), `expires_at timestamptz not null default now() + interval '7 days'`, `accepted_at timestamptz null`, `invited_by uuid references auth.users(id) not null`, `created_at timestamptz not null default now()`.
  - RLS: SELECT/INSERT/UPDATE limited to org admins+owners via `public.user_org_ids(array['owner','admin'])`; invitee can SELECT their own row by token-lookup pattern (handled in Phase 32 endpoint, not in RLS).

### Slug generation
- **D-06:** Add `slug text unique not null` column to `cs_organizations`. Algorithm:
  - Base: lowercase the org name, replace non-alphanumeric with `-`, collapse repeated `-`, trim leading/trailing `-`. Truncate to 60 chars.
  - Collision handling: if base slug exists, append `-{6-char-random-hex}` and retry. Max 3 retries (collision after 3 tries is astronomically unlikely with 6-hex-char suffix = 16^6 = 16M).
  - Existing rows: backfill in Phase 31's migration using the org's `name` column.
  - Personal orgs: auto-create trigger generates slug from user's display name or email-local-part.
- **Claude's Discretion:** exact regex pattern, exact retry count, exact suffix length. The above is the recommended baseline.

### Claude's Discretion
- Audit query exact SQL form (CTE vs explicit per-table queries — performance trade-off at 47 tables)
- Whether to ship slug generation as a SQL function in the migration or as application code with a DB constraint
- Order of operations within the single migration (audit first → backfill → invitations → slug column) vs alternative orderings
- Naming of the new migration file (will follow `YYYYMMDD###_phase31_*.sql` convention)
- RLS policy names for `cs_org_invitations` (follow project convention: `cs_org_invitations_select` etc.)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v2.1 multi-tenancy foundation (what's already shipped — read carefully)
- `supabase/migrations/20260413001_user_orgs_multi_tenancy.sql` — Original multi-tenancy foundation. Header documents the 2026-04-28 design session: composite PK, 3 roles, signup auto-create trigger, one-org-per-existing-user backfill. NOT INCLUDED list explicitly defers `cs_org_invitations` to "separate phase" — Phase 31 owns it now.
- `supabase/migrations/20260428002_org_id_core_tables.sql` — org_id propagation to cs_user_profiles, cs_projects, cs_contracts, cs_team_members
- `supabase/migrations/20260428003_group_b_org_scoped_rls.sql` — Group B (12 project-scoped tables): cs_activity_events, cs_ops_alerts, cs_punch_pro, cs_timecards, cs_change_orders, cs_project_assignments, cs_rfis, cs_transactions, etc.
- `supabase/migrations/20260428004_group_e_rls_audit.sql` — Group E (10 ambiguous tables, individually audited)
- `supabase/migrations/20260428005_group_d_user_personal_rls.sql` — Group D (user-personal tables by design)
- `supabase/migrations/20260428006_group_d_residue_user_personal_rls.sql` — Group D residue (cleanup pass)
- `supabase/migrations/20260509001_*.sql` — RLS recursion fix + `public.user_org_ids(filter_roles text[])` SECURITY DEFINER helper. ALL RLS policies in v2.2 onward MUST use this helper, not direct subqueries.

### v2.2 milestone artifacts
- `.planning/REQUIREMENTS.md` "v2.2 Requirements — Multi-tenancy Foundation" section — needs update to match D-01/D-02 (table names + 3 roles, not 4)
- `.planning/ROADMAP.md` Phase 31 entry (line 400) — Goal, Success Criteria, Plans=TBD
- `.planning/PROJECT.md` v2.2 Current Milestone block — 4 locked architecture decisions

### Project conventions
- `CLAUDE.md` — file-organization constraint ("Don't break apart monolithic files"), backward-compat constraint, both-platforms constraint
- `.planning/STATE.md` "Accumulated Context" — Phase 26 / Phase 28 migration timestamp collision history (relevant when picking the new migration timestamp)

### v2.1 → v2.2 reconciliation references (no external specs — captured in decisions above)
- D-01/D-02 contradict yesterday's REQUIREMENTS.md ORG-01/02 spec. The reconciliation work in Phase 31 includes updating REQUIREMENTS.md to match v2.1 reality.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`public.user_org_ids(filter_roles text[])` SECURITY DEFINER helper** (20260509001) — non-recursive helper that returns the orgs the current user belongs to, optionally filtered by role. ALL RLS policies must use this. Phase 31's `cs_org_invitations` RLS must call `public.user_org_ids(array['owner','admin'])` for invite/manage permissions.
- **Auto-create-on-signup trigger** (20260413001) — already inserts user_orgs row + cs_organizations row for new auth.users entries. Phase 31's backfill targets existing users (signed up before v2.1 trigger was active) AND will extend the trigger to also generate a slug.
- **Partial unique index `user_orgs_primary_idx`** — `where is_primary = true` enforces at most one primary per user. Useful for the "promote new primary" transaction pattern in future phases.

### Established Patterns
- **47-table RLS audit pattern** (20260428003-006) — multi-tenancy migrations were organized into Groups A/B/D/E by access pattern. Phase 31's audit query should follow the same grouping.
- **Migration timestamp convention** — `YYYYMMDD###_phase##_descriptive_name.sql` (per Phase 26 collision-recovery convention captured in STATE.md). Phase 31 picks `20260513001_phase31_*.sql` (or current date).
- **RLS recursion avoidance** — never query `user_orgs` in a policy on `user_orgs` (or any table that does). Always route through `public.user_org_ids()`.

### Integration Points
- **`auth.users INSERT trigger`** — extend (or replace) the existing signup trigger to also generate slug. Migration approach: CREATE OR REPLACE FUNCTION to preserve OID and avoid trigger churn.
- **Migration ordering matters** — Phase 31 migration must run AFTER 20260509001 (the helper exists), and the new `cs_org_invitations` RLS must use the helper, not direct subqueries.
- **`cs_organizations` ALTER for slug column** — must populate existing rows BEFORE applying NOT NULL constraint. Order: ADD COLUMN (nullable) → UPDATE all rows with generated slug → ALTER COLUMN SET NOT NULL → CREATE UNIQUE INDEX.

</code_context>

<specifics>
## Specific Ideas

- **"Honor the 2026-04-28 design session lock"** — D-01/D-02 explicitly defer to v2.1's locked decisions. The v2.2 spec was written without reading the v2.1 migration header; Phase 31's first job is reconciling those.
- **"Construction-industry users with one primary org should get zero-friction"** — drove D-03 (keep is_primary). Multi-org IS supported (composite PK), but the common case is one-primary-org per user. is_primary is the anchor that makes this UX clean.
- **"Audit before mutation"** — the migration logs counts before any UPDATE/INSERT runs. If audit shows orphan rows, the migration log captures it; remediation can be a follow-up scoped migration rather than a blind backfill.

</specifics>

<deferred>
## Deferred Ideas

- **Viewer role for read-only stakeholders (clients, inspectors, accountants)** — explicitly out of scope for v2.2. Construction-industry use case is real but adding the 4th role expands all RLS surface. If needed: backlog row for v2.3+ that adds 'viewer' to the role check + extends per-table RLS to differentiate write vs read.
- **Invitation lifecycle endpoints** — Phase 32 owns `/api/orgs/[id]/invite` + `/api/orgs/invitations/[token]/accept`. Phase 31 only ships the table + RLS.
- **Org switcher UI (web header dropdown, iOS COMMAND tab)** — Phase 33.
- **Org settings UI (members list, name editing, danger zone)** — Phase 34.
- **Multi-org E2E smoke test** — Phase 35.
- **999.7(c) recovery path** — if Phase 31's idempotent backfill reveals real gaps in v2.1's prod state, open 999.7(c) for the remediation. (Per the 999.7(b) closure annotation.)

</deferred>

---

*Phase: 31-org-schema-foundation-personal-org-backfill*
*Context gathered: 2026-05-13*
