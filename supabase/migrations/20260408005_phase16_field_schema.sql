-- Phase 16: Field Tools — Step 2 of 2
-- Adds GPS columns to cs_documents, creates cs_photo_annotations,
-- cs_daily_logs, cs_project_log_templates, and RLS policies.
--
-- REQUIRES: 20260408_phase16_extend_entity_type_enum.sql to be applied first
-- (Postgres requires enum-extension to commit before new values are usable).

-- =========================================================================
-- 1. GPS source enum
-- =========================================================================
DO $$ BEGIN
    CREATE TYPE cs_gps_source AS ENUM ('fresh', 'stale_last_known', 'manual_pin');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- =========================================================================
-- 2. cs_documents — GPS + captured_at columns (D-02)
-- =========================================================================
ALTER TABLE cs_documents
    ADD COLUMN IF NOT EXISTS gps_lat NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS gps_lng NUMERIC(9,6),
    ADD COLUMN IF NOT EXISTS gps_accuracy_m NUMERIC,
    ADD COLUMN IF NOT EXISTS gps_source cs_gps_source,
    ADD COLUMN IF NOT EXISTS captured_at TIMESTAMPTZ;

-- NOTE: cs_documents has no project_id column (project linkage flows through
-- cs_document_attachments). Index captured_at alone for time-range queries.
CREATE INDEX IF NOT EXISTS idx_cs_documents_captured_at
    ON cs_documents (captured_at);

-- =========================================================================
-- 3. cs_photo_annotations (D-09, D-13)
-- =========================================================================
CREATE TABLE IF NOT EXISTS cs_photo_annotations (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id     UUID NOT NULL REFERENCES cs_documents(id) ON DELETE CASCADE,
    org_id          UUID NOT NULL,
    layer_json      JSONB NOT NULL,
    schema_version  SMALLINT NOT NULL DEFAULT 1,
    created_by      UUID,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by      UUID,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT cs_photo_annotations_document_unique UNIQUE (document_id)
);

CREATE INDEX IF NOT EXISTS idx_cs_photo_annotations_document
    ON cs_photo_annotations (document_id);

-- =========================================================================
-- 4. cs_daily_logs (D-15, D-17)
-- =========================================================================
CREATE TABLE IF NOT EXISTS cs_daily_logs (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id                   UUID NOT NULL,
    project_id               UUID NOT NULL,
    log_date                 DATE NOT NULL,
    template_snapshot_jsonb  JSONB,
    content_jsonb            JSONB,
    weather_jsonb            JSONB,
    created_by               UUID,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_by               UUID,
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Defensive: if a prior phase created cs_daily_logs with a different shape,
-- add any missing Phase 16 columns so the rest of this migration succeeds.
ALTER TABLE cs_daily_logs
    ADD COLUMN IF NOT EXISTS org_id                  UUID,
    ADD COLUMN IF NOT EXISTS project_id              UUID,
    ADD COLUMN IF NOT EXISTS log_date                DATE,
    ADD COLUMN IF NOT EXISTS template_snapshot_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS content_jsonb           JSONB,
    ADD COLUMN IF NOT EXISTS weather_jsonb           JSONB,
    ADD COLUMN IF NOT EXISTS created_by              UUID,
    ADD COLUMN IF NOT EXISTS created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    ADD COLUMN IF NOT EXISTS updated_by              UUID,
    ADD COLUMN IF NOT EXISTS updated_at              TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$ BEGIN
    ALTER TABLE cs_daily_logs
        ADD CONSTRAINT cs_daily_logs_project_date_unique UNIQUE (project_id, log_date);
EXCEPTION WHEN duplicate_table THEN NULL;
         WHEN duplicate_object THEN NULL;
END $$;

CREATE INDEX IF NOT EXISTS idx_cs_daily_logs_project_date
    ON cs_daily_logs (project_id, log_date);

-- =========================================================================
-- 5. cs_project_log_templates (D-17)
-- =========================================================================
CREATE TABLE IF NOT EXISTS cs_project_log_templates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id          UUID NOT NULL,
    project_id      UUID NOT NULL,
    template_jsonb  JSONB,
    updated_by      UUID,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE cs_project_log_templates
    ADD COLUMN IF NOT EXISTS org_id         UUID,
    ADD COLUMN IF NOT EXISTS project_id     UUID,
    ADD COLUMN IF NOT EXISTS template_jsonb JSONB,
    ADD COLUMN IF NOT EXISTS updated_by     UUID,
    ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMPTZ NOT NULL DEFAULT now();

DO $$ BEGIN
    ALTER TABLE cs_project_log_templates
        ADD CONSTRAINT cs_project_log_templates_project_unique UNIQUE (project_id);
EXCEPTION WHEN duplicate_table THEN NULL;
         WHEN duplicate_object THEN NULL;
END $$;

-- =========================================================================
-- 6. Enable RLS
-- =========================================================================
ALTER TABLE cs_photo_annotations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_daily_logs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_project_log_templates ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- 7. RLS policies
-- =========================================================================

-- ---- cs_photo_annotations (D-18) ----
-- SELECT/INSERT/UPDATE/DELETE allowed iff caller can SELECT the parent
-- cs_documents row. We delegate to the Phase 13 SELECT predicate by using
-- an EXISTS subquery against cs_documents — RLS on cs_documents will be
-- evaluated for the inner SELECT, so this automatically inherits the
-- correct visibility rules. Mitigates T-16-RLS.

DROP POLICY IF EXISTS cs_photo_annotations_select ON cs_photo_annotations;
CREATE POLICY cs_photo_annotations_select ON cs_photo_annotations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM cs_documents d
            WHERE d.id = cs_photo_annotations.document_id
        )
    );

