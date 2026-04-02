-- PART 1: CREATE ALL TABLES
-- Paste this into Supabase SQL Editor and click RUN

create table if not exists cs_projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  client text not null default '',
  type text not null default 'General',
  status text not null default 'Active',
  progress int not null default 0,
  budget text not null default '$0',
  score text not null default '',
  team text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_contracts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  client text not null default '',
  location text not null default '',
  sector text not null default '',
  stage text not null default 'Pursuit',
  package text not null default '',
  budget text not null default '$0',
  bid_due text not null default '',
  live_feed_status text not null default '',
  bidders int not null default 0,
  score int not null default 0,
  watch_count int not null default 0,
  created_at timestamptz default now()
);

create table if not exists cs_market_data (
  id uuid primary key default gen_random_uuid(),
  city text not null,
  vacancy double precision not null default 0,
  new_biz int not null default 0,
  closed int not null default 0,
  trend text not null default 'flat',
  updated_at timestamptz default now()
);

create table if not exists cs_ai_messages (
  id uuid primary key default gen_random_uuid(),
  session_id text not null,
  role text not null,
  content text not null,
  created_at timestamptz default now()
);

create table if not exists cs_wealth_opportunities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  wealth_signal int not null default 0,
  contract_id text,
  status text not null default 'active',
  created_at timestamptz default now()
);

create table if not exists cs_decision_journal (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  context text not null default '',
  thinking_mode text not null default 'Strategic',
  decision text not null default '',
  first_order text not null default '',
  second_order text not null default '',
  gates_passed int not null default 0,
  outcome_status text not null default 'pending',
  created_at timestamptz default now(),
  reviewed_at timestamptz
);

