-- Phase 22: DB webhook trigger — fires pg_net HTTP POST to ffmpeg worker on VOD upload (D-05).
-- On INSERT into cs_video_assets where kind='vod' AND status='uploading', fire a
-- webhook to the ffmpeg transcode worker. Worker reads the raw object from storage,
-- produces HLS output under the org-scoped prefix, and updates the row's status.
--
-- Worker URL + shared secret are supplied via database GUCs set at deploy time:
--   alter database postgres set app.ffmpeg_worker_url    = 'https://<worker>/transcode';
--   alter database postgres set app.ffmpeg_worker_secret = '<openssl rand -hex 32>';
-- GUCs are NOT committed here (secrets must stay out of source). The worker secret
-- must also be stored in Vercel env as WORKER_SHARED_SECRET so the webhook-verify
-- path on the web side can validate the X-Worker-Secret header both directions.
--
-- Backstop: Supabase pg_net webhooks do not natively retry. The requeue_stuck_uploads()
-- function below is the recovery path — it re-POSTs any cs_video_assets row stuck in
-- status='uploading' for more than 5 minutes. Plan 22-10 schedules it via pg_cron
-- every 5 minutes. It is defined here (alongside its sibling trigger) so both the
-- happy path and the recovery path live in one migration.

create extension if not exists pg_net with schema extensions;

-- Forward dispatch: fires on every INSERT into cs_video_assets.
create or replace function notify_ffmpeg_worker()
returns trigger
language plpgsql
security definer
as $$
declare
  v_url    text := current_setting('app.ffmpeg_worker_url', true);
  v_secret text := current_setting('app.ffmpeg_worker_secret', true);
begin
  -- Only VOD rows freshly inserted in uploading state need transcode.
  if new.kind = 'vod' and new.status = 'uploading' then
    -- current_setting(..., true) returns NULL if the GUC is unset; skip gracefully
    -- so dev / test databases without the GUC don't error on every insert.
    if v_url is null or v_url = '' then
      return new;
    end if;

    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Worker-Secret', coalesce(v_secret, '')
      ),
      body := jsonb_build_object(
        'asset_id', new.id,
        'storage_path', new.storage_path,
        'org_id', new.org_id,
        'project_id', new.project_id
      )
    );
  end if;

  return new;
end
$$;

drop trigger if exists trg_notify_ffmpeg_worker on cs_video_assets;
create trigger trg_notify_ffmpeg_worker
  after insert on cs_video_assets
  for each row execute function notify_ffmpeg_worker();

comment on function notify_ffmpeg_worker() is
  'Phase 22 — fires pg_net HTTP POST to ffmpeg worker on VOD upload (D-05). Worker URL + secret read from GUCs app.ffmpeg_worker_url / app.ffmpeg_worker_secret, set post-deploy.';

-- Backstop: re-POST any VOD asset stuck in uploading for >5 minutes.
-- Scheduled by plan 22-10 via pg_cron every 5 minutes (NOT scheduled here).
-- Idempotent on the worker side: worker keys by asset_id and no-ops if already transcoded.
create or replace function requeue_stuck_uploads()
returns void
language plpgsql
security definer
as $$
declare
  rec record;
  v_url    text := current_setting('app.ffmpeg_worker_url', true);
  v_secret text := current_setting('app.ffmpeg_worker_secret', true);
begin
  if v_url is null or v_url = '' then
    return;
  end if;

  for rec in
    select id, storage_path, org_id, project_id
    from cs_video_assets
    where kind = 'vod'
      and status = 'uploading'
      and created_at < now() - interval '5 minutes'
  loop
    perform net.http_post(
      url := v_url,
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'X-Worker-Secret', coalesce(v_secret, '')
      ),
      body := jsonb_build_object(
        'asset_id', rec.id,
        'storage_path', rec.storage_path,
        'org_id', rec.org_id,
        'project_id', rec.project_id,
        'requeue', true
      )
    );
  end loop;
end
$$;

comment on function requeue_stuck_uploads() is
  'Phase 22 backstop — re-POSTs VOD assets stuck in uploading for >5 minutes. Scheduled by pg_cron in plan 22-10.';
