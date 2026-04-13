-- Phase 21: Equipment tracking tables for live satellite & traffic maps
-- Creates cs_equipment (asset registry) and cs_equipment_locations (GPS history).
-- Adds lat/lng columns to cs_projects for map site display.
-- Threat T-21-02: CHECK constraints enforce coordinate ranges at DB level.
-- Threat T-21-03: CHECK constraints enforce enum values for type and status.

create extension if not exists pgcrypto;

-- Equipment asset registry
create table if not exists cs_equipment (
  id                uuid primary key default gen_random_uuid(),
  org_id            uuid not null,
  name              text not null,
  type              text not null check (type in ('equipment', 'vehicle', 'material')),
  subtype           text,
  assigned_project  uuid references cs_projects(id) on delete set null,
  status            text not null default 'active' check (status in ('active', 'idle', 'needs_attention')),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists cs_equipment_org_idx     on cs_equipment(org_id);
create index if not exists cs_equipment_project_idx on cs_equipment(assigned_project);
create index if not exists cs_equipment_status_idx  on cs_equipment(status);

-- Equipment location history (append-only per T-21-04)
create table if not exists cs_equipment_locations (
  id            uuid primary key default gen_random_uuid(),
  equipment_id  uuid not null references cs_equipment(id) on delete cascade,
  lat           numeric(9,6) not null,
  lng           numeric(9,6) not null,
  accuracy_m    numeric,
  source        text not null default 'manual' check (source in ('manual', 'gps_tracker', 'telematics')),
  recorded_at   timestamptz not null default now(),
  recorded_by   uuid references auth.users(id),
  notes         text,
  constraint cs_equip_loc_lat_range check (lat between -90 and 90),
  constraint cs_equip_loc_lng_range check (lng between -180 and 180)
);

create index if not exists cs_equip_loc_latest_idx on cs_equipment_locations(equipment_id, recorded_at desc);

-- Add lat/lng to cs_projects for map site display
alter table cs_projects add column if not exists lat numeric(9,6);
alter table cs_projects add column if not exists lng numeric(9,6);

-- View: latest position per equipment (DISTINCT ON pattern)
create or replace view cs_equipment_latest_positions as
select
  e.id,
  e.org_id,
  e.name,
  e.type,
  e.subtype,
  e.assigned_project,
  e.status,
  e.created_at,
  e.updated_at,
  el.lat   as latest_lat,
  el.lng   as latest_lng,
  el.recorded_at as latest_recorded_at,
  el.accuracy_m  as latest_accuracy_m
from cs_equipment e
inner join (
  select distinct on (equipment_id)
    equipment_id, lat, lng, recorded_at, accuracy_m
  from cs_equipment_locations
  order by equipment_id, recorded_at desc
) el on el.equipment_id = e.id;

-- Updated_at trigger (reuses existing function from 001_updated_at_triggers.sql)
drop trigger if exists cs_equipment_updated_at on cs_equipment;
create trigger cs_equipment_updated_at
  before update on cs_equipment
  for each row execute function update_updated_at_column();

comment on table cs_equipment           is 'Phase 21 equipment asset registry — D-06, D-07';
comment on table cs_equipment_locations is 'Phase 21 equipment GPS location history — D-08 (append-only per T-21-04)';
