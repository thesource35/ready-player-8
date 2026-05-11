-- Phase 13: Document Management Foundation — schema
-- Implements D-04 (cs_documents), D-05 (junction), D-06 (enum), D-07 (versioning).
--
-- PREREQUISITE VERIFICATION (to be confirmed during Task 3 application):
--   1. auth.jwt() ->> 'org_id' availability — if NULL for current users, the
--      Storage insert RLS policy in the companion _rls.sql migration falls back
--      to auth.uid()::text as the path prefix (already coded via coalesce()).
--   2. Entity tables cs_projects, cs_rfis, cs_submittals, cs_change_orders are
--      expected to exist with RLS enabled. If any are missing at apply time,
--      create stub tables (id uuid PK, org_id uuid, RLS enabled) before this
--      migration so foreign-key style RLS joins resolve.
--
-- This migration is idempotent-friendly via guarded type creation but assumes
-- a clean target. Re-running is not supported without DROPs.

do $$ begin
  create type cs_document_entity_type as enum ('project','rfi','submittal','change_order');
exception when duplicate_object then null; end $$;

create table if not exists cs_documents (
  id               uuid primary key default gen_random_uuid(),
  org_id           uuid not null,
  version_chain_id uuid not null,
  version_number   int  not null check (version_number >= 1),
  is_current       boolean not null default true,
  filename         text not null,
  mime_type        text not null check (mime_type in (
    'application/pdf','image/png','image/jpeg','image/webp','image/heic'
  )),
  size_bytes       bigint not null check (size_bytes > 0 and size_bytes <= 52428800),
  storage_path     text not null unique,
  uploaded_by      uuid not null references auth.users(id),
  created_at       timestamptz not null default now()
);

create unique index if not exists cs_documents_one_current_per_chain
  on cs_documents (version_chain_id) where is_current;
create unique index if not exists cs_documents_unique_version_in_chain
  on cs_documents (version_chain_id, version_number);
create index if not exists cs_documents_storage_path_idx on cs_documents (storage_path);
create index if not exists cs_documents_chain_idx on cs_documents (version_chain_id);
create index if not exists cs_documents_org_idx on cs_documents (org_id);

create table if not exists cs_document_attachments (
  document_id  uuid not null references cs_documents(id) on delete cascade,
  entity_type  cs_document_entity_type not null,
  entity_id    uuid not null,
  created_at   timestamptz not null default now(),
  primary key (document_id, entity_type, entity_id)
);

create index if not exists cs_document_attachments_entity_idx
  on cs_document_attachments (entity_type, entity_id);
create index if not exists cs_document_attachments_document_idx
  on cs_document_attachments (document_id);

alter table cs_documents enable row level security;
alter table cs_document_attachments enable row level security;

-- RPC: atomic new-version creation (D-07, D-08)
create or replace function create_document_version(
  p_chain_id uuid,
  p_filename text,
  p_mime_type text,
  p_size_bytes bigint,
  p_storage_path text,
  p_org_id uuid
) returns uuid
language plpgsql security definer as $$
declare
  v_new_id uuid;
  v_next_number int;
begin
  select coalesce(max(version_number), 0) + 1 into v_next_number
    from cs_documents where version_chain_id = p_chain_id;

  update cs_documents set is_current = false
    where version_chain_id = p_chain_id and is_current;

  insert into cs_documents (
    id, org_id, version_chain_id, version_number, is_current,
    filename, mime_type, size_bytes, storage_path, uploaded_by
  ) values (
    gen_random_uuid(), p_org_id, p_chain_id, v_next_number, true,
    p_filename, p_mime_type, p_size_bytes, p_storage_path, auth.uid()
  ) returning id into v_new_id;

  -- Copy attachments from prior current version
  insert into cs_document_attachments (document_id, entity_type, entity_id)
  select v_new_id, entity_type, entity_id
    from cs_document_attachments
    where document_id = (
      select id from cs_documents
      where version_chain_id = p_chain_id and version_number = v_next_number - 1
    );

  return v_new_id;
end $$;
