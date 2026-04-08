-- Migration 2 of 3: Backfill existing rows with admin user_id
-- IMPORTANT: Run AFTER migration 1 (user_id columns must exist)
-- If no users exist yet, this safely no-ops

DO $$
DECLARE
  admin_uid uuid;
BEGIN
  -- Pick the first registered user as the owner of orphan rows
  SELECT id INTO admin_uid FROM auth.users ORDER BY created_at ASC LIMIT 1;

  -- If no users exist, nothing to backfill
  IF admin_uid IS NULL THEN
    RAISE NOTICE 'No users found — skipping backfill (new rows will set user_id via auth)';
    RETURN;
  END IF;

  -- Backfill NOT NULL tables: update rows still using the placeholder UUID
  UPDATE cs_user_profiles SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_projects SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_contracts SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_todos SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_schedule_events SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_reminders SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_ops_alerts SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_rfis SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_change_orders SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_punch_pro SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_transactions SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_tax_expenses SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_daily_logs SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_timecards SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_wealth_opportunities SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_decision_journal SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_psychology_sessions SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_leverage_snapshots SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';
  UPDATE cs_wealth_tracking SET user_id = admin_uid WHERE user_id = '00000000-0000-0000-0000-000000000000';

  -- Backfill NULLABLE tables: update rows with NULL user_id
  UPDATE cs_feed_posts SET user_id = admin_uid WHERE user_id IS NULL;
  UPDATE cs_rental_leads SET user_id = admin_uid WHERE user_id IS NULL;
  UPDATE cs_market_data SET user_id = admin_uid WHERE user_id IS NULL;
  UPDATE cs_ai_messages SET user_id = admin_uid WHERE user_id IS NULL;

  RAISE NOTICE 'Backfill complete — all orphan rows assigned to user %', admin_uid;
END $$;
