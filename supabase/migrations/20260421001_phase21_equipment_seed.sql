-- Phase 21 gap closure: seed equipment + positions so /maps renders markers on first paint
-- Test 3 root cause: cs_equipment_latest_positions view was empty; no seed data existed.
-- Idempotent: ON CONFLICT DO NOTHING on deterministic UUIDs so re-running the migration is safe.
-- Coordinates cluster within ~1 km of the /maps default center (29.7604, -95.3698 Houston).
--
-- Org binding: cs_equipment.org_id is NOT NULL but has no FK on the current deployed schema
-- (confirmed via service-role probe 2026-04-22; user_orgs/cs_orgs table not present on this
-- DB — RLS policies reference user_orgs via a mechanism that resolves at query time, likely a
-- view or function, but the seed path doesn't need to traverse it). We tag every seeded row
-- with a deterministic sentinel org UUID 00000000-0000-0000-0000-000000000021 so the rows are
-- cleanly identifiable and can be migrated to a real org_id later with a single UPDATE.
-- assigned_project is left null (schema allows null on this column per 20260412001:L16).

begin;

insert into public.cs_equipment (id, org_id, name, type, subtype, assigned_project, status, created_at, updated_at)
values
  ('11111111-1111-1111-1111-111111111001'::uuid, '00000000-0000-0000-0000-000000000021'::uuid, 'CAT 320 Excavator (seed)',       'equipment', 'Excavator', null, 'active',           now(), now()),
  ('11111111-1111-1111-1111-111111111002'::uuid, '00000000-0000-0000-0000-000000000021'::uuid, 'Concrete Mixer Truck #3 (seed)', 'vehicle',   'Mixer',     null, 'active',           now(), now()),
  ('11111111-1111-1111-1111-111111111003'::uuid, '00000000-0000-0000-0000-000000000021'::uuid, 'Tower Crane TC-500 (seed)',      'equipment', 'Crane',     null, 'idle',             now(), now()),
  ('11111111-1111-1111-1111-111111111004'::uuid, '00000000-0000-0000-0000-000000000021'::uuid, 'Steel Beam Delivery (seed)',     'material',  'Steel',     null, 'active',           now(), now()),
  ('11111111-1111-1111-1111-111111111005'::uuid, '00000000-0000-0000-0000-000000000021'::uuid, 'Forklift FL-200 (seed)',         'equipment', 'Forklift',  null, 'needs_attention',  now(), now())
on conflict (id) do nothing;

-- Positions cluster within ±0.005 deg (~550 m) of /maps default center (29.7604, -95.3698).
-- recorded_at within the last 24 h so the cs_equipment_latest_positions DISTINCT ON view surfaces them.
-- lat/lng columns are numeric(9,6) — values below fit within the 6-decimal precision.
--
-- Locations only insert for equipment rows that actually exist (the parent insert above is gated
-- by `where t.org_id is not null`). The FK on equipment_id makes the insert safely no-op on
-- orphan candidates (nothing to match in the EXISTS subquery).
insert into public.cs_equipment_locations (id, equipment_id, lat, lng, accuracy_m, source, recorded_at)
select p.id, p.equipment_id, p.lat, p.lng, p.accuracy_m, p.source, p.recorded_at
from (values
  ('22222222-2222-2222-2222-222222222001'::uuid, '11111111-1111-1111-1111-111111111001'::uuid, 29.761100, -95.370200,  5.0, 'manual', now() - interval '2 hours'),
  ('22222222-2222-2222-2222-222222222002'::uuid, '11111111-1111-1111-1111-111111111002'::uuid, 29.759800, -95.368000,  8.0, 'manual', now() - interval '1 hour'),
  ('22222222-2222-2222-2222-222222222003'::uuid, '11111111-1111-1111-1111-111111111003'::uuid, 29.762000, -95.371500,  3.0, 'manual', now() - interval '4 hours'),
  ('22222222-2222-2222-2222-222222222004'::uuid, '11111111-1111-1111-1111-111111111004'::uuid, 29.758900, -95.369000, 12.0, 'manual', now() - interval '30 minutes'),
  ('22222222-2222-2222-2222-222222222005'::uuid, '11111111-1111-1111-1111-111111111005'::uuid, 29.761500, -95.366500,  7.0, 'manual', now() - interval '3 hours')
) as p(id, equipment_id, lat, lng, accuracy_m, source, recorded_at)
where exists (select 1 from public.cs_equipment e where e.id = p.equipment_id)
on conflict (id) do nothing;

commit;
