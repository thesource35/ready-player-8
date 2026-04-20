-- Phase 29 LIVE-13 — schedule prune-expired-suggestions daily at 03:45 UTC.
-- Stagger slot 03:45 is 15 minutes after Phase 22's latest 03:30 slot (prune-webhook-events).
-- Reuses Vault secrets 'project_url' and 'service_role_key'.

create extension if not exists pg_cron with schema extensions;

do $$
begin
  if exists (select 1 from cron.job where jobname = 'phase29-prune-expired-suggestions') then
    perform cron.unschedule('phase29-prune-expired-suggestions');
  end if;
end $$;

-- Daily 03:45 UTC: delete cs_live_suggestions rows older than 7 days (D-21).
select cron.schedule(
  'phase29-prune-expired-suggestions',
  '45 3 * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/prune-expired-suggestions',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type', 'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
