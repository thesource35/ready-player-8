-- Phase 21: RLS policies for equipment tables
-- Threat T-21-01: org-scoped access via user_orgs join
-- Threat T-21-04: No UPDATE or DELETE on cs_equipment_locations (append-only history)

alter table cs_equipment enable row level security;
alter table cs_equipment_locations enable row level security;

-- cs_equipment: org-scoped SELECT, INSERT, UPDATE (no DELETE — decommission via status)
create policy cs_equipment_select
  on cs_equipment for select to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_equipment_insert
  on cs_equipment for insert to authenticated
  with check (org_id in (select org_id from user_orgs where user_id = auth.uid()));

create policy cs_equipment_update
  on cs_equipment for update to authenticated
  using (org_id in (select org_id from user_orgs where user_id = auth.uid()));

-- cs_equipment_locations: org-scoped SELECT and INSERT only
-- No UPDATE or DELETE policies — append-only location history (T-21-04)
create policy cs_equipment_locations_select
  on cs_equipment_locations for select to authenticated
  using (equipment_id in (
    select id from cs_equipment
    where org_id in (select org_id from user_orgs where user_id = auth.uid())
  ));

create policy cs_equipment_locations_insert
  on cs_equipment_locations for insert to authenticated
  with check (equipment_id in (
    select id from cs_equipment
    where org_id in (select org_id from user_orgs where user_id = auth.uid())
  ));
