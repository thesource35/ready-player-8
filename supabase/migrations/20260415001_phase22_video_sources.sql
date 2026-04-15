-- Phase 22: cs_video_sources — per-camera registration (D-07, D-35, D-27, D-39). Applied 2026-04-15.
-- Decisions encoded:
--   D-07: kind in ('fixed_camera','drone','upload') (two-table model, head-source registration)
--   D-27: status in ('idle','active','offline','archived') default 'idle'
--   D-35: audio_enabled boolean default false (per-camera audio gate)
--   D-38: name required, length bounded
--   D-39: DELETE role-gated to owner/admin via user_orgs.role
--   RLS shape mirrors Phase 21 cs_equipment (D-16)

create extension if not exists pgcrypto;

create table cs_video_sources (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null,
  project_id uuid not null references cs_projects(id) on delete cascade,
  kind text not null check (kind in ('fixed_camera','drone','upload')),
  name text not null check (char_length(name) between 1 and 128),
  location_label text null check (location_label is null or char_length(location_label) <= 256),
  mux_live_input_id text null,
  mux_playback_id text null,
  audio_enabled boolean not null default false,
  status text not null default 'idle' check (status in ('idle','active','offline','archived')),
  last_active_at timestamptz null,
  created_at timestamptz not null default now(),
  created_by uuid not null
);

create index if not exists cs_video_sources_project_idx
  on cs_video_sources(project_id);
create index if not exists cs_video_sources_org_idx
  on cs_video_sources(org_id);
create index if not exists cs_video_sources_mux_live_input_idx
  on cs_video_sources(mux_live_input_id) where mux_live_input_id is not null;
create index if not exists cs_video_sources_mux_playback_idx
  on cs_video_sources(mux_playback_id) where mux_playback_id is not null;

alter table cs_video_sources enable row level security;

-- SELECT: org members can read (T-22-01-01 mitigation, mirrors Phase 21 D-16)
create policy cs_video_sources_select
  on cs_video_sources for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- INSERT: org members can create; created_by pinned to caller
create policy cs_video_sources_insert
  on cs_video_sources for insert to authenticated
  with check (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
    and created_by = auth.uid()
  );

-- UPDATE: org members can update rows in their org
create policy cs_video_sources_update
  on cs_video_sources for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- DELETE: role-gated to owner/admin (T-22-01-02 mitigation, D-39)
create policy cs_video_sources_delete
  on cs_video_sources for delete to authenticated
  using (
    org_id in (
      select org_id from user_orgs
      where user_id = auth.uid() and role in ('owner','admin')
    )
  );

comment on table cs_video_sources is 'Phase 22 per-camera / per-drone / per-upload head registration (D-07, D-35).';
