-- Phase 15: pg_cron schedule for cert expiry sweep (D-05)
-- Runs daily at 13:15 UTC (15 minutes after Phase 14 notifications-schedule)
--
-- Reuses Vault secrets established by Phase 14 (20260407_phase14_pgcron_schedule.sql):
--   name='project_url'       -> https://<PROJECT_REF>.supabase.co
--   name='service_role_key'  -> <SERVICE_ROLE_KEY>
--
-- Requires: pg_cron and pg_net (installed by 20260407_phase14_notifications.sql)
-- Pattern mirrors phase14-notifications-nightly-scheduler exactly.

-- Unschedule any previous version so re-running the migration is idempotent
do $$
begin
  if exists (select 1 from cron.job where jobname = 'phase15-cert-expiry-sweep') then
    perform cron.unschedule('phase15-cert-expiry-sweep');
  end if;
end $$;

select cron.schedule(
  'phase15-cert-expiry-sweep',
  '15 13 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/cert-expiry-scan',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
