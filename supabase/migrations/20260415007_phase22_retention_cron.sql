-- Phase 22: cron schedules for retention, idle-archive, webhook-dedupe prune, upload backstop.
--
-- Reuses Vault secrets established by Phase 14 (20260407002_phase14_pgcron_schedule.sql):
--   name='project_url'       -> https://<PROJECT_REF>.supabase.co
--   name='service_role_key'  -> <SERVICE_ROLE_KEY>
--
-- Requires: pg_cron and pg_net (installed by prior Phase 14/22 migrations)

create extension if not exists pg_cron with schema extensions;

-- Idempotent: unschedule any previous versions so re-running the migration is safe
do $$
begin
  if exists (select 1 from cron.job where jobname = 'phase22-prune-expired-videos') then
    perform cron.unschedule('phase22-prune-expired-videos');
  end if;
  if exists (select 1 from cron.job where jobname = 'phase22-archive-idle-sources') then
    perform cron.unschedule('phase22-archive-idle-sources');
  end if;
  if exists (select 1 from cron.job where jobname = 'phase22-prune-webhook-events') then
    perform cron.unschedule('phase22-prune-webhook-events');
  end if;
  if exists (select 1 from cron.job where jobname = 'phase22-requeue-stuck-uploads') then
    perform cron.unschedule('phase22-requeue-stuck-uploads');
  end if;
end $$;

-- Daily 03:00 UTC: prune expired VOD + live rows, remove storage, delete Mux archives (D-09, D-10)
select cron.schedule(
  'phase22-prune-expired-videos',
  '0 3 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/prune-expired-videos',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type', 'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- Daily 03:05 UTC: archive idle fixed_camera sources + disable Mux live_input (D-30)
select cron.schedule(
  'phase22-archive-idle-sources',
  '5 3 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/archive-idle-sources',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type', 'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- Daily 03:30 UTC: prune 7-day old webhook-events dedupe rows (D-32)
select cron.schedule(
  'phase22-prune-webhook-events',
  '30 3 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/prune-webhook-events',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type', 'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

-- Every 5 minutes: requeue uploads stuck > 5 min in 'uploading' status (RESEARCH backstop)
-- Uses the SQL function requeue_stuck_uploads() defined in 20260415006_phase22_db_webhook_trigger.sql
-- Direct SQL invocation is more efficient than HTTP round-trip for this backstop.
select cron.schedule(
  'phase22-requeue-stuck-uploads',
  '*/5 * * * *',
  $$select requeue_stuck_uploads()$$
);

-- One-time Vault setup (operator runs these ONCE in Dashboard > Project Settings > Vault):
--   If not already done from Phase 14:
--   1. name='project_url'      secret='https://<PROJECT_REF>.supabase.co'
--   2. name='service_role_key'  secret='<SERVICE_ROLE_KEY>'
--
-- Edge function secrets (operator runs via CLI):
--   supabase secrets set MUX_TOKEN_ID=... MUX_TOKEN_SECRET=...
--   supabase secrets set SUPABASE_URL=https://<PROJECT_REF>.supabase.co
--   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY>
--   supabase secrets set FFMPEG_WORKER_URL=https://<worker>.fly.dev/transcode
--   supabase secrets set WORKER_SHARED_SECRET=<shared-secret>

-- To disable any schedule:
--   select cron.unschedule('phase22-prune-expired-videos');
--   select cron.unschedule('phase22-archive-idle-sources');
--   select cron.unschedule('phase22-prune-webhook-events');
--   select cron.unschedule('phase22-requeue-stuck-uploads');
--
-- To inspect scheduled jobs:
--   select * from cron.job where jobname like 'phase22-%';
--
-- To check run history:
--   select * from cron.job_run_details
--   where jobid = (select jobid from cron.job where jobname='phase22-prune-expired-videos')
--   order by start_time desc limit 10;
