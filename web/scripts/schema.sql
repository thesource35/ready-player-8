-- ConstructionOS Database Schema
-- Run this against a fresh Supabase project to create all required tables.
-- Requires: Supabase Auth enabled (provides auth.users)

-- ============================================================
-- USER PROFILES
-- ============================================================
create table if not exists cs_user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null default '',
  company text not null default '',
  title text not null default '',
  subscription_tier text not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

-- ============================================================
-- PROJECTS
-- ============================================================
create table if not exists cs_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  client text not null default '',
  type text not null default 'General',
  status text not null default 'On Track',
  progress integer not null default 0,
  budget text not null default '$0',
  score integer not null default 0,
  team text not null default '',
  start_date text not null default '',
  end_date text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- CONTRACTS (bid pipeline)
-- ============================================================
create table if not exists cs_contracts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  client text not null default '',
  sector text not null default '',
  stage text not null default 'Open For Bid',
  budget text not null default '$0',
  score integer not null default 0,
  watch_count integer not null default 0,
  location text not null default '',
  bid_due text not null default 'N/A',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- FEED POSTS (also used for job listings via post_type = 'hiring')
-- ============================================================
create table if not exists cs_feed_posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  author_name text not null default '',
  author_title text not null default '',
  author_company text not null default '',
  content text not null default '',
  post_type text not null default 'update',
  tags text[] not null default '{}',
  likes integer not null default 0,
  comments integer not null default 0,
  shares integer not null default 0,
  photo_count integer not null default 0,
  created_at timestamptz not null default now()
);

-- ============================================================
-- TASKS / TODOS
-- ============================================================
create table if not exists cs_todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  priority text not null default 'medium',
  status text not null default 'pending',
  category text not null default 'ops',
  project text not null default '',
  due_date text not null default '',
  time text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- SCHEDULE EVENTS
-- ============================================================
create table if not exists cs_schedule_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  type text not null default 'meeting',
  date text not null default '',
  start_time text not null default '',
  end_time text not null default '',
  location text not null default '',
  color text not null default '#4AC4CC',
  created_at timestamptz not null default now()
);

-- ============================================================
-- REMINDERS (AI-generated)
-- ============================================================
create table if not exists cs_reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  message text not null default '',
  icon text not null default '',
  trigger_at timestamptz not null default now(),
  dismissed boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- OPS — ALERTS
-- ============================================================
create table if not exists cs_ops_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  owner text not null default '',
  severity integer not null default 1,
  due_date text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- OPS — RFIs
-- ============================================================
create table if not exists cs_rfis (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref text not null default '',
  description text not null default '',
  category text not null default '',
  status text not null default 'OPEN',
  created_at timestamptz not null default now()
);

-- ============================================================
-- OPS — CHANGE ORDERS
-- ============================================================
create table if not exists cs_change_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref text not null default '',
  description text not null default '',
  amount text not null default '',
  status text not null default 'PENDING',
  created_at timestamptz not null default now()
);