create table if not exists cs_psychology_sessions (
  id uuid primary key default gen_random_uuid(),
  score double precision not null default 0,
  profile_label text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_leverage_snapshots (
  id uuid primary key default gen_random_uuid(),
  total_score double precision not null default 0,
  created_at timestamptz default now()
);

create table if not exists cs_wealth_tracking (
  id uuid primary key default gen_random_uuid(),
  name text not null default '',
  revenue double precision not null default 0,
  expenses double precision not null default 0,
  margin double precision not null default 0,
  notes text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_daily_logs (
  id uuid primary key default gen_random_uuid(),
  date text not null,
  weather text not null default '',
  temp_high int not null default 0,
  temp_low int not null default 0,
  manpower int not null default 0,
  work_performed text not null default '',
  visitors text not null default '',
  delays text not null default '',
  safety_notes text not null default '',
  photo_count int not null default 0,
  created_by text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_timecards (
  id uuid primary key default gen_random_uuid(),
  crew_member text not null,
  trade text not null default '',
  clock_in text not null default '',
  clock_out text not null default '',
  hours_regular double precision not null default 0,
  hours_ot double precision not null default 0,
  rate double precision not null default 0,
  site text not null default '',
  date text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_ops_alerts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  detail text not null default '',
  owner text not null default '',
  severity int not null default 1,
  due text not null default '',
  resolved boolean not null default false,
  created_at timestamptz default now()
);

create table if not exists cs_rfis (
  id uuid primary key default gen_random_uuid(),
  ref_number text not null,
  subject text not null,
  from_trade text not null default '',
  to_trade text not null default '',
  status text not null default 'open',
  priority text not null default 'normal',
  due_date text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_change_orders (
  id uuid primary key default gen_random_uuid(),
  ref_number text not null,
  description text not null,
  amount double precision not null default 0,
  status text not null default 'pending',
  project_ref text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_punch_pro (
  id uuid primary key default gen_random_uuid(),
  description text not null,
  location text not null default '',
  trade text not null default '',
  priority text not null default 'medium',
  status text not null default 'open',
  assignee text not null default '',
  due_date text not null default '',
  photo_count int not null default 0,
  created_at timestamptz default now()
);

create table if not exists cs_feed_posts (
  id uuid primary key default gen_random_uuid(),
  author_name text not null,
  author_title text not null default '',
  author_company text not null default '',
  content text not null default '',
  post_type text not null default 'update',
  tags text[] not null default '{}',
  likes int not null default 0,
  comments int not null default 0,
  shares int not null default 0,
  photo_count int not null default 0,
  created_at timestamptz default now()
);

create table if not exists cs_transactions (
  id uuid primary key default gen_random_uuid(),
  from_name text not null,
  to_name text not null,
  amount double precision not null default 0,
  type text not null default 'invoice',
  project_ref text not null default '',
  status text not null default 'pending',
  fee double precision not null default 0,
  payment_method text not null default 'standard',
  created_at timestamptz default now()
);

create table if not exists cs_crypto_transactions (
  id uuid primary key default gen_random_uuid(),
  chain text not null,
  symbol text not null,
  amount double precision not null default 0,
  usd_equivalent double precision not null default 0,
  from_address text not null default '',
  to_address text not null default '',
  tx_hash text not null default '',
  purpose text not null default '',
  project_ref text not null default '',
  status text not null default 'pending',
  confirmations int not null default 0,
  required_confirmations int not null default 12,
  created_at timestamptz default now()
);

create table if not exists cs_tax_expenses (
  id uuid primary key default gen_random_uuid(),
  date text not null,
  description text not null,
  amount double precision not null default 0,
  category text not null default '',
  project_ref text not null default '',
  receipt_attached boolean not null default false,
  deductible boolean not null default true,
  created_at timestamptz default now()
);

create table if not exists cs_equipment_rentals (
  id uuid primary key default gen_random_uuid(),
  equipment_name text not null,
  category text not null default '',
  provider text not null default '',
  daily_rate double precision not null default 0,
  weekly_rate double precision not null default 0,
  monthly_rate double precision not null default 0,
  status text not null default 'available',
  location text not null default '',
  specs text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) unique,
  email text not null default '',
  full_name text not null default '',
  company text not null default '',
  trade text not null default '',
  title text not null default '',
  location text not null default '',
  bio text not null default '',
  verification_tier text not null default 'none',
  subscription_tier text not null default 'free',
  role_preset text not null default 'SUPER',
  created_at timestamptz default now()
);

create table if not exists cs_verification_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  tier text not null default 'licensed',
  status text not null default 'pending',
  full_name text not null,
  email text not null,
  phone text not null default '',
  trade text not null,
  license_type text not null default '',
  license_number text not null default '',
  license_state text not null default '',
  license_expiry text not null default '',
  osha_level text not null default '',
  company_name text not null default '',
  ein text not null default '',
  years_in_business int not null default 0,
  insurance_carrier text not null default '',
  insurance_policy_number text not null default '',
  gl_coverage_amount text not null default '',
  wc_coverage_amount text not null default '',
  bonding_company text not null default '',
  bonding_capacity text not null default '',
  license_photo_url text,
  insurance_cert_url text,
  id_photo_url text,
  reviewer_notes text not null default '',
  denial_reason text not null default '',
  verified_at timestamptz,
  submitted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists cs_verified_badges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) unique,
  tier text not null default 'identity',
  badge_label text not null default 'VERIFIED',
  trade text not null default '',
  license_number text not null default '',
  license_state text not null default '',
  license_verified boolean not null default false,
  insurance_verified boolean not null default false,
  bonding_verified boolean not null default false,
  company_name text not null default '',
  expires_at timestamptz,
  granted_at timestamptz default now()
);

create table if not exists cs_verification_log (
  id uuid primary key default gen_random_uuid(),
  request_id uuid references cs_verification_requests(id),
  action text not null,
  actor text not null default 'system',
  details text not null default '',
  created_at timestamptz default now()
);

create table if not exists cs_trade_requirements (
  id uuid primary key default gen_random_uuid(),
  trade text not null unique,
  requires_state_license boolean not null default true,
  license_types text[] not null default '{}',
  accepted_certifications text[] not null default '{}',
  verify_with text not null default 'State Licensing Board',
  states_covered int not null default 50,
  avg_processing_days int not null default 3
);
