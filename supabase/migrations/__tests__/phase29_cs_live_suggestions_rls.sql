-- Owner: 29-01-PLAN.md Wave 1 — LIVE-05 smoke test for cs_live_suggestions RLS
-- Run: psql $DATABASE_URL -f supabase/migrations/__tests__/phase29_cs_live_suggestions_rls.sql
-- Expectation (post-migration): listed assertions pass; each \echo line documents the test.
--
-- Wave 1 plan 29-01 will flesh these out. For now this is a scaffolding placeholder so the
-- <automated> command in that plan resolves to an existing file.

\echo 'TODO Wave 1 plan 29-01: verify cs_live_suggestions table exists, RLS enabled, 2 policies (select + update/dismiss)'
\echo 'TODO Wave 1 plan 29-01: verify cross-org SELECT returns 0 rows under a different org_id JWT'
\echo 'TODO Wave 1 plan 29-01: verify UPDATE policy only allows dismissed_by = auth.uid()'
