-- Phase 14: Notifications & Activity Feed — Schema + Triggers
-- Covers decisions: D-01 (two-table split), D-02 (triggers are sole writers),
-- D-04 (document events flow through timeline when cs_attachments lands),
-- D-13 (partial unread index), D-15 (device tokens)
-- See: .planning/phases/14-notifications-activity-feed/SCHEMA-AUDIT.md

-- =============================================================================
-- Extensions
-- =============================================================================
create extension if not exists pg_cron;
create extension if not exists pg_net;

-- =============================================================================
-- cs_project_members (Path B — created here per SCHEMA-AUDIT)
-- =============================================================================
create table if not exists cs_project_members (
  project_id uuid not null,
  user_id    uuid not null,
  role       text,
  created_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create index if not exists cs_project_members_user_idx
  on cs_project_members (user_id);

-- =============================================================================
-- cs_activity_events — immutable per-project event log (D-01)
-- =============================================================================
create table if not exists cs_activity_events (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid,                         -- nullable: some events are not project-scoped
  entity_type text not null,                -- e.g. 'cs_projects', 'cs_rfis'
  entity_id   uuid,
  action      text not null,                -- 'insert' | 'update' | 'delete'
  category    text not null,                -- 'bid_deadline' | 'safety_alert' | 'assigned_task' | 'generic'
  actor_id    uuid,                         -- best-effort; from NEW.created_by/updated_by when present
  payload     jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now()
);

create index if not exists cs_activity_events_project_created_idx
  on cs_activity_events (project_id, created_at desc);

create index if not exists cs_activity_events_created_idx
  on cs_activity_events (created_at desc);

-- =============================================================================
-- cs_notifications — per-user delivery with read/dismissed state (D-10, D-11)
-- =============================================================================
create table if not exists cs_notifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null,
  event_id     uuid not null references cs_activity_events(id) on delete cascade,
  project_id   uuid,
  category     text not null,
  title        text not null,
  body         text,
  entity_type  text,
  entity_id    uuid,
  read_at      timestamptz,
  dismissed_at timestamptz,
  created_at   timestamptz not null default now()
);

create index if not exists cs_notifications_user_created_idx
  on cs_notifications (user_id, created_at desc)
  where dismissed_at is null;

-- D-13: partial unread index — hot path for badge count
create index if not exists cs_notifications_unread_idx
  on cs_notifications (user_id)
  where read_at is null and dismissed_at is null;

-- =============================================================================
-- cs_device_tokens — APNs device registry (D-15)
-- =============================================================================
create table if not exists cs_device_tokens (
  user_id      uuid not null,
  device_token text not null,
  platform     text not null default 'ios',
  app_version  text,
  last_seen_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  primary key (user_id, device_token)
);

create index if not exists cs_device_tokens_user_idx
  on cs_device_tokens (user_id);

-- =============================================================================
-- emit_activity_event() — single trigger function used by every source table
-- =============================================================================
create or replace function emit_activity_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row        jsonb;
  v_project_id uuid;
  v_entity_id  uuid;
  v_actor_id   uuid;
  v_action     text;
  v_category   text;
begin
  -- Pitfall 3 (RESEARCH): bulk-import short-circuit guard
  if current_setting('app.bulk_import', true) = 'on' then
    return coalesce(NEW, OLD);
  end if;

  v_action := lower(TG_OP);  -- 'insert' | 'update' | 'delete'
  v_row    := to_jsonb(coalesce(NEW, OLD));

  -- Resolve project_id:
  --   cs_projects: the row IS the project → use id
  --   everything else: use project_id column if present (introspected)
  if TG_TABLE_NAME = 'cs_projects' then
    v_project_id := (v_row->>'id')::uuid;
  else
    v_project_id := nullif(v_row->>'project_id', '')::uuid;
  end if;

  v_entity_id := nullif(v_row->>'id', '')::uuid;

  -- Best-effort actor attribution
  v_actor_id := coalesce(
    nullif(v_row->>'updated_by', '')::uuid,
    nullif(v_row->>'created_by', '')::uuid
  );

  -- Category gating drives NOTIF-05 push decision in Plan 14-02
  v_category := case
    when TG_TABLE_NAME = 'cs_contracts' and (v_row ? 'bid_deadline') then 'bid_deadline'
    when TG_TABLE_NAME = 'cs_safety_incidents' then 'safety_alert'
    when v_row ? 'assignee_id' or v_row ? 'assigned_to' then 'assigned_task'
    else 'generic'
  end;

  insert into cs_activity_events (
    project_id, entity_type, entity_id, action, category, actor_id, payload
  ) values (
    v_project_id, TG_TABLE_NAME, v_entity_id, v_action, v_category, v_actor_id, v_row
  );

  return coalesce(NEW, OLD);
end;
$$;

-- =============================================================================
-- Attach triggers — ONLY to tables that EXIST in the live schema
-- (per SCHEMA-AUDIT.md: cs_projects, cs_contracts, cs_rfis, cs_change_orders, cs_daily_logs)
--
-- Deferred (table missing): cs_submittals, cs_safety_incidents, cs_attachments, cs_punch_list
-- =============================================================================
do $$
declare
  t text;
  source_tables text[] := array[
    'cs_projects',
    'cs_contracts',
    'cs_rfis',
    'cs_change_orders',
    'cs_daily_logs'
  ];
begin
  foreach t in array source_tables loop
    -- Only attach if the table actually exists — belt-and-suspenders on top of the audit
    if exists (select 1 from pg_tables where schemaname = 'public' and tablename = t) then
      execute format('drop trigger if exists emit_activity_event_trg on %I', t);
      execute format($f$
        create trigger emit_activity_event_trg
        after insert or update or delete on %I
        for each row execute function emit_activity_event()
      $f$, t);
    end if;
  end loop;
end $$;

-- =============================================================================
-- Footer — attached vs skipped summary
-- =============================================================================
-- Attached (5): cs_projects, cs_contracts, cs_rfis, cs_change_orders, cs_daily_logs
-- Skipped (4):  cs_submittals, cs_safety_incidents, cs_attachments, cs_punch_list
-- When any skipped table is created in a later phase, append a follow-up
-- migration that re-runs the trigger attachment loop for that specific table.
