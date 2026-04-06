-- Migration: Add updated_at auto-update triggers to all cs_* tables
-- Run this in Supabase SQL Editor or via supabase db push
-- Idempotent: safe to run multiple times (DROP IF EXISTS + CREATE OR REPLACE)

-- Step 1: Create the trigger function (idempotent with CREATE OR REPLACE)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Apply trigger to each cs_* table
-- Using DROP IF EXISTS + CREATE to make migration idempotent

DROP TRIGGER IF EXISTS set_updated_at ON cs_projects;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_contracts;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_contracts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_market_data;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_market_data
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_daily_logs;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_daily_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_timecards;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_timecards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_ops_alerts;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_ops_alerts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_rfis;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_rfis
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_change_orders;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_change_orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_punch_pro;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_punch_pro
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_feed_posts;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_feed_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_transactions;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_tax_expenses;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_tax_expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_rental_leads;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_rental_leads
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_ai_messages;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_ai_messages
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_wealth_opportunities;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_wealth_opportunities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_decision_journal;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_decision_journal
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_psychology_sessions;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_psychology_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_leverage_snapshots;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_leverage_snapshots
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_updated_at ON cs_wealth_tracking;
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON cs_wealth_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
