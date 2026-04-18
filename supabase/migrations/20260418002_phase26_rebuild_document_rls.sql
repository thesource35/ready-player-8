-- Phase 26: Documents RLS Table Reconciliation — Migration B (rebuild document RLS)
-- Replaces the Phase 13 defensive silent-skip (which used a reg-class existence check
-- to skip non-existent ops tables) with deterministic static policies covering all 7
-- cs_document_entity_type enum values.
--
-- Decisions: D-05 two-migration split (this = B); D-07 defense-in-depth with DB enum;
--            D-01 stubs preserve Phase 13 D-03 mirror-entity-access principle.
--
-- Threat mitigations:
--   T-26-03 RLS policy gap window — DROP + CREATE wrapped in single transaction.
--   T-26-04 Storage bucket policy parity — storage.objects policy rebuilt with the
--            SAME 7-entity predicate as cs_document_attachments (prevents signed-URL leak).
--
-- Assumes Migration A (20260418001) has committed: cs_rfis, cs_submittals,
-- cs_change_orders, cs_safety_incidents, cs_punch_items all exist. cs_daily_logs
-- already existed from Phase 16 (20260408005). cs_projects existed from Phase 1.

BEGIN;

-- =========================================================================
-- 1. Drop Phase 13 policies (they defensively skipped 3 entity_types).
-- =========================================================================
DROP POLICY IF EXISTS "select documents via attachments"     ON cs_documents;
DROP POLICY IF EXISTS "select attachments via entity access" ON cs_document_attachments;
DROP POLICY IF EXISTS "insert attachments via entity access" ON cs_document_attachments;
DROP POLICY IF EXISTS "read documents bucket via attachments" ON storage.objects;

-- =========================================================================
-- 2. cs_documents SELECT — user can read a document iff at least one
--    attachment row points at an entity they can access. Covers all 7 types.
-- =========================================================================
CREATE POLICY "select documents via attachments" ON cs_documents
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM cs_document_attachments a
            WHERE a.document_id = cs_documents.id
              AND (
                     (a.entity_type = 'project'         AND EXISTS (SELECT 1 FROM cs_projects          p  WHERE p.id  = a.entity_id))
                  OR (a.entity_type = 'rfi'             AND EXISTS (SELECT 1 FROM cs_rfis             r  WHERE r.id  = a.entity_id))
                  OR (a.entity_type = 'submittal'       AND EXISTS (SELECT 1 FROM cs_submittals       s  WHERE s.id  = a.entity_id))
                  OR (a.entity_type = 'change_order'    AND EXISTS (SELECT 1 FROM cs_change_orders    c  WHERE c.id  = a.entity_id))
                  OR (a.entity_type = 'daily_log'       AND EXISTS (SELECT 1 FROM cs_daily_logs       dl WHERE dl.id = a.entity_id))
                  OR (a.entity_type = 'safety_incident' AND EXISTS (SELECT 1 FROM cs_safety_incidents si WHERE si.id = a.entity_id))
                  OR (a.entity_type = 'punch_item'      AND EXISTS (SELECT 1 FROM cs_punch_items      pi WHERE pi.id = a.entity_id))
              )
        )
    );

-- =========================================================================
-- 3. cs_document_attachments SELECT — mirror-entity access, all 7 types.
-- =========================================================================
CREATE POLICY "select attachments via entity access" ON cs_document_attachments
    FOR SELECT TO authenticated
    USING (
           (entity_type = 'project'         AND EXISTS (SELECT 1 FROM cs_projects          p  WHERE p.id  = entity_id))
        OR (entity_type = 'rfi'             AND EXISTS (SELECT 1 FROM cs_rfis             r  WHERE r.id  = entity_id))
        OR (entity_type = 'submittal'       AND EXISTS (SELECT 1 FROM cs_submittals       s  WHERE s.id  = entity_id))
        OR (entity_type = 'change_order'    AND EXISTS (SELECT 1 FROM cs_change_orders    c  WHERE c.id  = entity_id))
        OR (entity_type = 'daily_log'       AND EXISTS (SELECT 1 FROM cs_daily_logs       dl WHERE dl.id = entity_id))
        OR (entity_type = 'safety_incident' AND EXISTS (SELECT 1 FROM cs_safety_incidents si WHERE si.id = entity_id))
        OR (entity_type = 'punch_item'      AND EXISTS (SELECT 1 FROM cs_punch_items      pi WHERE pi.id = entity_id))
    );

-- =========================================================================
-- 4. cs_document_attachments INSERT — must pass the entity-access predicate
--    (RLS on the child tables provides the final authorization gate).
-- =========================================================================
CREATE POLICY "insert attachments via entity access" ON cs_document_attachments
    FOR INSERT TO authenticated
    WITH CHECK (
           (entity_type = 'project'         AND EXISTS (SELECT 1 FROM cs_projects          p  WHERE p.id  = entity_id))
        OR (entity_type = 'rfi'             AND EXISTS (SELECT 1 FROM cs_rfis             r  WHERE r.id  = entity_id))
        OR (entity_type = 'submittal'       AND EXISTS (SELECT 1 FROM cs_submittals       s  WHERE s.id  = entity_id))
        OR (entity_type = 'change_order'    AND EXISTS (SELECT 1 FROM cs_change_orders    c  WHERE c.id  = entity_id))
        OR (entity_type = 'daily_log'       AND EXISTS (SELECT 1 FROM cs_daily_logs       dl WHERE dl.id = entity_id))
        OR (entity_type = 'safety_incident' AND EXISTS (SELECT 1 FROM cs_safety_incidents si WHERE si.id = entity_id))
        OR (entity_type = 'punch_item'      AND EXISTS (SELECT 1 FROM cs_punch_items      pi WHERE pi.id = entity_id))
    );

-- =========================================================================
-- 5. storage.objects SELECT on documents bucket — parity with document RLS.
--    T-26-04: the storage predicate MUST match the cs_documents predicate,
--    or signed URLs can leak files whose entity the user cannot access.
-- =========================================================================
CREATE POLICY "read documents bucket via attachments" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'documents'
        AND EXISTS (
            SELECT 1 FROM cs_documents d
            JOIN cs_document_attachments a ON a.document_id = d.id
            WHERE d.storage_path = storage.objects.name
              AND (
                     (a.entity_type = 'project'         AND EXISTS (SELECT 1 FROM cs_projects          p  WHERE p.id  = a.entity_id))
                  OR (a.entity_type = 'rfi'             AND EXISTS (SELECT 1 FROM cs_rfis             r  WHERE r.id  = a.entity_id))
                  OR (a.entity_type = 'submittal'       AND EXISTS (SELECT 1 FROM cs_submittals       s  WHERE s.id  = a.entity_id))
                  OR (a.entity_type = 'change_order'    AND EXISTS (SELECT 1 FROM cs_change_orders    c  WHERE c.id  = a.entity_id))
                  OR (a.entity_type = 'daily_log'       AND EXISTS (SELECT 1 FROM cs_daily_logs       dl WHERE dl.id = a.entity_id))
                  OR (a.entity_type = 'safety_incident' AND EXISTS (SELECT 1 FROM cs_safety_incidents si WHERE si.id = a.entity_id))
                  OR (a.entity_type = 'punch_item'      AND EXISTS (SELECT 1 FROM cs_punch_items      pi WHERE pi.id = a.entity_id))
              )
        )
    );

COMMIT;
