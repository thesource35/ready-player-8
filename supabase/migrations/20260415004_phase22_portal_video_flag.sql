-- Phase 22: extend Phase 20 cs_portal_config with show_cameras toggle (D-21, D-22, D-34).
-- Additive migration: uses `add column if not exists` so re-apply is safe and Phase 20
-- existing rows get default false (cameras off until owner explicitly opts in).

alter table cs_portal_config add column if not exists show_cameras boolean not null default false;

comment on column cs_portal_config.show_cameras is
  'Phase 22 — when true, portal viewers can watch head-only live streams and portal_visible=true VOD clips from source_type in (fixed_camera, upload). Drone assets are never exposed to portal (D-22). Amended by D-34 for head-only + streaming-only constraints: portal never receives camera URLs directly, only short-lived signed playback JWTs minted server-side per request.';
