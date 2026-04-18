-- Phase 26: Documents RLS Table Reconciliation — Migration C (extend trigger whitelist)
-- Extends the Phase 24 emit_document_activity_event() whitelist from 3 to 6
-- non-project entity types, matching the cs_document_entity_type enum.
-- Preserves every other behavior (bulk_import guard, version_copy guard,
-- null-project silent-return D-09) byte-for-byte.
--
-- Decisions: D-08 bundle trigger fix into Phase 26; D-09 preserve Phase 24 silent-return.
--
-- Threat mitigations:
--   T-26-SQLI SQL injection in dynamic SQL — whitelist check happens BEFORE format()
--             so only the 6 literal strings can flow into the %s table-name substitution.
--             All 6 map to real tables after Migrations A + Phase 16 schema.

create or replace function emit_document_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row                    jsonb;
  v_project_id             uuid;
  v_entity_id              uuid;
  v_actor_id               uuid;
  v_action                 text;
  v_detail                 text;
  v_filename               text;
  v_attachment_entity_id   uuid;
  v_attachment_entity_type text;
begin
  -- Bulk import guard (matches existing emit_activity_event() pattern)
  if current_setting('app.bulk_import', true) = 'on' then
    return coalesce(NEW, OLD);
  end if;

  v_action := lower(TG_OP);
  v_row    := to_jsonb(coalesce(NEW, OLD));

  if TG_TABLE_NAME = 'cs_document_attachments' then
    -- Version copy guard: suppress attachment events during create_document_version RPC
    if current_setting('app.version_copy', true) = 'on' then
      return coalesce(NEW, OLD);
    end if;

    v_detail := case when TG_OP = 'DELETE' then 'document_detached' else 'document_attached' end;
    v_entity_id := (v_row->>'document_id')::uuid;

    if v_row->>'entity_type' = 'project' then
      v_project_id := (v_row->>'entity_id')::uuid;
    else
      -- T-26-SQLI + T-24-01 whitelist guard — EXTENDED from 3 to 6 entity types (D-08).
      if v_row->>'entity_type' not in ('rfi', 'submittal', 'change_order', 'daily_log', 'safety_incident', 'punch_item') then
        return coalesce(NEW, OLD);
      end if;
      execute format('SELECT project_id FROM cs_%ss WHERE id = $1', v_row->>'entity_type')
        into v_project_id using (v_row->>'entity_id')::uuid;
    end if;

    -- D-09: preserve silent-return on null project_id
    if v_project_id is null then
      return coalesce(NEW, OLD);
    end if;

    select d.filename into v_filename
      from cs_documents d where d.id = v_entity_id;

    select d.uploaded_by into v_actor_id
      from cs_documents d where d.id = v_entity_id;

    v_row := v_row || jsonb_build_object('detail', v_detail, 'filename', coalesce(v_filename, 'unknown'));

  elsif TG_TABLE_NAME = 'cs_documents' then
    if (v_row->>'is_current')::boolean is distinct from true then
      return coalesce(NEW, OLD);
    end if;

    v_entity_id := (v_row->>'id')::uuid;

    v_detail := case
      when (v_row->>'version_number')::int > 1 then 'version_added'
      else 'document_uploaded'
    end;

    select da.entity_id into v_project_id
      from cs_document_attachments da
      where da.document_id = v_entity_id
        and da.entity_type = 'project'
      limit 1;

    if v_project_id is null then
      select da.entity_id, da.entity_type::text
        into v_attachment_entity_id, v_attachment_entity_type
        from cs_document_attachments da
        where da.document_id = v_entity_id
        limit 1;

      if v_attachment_entity_type is not null and v_attachment_entity_type != 'project' then
        -- T-26-SQLI + T-24-01 whitelist guard — EXTENDED from 3 to 6 entity types (D-08).
        if v_attachment_entity_type not in ('rfi', 'submittal', 'change_order', 'daily_log', 'safety_incident', 'punch_item') then
          return coalesce(NEW, OLD);
        end if;
        execute format('SELECT project_id FROM cs_%ss WHERE id = $1', v_attachment_entity_type)
          into v_project_id using v_attachment_entity_id;
      end if;
    end if;

    -- D-09: preserve silent-return on null project_id
    if v_project_id is null then
      return coalesce(NEW, OLD);
    end if;

    v_actor_id := (v_row->>'uploaded_by')::uuid;
    v_row := v_row || jsonb_build_object('detail', v_detail, 'filename', v_row->>'filename');

  else
    return coalesce(NEW, OLD);
  end if;

  insert into cs_activity_events (
    project_id, entity_type, entity_id, action, category, actor_id, payload
  ) values (
    v_project_id, TG_TABLE_NAME, v_entity_id, v_action, 'document', v_actor_id, v_row
  );

  return coalesce(NEW, OLD);
end;
$$;
