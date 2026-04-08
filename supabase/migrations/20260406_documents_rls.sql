-- Phase 13: RLS policies for cs_documents, cs_document_attachments, and storage.objects.
-- Implements D-02 (signed URL only), D-03 (mirror entity-level RLS).
--
-- The storage.objects insert policy uses coalesce(auth.jwt()->>'org_id', auth.uid()::text)
-- so it works whether or not the org_id JWT claim is present in this Supabase project.
-- Downstream plans should standardize on whichever prefix is actually used.

-- cs_documents: SELECT if user can read at least one attached entity.
create policy "select documents via attachments" on cs_documents
for select to authenticated using (
  exists (
    select 1 from cs_document_attachments a
    where a.document_id = cs_documents.id
      and (
        (a.entity_type = 'project'      and exists (select 1 from cs_projects      p where p.id = a.entity_id))
        or (a.entity_type = 'rfi'         and exists (select 1 from cs_rfis           r where r.id = a.entity_id))
        or (a.entity_type = 'submittal'   and exists (select 1 from cs_submittals     s where s.id = a.entity_id))
        or (a.entity_type = 'change_order'and exists (select 1 from cs_change_orders  c where c.id = a.entity_id))
      )
  )
);

create policy "insert documents authenticated" on cs_documents
for insert to authenticated with check (uploaded_by = auth.uid());

-- cs_document_attachments: same gating, plus insert requires entity access.
create policy "select attachments via entity access" on cs_document_attachments
for select to authenticated using (
  (entity_type = 'project'      and exists (select 1 from cs_projects      p where p.id = entity_id))
  or (entity_type = 'rfi'         and exists (select 1 from cs_rfis           r where r.id = entity_id))
  or (entity_type = 'submittal'   and exists (select 1 from cs_submittals     s where s.id = entity_id))
  or (entity_type = 'change_order'and exists (select 1 from cs_change_orders  c where c.id = entity_id))
);

create policy "insert attachments via entity access" on cs_document_attachments
for insert to authenticated with check (
  (entity_type = 'project'      and exists (select 1 from cs_projects      p where p.id = entity_id))
  or (entity_type = 'rfi'         and exists (select 1 from cs_rfis           r where r.id = entity_id))
  or (entity_type = 'submittal'   and exists (select 1 from cs_submittals     s where s.id = entity_id))
  or (entity_type = 'change_order'and exists (select 1 from cs_change_orders  c where c.id = entity_id))
);

-- storage.objects policies for the 'documents' bucket.
create policy "read documents bucket via attachments" on storage.objects
for select to authenticated using (
  bucket_id = 'documents'
  and exists (
    select 1 from cs_documents d
    join cs_document_attachments a on a.document_id = d.id
    where d.storage_path = storage.objects.name
      and (
        (a.entity_type = 'project'       and exists (select 1 from cs_projects       p where p.id = a.entity_id))
        or (a.entity_type = 'rfi'         and exists (select 1 from cs_rfis           r where r.id = a.entity_id))
        or (a.entity_type = 'submittal'   and exists (select 1 from cs_submittals     s where s.id = a.entity_id))
        or (a.entity_type = 'change_order'and exists (select 1 from cs_change_orders  c where c.id = a.entity_id))
      )
  )
);

create policy "insert documents bucket authenticated" on storage.objects
for insert to authenticated with check (
  bucket_id = 'documents'
  and (storage.foldername(name))[1] = coalesce(auth.jwt() ->> 'org_id', auth.uid()::text)
);
