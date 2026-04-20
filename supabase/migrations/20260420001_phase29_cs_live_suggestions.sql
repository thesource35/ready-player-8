-- Phase 29: cs_live_suggestions — AI live feed cards per drone clip. D-17/D-22/D-24. 2026-04-20.

-- STEP A: Table with 11 columns matching D-17
create table cs_live_suggestions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references cs_projects(id) on delete cascade,
  org_id uuid not null,
  generated_at timestamptz not null default now(),
  source_asset_id uuid not null references cs_video_assets(id) on delete cascade,
  model text not null check (model in ('claude-haiku-4-5-20251001', 'claude-sonnet-4-6', 'claude-opus-4-7', 'budget_reached_marker')),
  suggestion_text text not null check (char_length(suggestion_text) between 1 and 2000),
  action_hint jsonb null,
  dismissed_at timestamptz null,
  dismissed_by uuid null references auth.users(id),
  created_at timestamptz not null default now()
);

-- STEP B: 3 performance indexes
-- Primary: card-stream query (LIVE-09) + retention scan (LIVE-13) both ride this composite index
create index cs_live_suggestions_project_generated_idx
  on cs_live_suggestions(project_id, generated_at desc);

-- Budget-count query (LIVE-11) — generated_at filter by date range
-- RESEARCH §Code Examples initially proposed a PARTIAL index `where generated_at > now() - interval '1 day'`,
-- but now() is not IMMUTABLE so PostgreSQL rejects it in partial-index predicates. Plain btree serves the
-- budget-count query just as well alongside the composite index above.
create index cs_live_suggestions_project_today_idx
  on cs_live_suggestions(project_id, generated_at);

-- FK lookup for asset deletion cascade verification
create index cs_live_suggestions_source_asset_idx
  on cs_live_suggestions(source_asset_id);

-- STEP C: Enable RLS + 2 policies mirroring Phase 21 cs_equipment pattern
alter table cs_live_suggestions enable row level security;

-- SELECT: authenticated users read only their own org's suggestions (T-29-RLS mitigation)
create policy cs_live_suggestions_select
  on cs_live_suggestions
  for select
  to authenticated
  using (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
  );

-- UPDATE: authenticated users can only dismiss suggestions in their own org,
-- and the dismissed_by field must match the caller (T-29-01-02 cross-user dismissal forgery mitigation)
create policy cs_live_suggestions_dismiss
  on cs_live_suggestions
  for update
  to authenticated
  using (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
  )
  with check (
    org_id in (select org_id from user_orgs where user_id = auth.uid())
    and dismissed_by = auth.uid()
  );

-- STEP D: Explicit non-policies documented as SQL comments (intent, no policy created)
-- No INSERT policy — service_role only (generate-live-suggestions Edge Function writes via createClient with SUPABASE_SERVICE_ROLE_KEY) — T-29-01-03 mitigation
-- No DELETE policy — service_role only (prune-expired-suggestions Edge Function) — T-29-01-04 mitigation

-- STEP E: Table comment for downstream discovery
comment on table cs_live_suggestions is 'Phase 29 AI live-feed observation cards per drone clip (D-17). Service-role writes only. UPDATE limited to dismissed_at/dismissed_by by row owner auth.uid(). 7-day retention via prune-expired-suggestions Edge Function (29-04).';
