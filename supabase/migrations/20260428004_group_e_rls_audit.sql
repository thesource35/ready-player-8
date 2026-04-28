-- Phase: Group E — per-table RLS audit for the 10 ambiguous tables.
--
-- Completes the multi-tenancy migration by handling the tables that didn't
-- fit neatly into Group A (direct org_id), B (project-scoped), C (had user_id
-- only, gained org_id), or D (user-personal by design).
--
-- Each table here got individual analysis based on its schema + semantic
-- purpose (CLAUDE.md "construction social network" + "billionaire wealth
-- suite" context). The 10 tables cluster into 5 access patterns:
--
--   User-personal (2): cs_ai_messages, cs_credentials
--   Public read, auth write (3): cs_endorsements, cs_feed_posts, cs_reviews
--   Public read, admin/service write (2): cs_market_data, cs_trade_requirements
--   Org-scoped via FK chain (1): cs_certifications (via cs_team_members.org_id)
--   Service-role only (2): cs_rental_leads, cs_video_webhook_events

-- =============================================================================
-- Pattern 1: User-personal (only owner reads/writes)
-- =============================================================================

-- ---- cs_ai_messages ----
-- Claude conversation history. Each row tied to a user_id. AI chats are
-- private — never visible to other org members.

alter table cs_ai_messages enable row level security;
drop policy if exists cs_ai_messages_select on cs_ai_messages;
drop policy if exists cs_ai_messages_insert on cs_ai_messages;
drop policy if exists cs_ai_messages_update on cs_ai_messages;
drop policy if exists cs_ai_messages_delete on cs_ai_messages;

create policy cs_ai_messages_select on cs_ai_messages for select to authenticated
  using (user_id = auth.uid());
create policy cs_ai_messages_insert on cs_ai_messages for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_ai_messages_update on cs_ai_messages for update to authenticated
  using (user_id = auth.uid());
create policy cs_ai_messages_delete on cs_ai_messages for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_credentials ----
-- Professional licensing/credentials. Owner sees their own; org owner/admin
-- can read for verification (HR / compliance workflow). Owner-only writes.

alter table cs_credentials enable row level security;
drop policy if exists cs_credentials_select on cs_credentials;
drop policy if exists cs_credentials_insert on cs_credentials;
drop policy if exists cs_credentials_update on cs_credentials;
drop policy if exists cs_credentials_delete on cs_credentials;

create policy cs_credentials_select on cs_credentials for select to authenticated
  using (
    user_id = auth.uid()
    or user_id in (
      select tm.user_id from cs_team_members tm
      where tm.org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
    )
  );
create policy cs_credentials_insert on cs_credentials for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_credentials_update on cs_credentials for update to authenticated
  using (user_id = auth.uid());
create policy cs_credentials_delete on cs_credentials for delete to authenticated
  using (user_id = auth.uid());

-- =============================================================================
-- Pattern 2: Public read, authenticated write (social/reputation tables)
-- =============================================================================

-- ---- cs_endorsements ----
-- Peer endorsements (LinkedIn-style). Public read for reputation visibility.
-- Auth users add endorsements; only endorser deletes.

alter table cs_endorsements enable row level security;
drop policy if exists cs_endorsements_select on cs_endorsements;
drop policy if exists cs_endorsements_insert on cs_endorsements;
drop policy if exists cs_endorsements_update on cs_endorsements;
drop policy if exists cs_endorsements_delete on cs_endorsements;

create policy cs_endorsements_select on cs_endorsements for select to anon, authenticated
  using (true);
create policy cs_endorsements_insert on cs_endorsements for insert to authenticated
  with check (endorser_id = auth.uid());
-- No UPDATE — endorsements are append-only (deleting + re-creating is the only edit path).
create policy cs_endorsements_delete on cs_endorsements for delete to authenticated
  using (endorser_id = auth.uid());

-- ---- cs_feed_posts ----
-- Construction social network posts (CLAUDE.md "construction professionals
-- social feed"). Public read; author writes.

alter table cs_feed_posts enable row level security;
drop policy if exists cs_feed_posts_select on cs_feed_posts;
drop policy if exists cs_feed_posts_insert on cs_feed_posts;
drop policy if exists cs_feed_posts_update on cs_feed_posts;
drop policy if exists cs_feed_posts_delete on cs_feed_posts;

create policy cs_feed_posts_select on cs_feed_posts for select to anon, authenticated
  using (true);
create policy cs_feed_posts_insert on cs_feed_posts for insert to authenticated
  with check (user_id = auth.uid());
create policy cs_feed_posts_update on cs_feed_posts for update to authenticated
  using (user_id = auth.uid());
create policy cs_feed_posts_delete on cs_feed_posts for delete to authenticated
  using (user_id = auth.uid());

-- ---- cs_reviews ----
-- Peer reviews (Yelp-style). Public read for trust/reputation. Reviewer-only writes.

alter table cs_reviews enable row level security;
drop policy if exists cs_reviews_select on cs_reviews;
drop policy if exists cs_reviews_insert on cs_reviews;
drop policy if exists cs_reviews_update on cs_reviews;
drop policy if exists cs_reviews_delete on cs_reviews;

create policy cs_reviews_select on cs_reviews for select to anon, authenticated
  using (true);
create policy cs_reviews_insert on cs_reviews for insert to authenticated
  with check (reviewer_id = auth.uid());
create policy cs_reviews_update on cs_reviews for update to authenticated
  using (reviewer_id = auth.uid());
create policy cs_reviews_delete on cs_reviews for delete to authenticated
  using (reviewer_id = auth.uid());

-- =============================================================================
-- Pattern 3: Public read, admin/service write (global reference data)
-- =============================================================================

-- ---- cs_market_data ----
-- Market intelligence data per city. Read by all (anyone sees market trends);
-- writes only via service-role (admin/cron-pushed data updates).

alter table cs_market_data enable row level security;
drop policy if exists cs_market_data_select on cs_market_data;
drop policy if exists cs_market_data_insert on cs_market_data;
drop policy if exists cs_market_data_update on cs_market_data;
drop policy if exists cs_market_data_delete on cs_market_data;

create policy cs_market_data_select on cs_market_data for select to anon, authenticated
  using (true);
-- INSERT/UPDATE/DELETE: no policies = all blocked for anon + authenticated.
-- service-role bypasses RLS entirely, so admin scripts/crons that use the
-- SUPABASE_SERVICE_ROLE_KEY can still write.

-- ---- cs_trade_requirements ----
-- Static reference data: which trades require what licensing/certifications.
-- Read by all; writes only via service-role.

alter table cs_trade_requirements enable row level security;
drop policy if exists cs_trade_requirements_select on cs_trade_requirements;
drop policy if exists cs_trade_requirements_insert on cs_trade_requirements;
drop policy if exists cs_trade_requirements_update on cs_trade_requirements;
drop policy if exists cs_trade_requirements_delete on cs_trade_requirements;

create policy cs_trade_requirements_select on cs_trade_requirements for select to anon, authenticated
  using (true);
-- No write policies; service-role only.

-- =============================================================================
-- Pattern 4: Org-scoped via FK chain (cs_certifications → cs_team_members.org_id)
-- =============================================================================

-- ---- cs_certifications ----
-- Team-member certifications. Each cert.member_id points at cs_team_members.id;
-- cs_team_members has org_id (added in 20260428002). 3-hop RLS:
-- cert → member → org → user_orgs.

alter table cs_certifications enable row level security;
drop policy if exists cs_certifications_select on cs_certifications;
drop policy if exists cs_certifications_insert on cs_certifications;
drop policy if exists cs_certifications_update on cs_certifications;
drop policy if exists cs_certifications_delete on cs_certifications;

create policy cs_certifications_select on cs_certifications for select to authenticated
  using (
    member_id in (
      select id from cs_team_members
      where org_id in (select org_id from user_orgs where user_id = auth.uid())
    )
  );
create policy cs_certifications_insert on cs_certifications for insert to authenticated
  with check (
    member_id in (
      select id from cs_team_members
      where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
    )
  );
create policy cs_certifications_update on cs_certifications for update to authenticated
  using (
    member_id in (
      select id from cs_team_members
      where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
    )
  );
create policy cs_certifications_delete on cs_certifications for delete to authenticated
  using (
    member_id in (
      select id from cs_team_members
      where org_id in (select org_id from user_orgs where user_id = auth.uid() and role in ('owner', 'admin'))
    )
  );

-- =============================================================================
-- Pattern 5: Service-role only (no client access)
-- =============================================================================

-- ---- cs_rental_leads ----
-- Inbound equipment-rental lead form submissions. Sensitive PII (name, email,
-- phone, company, project location). Only sales/admin sees these — and the app
-- accesses them via the service-role key in trusted server paths only.
-- RLS enabled with NO policies = all authenticated/anon access denied.
-- service-role bypasses RLS so it can still read/write.

alter table cs_rental_leads enable row level security;
drop policy if exists cs_rental_leads_select on cs_rental_leads;
drop policy if exists cs_rental_leads_insert on cs_rental_leads;
drop policy if exists cs_rental_leads_update on cs_rental_leads;
drop policy if exists cs_rental_leads_delete on cs_rental_leads;
-- Intentionally NO policies created.

-- ---- cs_video_webhook_events ----
-- Mux webhook event log (system internal). Written by /api/video/mux/webhook
-- via service-role key; never read by clients. RLS enabled with NO policies.

alter table cs_video_webhook_events enable row level security;
drop policy if exists cs_video_webhook_events_select on cs_video_webhook_events;
drop policy if exists cs_video_webhook_events_insert on cs_video_webhook_events;
drop policy if exists cs_video_webhook_events_update on cs_video_webhook_events;
drop policy if exists cs_video_webhook_events_delete on cs_video_webhook_events;
-- Intentionally NO policies created.

-- =============================================================================
-- End of Group E. Multi-tenancy migration complete.
-- =============================================================================
-- 39 of 48 cs_* tables now have explicit RLS policies.
-- 8 Group D wealth/personal tables (cs_decision_journal, cs_leverage_snapshots,
-- cs_psychology_sessions, cs_wealth_*) keep their existing user_id-based RLS
-- (set up by their original phase migrations); not changed by this series.
-- 1 table (cs_organizations) was set up by 20260413001.
