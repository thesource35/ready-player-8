-- Phase 29 LIVE-06 — schedule generate-live-suggestions Edge Function every 15 minutes.
-- Reuses Vault secrets 'project_url' and 'service_role_key' established by Phase 14/22.
-- Requires: pg_cron and pg_net (installed via Phase 14/22 migrations).

create extension if not exists pg_cron with schema extensions;

-- Idempotent: unschedule any prior version so re-running is safe
do $$
begin
  if exists (select 1 from cron.job where jobname = 'phase29-generate-live-suggestions') then
    perform cron.unschedule('phase29-generate-live-suggestions');
  end if;
end $$;

-- Every 15 minutes: invoke generate-live-suggestions Edge Function (D-14, D-25).
-- Body is '{}' — Edge Function iterates all active projects with drone assets in the last 24h.
-- Budget cap (D-22) is enforced inside the Edge Function.
select cron.schedule(
  'phase29-generate-live-suggestions',
  '*/15 * * * *',
  $$
  select net.http_post(
    url     := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/generate-live-suggestions',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'),
      'Content-Type', 'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);

comment on extension pg_cron is 'Phase 29 adds phase29-generate-live-suggestions (every 15 min). Phase 22 owns phase22-prune-expired-videos/archive-idle-sources/prune-webhook-events/requeue-stuck-uploads. Phase 29-04 adds phase29-prune-expired-suggestions (daily 03:45 UTC).';

-- Edge Function secrets required (set by operator; see 29-01 BLOCKING task):
--   supabase secrets set ANTHROPIC_API_KEY=<key>
--   supabase secrets set SUPABASE_URL=https://<PROJECT_REF>.supabase.co    (reused from Phase 22)
--   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY>        (reused from Phase 22)
--
-- To disable schedule:
--   select cron.unschedule('phase29-generate-live-suggestions');
--
-- To inspect:
--   select * from cron.job where jobname = 'phase29-generate-live-suggestions';
--   select * from cron.job_run_details
--     where jobid = (select jobid from cron.job where jobname='phase29-generate-live-suggestions')
--     order by start_time desc limit 10;
