-- Phase 14: pg_cron schedule for nightly bid-deadline scan (D-17)
-- Runs daily at 13:00 UTC (~08:00 America/Chicago)
--
-- Prerequisites — admin must populate Supabase Vault with two secrets BEFORE applying:
--   1. name='project_url'        secret='https://<PROJECT_REF>.supabase.co'
--   2. name='service_role_key'   secret='<SERVICE_ROLE_KEY>'
--
-- Vault path: Dashboard → Project Settings → Vault → New secret
-- Reason: Supabase managed Postgres denies `ALTER DATABASE postgres SET app.settings.*`
-- to non-superusers (ERROR 42501). Vault is the supported pattern for storing secrets
-- pg_cron jobs need to read at runtime.
--
-- Requires: pg_cron and pg_net (installed by 20260407_phase14_notifications.sql)

-- Unschedule any previous version so re-running the migration is idempotent
do $$
begin
  if exists (select 1 from cron.job where jobname = 'notifications-nightly-scheduler') then
    perform cron.unschedule('notifications-nightly-scheduler');
  end if;
end $$;

select cron.schedule(
  'notifications-nightly-scheduler',
  '0 13 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/notifications-schedule',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
