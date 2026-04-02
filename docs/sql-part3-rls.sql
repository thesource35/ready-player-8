-- PART 3: ROW LEVEL SECURITY + POLICIES
-- Paste this into Supabase SQL Editor and click RUN (after Part 1 and Part 2)

alter table cs_projects enable row level security;
alter table cs_contracts enable row level security;
alter table cs_market_data enable row level security;
alter table cs_ai_messages enable row level security;
alter table cs_wealth_opportunities enable row level security;
alter table cs_decision_journal enable row level security;
alter table cs_psychology_sessions enable row level security;
alter table cs_leverage_snapshots enable row level security;
alter table cs_wealth_tracking enable row level security;
alter table cs_daily_logs enable row level security;
alter table cs_timecards enable row level security;
alter table cs_ops_alerts enable row level security;
alter table cs_rfis enable row level security;
alter table cs_change_orders enable row level security;
alter table cs_punch_pro enable row level security;
alter table cs_feed_posts enable row level security;
alter table cs_transactions enable row level security;
alter table cs_crypto_transactions enable row level security;
alter table cs_tax_expenses enable row level security;
alter table cs_equipment_rentals enable row level security;
alter table cs_user_profiles enable row level security;
alter table cs_verification_requests enable row level security;
alter table cs_verified_badges enable row level security;
alter table cs_verification_log enable row level security;
alter table cs_trade_requirements enable row level security;

create policy "Public read" on cs_projects for select using (true);
create policy "Public read" on cs_contracts for select using (true);
create policy "Public read" on cs_market_data for select using (true);
create policy "Public read" on cs_feed_posts for select using (true);
create policy "Public read" on cs_equipment_rentals for select using (true);
create policy "Public read" on cs_trade_requirements for select using (true);
create policy "Public read" on cs_ops_alerts for select using (true);
create policy "Public read" on cs_rfis for select using (true);
create policy "Public read" on cs_change_orders for select using (true);
create policy "Public read" on cs_punch_pro for select using (true);

create policy "Users read own" on cs_ai_messages for select using (true);
create policy "Users insert" on cs_ai_messages for insert with check (true);
create policy "Users read own" on cs_verification_requests for select using (auth.uid() = user_id);
create policy "Users insert" on cs_verification_requests for insert with check (auth.uid() = user_id);
create policy "Users read own" on cs_verified_badges for select using (auth.uid() = user_id);
create policy "Users read own" on cs_user_profiles for select using (auth.uid() = user_id);
create policy "Users insert" on cs_user_profiles for insert with check (auth.uid() = user_id);
create policy "Users update own" on cs_user_profiles for update using (auth.uid() = user_id);

create policy "Auth read" on cs_daily_logs for select using (true);
create policy "Auth insert" on cs_daily_logs for insert with check (true);
create policy "Auth read" on cs_timecards for select using (true);
create policy "Auth insert" on cs_timecards for insert with check (true);
create policy "Auth read" on cs_transactions for select using (true);
create policy "Auth insert" on cs_transactions for insert with check (true);
create policy "Auth read" on cs_crypto_transactions for select using (true);
create policy "Auth insert" on cs_crypto_transactions for insert with check (true);
create policy "Auth read" on cs_tax_expenses for select using (true);
create policy "Auth insert" on cs_tax_expenses for insert with check (true);
create policy "Auth read" on cs_wealth_opportunities for select using (true);
create policy "Auth insert" on cs_wealth_opportunities for insert with check (true);
create policy "Auth read" on cs_decision_journal for select using (true);
create policy "Auth insert" on cs_decision_journal for insert with check (true);
create policy "Auth read" on cs_psychology_sessions for select using (true);
create policy "Auth insert" on cs_psychology_sessions for insert with check (true);
create policy "Auth read" on cs_leverage_snapshots for select using (true);
create policy "Auth insert" on cs_leverage_snapshots for insert with check (true);
create policy "Auth read" on cs_wealth_tracking for select using (true);
create policy "Auth insert" on cs_wealth_tracking for insert with check (true);

create policy "Users read own logs" on cs_verification_log for select using (
  request_id in (select id from cs_verification_requests where user_id = auth.uid())
);
