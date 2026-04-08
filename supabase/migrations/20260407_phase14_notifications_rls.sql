-- Phase 14: RLS for notifications, activity events, device tokens, project members
-- Decisions: D-02 (triggers are sole writers), D-10/D-11 (per-user state),
-- D-15 (own tokens only), Phase 03 project-membership pattern
-- See: .planning/phases/14-notifications-activity-feed/SCHEMA-AUDIT.md

alter table cs_activity_events enable row level security;
alter table cs_notifications   enable row level security;
alter table cs_device_tokens   enable row level security;
alter table cs_project_members enable row level security;

-- =============================================================================
-- cs_notifications — users only see/modify their own rows
-- =============================================================================
drop policy if exists "select own notifications" on cs_notifications;
create policy "select own notifications" on cs_notifications
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "update own notifications" on cs_notifications;
create policy "update own notifications" on cs_notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "delete own notifications" on cs_notifications;
create policy "delete own notifications" on cs_notifications
  for delete to authenticated
  using (user_id = auth.uid());

-- No client INSERT policy — notifications-fanout Edge Function uses service role.

-- =============================================================================
-- cs_activity_events — project members only; no client writes
-- =============================================================================
drop policy if exists "select project events" on cs_activity_events;
create policy "select project events" on cs_activity_events
  for select to authenticated
  using (
    project_id is null
    or exists (
      select 1 from cs_project_members m
      where m.project_id = cs_activity_events.project_id
        and m.user_id = auth.uid()
    )
  );

-- No client write policies — emit_activity_event() trigger (SECURITY DEFINER) is the sole writer (D-02).

-- =============================================================================
-- cs_device_tokens — users can only read/write their own tokens (D-15)
-- =============================================================================
drop policy if exists "select own tokens" on cs_device_tokens;
create policy "select own tokens" on cs_device_tokens
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "insert own tokens" on cs_device_tokens;
create policy "insert own tokens" on cs_device_tokens
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "update own tokens" on cs_device_tokens;
create policy "update own tokens" on cs_device_tokens
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "delete own tokens" on cs_device_tokens;
create policy "delete own tokens" on cs_device_tokens
  for delete to authenticated
  using (user_id = auth.uid());

-- =============================================================================
-- cs_project_members — users see their own memberships
-- (Created by Phase 14 per SCHEMA-AUDIT Path B)
-- =============================================================================
drop policy if exists "select own memberships" on cs_project_members;
create policy "select own memberships" on cs_project_members
  for select to authenticated
  using (user_id = auth.uid());

-- No client write policies — memberships are managed by service role / admin flows.
