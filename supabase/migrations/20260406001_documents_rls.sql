-- Phase 13: RLS policies for cs_documents, cs_document_attachments, and storage.objects.
-- Implements D-02 (signed URL only), D-03 (mirror entity-level RLS).
--
-- The storage.objects insert policy uses coalesce(auth.jwt()->>'org_id', auth.uid()::text)
-- so it works whether or not the org_id JWT claim is present in this Supabase project.
-- Downstream plans should standardize on whichever prefix is actually used.
--
-- DEFENSIVE: References to cs_rfis / cs_submittals / cs_change_orders are guarded
-- by to_regclass() so this migration applies cleanly even if those ops tables do
-- not yet exist on the target database. Policies are (re)created in a later
-- migration once the ops tables land.

-- Helper: build the entity-existence predicate dynamically based on which
-- ops tables exist at migration time. We always include 'project'.
DO $mig$
DECLARE
  has_rfis    boolean := to_regclass('public.cs_rfis')          IS NOT NULL;
  has_subs    boolean := to_regclass('public.cs_submittals')    IS NOT NULL;
  has_co      boolean := to_regclass('public.cs_change_orders') IS NOT NULL;
  doc_pred    text;
  attach_pred text;
BEGIN
  -- Predicate referencing cs_document_attachments alias 'a' and outer cs_documents
  doc_pred := $p$(a.entity_type = 'project' and exists (select 1 from cs_projects p where p.id = a.entity_id))$p$;
  IF has_rfis THEN
    doc_pred := doc_pred || $p$ or (a.entity_type = 'rfi' and exists (select 1 from cs_rfis r where r.id = a.entity_id))$p$;
  END IF;
  IF has_subs THEN
    doc_pred := doc_pred || $p$ or (a.entity_type = 'submittal' and exists (select 1 from cs_submittals s where s.id = a.entity_id))$p$;
  END IF;
  IF has_co THEN
    doc_pred := doc_pred || $p$ or (a.entity_type = 'change_order' and exists (select 1 from cs_change_orders c where c.id = a.entity_id))$p$;
  END IF;

  -- Predicate referencing cs_document_attachments columns directly (no alias)
  attach_pred := $p$(entity_type = 'project' and exists (select 1 from cs_projects p where p.id = entity_id))$p$;
  IF has_rfis THEN
    attach_pred := attach_pred || $p$ or (entity_type = 'rfi' and exists (select 1 from cs_rfis r where r.id = entity_id))$p$;
  END IF;
  IF has_subs THEN
    attach_pred := attach_pred || $p$ or (entity_type = 'submittal' and exists (select 1 from cs_submittals s where s.id = entity_id))$p$;
  END IF;
  IF has_co THEN
    attach_pred := attach_pred || $p$ or (entity_type = 'change_order' and exists (select 1 from cs_change_orders c where c.id = entity_id))$p$;
  END IF;

  -- cs_documents: SELECT if user can read at least one attached entity.
  EXECUTE format($f$
    create policy "select documents via attachments" on cs_documents
    for select to authenticated using (
      exists (
        select 1 from cs_document_attachments a
        where a.document_id = cs_documents.id
          and (%s)
      )
    )
  $f$, doc_pred);

  -- cs_document_attachments: same gating, plus insert requires entity access.
  EXECUTE format($f$
    create policy "select attachments via entity access" on cs_document_attachments
    for select to authenticated using (%s)
  $f$, attach_pred);

  EXECUTE format($f$
    create policy "insert attachments via entity access" on cs_document_attachments
    for insert to authenticated with check (%s)
  $f$, attach_pred);

  -- storage.objects read policy for the 'documents' bucket.
  EXECUTE format($f$
    create policy "read documents bucket via attachments" on storage.objects
    for select to authenticated using (
      bucket_id = 'documents'
      and exists (
        select 1 from cs_documents d
        join cs_document_attachments a on a.document_id = d.id
        where d.storage_path = storage.objects.name
          and (%s)
      )
    )
  $f$, doc_pred);
END
$mig$;

-- Static policies that don't depend on ops tables.
create policy "insert documents authenticated" on cs_documents
for insert to authenticated with check (uploaded_by = auth.uid());

create policy "insert documents bucket authenticated" on storage.objects
for insert to authenticated with check (
  bucket_id = 'documents'
  and (storage.foldername(name))[1] = coalesce(auth.jwt() ->> 'org_id', auth.uid()::text)
);
