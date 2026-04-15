-- Phase 22: cs_video_assets — per-clip / per-live-session instance (D-07, D-08, D-21, D-38, D-39).
-- Decisions encoded:
--   D-07: two-table model (sources + assets)
--   D-08: source_type discriminator for Phase 29 row-only compatibility
--   D-21: portal_visible boolean default false
--   D-27: status in ('uploading','transcoding','ready','failed') default 'uploading'
--   D-38: optional asset name, length bounded
--   D-39: DELETE permits self (created_by) OR role in owner/admin
--   RLS mirrors Phase 21 cs_equipment (D-16)

create table cs_video_assets (
  id uuid primary key default gen_random_uuid(),
  source_id uuid not null references cs_video_sources(id) on delete cascade,
  org_id uuid not null,
  project_id uuid not null references cs_projects(id) on delete cascade,
  source_type text not null check (source_type in ('fixed_camera','drone','upload')),
  kind text not null check (kind in ('live','vod')),
  storage_path text null,
  mux_playback_id text null,
  mux_asset_id text null,
  status text not null default 'uploading' check (status in ('uploading','transcoding','ready','failed')),
  started_at timestamptz not null default now(),
  ended_at timestamptz null,
  duration_s numeric null,
  retention_expires_at timestamptz null,
  name text null check (name is null or char_length(name) <= 200),
  portal_visible boolean not null default false,
  last_error text null,
  created_at timestamptz not null default now(),
  created_by uuid not null
);

create index if not exists cs_video_assets_source_idx
  on cs_video_assets(source_id);
create index if not exists cs_video_assets_project_idx
  on cs_video_assets(project_id);
create index if not exists cs_video_assets_status_idx
  on cs_video_assets(status);
create index if not exists cs_video_assets_retention_idx
  on cs_video_assets(retention_expires_at) where retention_expires_at is not null;
create index if not exists cs_video_assets_portal_visible_idx
  on cs_video_assets(project_id, portal_visible) where portal_visible = true;
create index if not exists cs_video_assets_kind_ended_idx
  on cs_video_assets(kind, ended_at);

alter table cs_video_assets enable row level security;

-- SELECT: org members can read
create policy cs_video_assets_select
  on cs_video_assets for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- INSERT: org members can create; created_by pinned to caller
create policy cs_video_assets_insert
  on cs_video_assets for insert to authenticated
  with check (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
    and created_by = auth.uid()
  );

-- UPDATE: org members can update rows in their org
create policy cs_video_assets_update
  on cs_video_assets for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- DELETE (T-22-01-03 mitigation, D-39):
-- creator can delete their own; owner/admin can delete any in org
create policy cs_video_assets_delete
  on cs_video_assets for delete to authenticated
  using (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
    and (
      created_by = auth.uid()
      or auth.uid() in (
        select user_id from user_orgs
        where org_id = cs_video_assets.org_id and role in ('owner','admin')
      )
    )
  );

comment on table cs_video_assets is 'Phase 22 per-clip / per-live-session video asset (D-07, D-08, D-21).';