DROP POLICY IF EXISTS cs_photo_annotations_insert ON cs_photo_annotations;
CREATE POLICY cs_photo_annotations_insert ON cs_photo_annotations
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_documents d
            WHERE d.id = cs_photo_annotations.document_id
        )
    );

DROP POLICY IF EXISTS cs_photo_annotations_update ON cs_photo_annotations;
CREATE POLICY cs_photo_annotations_update ON cs_photo_annotations
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_documents d
            WHERE d.id = cs_photo_annotations.document_id
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_documents d
            WHERE d.id = cs_photo_annotations.document_id
        )
    );

DROP POLICY IF EXISTS cs_photo_annotations_delete ON cs_photo_annotations;
CREATE POLICY cs_photo_annotations_delete ON cs_photo_annotations
    FOR DELETE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_documents d
            WHERE d.id = cs_photo_annotations.document_id
        )
    );

-- ---- cs_daily_logs (D-19) ----
-- SELECT: any authenticated user assigned to the project (Phase 15
-- cs_project_assignments) or org admin.
-- INSERT/UPDATE: created_by::text = auth.uid()::text OR admin OR PM/superintendent in
-- cs_project_assignments. Mitigates T-16-IDOR.

DROP POLICY IF EXISTS cs_daily_logs_select ON cs_daily_logs;
CREATE POLICY cs_daily_logs_select ON cs_daily_logs
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_daily_logs.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_daily_logs_insert ON cs_daily_logs;
CREATE POLICY cs_daily_logs_insert ON cs_daily_logs
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (
            created_by::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM cs_project_assignments pa
                JOIN cs_team_members tm ON tm.id = pa.member_id
                WHERE pa.project_id = cs_daily_logs.project_id
                  AND tm.user_id    = auth.uid()
                  AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
            )
        )
    );

DROP POLICY IF EXISTS cs_daily_logs_update ON cs_daily_logs;
CREATE POLICY cs_daily_logs_update ON cs_daily_logs
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND (
            created_by::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM cs_project_assignments pa
                JOIN cs_team_members tm ON tm.id = pa.member_id
                WHERE pa.project_id = cs_daily_logs.project_id
                  AND tm.user_id    = auth.uid()
                  AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
            )
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (
            created_by::text = auth.uid()::text
            OR EXISTS (
                SELECT 1 FROM cs_project_assignments pa
                JOIN cs_team_members tm ON tm.id = pa.member_id
                WHERE pa.project_id = cs_daily_logs.project_id
                  AND tm.user_id    = auth.uid()
                  AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
            )
        )
    );

-- ---- cs_project_log_templates (D-19, same predicate as daily_logs) ----
DROP POLICY IF EXISTS cs_project_log_templates_select ON cs_project_log_templates;
CREATE POLICY cs_project_log_templates_select ON cs_project_log_templates
    FOR SELECT
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_project_log_templates.project_id
              AND tm.user_id    = auth.uid()
        )
    );

DROP POLICY IF EXISTS cs_project_log_templates_insert ON cs_project_log_templates;
CREATE POLICY cs_project_log_templates_insert ON cs_project_log_templates
    FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_project_log_templates.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );

DROP POLICY IF EXISTS cs_project_log_templates_update ON cs_project_log_templates;
CREATE POLICY cs_project_log_templates_update ON cs_project_log_templates
    FOR UPDATE
    USING (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_project_log_templates.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    )
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND EXISTS (
            SELECT 1 FROM cs_project_assignments pa
            JOIN cs_team_members tm ON tm.id = pa.member_id
            WHERE pa.project_id = cs_project_log_templates.project_id
              AND tm.user_id    = auth.uid()
              AND pa.role_on_project IN ('admin', 'project_manager', 'superintendent')
        )
    );
