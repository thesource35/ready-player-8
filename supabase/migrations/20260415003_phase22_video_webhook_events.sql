-- Phase 22: cs_video_webhook_events — HMAC-verified Mux webhook dedupe (D-32). 7-day retention via cron in 22-10.
-- Service-role-only write path: no authenticated user policies defined; default-deny applies.
-- Threat T-22-01-05: Information Disclosure mitigation — RLS enabled + no user policies means
--   authenticated users cannot SELECT/INSERT/UPDATE/DELETE. Only service_role (bypasses RLS)
--   can touch this table — that's the Mux webhook handler and the retention cron.

create table cs_video_webhook_events (
  event_id text primary key,
  event_type text not null,
  received_at timestamptz not null default now(),
  processed_at timestamptz null,
  payload_hash text not null,
  processing_error text null
);

create index if not exists cs_video_webhook_events_received_at_idx
  on cs_video_webhook_events(received_at);

alter table cs_video_webhook_events enable row level security;

-- Intentionally NO authenticated-user policies defined here.
-- Service-role bypasses RLS and is the only writer (Mux webhook handler in 22-03,
-- retention prune cron in 22-10). Default-deny protects against any future
-- accidental grant to `authenticated` role.

comment on table cs_video_webhook_events is 'Phase 22 Mux webhook dedupe table (D-32). Service-role-only; 7-day retention.';
