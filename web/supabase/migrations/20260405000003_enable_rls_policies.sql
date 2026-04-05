-- Migration 3 of 3: Enable RLS and create per-user access policies
-- Prerequisite: Both iOS and web clients must send auth tokens (Phase 2 complete)
-- CRITICAL: Run AFTER migration 2 (backfill). Enabling RLS without backfill makes data invisible.

-- Enable RLS on all tables
ALTER TABLE cs_user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_todos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_schedule_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_ops_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_rfis ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_change_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_punch_pro ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_rental_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_market_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_ai_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_tax_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_timecards ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_wealth_opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_decision_journal ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_psychology_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_leverage_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE cs_wealth_tracking ENABLE ROW LEVEL SECURITY;

-- Standard per-user policies (own data only)
DROP POLICY IF EXISTS "Users manage own profiles" ON cs_user_profiles;
CREATE POLICY "Users manage own profiles" ON cs_user_profiles FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own projects" ON cs_projects;
CREATE POLICY "Users manage own projects" ON cs_projects FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own contracts" ON cs_contracts;
CREATE POLICY "Users manage own contracts" ON cs_contracts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own todos" ON cs_todos;
CREATE POLICY "Users manage own todos" ON cs_todos FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own schedule" ON cs_schedule_events;
CREATE POLICY "Users manage own schedule" ON cs_schedule_events FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own reminders" ON cs_reminders;
CREATE POLICY "Users manage own reminders" ON cs_reminders FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own alerts" ON cs_ops_alerts;
CREATE POLICY "Users manage own alerts" ON cs_ops_alerts FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own rfis" ON cs_rfis;
CREATE POLICY "Users manage own rfis" ON cs_rfis FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own change orders" ON cs_change_orders;
CREATE POLICY "Users manage own change orders" ON cs_change_orders FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own punch items" ON cs_punch_pro;
CREATE POLICY "Users manage own punch items" ON cs_punch_pro FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own transactions" ON cs_transactions;
CREATE POLICY "Users manage own transactions" ON cs_transactions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own tax expenses" ON cs_tax_expenses;
CREATE POLICY "Users manage own tax expenses" ON cs_tax_expenses FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own daily logs" ON cs_daily_logs;
CREATE POLICY "Users manage own daily logs" ON cs_daily_logs FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own timecards" ON cs_timecards;
CREATE POLICY "Users manage own timecards" ON cs_timecards FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own wealth opportunities" ON cs_wealth_opportunities;
CREATE POLICY "Users manage own wealth opportunities" ON cs_wealth_opportunities FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own decision journal" ON cs_decision_journal;
CREATE POLICY "Users manage own decision journal" ON cs_decision_journal FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own psychology sessions" ON cs_psychology_sessions;
CREATE POLICY "Users manage own psychology sessions" ON cs_psychology_sessions FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own leverage snapshots" ON cs_leverage_snapshots;
CREATE POLICY "Users manage own leverage snapshots" ON cs_leverage_snapshots FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users manage own wealth tracking" ON cs_wealth_tracking;
CREATE POLICY "Users manage own wealth tracking" ON cs_wealth_tracking FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Public-read tables (community data visible to all, write restricted to owner)
DROP POLICY IF EXISTS "Public can read feed posts" ON cs_feed_posts;
CREATE POLICY "Public can read feed posts" ON cs_feed_posts FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users manage own feed posts" ON cs_feed_posts;
CREATE POLICY "Users manage own feed posts" ON cs_feed_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users update own feed posts" ON cs_feed_posts;
CREATE POLICY "Users update own feed posts" ON cs_feed_posts FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users delete own feed posts" ON cs_feed_posts;
CREATE POLICY "Users delete own feed posts" ON cs_feed_posts FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can read market data" ON cs_market_data;
CREATE POLICY "Public can read market data" ON cs_market_data FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users manage own market data" ON cs_market_data;
CREATE POLICY "Users manage own market data" ON cs_market_data FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users update own market data" ON cs_market_data;
CREATE POLICY "Users update own market data" ON cs_market_data FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users delete own market data" ON cs_market_data;
CREATE POLICY "Users delete own market data" ON cs_market_data FOR DELETE USING (auth.uid() = user_id);

-- Rental leads: anyone can insert (public form), only owner can read/modify
DROP POLICY IF EXISTS "Anyone can submit rental leads" ON cs_rental_leads;
CREATE POLICY "Anyone can submit rental leads" ON cs_rental_leads FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Users read own rental leads" ON cs_rental_leads;
CREATE POLICY "Users read own rental leads" ON cs_rental_leads FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users manage own rental leads" ON cs_rental_leads;
CREATE POLICY "Users manage own rental leads" ON cs_rental_leads FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users delete own rental leads" ON cs_rental_leads;
CREATE POLICY "Users delete own rental leads" ON cs_rental_leads FOR DELETE USING (auth.uid() = user_id);

-- AI messages: per-user only
DROP POLICY IF EXISTS "Users manage own AI messages" ON cs_ai_messages;
CREATE POLICY "Users manage own AI messages" ON cs_ai_messages FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
