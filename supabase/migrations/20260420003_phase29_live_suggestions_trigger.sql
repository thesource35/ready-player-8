-- Phase 29 LIVE-07 — per-upload pg_net trigger invoking generate-live-suggestions
-- when a cs_video_assets row transitions to status='ready' AND source_type='drone'.
-- Mirrors the shape of 20260415006_phase22_db_webhook_trigger.sql notify_ffmpeg_worker().
--
-- T-29-TRIGGER-LOOP guard: fires ONLY when status transitions FROM non-ready TO 'ready'.
-- Unrelated UPDATEs (metadata edits, portal_visible flips, etc.) do NOT re-fire.

create or replace function notify_live_suggestions_worker()
returns trigger
language plpgsql
security definer
as $$
declare
  v_url  text := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/generate-live-suggestions';
  v_key  text := (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key');
begin
  -- T-29-TRIGGER-LOOP mitigation: fire ONLY on status transition-to-ready for drone assets.
  -- 'IS DISTINCT FROM' handles the NULL case where old.status was NULL (uncommon but defensive).
  if new.source_type = 'drone'
     and new.status = 'ready'
     and (old.status is distinct from 'ready') then
    -- If Vault not yet populated (e.g., local dev), fail silent — never raise.
    if v_url is null or v_url = '' or v_key is null or v_key = '' then
      return new;
    end if;
    perform net.http_post(
      url := v_url || '?project_id=' || new.project_id::text,
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || v_key,
        'Content-Type', 'application/json'
      ),
      body := jsonb_build_object(
        'trigger', 'per_upload',
        'asset_id', new.id
      )
    );
  end if;
  return new;
end
$$;

drop trigger if exists trg_notify_live_suggestions on cs_video_assets;
create trigger trg_notify_live_suggestions
  after update on cs_video_assets
  for each row execute function notify_live_suggestions_worker();

comment on function notify_live_suggestions_worker() is
  'Phase 29 LIVE-07 — fires generate-live-suggestions Edge Function scoped to new.project_id when a drone asset transitions to status=ready. Guard prevents re-fire on unrelated UPDATEs (T-29-TRIGGER-LOOP).';
