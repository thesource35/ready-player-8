-- Phase 26: Documents RLS Table Reconciliation — Migration A (stub tables + RLS)
-- Closes INT-01 by creating backing tables for every cs_document_entity_type enum value
-- that currently lacks one: rfi, submittal, change_order (Phase 13 gap) and
-- safety_incident, punch_item (Phase 16 enum extension gap; cs_daily_logs already exists).
--
-- Decisions: D-01 stub strategy; D-02 five-table pass; D-03 minimum joinable shape;
--            D-04 copy cs_daily_logs RLS pattern; D-05 two-migration split (this = A);
--            D-13 non-blocking pre-migration audit via RAISE NOTICE.
--
-- Threat mitigations:
--   T-26-01 Authorization bypass — every table gets ENABLE ROW LEVEL SECURITY
--            BEFORE any CREATE POLICY; no unprotected window.
--   T-26-05 Privilege escalation — INSERT/UPDATE restricted to
--            admin/project_manager/superintendent (matches cs_daily_logs).
--   T-26-03 RLS policy gap window — whole migration wrapped in a single transaction.

BEGIN;

-- =========================================================================
-- 0. Pre-migration audit (D-13) — non-blocking RAISE NOTICE of attachment
--    row counts grouped by entity_type. Production should show zero non-project
--    rows (the Phase 13 silent-skip RLS would have blocked inserts), but we
--    surface the pre-state for operator visibility.
-- =========================================================================
DO $audit$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT entity_type::text AS et, count(*) AS n
        FROM cs_document_attachments
        GROUP BY entity_type
        ORDER BY entity_type
    LOOP
        RAISE NOTICE 'phase26-audit cs_document_attachments entity_type=% count=%', rec.et, rec.n;
    END LOOP;
EXCEPTION WHEN OTHERS THEN
    -- Never block the migration on the audit.
    RAISE NOTICE 'phase26-audit skipped: %', SQLERRM;
END
$audit$;

-- =========================================================================
-- 1. Stub tables (D-03: minimum joinable shape — id, org_id, project_id, created_at)
--    No status/title/created_by — future feature phases own every other column.
-- =========================================================================
CREATE TABLE IF NOT EXISTS cs_rfis (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cs_submittals (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cs_change_orders (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cs_safety_incidents (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cs_punch_items (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id     UUID NOT NULL,
    project_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================================================================
-- 2. Enable RLS on every stub table BEFORE creating any policy.
--    T-26-01 mitigation: no unprotected window between CREATE TABLE and policy creation.
-- =========================================================================
ALTER TABLE cs_rfis             ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_submittals       ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_change_orders    ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_punch_items      ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- 3. RLS policies — copy the cs_daily_logs pattern from 20260408005 lines 186–250.
--    SELECT: authenticated user with cs_project_assignments row for the project.
--    INSERT/UPDATE: role_on_project IN ('admin','project_manager','superintendent').
--    (No DELETE policy — stubs are not user-mutable surfaces yet.)
-- =========================================================================

-- ---- cs_rfis ----
DROP POLICY IF EXISTS cs_rfis_select ON cs_rfis;
CREATE POLICY cs_rfis_select ON cs_rfis
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_rfis.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_rfis_insert ON cs_rfis;
CREATE POLICY cs_rfis_insert ON cs_rfis
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_rfis.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_rfis_update ON cs_rfis;
CREATE POLICY cs_rfis_update ON cs_rfis
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_rfis.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_rfis.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

-- ---- cs_submittals ----
DROP POLICY IF EXISTS cs_submittals_select ON cs_submittals;
CREATE POLICY cs_submittals_select ON cs_submittals
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_submittals.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_submittals_insert ON cs_submittals;
CREATE POLICY cs_submittals_insert ON cs_submittals
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_submittals.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_submittals_update ON cs_submittals;
CREATE POLICY cs_submittals_update ON cs_submittals
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_submittals.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_submittals.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

-- ---- cs_change_orders ----
DROP POLICY IF EXISTS cs_change_orders_select ON cs_change_orders;
CREATE POLICY cs_change_orders_select ON cs_change_orders
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_change_orders.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_change_orders_insert ON cs_change_orders;
CREATE POLICY cs_change_orders_insert ON cs_change_orders
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_change_orders.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_change_orders_update ON cs_change_orders;
CREATE POLICY cs_change_orders_update ON cs_change_orders
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_change_orders.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_change_orders.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

-- ---- cs_safety_incidents ----
DROP POLICY IF EXISTS cs_safety_incidents_select ON cs_safety_incidents;
CREATE POLICY cs_safety_incidents_select ON cs_safety_incidents
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_safety_incidents.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_safety_incidents_insert ON cs_safety_incidents;
CREATE POLICY cs_safety_incidents_insert ON cs_safety_incidents
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_safety_incidents.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_safety_incidents_update ON cs_safety_incidents;
CREATE POLICY cs_safety_incidents_update ON cs_safety_incidents
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_safety_incidents.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_safety_incidents.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

-- ---- cs_punch_items ----
DROP POLICY IF EXISTS cs_punch_items_select ON cs_punch_items;
CREATE POLICY cs_punch_items_select ON cs_punch_items
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_punch_items.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_punch_items_insert ON cs_punch_items;
CREATE POLICY cs_punch_items_insert ON cs_punch_items
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_punch_items.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_punch_items_update ON cs_punch_items;
CREATE POLICY cs_punch_items_update ON cs_punch_items
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_punch_items.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_punch_items.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

COMMIT;
