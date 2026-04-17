-- Phase 24: Document Activity Event Emission
-- Creates emit_document_activity_event() trigger function (SEPARATE from emit_activity_event())
-- Attaches to cs_documents and cs_document_attachments tables
-- Backfills existing documents into cs_activity_events with historical flag
--
-- Decisions: D-01 (dual table triggers), D-03 (separate function), D-04 (detail key),
--   D-05 (document category), D-06 (backfill with historical flag)
-- Threat mitigations: T-24-01 (entity_type whitelist), T-24-03 (NOT EXISTS backfill guard)

-- =============================================================================
-- emit_document_activity_event() — document-specific trigger function
-- =============================================================================
create or replace function emit_document_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row                   jsonb;
  v_project_id            uuid;
  v_entity_id             uuid;
  v_actor_id              uuid;
  v_action                text;
  v_detail                text;
  v_filename              text;
  v_attachment_entity_id  uuid;
  v_attachment_entity_type text;
begin
  -- Bulk import guard (matches existing emit_activity_event() pattern)
  if current_setting('app.bulk_import', true) = 'on' then
    return coalesce(NEW, OLD);
  end if;

  v_action := lower(TG_OP);
  v_row    := to_jsonb(coalesce(NEW, OLD));

  -- =========================================================================
  -- Branch on source table
  -- =========================================================================
  if TG_TABLE_NAME = 'cs_document_attachments' then
    -- Version copy guard: suppress attachment events during create_document_version RPC
    if current_setting('app.version_copy', true) = 'on' then
      return coalesce(NEW, OLD);
    end if;

    -- Determine semantic detail
    v_detail := case when TG_OP = 'DELETE' then 'document_detached' else 'document_attached' end;

    -- Entity ID is the document
    v_entity_id := (v_row->>'document_id')::uuid;

    -- Resolve project_id from the attachment's entity
    if v_row->>'entity_type' = 'project' then
      v_project_id := (v_row->>'entity_id')::uuid;
    else
      -- T-24-01: Whitelist guard before dynamic SQL (defense-in-depth over enum constraint)
      if v_row->>'entity_type' not in ('rfi', 'submittal', 'change_order') then
        return coalesce(NEW, OLD);
      end if;
      execute format('SELECT project_id FROM cs_%ss WHERE id = $1', v_row->>'entity_type')
        into v_project_id using (v_row->>'entity_id')::uuid;
    end if;

    -- D-01: skip silently if project_id cannot be resolved
    if v_project_id is null then
      return coalesce(NEW, OLD);
    end if;

    -- Enrich payload with filename from cs_documents
    select d.filename into v_filename
      from cs_documents d
      where d.id = v_entity_id;

    -- Actor attribution from the document uploader
    select d.uploaded_by into v_actor_id
      from cs_documents d
      where d.id = v_entity_id;

    v_row := v_row || jsonb_build_object('detail', v_detail, 'filename', coalesce(v_filename, 'unknown'));

  elsif TG_TABLE_NAME = 'cs_documents' then
    -- Only emit for current versions (skip historical version rows marked not current)
    if (v_row->>'is_current')::boolean is distinct from true then
      return coalesce(NEW, OLD);
    end if;

    v_entity_id := (v_row->>'id')::uuid;

    -- Determine semantic detail based on version number
    v_detail := case
      when (v_row->>'version_number')::int > 1 then 'version_added'
      else 'document_uploaded'
    end;

    -- Resolve project_id via cs_document_attachments junction table
    -- First try direct project attachment
    select da.entity_id into v_project_id
      from cs_document_attachments da
      where da.document_id = v_entity_id
        and da.entity_type = 'project'
      limit 1;

    -- If not directly attached to a project, try resolving through parent entity
    if v_project_id is null then
      select da.entity_id, da.entity_type::text
        into v_attachment_entity_id, v_attachment_entity_type
        from cs_document_attachments da
        where da.document_id = v_entity_id
        limit 1;

      if v_attachment_entity_type is not null and v_attachment_entity_type != 'project' then
        -- T-24-01: Whitelist guard before dynamic SQL
        if v_attachment_entity_type not in ('rfi', 'submittal', 'change_order') then
          return coalesce(NEW, OLD);
        end if;
        execute format('SELECT project_id FROM cs_%ss WHERE id = $1', v_attachment_entity_type)
          into v_project_id using v_attachment_entity_id;
      end if;
    end if;

    -- D-01: if no attachment exists yet, skip emission silently
    if v_project_id is null then
      return coalesce(NEW, OLD);
    end if;

    -- Actor is the uploader
    v_actor_id := (v_row->>'uploaded_by')::uuid;

    v_row := v_row || jsonb_build_object('detail', v_detail, 'filename', v_row->>'filename');

  else
    -- Unknown table — should not happen; return without emitting
    return coalesce(NEW, OLD);
  end if;

  -- =========================================================================
  -- Insert activity event with 'document' category (D-05)
  -- =========================================================================
  insert into cs_activity_events (
    project_id, entity_type, entity_id, action, category, actor_id, payload
  ) values (
    v_project_id, TG_TABLE_NAME, v_entity_id, v_action, 'document', v_actor_id, v_row
  );

  return coalesce(NEW, OLD);
end;
$$;

-- =============================================================================
-- Update create_document_version() RPC to suppress attachment trigger during copy
-- =============================================================================
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

  -- Suppress attachment trigger during version copy to prevent duplicate events
  set local app.version_copy = 'on';

  insert into cs_document_attachments (document_id, entity_type, entity_id)
  select v_new_id, entity_type, entity_id
    from cs_document_attachments
    where document_id = (
      select id from cs_documents
      where version_chain_id = p_chain_id and version_number = v_next_number - 1
    );

  -- Reset version copy guard
  set local app.version_copy = 'off';

  return v_new_id;
end $$;

-- =============================================================================
-- Attach triggers to cs_documents and cs_document_attachments
-- =============================================================================
do $$
begin
  -- cs_documents trigger
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'cs_documents') then
    drop trigger if exists emit_document_activity_event_trg on cs_documents;
    create trigger emit_document_activity_event_trg
      after insert or update or delete on cs_documents
      for each row execute function emit_document_activity_event();
  end if;

  -- cs_document_attachments trigger
  if exists (select 1 from pg_tables where schemaname = 'public' and tablename = 'cs_document_attachments') then
    drop trigger if exists emit_document_activity_event_trg on cs_document_attachments;
    create trigger emit_document_activity_event_trg
      after insert or delete on cs_document_attachments
      for each row execute function emit_document_activity_event();
  end if;
end $$;

-- =============================================================================
-- Backfill existing documents into cs_activity_events (D-06)
-- =============================================================================
do $backfill$
begin
  insert into cs_activity_events (
    project_id, entity_type, entity_id, action, category, actor_id, payload, created_at
  )
  select
    case
      when da.entity_type = 'project' then da.entity_id
      else null  -- non-project entities: skip complex lookup for backfill simplicity
    end as project_id,
    'cs_documents' as entity_type,
    d.id as entity_id,
    'insert' as action,
    'document' as category,
    d.uploaded_by as actor_id,
    to_jsonb(d) || jsonb_build_object(
      'detail', 'document_uploaded',
      'historical', true,
      'filename', d.filename
    ) as payload,
    d.created_at
  from cs_documents d
  join cs_document_attachments da on da.document_id = d.id
  where d.is_current = true
    and not exists (
      select 1 from cs_activity_events ae
      where ae.entity_type = 'cs_documents' and ae.entity_id = d.id
    );
end $backfill$;