-- ============================================================
-- PUNCH LIST
-- ============================================================
create table if not exists cs_punch_pro (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  description text not null,
  location text not null default '',
  trade text not null default '',
  priority text not null default 'MEDIUM',
  status text not null default 'OPEN',
  assignee text not null default '',
  due_date text not null default '',
  photo_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- RENTAL LEADS
-- ============================================================
create table if not exists cs_rental_leads (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null default '',
  email text not null default '',
  phone text not null default '',
  company text not null default '',
  equipment_type text not null default '',
  category text not null default '',
  project_name text not null default '',
  project_location text not null default '',
  rental_start text not null default '',
  rental_duration text not null default '',
  budget_range text not null default '',
  quantity integer not null default 1,
  delivery_needed boolean not null default true,
  notes text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- MARKET DATA
-- ============================================================
create table if not exists cs_market_data (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  city text not null default '',
  region text not null default '',
  sector text not null default '',
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ============================================================
-- AI MESSAGES
-- ============================================================
create table if not exists cs_ai_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  session_id text not null default '',
  role text not null default 'user',
  content text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- FINANCIAL
-- ============================================================
create table if not exists cs_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default '',
  amount numeric not null default 0,
  description text not null default '',
  project text not null default '',
  status text not null default 'pending',
  created_at timestamptz not null default now()
);

create table if not exists cs_tax_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null default '',
  amount numeric not null default 0,
  description text not null default '',
  receipt_url text not null default '',
  date text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- FIELD OPS
-- ============================================================
create table if not exists cs_daily_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project text not null default '',
  date text not null default '',
  weather text not null default '',
  crew_count integer not null default 0,
  notes text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists cs_timecards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  worker_name text not null default '',
  project text not null default '',
  date text not null default '',
  hours numeric not null default 0,
  trade text not null default '',
  created_at timestamptz not null default now()
);

-- ============================================================
-- WEALTH SUITE (synced from iOS app)
-- ============================================================
create table if not exists cs_wealth_opportunities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  score integer not null default 0,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists cs_decision_journal (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists cs_psychology_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer not null default 0,
  answers jsonb not null default '[]',
  created_at timestamptz not null default now()
);

create table if not exists cs_leverage_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  scores jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists cs_wealth_tracking (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

-- Enable RLS on all tables
alter table cs_user_profiles enable row level security;
alter table cs_projects enable row level security;
alter table cs_contracts enable row level security;
alter table cs_feed_posts enable row level security;
alter table cs_todos enable row level security;
alter table cs_schedule_events enable row level security;
alter table cs_reminders enable row level security;
alter table cs_ops_alerts enable row level security;
alter table cs_rfis enable row level security;
alter table cs_change_orders enable row level security;
alter table cs_punch_pro enable row level security;
alter table cs_rental_leads enable row level security;
alter table cs_market_data enable row level security;
alter table cs_ai_messages enable row level security;
alter table cs_transactions enable row level security;
alter table cs_tax_expenses enable row level security;
alter table cs_daily_logs enable row level security;
alter table cs_timecards enable row level security;
alter table cs_wealth_opportunities enable row level security;
alter table cs_decision_journal enable row level security;
alter table cs_psychology_sessions enable row level security;
alter table cs_leverage_snapshots enable row level security;
alter table cs_wealth_tracking enable row level security;

-- Users can read/write their own rows
-- Feed posts are publicly readable
create policy "Users manage own profile"
  on cs_user_profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own projects"
  on cs_projects for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own contracts"
  on cs_contracts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Anyone can read feed posts"
  on cs_feed_posts for select
  using (true);

create policy "Users manage own feed posts"
  on cs_feed_posts for insert
  with check (auth.uid() = user_id);

create policy "Users update own feed posts"
  on cs_feed_posts for update
  using (auth.uid() = user_id);

create policy "Users delete own feed posts"
  on cs_feed_posts for delete
  using (auth.uid() = user_id);

create policy "Users manage own todos"
  on cs_todos for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own schedule events"
  on cs_schedule_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own reminders"
  on cs_reminders for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own ops alerts"
  on cs_ops_alerts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own RFIs"
  on cs_rfis for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own change orders"
  on cs_change_orders for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own punch items"
  on cs_punch_pro for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Anyone can submit rental leads"
  on cs_rental_leads for insert
  with check (true);

create policy "Users read own rental leads"
  on cs_rental_leads for select
  using (auth.uid() = user_id);

create policy "Users manage own rental leads"
  on cs_rental_leads for update
  using (auth.uid() = user_id);

create policy "Users delete own rental leads"
  on cs_rental_leads for delete
  using (auth.uid() = user_id);

create policy "Anyone can read market data"
  on cs_market_data for select
  using (true);

create policy "Users manage own market data"
  on cs_market_data for insert
  with check (auth.uid() = user_id);

create policy "Users update own market data"
  on cs_market_data for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users delete own market data"
  on cs_market_data for delete
  using (auth.uid() = user_id);

create policy "Users manage own AI messages"
  on cs_ai_messages for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own transactions"
  on cs_transactions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own tax expenses"
  on cs_tax_expenses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own daily logs"
  on cs_daily_logs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own timecards"
  on cs_timecards for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own wealth opportunities"
  on cs_wealth_opportunities for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own decision journal"
  on cs_decision_journal for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own psychology sessions"
  on cs_psychology_sessions for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own leverage snapshots"
  on cs_leverage_snapshots for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users manage own wealth tracking"
  on cs_wealth_tracking for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================
-- INDEXES
-- ============================================================
create index if not exists idx_user_profiles_user on cs_user_profiles(user_id);
create index if not exists idx_projects_user on cs_projects(user_id);
create index if not exists idx_contracts_user on cs_contracts(user_id);
create index if not exists idx_feed_posts_user on cs_feed_posts(user_id);
create index if not exists idx_feed_posts_type on cs_feed_posts(post_type);
create index if not exists idx_feed_posts_created on cs_feed_posts(created_at desc);
create index if not exists idx_todos_user on cs_todos(user_id);
create index if not exists idx_schedule_events_user on cs_schedule_events(user_id);
create index if not exists idx_reminders_user on cs_reminders(user_id);
create index if not exists idx_ops_alerts_user on cs_ops_alerts(user_id);
create index if not exists idx_rfis_user on cs_rfis(user_id);
create index if not exists idx_change_orders_user on cs_change_orders(user_id);
create index if not exists idx_punch_user on cs_punch_pro(user_id);
create index if not exists idx_rental_leads_user on cs_rental_leads(user_id);
create index if not exists idx_market_data_user on cs_market_data(user_id);
create index if not exists idx_ai_messages_user on cs_ai_messages(user_id);
create index if not exists idx_transactions_user on cs_transactions(user_id);
create index if not exists idx_tax_expenses_user on cs_tax_expenses(user_id);
create index if not exists idx_daily_logs_user on cs_daily_logs(user_id);
create index if not exists idx_timecards_user on cs_timecards(user_id);
create index if not exists idx_wealth_opps_user on cs_wealth_opportunities(user_id);
create index if not exists idx_decision_journal_user on cs_decision_journal(user_id);
create index if not exists idx_psych_sessions_user on cs_psychology_sessions(user_id);
create index if not exists idx_leverage_snaps_user on cs_leverage_snapshots(user_id);
create index if not exists idx_wealth_tracking_user on cs_wealth_tracking(user_id);

-- NOTE: updated_at triggers defined in supabase/migrations/001_updated_at_triggers.sql
-- Run that migration to enable automatic updated_at timestamps on all tables
