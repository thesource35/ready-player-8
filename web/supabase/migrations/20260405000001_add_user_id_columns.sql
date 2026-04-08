-- Migration 1 of 3: Add user_id column to tables missing it
-- SAFE: ADD COLUMN IF NOT EXISTS is idempotent
-- Temporary default '00000000-...' will be replaced in migration 2

-- NOT NULL tables (cascade on user delete)
ALTER TABLE cs_user_profiles ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_projects ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_contracts ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_todos ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_schedule_events ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_reminders ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_ops_alerts ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_rfis ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_change_orders ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_punch_pro ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_transactions ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_tax_expenses ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_daily_logs ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_timecards ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_wealth_opportunities ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_decision_journal ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_psychology_sessions ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_leverage_snapshots ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE cs_wealth_tracking ADD COLUMN IF NOT EXISTS user_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000' REFERENCES auth.users(id) ON DELETE CASCADE;

-- NULLABLE tables (set null on user delete)
ALTER TABLE cs_feed_posts ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE cs_rental_leads ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE cs_market_data ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE cs_ai_messages ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- Indexes for user_id lookups
CREATE INDEX IF NOT EXISTS idx_profiles_user ON cs_user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_projects_user ON cs_projects(user_id);
CREATE INDEX IF NOT EXISTS idx_contracts_user ON cs_contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_todos_user ON cs_todos(user_id);
CREATE INDEX IF NOT EXISTS idx_schedule_user ON cs_schedule_events(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_user ON cs_reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_alerts_user ON cs_ops_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_rfis_user ON cs_rfis(user_id);
CREATE INDEX IF NOT EXISTS idx_changes_user ON cs_change_orders(user_id);
CREATE INDEX IF NOT EXISTS idx_punch_user ON cs_punch_pro(user_id);
CREATE INDEX IF NOT EXISTS idx_leads_user ON cs_rental_leads(user_id);
CREATE INDEX IF NOT EXISTS idx_market_user ON cs_market_data(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_user ON cs_ai_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user ON cs_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_tax_user ON cs_tax_expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_user ON cs_daily_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_timecards_user ON cs_timecards(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_user ON cs_feed_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_wealth_opp_user ON cs_wealth_opportunities(user_id);
CREATE INDEX IF NOT EXISTS idx_decisions_user ON cs_decision_journal(user_id);
CREATE INDEX IF NOT EXISTS idx_psych_user ON cs_psychology_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_leverage_user ON cs_leverage_snapshots(user_id);
CREATE INDEX IF NOT EXISTS idx_wealth_track_user ON cs_wealth_tracking(user_id);
